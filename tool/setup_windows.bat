@echo off
setlocal

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter was not found on PATH.
  echo Install Flutter from https://docs.flutter.dev/get-started/install/windows
  exit /b 1
)

cd /d "%~dp0\.."

rem The Android, web and Windows runners are tracked in the repo with the app ID
rem com.TetherHealthLLC.tetherhealth, so this script does not regenerate any runner.

echo Downloading packages...
flutter pub get
if errorlevel 1 exit /b 1

echo Running analysis...
flutter analyze
if errorlevel 1 exit /b 1

echo Running tests...
flutter test
if errorlevel 1 exit /b 1

echo.
echo BreatheFree setup passed.
echo Run tool\run_windows.bat for the native Windows app.
echo Run flutter run -d chrome for the browser version.
