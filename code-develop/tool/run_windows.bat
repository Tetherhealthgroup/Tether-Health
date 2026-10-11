@echo off
setlocal
cd /d "%~dp0\.."

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter was not found on PATH.
  exit /b 1
)

flutter run -d windows
