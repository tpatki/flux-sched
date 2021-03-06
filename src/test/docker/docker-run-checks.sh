#!/bin/bash
#
#  Build flux-sched docker image and run tests, exporting
#   important environment variables to the docker environment.
#
#  Arguments here are passed directly to ./configure
#
#
# option Defaults:
IMAGE=bionic
JOBS=2
MOUNT_HOME_ARGS="--volume=$HOME:/home/$USER -e HOME"

#
declare -r prog=${0##*/}
die() { echo -e "$prog: $@"; exit 1; }

#
declare -r long_opts="help,quiet,interactive,image:,jobs:,no-cache,no-home,distcheck,tag:,build-directory:"
declare -r short_opts="hqIdi:j:t:D:"
declare -r usage="
Usage: $prog [OPTIONS] -- [CONFIGURE_ARGS...]\n\
Build docker image for travis builds, then run tests inside the new\n\
container as the current user and group.\n\
\n\
Uses the current git repo for the build.\n\
\n\
Options:\n\
 -h, --help                    Display this message\n\
     --no-cache                Disable docker caching\n\
     --no-home                 Skip mounting the host home directory\n\
 -q, --quiet                   Add --quiet to docker-build\n\
 -t, --tag=TAG                 If checks succeed, tag image as NAME\n\
 -i, --image=NAME              Use base docker image NAME (default=$IMAGE)\n\
 -j, --jobs=N                  Value for make -j (default=$JOBS)\n
 -d, --distcheck               Run 'make distcheck' instead of 'make check'\n\
 -D, --build-directory=DIRNAME Name of a subdir to build in, will be made\n\
 -I, --interactive             Instead of running travis build, run docker\n\
                                image with interactive shell.\n\
"

# check if running in OSX
if [[ "$(uname)" == "Darwin" ]]; then
    # BSD getopt
    GETOPTS=`/usr/bin/getopt $short_opts -- $*`
else
    # GNU getopt
    GETOPTS=`/usr/bin/getopt -u -o $short_opts -l $long_opts -n $prog -- $@`
    if [[ $? != 0 ]]; then
        die "$usage"
    fi
    eval set -- "$GETOPTS"
fi
while true; do
    case "$1" in
      -h|--help)                   echo -ne "$usage";          exit 0  ;;
      -q|--quiet)                  QUIET="--quiet";            shift   ;;
      -i|--image)                  IMAGE="$2";                 shift 2 ;;
      -j|--jobs)                   JOBS="$2";                  shift 2 ;;
      -I|--interactive)            INTERACTIVE="/bin/bash";    shift   ;;
      -d|--distcheck)              DISTCHECK=t;                shift   ;;
      -D|--build-directory)        BUILD_DIR="$2";             shift 2 ;;
      --no-cache)                  NO_CACHE="--no-cache";      shift   ;;
      --no-home)                   MOUNT_HOME_ARGS="";         shift   ;;
      -t|--tag)                    TAG="$2";                   shift 2 ;;
      --)                          shift; break;                       ;;
      *)                           die "Invalid option '$1'\n$usage"   ;;
    esac
done


TOP=$(git rev-parse --show-toplevel 2>&1) \
    || die "not inside flux-sched git repository!"
which docker >/dev/null \
    || die "unable to find a docker binary"

CONFIGURE_ARGS="$@"

. ${TOP}/src/test/travis-lib.sh

travis_fold "docker_build" \
  "Building image $IMAGE for user $USER $(id -u) group=$(id -g)" \
  docker build \
    ${NO_CACHE} \
    ${QUIET} \
    --build-arg USER=$USER \
    --build-arg UID=$(id -u) \
    -t travis-builder:${IMAGE} \
    $TOP/src/test/docker/${IMAGE} \
    || die "docker build failed"

if [[ -n "$MOUNT_HOME_ARGS" ]]; then
    echo "mounting $HOME as /home/$USER"
fi
echo "mounting $TOP as /usr/src"

export JOBS
export DISTCHECK
export BUILD_DIR
export chain_lint

docker run --rm \
    --workdir=/usr/src \
    --volume=$TOP:/usr/src \
    $MOUNT_HOME_ARGS \
    -e CC \
    -e CXX \
    -e LDFLAGS \
    -e CFLAGS \
    -e CPPFLAGS \
    -e GCOV \
    -e CCACHE_CPP2 \
    -e CCACHE_READONLY \
    -e COVERAGE \
    -e TEST_INSTALL \
    -e CPPCHECK \
    -e DISTCHECK \
    -e BUILD_DIR \
    -e chain_lint \
    -e JOBS \
    -e USER \
    -e TRAVIS \
    -e TAP_DRIVER_QUIET \
    -e TEST_CHECK_PREREQS \
    --cap-add SYS_PTRACE \
    --tty \
    ${INTERACTIVE:+--interactive} \
    travis-builder:${IMAGE} \
    ${INTERACTIVE:-./src/test/travis_run.sh ${CONFIGURE_ARGS}} \
    || die "docker run failed"

if test -n "$TAG"; then
    # Re-run 'make install' in fresh image, otherwise we get all
    # the context from the build above
    docker run --name=tmp.$$ \
	--workdir=/usr/src \
        --volume=$TOP:/usr/src \
        --user="root" \
	travis-builder:${IMAGE} \
	sh -c "cd ${BUILD_DIR:-.} && \
	       make install && \
               userdel $USER" \
	|| (docker rm tmp.$$; die "docker run of 'make install' failed")
    docker commit \
	--change 'ENTRYPOINT [ "/usr/local/sbin/entrypoint.sh" ]' \
	--change 'CMD [ "/usr/bin/flux", "start", "/bin/bash" ]' \
	--change 'USER fluxuser' \
	--change 'WORKDIR /home/fluxuser' \
	tmp.$$ $TAG \
	|| die "docker commit failed"
    docker rm tmp.$$
    echo "Tagged image $TAG"
fi
