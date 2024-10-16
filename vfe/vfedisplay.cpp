//******************************************************************************
///
/// @file vfe/vfedisplay.cpp
///
/// This module contains a basic in-memory implementation of the Display class.
///
/// @author: Christopher J. Cason
///
/// @copyright
/// @parblock
///
/// LPub3D Ray Tracer ('LPub3D-Trace') version 3.8. is built
/// specially for LPub3D - An LDraw Building Instruction Editor.
/// Copyright 2017 - 2024 by Trevor SANDY.
///
/// LPub3D-Trace is free software: you can redistribute it and/or modify
/// it under the terms of the GNU Affero General Public License as
/// published by the Free Software Foundation, either version 3 of the
/// License, or (at your option) any later version.
///
/// LPub3D-Trace is distributed in the hope that it will be useful,
/// but WITHOUT ANY WARRANTY; without even the implied warranty of
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
/// GNU Affero General Public License for more details.
///
/// You should have received a copy of the GNU Affero General Public License
/// along with this program.  If not, see <http://www.gnu.org/licenses/>.
///
/// ----------------------------------------------------------------------------
///
/// LPub3D-Trace is based on Persistence of Vision Ray Tracer ('POV-Ray') version 3.8.
/// Copyright 1991-2021 Persistence of Vision Raytracer Pty. Ltd which is,
/// in turn, based on the popular DKB raytracer version 2.12.
/// DKBTrace was originally written by David K. Buck.
/// DKBTrace Ver 2.0-2.12 were written by David K. Buck & Aaron A. Collins.
///
/// @endparblock
///
//------------------------------------------------------------------------------
// SPDX-License-Identifier: AGPL-3.0-or-later
//******************************************************************************

#include "vfe.h"
#include <iostream>
#include <fstream>

// this must be the last file included
#include "syspovdebug.h"

////////////////////////////////////////////////////////////////////////////////////////
//
// class vfeDisplay
//
////////////////////////////////////////////////////////////////////////////////////////

namespace vfe
{

struct vfeDisplayBufferHeader
{
  uint32_t Version;
  uint32_t Width;
  uint32_t Height;
  uint32_t PixelsWritten;
  uint32_t PixelsRead;
};

vfeDisplay::vfeDisplay(unsigned int w, unsigned int h, vfeSession* session, bool visible) :
  Display(w, h),
  m_Session(session),
  m_VisibleOnCreation(visible),
  m_Buffer(NULL),
  m_FileMapping(NULL),
  m_MappedRegion(NULL)
{
}

vfeDisplay::~vfeDisplay()
{
 Clear();
}

void vfeDisplay::Initialise()
{
 POVMSUCS2String SharedMemoryName = m_Session->GetOptions().GetOptions().TryGetUCS2String(kPOVAttrib_SharedMemory, "");
  const size_t AllocSize = GetWidth() * GetHeight() * sizeof(RGBA8) + sizeof(vfeDisplayBufferHeader);

  if (SharedMemoryName.empty())
    m_Buffer = malloc(AllocSize);
  else
  {
    std::string FileName = UCS2toASCIIString(SharedMemoryName);
    std::filebuf fbuf;
    fbuf.open(FileName, std::ios_base::in | std::ios_base::out | std::ios_base::trunc | std::ios_base::binary);
    fbuf.pubseekoff(AllocSize, std::ios_base::beg);
    fbuf.sputc(0);
    fbuf.close();

    m_FileMapping = new boost::interprocess::file_mapping(FileName.c_str(), boost::interprocess::read_write);
    m_MappedRegion = new boost::interprocess::mapped_region(*m_FileMapping, boost::interprocess::read_write);

	m_Buffer = m_MappedRegion->get_address();

    vfeDisplayBufferHeader* Header = (vfeDisplayBufferHeader*)m_Buffer;
    Header->Version = 1;
    Header->Width = GetWidth();
    Header->Height = GetHeight();
    Header->PixelsWritten = 0;
    Header->PixelsRead = 0;
  }
}

void vfeDisplay::Close()
{
}

void vfeDisplay::Show()
{
}

void vfeDisplay::Hide()
{
}

void vfeDisplay::DrawPixel(unsigned int x, unsigned int y, const RGBA8& colour)
{
  assert (x < GetWidth() && y < GetHeight());
  vfeDisplayBufferHeader* Header = (vfeDisplayBufferHeader*)m_Buffer;
  RGBA8* Pixels = (RGBA8*)(Header + 1);
  Pixels[y * GetWidth() + x] = colour;
  Header->PixelsWritten++;
}

void vfeDisplay::DrawRectangleFrame(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8& colour)
{
}

void vfeDisplay::DrawFilledRectangle(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8& colour)
{
}

void vfeDisplay::DrawPixelBlock(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, const RGBA8 *colour)
{
  for (int y = y1 ; y <= y2; y++)
    for (int x = x1; x <= x2; x++)
      DrawPixel (x, y, *colour++) ;
}

void vfeDisplay::Clear()
{
  if (!m_FileMapping)
    free(m_Buffer);
  else
  {
    delete m_MappedRegion;
    m_MappedRegion = NULL;
    delete m_FileMapping;
    m_FileMapping = NULL;
  }
  m_Buffer = NULL;
}

} // end of namespace
