@echo off
:: Launch the viewer with STA to support WinForms/clipboard reliably, detached from the batch console
start "GIF Viewer" powershell -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0gif_viewer.ps1" %*
