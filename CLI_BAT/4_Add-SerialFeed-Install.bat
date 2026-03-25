@echo off
REM Add NI Feeds and Install Packages Script
REM Maps \\argo\ni\nipkg to X: drive and adds custom feeds

REM ======================================================================
REM CONFIGURATION - Edit these variables to add different feeds/packages
REM ======================================================================
REM To add more feeds, duplicate the feed sections below and update paths
SET "FEED1_PATH=X:\feeds\ni-b\ni-bluetooth-toolkit\20.0.1\20.0.1.49152-0+f0"
SET "FEED1_NAME=NI-Bluetooth-Toolkit_20_0_1"
SET "PACKAGE1=ni-bluetooth-toolkit"

REM Example for additional feeds (uncomment and configure as needed):
REM SET "FEED2_PATH=X:\feeds\ni-5\ni-5690\20.0.0\20.0.0.49152-0+f0"
REM SET "FEED2_NAME=NI-5690_20_0"
REM SET "PACKAGE2=ni-5690"
REM ======================================================================

REM Check for administrator privileges
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Adding NI Feeds and Installing Packages...
echo.

SET "NIPKG_PATH=C:\Program Files\National Instruments\NI Package Manager"

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

echo ======================================================================
echo Adding Feed 1: '%FEED1_NAME%'...
echo ======================================================================

REM Add the first feed
"%NIPKG_PATH%\nipkg.exe" feed-add --name="%FEED1_NAME%" "%FEED1_PATH%"
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Failed to add feed %FEED1_NAME%
    echo Error code: %ERRORLEVEL%
) else (
    echo Feed %FEED1_NAME% added successfully!
)

REM To add more feeds, uncomment and configure FEED2, FEED3, etc. at the top
REM Then duplicate this section:
REM echo.
REM echo ======================================================================
REM echo Adding Feed 2: '%FEED2_NAME%'...
REM echo ======================================================================
REM "%NIPKG_PATH%\nipkg.exe" feed-add --name="%FEED2_NAME%" "%FEED2_PATH%"
REM if %ERRORLEVEL% NEQ 0 (
REM     echo Warning: Failed to add feed %FEED2_NAME%
REM     echo Error code: %ERRORLEVEL%
REM ) else (
REM     echo Feed %FEED2_NAME% added successfully!
REM )

echo.
echo Updating package feeds...
"%NIPKG_PATH%\nipkg.exe" update
echo.

echo ======================================================================
echo Installing Package 1: '%PACKAGE1%'...
echo ======================================================================

REM Install the first package
"%NIPKG_PATH%\nipkg.exe" install %PACKAGE1% --accept-eulas --yes
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Package installation failed or no packages available
    echo Error code: %ERRORLEVEL%
) else (
    echo Package %PACKAGE1% installed successfully!
)

REM To install additional packages, uncomment and duplicate:
REM echo.
REM echo ======================================================================
REM echo Installing Package 2: '%PACKAGE2%'...
REM echo ======================================================================
REM "%NIPKG_PATH%\nipkg.exe" install %PACKAGE2% --accept-eulas --yes
REM if %ERRORLEVEL% NEQ 0 (
REM     echo Warning: Package installation failed
REM     echo Error code: %ERRORLEVEL%
REM ) else (
REM     echo Package %PACKAGE2% installed successfully!
REM )

echo ======================================================================
echo.
echo Listing installed feeds...
"%NIPKG_PATH%\nipkg.exe" feed-list

echo.
echo ======================================================================
echo Listing all installed packages (showing last 20)...
"%NIPKG_PATH%\nipkg.exe" list-installed | findstr /v "^$" | more +2 | tail -20

echo.
echo ======================================================================
echo Operation completed!
echo.
echo Network drive X: remains connected for future use.
echo Use this script again to add more feeds by editing the configuration section.
echo.
pause
exit /b 0
