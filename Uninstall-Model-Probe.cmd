@echo off
setlocal EnableExtensions
chcp 65001 >nul
title CedarDSH Model Probe - Uninstall

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
call :confirm_desktop_closed

set "PROFILE_DIR=%APP_DIR%dsh-home\profiles\web"
set "PROFILE_MANIFEST=%PROFILE_DIR%\package.json"
if not exist "%PROFILE_MANIFEST%" goto already_removed
"%APP_DIR%runtime\node.exe" -e "const p=require(process.argv[1]);const n='@maiziman/dsh-model-capabilities';process.exit(p.dependencies?.[n]||p.dsh?.profile?.bundles?.includes(n)?0:1)" "%PROFILE_MANIFEST%"
if errorlevel 1 goto already_removed

pushd "%APP_DIR%"
call "%APP_DIR%dsh.cmd" plugin --profile web remove @maiziman/dsh-model-capabilities
set "RESULT=%ERRORLEVEL%"
popd
if not "%RESULT%"=="0" (
  echo.
  echo Removal failed with exit code %RESULT%.
  goto failed
)

"%APP_DIR%runtime\node.exe" -e "const p=require(process.argv[1]);const n='@maiziman/dsh-model-capabilities';process.exit(!p.dependencies?.[n]&&!p.dsh?.profile?.bundles?.includes(n)?0:1)" "%PROFILE_MANIFEST%"
if errorlevel 1 (
  echo CedarDSH still lists the plugin in the web profile.
  goto failed
)

call :remove_archives
echo.
echo CedarDSH Model Probe was removed successfully.
echo Previously saved model capability settings were kept.
echo Reopen CedarDSH Desktop to finish removal.
echo.
pause
exit /b 0

:already_removed
call :remove_archives
echo.
echo CedarDSH Model Probe is already removed.
echo Previously saved model capability settings were kept.
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

:remove_archives
set "PACKAGE_DIR=%PROFILE_DIR%\plugin-packages"
if exist "%PACKAGE_DIR%" del /Q "%PACKAGE_DIR%\CedarDSH-Model-Probe-v*.tgz" >nul 2>nul
exit /b 0

:failed
echo.
echo No administrator access is required. Keep this window open to read the error above.
pause
exit /b 1
