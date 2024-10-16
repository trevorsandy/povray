//******************************************************************************
///
/// @file vfe/win/console/winconsole.cpp
///
/// This file contains a POV implementation using VFE.
///
/// @author Trevor SANDY<trevor.sandy@gmial.com>
/// @author Based on VFE proof-of-concept by Christopher J. Cason
/// and extensions adapted from vfe/unix/unixconsole.cpp
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
//******************************************************************************

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

// Windows standard header files
#include <windows.h>
#include <stdio.h>

// C++ variants of C standard header files
#include <cstdlib>

// boost header files
#include <boost/shared_ptr.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/thread.hpp>

// version details
#include "base/version_info.h"

// from directory "vfe"
#include "vfe.h"

// from command line
#ifndef _CONSOLE
#error "You must define _CONSOLE in windows/povconfig/syspovconfig.h prior to building the console version, otherwise you will get link errors."
#endif

// from directory "windows"
#include "disp.h"
#include "disp_text.h"
#include "disp_sdl.h"

#include "backend/povray.h"
#include "backend/control/benchmark.h"

using namespace vfe;
using namespace vfePlatform;

namespace pov_frontend
{
  shared_ptr<Display> gDisplay;

  ////////////////////////////////
  // Called from the shellout code
  ////////////////////////////////
  bool MinimizeShellouts(void) { return false; } // TODO
  bool ShelloutsPermitted(void) { return false; } // TODO
}

enum DispMode
{
  DISP_MODE_NONE,
  DISP_MODE_TEXT,
  DISP_MODE_SDL
};

static DispMode gDisplayMode;

enum ReturnValue
{
  RETURN_OK=0,
  RETURN_ERROR,
  RETURN_USER_ABORT
};

static bool gCancelRender = false;

// for handling console events
BOOL WINAPI ConsoleHandler(DWORD);
HANDLE hStdin;
DWORD fdwSaveOldMode;

BOOL WINAPI ConsoleHandler(DWORD CEvent)
{
  switch(CEvent)
  {
  case CTRL_C_EVENT:
    fprintf(stderr, "\n%s: received CTRL_C_EVENT: CTRL+C; requested render cancel\n", PACKAGE_NAME);
    gCancelRender = true;
    break;
  case CTRL_BREAK_EVENT:
    fprintf(stderr, "\n%s: received CTRL_BREAK_EVENT: CTRL+BREAK; requested render cancel\n", PACKAGE_NAME);
    gCancelRender = true;
    break;
  case CTRL_CLOSE_EVENT:
    fprintf(stderr, "\n%s: received CTRL_CLOSE_EVENT: Program being closed; requested render cancel\n", PACKAGE_NAME);
    gCancelRender = true;
    break;
  case CTRL_LOGOFF_EVENT:
    fprintf(stderr, "\n%s: received CTRL_LOGOFF_EVENT: User is logging off; requested render cancel\n", PACKAGE_NAME);
    gCancelRender = true;
    break;
  case CTRL_SHUTDOWN_EVENT:
    fprintf(stderr, "\n%s: received CTRL_SHUTDOWN_EVENT: User shutting down; requested render cancel\n", PACKAGE_NAME);
    gCancelRender = true;
    break;
  default:
      gCancelRender = false;
  }
  return TRUE;
}

static vfeDisplay *WinConDisplayCreator(unsigned int width, unsigned int height, vfeSession *session, bool visible)
{
  WinConDisplay *display = GetRenderWindow();
  switch (gDisplayMode)
  {
#ifdef HAVE_LIBSDL
  case DISP_MODE_SDL:
    if (display != nullptr && display->GetWidth() == width && display->GetHeight() == height)
    {
      WinConDisplay *p = new WinConSDLDisplay(width, height, session, false);
      if (p->TakeOver(display))
        return p;
      delete p;
    }
    return new WinConSDLDisplay(width, height, session, visible);
    break;
#endif
  case DISP_MODE_TEXT:
    return new WinConTextDisplay(width, height, session, visible);
    break;
  default:
    return nullptr;
  }
}

/* Show a message */
static void PrintMessage(const char *title, const char *message)
{
  fprintf(stderr, "%s: %s\n", title, message);
}

