<#
.SYNOPSIS
    Builds a clean release ZIP of HNZHealingTools, ready to upload to
    CurseForge, Wago.io or WoWInterface.

.DESCRIPTION
    Reads the version from HNZHealingTools.toc, copies the addon files
    (excluding development artifacts) into a temp staging folder under a
    top-level "HNZHealingTools/" directory, and zips the result into
    .\dist\HNZHealingTools-<version>.zip.

    The "HNZHealingTools/" wrapper is required: WoW addon installers expect
    the top-level folder inside the ZIP to match the AddOn folder name.

.EXAMPLE
    .\Build-Package.ps1
    # Produces .\dist\HNZHealingTools-1.0.28.zip
#>

[CmdletBinding()]
param(
    [string]$OutputDir = (Join-Path $PSScriptRoot 'dist')
)

$ErrorActionPreference = 'Stop'
$AddonName = 'HNZHealingTools'
$Root      = $PSScriptRoot

# --- Read version from .toc -------------------------------------------------
$Toc = Join-Path $Root "$AddonName.toc"
if (-not (Test-Path $Toc)) { throw "Cannot find $Toc" }

$Version = (Get-Content $Toc | Where-Object { $_ -match '^\s*##\s*Version:\s*(.+)$' } |
            ForEach-Object { $Matches[1].Trim() } | Select-Object -First 1)
if (-not $Version) { throw "Could not parse '## Version:' line from $AddonName.toc" }

Write-Host "Building $AddonName v$Version" -ForegroundColor Cyan

# --- Files / folders to include in the release -----------------------------
# Whitelist approach: only ship what the addon needs at runtime + docs.
$IncludeFiles = @(
    "$AddonName.toc",
    'README.md',
    'CHANGELOG.md',
    'LICENSE',
    'Core.lua',
    'Utils.lua',
    'SpellMonitor.lua',
    'AuraMonitor.lua',
    'CursorDisplay.lua',
    'RingDisplay.lua',
    'CooldownPulse.lua',
    'CursorRing.lua',
    'MrtTimeline.lua',
    'Config.lua',
    'Minimap.lua'
)
$IncludeDirs = @('Locales', 'Textures')

# --- Stage in a temp folder -------------------------------------------------
$Staging = Join-Path ([System.IO.Path]::GetTempPath()) "$AddonName-build-$([Guid]::NewGuid().ToString('N'))"
$AddonStaging = Join-Path $Staging $AddonName
New-Item -ItemType Directory -Path $AddonStaging -Force | Out-Null

try {
    foreach ($file in $IncludeFiles) {
        $src = Join-Path $Root $file
        if (Test-Path $src) {
            Copy-Item -LiteralPath $src -Destination $AddonStaging -Force
        } else {
            Write-Warning "Skipping missing file: $file"
        }
    }

    foreach ($dir in $IncludeDirs) {
        $src = Join-Path $Root $dir
        if (Test-Path $src) {
            Copy-Item -LiteralPath $src -Destination $AddonStaging -Recurse -Force
        } else {
            Write-Warning "Skipping missing directory: $dir"
        }
    }

    # --- Sanity: refuse to ship if dev folders sneak in -------------------
    $forbidden = @('.claude', 'memory', '.git', 'dist')
    foreach ($bad in $forbidden) {
        if (Test-Path (Join-Path $AddonStaging $bad)) {
            throw "Forbidden folder '$bad' ended up in the staging directory. Aborting."
        }
    }

    # --- Zip it -----------------------------------------------------------
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    $ZipPath = Join-Path $OutputDir "$AddonName-$Version.zip"
    if (Test-Path $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }

    Compress-Archive -Path (Join-Path $Staging '*') -DestinationPath $ZipPath -CompressionLevel Optimal

    Write-Host ""
    Write-Host "Built: $ZipPath" -ForegroundColor Green
    Write-Host "Size : $([Math]::Round((Get-Item $ZipPath).Length / 1KB, 1)) KB" -ForegroundColor Green
    Write-Host ""
    Write-Host "Contents:" -ForegroundColor Cyan
    # Show what's inside without extracting
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $zip.Entries | Sort-Object FullName | ForEach-Object {
            "  {0,8} bytes  {1}" -f $_.Length, $_.FullName
        }
    } finally {
        $zip.Dispose()
    }
}
finally {
    if (Test-Path $Staging) {
        Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}
