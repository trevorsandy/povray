@ECHO OFF

Title LPub3D-Trace on Windows auto build script

:: This script uses MSBuild to configure and build LPub3D-Trace from the command line.
:: The primary benefit is not having to modify source files before building
:: as described in the official POV-Ray build documentation.
:: It is possible to build either the GUI or CUI project - see usage below.

:: This script is requires autobuild_defs.cmd
:: --
::  Trevor SANDY <trevor.sandy@gmail.com>
::  Last Update: May 19, 2017
::  Copyright (c) 2017 by Trevor SANDY
:: --
:: This script is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

:: It is expected that this script will reside in .\windows\vs2015

:: Variables
SET APPNAME=lpub3d_trace_cui
SET VERSION=3.7
SET DIST_DIR_ROOT=..\..\..\lpub3d_windows_3rdparty
:: Build check static settings - don't change these.
SET BUILD_CHK_INCLUDE=+L"../../distribution/ini" +L"../../distribution/include" +L"../../distribution/scenes"
:: Build check varialbe settings - set according to your check requirements
:: Check 01
::SET BUILD_CHK_POV_FILE=../../distribution/scenes/advanced/biscuit.pov
::SET BUILD_CHK_PARAMS=-f +d +p +v +w320 +h240 +a0.3 %BUILD_CHK_INCLUDE%
:: Check 02
SET BUILD_CHK_POV_FILE=tests\csi.ldr.pov
SET BUILD_CHK_INCLUDE=%BUILD_CHK_INCLUDE% +L"%USERPROFILE%\LDraw\lgeo\ar" +L"%USERPROFILE%\LDraw\lgeo\lg" +L"%USERPROFILE%\LDraw\lgeo\stl"
SET BUILD_CHK_PARAMS=+w2549 +h1650 +UA +A %BUILD_CHK_INCLUDE%


SET PLATFORM=unknown
SET CONFIGURATION=unknown
SET PROJECT=unknown
SET CONSOLE=unknown
SET VERBOSE=unknown
SET CHECK=unknown

:: Check if invalid platform flag
IF NOT [%1]==[] (
	IF NOT "%1"=="x86" (
		IF NOT "%1"=="x86_64" (
			IF NOT "%1"=="-allcui" (
					IF NOT "%1"=="-help" GOTO :PLATFORM_ERROR
			)
		)
	)
)
:: Parse platform input flag
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

IF /I "%1"=="-help" (
	GOTO :USAGE
)
:: If we get here display invalid command message.
GOTO :COMMAND_ERROR

:SET_CONFIGURATION
:: Check if invalid configuration flag
IF NOT [%2]==[] (
	IF NOT "%2"=="-rel" (
		IF NOT "%2"=="-avx" (
			IF NOT "%2"=="-ins" (
				IF NOT "%2"=="-allins" (
					IF NOT "%2"=="-chk" (
						IF NOT "%2"=="-sse2" GOTO :CONFIGURATION_ERROR
					)
				)
			)
		)
	)
)
:: Parse configuration input flag
IF [%2]==[] (
	SET CONFIGURATION=Release
	GOTO :BUILD
)
:: Check if no extension release build
IF /I "%2"=="-rel" (
	SET CONFIGURATION=Release
	GOTO :BUILD
)
:: Check if x86_64 and AVX
IF "%PLATFORM%"=="x64" (
	IF /I "%2"=="-avx" GOTO :SET_AVX
)
:: Check if x86 and SSE2
IF "%PLATFORM%"=="Win32" (
	IF /I "%2"=="-sse2" GOTO :SET_SSE2
)
:: Check if bad platform and configuration flag combination
IF "%PLATFORM%"=="Win32" (
	IF /I "%2"=="-avx" GOTO :AVX_ERROR
)
IF "%PLATFORM%"=="x64" (
	IF /I "%2"=="-sse2" GOTO :SSE2_ERROR
)

:: Check if install - reset configuration
IF /I "%2"=="-ins" (
	:: 3rd party install
	SET THIRD_INSTALL=1
	SET INSTALL_ALL=0
	SET CONFIGURATION=Release
	GOTO :BUILD
)

