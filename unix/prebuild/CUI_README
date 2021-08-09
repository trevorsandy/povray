    ///
    /// LPub3D-Trace Windows Console User Interface (CUI) build
	/// @author Trevor SANDY <trevor.sandy@gmail.com>
	/// November 05, 2017
	///
	/// LPub3D Ray Tracer ('LPub3D-Trace') version 3.8. is built
	/// specially for LPub3D - An LDraw Building Instruction Editor.
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
	/// Copyright 1991-2017 Persistence of Vision Raytracer Pty. Ltd which is,
	/// in turn, based on the popular DKB raytracer version 2.12.
	/// DKBTrace was originally written by David K. Buck.
	/// DKBTrace Ver 2.0-2.12 were written by David K. Buck & Aaron A. Collins.
	///
	//////////////////////////////////////////////////////

	/// Application Updates
	//////////////////////////////////////////////////////
	Updated Windows Console User Interface (CUI) LPub3D-Trace build, including:
	- Rename to LPub3D-Trace (respect license terms)
	- Port Unix CUI functionality to Windows project
	- SDL2 image display window (Using SDL2 v2.0.5 built from source)
	- Integrate SDL2 v2.0.5 library source to enable build from source
	- Options processor class
	- Benchmark, help and version options
	- Detailed console output_iterator
	- Uses povray.conf just as Unix build
	- Console signal management
	- GUI and CUI AppVeyor CI build check
	- Build CUI and GUI projects from the command line
	- Modify confa and ini file default directory locations
	- Additional little features...
	Updated Unix Console User Interface (CUI) LPub3D-Trace build, including:
	- Rename to LPub3D-Trace (respect license terms)
	- Quoted command line arguments allowign spaces in path names
	- Updated SDL library (Using SDL2 v2.0.5 built from source or system SDL2)
	- Integrate SDL2 v2.0.5 library source to enable build from source option
	- Cross compile i386 target on x86_64 host
	- Modify conf and ini file default directory locations
	- Travis CI CUI build check
	- Additional little features...

	/// Building the Console User Interface (VS2019 GUI)
	//////////////////////////////////////////////////////
	See README.md for comprehensive details on building POV-Ray.

	1. Open `windows\vs2015\povray.sln` in Visual Studio

	2. Set 'Windows Targets' > 'CUI(Visual Studio 2015)' as the start-up project

	3. Select the 'Generic POV-Ray > povbase (Visual Studio 2015)' project

		3a. enable the definition of `_CONSOLE` in	povbase > 'Base Headers' > syspovconfig.h
            (povray\windows\povconfig\syspovconfig.h) and 

        3b. Continuing in povbase > 'Base Headers' > syspovconfig.h, 
            add: 
                #ifndef VERSION_BASE
                #define VERSION_BASE "3.8"
                #endif // VERSION_BASE
            on the following 3 lines. 

		3c. Set `BUILT_BY` in povbase > 'Base Headers' > build.h
            (povray\source\base\build.h) to YOUR NAME (YOUR EMAIL)

		3d. Remark the `#error` directive after `BUILT_BY`

	4. Select 'Windows Targets' > 'CUI(Visual Studio 2015)' and launch 'Build CUI' (Ctrl+B)
       Using 'Build Solution' (Ctrl+Shift+B) will abend because Visual Studio will attempt 
       to build the 'GUI(Visual Studio 2015)' also.
	   
	5. NOTE: It goes without saying that you should reverse the updates described above 
	         before committing any changes.

	/// Building LPub3D-Trace from the command line (VS2017 MSBuild)
	//////////////////////////////////////////////////////
	See README.md for comprehensive details on building POV-Ray/LPub3D-Trace.

	This autobuild.cmd script uses MSBuild to configure and build LPub3D-Trace from the command line.
	The primary benefit is not having to modify source files before building
	as described in the official POV-Ray build documentation when building from Visual Studio GUI.
	Additionally, it is possible to build either the CUI or GUI project.

	1. Launch `windows\vs2015\autobuild.cmd -info` from command prompt to see usage info.

	2. Execute autobuild.cmd with appropriate flags as desired.

	/// Build success (VS2017 GUI and MSBuild)
	//////////////////////////////////////////////////////
    If all goes well, you should end up with the LPub3D-Trace for Windows
    executable. All 32-bit binaries should end up in
    `windows\vs2015\bin32`, and the 64-bit ones are in
    `windows\vs2015\bin64`.

	/// Building LPub3D-Trace from the command line (GCC Unix)
	//////////////////////////////////////////////////////
	See README.md for comprehensive details on building POV-Ray.

	/// File locations
    /////////////////////////////////////////////////////
	All Files

	The default locations for the povray conf, and INI, files are in the User Location.
	The default location for the scene, and include files are in the System Location

    The Windows Console User Interface build uses a file location
	architecture similar to that of the Unix build.

	- User Location:          %USERPROFILE%\AppData\Local\LPub3D Software\LPub3D\3rdParty\lpub3d_trace_cui-3.8\config
	- System Location x86_64: C:\Program Files\LPub3D\3rdParty\resources\lpub3d_trace_cui-3.8\config
	- System Location x86:    C:\Program Files(x86)\LPub3D\3rdParty\resources\lpub3d_trace_cui-3.8\config

	Note: The system location is actually the install path for LPub3D, therefore the drive letter
	and even te path name may be different on your installation. The value presented here shows
	the default LPub3D installation path.

    The Unix Console User Interface build uses a file location
	architecture similar to that of the POV-Ray build. The default
	locations for the povray conf, INI, scene, and include files are:

	- User Location MacOS:    $HOME/Library/Application Support/LPub3D Software/LPub3D/3rdParty/lpub3d_trace_cui-3.8/config
	- System Location MacOS:  /Applications/LPub3D.app/Contents/3rdParty/resources/lpub3d_trace_cui-3.8/config

	- User Location Linux:    $HOME/.local/share/LPub3D Software/LPub3D/3rdParty/lpub3d_trace_cui-3.8/config
	- System Location Linux:  /usr/share/lpub3d/3rdParty/resources/lpub3d_trace_cui-3.8/config

	There is no default location for the povray binary itself.
	However the LPub3D installation places the povray executable
	at the following locations:

	- MacOS:          /Applications/LPub3D.app/Contents/3rdParty/bin
	- Linux:          /opt/lpub3d/3rdParty/lpub3d_trace_cui-3.8/bin
	- Windows x86:    C:\Program Files(x86)\LPub3D\3rdParty\bin
	- Windows x86_64: C:\Program Files\LPub3D\3rdParty\bin

	Documentation and other resource files are places at the
	{System Location}/docs and {System Location}/resources respectively.

	At this moment default locations are fixed (hard-coded).
	However all locations, except that for povray.conf, can be defined
	in the povray.conf file and; therefore, can be placed wherever
	you like as long as their path is defined in povray.conf

	INI Files

	LPub3D-Trace allows the use of INI files to store common configuration
	settings, such as the output format, image size, and library paths.
	Upon startup, LPub3D-Trace Console User Interface will use the environment
	variable POVINI to determine custom configuration information if
	that environment variable is set.  Otherwise, it will look for the
	file "povray.ini" in the current directory.  If neither of these are
	set, LPub3D-Trace will try to read the user "povray.ini" file (located under
	{User Location}\ini) or, otherwise, the system-level "povray.ini" (by
	default in {User Location}\ini).

	CONF File

	LPub3D-Trace CUI build include the I/O Restriction feature as an attempt
	to at least partially protect a machine running the program to perform
	forbidden file operation and/or run external programs.  I/O Restriction
	settings are specified in a "povray.conf" configuration file.  There are
	two configuration levels within LPub3D-Trace CUI: a system and a user-
	level configuration.  The system-level povray.conf file (by default in
	{System Location}) is intended for system administrators to set up minimal
	restrictions for the system on which LPub3D-Trace will run. The user povray.conf
	file (under {User Location}) allows further restrictions to be set. For
	obvious security reasons, the user's settings can only be more (or equally)
	restrictive than the system-level settings. The administrator must take
	responsibility to secure the system location as appropriate.

	/// Updated source files
    /////////////////////////////////////////////////////
	0.  .gitignore.............../
	1.  povray.cpp.............../source/backend
	2.  povray.conf............../distribution......(New)
	3.  povray.ini.............../distribution/ini
    4.  processrenderoptions.cpp./source/frontend
	5.  renderfrontend.cpp       /source/frontend
	6.	povmsid.h................/source/povms
	7.	vfe.h..................../vfe
	8.	vfedisplay.cpp.........../vfe

	Windows
	 9.  appveyor.yml............/
	10.  console.vcxproj........./windows/vs2015
    11.  console.vcxproj.filters./windows/vs2015
    12.  vfewin.vcxproj........../windows/vs2015
    13.  vfewin.vcxproj.filters../windows/vs2015
    14.  openexr_eLut.vcxproj..../windows/vs2015
	15. openexr_toFloat.vcxproj../windows/vs2015
	16. povray.sln.............../windows/vs2015
	17. povbackend.vcxproj......./windows/vs2015	
	18. autobuild.cmd............/windows/vs2015.........(New)
	19. autobuild_defs.cmd......./windows/vs2015.........(New)
	20. SDL2.vcxproj............./windows/vs2015.........(New)
	21. SDL2_vcxproj.filters...../windows/vs2015.........(New)
	22. SDL2Main.vcxproj........./windows/vs2015.........(New)	
	23. console.ico............../windows/vs2015.........(New)
	24. console_resource.rc....../windows/vs2015.........(New)
	25. csi.ldr.pov............../windows/vs2015/tests/..(New)
	26. test.cmd................./windows/vs2015/tests/..(New)
	27. biscuit.pov............../windows/vs2015/tests/space in dir name test/..(New)
	28. syspovconfig.h.........../windows/povconfig
	29. vfeplatform.cpp........../vfe/win
	30. vfeplatform.h............/vfe/win
	31. winconsole.cpp.........../vfe/win/console
	32. winoptions.cpp.........../vfe/win/console...(New)
	33. winoptions.h............./vfe/win/console...(New)
	34. disp.h.................../windows...........(New)
	35. disp_sdl.cpp............./windows...........(New)
	36. disp_sdl.h.............../windows...........(New)
	37. disp_text.h............../windows...........(New)
	38. disp_text.cpp............/windows...........(New)
	39. CUI_README.txt.........../windows...........(New)
	
	Unix
	40. travis.yml.............../
	41. prebuild3rdparty.sh....../unix..............(New) replaces prebuild.sh
	42. configure.ac............./unix
	43. install................../unix
	44. syspovconfig.h.........../unix
	45. disp_sdl.cpp............./unix
	46. disp_sdl.h.............../unix
	47. disp_text.cpp............/unix
	48. disp_text.h............../unix	
	49. acx_pthread.m4.........../unix/config
	50. ax_check_lib.m4........../unix/config
	51. ax_check_libjpeg.m4....../unix/config
	52. ax_check_libtiff.m4....../unix/config
	53. ax_check_libsdl2.m4....../unix/config.......(New) replaces ax_check_libsdl.m4
	54. unixconsole.cpp........../vfe/unix
	55. unixoptions.cpp........../vfe/unix
	56. unixoptions.h............/vfe/unix

    Libraries
	57. sdl2...................../libraries/sdl2.....................(New)
	58. boost::interprocess....../libraries/boost/boost/interprocess.(New)
		
	Note: Although I used VS2017 to develop the Windows Console User Interface build
	components described here. I do not believe there is any material difference
	between VS2017 and VS2015 so you can substitute VS2017 for 2015.

	Please send any comments or corrections to Trevor SANDY <trevor.sandy@gmail.com>

	/// Sample povray.conf and povray.ini files
    /////////////////////////////////////////////////////
	The sample files below are configured for Windows x86_64. You may
	substitute the {System Location} and {User Location} paths above to
	configure for MacOS or Linux targets.

	/// Sample conf file
    /////////////////////////////////////////////////////
	Here are the conf file options (cut and paste to create your povray.conf file):

	;                         LPUB3D_TRACE RAY TRACER
	;
	;                         LPub3d_Trace VERSION 3.8
	;                             POVRAY.CONF FILE
	;                       FOR I/O RESTRICTIONS SETTINGS
	;
	; The general form of the conf file option is:
	;
	; [Section]
	; setting
	;
	; Note: characters after a semi-colon are treated as a comment.
	;

	; [File I/O Security] determines whether LPub3D-Trace will be allowed to perform
	; read-write operations on files.  Specify one of the 3 following values:
	; - "none" means that there are no restrictions other than those enforced
	;   by the file system, i.e. normal file and directory permissions.
	; - "read-only" means that files may be read without restriction.
	; - "restricted" means that files access is subject to restrictions as
	;   specified in the rest of this file. See the other variables for details.

	[File I/O Security]
	;none       ; all read and write operations on files are allowed.
	;read-only  ; uses the "read+write" directories for writing (see below).
	restricted  ; uses _only_ "read" and "read+write" directories for file I/O.

	; [Shellout Security] determines whether LPub3D-Trace will be allowed to call
	; scripts (e.g. Post_Frame_Command) as specified in the documentation.
	; Specify one of the 2 following values:
	; - "allowed" means that shellout will work as specified in the documentation.
	; - "forbidden" means that shellout will be disabled.

	[Shellout Security]
	;allowed
	forbidden

	; [Permitted Paths] specifies a list of directories for which reading or
	; reading + writing is permitted (in those directories and optionally
	; in their descendants).  Any entry of the directory list is specified on
	; a single line.  These paths are only used when the file I/O security
	; is enabled (i.e. "read-only" or "restricted").
	;
	; The list entries must be formatted as following:
	;   read = directory	     ; read-only directory
	;   read* = directory        ; read-only directory including its descendants
	;   read+write = directory   ; read/write directory
	;   read+write* = directory  ; read/write directory including its descendants
	; where directory is a string (to be quoted or doubly-quoted if it contains
	; space characters; see the commented example below).  Any number of spaces
	; can be placed before and after the equal sign.  Read-only and read/write
	; entries can be specified in any order.
	;
	; Both relative and absolute paths are possible (which makes "." particularly
	; useful for defining the current working directory).  The LPub3D-Trace install
	; directory is designated as the {System Location}) and
	; can be specified with "%INSTALLDIR%".  You should not specify
	; "%INSTALLDIR%" in read/write directory paths.  The user home (%USERPROFILE%)
	; directory can be specified with "%HOME%".
	;
	; Note that since user-level restrictions are at least as strict as system-
	; level restrictions, any paths specified in the system-wide povray.conf
	; will also need to be specified in the user povray.conf file.

	[Permitted Paths]
	; You can set permitted paths to control where LPub3D-Trace can access content.
	; To enable remove the preceding ';'.

	; Default (hard coded) paths:
	; HOME        = C:\Users\<user> (%USERPROFILE%)
	; INSTALLDIR  = C:\Program Files (x86)\LPub3D\3rdParty\resources\lpub3d_trace_cui-3.8
	; SYSCONF     = C:\Program Files (x86)\LPub3D\3rdParty\resources\lpub3d_trace_cui-3.8\config\povray.conf
	; USERCONF    = %HOME%\AppData\Local\LPub3D Software\LPub3D\3rdParty\lpub3d_trace_cui-3.8\config\povray.conf
	; SYSINI      = C:\Program Files (x86)\LPub3D\3rdParty\resources\lpub3d_trace_cui-3.8\config\povray.ini
	; USERINI     = %HOME%\AppData\Local\LPub3D Software\LPub3D\3rdParty\lpub3d_trace_cui-3.8\config\povray.ini
	;

	; This example shows how to qualify path names containing space(s):
	; read = "C:\this\directory\contains space characters"

	; You can use %HOME%, %INSTALLDIR% and the current working directory as the origin to define permitted paths:

	; %HOME% is hard-coded to the %USERPROFILE% environment variable.
	read* = "%HOME%\AppData\Local\LPub3D Software\LPub3D\3rdParty\lpub3d_trace_cui-3.8\config"

	read* = "%HOME%\Projects\build-LPub3D-Desktop_Qt_5_7_1_MinGW_32bit-Debug\mainApp\debug\3rdParty\lpub3d_trace_cui-3.8\resources\include"
	read* = "%HOME%\Projects\build-LPub3D-Desktop_Qt_5_7_1_MinGW_32bit-Debug\mainApp\debug\3rdParty\lpub3d_trace_cui-3.8\resources\ini"
	read* = "%HOME%\LDraw\lgeo\ar"
	read* = "%HOME%\LDraw\lgeo\lg"
	read* = "%HOME%\LDraw\lgeo\stl"

	; %INSTALLDIR% is hard-coded to the default LPub3D installation path - see default paths above.

	; The current working directory is where LPub3D-Trace is called from.
	read* = "..\..\distribution\ini"
    read* = "..\..\distribution\include"
    read* = "..\..\distribution\scenes"

	read+write* = .

	; End povray conf file

	/// Sample ini file
    /////////////////////////////////////////////////////
	Here are the INI file options for the conf file above (cut and paste to create your povray.ini file(s)):

	;                         LPUB3D-TRACE RAY TRACER
	;
	;                         LPUB3D-TRACE VERSION 3.8
	;
	;                          LPUB3D-TRACE.INI FILE
	;
	;  The general form of the options is "Variable=value".  Everything
	;  between the equals sign and the end of the line is considered part
	;  of the value.  The spacing and layout is free-form but only one option
	;  per line is allowed.  Variables and values are not case-sensitive.
	;
	;  Note: characters after a semi-colon are treated as a comment
	;
	;  Traditional POV-Ray switches beginning with + or - are also allowed
	;  and they may be given with more than one switch per line.
	;
	;  Add your own options at the bottom and/or edit these to suit. See the
	;  general documentation for full instructions on how to use INI options.
	;
	; Width of image in pixels.  Accepts integer values.
	;
	Width = 800
	;
	;
	; Height of image in pixels.  Accepts integer values.
	;
	Height = 600
	;
	; Sets minimum number of objects before auto bounding kicks in.
	;
	Bounding_Threshold = 3
	;
	;
	; Turn display on
	Display=On
	;
	; Turn verbose mode on
	Verbose=On
	;
	;
	; Specify path to search for any files not found in current directory.
	; For example: Library_Path="C:\Program Files\POV-Ray for Windows\include"
	; There may be some entries already here; if there are they were
	; probably added by the install process or whoever set up the
	; software for you. At the least you can expect an entry that
	; points to the standard POV-Ray include files directory; on
	; some operating systems there may also be one which points to
	; the system's fonts directory.
	;
	; Note that some platforms (e.g. Windows, unless this feature is
	; turned off via the configuration file) will automatically append
	; standard locations like those mentioned above to the library
	; path list after reading this file, so in those cases you don't
	; necessarily have to have anything at all here.
	;
	; Search path for #include source files or command line ini files not
	; found in the current directory.  New directories are added to the
	; search path, up to a maximum of 25.
	;
	;

	; Search path for #include source files or command line ini files not
	; found in the current directory.  New directories are added to the
	; search path, up to a maximum of 25.

	Library_Path="C:\Program Files\LPub3D\3rdParty\lpub3d_trace_cui-3.8\resources"
	Library_Path="C:\Program Files\LPub3D\3rdParty\lpub3d_trace_cui-3.8\resources\ini"
	Library_Path="C:\Program Files\LPub3D\3rdParty\lpub3d_trace_cui-3.8\resources\include"

	; File output type control.
	;     T    Uncompressed Targa-24
	;     C    Compressed Targa-24
	;     P    UNIX PPM
	;     N    PNG (8-bits per colour RGB)
	;     Nc   PNG ('c' bit per colour RGB where 5 <= c <= 16)

	Output_to_File=true
	Output_File_Type=N8             ; (+/-Ftype)
