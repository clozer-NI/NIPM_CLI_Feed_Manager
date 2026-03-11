@echo off
:: ============================================================
:: 4_Uninstall-NI-Packages.bat
:: Uninstalls NI packages using the NI Package Manager
:: (nipkg) CLI.
:: Requires NI Package Manager to be installed.
:: Requires Administrator privileges.
::
:: Usage options (edit the section below):
::   A) Remove specific packages by name
::   B) Remove all NI software EXCEPT NI Package Manager
::   C) Remove ALL NI software INCLUDING NI Package Manager
:: ============================================================

setlocal

set "NIPKG=C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"

if not exist "%NIPKG%" (
    echo ERROR: nipkg.exe not found at:
    echo   %NIPKG%
    echo Please install NI Package Manager first (run 1_Install-NIPackageManager.bat).
    pause
    exit /b 1
)

:: ============================================================
:: OPTION A – Uninstall specific packages (default).
:: List the package names to remove, separated by spaces.
:: Obtain package names with: nipkg list-installed
:: ============================================================
set "PACKAGES_TO_REMOVE=ni-labview ni-daqmx ni-visa"

echo The following packages will be removed:
echo   %PACKAGES_TO_REMOVE%
echo.
set /p CONFIRM="Are you sure you want to uninstall these packages? [Y/N]: "
if /i not "%CONFIRM%"=="Y" (
    echo Uninstall cancelled.
    pause
    exit /b 0
)

echo.
echo Uninstalling packages...
"%NIPKG%" remove --allow-uninstall --yes %PACKAGES_TO_REMOVE%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Packages removed successfully.
) else (
    echo.
    echo ERROR: Uninstall encountered an error (exit code %ERRORLEVEL%).
    pause
    exit /b %ERRORLEVEL%
)

:: ============================================================
:: OPTION B – Remove ALL NI software except NI Package Manager
:: Uncomment the lines below and comment out Option A above.
:: ============================================================
:: echo Removing all NI software (NI Package Manager will remain)...
:: "%NIPKG%" remove --yes

:: ============================================================
:: OPTION C – Remove ALL NI software INCLUDING NI Package Manager
:: Uncomment the lines below and comment out Option A above.
:: ============================================================
:: echo Removing ALL NI software including NI Package Manager...
:: "%NIPKG%" remove --force-essential --force-locked --yes

endlocal
pause
