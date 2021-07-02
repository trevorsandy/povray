@ECHO OFF &SETLOCAL

Title LPub3D-Trace on Windows auto build script

rem This script uses MSBuild to configure and build LPub3D-Trace from the command line.
rem The primary benefit is not having to modify source files before building
rem as described in the official POV-Ray build documentation.
rem It is possible to build either the GUI or CUI project - see usage below.

rem This script is requires autobuild_defs.cmd
rem --
rem  Trevor SANDY <trevor.sandy@gmail.com>
rem  Last Update: June 10, 2021
rem  Copyright (c) 2019 - 2021 by Trevor SANDY
rem --
rem This script is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

rem It is expected that this script will reside in .\windows\vs2015

SET start=%time%

rem Static defaults
IF "%APPVEYOR%" EQU "True" (
    IF [%LP3D_DIST_DIR_PATH%] == [] (
      ECHO.
      ECHO  -ERROR: Distribution directory path not defined.
      ECHO  -%~nx0 terminated!
      GOTO :END
    )
    SET MAP_FILE_CHECK=0
    rem If Appveyor, do not show the image display window
    SET DISP_WIN=-d
    rem deposit archive folder top build-folder
    SET DIST_DIR=%LP3D_DIST_DIR_PATH%
) ELSE (
    SET MAP_FILE_CHECK=0
    SET DISP_WIN=+d
    SET DIST_DIR=..\..\..\lpub3d_windows_3rdparty
)
rem Visual C++ 2012 -vcvars_ver=11.0
rem Visual C++ 2013 -vcvars_ver=12.0
rem Visual C++ 2015 -vcvars_ver=14.0
rem Visual C++ 2017 -vcvars_ver=14.1
rem Visual C++ 2019 -vcvars_ver=14.2
SET LP3D_VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build
SET LP3D_VCVARSALL_VER=-vcvars_ver=14.2
SET LP3D_VCTOOLSET=/p:PlatformToolset=v142 /p:WindowsTargetPlatformVersion=10.0.17763.0
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
REM SET BUILD_CHK_MY_POV_FILE=tests\space in dir name test\biscuit.pov
REM SET BUILD_CHK_MY_OUTPUT=tests\space in dir name test\biscuit space in file name test
REM SET BUILD_CHK_MY_PARMS=%DISP_WIN% -p +a0.3 +UA +A +w320 +h240
REM SET BUILD_CHK_MY_INCLUDES=

rem Check 04
rem ------------------------------------------
SET BUILD_CHECK_MAP_FILE=+SM"%USERPROFILE%\Temp\build_check_povray_map.out"
SET BUILD_CHK_MY_POV_FILE=tests\space in dir name test\biscuit.pov
IF MAP_FILE_CHECK EQU 1 (
    SET BUILD_CHK_MY_OUTPUT=-O-
) ELSE (
    SET BUILD_CHK_MY_OUTPUT=tests\space in dir name test\biscuit space in file name test
)
SET BUILD_CHK_MY_PARMS=%DISP_WIN% -p +a0.3 +UA +A +w320 +h240
SET BUILD_CHK_MY_INCLUDES=

rem Build check static settings - do not modify these.
SET BUILD_CHK_OUTPUT=%BUILD_CHK_MY_OUTPUT%
SET BUILD_CHK_POV_FILE=%BUILD_CHK_MY_POV_FILE%
SET BUILD_CHK_PARAMS=%BUILD_CHK_MY_PARMS%
IF MAP_FILE_CHECK EQU 1 (
    SET BUILD_CHK_INCLUDE=%BUILD_CHECK_MAP_FILE% +L"..\..\distribution\ini" +L"..\..\distribution\include" +L"..\..\distribution\scenes"
) ELSE (
    SET BUILD_CHK_INCLUDE=+L"..\..\distribution\ini" +L"..\..\distribution\include" +L"..\..\distribution\scenes"
)
SET BUILD_CHK_INCLUDE=%BUILD_CHK_INCLUDE% %BUILD_CHK_MY_INCLUDES%

