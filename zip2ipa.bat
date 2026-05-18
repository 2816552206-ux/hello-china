@echo off
setlocal enabledelayedexpansion
echo === ZIP to IPA Converter ===
echo.

if "%~1"=="" (
    echo Usage: drag runner.app.zip onto this bat file
    echo    or: zip2ipa.bat runner.app.zip
    pause
    exit /b 1
)

set "ZIP_FILE=%~1"

if not exist "%ZIP_FILE%" (
    echo File not found: %ZIP_FILE%
    pause
    exit /b 1
)

echo Input: %ZIP_FILE%

:: temp dir
set "TMP_DIR=%TEMP%\ipa_build"
rmdir /s /q "%TMP_DIR%" 2>nul
mkdir "%TMP_DIR%"

:: extract zip using PowerShell
echo Extracting...
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%ZIP_FILE%' -DestinationPath '%TMP_DIR%' -Force"

:: find Runner.app
set "APP_PATH="
for /r "%TMP_DIR%" /d %%i in (Runner.app) do (
    if not defined APP_PATH set "APP_PATH=%%i"
)

if not defined APP_PATH (
    echo ERROR: Runner.app not found in zip
    pause
    exit /b 1
)

echo Found: !APP_PATH!

:: build Payload structure
set "PAYLOAD_DIR=%TMP_DIR%\Payload"
mkdir "%PAYLOAD_DIR%" 2>nul
move "!APP_PATH!" "%PAYLOAD_DIR%\" >nul 2>&1

if not exist "%PAYLOAD_DIR%\Runner.app" (
    echo Copying files...
    xcopy "!APP_PATH!" "%PAYLOAD_DIR%\Runner.app\" /E /I /Q
)

:: Create IPA (zip then rename)
for %%f in ("%ZIP_FILE%") do set "OUT_DIR=%%~dpf"
set "ZIP_TMP=%OUT_DIR%Runner_tmp.zip"
set "IPA_FILE=%OUT_DIR%Runner.ipa"
echo Creating IPA...
powershell -NoProfile -Command "Compress-Archive -LiteralPath '%PAYLOAD_DIR%' -DestinationPath '%ZIP_TMP%' -Force"
if exist "%ZIP_TMP%" (
    move /y "%ZIP_TMP%" "%IPA_FILE%" >nul
)

:: cleanup
rmdir /s /q "%TMP_DIR%" 2>nul

echo.
echo === DONE ===
echo IPA saved to: %IPA_FILE%
echo.
echo Install with 3uTools or AltStore
pause
