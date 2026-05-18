@echo off
setlocal EnableDelayedExpansion

echo ======================================================================
echo NI Package Manager - Software Catalog Export
echo ======================================================================
echo.

set "NIPKG_EXE=C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"
set "PS_SCRIPT=%~dp0List-Software-Catalog.ps1"
set "TSV_FILE=%~dp0software_catalog.tsv"
set "CSV_FILE=%~dp0software_catalog.csv"
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

echo Enter a package filter to narrow the catalog.
echo Examples: *  ni-labview*  ni-vision*  ni-package-builder*
set /p PATTERN="Pattern [default: *]: "

if "%PATTERN%"=="" (
    set "PATTERN=*"
)

echo.
echo Building a software catalog from top-level user-visible NI packages...
echo Output is limited to 64-bit and English or language-neutral packages.
echo This can take a while because package metadata is queried for each match.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -NipkgPath "%NIPKG_EXE%" -Pattern "%PATTERN%" -TsvFile "%TSV_FILE%" -CsvFile "%CSV_FILE%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not build software catalog.
    pause
    exit /b 1
)

set "ROW_COUNT=0"
for /f %%C in ('powershell -NoProfile -Command "if (Test-Path -LiteralPath \"%TSV_FILE%\") { (Get-Content -LiteralPath \"%TSV_FILE%\" ^| Measure-Object -Line).Lines } else { 0 }"') do set "ROW_COUNT=%%C"

echo Done.
echo - Catalog TSV: %TSV_FILE%
echo - Catalog CSV: %CSV_FILE%
echo - Rows exported: %ROW_COUNT%
echo.
echo TSV columns:
echo Product [TAB] Package [TAB] DisplayName [TAB] DisplayVersion [TAB] Bitness [TAB] Language [TAB] Section [TAB] Version
echo.
pause
exit /b 0