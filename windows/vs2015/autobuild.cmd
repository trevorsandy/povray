@ECHO OFF &SETLOCAL

Title LPub3D-Trace on Windows auto build script

rem This script uses MSBuild to configure and build LPub3D-Trace from the command line.
rem The primary benefit is not having to modify source files before building
rem as described in the official POV-Ray build documentation.
rem It is possible to build either the GUI or CUI project - see usage below.

rem This script is requires autobuild_defs.cmd
rem --
rem  Trevor SANDY <trevor.sandy@gmail.com>
rem  Last Update: September 26, 2017
rem  Copyright (c) 2017 by Trevor SANDY
rem --
rem This script is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

rem It is expected that this script will reside in .\windows\vs2015

rem Static defaults
IF "%APPVEYOR%" EQU "True" (
	IF [%POV_DIST_DIR%] == [] (
		ECHO.
	  ECHO  -ERROR: Distribution directory not defined.
	  ECHO  -%~nx0 terminated!
	  GOTO :END
	)
	rem If Appveyor, do not show the image display window
	SET DISP_WIN=-d
	rem deposit archive folder top build-folder
	SET DIST_DIR_ROOT=%POV_DIST_DIR%
) ELSE (
  SET DISP_WIN=+d
	SET DIST_DIR_ROOT=..\..\..\lpub3d_windows_3rdparty
)
SET PACKAGE=lpub3d_trace_cui
SET DEFAULT_PLATFORM=x64
SET VERSION_BASE=3.8
SET DEBUG=0

rem Build checks settings - set according to your check requirements - do not add quotes
rem Check 01
rem ------------------------------------------
rem SET BUILD_CHK_POV_FILE=..\..\distribution\scenes\advanced\biscuit.pov
rem SET BUILD_CHK_MY_OUTPUT=..\..\distribution\scenes\advanced\biscuit
rem SET BUILD_CHK_MY_PARMS=-f +d +p +v +a0.3 +UA +A +w320 +h240
rem SET BUILD_CHK_MY_INCLUDES=

rem Check 02
rem ------------------------------------------
rem SET BUILD_CHK_MY_POV_FILE=tests\csi.ldr.pov
rem SET BUILD_CHK_MY_OUTPUT=tests\csi.ldr
rem SET BUILD_CHK_MY_PARMS=+d +a0.3 +UA +A +w2549 +h1650
rem SET BUILD_CHK_MY_INCLUDES=+L%USERPROFILE%\LDraw\lgeo\ar +L%USERPROFILE%\LDraw\lgeo\lg +L%USERPROFILE%\LDraw\lgeo\stl

rem Check 03
rem ------------------------------------------
SET BUILD_CHK_MY_POV_FILE=tests\space in dir name test\biscuit.pov
SET BUILD_CHK_MY_OUTPUT=tests\space in dir name test\biscuit space in file name test
SET BUILD_CHK_MY_PARMS=%DISP_WIN% -p +a0.3 +UA +A +w320 +h240
SET BUILD_CHK_MY_INCLUDES=

rem Build check static settings - do not modify these.
SET BUILD_CHK_OUTPUT=%BUILD_CHK_MY_OUTPUT%
SET BUILD_CHK_POV_FILE=%BUILD_CHK_MY_POV_FILE%
SET BUILD_CHK_PARAMS=%BUILD_CHK_MY_PARMS%
SET BUILD_CHK_INCLUDE=+L"..\..\distribution\ini" +L"..\..\distribution\include" +L"..\..\distribution\scenes"
SET BUILD_CHK_INCLUDE=%BUILD_CHK_INCLUDE% %BUILD_CHK_MY_INCLUDES%

rem Visual Studio 'debug' comand line: +I"tests\space in dir name test\biscuit.pov" +O"tests\space in dir name test\biscuit space in file name test.png" +w320 +h240 +d -p +a0.3 +UA +A +L"..\..\distribution\ini" +L"..\..\distribution\include" +L"..\..\distribution\scenes"

SET CONFIGURATION=unknown
SET PLATFORM=unknown
SET PROJECT=unknown
SET CONSOLE=unknown
SET VERBOSE=unknown
SET REBUILD=unknown
SET CHECK=unknown

IF %DEBUG%==1 (
	SET d=d
	SET DEFAULT_CONFIGURATION=Debug
) ELSE (
  SET d=
  SET DEFAULT_CONFIGURATION=Release
)