IF /I "%2"=="-allins" (
	:: 3rd party install
	SET THIRD_INSTALL=1
	SET INSTALL_ALL=1
	SET CONFIGURATION=Release
	GOTO :BUILD
)

:: Perform quick check
IF /I "%2"=="-chk" (
	SET CHECK=1
	SET CONFIGURATION=Release
	GOTO :BUILD
)

:: If we get here display invalid command message
GOTO :COMMAND_ERROR

:SET_AVX
:: AVX Configuration
SET CONFIGURATION=Release-AVX
GOTO :BUILD

:SET_SSE2
:: SSE2 Configuration
SET CONFIGURATION=Release-SSE2
GOTO :BUILD

:BUILD
:: Initialize the Visual Studio command line development environment
:: Note you can change this line to your specific environment - I am using VS2017 here.
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\VsDevCmd.bat"

:: Check if invalid console flag
IF NOT [%3]==[] (
	IF NOT "%3"=="-gui" (
		IF NOT "%3"=="-cui" GOTO :PROJECT_ERROR
	)
)

:: Build CUI or GUI project - CUI is default
:: Parse configuration input flag
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

:: Check if invalid verbose flag
IF NOT [%4]==[] (
	IF NOT "%4"=="-verbose" GOTO :VERBOSE_ERROR
)
:: Enable verbose tracing (useful for debugging)
IF /I "%4"=="-verbose" (
	:: Check if CUI or allCUI project build
	IF NOT "%3"=="-cui" (
		IF NOT "%PLATFORM%"=="-allcui" GOTO :VERBOSE_CUI_ERROR
	)
	SET VERBOSE=1
) ELSE (
	SET VERBOSE=0
)

:: Check if build all platforms
IF /I "%PLATFORM%"=="-allcui" (
	SET CONFIGURATION=Release
	GOTO :BUILD_ALL_CUI
)

:: Display build project message
CALL :PROJECT_MESSAGE %CONSOLE%

:: Display verbosity message
CALL :VERBOSE_MESSAGE %VERBOSE%

:: Set the LPub3D-Trace auto-build pre-processor defines
CALL autobuild_defs.cmd

:: Display the defines set (as environment variables) for MSbuild
ECHO.
ECHO   BUILD_DEFINES.....[%PovBuildDefs%]
:: Display the build configuration and platform settings
ECHO.
ECHO -Building %CONFIGURATION% Configuration for %PLATFORM% Platform...
ECHO.

:: Launch msbuild
msbuild /m /p:Configuration=%CONFIGURATION% /p:Platform=%PLATFORM% %PROJECT%
:: Perform build check if specified
IF %CHECK%==1 CALL :CHECK_BUILD %PLATFORM%
:: Finish
EXIT /b

:BUILD_ALL_CUI
:: Set CUI statically
SET CONSOLE=1
SET PROJECT=console.vcxproj

:: Display build project message
CALL :PROJECT_MESSAGE %CONSOLE%

:: Display verbosity message
CALL :VERBOSE_MESSAGE %VERBOSE%

:: Set the LPub3D-Trace auto-build pre-processor defines
CALL autobuild_defs.cmd

:: Display the defines set (as environment variables) for MSbuild
ECHO.
ECHO   BUILD_DEFINES.....[%PovBuildDefs%]

:: Launch msbuild across all CUI platform builds
FOR %%P IN ( Win32, x64 ) DO (
	ECHO.
	ECHO --All CUI Platforms: Building %CONFIGURATION% Configuration for %%P Platform...
	ECHO.
	msbuild /m /p:Configuration=%CONFIGURATION% /p:Platform=%%P %PROJECT%
	:: Perform build check if specified
	IF %CHECK%==1 CALL :CHECK_BUILD %%P
)
:: Perform 3rd party install if specified
IF %THIRD_INSTALL%==1 GOTO :3RD_PARTY_INSTALL
:: Finish
EXIT /b

