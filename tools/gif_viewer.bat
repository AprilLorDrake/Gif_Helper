@echo off
:: Launch the viewer with STA to support WinForms/clipboard reliably.
:: Defaults to hidden/detached so closing the app closes PowerShell too.
:: Enable debug console with /debug (or -debug) or GIF_VIEWER_DEBUG=1.

@setlocal
@set DEBUG_FLAG=0

set SCRIPT_PATH=%~dp0gif_viewer.ps1

if /I "%1"=="/debug" (set DEBUG_FLAG=1 & shift)
if /I "%1"=="-debug" (set DEBUG_FLAG=1 & shift)
if "%GIF_VIEWER_DEBUG%"=="1" set DEBUG_FLAG=1

if %DEBUG_FLAG%==1 (
	set GIF_VIEWER_DEBUG=1
	echo Launching "%SCRIPT_PATH%" with debug...
	powershell -NoProfile -STA -ExecutionPolicy Bypass -NoExit -File "%SCRIPT_PATH%" %*
) else (
	powershell -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT_PATH%" %*
)

@endlocal
