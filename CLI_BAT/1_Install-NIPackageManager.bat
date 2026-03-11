@echo off
REM Install NI Package Manager Script
REM Runs silent installation, adds to PATH, and verifies with nipkg help

REM Check for administrator privileges
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Starting NI Package Manager installation...
echo.

SET "INSTALLER=%~dp0NIPackageManager26.0.0_online.exe"
SET "NIPKG_PATH=C:\Program Files\National Instruments\NI Package Manager"

REM Check if installer exists
if not exist "%INSTALLER%" (
    echo ERROR: Installer not found at %INSTALLER%
    exit /b 1
)

REM Run silent installation
echo Installing NI Package Manager (this may take a few minutes)...
"%INSTALLER%" /quiet /acceptlicenses yes
if %ERRORLEVEL% NEQ 0 (
    echo Installation failed with exit code: %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo Installation completed successfully!
echo.

REM Check if NI Package Manager was installed
if not exist "%NIPKG_PATH%" (
    echo ERROR: NI Package Manager not found at %NIPKG_PATH%
    exit /b 1
)

REM Add to PATH environment variable (requires admin rights)
echo Adding NI Package Manager to PATH...
echo.

REM Check if already in PATH
echo %PATH% | find /i "%NIPKG_PATH%" >nul
if %ERRORLEVEL% EQU 0 (
    echo NI Package Manager is already in PATH
) else (
    REM Add to system PATH (requires admin)
    setx PATH "%PATH%;%NIPKG_PATH%" /M >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo Added to system PATH successfully!
        REM Update current session PATH
        set "PATH=%PATH%;%NIPKG_PATH%"
    ) else (
        echo Warning: Could not modify system PATH (requires administrator privileges^)
        echo You can manually add '%NIPKG_PATH%' to your PATH
        REM Add to user PATH as fallback
        setx PATH "%PATH%;%NIPKG_PATH%" >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            echo Added to user PATH instead
            set "PATH=%PATH%;%NIPKG_PATH%"
        )
    )
)

echo.
echo Running 'nipkg update' to refresh package feeds...
echo ======================================================================

REM Run nipkg update
"%NIPKG_PATH%\nipkg.exe" update
if %ERRORLEVEL% NEQ 0 (
    echo Warning: nipkg update failed
) else (
    echo Package feeds updated successfully!
)

echo ======================================================================
echo.
echo Adding custom feed 'serial_25.8'...
echo ======================================================================

SET "FEED_PATH=\\argo\ni\nipkg\feeds\ni-5\ni-5690\20.0.0\20.0.0.49152-0+f0"
SET "FEED_NAME=NI-5690_20.0"


REM Add the feed
"%NIPKG_PATH%\nipkg.exe" feed-add --name="%FEED_NAME%" "%FEED_PATH%"
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Failed to add feed %FEED_NAME%
) else (
    echo Feed %FEED_NAME% added successfully!
)

echo.
echo Installing packages from %FEED_NAME% feed...
echo ======================================================================

REM Install packages from the feed
"%NIPKG_PATH%\nipkg.exe" install ni-serial --accept-eulas --yes
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Package installation failed or no packages available
) else (
    echo Packages installed successfully!
)

echo ======================================================================
echo.
echo Running 'nipkg help' to verify installation...
echo ======================================================================

REM Run nipkg help
"%NIPKG_PATH%\nipkg.exe" help
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to run nipkg help
    exit /b 1
)

echo ======================================================================
echo Installation and verification completed successfully!
echo.
echo You may need to restart your terminal for PATH changes to take effect.
timeout 5
exit /b 0