:3RD_PARTY_INSTALL
ECHO.
ECHO -Copying 3rd party distribution files...
ECHO.
ECHO -Copying 32bit exe...
IF NOT EXIST "%DIST_DIR_ROOT%\bin\%APPNAME%-%VERSION%\i386\" (
	MKDIR "%DIST_DIR_ROOT%\bin\%APPNAME%-%VERSION%\i386\"
)
COPY /V /Y "bin32\%APPNAME%32.exe" "%DIST_DIR_ROOT%\bin\%APPNAME%-%VERSION%\i386\" /B

ECHO -Copying 64bit exe...
IF NOT EXIST "%DIST_DIR_ROOT%\bin\%APPNAME%-%VERSION%\x86_64\" (
	MKDIR "%DIST_DIR_ROOT%\bin\%APPNAME%-%VERSION%\x86_64\"
)
COPY /V /Y "bin64\%APPNAME%64.exe" "%DIST_DIR_ROOT%\bin\%APPNAME%-%VERSION%\x86_64\" /B

ECHO -Copying Documentaton...
IF NOT EXIST "%DIST_DIR_ROOT%\docs\%APPNAME%-%VERSION%\" (
	MKDIR "%DIST_DIR_ROOT%\docs\%APPNAME%-%VERSION%\"
)
SET DIST_DIR="%DIST_DIR_ROOT%\docs\%APPNAME%-%VERSION%"
SET DIST_SRC="..\..\distribution\platform-specific\windows"
IF  %INSTALL_ALL% == 1  XCOPY /S /I /E /V /Y "%DIST_SRC%\Help" "%DIST_DIR%\help"
IF  %INSTALL_ALL% == 1  XCOPY /S /I /E /V /Y "..\..\doc\html" "%DIST_DIR%\html"
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\CUI_README.txt" "%DIST_DIR%" /A
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\..\LICENSE" "%DIST_DIR%\LICENSE.txt" /A
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\..\changes.txt" "%DIST_DIR%\ChangeLog.txt" /A
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\..\unix\AUTHORS" "%DIST_DIR%\AUTHORS.txt" /A

ECHO -Copying Resources...
IF NOT EXIST "%DIST_DIR_ROOT%\resources\%APPNAME%-%VERSION%\" (
	MKDIR "%DIST_DIR_ROOT%\resources\%APPNAME%-%VERSION%\"
)
SET DIST_DIR="%DIST_DIR_ROOT%\resources\%APPNAME%-%VERSION%"
IF  %INSTALL_ALL% == 1  XCOPY /S /I /E /V /Y "%DIST_SRC%\Icons" "%DIST_DIR%\Icons"
IF  %INSTALL_ALL% == 1  XCOPY /S /I /E /V /Y "..\..\distribution\include" "%DIST_DIR%\include"
IF  %INSTALL_ALL% == 1  XCOPY /S /I /E /V /Y "..\..\distribution\ini" "%DIST_DIR%\ini"
IF  %INSTALL_ALL% == 1  XCOPY /S /I /E /V /Y "..\..\distribution\scenes" "%DIST_DIR%\scenes"
IF NOT EXIST "%DIST_DIR%\conf\" (
	MKDIR "%DIST_DIR%\conf\"
)
COPY /V /Y "..\povconfig\povray.conf" "%DIST_DIR%\conf\povray.conf" /A
COPY /V /Y "..\..\distribution\ini\povray.ini" "%DIST_DIR%\conf\povray.ini" /A
:: Finish
EXIT /b

:PROJECT_MESSAGE
SET OPTION=Build Graphic User Interface (GUI) solution...
IF %1==1 SET OPTION=Build Console User Interface (CUI) project - Default...
ECHO.
ECHO -%OPTION%
EXIT /b

:VERBOSE_MESSAGE
SET STATE=Verbose tracing is OFF - Default
IF %1==1 SET STATE=Verbose tracing is ON
ECHO.
ECHO -%STATE%
EXIT /b

