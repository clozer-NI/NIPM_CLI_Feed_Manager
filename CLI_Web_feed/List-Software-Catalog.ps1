param(
    [Parameter(Mandatory = $true)]
    [string]$NipkgPath,

    [Parameter(Mandatory = $true)]
    [string]$Pattern,

    [Parameter(Mandatory = $true)]
    [string]$TsvFile,

    [Parameter(Mandatory = $true)]
    [string]$CsvFile
)

$ErrorActionPreference = 'Stop'

function Get-LanguageName {
    param(
        [string]$PackageName,
        [string]$DisplayName
    )

    $suffixMap = @{
        '-en' = 'English'
        '-de' = 'German'
        '-fr' = 'French'
        '-ja' = 'Japanese'
        '-ko' = 'Korean'
        '-zh-cn' = 'Chinese (Simplified)'
    }

    foreach ($suffix in $suffixMap.Keys) {
        if ($PackageName.ToLowerInvariant().EndsWith($suffix)) {
            return $suffixMap[$suffix]
        }
    }

    if ($DisplayName -match 'English') { return 'English' }
    if ($DisplayName -match 'Deutsch|German|Englisch') { return 'German' }
    if ($DisplayName -match 'French|Francais|Français|Anglais') { return 'French' }
    if ($DisplayName -match 'Japanese|日本語|英語版') { return 'Japanese' }
    if ($DisplayName -match 'Korean|한국어|영어 버전') { return 'Korean' }
    if ($DisplayName -match 'Chinese|中文') { return 'Chinese (Simplified)' }

    return 'Any'
}

function Get-Bitness {
    param(
        [string]$PackageName,
        [string]$DisplayName,
        [string]$Architecture
    )

    if ($DisplayName -match '32-bit|32 Bit|32位|32ビット|32비트') { return '32-bit' }
    if ($DisplayName -match '64-bit|64 Bit|64位|64ビット|64비트') { return '64-bit' }
    if ($PackageName -match 'x86$') { return '32-bit' }
    if ($Architecture -eq 'windows_x64') { return '64-bit' }
    return $Architecture
}

function Get-ProductName {
    param(
        [string]$DisplayName
    )

    $name = $DisplayName
    $name = $name -replace '\s*\((32|64)-bit\)', ''
    $name = $name -replace '\s*\((32|64) Bit\)', ''
    $name = $name -replace '\s+English$', ''
    $name = $name -replace '\s+-\s+Anglais$', ''
    $name = $name -replace '\s+-\s+Englisch$', ''
    $name = $name -replace '\s+英语版$', ''
    $name = $name -replace '\s+영어 버전$', ''
    return $name.Trim()
}

$listLines = & $NipkgPath list $Pattern 2>$null

$packageNames = $listLines |
    ForEach-Object {
        if ($_ -match '^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\b' -and $_ -notmatch '^\s*(Package|Name|Version|Feed|---)') {
            $matches[1]
        }
    } |
    Where-Object { $_ -and $_.Trim() -ne '' } |
    Sort-Object -Unique

$rows = [System.Collections.Generic.List[object]]::new()
$seen = [System.Collections.Generic.HashSet[string]]::new()

foreach ($packageName in $packageNames) {
    $infoLines = & $NipkgPath info $packageName 2>$null
    if (-not $infoLines) {
        continue
    }

    $blocks = [System.Collections.Generic.List[object]]::new()
    $currentBlock = [System.Collections.Generic.List[string]]::new()

    foreach ($line in $infoLines) {
        if ($line -match '^Architecture:' -and $currentBlock.Count -gt 0) {
            $blocks.Add(@($currentBlock.ToArray())) | Out-Null
            $currentBlock = [System.Collections.Generic.List[string]]::new()
        }
        $currentBlock.Add([string]$line) | Out-Null
    }

    if ($currentBlock.Count -gt 0) {
        $blocks.Add(@($currentBlock.ToArray())) | Out-Null
    }

    foreach ($block in $blocks) {
        if (-not ($block | Select-String '^StoreProduct:\s+yes')) {
            continue
        }
        if (-not ($block | Select-String '^UserVisible:\s+yes')) {
            continue
        }

        $package = ((($block | Select-String '^Package:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value) -as [string]).Trim()
        $displayName = ((($block | Select-String '^DisplayName:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value) -as [string]).Trim()
        $displayVersion = ((($block | Select-String '^DisplayVersion:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value) -as [string]).Trim()
        $version = ((($block | Select-String '^Version:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value) -as [string]).Trim()
        $section = ((($block | Select-String '^Section:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value) -as [string]).Trim()
        $architecture = ((($block | Select-String '^Architecture:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value) -as [string]).Trim()

        if ([string]::IsNullOrWhiteSpace($package) -or [string]::IsNullOrWhiteSpace($displayName)) {
            continue
        }

        $key = '{0}|{1}' -f $package, $version
        if (-not $seen.Add($key)) {
            continue
        }

        $rows.Add([pscustomobject]@{
            Product        = Get-ProductName -DisplayName $displayName
            Package        = $package
            DisplayName    = $displayName
            DisplayVersion = $displayVersion
            Bitness        = Get-Bitness -PackageName $package -DisplayName $displayName -Architecture $architecture
            Language       = Get-LanguageName -PackageName $package -DisplayName $displayName
            Section        = $section
            Version        = $version
        }) | Out-Null
    }
}

$sortedRows = $rows | Sort-Object Product, DisplayVersion, Bitness, Language, Package, Version

$filteredRows = $sortedRows | Where-Object {
    $_.Bitness -eq '64-bit' -and ($_.Language -eq 'English' -or $_.Language -eq 'Any')
}

$filteredRows |
    ForEach-Object {
        "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}" -f $_.Product, $_.Package, $_.DisplayName, $_.DisplayVersion, $_.Bitness, $_.Language, $_.Section, $_.Version
    } |
    Set-Content -Path $TsvFile -Encoding ASCII

$filteredRows | Export-Csv -Path $CsvFile -NoTypeInformation -Encoding ASCII