rem Visual Studio 'debug' comand line: +I"tests\space in dir name test\biscuit.pov" +O"tests\space in dir name test\biscuit space in file name test.png" +w320 +h240 +d -p +a0.3 +UA +A +L"..\..\distribution\ini" +L"..\..\distribution\include" +L"..\..\distribution\scenes"
rem Set console output logging level - (0=normal:all output or 1=minimum:error output)
SET MINIMUM_LOGGING=unknown
SET THIRD_INSTALL=unknown
SET INSTALL_32BIT=unknown
SET INSTALL_64BIT=unknown
SET FLAG_CONFLICT=unknown
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

ECHO.
ECHO -Start %PACKAGE% %~nx0 with commandline args: [%*].

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
    CALL :BUILD_CHECK %PLATFORM%
    rem Finish
    GOTO :END
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
rem Run an image render check
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
rem Check if %1=x86_64 and %2=AVX
IF "%PLATFORM%"=="x64" (
    IF /I "%2"=="-avx" GOTO :SET_AVX
)
rem Check if  %1=x86 and %2=SSE2
IF "%PLATFORM%"=="Win32" (
    IF /I "%2"=="-sse2" GOTO :SET_SSE2
)
rem Check if bad platform and configuration flag combination -  %1=Win32 and %2=-avx
IF "%PLATFORM%"=="Win32" (
    IF /I "%2"=="-avx" GOTO :AVX_ERROR
)
rem Check if bad platform and configuration flag combination -  %1=x64 and %2=-sse2
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
rem Check if build all platforms
IF /I "%1"=="-allcui" (
    SET CONSOLE=1
    SET PROJECT=console.vcxproj
    SET CONFIGURATION=%DEFAULT_CONFIGURATION%
)
rem Check if invalid command line flag
IF NOT [%3]==[] (
    IF NOT "%3"=="-gui" (
        IF NOT "%3"=="-cui" (
            IF NOT "%3"=="-chk" (
                IF NOT "%3"=="-minlog" GOTO :PROJECT_ERROR
            )
        )
    )
)
rem Build CUI or GUI project - CUI is default
rem Parse configuration input flag
IF [%3]==[] (
    SET CONSOLE=1
    SET PROJECT=console.vcxproj
)
IF /I "%3"=="-gui" (
    IF "%1"=="-allcui" (
        SET FLAG_CONFLICT=-allcui flag detected, -gui flag ignored.
        CALL :FLAG_CONFLICT_DETECTED %*
    ) ELSE (
        SET CONSOLE=0
        SET PROJECT=povray.sln
    )
)
IF /I "%3"=="-cui" (
    IF "%1"=="-allcui" (
        SET FLAG_CONFLICT=-allcui flag detected, -cui flag ignored.
        CALL :FLAG_CONFLICT_DETECTED %*
    ) ELSE (
        SET CONSOLE=1
        SET PROJECT=console.vcxproj
    )
)
IF "%FLAG_CONFLICT%" == "fatal" GOTO :END
rem Run an image render check
IF /I "%3"=="-chk" (
    SET CHECK=1
    rem This flag should have it's own slot, but this will do for now...
    SET CONSOLE=1
    SET PROJECT=console.vcxproj
)
rem Check if invalid command line flag
IF NOT [%4]==[] (
    IF NOT "%4"=="-minlog" (
        IF NOT "%4"=="-verbose" GOTO :VERBOSE_ERROR
    )
)
rem Enable verbose tracing (useful for debugging)
IF /I "%1"=="-verbose" SET VERBOSE_CHK=true
IF /I "%4"=="-verbose" SET VERBOSE_CHK=true
IF "%CONFIGURATION%"=="Debug" SET VERBOSE_CHK=true
IF /I "%VERBOSE_CHK%"=="true" (
    rem Check if CUI or allCUI project build
    IF NOT %CONSOLE%==1 (
        IF NOT "%PLATFORM%"=="-allcui" (
            GOTO :VERBOSE_CUI_ERROR
        )
    )
    SET VERBOSE=1
)
rem Console output - see https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference
rem Set console output logging level - (normal:all output or minlog=only error output)
SET LOGGING_FLAGS=
IF /I "%3"=="-minlog" (
    SET MINIMUM_LOGGING=1
)
IF /I "%4"=="-minlog" (
    SET MINIMUM_LOGGING=1
)
IF /I %MINIMUM_LOGGING% == 1 (
    SET LOGGING_FLAGS=/clp:ErrorsOnly /nologo
)

