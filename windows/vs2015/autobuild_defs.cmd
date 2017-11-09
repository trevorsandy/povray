@ECHO OFF
Title LPub3D-Trace on Windows auto build script

rem This script sets the LPub3D-Trace preprocessor defines
rem needed to build the solution/project.

rem This script is intended to be called from autobuild.cmd
rem --
rem  Trevor SANDY <trevor.sandy@gmail.com>
rem  Last Update: September 03, 2017
rem  Copyright (c) 2017 by Trevor SANDY
rem --
rem This script is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

rem It is expected that this script will reside in .\windows\vs2015

rem Variables
SET DEV_ENV=unknown
SET GIT_SHA=unknown
SET VERSION_MAJ=unknown
SET VERSION_MIN=unknown
SET RELEASE=unknown
SET VERSION_H="..\..\source\base\version.h"

rem Get some source details to populate the required defines
rem These are not fixed. You can change as you like
FOR /F "tokens=3*" %%i IN ('FINDSTR /c:"#define POV_RAY_MAJOR_VERSION_INT" %VERSION_H%') DO SET VERSION_MAJ=%%i
FOR /F "tokens=3*" %%i IN ('FINDSTR /c:"#define POV_RAY_MINOR_VERSION_INT" %VERSION_H%') DO SET VERSION_MIN=%%i
FOR /F "tokens=3*" %%i IN ('FINDSTR /c:"#define POV_RAY_PRERELEASE" %VERSION_H%') DO SET RELEASE=%%i
IF "%APPVEYOR%" EQU "True" (
  SET GIT_SHA=%APPVEYOR_REPO_COMMIT:~0,8%
) ELSE (
  FOR /F "tokens=* USEBACKQ" %%i IN (`git rev-parse --short HEAD`) DO SET GIT_SHA=%%i
)
FOR /F "tokens=* USEBACKQ" %%i IN (`msbuild -nologo -version`) DO SET DEV_ENV=%%i

rem Remove quotes and trailing space
CALL :CLEAN VERSION_MAJ %VERSION_MAJ%
CALL :CLEAN VERSION_MIN %VERSION_MIN%
CALL :CLEAN RELEASE %RELEASE%

rem Build version number
SET VERSION_BASE="%VERSION_MAJ%.%VERSION_MIN%"
rem POV-Ray documentation would like you to use "YOUR NAME (YOUR EMAIL)" here.
SET BUILT_BY="Trevor SANDY<trevor.sandy@gmail.com> for LPub3D using MSBuild v%DEV_ENV%"
rem Here I use the git sha. You can change if you're not building from a local git repository.
SET BUILD_ID="%GIT_SHA%"

rem Set project build defines - configured to build GUI project at this stage
SET PovBuildDefs=POV_RAY_IS_AUTOBUILD=1;VERSION_BASE=%VERSION_BASE%;POV_RAY_BUILD_ID=%BUILD_ID%;BUILT_BY=%BUILT_BY%;
rem If console variable is not empty append console define to project build defines
IF %CONSOLE%==1 SET PovBuildDefs=%PovBuildDefs%_CONSOLE=1;
rem If verbose variable is not empty append tracing define to project build defines
IF %VERBOSE%==1 SET PovBuildDefs=%PovBuildDefs%WIN_DEBUG=1;

rem Display the define attributes to visually confirm all is well.
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
  ECHO   DIST_DIRECTORY......[%DIST_DIR_ROOT%]
)
ECHO   VERSION_MAJ.........[%VERSION_MAJ%]
ECHO   VERSION_MIN.........[%VERSION_MIN%]
ECHO   RELEASE.............[%RELEASE%]
ECHO   GIT_SHA.............[%GIT_SHA%]
ECHO   DEV_ENV.............[%DEV_ENV%]
ECHO   VERSION_BASE........[%VERSION_BASE%]
ECHO   BUILD_ID............[%BUILD_ID%]
ECHO   BUILT_BY............[%BUILT_BY%]
GOTO :END

:CLEAN
rem A little routine to remove quotes and trailing space
SETLOCAL ENABLEDELAYEDEXPANSION
SET INPUT=%*
SET INPUT=%INPUT:"=%
FOR /F "tokens=1*" %%a IN ("!INPUT!") DO ENDLOCAL & SET %1=%%b
EXIT /b

:END
rem Done
