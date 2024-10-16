//******************************************************************************
///
/// @file unix/povconfig/syspovconfigbackend.h
///
/// Unix-specific POV-Ray backend compile-time configuration.
///
/// This header file configures aspects of POV-Ray's backend module for running
/// properly on a Unix platform.
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

#ifndef POVRAY_UNIX_SYSPOVCONFIGBACKEND_H
#define POVRAY_UNIX_SYSPOVCONFIGBACKEND_H

#include "syspovconfig.h"

#define POVRAY_PLATFORM_NAME "Unix"
#define ALTMAIN
// POV_NEW_LINE_STRING remains undefined, optimizing the code for "\n" as used internally
#define SYS_DEF_EXT     ""

// On Unix platforms, we don't do anything special at thread startup.
#define POV_USE_DEFAULT_TASK_INITIALIZE 1
#define POV_USE_DEFAULT_TASK_CLEANUP    1

// Linux machines appear to need more stack storage than the default.
// Note that we leave this setting configurable via `-DPOV_THREAD_STACK_SIZE=...`.
#ifndef POV_THREAD_STACK_SIZE
    #define POV_THREAD_STACK_SIZE (4 * 1024 * 1024) // 4 MiB
#endif

#endif // POVRAY_UNIX_SYSPOVCONFIGBACKEND_H
