@echo off
setlocal EnableDelayedExpansion

REM Installation requires admin rights.
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ======================================================================
echo NI Package Manager - Install Selected Packages
echo ======================================================================
echo.

set "NIPKG_EXE=C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"
set "LIST_FILE=%~dp0selected_packages.txt"
set "ALL_FILE=%~dp0feed.txt"

if not exist "%NIPKG_EXE%" (
    echo ERROR: nipkg.exe was not found.
    echo Expected path: %NIPKG_EXE%
    pause
    exit /b 1
)

if not exist "%ALL_FILE%" (
    echo ERROR: feed.txt not found.
    echo Run 1_List-WebFeed-Packages-to-feed.bat first.
    pause
    exit /b 1
)

if not exist "%LIST_FILE%" (
    > "%LIST_FILE%" echo # Add package names here, one per line. Lines starting with # are ignored.
    echo Created %LIST_FILE%
    echo.
    echo Opening feed.txt and selected_packages.txt for editing...
    start notepad "%ALL_FILE%"
    start notepad "%LIST_FILE%"
    echo.
    echo Save selected_packages.txt and run this installer again.
    pause
    exit /b 0
)

set /A TOTAL=0
set /A SUCCESS=0
set /A FAILED=0

echo Installing packages from: %LIST_FILE%
echo.

for /F "usebackq tokens=* delims=" %%P in ("%LIST_FILE%") do (
    set "PKG=%%P"
    if not "!PKG!"=="" (
        if not "!PKG:~0,1!"=="#" (
            set /A TOTAL+=1
            echo [!TOTAL!] Installing !PKG! ...
            "%NIPKG_EXE%" install --accept-eulas --yes "!PKG!"
            if !ERRORLEVEL! NEQ 0 (
                set /A FAILED+=1
                echo     FAILED with code !ERRORLEVEL!
            ) else (
                set /A SUCCESS+=1
                echo     SUCCESS
            )
            echo.
        )
    )
)

echo ======================================================================
echo Install summary
echo ======================================================================
echo Total requested: %TOTAL%
echo Successful:      %SUCCESS%
echo Failed:          %FAILED%
echo.

if %TOTAL% EQU 0 (
    echo No packages were found in selected_packages.txt.
    echo Add package names (one per line) and run again.
)

pause
exit /b 0
