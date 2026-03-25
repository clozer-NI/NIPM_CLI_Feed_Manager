# Install NI Package Manager Script
# Runs silent installation, adds to PATH, and verifies with nipkg help

Write-Host "Starting NI Package Manager installation..." -ForegroundColor Cyan

# Get the installer path
$installerPath = Join-Path $PSScriptRoot "NIPackageManager26.0.0_online.exe"

if (-not (Test-Path $installerPath)) {
    Write-Host "ERROR: Installer not found at $installerPath" -ForegroundColor Red
    exit 1
}

# Run silent installation
Write-Host "Installing NI Package Manager (this may take a few minutes)..." -ForegroundColor Yellow
$installProcess = Start-Process -FilePath $installerPath -ArgumentList "/quiet", "/acceptlicenses", "yes" -Wait -PassThru

if ($installProcess.ExitCode -ne 0) {
    Write-Host "Installation failed with exit code: $($installProcess.ExitCode)" -ForegroundColor Red
    exit $installProcess.ExitCode
}

Write-Host "Installation completed successfully!" -ForegroundColor Green

# Define the NI Package Manager path
$nipkgPath = "C:\Program Files\National Instruments\NI Package Manager"

# Check if the path exists
if (-not (Test-Path $nipkgPath)) {
    Write-Host "ERROR: NI Package Manager not found at $nipkgPath" -ForegroundColor Red
    exit 1
}

# Add to PATH environment variable (Machine level - requires admin rights)
Write-Host "Adding NI Package Manager to PATH..." -ForegroundColor Yellow

try {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    
    if ($currentPath -notlike "*$nipkgPath*") {
        $newPath = $currentPath + ";" + $nipkgPath
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Host "Added to system PATH successfully!" -ForegroundColor Green
        
        # Update current session PATH
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    } else {
        Write-Host "NI Package Manager is already in PATH" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Warning: Could not modify system PATH (may require administrator privileges)" -ForegroundColor Yellow
    Write-Host "You can manually add '$nipkgPath' to your PATH" -ForegroundColor Yellow
}

# Run nipkg help to verify installation
Write-Host "`nRunning 'nipkg help' to verify installation..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

try {
    & "$nipkgPath\nipkg.exe" help
    Write-Host "`n" + "=" * 70 -ForegroundColor Gray
    Write-Host "Installation and verification completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to run nipkg help: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nYou may need to restart your terminal for PATH changes to take effect." -ForegroundColor Cyan