void PrintStatus(vfeSession *session)
{
  // TODO -- when invoked while processing "--help" command-line switch,
  //         GNU/Linux customs would be to print to stdout (among other differences).
  string str;
  vfeSession::MessageType type;
  static vfeSession::MessageType lastType = vfeSession::mUnclassified;

  while (session->GetNextCombinedMessage(type, str))
  {
    if (type != vfeSession::mGenericStatus)
    {
      if (lastType == vfeSession::mGenericStatus)
       fprintf(stderr, "\n");
      fprintf(stderr, "%s\n", str.c_str());
    }
    else
      fprintf(stderr, "%s\r", str.c_str());
    lastType = type;
  }
}

static void PrintStatusChanged (vfeSession *session, State force = kUnknown)
{
  if (force == kUnknown)
    force = session->GetBackendState();
  switch (force)
  {
    case kParsing:
      fprintf (stderr, "==== [Parsing...] ==========================================================\n");
      break;
    case kRendering:
#ifdef HAVE_LIBSDL
      if ((gDisplay != nullptr) && (gDisplayMode == DISP_MODE_SDL))
      {
          fprintf (stderr, "==== [Rendering... Press p to pause, q to quit] ============================\n");
      }
      else
      {
          fprintf (stderr, "==== [Rendering...] ========================================================\n");
      }
#else
      fprintf (stderr, "==== [Rendering...] ========================================================\n");
#endif
      break;
    case kPausedRendering:
#ifdef HAVE_LIBSDL
      if ((gDisplay != nullptr) && (gDisplayMode == DISP_MODE_SDL))
      {
          fprintf (stderr, "==== [Paused... Press p to resume] =========================================\n");
      }
      else
      {
          fprintf (stderr, "==== [Paused...] ===========================================================\n");
      }
#else
      fprintf (stderr, "==== [Paused...] ===========================================================\n");
#endif
      break;
    default:
      // Do nothing special.
      break;
  }
}

static void PrintVersion(void)
{
  // TODO -- GNU/Linux customs would be to print to stdout (among other differences).
  fprintf(stderr,
    "%s %s\n\n"
    "%s\n%s\n%s\n%s\n"
    "%s\n%s\n%s\n\n"
    "%s\n%s\n%s\n\n",
    PACKAGE_NAME, POV_RAY_VERSION,
    DISTRIBUTION_MESSAGE_LPUB3D_TRACE_1, DISTRIBUTION_MESSAGE_LPUB3D_TRACE_2, DISTRIBUTION_MESSAGE_2, DISTRIBUTION_MESSAGE_3,
    DESCRIPTION_MESSAGE_LPUB3D_TRACE_1, DESCRIPTION_MESSAGE_LPUB3D_TRACE_2, DESCRIPTION_MESSAGE_LPUB3D_TRACE_3,
    LPUB3D_TRACE_COPYRIGHT, DISCLAIMER_MESSAGE_1, DISCLAIMER_MESSAGE_2
  );
  fprintf(stderr,
    "Built-in features:\n"
    "  I/O restrictions:          %s\n"
    "  Supported image formats:   %s\n"
    "  Unsupported image formats: %s\n\n",
    BUILTIN_IO_RESTRICTIONS, BUILTIN_IMG_FORMATS, MISSING_IMG_FORMATS
  );
  fprintf(stderr,
    "Compilation settings:\n"
    "  Build architecture:  %s\n"
    "  Built/Optimized for: %s\n"
    "  Compiler vendor:     %s\n"
    "  Compiler version:    %d\n",
    BUILD_ARCH, BUILT_FOR, COMPILER_VENDOR, COMPILER_VERSION
  );
}

static void PrintGeneration(void)
{
    fprintf(stdout, "%s\n", POV_RAY_GENERATION POV_RAY_BETA_SUFFIX);
}


void ErrorExit(vfeSession *session)
{
  fprintf (stderr, "%s\n", session->GetErrorString());
  session->Shutdown();
  delete session;
  std::exit (1);
}

