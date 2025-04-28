#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour les composants MCP vers la dernière version.
.DESCRIPTION
    Ce script met à jour les composants MCP (npm, pip, binaires) vers
    la dernière version disponible et crée une sauvegarde avant la mise à jour.
.PARAMETER SkipBackup
    Ignore la création d'une sauvegarde avant la mise à jour.
.PARAMETER Components
    Liste des composants à mettre à jour (All, Npm, Pip, Binary). Par défaut: All.
.EXAMPLE
    .\update-mcp-components.ps1 -Components Npm,Pip
    Met à jour uniquement les composants npm et pip.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipBackup,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Npm", "Pip", "Binary")]
    [string[]]$Components = @("All")
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$versioningRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $versioningRoot).Parent.FullName
$projectRoot = (Get-Item $mcpRoot).Parent.FullName
$backupsDir = Join-Path -Path $versioningRoot -ChildPath "backups"
$changelogPath = Join-Path -Path $versioningRoot -ChildPath "changelog\changelog.md"
$versionHistoryPath = Join-Path -Path $versioningRoot -ChildPath "changelog\version-history.json"

# Fonctions d'aide
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "TITLE" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-CurrentVersion {
    if (Test-Path $versionHistoryPath) {
        try {
            $versionHistory = Get-Content -Path $versionHistoryPath -Raw | ConvertFrom-Json
            $latestVersion = $versionHistory | Sort-Object -Property Date -Descending | Select-Object -First 1
            return $latestVersion.Version
        }
        catch {
            Write-Log "Erreur lors de la lecture de l'historique des versions: $_" -Level "ERROR"
            return "1.0.0"
        }
    }
    else {
        return "1.0.0"
    }
}

function Get-NextVersion {
    $currentVersion = Get-CurrentVersion
    $versionParts = $currentVersion -split '\.'
    
    $major = [int]$versionParts[0]
    $minor = [int]$versionParts[1]
    $patch = [int]$versionParts[2]
    
    # Incrémenter le numéro de patch
    $patch++
    
    return "$major.$minor.$patch"
}