rem Check if invalid platform flag
IF NOT [%1]==[] (
	IF NOT "%1"=="x86" (
		IF NOT "%1"=="x86_64" (
			IF NOT "%1"=="-allcui" (
				IF NOT "%1"=="-run" (
					IF NOT "%1"=="-rbld" (
						IF NOT "%1"=="-verbose" (
							IF NOT "%1"=="-help" GOTO :PLATFORM_ERROR
						)
					)
				)
			)
		)
	)
)
rem Parse platform input flag
IF [%1]==[] (
	SET PLATFORM=-allcui
	GOTO :SET_CONFIGURATION
)
IF /I "%1"=="x86" (
	SET PLATFORM=Win32
	GOTO :SET_CONFIGURATION
)
IF /I "%1"=="x86_64" (
	SET PLATFORM=x64
	GOTO :SET_CONFIGURATION
)
IF /I "%1"=="-allcui" (
	SET PLATFORM=-allcui
	GOTO :SET_CONFIGURATION
)
IF /I "%1"=="-run" (
	GOTO :SET_CONFIGURATION
)
IF /I "%1"=="-rbld" (
	SET PLATFORM=-allcui
	GOTO :SET_CONFIGURATION
)
IF /I "%1"=="-verbose" (
	GOTO :SET_CONFIGURATION
)
IF /I "%1"=="-help" (
	GOTO :USAGE
)
rem If we get here display invalid command message.
GOTO :COMMAND_ERROR

:SET_CONFIGURATION
rem Check if invalid configuration flag
IF NOT [%2]==[] (
	IF NOT "%2"=="-rel" (
		IF NOT "%2"=="-dbg" (
			IF NOT "%2"=="-avx" (
				IF NOT "%2"=="-ins" (
					IF NOT "%2"=="-allins" (
						IF NOT "%2"=="-chk" (
							IF NOT "%2"=="-run" (
								IF NOT "%2"=="-rbld" (
									IF NOT "%2"=="-sse2" GOTO :CONFIGURATION_ERROR
								)
							)
						)
					)
				)
			)
		)
	)
)
rem  Set the default platform
IF "%PLATFORM%"=="unknown" (
	SET PLATFORM=%DEFAULT_PLATFORM%
)
rem Run a render check without building
IF /I "%1"=="-run" SET RUN_CHK=true
IF /I "%2"=="-run" SET RUN_CHK=true
IF /I "%RUN_CHK%"=="true" (
	SET CONFIGURATION=run render only
	CALL :CHECK_BUILD %PLATFORM%
	rem Finish
	EXIT /b
)
rem Perform verbose (debug) build
IF "%1"=="-verbose" (
	SET CHECK=1
	SET THIRD_INSTALL=0
	SET INSTALL_ALL=0
	SET CONFIGURATION=%DEFAULT_CONFIGURATION%
	GOTO :BUILD
)
rem Parse configuration input flag
IF /I "%1"=="-rbld" SET REBUILD_CHK=true
IF /I "%2"=="-rbld" SET REBUILD_CHK=true
IF /I "%REBUILD_CHK%"=="true" (
	SET REBUILD=1
	SET CHECK=1
	SET THIRD_INSTALL=1
	SET INSTALL_ALL=0
	SET CONFIGURATION=%DEFAULT_CONFIGURATION%
	GOTO :BUILD
)
rem Check if release build
IF /I "%2"=="-rel" (
	SET CONFIGURATION=Release
	GOTO :BUILD
)
rem Check if debug build
IF /I "%2"=="-dbg" (
	SET CONFIGURATION=Debug
	GOTO :BUILD
)
rem Check if install - reset configuration
IF /I "%2"=="-ins" (
	rem 3rd party install
	SET THIRD_INSTALL=1
	SET INSTALL_ALL=0
	SET CONFIGURATION=%DEFAULT_CONFIGURATION%
	GOTO :BUILD
)
rem Install all content
IF /I "%2"=="-allins" (
	rem 3rd party install
	SET THIRD_INSTALL=1
	SET INSTALL_ALL=1
	SET CONFIGURATION=%DEFAULT_CONFIGURATION%
	GOTO :BUILD
)
rem Build and run an image render check
IF /I "%2"=="-chk" (
	SET CHECK=1
	SET CONFIGURATION=%DEFAULT_CONFIGURATION%
	GOTO :BUILD
)
rem Parse configuration input flag
IF [%2]==[] (
	SET CHECK=1
	SET THIRD_INSTALL=1
	SET INSTALL_ALL=0
	SET CONFIGURATION=%DEFAULT_CONFIGURATION%
	GOTO :BUILD
)
rem Check if x86_64 and AVX
IF "%PLATFORM%"=="x64" (
	IF /I "%2"=="-avx" GOTO :SET_AVX
)
rem Check if x86 and SSE2
IF "%PLATFORM%"=="Win32" (
	IF /I "%2"=="-sse2" GOTO :SET_SSE2
)
rem Check if bad platform and configuration flag combination
IF "%PLATFORM%"=="Win32" (
	IF /I "%2"=="-avx" GOTO :AVX_ERROR
)
IF "%PLATFORM%"=="x64" (
	IF /I "%2"=="-sse2" GOTO :SSE2_ERROR
)
rem If we get here display invalid command message
GOTO :COMMAND_ERROR

