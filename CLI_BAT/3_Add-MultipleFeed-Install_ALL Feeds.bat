@echo off
setlocal enabledelayedexpansion
REM Add Multiple NI Feeds Script
REM Maps \\argo\ni\nipkg to X: drive and adds all feeds from a list

REM ======================================================================
REM CONFIGURATION OPTIONS
REM ======================================================================
REM Option 1: Edit feeds.txt file with feed paths (one per line)
REM Option 2: Set AUTO_DISCOVER=yes to auto-find feeds in a directory
REM Option 3: List feed paths directly below in this script
REM 
REM INSTALL_PACKAGES - Set to "yes" to auto-install packages after adding feeds
REM ======================================================================

SET "AUTO_DISCOVER=no"
SET "DISCOVER_PATH=X:\feeds"
SET "INSTALL_PACKAGES=yes"

REM ======================================================================
REM Check for administrator privileges
REM ======================================================================
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ======================================================================
echo NI Package Manager - Bulk Feed Installer
echo ======================================================================
echo Configuration:
echo   - Auto-discover: %AUTO_DISCOVER%
echo   - Install packages: %INSTALL_PACKAGES%
echo   - Running as: Administrator
echo ======================================================================
echo ======================================================================
echo.

SET "NIPKG_PATH=C:\Program Files\National Instruments\NI Package Manager"
SET "SCRIPT_DIR=%~dp0"

REM Check if NI Package Manager exists
if not exist "%NIPKG_PATH%\nipkg.exe" (
    echo ERROR: NI Package Manager not found at %NIPKG_PATH%
    echo Please install NI Package Manager first.
    pause
    exit /b 1
)

echo ======================================================================
echo Mapping network drive to \\argo\ni\nipkg...
echo ======================================================================

SET StartDir=\\argo\ni\nipkg

REM Loop until we know StartDir exists and net use does not return an error 
:loop 

net use x: /delete /yes >nul 2>&1
net use x: %StartDir% /user:amer\nitest nitest /persistent:no 

if not %errorlevel%==0 (
   REM Try the command without the user
   net use x: %StartDir% /persistent:no 
)

if not %errorlevel%==0 (
   REM We are still erroring, so wait 10 seconds and try the whole loop again
   echo Retrying network connection...
   ping -n 10 localhost>nul 
   GOTO loop
)

echo Network drive X: mapped successfully!
echo.

REM ======================================================================
REM Process feeds from file if it exists
REM ======================================================================

SET "FEED_FILE=%SCRIPT_DIR%feeds.txt"

if exist "%FEED_FILE%" (
    echo ======================================================================
    echo Reading feed paths from feeds.txt...
    echo ======================================================================
    echo.
    
    for /F "usebackq tokens=* delims=" %%F in ("%FEED_FILE%") do (
        SET "FEED_PATH=%%F"
        
        REM Skip empty lines and comments
        if not "!FEED_PATH!"=="" (
            if not "!FEED_PATH:~0,1!"=="#" (
                call :AddFeed "!FEED_PATH!"
            )
        )
    )
) else (
    echo No feeds.txt file found. Create one with feed paths, one per line.
    echo Example: X:\feeds\ni-b\ni-bluetooth-toolkit\20.0.1\20.0.1.49152-0+f0
    echo.
)

REM ======================================================================
REM Auto-discover feeds if enabled
REM ======================================================================

if /I "%AUTO_DISCOVER%"=="yes" (
    echo ======================================================================
    echo Auto-discovering feeds in %DISCOVER_PATH%...
    echo ======================================================================
    echo.
    
    for /D /R "%DISCOVER_PATH%" %%D in (*.*.*-0+f*) do (
        if exist "%%D\Packages.txt" (
            call :AddFeed "%%D"
        )
    )
)

REM ======================================================================
REM Update all feeds
REM ======================================================================

echo.
echo ======================================================================
echo Updating all package feeds...
echo ======================================================================
"%NIPKG_PATH%\nipkg.exe" update
echo.

REM ======================================================================
REM List all configured feeds
REM ======================================================================

echo ======================================================================
echo Currently configured feeds:
echo ======================================================================
"%NIPKG_PATH%\nipkg.exe" feed-list
echo.

echo ======================================================================
echo Operation completed!
echo.
echo Network drive X: remains connected for future use.
echo.
echo To add more feeds:
echo   1. Create/edit feeds.txt with feed paths (one per line)
echo   2. Or set AUTO_DISCOVER=yes to auto-find feeds
echo   3. Or call this script with feed paths as arguments
echo.
pause
exit /b 0

REM ======================================================================
REM Subroutine to add a feed
REM ======================================================================
:AddFeed
SET "FULL_PATH=%~1"

REM Extract version directory from path (last folder)
for %%I in ("%FULL_PATH%") do (
    SET "VERSION_DIR=%%~nI"
)

REM Get parent folder (version number like 24.8.0)
for %%I in ("%FULL_PATH%\..") do (
    SET "VERSION_NUM=%%~nxI"
)

REM Get product name (2 levels up)
for %%I in ("%FULL_PATH%\..\..") do (
    SET "PRODUCT_NAME=%%~nxI"
)

REM Clean up product name and create feed name
SET "FEED_NAME=%PRODUCT_NAME%_%VERSION_NUM%"
SET "FEED_NAME=%FEED_NAME:.=_%"
SET "FEED_NAME=%FEED_NAME:-=_%"
SET "FEED_NAME=%FEED_NAME:+=_%"

REM Ensure the name starts with a letter (prepend NI_ if it starts with a number)
SET "FIRST_CHAR=%FEED_NAME:~0,1%"
echo %FIRST_CHAR%| findstr /r "^[0-9]$" >nul
if %ERRORLEVEL% EQU 0 (
    SET "FEED_NAME=NI_%FEED_NAME%"
)

echo Adding feed: %FEED_NAME%
echo Path: %FULL_PATH%

"%NIPKG_PATH%\nipkg.exe" feed-add --name="%FEED_NAME%" "%FULL_PATH%"
if %ERRORLEVEL% NEQ 0 (
    if %ERRORLEVEL% EQU -125006 (
        echo   [SKIP] Feed already exists
    ) else if %ERRORLEVEL% EQU -125003 (
        echo   [ERROR] Invalid feed name - names must start with a letter
        goto :eof
    ) else (
        echo   [WARNING] Failed to add feed with error code: %ERRORLEVEL%
        goto :eof
    )
) else (
    echo   [SUCCESS] Feed added!
)

REM Install main package if enabled (runs whether feed is new or already exists)
if /I "%INSTALL_PACKAGES%"=="yes" (
    echo   Installing package: %PRODUCT_NAME%
    "%NIPKG_PATH%\nipkg.exe" install %PRODUCT_NAME% --accept-eulas --yes
    if %ERRORLEVEL% NEQ 0 (
        echo   [ERROR] Installation failed with error code: %ERRORLEVEL%
    ) else (
        echo   [SUCCESS] Package installed!
    )
)
echo.

goto :eof
