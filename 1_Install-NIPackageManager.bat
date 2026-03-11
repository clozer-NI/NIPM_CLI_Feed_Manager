@echo off
:: ============================================================
:: 1_Install-NIPackageManager.bat
:: Silently installs NI Package Manager (NIPM) from the
:: standard offline network location: \\argo\ni\nipkg
:: Requires Administrator privileges.
:: ============================================================

setlocal

:: Path to the NI Package Manager installer on the network share
set "NIPM_INSTALLER=\\argo\ni\nipkg\install\install.exe"

:: Verify that the installer is reachable
if not exist "%NIPM_INSTALLER%" (
    echo ERROR: Installer not found at %NIPM_INSTALLER%
    echo Please verify the network share is accessible and the path is correct.
    pause
    exit /b 1
)

echo Installing NI Package Manager...
echo Source: %NIPM_INSTALLER%

start "" /wait "%NIPM_INSTALLER%" --passive --accept-eulas --prevent-reboot

if %ERRORLEVEL% EQU 0 (
    echo NI Package Manager installed successfully.
) else (
    echo ERROR: Installation failed with exit code %ERRORLEVEL%.
    pause
    exit /b %ERRORLEVEL%
)

endlocal
pause
