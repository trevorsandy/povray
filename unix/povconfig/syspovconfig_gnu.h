//******************************************************************************
///
/// @file unix/povconfig/syspovconfig_gnu.h
///
/// GNU/Linux Unixoid flavor-specific POV-Ray compile-time configuration.
///
/// This header file configures aspects of POV-Ray for running properly on a
/// GNU/Linux platform.
///
/// @copyright
/// @parblock
///
/// Persistence of Vision Ray Tracer ('POV-Ray') version 3.8.
/// Copyright 1991-2021 Persistence of Vision Raytracer Pty. Ltd.
///
/// POV-Ray is free software: you can redistribute it and/or modify
/// it under the terms of the GNU Affero General Public License as
/// published by the Free Software Foundation, either version 3 of the
/// License, or (at your option) any later version.
///
/// POV-Ray is distributed in the hope that it will be useful,
/// but WITHOUT ANY WARRANTY; without even the implied warranty of
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
/// GNU Affero General Public License for more details.
///
/// You should have received a copy of the GNU Affero General Public License
/// along with this program.  If not, see <http://www.gnu.org/licenses/>.
///
/// ----------------------------------------------------------------------------
///
/// POV-Ray is based on the popular DKB raytracer version 2.12.
/// DKBTrace was originally written by David K. Buck.
/// DKBTrace Ver 2.0-2.12 were written by David K. Buck & Aaron A. Collins.
///
/// @endparblock
///
//******************************************************************************

#ifndef POVRAY_UNIX_SYSPOVCONFIG_GNU_H
#define POVRAY_UNIX_SYSPOVCONFIG_GNU_H

#include <unistd.h>

// GNU/Linux provides large file support via the `lseek64` function,
// with file offsets having type `off64_t`.
#define POV_LSEEK(handle,offset,whence) lseek64(handle,offset,whence)
#define POV_OFF_T off64_t

#if defined(_POSIX_V6_LPBIG_OFFBIG) || defined(_POSIX_V6_LP64_OFF64)
    // long is at least 64 bits.
    #define POV_LONG long
#elif defined(_POSIX_V6_ILP32_OFFBIG) || defined(_POSIX_V6_ILP32_OFF32)
    // long is 32 bits.
    #define POV_LONG long long
#else
    // Unable to detect long size at compile-time, assuming less than 64 bits.
    #define POV_LONG long long
#endif

#define POV_ULONG unsigned POV_LONG

#define MACHINE_INTRINSICS_H <x86intrin.h>
#define ALIGN32 __attribute__ ((aligned(32)))

#endif // POVRAY_UNIX_SYSPOVCONFIG_GNU_H