:SET_AVX
rem AVX Configuration
SET CONFIGURATION=Release-AVX
GOTO :BUILD

:SET_SSE2
rem SSE2 Configuration
SET CONFIGURATION=Release-SSE2
GOTO :BUILD

:BUILD
rem Configure build parameters
SET DO_REBUILD=
SET BUILD_LBL=Building
IF %REBUILD%==1 (
	SET DO_REBUILD=/t:Rebuild
	SET BUILD_LBL=Rebuilding
)
rem Check if invalid console flag
IF NOT [%3]==[] (
	IF NOT "%3"=="-gui" (
		IF NOT "%3"=="-cui" GOTO :PROJECT_ERROR
	)
)
rem Build CUI or GUI project - CUI is default
rem Parse configuration input flag
IF [%3]==[] (
	SET CONSOLE=1
	SET PROJECT=console.vcxproj
)
IF /I "%3"=="-gui" (
	SET CONSOLE=0
	SET PROJECT=povray.sln
)
IF /I "%3"=="-cui" (
	SET CONSOLE=1
	SET PROJECT=console.vcxproj
)
rem Check if invalid verbose flag
IF NOT [%4]==[] (
	IF NOT "%4"=="-verbose" GOTO :VERBOSE_ERROR
)
rem Enable verbose tracing (useful for debugging)
IF /I "%1"=="-verbose" SET VERBOSE_CHK=true
IF /I "%4"=="-verbose" SET VERBOSE_CHK=true
IF "%CONFIGURATION%"=="Debug" SET VERBOSE_CHK=true
IF /I "%VERBOSE_CHK%"=="true" (
	rem Check if CUI or allCUI project build
	IF NOT %CONSOLE%==1 (
		IF NOT "%PLATFORM%"=="-allcui" GOTO :VERBOSE_CUI_ERROR
	)
	SET VERBOSE=1
) ELSE (
	SET VERBOSE=0
)
rem Initialize the Visual Studio command line development environment
rem Note you can change this line to your specific environment - I am using VS2017 here.
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\VsDevCmd.bat"
rem Set the LPub3D-Trace auto-build pre-processor defines
CALL autobuild_defs.cmd
rem Display the defines set (as environment variable 'PovBuildDefs') for MSbuild
ECHO.
ECHO   BUILD_DEFINES.....[%PovBuildDefs%]

rem Display build project message
CALL :PROJECT_MESSAGE %CONSOLE%

rem Display verbosity message
CALL :VERBOSE_MESSAGE %VERBOSE%

rem Console logging flags (see https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference)
rem SET LOGGING=/clp:ErrorsOnly /nologo
CALL :DISPLAY_ERRRORS_ONLY_MESSAGE
SET LOGGING=/clp:ErrorsOnly

rem Check if build all platforms
IF /I "%PLATFORM%"=="-allcui" (
	SET CONSOLE=1
	SET PROJECT=console.vcxproj
	SET CONFIGURATION=%DEFAULT_CONFIGURATION%
	GOTO :BUILD_ALL_CUI
)