rem Display the attributges and arguments to visually confirm all is well.
ECHO.
ECHO -Build Parameters:
ECHO.
IF "%APPVEYOR%" EQU "True" (
    ECHO   BUILD_HOST..........[APPVEYOR CONTINUOUS INTEGRATION SERVICE]
    ECHO   BUILD_ID............[%APPVEYOR_BUILD_ID%]
    ECHO   BUILD_BRANCH........[%APPVEYOR_REPO_BRANCH%]
    ECHO   PROJECT_NAME........[%APPVEYOR_PROJECT_NAME%]
    ECHO   REPOSITORY_NAME.....[%APPVEYOR_REPO_NAME%]
    ECHO   REPO_PROVIDER.......[%APPVEYOR_REPO_PROVIDER%]
    ECHO   DIST_DIRECTORY......[%DIST_DIR%]
)

rem Display build project message
CALL :PROJECT_MESSAGE %CONSOLE%

rem Display verbosity message
CALL :VERBOSE_MESSAGE %VERBOSE%

rem Console output logging level message
CALL :OUTPUT_LOGGING_MESSAGE %MINIMUM_LOGGING%

rem Check if build all platforms
IF /I "%PLATFORM%"=="-allcui" (
    GOTO :BUILD_ALL_CUI
)

rem Configure buid arguments and set environment variables
CALL :CONFIGURE_BUILD_ENV

rem Assemble command line
SET COMMAND_LINE=msbuild /m /p:Configuration=%CONFIGURATION% /p:Platform=%PLATFORM% %LP3D_VCTOOLSET% %PROJECT% %LOGGING_FLAGS% %DO_REBUILD%
ECHO.
ECHO   BUILD_COMMAND.....[%COMMAND_LINE%]
rem Display the build configuration and platform settings
ECHO.
ECHO -%BUILD_LBL% %CONFIGURATION% Configuration for %PLATFORM% Platform...
ECHO.
rem Launch msbuild
%COMMAND_LINE%
rem Perform build check if specified
IF %CHECK% == 1 CALL :BUILD_CHECK %PLATFORM%
rem Perform 3rd party install if specified
IF %THIRD_INSTALL% == 1 (
    CALL :3RD_PARTY_INSTALL %PLATFORM%
)
GOTO :END

:BUILD_ALL_CUI
rem Display the build configuration and platform settings
ECHO.
ECHO -%BUILD_LBL% x86 and x86_64 CUI Platforms for %CONFIGURATION% Configuration...
rem Launch msbuild across all CUI platform builds
FOR %%P IN ( Win32, x64 ) DO (
    ECHO.
    ECHO --%BUILD_LBL% %%P Platform...
    ECHO.
    rem Initialize the Visual Studio command line development environment
    SET PLATFORM=%%P
    CALL :CONFIGURE_BUILD_ENV
    rem Assemble command line parameters
    SET COMMAND_LINE=msbuild /m /p:Configuration=%CONFIGURATION% /p:Platform=%%P %LP3D_VCTOOLSET% %PROJECT% %LOGGING_FLAGS% %DO_REBUILD%
    SETLOCAL ENABLEDELAYEDEXPANSION
    ECHO   BUILD_COMMAND.....[!COMMAND_LINE!]
    IF NOT %MINIMUM_LOGGING% == 1 ECHO.
    rem Launch msbuild
    !COMMAND_LINE!
    rem Perform build check if specified
    IF %%P == x64 (
        SET EXE=bin64\%PACKAGE%64%d%.exe
    ) ELSE (
        SET EXE=bin32\%PACKAGE%32%d%.exe
    )
    IF NOT EXIST "!EXE!" (
       ECHO.
       ECHO "-ERROR - !EXE! was not successfully built - autobuild will trminate."
       GOTO :END
    )
    ENDLOCAL
    IF %CHECK% == 1 CALL :BUILD_CHECK %%P
)
rem Perform 3rd party install if specified
IF %THIRD_INSTALL% == 1 (
    CALL :3RD_PARTY_INSTALL %PLATFORM%
)
GOTO :END

