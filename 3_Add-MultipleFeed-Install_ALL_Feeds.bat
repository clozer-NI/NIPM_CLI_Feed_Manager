@echo off
:: ============================================================
:: 3_Add-MultipleFeed-Install_ALL_Feeds.bat
:: Adds multiple NI offline feeds from \\argo\ni\nipkg and
:: installs ALL available packages from those feeds.
:: Requires NI Package Manager to be installed.
:: Requires Administrator privileges.
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

:: ============================================================
:: Define the feeds to add.
:: Add or remove feed entries below as needed.
:: Format: feed-add --name="<FeedName>" "<FeedPath>"
:: ============================================================

echo Adding NI offline feeds...

"%NIPKG%" feed-add --name="NI-Main"          "\\argo\ni\nipkg"
"%NIPKG%" feed-add --name="NI-LabVIEW"       "\\argo\ni\nipkg\labview"
"%NIPKG%" feed-add --name="NI-DAQmx"         "\\argo\ni\nipkg\daqmx"
"%NIPKG%" feed-add --name="NI-VISA"          "\\argo\ni\nipkg\visa"
"%NIPKG%" feed-add --name="NI-Serial"        "\\argo\ni\nipkg\serial"

echo.
echo Refreshing feed metadata...
"%NIPKG%" feed-update

echo.
echo ============================================================
echo  Installing ALL packages from configured feeds
echo ============================================================
:: Install all available packages by iterating over the feed list output.
:: Each token on the first column of "nipkg list" is a package name.
for /f "usebackq tokens=1" %%p in (`"%NIPKG%" list`) do (
    echo Installing: %%p
    "%NIPKG%" install --yes --accept-eulas %%p
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo All packages installed successfully.
) else (
    echo.
    echo WARNING: One or more packages may not have installed correctly.
    echo          Check the output above for details (exit code %ERRORLEVEL%).
    pause
    exit /b %ERRORLEVEL%
)

endlocal
pause