:CHECK_BUILD
IF %1==Win32 SET PL=32
IF %1==x64 SET PL=64
ECHO.
ECHO --Check %CONFIGURATION% Configuration, %PL%bit Platform...
ECHO.
SET BUILD_CHK_OUTPUT=%BUILD_CHK_POV_FILE%.%PL%bit.png
SET BUILD_CHK_COMMAND=+I"%BUILD_CHK_POV_FILE%" +O"%BUILD_CHK_OUTPUT%" %BUILD_CHK_PARAMS%
ECHO --Command: %APPNAME%%PL%.exe %BUILD_CHK_COMMAND%
ECHO.
IF EXIST "%BUILD_CHK_OUTPUT%" (
	DEL /Q "%BUILD_CHK_OUTPUT%"
)
bin%PL%\%APPNAME%%PL%.exe %BUILD_CHK_COMMAND%
EXIT /b

:PLATFORM_ERROR
ECHO.
ECHO -(FLAG ERROR) Platform or usage flag is invalid. Use x86 or x86_64. For usage help use -help.
GOTO :USAGE

:CONFIGURATION_ERROR
ECHO.
ECHO -(FLAG ERROR) Configuration flag is invalid. Use -rel, -avx or -sse2 with appropriate platform flag.
GOTO :USAGE

:AVX_ERROR
ECHO.
ECHO -(FLAG ERROR) AVX is not compatable with %PLATFORM% platform. Use -avx only with x86_64 flag.
GOTO :USAGE

:SSE2_ERROR
ECHO.
ECHO -(FLAG ERROR) SSE2 is not compatable with %PLATFORM% platform. Use -sse2 only with x86 flag.
GOTO :USAGE

:PROJECT_ERROR
ECHO.
ECHO -(FLAG ERROR) Project flag is invalid. Use -cui for Console UI or -gui for Graphic UI.
GOTO :USAGE

:VERBOSE_ERROR
ECHO.
ECHO -(FLAG ERROR) Output flag is invalid. Use -verbose.
GOTO :USAGE

:VERBOSE_CUI_ERROR
ECHO.
ECHO -(FLAG ERROR) Output flag can only be used with CUI project. Use -verbose only with -cui flag.
GOTO :USAGE

:COMMAND_ERROR
ECHO.
ECHO -(COMMAND ERROR) Invalid command string.
GOTO :USAGE

:USAGE
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
ECHO Usage:
ECHO autobuild [ -help ]
ECHO autobuild [ -allcui ^| x86 ^| x86_64 ^| ] [ -allins ^| -rel ^| -avx ^| sse2 ^| -ins ^| -chk ] [-cui ^| -gui] [ -verbose ]
ECHO.
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
ECHO Flags:
ECHO  -help.....1.Useage flag - Display useage.
ECHO  x86.......1.Platform flag - Build 32bit architecture.
ECHO  x86_64....1.Platform flag - Build 64bit architecture.
ECHO  -allcui...1.Configuraiton flag - [Default] Build and install 32bit, 64bit, CUI configurations.
ECHO  -allins...2.Project flag - Install all distribution artefacts as LPub3D 3rd party installation.
ECHO  -ins......2.Project flag - Install subset of distribution artefacts as LPub3D 3rd party installation.
EChO  -rel......2.Configuration flag - [Default] Release, no extensions (must be preceded by platform flag).
ECHO  -avx......2.Configuraiton flag - AVX-Release, use Advanced Vector Extensions (must be preceded by x86_64 flag).
ECHO  -sse2.....2.Configuration flag - SSE2-Release, use Streaming SIMD Extensions 2 (must be preceded by x86 flag).
ECHO  -chk......2.Project flag - Perform a quick image redering check.
ECHO  -cui......3.Project flag - Build Console User Interface (CUI) project (must be preceded by a configuration flag).
ECHO  -gui......3.Project flag - Build Graphic User Interface (GUI) project (must be preceded by a configuration flag).
ECHO  -verbose..4.Output flag - Display verbose output. Useful for debugging (must be preceded by -cui flag).
ECHO.
ECHO Flags are case sensitive, use lowere case.
ECHO.
ECHO If no flag is supplied, 32bit platform, Release Configuration, CUI project built by default.
EXIT /b

:END
:: Done
