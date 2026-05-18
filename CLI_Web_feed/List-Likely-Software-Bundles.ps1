param(
    [Parameter(Mandatory = $true)]
    [string]$NipkgPath,

    [Parameter(Mandatory = $true)]
    [string]$Pattern,

    [Parameter(Mandatory = $true)]
    [string]$OutFile,

    [Parameter(Mandatory = $true)]
    [string]$DetailFile
)

$ErrorActionPreference = 'Stop'

$raw = & $NipkgPath list $Pattern 2>$null

$packages = $raw |
    ForEach-Object {
        if ($_ -match '^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\b' -and $_ -notmatch '^\s*(Package|Name|Version|Feed|---)') {
            $matches[1]
        }
    } |
    Where-Object { $_ -and $_.Trim() -ne '' } |
    Sort-Object -Unique

$bundleNames = [System.Collections.Generic.List[string]]::new()
$detailLines = [System.Collections.Generic.List[string]]::new()

foreach ($package in $packages) {
    $infoLines = & $NipkgPath info $package 2>$null
    if (-not $infoLines) {
        continue
    }

    $hasStore = @($infoLines | Select-String '^StoreProduct:\s+yes').Count -gt 0
    $hasVisible = @($infoLines | Select-String '^UserVisible:\s+yes').Count -gt 0

    if (-not ($hasStore -and $hasVisible)) {
        continue
    }

    if ($bundleNames.Contains($package)) {
        continue
    }

    $displayName = (($infoLines | Select-String '^DisplayName:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value).Trim()
    $section = (($infoLines | Select-String '^Section:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value).Trim()
    $version = (($infoLines | Select-String '^Version:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value).Trim()

    if ([string]::IsNullOrWhiteSpace($displayName)) {
        $displayName = $package
    }

    $bundleNames.Add($package) | Out-Null
    $detailLines.Add(("{0}`t{1}`t{2}`t{3}" -f $package, $displayName, $version, $section)) | Out-Null
}

Set-Content -Path $OutFile -Value ($bundleNames | Sort-Object) -Encoding ASCII
Set-Content -Path $DetailFile -Value ($detailLines | Sort-Object) -Encoding ASCII