rem Assemble command line
SET COMMAND_LINE=msbuild /m /p:Configuration=%CONFIGURATION% /p:Platform=%PLATFORM% %PROJECT% %LOGGING% %DO_REBUILD%
ECHO   BUILD_COMMAND.....[%COMMAND_LINE%]
rem Display the build configuration and platform settings
ECHO.
ECHO -%BUILD_LBL% %CONFIGURATION% Configuration for %PLATFORM% Platform...
ECHO.
rem Launch msbuild
%COMMAND_LINE%
rem Perform build check if specified
IF %CHECK%==1 CALL :CHECK_BUILD %PLATFORM%
rem Finish
EXIT /b

:BUILD_ALL_CUI
rem Display the build configuration and platform settings
ECHO.
ECHO -%BUILD_LBL% all CUI Platforms for %CONFIGURATION% Configuration...
rem Launch msbuild across all CUI platform builds
FOR %%P IN ( Win32, x64 ) DO (
	SETLOCAL ENABLEDELAYEDEXPANSION
	rem Assemble command line
	SET COMMAND_LINE=msbuild /m /p:Configuration=%CONFIGURATION% /p:Platform=%%P %PROJECT% %LOGGING% %DO_REBUILD%
	ECHO.
	ECHO --%BUILD_LBL% %%P Platform...
	ECHO.
	ECHO   BUILD_COMMAND.....[!COMMAND_LINE!]
	ECHO.
	rem Launch msbuild
	!COMMAND_LINE!
	rem Perform build check if specified
	IF %CHECK%==1 CALL :CHECK_BUILD %%P
	IF "%APPVEYOR%" EQU "True" CALL :CHECK_BUILD %%P
	ENDLOCAL
)
rem Perform 3rd party install if specified
IF %THIRD_INSTALL%==1 GOTO :3RD_PARTY_INSTALL
rem Finish
EXIT /b

:3RD_PARTY_INSTALL
rem Version major and minor pulled in from autobuild_defs
SET VERSION_BASE=%VERSION_MAJ%.%VERSION_MIN%
ECHO.
ECHO -Copying 3rd party distribution files...
ECHO.
ECHO -Copying %PACKAGE%32%d%.exe...
IF NOT EXIST "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\bin\i386\" (
	MKDIR "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\bin\i386\"
)
COPY /V /Y "bin32\%PACKAGE%32%d%.exe" "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\bin\i386\" /B

ECHO -Copying %PACKAGE%64%d%.exe...
IF NOT EXIST "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\bin\x86_64\" (
	MKDIR "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\bin\x86_64\"
)
COPY /V /Y "bin64\%PACKAGE%64%d%.exe" "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\bin\x86_64\" /B

IF  %INSTALL_ALL% == 1  ECHO -Copying Documentaton...
IF NOT EXIST "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\docs\" (
	IF  %INSTALL_ALL% == 1 MKDIR "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\docs\"
)
IF  %INSTALL_ALL% == 1  SET DIST_DIR=%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\docs
IF  %INSTALL_ALL% == 1  SET DIST_SRC="..\..\distribution\platform-specific\windows"
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\CUI_README.txt" "%DIST_DIR%" /A
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\..\LICENSE" "%DIST_DIR%\LICENSE.txt" /A
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\..\changes.txt" "%DIST_DIR%\ChangeLog.txt" /A
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\..\unix\AUTHORS" "%DIST_DIR%\AUTHORS.txt" /A
IF  %INSTALL_ALL% == 1  XCOPY /Q /S /I /E /V /Y "%DIST_SRC%\Help" "%DIST_DIR%\help"
REM IF  %INSTALL_ALL% == 1  XCOPY /Q /S /I /E /V /Y "..\..\doc\html" "%DIST_DIR%\html"
IF  %INSTALL_ALL% == 1  ECHO -Copying Resources...
IF NOT EXIST "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\resources\" (
	IF  %INSTALL_ALL% == 1  MKDIR "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\resources\"
)
IF  %INSTALL_ALL% == 1  SET DIST_DIR=%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\resources
IF  %INSTALL_ALL% == 1  ECHO -Copying Include scripts...
IF  %INSTALL_ALL% == 1  XCOPY /Q /S /I /E /V /Y "..\..\distribution\include" "%DIST_DIR%\include"
IF  %INSTALL_ALL% == 1  ECHO -Copying Initialization files...
IF  %INSTALL_ALL% == 1  XCOPY /Q /S /I /E /V /Y "..\..\distribution\ini" "%DIST_DIR%\ini"
REM IF  %INSTALL_ALL% == 1  XCOPY /Q /S /I /E /V /Y "%DIST_SRC%\Icons" "%DIST_DIR%\Icons"
REM IF  %INSTALL_ALL% == 1  XCOPY /Q /S /I /E /V /Y "..\..\distribution\scenes" "%DIST_DIR%\scenes"

