/*****************************************************************************\
 *  Copyright (c) 2019 Lawrence Livermore National Security, LLC.  Produced at
 *  the Lawrence Livermore National Laboratory (cf, AUTHORS, DISCLAIMER.LLNS).
 *  LLNL-CODE-658032 All rights reserved.
 *
 *  This file is part of the Flux resource manager framework.
 *  For details, see https://github.com/flux-framework.
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the Free
 *  Software Foundation; either version 2 of the license, or (at your option)
 *  any later version.
 *
 *  Flux is distributed in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the terms and conditions of the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
 *  See also:  http://www.gnu.org/licenses/
\*****************************************************************************/

#ifndef QUEUE_POLICY_HYBRID_HPP
#define QUEUE_POLICY_HYBRID_HPP

#include "qmanager/policies/queue_policy_bf_base.hpp"

namespace Flux {
namespace queue_manager {
namespace detail {

template<class reapi_type>
class queue_policy_hybrid_t : public queue_policy_bf_base_t<reapi_type>
{
public:
    virtual ~queue_policy_hybrid_t ();
    queue_policy_hybrid_t ();
    queue_policy_hybrid_t (const queue_policy_hybrid_t &p) = default;
    queue_policy_hybrid_t (queue_policy_hybrid_t &&p) = default;
    queue_policy_hybrid_t &operator= (const queue_policy_hybrid_t &p) = default;
    queue_policy_hybrid_t &operator= (queue_policy_hybrid_t &&p) = default;

    virtual int apply_params ();
};

} // namespace Flux::queue_manager::detail
} // namespace Flux::queue_manager
} // namespace Flux

#endif // QUEUE_POLICY_HYBRID_HPP

/*
 * vi:tabstop=4 shiftwidth=4 expandtab
 */