void BenchMarkErrorExit(LPSTR lpszMessage)
{
  fprintf(stderr, "%s\n", lpszMessage);
  // Restore input mode on exit.
  SetConsoleMode(hStdin, fdwSaveOldMode);
  ExitProcess(0);
}

static void CancelRender(vfeSession *session)
{
  session->CancelRender();  // request the backend to cancel
  PrintStatus (session);
  while (session->GetBackendState() != kReady)  // wait for the render to effectively shut down
    Delay(10);
  PrintStatus (session);
}

static void PauseWhenDone(vfeSession *session)
{
  GetRenderWindow()->UpdateScreen(true);
  GetRenderWindow()->PauseWhenDoneNotifyStart();
  while (GetRenderWindow()->PauseWhenDoneResumeIsRequested() == false)
  {
    if (gCancelRender)
      break;
    else
      Delay(10);
  }
  GetRenderWindow()->PauseWhenDoneNotifyEnd();
}

static ReturnValue PrepareBenchmark(vfeSession *session, vfeRenderOptions& opts, string& ini, string& pov, int argc, char **argv)
{

  // parse command-line options
  while (*++argv)
  {
    string s = string(*argv);
    boost::algorithm::to_lower(s);
    // set number of threads to run the benchmark
    if (boost::starts_with(s, "+wt") || boost::starts_with(s, "-wt"))
    {
      s.erase(0, 3);
      int n = std::atoi(s.c_str());
      if (n)
        opts.SetThreadCount(n);
      else
        fprintf(stderr, "%s: ignoring malformed '%s' command-line option\n", PACKAGE_NAME, *argv);
    }
    // add library path
    else if (boost::starts_with(s, "+l") || boost::starts_with(s, "-l"))
    {
      s.erase(0, 2);
      opts.AddLibraryPath(s);
    }
  }

  int benchversion = pov::Get_Benchmark_Version();
  fprintf(stderr, "\
    %s %s\n\n\
    Entering the standard " PACKAGE_NAME " %s benchmark version %x.%02x.\n\n\
    This built-in benchmark requires " PACKAGE_NAME " to be installed on your system\n\
    before running it.  There will be neither display nor file output, and\n\
    any additional command-line option except setting the number of render\n\
    threads (+wtN for N threads) and library paths (+Lpath) will be ignored.\n\
    To get an accurate benchmark result you might consider running  " PACKAGE_NAME "\n\
    with the Win 'time' command (e.g. 'time povray -benchmark').\n\n\
    The benchmark will run using %d render thread(s).\n\
    Press <Enter> to continue or <Ctrl-C> to abort.\n\
    ",
    PACKAGE_NAME, POV_RAY_VERSION_INFO,
    VERSION_BASE, benchversion / 256, benchversion % 256,
    opts.GetThreadCount()
    );

  DWORD cNumRead, fdwMode, i;
  INPUT_RECORD irInBuf[128];
  int counter = 0;

  // Get the standard input handle.
  hStdin = GetStdHandle(STD_INPUT_HANDLE);
  if (hStdin == INVALID_HANDLE_VALUE)
    BenchMarkErrorExit("Invalid standard input handle.");

  // Save the current input mode, to be restored on exit.

  if (!GetConsoleMode(hStdin, &fdwSaveOldMode))
    BenchMarkErrorExit("Unable to get current console mode.");

  // Enable the window and mouse input events.

  fdwMode = ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT;
  if (!SetConsoleMode(hStdin, fdwMode))
    BenchMarkErrorExit("Unable to set console mode with window and mouse input.");

  // wait for user input from stdin (including abort signals)
  while (true)
  {
    if (gCancelRender)
    {
      fprintf(stderr, "Render cancelled by user\n");
      return RETURN_USER_ABORT;
    }

    // Wait for user input events.
    if (!ReadConsoleInput(
      hStdin,      // input buffer handle
      irInBuf,     // buffer to read into
      128,         // size of read buffer
      &cNumRead))  // number of records read
    BenchMarkErrorExit("ReadConsoleInput");

    if (cNumRead > 0)  // user input is available
    {
      for (i = 0; i < cNumRead; i++)     // read till <ENTER> is hit
      {
        if (irInBuf[i].EventType == KEY_EVENT && irInBuf[i].Event.KeyEvent.wVirtualKeyCode == VK_RETURN)
          break;
      }
    }
    Delay(20);
  }

  string basename = UCS2toASCIIString(session->CreateTemporaryFile());
  ini = basename + ".ini";
  pov = basename + ".pov";
  if (pov::Write_Benchmark_File(pov.c_str(), ini.c_str()))
  {
    fprintf(stderr, "%s: creating %s\n", PACKAGE_NAME, ini.c_str());
    fprintf(stderr, "%s: creating %s\n", PACKAGE_NAME, pov.c_str());
    fprintf(stderr, "Running standard " PACKAGE_NAME " benchmark version %x.%02x\n", benchversion / 256, benchversion % 256);
  }
  else
  {
    fprintf(stderr, "%s: failed to write temporary files for benchmark\n", PACKAGE_NAME);
    return RETURN_ERROR;
  }

  // Restore input mode on exit.
  SetConsoleMode(hStdin, fdwSaveOldMode);

  return RETURN_OK;
}