SET __POVUSERDIR__=AppData\Local\LPub3D Software\LPub3D\3rdParty\%PACKAGE%-%VERSION_BASE%
SET __HOME__=%%USERPROFILE%%

ECHO -Copying x86_64 (64bit) .Conf and .Ini files...
IF NOT EXIST "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\resources\config\x86_64\" (
	MKDIR "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\resources\config\x86_64\"
)
SET DIST_DIR=%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\resources\config\x86_64
SET __POVSYSDIR__=C:\Program Files\LPub3D\3rdParty\%PACKAGE%-%VERSION_BASE%
COPY /V /Y "..\..\distribution\povray.conf" "%DIST_DIR%\povray.conf" /A
SET genConfigFile="%DIST_DIR%\povray.conf" ECHO
:GENERATE x86_64 povray.conf settings file
>>%genConfigFile%.
>>%genConfigFile%  ; Default (hard coded) paths:
>>%genConfigFile%  ; HOME        = %__HOME__%
>>%genConfigFile%  ; INSTALLDIR  = %__POVSYSDIR__%
>>%genConfigFile%  ; SYSCONF     = %__POVSYSDIR__%\resources\config\povray.conf
>>%genConfigFile%  ; SYSINI      = %__POVSYSDIR__%\resources\config\povray.ini
>>%genConfigFile%  ; USERCONF    = %%HOME%%\%__POVUSERDIR__%\config\povray.conf
>>%genConfigFile%  ; USERINI     = %%HOME%%\%__POVUSERDIR__%\config\povray.ini
>>%genConfigFile%.
>>%genConfigFile%  ; This example shows how to qualify path names containing space(s):
>>%genConfigFile%  ; read = "%%HOME%%\this\directory\contains space characters"
>>%genConfigFile%.
>>%genConfigFile%  ; You can use %%HOME%%, %%INSTALLDIR%% and $PWD (working directory) as the origin to define permitted paths:
>>%genConfigFile%.
>>%genConfigFile%  ; %%HOME%% is hard-coded to the $USER environment variable.
>>%genConfigFile%  read* = "%%HOME%%\%__POVUSERDIR__%\config"
>>%genConfigFile%.
>>%genConfigFile%  read* = "%__POVSYSDIR__%\resources\include"
>>%genConfigFile%  read* = "%__POVSYSDIR__%\resources\ini"
>>%genConfigFile%  read* = "%%HOME%%\LDraw\lgeo\ar"
>>%genConfigFile%  read* = "%%HOME%%\LDraw\lgeo\lg"
>>%genConfigFile%  read* = "%%HOME%%\LDraw\lgeo\stl"
>>%genConfigFile%.
>>%genConfigFile%  ; %%INSTALLDIR%% is hard-coded to the default LPub3D installation path - see default paths above.
>>%genConfigFile%.
>>%genConfigFile%  ; The $PWD (working directory) is where LPub3D-Trace is called from.
>>%genConfigFile%  read* = "..\..\distribution\ini"
>>%genConfigFile%  read* = "..\..\distribution\include"
>>%genConfigFile%  read* = "..\..\distribution\scenes"
>>%genConfigFile%.
>>%genConfigFile%  read+write* = .
COPY /V /Y "..\..\distribution\ini\povray.ini" "%DIST_DIR%\povray.ini" /A
SET genConfigFile="%DIST_DIR%\povray.ini" ECHO
:GENERATE x86_64 povray.ini settings file
>>%genConfigFile%.
>>%genConfigFile%  ; Search path for #include source files or command line ini files not
>>%genConfigFile%  ; found in the current directory.  New directories are added to the
>>%genConfigFile%  ; search path, up to a maximum of 25.
>>%genConfigFile%.
>>%genConfigFile%  Library_Path="%__POVSYSDIR__%\resources"
>>%genConfigFile%  Library_Path="%__POVSYSDIR__%\resources\ini"
>>%genConfigFile%  Library_Path="%__POVSYSDIR__%\resources\include"
>>%genConfigFile%.
>>%genConfigFile%  ; File output type control.
>>%genConfigFile%  ;     T    Uncompressed Targa-24
>>%genConfigFile%  ;     C    Compressed Targa-24
>>%genConfigFile%  ;     P    UNIX PPM
>>%genConfigFile%  ;     N    PNG (8-bits per colour RGB)
>>%genConfigFile%  ;     Nc   PNG ('c' bit per colour RGB where 5 ^<= c ^<= 16)
>>%genConfigFile%.
>>%genConfigFile%  Output_to_File=true
>>%genConfigFile%  Output_File_Type=N8             ; (+/-Ftype)