# Corps principal du script
try {
    Write-Log "Mise à jour des composants MCP..." -Level "TITLE"
    
    # Déterminer la version actuelle et la prochaine version
    $currentVersion = Get-CurrentVersion
    $newVersion = Get-NextVersion
    
    Write-Log "Version actuelle: $currentVersion" -Level "INFO"
    Write-Log "Nouvelle version: $newVersion" -Level "INFO"
    
    # Créer une sauvegarde
    if (-not $SkipBackup) {
        Write-Log "Création d'une sauvegarde avant la mise à jour..." -Level "INFO"
        
        $backupDir = Join-Path -Path $backupsDir -ChildPath "$(Get-Date -Format 'yyyyMMdd')-$currentVersion"
        
        if (-not (Test-Path $backupDir)) {
            New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder les fichiers importants
        $dirsToBackup = @(
            "config",
            "core",
            "modules",
            "python"
        )
        
        foreach ($dir in $dirsToBackup) {
            $sourcePath = Join-Path -Path $mcpRoot -ChildPath $dir
            $targetPath = Join-Path -Path $backupDir -ChildPath $dir
            
            if (Test-Path $sourcePath) {
                if ($PSCmdlet.ShouldProcess($sourcePath, "Backup to $targetPath")) {
                    Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                    Write-Log "Sauvegarde de $dir terminée." -Level "SUCCESS"
                }
            }
            else {
                Write-Log "Répertoire $dir non trouvé, ignoré." -Level "WARNING"
            }
        }
        
        Write-Log "Sauvegarde créée: $backupDir" -Level "SUCCESS"
    }
    
    # Mettre à jour les composants npm
    if ($Components -contains "All" -or $Components -contains "Npm") {
        Write-Log "Mise à jour des composants npm..." -Level "INFO"
        
        $npmPackages = @(
            "@modelcontextprotocol/server-filesystem",
            "@modelcontextprotocol/server-github",
            "gcp-mcp",
            "@suekou/mcp-notion-server"
        )
        
        foreach ($package in $npmPackages) {
            if ($PSCmdlet.ShouldProcess($package, "Update npm package")) {
                try {
                    npm update -g $package
                    Write-Log "Package $package mis à jour." -Level "SUCCESS"
                }
                catch {
                    Write-Log "Erreur lors de la mise à jour de $package: $_" -Level "ERROR"
                }
            }
        }
    }
    
    # Mettre à jour les composants pip
    if ($Components -contains "All" -or $Components -contains "Pip") {
        Write-Log "Mise à jour des composants pip..." -Level "INFO"
        
        $pipPackages = @(
            "pymcpfy",
            "mcp-git-ingest"
        )
        
        foreach ($package in $pipPackages) {
            if ($PSCmdlet.ShouldProcess($package, "Update pip package")) {
                try {
                    pip install --upgrade $package
                    Write-Log "Package $package mis à jour." -Level "SUCCESS"
                }
                catch {
                    Write-Log "Erreur lors de la mise à jour de $package: $_" -Level "ERROR"
                }
            }
        }
    }
    
    # Mettre à jour les composants binaires
    if ($Components -contains "All" -or $Components -contains "Binary") {
        Write-Log "Mise à jour des composants binaires..." -Level "INFO"
        
        # Mise à jour de Gateway
        $gatewayDir = Join-Path -Path $mcpRoot -ChildPath "dependencies\binary\gateway"
        if (Test-Path $gatewayDir) {
            if ($PSCmdlet.ShouldProcess("Gateway", "Update binary")) {
                try {
                    # URL de téléchargement (à remplacer par l'URL réelle)
                    $gatewayUrl = "https://github.com/centralmind/gateway/releases/latest/download/gateway-windows-amd64.zip"
                    $gatewayZipPath = Join-Path -Path $gatewayDir -ChildPath "gateway.zip"
                    
                    # Télécharger le fichier ZIP
                    Invoke-WebRequest -Uri $gatewayUrl -OutFile $gatewayZipPath
                    
                    # Extraire le fichier ZIP
                    Expand-Archive -Path $gatewayZipPath -DestinationPath $gatewayDir -Force
                    
                    # Supprimer le fichier ZIP
                    Remove-Item -Path $gatewayZipPath -Force
                    
                    Write-Log "Gateway mis à jour." -Level "SUCCESS"
                }
                catch {
                    Write-Log "Erreur lors de la mise à jour de Gateway: $_" -Level "ERROR"
                }
            }
        }
        else {
            Write-Log "Répertoire Gateway non trouvé, ignoré." -Level "WARNING"
        }
    }
    
    # Mettre à jour le changelog
    if ($PSCmdlet.ShouldProcess($changelogPath, "Update changelog")) {
        $changelogEntry = @"

## [$newVersion] - $(Get-Date -Format 'yyyy-MM-dd')

### Added
- Nouvelles fonctionnalités ajoutées

### Changed
- Modifications apportées

### Fixed
- Corrections de bugs

"@
        
        if (Test-Path $changelogPath) {
            $changelog = Get-Content -Path $changelogPath -Raw
            $updatedChangelog = $changelog + $changelogEntry
            Set-Content -Path $changelogPath -Value $updatedChangelog
        }
        else {
            $changelogHeader = @"
# Changelog

Toutes les modifications notables apportées au projet MCP seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
"@
            $fullChangelog = $changelogHeader + $changelogEntry
            
            $changelogDir = Split-Path -Parent $changelogPath
            if (-not (Test-Path $changelogDir)) {
                New-Item -Path $changelogDir -ItemType Directory -Force | Out-Null
            }
            
            Set-Content -Path $changelogPath -Value $fullChangelog
        }
        
        Write-Log "Changelog mis à jour." -Level "SUCCESS"
    }
    
    # Mettre à jour l'historique des versions
    if ($PSCmdlet.ShouldProcess($versionHistoryPath, "Update version history")) {
        $versionInfo = @{
            Version = $newVersion
            Date = Get-Date -Format "yyyy-MM-dd"
            Components = $Components
            UpdatedBy = $env:USERNAME
        }
        
        if (Test-Path $versionHistoryPath) {
            $versionHistory = Get-Content -Path $versionHistoryPath -Raw | ConvertFrom-Json
            $versionHistory += $versionInfo
            $versionHistory | ConvertTo-Json -Depth 5 | Set-Content -Path $versionHistoryPath
        }
        else {
            $versionHistoryDir = Split-Path -Parent $versionHistoryPath
            if (-not (Test-Path $versionHistoryDir)) {
                New-Item -Path $versionHistoryDir -ItemType Directory -Force | Out-Null
            }
            
            @($versionInfo) | ConvertTo-Json -Depth 5 | Set-Content -Path $versionHistoryPath
        }
        
        Write-Log "Historique des versions mis à jour." -Level "SUCCESS"
    }
    
    Write-Log "Mise à jour des composants MCP terminée." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de la mise à jour des composants MCP: $_" -Level "ERROR"
    exit 1
}
