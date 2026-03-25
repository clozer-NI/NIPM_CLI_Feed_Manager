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
set "VERSION_LIMIT="

echo.
echo Enter version limit prefix (e.g., 25.8., 26.0.) or 0 to skip version filtering:
set /p VERSION_LIMIT="Version limit [default: 25.8.]: "

if "%VERSION_LIMIT%"==" " (
    set "VERSION_LIMIT=25.8."
)

if "%VERSION_LIMIT%"=="0" (
    set "VERSION_LIMIT="
)

set "LIMIT_FILE=%~dp0feed_%VERSION_LIMIT%x.txt"

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

if not "%VERSION_LIMIT%"==" " (
    powershell -NoProfile -Command "$prefix = $env:VERSION_LIMIT; $raw = Get-Content -Path $env:RAW_FILE; $rows = foreach($line in $raw){ if($line -match '^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\s+([0-9]+\.[0-9]+\.[0-9]+\.[^\s]+)\s+'){ [pscustomobject]@{Name=$matches[1]; Version=$matches[2]} } }; $rows | Where-Object { $_.Version.StartsWith($prefix) } | Sort-Object Name, Version -Unique | ForEach-Object { '{0}={1}' -f $_.Name, $_.Version } | Set-Content -Path $env:LIMIT_FILE -Encoding ASCII"
    if !ERRORLEVEL! NEQ 0 (
        echo ERROR: Could not build version-limited feed file.
        del /q "%RAW_FILE%" >nul 2>&1
        pause
        exit /b 1
    )
) else (
    echo Skipping version-limited feed generation.
)

del /q "%RAW_FILE%" >nul 2>&1

if not exist "%SELECT_FILE%" (
    > "%SELECT_FILE%" echo # Put package names here, one per line, then run 3_Install-Selected-Packages-from-file.bat
)

echo.
echo Done.
echo - Full available list: %ALL_FILE%
echo - Package names only: %OUT_FILE%
if not "%VERSION_LIMIT%"==" " (
    echo - Version-limited package list: %LIMIT_FILE%
)
echo - Selection file: %SELECT_FILE%
echo.
pause
exit /b 0