:CONFIGURE_BUILD_ENV
ECHO.
ECHO -Configure %PACKAGE% %PLATFORM% build environment...
rem Set vcvars for AppVeyor or local build environments
IF "%PATH_PREPENDED%" NEQ "True" (
  IF %PLATFORM% EQU Win32 (
    ECHO.
    CALL "%LP3D_VCVARSALL%\vcvars32.bat" %LP3D_VCVARSALL_VER%
  ) ELSE (
    ECHO.
    CALL "%LP3D_VCVARSALL%\vcvars64.bat" %LP3D_VCVARSALL_VER%
  )
  rem Display MSVC Compiler settings
  cl -Bv
  ECHO.
) ELSE (
  ECHO.
  ECHO -%PLATFORM% build environment already configured...
)
rem Set the LPub3D-Trace auto-build pre-processor defines
CALL autobuild_defs.cmd
rem Display the defines set (as environment variable 'PovBuildDefs') for MSbuild
ECHO.
ECHO   BUILD_DEFINES.....[%PovBuildDefs%]
EXIT /b

:BUILD_CHECK
IF %1 == x64 SET PL=64
IF %1 == Win32 SET PL=32
REM IF "%APPVEYOR%" NEQ "True" (
    REM IF %1 == x86 SET PL=32
REM )
ECHO.
ECHO --Build check - %CONFIGURATION% Configuration, %PL%bit Platform...
rem Version major and minor pulled in from autobuild_defs
SET VERSION_BASE=%VERSION_MAJ%.%VERSION_MIN%
rem Suppress Missing System Povray.conf file as we are only using the user instance
SET POV_IGNORE_SYSCONF_MSG=AnyValueOtherThanEmpty
SET ARCH_LABEL=[%PL%bit]
SET CONFIG_DIR=%USERPROFILE%\AppData\Local\LPub3D Software\LPub3D\3rdParty\%PACKAGE%-%VERSION_BASE%\config

IF EXIST "%BUILD_CHK_OUTPUT%" DEL /Q "%BUILD_CHK_OUTPUT%"

IF MAP_FILE_CHECK EQU 1 (
    SET BUILD_CHK_COMMAND=+I"%BUILD_CHK_POV_FILE%" %BUILD_CHK_OUTPUT% %BUILD_CHK_PARAMS% %BUILD_CHK_INCLUDE%
) ELSE (
    SET BUILD_CHK_COMMAND=+I"%BUILD_CHK_POV_FILE%" +O"%BUILD_CHK_OUTPUT%.%PL%bit.png" %BUILD_CHK_PARAMS% %BUILD_CHK_INCLUDE%
)

ECHO.
ECHO   BUILD_CHECK_COMMAND.......[%PACKAGE%%PL%%d%.exe %BUILD_CHK_COMMAND%]

bin%PL%\%PACKAGE%%PL%%d%.exe %BUILD_CHK_COMMAND%

ECHO.
ECHO --Build check cleanup...
FOR %%I IN ( conf, ini ) DO (
    IF EXIST "%CONFIG_DIR%\povray.CHK_BAK.%%I" (
        COPY /V /Y "%CONFIG_DIR%\povray.CHK_BAK.%%I" "%CONFIG_DIR%\povray.%%I"
        DEL /Q "%CONFIG_DIR%\povray.CHK_BAK.%%I"
    ) ELSE (
        DEL /Q "%CONFIG_DIR%\povray.%%I"
    )
)
EXIT /b

