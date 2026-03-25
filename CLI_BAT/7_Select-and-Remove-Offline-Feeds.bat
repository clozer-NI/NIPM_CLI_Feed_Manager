@echo off
setlocal EnableDelayedExpansion

echo ======================================================================
echo NI Package Manager - Select and Remove Offline Feeds
echo ======================================================================
echo.

set "NIPKG_EXE=C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"

if not exist "%NIPKG_EXE%" (
    echo ERROR: nipkg.exe was not found.
    echo Expected path: %NIPKG_EXE%
    pause
    exit /b 1
)

echo.
echo Fetching all feeds...
echo.

REM Create temporary file for feed list
set "TEMP_FEED_LIST=%TEMP%\nipkg_feeds_temp.txt"
"%NIPKG_EXE%" feed-list > "%TEMP_FEED_LIST%"

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not retrieve feed list.
    del /q "%TEMP_FEED_LIST%" >nul 2>&1
    pause
    exit /b 1
)

echo Feeds currently configured:
echo.
echo ONLINE FEEDS (HTTPS - Recommended to keep):
echo ============================================
findstr /i "https" "%TEMP_FEED_LIST%"
echo.
echo.
echo OFFLINE FEEDS (Local/Network - May cause errors if not accessible):
echo ===================================================================
findstr /v /i "https" "%TEMP_FEED_LIST%"
echo.
echo.

echo Would you like to remove offline feeds? (y/n): 
set /p REMOVE_OFFLINE="Enter choice: "

if /i not "%REMOVE_OFFLINE%"=="y" (
    echo Operation cancelled.
    del /q "%TEMP_FEED_LIST%" >nul 2>&1
    pause
    exit /b 0
)

echo.
echo Select which offline feeds to remove by entering their numbers (comma-separated):
echo Example: 1,2,3
echo.
echo Or type 'all' to remove all offline feeds at once.
echo.

set /p FEED_SELECTION="Your selection: "

if /i "%FEED_SELECTION%"=="all" (
    echo.
    echo Removing all offline feeds...
    echo.
    
    set /A TOTAL=0
    set /A SUCCESS=0
    set /A FAILED=0
    
    REM Extract feed names that are not HTTPS and remove them
    for /f "usebackq tokens=1 delims= " %%F in (`findstr /v /i "https" "%TEMP_FEED_LIST%"`) do (
        if not "%%F"=="" (
            set /A TOTAL+=1
            echo [!TOTAL!] Removing %%F ...
            "%NIPKG_EXE%" feed-remove "%%F"
            if !ERRORLEVEL! NEQ 0 (
                set /A FAILED+=1
                echo     FAILED
            ) else (
                set /A SUCCESS+=1
                echo     SUCCESS
            )
            echo.
        )
    )
    
    echo ======================================================================
    echo Removal summary
    echo ======================================================================
    echo Total feeds removed: %TOTAL%
    echo Successful:          %SUCCESS%
    echo Failed:              %FAILED%
    
) else (
    echo.
    echo Manual selection not yet implemented in this version.
    echo Please use option 'all' or run 4_Remove-offline-feeds.bat for the default removal.
)

del /q "%TEMP_FEED_LIST%" >nul 2>&1
echo.
pause
exit /b 0
