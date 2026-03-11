@echo off
:: ============================================================
:: 2_Browse-NI-Feeds.bat
:: Lists currently configured feeds and installed NI packages
:: using the NI Package Manager (nipkg) CLI.
:: Requires NI Package Manager to be installed.
:: ============================================================

setlocal

set "NIPKG=C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"

if not exist "%NIPKG%" (
    echo ERROR: nipkg.exe not found at:
    echo   %NIPKG%
    echo Please install NI Package Manager first (run 1_Install-NIPackageManager.bat).
    pause
    exit /b 1
)

echo ============================================================
echo  Configured Feeds
echo ============================================================
"%NIPKG%" feed-list
echo.

echo ============================================================
echo  Available Packages (from all configured feeds)
echo ============================================================
"%NIPKG%" list
echo.

echo ============================================================
echo  Installed NI Packages
echo ============================================================
"%NIPKG%" list-installed
echo.

endlocal
pause