:3RD_PARTY_INSTALL
IF %1 == Win32 SET INSTALL_32BIT=1
IF %1 == x64 SET INSTALL_64BIT=1
IF %1 == -allcui (
    SET INSTALL_32BIT=1
    SET INSTALL_64BIT=1
)
rem Version major and minor pulled in from autobuild_defs
SET VERSION_BASE=%VERSION_MAJ%.%VERSION_MIN%
ECHO.
IF %INSTALL_ALL% == 1 (
    ECHO -Installing all distribution files...
) ELSE (
    ECHO -Installing configuration files...
)
IF  %INSTALL_ALL% == 1  ECHO.
IF  %INSTALL_ALL% == 1  ECHO -Installing Documentaton to [%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\docs]...
IF NOT EXIST "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\docs\" (
    IF  %INSTALL_ALL% == 1 MKDIR "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\docs\"
)
IF  %INSTALL_ALL% == 1  SET DIST_INSTALL_PATH=%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\docs
IF  %INSTALL_ALL% == 1  SET DIST_INSTALL_SRC="..\..\distribution\platform-specific\windows"
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\CUI_README.txt" "%DIST_INSTALL_PATH%" /A
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\..\LICENSE" "%DIST_INSTALL_PATH%\LICENSE.txt" /A
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\..\changes.txt" "%DIST_INSTALL_PATH%\ChangeLog.txt" /A
IF  %INSTALL_ALL% == 1  COPY /V /Y "..\..\unix\AUTHORS" "%DIST_INSTALL_PATH%\AUTHORS.txt" /A
IF  %INSTALL_ALL% == 1  XCOPY /Q /S /I /E /V /Y "%DIST_INSTALL_SRC%\Help" "%DIST_INSTALL_PATH%\help"
IF  %INSTALL_ALL% == 1  ECHO.
IF  %INSTALL_ALL% == 1  ECHO -Installing Resources...
IF NOT EXIST "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\resources\" (
    IF  %INSTALL_ALL% == 1  MKDIR "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\resources\"
)
IF  %INSTALL_ALL% == 1  SET DIST_INSTALL_PATH=%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\resources
IF  %INSTALL_ALL% == 1  ECHO.
IF  %INSTALL_ALL% == 1  ECHO -Installing Include scripts to [%DIST_INSTALL_PATH%\include]...
IF  %INSTALL_ALL% == 1  XCOPY /Q /S /I /E /V /Y "..\..\distribution\include" "%DIST_INSTALL_PATH%\include"
IF  %INSTALL_ALL% == 1  ECHO.
IF  %INSTALL_ALL% == 1  ECHO -Installing Initialization files to [%DIST_INSTALL_PATH%\ini]...
IF  %INSTALL_ALL% == 1  XCOPY /Q /S /I /E /V /Y "..\..\distribution\ini" "%DIST_INSTALL_PATH%\ini"

SET DIST_INSTALL_PATH_PREFIX=%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\resources\config
IF %INSTALL_32BIT% == 1 (
    ECHO.
    ECHO -Installing %PACKAGE%32%d%.exe to [%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\bin\i386]...
    IF NOT EXIST "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\bin\i386\" (
        MKDIR "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\bin\i386\"
    )
    COPY /V /Y "bin32\%PACKAGE%32%d%.exe" "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\bin\i386\" /B
    SET ARCH_LABEL=[32bit]
    SET DIST_INSTALL_PATH=%DIST_INSTALL_PATH_PREFIX%\i386
    ECHO.
)
IF %INSTALL_32BIT% == 1 CALL :MAKE_CONF_AND_INI_FILES
IF %INSTALL_64BIT% == 1 (
    ECHO.
    ECHO -Installing %PACKAGE%64%d%.exe to [%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\bin\x86_64]...
    IF NOT EXIST "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\bin\x86_64\" (
        MKDIR "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\bin\x86_64\"
    )
    COPY /V /Y "bin64\%PACKAGE%64%d%.exe" "%DIST_DIR%\%PACKAGE%-%VERSION_BASE%\bin\x86_64\" /B
    SET ARCH_LABEL=[64bit]
    SET DIST_INSTALL_PATH=%DIST_INSTALL_PATH_PREFIX%\x86_64
    ECHO.
)
IF %INSTALL_64BIT% == 1 CALL :MAKE_CONF_AND_INI_FILES
EXIT /b

