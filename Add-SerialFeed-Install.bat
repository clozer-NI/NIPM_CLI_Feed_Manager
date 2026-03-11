@echo off
:: ============================================================
:: Add-SerialFeed-Install.bat
:: Adds the NI-Serial offline feed from \\argo\ni\nipkg\serial
:: and installs NI-Serial (NI Serial) packages.
:: Requires NI Package Manager to be installed.
:: Requires Administrator privileges.
:: ============================================================

setlocal

set "NIPKG=C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"
set "SERIAL_FEED_PATH=\\argo\ni\nipkg\serial"
set "SERIAL_FEED_NAME=NI-Serial"

if not exist "%NIPKG%" (
    echo ERROR: nipkg.exe not found at:
    echo   %NIPKG%
    echo Please install NI Package Manager first (run 1_Install-NIPackageManager.bat).
    pause
    exit /b 1
)

echo Adding NI-Serial offline feed...
echo   Name: %SERIAL_FEED_NAME%
echo   Path: %SERIAL_FEED_PATH%
echo.

"%NIPKG%" feed-add --name="%SERIAL_FEED_NAME%" "%SERIAL_FEED_PATH%"

echo.
echo Refreshing feed metadata...
"%NIPKG%" feed-update

echo.
echo ============================================================
echo  Installing NI-Serial packages
echo ============================================================
"%NIPKG%" install --yes --accept-eulas ni-serial

if %ERRORLEVEL% EQU 0 (
    echo.
    echo NI-Serial packages installed successfully.
) else (
    echo.
    echo ERROR: Installation failed with exit code %ERRORLEVEL%.
    pause
    exit /b %ERRORLEVEL%
)

endlocal
pause
