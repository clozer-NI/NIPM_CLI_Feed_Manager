@echo off
setlocal EnableDelayedExpansion

REM Remove all configured NI Package Manager feeds

REM ======================================================================
REM Check for administrator privileges
REM ======================================================================
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ======================================================================
echo NI Package Manager - Remove All Feeds
echo ======================================================================
echo.

set "NIPKG_EXE=C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"

if not exist "%NIPKG_EXE%" (
    echo ERROR: nipkg.exe was not found.
    echo Expected path: %NIPKG_EXE%
    pause
    exit /b 1
)

echo Current feeds:
"%NIPKG_EXE%" feed-list
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to list feeds.
    pause
    exit /b 1
)

echo.
set /P CONFIRM=Type YES to remove ALL listed feeds: 
if /I not "%CONFIRM%"=="YES" (
    echo Cancelled.
    pause
    exit /b 0
)

set /A TOTAL=0
set /A REMOVED=0
set /A FAILED=0

echo.
echo Removing feeds...
echo.

for /F "skip=2 tokens=1" %%F in ('"%NIPKG_EXE%" feed-list') do (
    set "FEED_NAME=%%F"

    if not "!FEED_NAME!"=="" if /I not "!FEED_NAME!"=="Name" if not "!FEED_NAME:~0,1!"=="-" (
        set /A TOTAL+=1
        echo Removing: !FEED_NAME!
        "%NIPKG_EXE%" feed-remove "!FEED_NAME!" --yes
        if !ERRORLEVEL! EQU 0 (
            set /A REMOVED+=1
            echo   SUCCESS
        ) else (
            set /A FAILED+=1
            echo   FAILED with code !ERRORLEVEL!
        )
        echo.
    )
)

echo ======================================================================
echo Feed removal summary
echo ======================================================================
echo Total found:   %TOTAL%
echo Removed:       %REMOVED%
echo Failed:        %FAILED%
echo.

if %TOTAL% EQU 0 (
    echo No feeds were found to remove.
)

echo Remaining feeds:
"%NIPKG_EXE%" feed-list
echo.
pause
exit /b 0