ECHO -Copying x86 (32bit) .Conf and .Ini files...
IF NOT EXIST "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\resources\config\i386\" (
	MKDIR "%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\resources\config\i386\"
)
SET DIST_DIR=%DIST_DIR_ROOT%\%PACKAGE%-%VERSION_BASE%\resources\config\i386
SET __POVSYSDIR__=C:\Program Files (x86)\LPub3D\3rdParty\%PACKAGE%-%VERSION_BASE%
COPY /V /Y "..\..\distribution\povray.conf" "%DIST_DIR%\povray.conf" /A
SET genConfigFile="%DIST_DIR%\povray.conf" ECHO
:GENERATE i386 povray.conf settings file
>>%genConfigFile%.
>>%genConfigFile%  ; Default (hard coded) paths:
>>%genConfigFile%  ; HOME        = %__HOME__%
>>%genConfigFile%  ; INSTALLDIR  = %__POVSYSDIR__%
>>%genConfigFile%  ; SYSCONF     = %__POVSYSDIR__%\resources\config\povray.conf
>>%genConfigFile%  ; SYSINI      = %__POVSYSDIR__%\resources\config\povray.ini
>>%genConfigFile%  ; USERCONF    = %%HOME%%\%__POVUSERDIR__%\config\povray.conf
>>%genConfigFile%  ; USERINI     = %%HOME%%\%__POVUSERDIR__%\config\povray.ini
>>%genConfigFile%.
>>%genConfigFile%  ; This example shows how to qualify path names containing space(s):
>>%genConfigFile%  ; read = "%%HOME%%\this\directory\contains space characters"
>>%genConfigFile%.
>>%genConfigFile%  ; You can use %%HOME%%, %%INSTALLDIR%% and $PWD (working directory) as the origin to define permitted paths:
>>%genConfigFile%.
>>%genConfigFile%  ; %%HOME%% is hard-coded to the $USER environment variable.
>>%genConfigFile%  read* = "%%HOME%%\%__POVUSERDIR__%\config"
>>%genConfigFile%.
>>%genConfigFile%  read* = "%__POVSYSDIR__%\resources\include"
>>%genConfigFile%  read* = "%__POVSYSDIR__%\resources\ini"
>>%genConfigFile%  read* = "%%HOME%%\LDraw\lgeo\ar"
>>%genConfigFile%  read* = "%%HOME%%\LDraw\lgeo\lg"
>>%genConfigFile%  read* = "%%HOME%%\LDraw\lgeo\stl"
>>%genConfigFile%.
>>%genConfigFile%  ; %%INSTALLDIR%% is hard-coded to the default LPub3D installation path - see default paths above.
>>%genConfigFile%.
>>%genConfigFile%  ; The $PWD (working directory) is where LPub3D-Trace is called from.
>>%genConfigFile%  read* = "..\..\distribution\ini"
>>%genConfigFile%  read* = "..\..\distribution\include"
>>%genConfigFile%  read* = "..\..\distribution\scenes"
>>%genConfigFile%.
>>%genConfigFile%  read+write* = .
COPY /V /Y "..\..\distribution\ini\povray.ini" "%DIST_DIR%\povray.ini" /A
SET genConfigFile="%DIST_DIR%\povray.ini" ECHO
:GENERATE i386 povray.ini settings file
>>%genConfigFile%.
>>%genConfigFile%  ; Search path for #include source files or command line ini files not
>>%genConfigFile%  ; found in the current directory.  New directories are added to the
>>%genConfigFile%  ; search path, up to a maximum of 25.
>>%genConfigFile%.
>>%genConfigFile%  Library_Path="%__POVSYSDIR__%\resources"
>>%genConfigFile%  Library_Path="%__POVSYSDIR__%\resources\ini"
>>%genConfigFile%  Library_Path="%__POVSYSDIR__%\resources\include"
>>%genConfigFile%.
>>%genConfigFile%  ; File output type control.
>>%genConfigFile%  ;     T    Uncompressed Targa-24
>>%genConfigFile%  ;     C    Compressed Targa-24
>>%genConfigFile%  ;     P    UNIX PPM
>>%genConfigFile%  ;     N    PNG (8-bits per colour RGB)
>>%genConfigFile%  ;     Nc   PNG ('c' bit per colour RGB where 5 ^<= c ^<= 16)
>>%genConfigFile%.
>>%genConfigFile%  Output_to_File=true
>>%genConfigFile%  Output_File_Type=N8             ; (+/-Ftype)
rem Finish
EXIT /b

