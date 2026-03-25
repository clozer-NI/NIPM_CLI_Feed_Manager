@echo off
setlocal enabledelayedexpansion
REM Uninstall NI Package Manager and Packages Script
REM Removes all NI packages, feeds, and NI Package Manager itself

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
echo NI Package Manager - Uninstaller
echo ======================================================================
echo This script will:
echo   1. List all installed NI packages
echo   2. Remove all custom feeds
echo   3. Uninstall all NI packages
echo   4. Remove NI Package Manager from PATH
echo   5. Uninstall NI Package Manager
echo ======================================================================
echo.

SET "NIPKG_PATH=C:\Program Files\National Instruments\NI Package Manager"

REM Check if NI Package Manager exists
if not exist "%NIPKG_PATH%\nipkg.exe" (
    echo NI Package Manager not found at %NIPKG_PATH%
    echo Nothing to uninstall.
    echo.
    pause
    exit /b 0
)

REM ======================================================================
REM Step 1: List all installed packages
REM ======================================================================

echo ======================================================================
echo Step 1: Listing all installed NI packages...
echo ======================================================================
echo.

"%NIPKG_PATH%\nipkg.exe" list --installed
echo.

echo ======================================================================
echo Do you want to continue with uninstallation?
echo ======================================================================
echo WARNING: This will remove ALL NI packages and the Package Manager!
echo.
SET /P CONFIRM="Type 'YES' to continue or 'NO' to cancel: "

if /I not "%CONFIRM%"=="YES" (
    echo Uninstallation cancelled.
    pause
    exit /b 0
)

echo.
echo Proceeding with uninstallation...
echo.

REM ======================================================================
REM Step 2: Remove all custom feeds
REM ======================================================================

echo ======================================================================
echo Step 2: Removing custom feeds...
echo ======================================================================
echo.

REM List all feeds
echo Current feeds:
"%NIPKG_PATH%\nipkg.exe" feed-list

echo.
echo Removing custom feeds...

REM Get feed names and remove them (skip ni.com feeds)
for /f "skip=2 tokens=1" %%F in ('"%NIPKG_PATH%\nipkg.exe" feed-list') do (
    SET "FEED_NAME=%%F"
    
    REM Skip if it's a ni.com feed or empty
    if not "!FEED_NAME!"=="" (
        echo !FEED_NAME! | findstr /i "ni.com" >nul
        if !ERRORLEVEL! NEQ 0 (
            echo   Removing feed: !FEED_NAME!
            "%NIPKG_PATH%\nipkg.exe" feed-remove !FEED_NAME! --yes
            if !ERRORLEVEL! NEQ 0 (
                echo   [WARNING] Failed to remove feed: !FEED_NAME!
            ) else (
                echo   [SUCCESS] Removed feed: !FEED_NAME!
            )
        )
    )
)

echo.

REM ======================================================================
REM Step 3: Uninstall all NI packages
REM ======================================================================

echo ======================================================================
echo Step 3: Uninstalling all NI packages...
echo ======================================================================
echo This may take several minutes...
echo.

REM Get list of installed packages and uninstall them
for /f "skip=2 tokens=1" %%P in ('"%NIPKG_PATH%\nipkg.exe" list --installed') do (
    SET "PKG_NAME=%%P"
    
    if not "!PKG_NAME!"=="" (
        echo   Uninstalling: !PKG_NAME!
        "%NIPKG_PATH%\nipkg.exe" remove !PKG_NAME! --yes --accept-eulas
        if !ERRORLEVEL! NEQ 0 (
            echo   [WARNING] Failed to uninstall: !PKG_NAME!
        ) else (
            echo   [SUCCESS] Uninstalled: !PKG_NAME!
        )
        echo.
    )
)

echo All packages processed.
echo.

REM ======================================================================
REM Step 4: Remove NI Package Manager from PATH
REM ======================================================================

echo ======================================================================
echo Step 4: Removing NI Package Manager from PATH...
echo ======================================================================
echo.

REM Use PowerShell to safely remove from PATH
powershell -Command "$path = [Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($path -like '*%NIPKG_PATH%*') { $newPath = ($path.Split(';') | Where-Object { $_ -ne '%NIPKG_PATH%' }) -join ';'; [Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine'); Write-Host '[SUCCESS] Removed from system PATH' } else { Write-Host '[INFO] Not found in system PATH' }"

powershell -Command "$path = [Environment]::GetEnvironmentVariable('Path', 'User'); if ($path -like '*%NIPKG_PATH%*') { $newPath = ($path.Split(';') | Where-Object { $_ -ne '%NIPKG_PATH%' }) -join ';'; [Environment]::SetEnvironmentVariable('Path', $newPath, 'User'); Write-Host '[SUCCESS] Removed from user PATH' } else { Write-Host '[INFO] Not found in user PATH' }"

echo.

REM ======================================================================
REM Step 5: Uninstall NI Package Manager
REM ======================================================================

echo ======================================================================
echo Step 5: Uninstalling NI Package Manager...
echo ======================================================================
echo.

REM Find the uninstaller using wmic
echo Searching for NI Package Manager uninstaller...

for /f "tokens=*" %%U in ('wmic product where "Name like '%%NI Package Manager%%'" get UninstallString /value 2^>nul') do (
    SET "LINE=%%U"
    if not "!LINE!"=="" (
        SET "LINE=!LINE:UninstallString=!"
        SET "UNINSTALLER=!LINE:~1!"
    )
)

if not defined UNINSTALLER (
    echo Could not find automatic uninstaller.
    echo.
    echo Opening Control Panel to uninstall manually...
    appwiz.cpl
    echo.
    echo Please manually uninstall "NI Package Manager" from the Control Panel.
    echo.
) else (
    echo Running uninstaller: !UNINSTALLER!
    echo This may take a few minutes...
    start /wait "" !UNINSTALLER! /quiet
    
    if !ERRORLEVEL! NEQ 0 (
        echo [WARNING] Uninstaller returned error code: !ERRORLEVEL!
    ) else (
        echo [SUCCESS] NI Package Manager uninstalled!
    )
)

echo.
echo ======================================================================
echo Uninstallation Complete!
echo ======================================================================
echo.
echo NI Package Manager and all associated packages have been removed.
echo You may need to restart your terminal for PATH changes to take effect.
echo.
pause
exit /b 0
