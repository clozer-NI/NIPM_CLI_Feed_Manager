@echo off
setlocal EnableDelayedExpansion

echo ======================================================================
echo NI Package Manager - Likely Software Bundles Export
echo ======================================================================
echo.

set "NIPKG_EXE=C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"
set "PS_SCRIPT=%~dp0List-Likely-Software-Bundles.ps1"
set "OUT_FILE=%~dp0software_bundles.txt"
set "DETAIL_FILE=%~dp0software_bundles_detailed.txt"
set "PATTERN=*"

if not exist "%NIPKG_EXE%" (
    echo ERROR: nipkg.exe was not found.
    echo Expected path: %NIPKG_EXE%
    pause
    exit /b 1
)

if not exist "%PS_SCRIPT%" (
    echo ERROR: PowerShell helper script not found.
    echo Expected path: %PS_SCRIPT%
    pause
    exit /b 1
)

echo Optional package name filter.
echo Examples: ni-*, ni-labview*, ni-vision*
set /p PATTERN="Pattern [default: *]: "

if "%PATTERN%"=="" (
    set "PATTERN=*"
)

echo.
echo Scanning package metadata for likely top-level software bundles...
echo This can take a while because nipkg info is queried for each package.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -NipkgPath "%NIPKG_EXE%" -Pattern "%PATTERN%" -OutFile "%OUT_FILE%" -DetailFile "%DETAIL_FILE%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not evaluate package metadata.
    pause
    exit /b 1
)

set "BUNDLE_COUNT=0"
for /f %%C in ('powershell -NoProfile -Command "if (Test-Path -LiteralPath \"%OUT_FILE%\") { (Get-Content -LiteralPath \"%OUT_FILE%\" ^| Measure-Object -Line).Lines } else { 0 }"') do set "BUNDLE_COUNT=%%C"

echo Done.
echo - Bundle names: %OUT_FILE%
echo - Bundle details: %DETAIL_FILE%
echo - Likely bundle count: %BUNDLE_COUNT%
echo.
echo Detail file columns:
echo package-name [TAB] display-name [TAB] version [TAB] section
echo.
pause
exit /b 0