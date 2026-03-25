@echo off
setlocal EnableDelayedExpansion

echo ======================================================================
echo NI Package Manager - Available Package Export
echo ======================================================================
echo.

set "NIPKG_EXE=C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"
set "OUT_FILE=%~dp0feed.txt"
set "RAW_FILE=%~dp0feed_raw.txt"
set "ALL_FILE=%~dp0available_packages.txt"
set "SELECT_FILE=%~dp0selected_packages.txt"

if not exist "%NIPKG_EXE%" (
    echo ERROR: nipkg.exe was not found.
    echo Expected path: %NIPKG_EXE%
    echo Install NI Package Manager first.
    pause
    exit /b 1
)

echo.
echo Exporting all available package/driver entries...
"%NIPKG_EXE%" list > "%RAW_FILE%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not query package list.
    pause
    exit /b 1
)

copy /y "%RAW_FILE%" "%ALL_FILE%" >nul

powershell -NoProfile -Command "$raw = Get-Content -Path $env:RAW_FILE; $pkgs = foreach($line in $raw){ if($line -match '^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\b' -and $line -notmatch '^\s*(Package|Name|Version|Feed|---)'){ $matches[1] } }; $pkgs | Sort-Object -Unique | Set-Content -Path $env:OUT_FILE -Encoding ASCII"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not parse package list into feed.txt.
    del /q "%RAW_FILE%" >nul 2>&1
    pause
    exit /b 1
)

del /q "%RAW_FILE%" >nul 2>&1

if not exist "%SELECT_FILE%" (
    > "%SELECT_FILE%" echo # Put package names here, one per line, then run 2_Install-Selected-Packages-from-file.bat
)

echo.
echo Done.
echo - Full available list: %ALL_FILE%
echo - Package names only: %OUT_FILE%
echo - Selection file: %SELECT_FILE%
echo.
echo Tip: use available_packages.txt to browse all versions/feeds, then put desired package names in selected_packages.txt.
echo.
pause
exit /b 0