:PROJECT_MESSAGE
SET OPTION=%BUILD_LBL% Graphic User Interface (GUI) solution...
IF %1==1 SET OPTION=%BUILD_LBL% Console User Interface (CUI) project - Default...
ECHO.
ECHO -%OPTION%
EXIT /b

:VERBOSE_MESSAGE
SET STATE=Verbose (%CONFIGURATION%) tracing is OFF - Default
IF %1==1 SET STATE=Verbose (%CONFIGURATION%) tracing is ON
ECHO.
ECHO -%STATE%
EXIT /b

:DISPLAY_ERRRORS_ONLY_MESSAGE
SET ERROR_ONLY=Minimum console display enabled - only error messages displayed.
ECHO.
ECHO -%ERROR_ONLY%
EXIT /b

:CHECK_BUILD
IF %1==Win32 SET PL=32
IF %1==x64 SET PL=64
ECHO.
ECHO --Check %CONFIGURATION% Configuration, %PL%bit Platform...
SET BUILD_CHK_COMMAND=+I"%BUILD_CHK_POV_FILE%" +O"%BUILD_CHK_OUTPUT%.%PL%bit.png" %BUILD_CHK_PARAMS% %BUILD_CHK_INCLUDE%
ECHO   RUN_COMMAND.......[%PACKAGE%%PL%%d%.exe %BUILD_CHK_COMMAND%]
ECHO.
IF EXIST "%BUILD_CHK_OUTPUT%" (
	DEL /Q "%BUILD_CHK_OUTPUT%"
)
bin%PL%\%PACKAGE%%PL%%d%.exe %BUILD_CHK_COMMAND%
EXIT /b

:PLATFORM_ERROR
ECHO.
ECHO -(01. FLAG ERROR) Platform or usage flag is invalid [%~nx0 %*].
ECHO  Use x86 or x86_64. For usage help use -help.
GOTO :USAGE

:CONFIGURATION_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -(02. FLAG ERROR) Configuration flag is invalid [%~nx0 %*].
ECHO  Use -rel, -avx or -sse2 with appropriate platform flag.
GOTO :END

:AVX_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -(03. FLAG ERROR) AVX is not compatable with %PLATFORM% platform [%~nx0 %*].
ECHO  Use -avx only with x86_64 flag.
GOTO :END

:SSE2_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -(04. FLAG ERROR) SSE2 is not compatable with %PLATFORM% platform [%~nx0 %*].
ECHO  Use -sse2 only with x86 flag.
GOTO :END

:PROJECT_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -(05. FLAG ERROR) Project flag is invalid [%~nx0 %*].
ECHO  Use -cui for Console UI or -gui for Graphic UI.
GOTO :END

:VERBOSE_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -(06. FLAG ERROR) Output flag is invalid [%~nx0 %*].
ECHO  Use -verbose.
GOTO :END

:VERBOSE_CUI_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -(07. FLAG ERROR) Output flag can only be used with CUI project [%~nx0 %*].
ECHO  Use -verbose only with -cui flag.
GOTO :END

:COMMAND_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -(08. COMMAND ERROR) Invalid command string [%~nx0 %*].
GOTO :END

