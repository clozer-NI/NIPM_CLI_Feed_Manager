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
set "AVAILABLE_FILE=%~dp0available_packages.txt"
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

if not exist "%NIPKG_EXE%" (
    echo ERROR: nipkg.exe was not found.
    echo Expected path: %NIPKG_EXE%
    pause
    exit /b 1
)

if not exist "%ALL_FILE%" (
    echo ERROR: feed.txt not found.
    echo Run 2_List-WebFeed-Packages-to-feed.bat first.
    pause
    exit /b 1
)

if not exist "%AVAILABLE_FILE%" (
    echo ERROR: available_packages.txt not found.
    echo Run 2_List-WebFeed-Packages-to-feed.bat first.
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
echo Version limit prefix: %VERSION_LIMIT%
echo.

for /F "usebackq tokens=* delims=" %%P in ("%LIST_FILE%") do (
    set "PKG=%%P"
    if not "!PKG!"=="" (
        if not "!PKG:~0,1!"=="#" (
            set "INSTALL_SPEC=!PKG!"
            set "HAS_VERSION="
            for /f "tokens=1,2 delims==" %%A in ("!PKG!") do (
                if not "%%B"=="" set "HAS_VERSION=1"
            )

            if not defined HAS_VERSION (
                for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$name = $env:PKG; $prefix = $env:VERSION_LIMIT; $rows = Get-Content -Path $env:AVAILABLE_FILE ^| ForEach-Object { if($_ -match '^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\s+([0-9]+\.[0-9]+\.[0-9]+\.[^\s]+)\s+'){ [pscustomobject]@{Name=$matches[1]; Version=$matches[2]} } } ^| Where-Object { $_ -and $_.Name -eq $name -and $_.Version.StartsWith($prefix) } ^| Sort-Object Version -Descending; if($rows){ ($rows ^| Select-Object -First 1).Version }"`) do (
                    set "RESOLVED_VERSION=%%V"
                )

                if defined RESOLVED_VERSION (
                    set "INSTALL_SPEC=!PKG!=!RESOLVED_VERSION!"
                    set "RESOLVED_VERSION="
                ) else (
                    echo     WARNING: No matching version for !PKG! with prefix %VERSION_LIMIT%; using default resolution.
                )
            )

            set /A TOTAL+=1
            echo [!TOTAL!] Installing !INSTALL_SPEC! ...
            "%NIPKG_EXE%" install --accept-eulas --yes --allow-downgrade "!INSTALL_SPEC!"
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