static void CleanupBenchmark(vfeWinSession *session, string& ini, string& pov)
{
  fprintf(stderr, "%s: removing %s\n", PACKAGE_NAME, ini.c_str());
  session->DeleteTemporaryFile(ASCIItoUCS2String(ini.c_str()));
  fprintf(stderr, "%s: removing %s\n", PACKAGE_NAME, pov.c_str());
  session->DeleteTemporaryFile(ASCIItoUCS2String(pov.c_str()));
}

// Tokenize quoted command line arguments
// Single and double quoted arguments stored in a string vector
// Quotes can start before or after the '+|-' character e.g.
// "+Idir with space in the name/f o o.pov" or
// +I"dir with space in the name/f o o.pov"
void FormatQuotedArguments(std::vector<std::string>& cmdargs, const std::string& commandline)
{
    int len = commandline.length();
    bool dqot = false, sqot = false, optflag = false;
    int arglen, adjustment, qotpos;
    for (size_t i = 0; i < len; i++) {
        int start = i;
        if (commandline[i] == '\"') dqot = true;
        else if (commandline[i] == '\'') sqot = true;
        else if (commandline[i] == '+' || commandline[i] == '-') {
            optflag = true; qotpos = i + 2;
            if (qotpos < len) {
                if (commandline[qotpos] == '\"') dqot = true;
                else if (commandline[qotpos] == '\'') sqot = true;
                if (dqot || sqot) i = qotpos;
            }
        }

        if (dqot) {
            i++;
            while (i < len && commandline[i] != '\"')
                i++;
            if (i < len) {
                adjustment = i + 1;
                dqot = false;
                if (optflag) optflag = false;
            }
            arglen = adjustment - start;
            i++;
        }
        else if (sqot) {
            i++;
            while (i<len && commandline[i] != '\'')
                i++;
            if (i < len) {
                adjustment = i + 1;
                sqot = false;
                if (optflag) optflag = false;
            }
            arglen = adjustment - start;
            i++;
        }
        else {
            while (i<len && commandline[i] != ' ')
                i++;
            arglen = i - start;
        }
        cmdargs.push_back(commandline.substr(start, arglen));
    }
    if (dqot || sqot) fprintf(stderr, "One of the command line quotes is open\n");
}

// This is the console user interface build of LPub3D-Trace under Windows
// using the VFE (virtual front-end) library. This implementation
// includes the same capabilities as the Unix console build.
// It is not officially supported.


/**
*  For SDL on Windows, declare main() function using C linkage like this:
*/