:USAGE
ECHO ----------------------------------------------------------------
ECHO.
ECHO LPub3D-Trace Windows auto build script.
ECHO.
ECHO Use the options below to select between Graphic User Interface (GUI)
ECHO or Console User Interface (CUI) build projects.
ECHO You can also select configuration Advanced Vector Extensions (AVX)
ECHO for 64bit platforms or Streaming SIMD Extensions 2 (SSE2) for 32bit.
ECHO.
ECHO To run this scrip as is, you must have the following components:
ECHO     - Visual Studio 2017 (I'm using Community Edition here)
ECHO     - Git
ECHO     - Local POV-Ray git repository
ECHO However, you are free to reconfigue this script to use different components.
ECHO.
ECHO ----------------------------------------------------------------
ECHO Usage:
ECHO.
ECHO Help...
ECHO autobuild [ -help ]
ECHO.
ECHO First position flags...
ECHO autobuild [ x86 ^| x86_64 ^| -allcui ^| -run ^| -rbld ^| -verbose ^| -help]
ECHO.
ECHO All flags, 1st, 2nd, 3rd and 4th...
ECHO autobuild [ x86 ^| x86_64 ^| -allcui ^| -run ^| -rbld ^| -verbose ^| -help]
ECHO           [ -rel ^| -dgb ^|-ins ^| -allins ^| -chk ^| -run ^| -rbld ^| -avx ^| sse2]
ECHO           [-cui ^| -gui]
ECHO           [ -verbose ]
ECHO.
ECHO ----------------------------------------------------------------
ECHO Build all CUI projects and deploy all artefacts as a 3rd party installation bundle
ECHO autobuild -allcui -allins
ECHO.
ECHO Build 64bit, Release and perform build check
ECHO autobuild x86_64 -chk
ECHO.
ECHO Build 64bit, AVX-Release CUI project example:
ECHO autobuild x86_64 -avx
ECHO.
ECHO Build 64bit, Release, CUI project with verbose output example:
ECHO autobuild x86_64 -rel -cui -verbose
ECHO.
ECHO Build 32bit, Release GUI project example:
ECHO autobuild x86 -rel -gui
ECHO.
ECHO Build 32bit, SSE2-Release GUI project example:
ECHO autobuild x86 -sse2 -gui
ECHO.
ECHO Build 32bit, Release CUI project example:
ECHO autobuild
ECHO.
ECHO.
ECHO Flags are case sensitive, use lowere case.
ECHO.
ECHO If no flag is supplied, 32bit platform, Release Configuration, CUI project built by default.
ECHO.
ECHO Flags:
ECHO ----------------------------------------------------------------
ECHO ^| Flag    ^| Pos ^| Type             ^| Description
ECHO ----------------------------------------------------------------
ECHO  -help......1.....Useage flag        [Difault=Off] Display useage.
ECHO  x86........1.....Platform flag      [Default=On ] Build 32bit architecture.
ECHO  x86_64.....1.....Platform flag      [Default=On ] Build 64bit architecture.
ECHO  -allcui....1.....Project flag       [Default=On ] Build and install 32bit, 64bit, CUI configurations.
ECHO  -allins....2.....Project flag       [Default=Off] Install all distribution artefacts to lpub3d_windows_3rdparty archive folder.
ECHO  -ins.......2.....Project flag       [Default=On ] Install subset of distribution artefacts to lpub3d_windows_3rdparty archive folder.
ECHO  -run.......2,1...Project flag       [Default=Off] Run an image redering check - must be preceded by x86 or x86_64 flag.
ECHO  -rbld......2,1...Project flag       [Default=Off] Rebuild project - clean and rebuild all project components.
EChO  -rel.......2.....Configuration flag [Default=On ] Specify a release build.
EChO  -dgb.......2.....Configuration flag [Default=Off] Specify a debug build.
ECHO  -avx.......2.....Configuraiton flag [Default=Off] AVX-Release, use Advanced Vector Extensions (must be preceded by x86_64 flag).
ECHO  -sse2......2.....Configuration flag [Default=Off] SSE2-Release, use Streaming SIMD Extensions 2 (must be preceded by x86 flag).
ECHO  -chk.......2.....Project flag       [Default=On ] Build and run an image redering check.
ECHO  -cui.......3.....Project flag       [Default=On ] Build Console User Interface (CUI) project (must be preceded by a configuration flag).
ECHO  -gui.......3.....Project flag       [Default=Off] Build Graphic User Interface (GUI) project (must be preceded by a configuration flag).
ECHO  -verbose...4,1...Project flag       [Default=Off] Display verbose output. Useful for debugging (must be preceded by -cui flag).
ECHO ----------------------------------------------------------------
EXIT /b

:END
ENDLOCAL
EXIT /b
rem Done
