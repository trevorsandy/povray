@ECHO OFF
Title LPub3D-Trace on Windows auto build script

rem This script sets the LPub3D-Trace preprocessor defines
rem needed to build the solution/project.

rem This script is intended to be called from autobuild.cmd
rem --
rem  Trevor SANDY <trevor.sandy@gmail.com>
rem  Last Update: July 01, 2021
rem  Copyright (c) 2019 - 2024 by Trevor SANDY
rem --
rem This script is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

rem It is expected that this script will reside in .\windows\vs2015

rem Variables
SET DEV_ENV=unknown
SET VERSION_MAJ=unknown
SET VERSION_MIN=unknown
SET VERSION_REV=unknown
SET VERSION_PATCH=unknown
SET RELEASE=
SET GIT_SHA=000000
SET VERSION_H="..\..\source\base\version.h"

rem Get some source details to populate the required defines
rem These are not fixed. You can change as you like
FOR /F "tokens=3*" %%i IN ('FINDSTR /c:"#define POV_RAY_MAJOR_VERSION_INT" %VERSION_H%') DO SET VERSION_MAJ=%%i
FOR /F "tokens=3*" %%i IN ('FINDSTR /c:"#define POV_RAY_MINOR_VERSION_INT" %VERSION_H%') DO SET VERSION_MIN=%%i
FOR /F "tokens=3*" %%i IN ('FINDSTR /c:"#define POV_RAY_REVISION_INT" %VERSION_H%') DO SET VERSION_REV=%%i
FOR /F "tokens=3*" %%i IN ('FINDSTR /c:"#define POV_RAY_PATCHLEVEL_INT" %VERSION_H%') DO SET VERSION_PATCH=%%i
FOR /F "tokens=3*" %%i IN ('FINDSTR /c:"#define POV_RAY_PRERELEASE" %VERSION_H%') DO IF NOT DEFINED RELEASE SET RELEASE=%%i
rem Get the latest version tag sha - if not available locally, try remote
IF "%APPVEYOR%" EQU "True" (
    SET GIT_SHA=%APPVEYOR_REPO_COMMIT:~0,7%
) ELSE (
    IF EXIST "..\..\.git" (
        FOR /F "tokens=* USEBACKQ" %%i IN (`git rev-parse --short HEAD`) DO SET GIT_SHA=%%i
    ) ELSE (
        FOR /F "tokens=1 USEBACKQ" %%i IN (`git ls-remote --tags https://github.com/trevorsandy/povray.git v3.8.0_lpub3d`) DO SET GIT_SHA=%%i
    )
)
rem Get the MSBuild version
FOR /F "tokens=* USEBACKQ" %%i IN (`msbuild -nologo -version`) DO SET DEV_ENV=%%i

rem Remove quotes and trailing space
CALL :CLEAN VERSION_MAJ %VERSION_MAJ%
CALL :CLEAN VERSION_MIN %VERSION_MIN%
CALL :CLEAN VERSION_REV %VERSION_REV%
CALL :CLEAN VERSION_PATCH %VERSION_PATCH%
CALL :CLEAN RELEASE %RELEASE%

rem Build version number
SET VERSION_BASE="%VERSION_MAJ%.%VERSION_MIN%"
rem POV-Ray documentation would like you to use "YOUR NAME (YOUR EMAIL)" here.
SET BUILT_BY="Trevor SANDY<trevor.sandy@gmail.com> for LPub3D using MSBuild v%DEV_ENV%"
rem Here I use the git sha. You can change if you're not building from a local git repository.
SET BUILD_ID="%GIT_SHA:~0,7%"

rem Set project build defines - configured to build GUI project at this stage
SET PovBuildDefs=POV_RAY_IS_AUTOBUILD=1;VERSION_BASE=%VERSION_BASE%;POV_RAY_BUILD_ID=%BUILD_ID%;BUILT_BY=%BUILT_BY%;
rem If console variable is not empty append console define to project build defines
IF %CONSOLE%==1 SET PovBuildDefs=%PovBuildDefs%_CONSOLE=1;
rem If verbose variable is not empty append tracing define to project build defines
IF %VERBOSE%==1 SET PovBuildDefs=%PovBuildDefs%WIN_DEBUG=1;

rem Display the define attributes to visually confirm all is well.
ECHO   MSVS_DEV_VERSION....[%DEV_ENV%]
ECHO   RELEASE.............[%RELEASE%]
ECHO   VERSION_MAJ.........[%VERSION_MAJ%]
ECHO   VERSION_MIN.........[%VERSION_MIN%]
ECHO   VERSION_REV.........[%VERSION_REV%]
ECHO   VERSION_PATCH.......[%VERSION_PATCH%]
ECHO   VERSION_BASE........[%VERSION_BASE%]
ECHO   BUILD_ID.(GIT_SHA)..[%BUILD_ID%]
ECHO   BUILT_BY............[%BUILT_BY%]
GOTO :EOF

:CLEAN
rem A little routine to remove quotes and trailing space
SETLOCAL ENABLEDELAYEDEXPANSION
SET INPUT=%*
SET INPUT=%INPUT:"=%
FOR /F "tokens=1*" %%a IN ("!INPUT!") DO ENDLOCAL & SET %1=%%b
EXIT /b

