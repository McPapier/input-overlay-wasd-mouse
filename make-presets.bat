@echo off
rem Rebuilds keyboard\ and mouse\ from keyboard-layout.txt.
rem Optional: make-presets.bat #FF4FA3   (highlight color)
cd /d "%~dp0"
if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "tools\make-presets.ps1"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "tools\make-presets.ps1" -Accent "%~1"
)
echo.
pause