:MAKE_CONF_AND_INI_FILES
ECHO -Generate povray.conf and povray.ini files for %ARCH_LABEL% target platform...
SET __HOME__=%%USERPROFILE%%
SET __POVUSERDIR__=AppData\Local\LPub3D Software\LPub3D\3rdParty\%PACKAGE%-%VERSION_BASE%
IF NOT EXIST "%DIST_INSTALL_PATH%\" MKDIR "%DIST_INSTALL_PATH%\"
ECHO   Create povray.conf...
COPY /V /Y "..\..\distribution\povray.conf" "%DIST_INSTALL_PATH%\povray.conf" /A
SET genConfigFile="%DIST_INSTALL_PATH%\povray.conf" ECHO
:GENERATE povray.conf settings file
>>%genConfigFile%.
>>%genConfigFile% ; Default (hard coded) paths:
>>%genConfigFile% ; HOME        = %__HOME__%
>>%genConfigFile% ; INSTALLDIR  = __POVSYSDIR__
>>%genConfigFile% ; SYSCONF     = __POVSYSDIR__\resources\config\povray.conf
>>%genConfigFile% ; SYSINI      = __POVSYSDIR__\resources\config\povray.ini
>>%genConfigFile% ; USERCONF    = %%HOME%%\__POVUSERDIR__\config\povray.conf
>>%genConfigFile% ; USERINI     = %%HOME%%\__POVUSERDIR__\config\povray.ini
>>%genConfigFile%.
>>%genConfigFile% ; This example shows how to qualify path names containing space(s):
>>%genConfigFile% ; read = "%%HOME%%\this\directory\contains space characters"
>>%genConfigFile%.
>>%genConfigFile% ; __USEFUL_LOCATIONS_COMMENT__
>>%genConfigFile%.
>>%genConfigFile% ; __HOMEDIR_COMMENT__
>>%genConfigFile% read* = "%%HOME%%\%__POVUSERDIR__%\config"
>>%genConfigFile%.
>>%genConfigFile% ; read* = "__LGEOARDIR__\ar"
>>%genConfigFile% ; read* = "__LGEOLGDIR__\lg"
>>%genConfigFile% ; read* = "__LGEOSTLDIR__\stl"
>>%genConfigFile%.
>>%genConfigFile% ; %%INSTALLDIR%% is hard-coded to the default LPub3D installation path - see default paths above.
>>%genConfigFile% read* = "__POVSYSDIR__\resources\include"
>>%genConfigFile% read* = "__POVSYSDIR__\resources\ini"
>>%genConfigFile%.
>>%genConfigFile% ; __WORKINGDIR_COMMENT__
>>%genConfigFile% read+write* = .
ECHO   Create povray.ini...
COPY /V /Y "..\..\distribution\ini\povray.ini" "%DIST_INSTALL_PATH%\povray.ini" /A
SET genConfigFile="%DIST_INSTALL_PATH%\povray.ini" ECHO
:GENERATE povray.ini settings file
>>%genConfigFile%.
>>%genConfigFile% ; Search path for #include source files or command line ini files not
>>%genConfigFile% ; found in the current directory.  New directories are added to the
>>%genConfigFile% ; search path, up to a maximum of 25.
>>%genConfigFile%.
>>%genConfigFile% Library_Path="__POVSYSDIR__\resources"
>>%genConfigFile% Library_Path="__POVSYSDIR__\resources\ini"
>>%genConfigFile% Library_Path="__POVSYSDIR__\resources\include"
>>%genConfigFile%.
>>%genConfigFile% ; File output type control.
>>%genConfigFile% ;     T    Uncompressed Targa-24
>>%genConfigFile% ;     C    Compressed Targa-24
>>%genConfigFile% ;     P    UNIX PPM
>>%genConfigFile% ;     N    PNG (8-bits per colour RGB)
>>%genConfigFile% ;     Nc   PNG ('c' bit per colour RGB where 5 ^<= c ^<= 16)
>>%genConfigFile%.
>>%genConfigFile% Output_to_File=true
>>%genConfigFile% Output_File_Type=N8             ; (+/-Ftype)
EXIT /b

