@echo off
setlocal EnableExtensions
chcp 65001 >nul
title CedarDSH Model Probe - Install

set "SCRIPT_DIR=%~dp0"
set "APP_DIR="
call :find_app "%SCRIPT_DIR%"
if defined APP_DIR goto app_found
call :find_app "%SCRIPT_DIR%.."
if defined APP_DIR goto app_found

echo CedarDSH Desktop was not found.
echo Put this extracted plugin folder inside the CedarDSH Desktop folder,
echo beside CedarDSH-Desktop.exe and dsh.cmd, then run this file again.
goto failed

:app_found
set "PLUGIN_ARCHIVE="
for %%F in ("%SCRIPT_DIR%CedarDSH-Model-Probe-v*.tgz") do set "PLUGIN_ARCHIVE=%%~fF"
if not exist "%PLUGIN_ARCHIVE%" (
  echo The CedarDSH Model Probe TGZ was not found beside this installer.
  echo Extract every file from the Windows plugin ZIP, then try again.
  goto failed
)
for %%F in ("%PLUGIN_ARCHIVE%") do set "PLUGIN_FILE=%%~nxF"

call :confirm_desktop_closed

set "PROFILE_DIR=%APP_DIR%dsh-home\profiles\web"
set "PACKAGE_DIR=%PROFILE_DIR%\plugin-packages"
if not exist "%PACKAGE_DIR%" mkdir "%PACKAGE_DIR%"
if not exist "%PACKAGE_DIR%" (
  echo Could not create the plugin package folder:
  echo %PACKAGE_DIR%
  goto failed
)

copy /Y "%PLUGIN_ARCHIVE%" "%PACKAGE_DIR%\%PLUGIN_FILE%" >nul
if errorlevel 1 (
  echo Could not copy the plugin package into the CedarDSH profile.
  goto failed
)

pushd "%APP_DIR%"
call "%APP_DIR%dsh.cmd" plugin --profile web add "file:plugin-packages/%PLUGIN_FILE%" --offline --ignore-scripts
set "RESULT=%ERRORLEVEL%"
popd
if not "%RESULT%"=="0" (
  echo.
  echo Installation failed with exit code %RESULT%.
  goto failed
)

set "PROFILE_MANIFEST=%PROFILE_DIR%\package.json"
"%APP_DIR%runtime\node.exe" -e "const p=require(process.argv[1]);const n='@maiziman/dsh-model-capabilities';process.exit(p.dependencies?.[n]&&p.dsh?.profile?.bundles?.includes(n)?0:1)" "%PROFILE_MANIFEST%"
if errorlevel 1 (
  echo CedarDSH did not register the plugin in the web profile.
  goto failed
)
if not exist "%PROFILE_DIR%\node_modules\@maiziman\dsh-model-capabilities\package.json" (
  echo CedarDSH registered the plugin but its installed files are missing.
  goto failed
)

for %%F in ("%PACKAGE_DIR%\CedarDSH-Model-Probe-v*.tgz") do if /I not "%%~nxF"=="%PLUGIN_FILE%" del /Q "%%~fF" >nul 2>nul

echo.
echo CedarDSH Model Probe was installed successfully.
echo Reopen CedarDSH Desktop. In Settings ^> Plugins ^> Global Plugins,
echo search for: model-capabilities
echo.
pause
exit /b 0

:find_app
set "CANDIDATE="
for %%D in ("%~1") do set "CANDIDATE=%%~fD\"
if not exist "%CANDIDATE%dsh.cmd" exit /b 0
if not exist "%CANDIDATE%runtime\node.exe" exit /b 0
if exist "%CANDIDATE%CedarDSH-Desktop.exe" set "APP_DIR=%CANDIDATE%"
if exist "%CANDIDATE%DeepSeek-Harness.exe" set "APP_DIR=%CANDIDATE%"
exit /b 0

:confirm_desktop_closed
echo.
echo Close CedarDSH Desktop and any CedarDSH window started from dsh.cmd.
echo Press any key only after they are closed.
pause >nul
if /I "%CEDARDSH_INSTALLER_TEST_MODE%"=="1" exit /b 0

:wait_for_desktop
tasklist /FI "IMAGENAME eq CedarDSH-Desktop.exe" 2>nul | find /I "CedarDSH-Desktop.exe" >nul
if not errorlevel 1 goto desktop_running
tasklist /FI "IMAGENAME eq DeepSeek-Harness.exe" 2>nul | find /I "DeepSeek-Harness.exe" >nul
if not errorlevel 1 goto desktop_running
exit /b 0

:desktop_running
echo.
echo Close CedarDSH Desktop, then press any key to continue.
echo Also close any CedarDSH window started from dsh.cmd.
pause >nul
goto wait_for_desktop

:failed
echo.
echo No administrator access is required. Keep this window open to read the error above.
pause
exit /b 1