extern "C" int main(int argc, char **argv)
{
  char              *s;
  vfeWinSession     *session;
  vfeStatusFlags    flags;
  vfeRenderOptions  opts;
  ReturnValue       retval = RETURN_OK;
  bool              running_benchmark = false;
  bool              mapped_file_mode = false;
  std::string       bench_ini_name;
  std::string       bench_pov_name;
  char **           argv_copy=argv; /* because argv is updated later */
  int               argc_copy=argc; /* because it might also be updated */

  fprintf(stderr,
    "\n" PACKAGE_NAME " for Windows.\n\n"
    PACKAGE_NAME " Ray Tracer Version " POV_RAY_VERSION_INFO ".\n\n"
    DISTRIBUTION_MESSAGE_LPUB3D_TRACE_1 "\n"
    DISTRIBUTION_MESSAGE_LPUB3D_TRACE_2 "\n"
    DISTRIBUTION_MESSAGE_2 ".\n"
    DISTRIBUTION_MESSAGE_3 "\n"
    DESCRIPTION_MESSAGE_LPUB3D_TRACE_1 "\n"
    DESCRIPTION_MESSAGE_LPUB3D_TRACE_2 "\n"
    DESCRIPTION_MESSAGE_LPUB3D_TRACE_3 "\n\n"
    LPUB3D_TRACE_COPYRIGHT "\n"
    DISCLAIMER_MESSAGE_1 "\n"
    DISCLAIMER_MESSAGE_2 "\n\n");

  // create handler to manage console signals
  if (!SetConsoleCtrlHandler((PHANDLER_ROUTINE)ConsoleHandler,TRUE))
  {
   fprintf(stderr, "Unable to install console control handler!\n");
   return RETURN_ERROR;
  }

  if (argc > 1)
  {
#ifdef WIN_DEBUG
	std::cerr << "ORIGINAL COMMAND LINE (" << argc << ")" << std::endl;
#endif
    std::string commandline;
    std::vector<std::string> commandargs;
    for (int i = 0; i < argc; i++)
    {
#ifdef WIN_DEBUG // ORIGINAL COMMAND LINE
	   std::cerr << "- " << i + 1 << ". " << argv[i] << std::endl;
#endif
      if (i == 0)
		  commandargs.push_back(std::string(argv[i]));
      else
		  commandline.append(std::string(argv[i]).append(" "));

	  // set mapped file mode
	  std::size_t found = std::string(argv[i]).find("+SM");
	  if(found != std::string::npos)
		  mapped_file_mode = true;
    }

	// Check for spaces in command line arguments
    FormatQuotedArguments(commandargs, commandline);

#ifdef WIN_DEBUG
	std::cerr << "FORMATTED COMMAND LINE (" << argc << ")" << std::endl;
#endif
    int n_argc = commandargs.size();
    char **n_argv = (char **)malloc((n_argc + 1) * sizeof(char *));
    for (int i = 0; i < n_argc; i++)
    {
      n_argv[i] = (char *)malloc(strlen(commandargs[i].c_str()) + 1);
      std::strcpy(n_argv[i], commandargs[i].c_str());
#ifdef WIN_DEBUG // FORMATTED COMMAND LINE
	  for (int i = 0; i < argc; i++) std::cerr << "- " << i + 1 << ". " << argv[i] << std::endl;
#endif
    }
    n_argv[n_argc] = nullptr;
    argc = n_argc;
    argv = n_argv;
  }

  // create display session
  session = new vfeWinSession();
  if (session->Initialize(nullptr, nullptr) != vfeNoError)
	  ErrorExit(session);

  // display mode registration
#ifdef HAVE_LIBSDL
  if (!mapped_file_mode) 
  {
	if (WinConSDLDisplay::Register(session))
	{
		gDisplayMode = DISP_MODE_SDL;
#ifdef WIN_DEBUG
		PrintMessage("--INFO", "Display Mode: SDL.\n");
#endif
	}
  }
  else
#endif
  if (WinConTextDisplay::Register(session))
  {
     gDisplayMode = DISP_MODE_TEXT;
#ifdef WIN_DEBUG
	 PrintMessage("--INFO", "Display Mode: Text.\n");
#endif
  }
  else
  {
     gDisplayMode = DISP_MODE_NONE;
#ifdef WIN_DEBUG
	 PrintMessage("--INFO", "Display Mode: None.\n");
#endif
  }

  // default number of work threads: number of CPUs or 4
  int nthreads = boost::thread::hardware_concurrency();
  if (nthreads < 2)
      nthreads = 4;
  opts.SetThreadCount(nthreads);

  // process command-line options
  session->GetWinConOptions()->ProcessOptions(&argc, &argv);
  if (session->GetWinConOptions()->isOptionSet("general", "help"))
  {
    session->Shutdown() ;
    PrintStatus (session) ;
    // TODO: general usage display (not yet in core code)
    session->GetWinConOptions()->PrintOptions();
    delete session;
    return RETURN_OK;
  }
  else if (session->GetWinConOptions()->isOptionSet("general", "version"))
  {
    session->Shutdown() ;
    PrintVersion();
    delete session;
    return RETURN_OK;
  }
  else if (session->GetWinConOptions()->isOptionSet("general", "generation"))
  {
    session->Shutdown();
    PrintGeneration();
    delete session;
    return RETURN_OK;
  }
  else if (session->GetWinConOptions()->isOptionSet("general", "benchmark"))
  {
    retval = PrepareBenchmark(session, opts, bench_ini_name, bench_pov_name, argc, argv);
    if (retval == RETURN_OK)
      running_benchmark = true;
    else
    {
      session->Shutdown();
      delete session;
      return retval;
    }
  }

  // process INI settings
  if (running_benchmark)
  {
    // read only the provided INI file and set minimal lib paths
    opts.AddLibraryPath(string(POVLIBDIR "\\include"));
    opts.AddINI(bench_ini_name.c_str());
    opts.SetSourceFile(bench_pov_name.c_str());
  }
  else
  {
    s = std::getenv ("POVINC");
    session->SetDisplayCreator(WinConDisplayCreator);
    session->GetWinConOptions()->Process_povray_ini(opts);
    if (s != nullptr)
      opts.AddLibraryPath (s);
    while (*++argv)
      opts.AddCommand (*argv);
  }

  // set all options and start rendering
  if (session->SetOptions(opts) != vfeNoError)
  {
    fprintf(stderr,"\nProblem with option setting\n");
    for(int loony=0;loony<argc_copy;loony++)
    {
        fprintf(stderr,"%s%c",argv_copy[loony],loony+1<argc_copy?' ':'\n');
    }
    ErrorExit(session);
  }
  if (session->StartRender() != vfeNoError)
    ErrorExit(session);

  // set inter-frame pause for animation
  if (session->RenderingAnimation() && session->GetBoolOption("Pause_When_Done", false))
    session->PauseWhenDone(true);

  // main render loop
  session->SetEventMask(stBackendStateChanged);  // immediately notify this event

  while (((flags = session->GetStatus(true, 200)) & stRenderShutdown) == 0)
  {
    if (gCancelRender)
    {
      CancelRender(session);
      break;
    }

    if (flags & stAnimationStatus)
      fprintf(stderr, "\nRendering frame %d of %d (#%d)\n", session->GetCurrentFrame(), session->GetTotalFrames(), session->GetCurrentFrameId());
    if (flags & stAnyMessage)
      PrintStatus(session);
    if (flags & stBackendStateChanged)
      PrintStatusChanged(session);

    if (GetRenderWindow() != nullptr)
    {
      // early exit
      if (GetRenderWindow()->HandleEvents())
      {
        gCancelRender = true;  // will set proper return value
        CancelRender(session);
        break;
      }

      GetRenderWindow()->UpdateScreen();

      // inter-frame pause
      if (session->GetCurrentFrame() < session->GetTotalFrames()
        && session->GetPauseWhenDone()
        && (flags & stAnimationFrameCompleted) != 0
        && session->Failed() == false)
      {
        PauseWhenDone(session);
        if (!gCancelRender)
          session->Resume();
      }
    }
  }

  // pause when done for single or last frame of an animation
  if (session->Failed() == false && GetRenderWindow() != nullptr && session->GetBoolOption("Pause_When_Done", false))
  {
    PrintStatusChanged(session, kPausedRendering);
    PauseWhenDone(session);
    gCancelRender = false;
  }

  if (running_benchmark)
    CleanupBenchmark(session, bench_ini_name, bench_pov_name);

  if (session->Succeeded() == false)
    retval = gCancelRender ? RETURN_USER_ABORT : RETURN_ERROR;

  session->Shutdown();
  PrintStatus (session);
  delete session;

  return retval;
}