:MAKE_BUILD_CHECK_CONF_AND_INI_FILES
ECHO.
ECHO   Generate build check povray.conf and povray.ini files for %ARCH_LABEL% target platform...
SET __POVUSERDIR__=AppData\Local\LPub3D Software\LPub3D\3rdParty\%PACKAGE%-%VERSION_BASE%
IF NOT EXIST "%CONFIG_DIR%\" MKDIR "%CONFIG_DIR%\"
IF EXIST "%CONFIG_DIR%\povray.conf" COPY /V /Y "%CONFIG_DIR%\povray.conf" "%CONFIG_DIR%\povray.CHK_BAK.conf"
ECHO   Create %CONFIG_DIR%\povray.conf...
COPY /V /Y "..\..\distribution\povray.conf" "%CONFIG_DIR%\povray.conf" /A
SET genConfigFile="%CONFIG_DIR%\povray.conf" ECHO
:GENERATE build check povray.conf settings file
>>%genConfigFile%.
>>%genConfigFile% ; LPub3D-Trace build check settings...
>>%genConfigFile%.
>>%genConfigFile% ; %%HOME%% is hard-coded to the %%USERPROFILE%% environment variable (%USERPROFILE%).
>>%genConfigFile% read* = "%%HOME%%\%__POVUSERDIR__%\config"
>>%genConfigFile%.
>>%genConfigFile% ; The working directory (%CD%) is where LPub3D-Trace is called from.
>>%genConfigFile% read* = "..\..\distribution\ini"
>>%genConfigFile% read* = "..\..\distribution\include"
>>%genConfigFile% read* = "..\..\distribution\scenes"
>>%genConfigFile% read+write* = ".\tests\space in dir name test"
ECHO   Create %CONFIG_DIR%\povray.ini...
IF EXIST "%CONFIG_DIR%\povray.ini" COPY /V /Y "%CONFIG_DIR%\povray.ini" "%CONFIG_DIR%\povray.CHK_BAK.ini"
COPY /V /Y "..\..\distribution\ini\povray.ini" "%CONFIG_DIR%\povray.ini" /A
SET genConfigFile="%CONFIG_DIR%\povray.ini" ECHO
:GENERATE build check povray.ini settings file
>>%genConfigFile%.
>>%genConfigFile% ; LPub3D-Trace build check settings...
>>%genConfigFile%.
>>%genConfigFile% Output_to_File=true
>>%genConfigFile% Output_File_Type=N8             ; (+/-Ftype)
EXIT /b

:PROJECT_MESSAGE
SET OPTION=%BUILD_LBL% Graphic User Interface ^(GUI^) solution...
IF %1==1 SET OPTION=%BUILD_LBL% Console User Interface (CUI) project - Default...
ECHO.
ECHO -%OPTION%
EXIT /b

:VERBOSE_MESSAGE
SET STATE=Verbose tracing is OFF - Default
IF %1==1 SET STATE=Verbose tracing is ON
ECHO.
ECHO -%STATE%
EXIT /b

:OUTPUT_LOGGING_MESSAGE
SET STATE=Normal build output enabled - all output displayed - Default.
IF %1==1 SET STATE=Minimum build output enabled - only error output displayed.
ECHO.
ECHO -%STATE%
EXIT /b

:FLAG_CONFLICT_DETECTED
IF "%FLAG_CONFLICT%" == "unknown" (
    SET FLAG_CONFLICT=fatal
    GOTO :FLAG_CONFLICT_ERROR
)
ECHO.
ECHO -08. (FLAG CONFLICT) %FLAG_CONFLICT_MSG% [%~nx0 %*].
ECHO      Enter '%~nx0 --help' to see Usage.
ECHO.
EXIT /b

:PLATFORM_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -01. (FLAG ERROR) Platform or usage flag is invalid [%~nx0 %*].
ECHO      Use x86 or x86_64 for platforms, -allcui for all CUIs, -run to execute
ECHO      without building, -rbld to rebuild or -verbose for 'Win Debug' messages.
ECHO      For usage help use -help.
GOTO :END

