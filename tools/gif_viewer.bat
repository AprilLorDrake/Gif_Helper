@echo off
:: Launch the viewer with STA to support WinForms/clipboard reliably
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0gif_viewer.ps1" %*
