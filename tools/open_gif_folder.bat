@echo off
setlocal EnableExtensions

REM open_gif_folder.bat
REM Wrapper for PowerShell: creates/opens the GIF folder and copies path to clipboard.
REM Usage:
REM   open_gif_folder.bat
REM   open_gif_folder.bat "D:\Media"
REM   open_gif_folder.bat /?

set "ARG1=%~1"
if /I "%ARG1%"=="/?" goto :help
if /I "%ARG1%"=="-h" goto :help
if /I "%ARG1%"=="--help" goto :help

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul

if "%ARG1%"=="" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%open_gif_folder.ps1"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%open_gif_folder.ps1" -BaseFolder "%ARG1%" -NonInteractive
)

set "ERR=%ERRORLEVEL%"
popd >nul
endlocal & exit /b %ERR%

:help
echo open_gif_folder.bat
echo Creates/opens your GIF folder and copies the path to clipboard.
echo.
echo Usage:
echo   open_gif_folder.bat
echo   open_gif_folder.bat "D:\Media"
echo.
echo Tip: In Explorer, press Alt+P to toggle the Preview pane.
exit /b 0