:CONFIGURATION_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -02. (FLAG ERROR) Configuration flag is invalid [%~nx0 %*].
ECHO      Use -avx or -sse2 with appropriate platform flag,
ECHO      -rel for release build, -dbg for debug build, -ins to
ECHO      install config files, -allins to install all documentation
ECHO      -chk for Build Check, -run to without building or -rbld to rebuild
ECHO
GOTO :END

:AVX_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -03. (FLAG ERROR) AVX is not compatable with %PLATFORM% platform [%~nx0 %*].
ECHO      Use -avx only with x86_64 flag.
GOTO :END

:SSE2_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -04. (FLAG ERROR) SSE2 is not compatable with %PLATFORM% platform [%~nx0 %*].
ECHO      Use -sse2 only with x86 flag.
GOTO :END

:PROJECT_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -05. (FLAG ERROR) Project flag is invalid [%~nx0 %*].
ECHO      Use -cui for Console UI, -gui for Graphic UI,
ECHO      -chk for Build Check or -minlog to display build errors only.
GOTO :END

:VERBOSE_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -06. (FLAG ERROR) Verbose (Win Debug) or minum console output flag invalid [%~nx0 %*].
ECHO      Use -verbose for 'Win Debug' messages or -minlog to display build errors only.
GOTO :END

:VERBOSE_CUI_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -07. (FLAG ERROR) Verbose (Win Debug) output flag can only be used with the CUI project [%~nx0 %*].
ECHO      Use -verbose only with -cui or -allcui flags.
GOTO :END

:FLAG_CONFLICT_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -08. (FLAG CONFLICT ERROR) Incompatable flag in the command arguments [%~nx0 %*].
ECHO      See Usage.
GOTO :END

:COMMAND_ERROR
ECHO.
CALL :USAGE
ECHO.
ECHO -09. (COMMAND ERROR) Invalid command string [%~nx0 %*].
ECHO      See Usage.
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
ECHO Flags are not case sensitive, use lowere case.
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
ECHO  -minlog....4,3...Project flag       [Default=Off] Minimum build logging - only display build errors
ECHO.
ECHO Flags are case sensitive, use lowere case.
ECHO.
ECHO If no flag is supplied, 32bit platform, Release Configuration, CUI project built by default.
ECHO ----------------------------------------------------------------
EXIT /b

:DEBUG_BYPASS
rem Insert marked section below before command as required
rem DEBUG ----------->>
GOTO :DEBUG_BYPASS
rem DEBUG <<----------
ECHO.
ECHO -DEBUG - EXECUTION BYPASS
EXIT /b

:END
ECHO.
ECHO -%~nx0 [%PACKAGE% v%VERSION_BASE%] finished.
SET end=%time%
SET options="tokens=1-4 delims=:.,"
FOR /f %options% %%a IN ("%start%") DO SET start_h=%%a&SET /a start_m=100%%b %% 100&SET /a start_s=100%%c %% 100&SET /a start_ms=100%%d %% 100
FOR /f %options% %%a IN ("%end%") DO SET end_h=%%a&SET /a end_m=100%%b %% 100&SET /a end_s=100%%c %% 100&SET /a end_ms=100%%d %% 100

SET /a hours=%end_h%-%start_h%
SET /a mins=%end_m%-%start_m%
SET /a secs=%end_s%-%start_s%
SET /a ms=%end_ms%-%start_ms%
IF %ms% lss 0 SET /a secs = %secs% - 1 & SET /a ms = 100%ms%
IF %secs% lss 0 SET /a mins = %mins% - 1 & SET /a secs = 60%secs%
IF %mins% lss 0 SET /a hours = %hours% - 1 & SET /a mins = 60%mins%
IF %hours% lss 0 SET /a hours = 24%hours%
IF 1%ms% lss 100 SET ms=0%ms%
ECHO -Elapsed build time %hours%:%mins%:%secs%.%ms%
ENDLOCAL
EXIT /b
