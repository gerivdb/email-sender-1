#Requires -Version 5.1
<#
.SYNOPSIS
    Organise automatiquement les scripts dans le dossier maintenance.
.DESCRIPTION
    Ce script analyse les fichiers PowerShell Ã  la racine du dossier maintenance
    et les dÃ©place dans les sous-dossiers appropriÃ©s en fonction de leur contenu et de leur nom.
.PARAMETER Force
    Force le dÃ©placement des fichiers sans demander de confirmation.
.PARAMETER CreateBackups
    CrÃ©e des copies de sauvegarde des fichiers avant de les dÃ©placer.
.EXAMPLE
    .\Organize-MaintenanceScripts.ps1 -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-10
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$CreateBackups = $true
)

# Fonction pour Ã©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }

    Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour dÃ©terminer la catÃ©gorie d'un script
function Get-ScriptCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [Parameter(Mandatory = $false)]
        [string]$Content = ""
    )

    $lowerName = $FileName.ToLower()

    # CatÃ©gorisation basÃ©e sur des mots-clÃ©s dans le nom du fichier
    if ($lowerName -match 'roadmap') { return 'roadmap' }
    if ($lowerName -match 'path') { return 'paths' }
    if ($lowerName -match 'checkbox') { return 'modes' }
    if ($lowerName -match 'analyze|analysis|feedback') { return 'api' }
    if ($lowerName -match 'test') { return 'test' }
    if ($lowerName -match 'vscode') { return 'vscode' }
    if ($lowerName -match 'git') { return 'git' }
    if ($lowerName -match 'clean|fix|repair|consolidate') { return 'cleanup' }
    if ($lowerName -match 'mode|check') { return 'modes' }
    if ($lowerName -match 'encoding') { return 'encoding' }
    if ($lowerName -match 'log') { return 'logs' }
    if ($lowerName -match 'performance|perf') { return 'performance' }
    if ($lowerName -match 'backup') { return 'backups' }
    if ($lowerName -match 'init|install') { return 'environment-compatibility' }
    if ($lowerName -match 'update') {
        if ($lowerName -match 'vscode') { return 'vscode' }
        if ($lowerName -match 'roadmap') { return 'roadmap' }
        if ($lowerName -match 'path') { return 'paths' }
        if ($lowerName -match 'checkbox') { return 'modes' }
        return 'utils'
    }

    # Analyse du contenu si disponible
    if ($Content) {
        if ($Content -match 'roadmap|plan') { return 'roadmap' }
        if ($Content -match 'path|chemin') { return 'paths' }
        if ($Content -match 'checkbox|case Ã  cocher') { return 'modes' }
        if ($Content -match 'analyze|analyse|feedback') { return 'api' }
        if ($Content -match 'test|pester') { return 'test' }
        if ($Content -match 'vscode|vs code') { return 'vscode' }
        if ($Content -match 'git|commit|push') { return 'git' }
        if ($Content -match 'clean|fix|repair|nettoyer|rÃ©parer') { return 'cleanup' }
        if ($Content -match 'mode|check|vÃ©rifier') { return 'modes' }
        if ($Content -match 'encoding|encodage|utf') { return 'encoding' }
        if ($Content -match 'log|journal') { return 'logs' }
        if ($Content -match 'performance|perf|mesure') { return 'performance' }
        if ($Content -match 'backup|sauvegarde') { return 'backups' }
    }

    # Par dÃ©faut, retourner 'utils'
    return 'utils'
}

# Fonction pour crÃ©er une sauvegarde d'un fichier
function Backup-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $backupPath = "$FilePath.bak"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Log "Sauvegarde crÃ©Ã©e: $backupPath" -Level "INFO"
        return $true
    } catch {
        Write-Log "Erreur lors de la crÃ©ation de la sauvegarde pour $FilePath : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour dÃ©placer un fichier vers un sous-dossier
function Move-ScriptToCategory {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup = $true
    )

    try {
        $fileName = Split-Path -Leaf $FilePath
        $targetDir = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $FilePath)) -ChildPath $Category
        $targetPath = Join-Path -Path $targetDir -ChildPath $fileName

        # VÃ©rifier si le dossier cible existe, sinon le crÃ©er
        if (-not (Test-Path -Path $targetDir)) {
            if ($PSCmdlet.ShouldProcess($targetDir, "CrÃ©er le dossier")) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                Write-Log "Dossier crÃ©Ã©: $targetDir" -Level "INFO"
            }
        }

        # VÃ©rifier si le fichier existe dÃ©jÃ  dans le dossier cible
        if (Test-Path -Path $targetPath) {
            Write-Log "Le fichier $fileName existe dÃ©jÃ  dans $targetDir" -Level "WARNING"
            return $false
        }

        # CrÃ©er une sauvegarde si demandÃ©
        if ($CreateBackup) {
            Backup-File -FilePath $FilePath | Out-Null
        }

        # DÃ©placer le fichier
        if ($PSCmdlet.ShouldProcess($FilePath, "DÃ©placer vers $targetDir")) {
            Move-Item -Path $FilePath -Destination $targetPath -Force
            Write-Log "Fichier dÃ©placÃ©: $FilePath -> $targetPath" -Level "SUCCESS"
            return $true
        }

        return $false
    } catch {
        Write-Log "Erreur lors du dÃ©placement de $FilePath : $_" -Level "ERROR"
        return $false
    }
}

# Chemin du dossier maintenance
$maintenanceDir = $PSScriptRoot | Split-Path -Parent
Write-Log "Dossier maintenance: $maintenanceDir" -Level "INFO"

# RÃ©cupÃ©rer tous les fichiers PowerShell Ã  la racine du dossier maintenance
$rootFiles = Get-ChildItem -Path $maintenanceDir -File | Where-Object {
    $_.Extension -in '.ps1', '.psm1', '.psd1' -and
    $_.Name -ne 'Organize-MaintenanceScripts.ps1' -and
    -not $_.Name.EndsWith('.bak')
}

Write-Log "Nombre de fichiers Ã  organiser: $($rootFiles.Count)" -Level "INFO"

# Statistiques
$stats = @{
    Total      = $rootFiles.Count
    Moved      = 0
    Skipped    = 0
    Failed     = 0
    Categories = @{}
}

# Traiter chaque fichier
foreach ($file in $rootFiles) {
    Write-Log "Traitement du fichier: $($file.Name)" -Level "INFO"

    # Lire le contenu du fichier pour une meilleure catÃ©gorisation
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    } catch {
        $content = ""
        Write-Log "Impossible de lire le contenu de $($file.Name): $_" -Level "WARNING"
    }

    # DÃ©terminer la catÃ©gorie
    $category = Get-ScriptCategory -FileName $file.Name -Content $content
    Write-Log "CatÃ©gorie dÃ©terminÃ©e: $category" -Level "INFO"

    # Mettre Ã  jour les statistiques
    if (-not $stats.Categories.ContainsKey($category)) {
        $stats.Categories[$category] = 0
    }
    $stats.Categories[$category]++

    # DÃ©placer le fichier
    $moved = Move-ScriptToCategory -FilePath $file.FullName -Category $category -CreateBackup:$CreateBackups

    if ($moved) {
        $stats.Moved++
    } else {
        $stats.Skipped++
    }
}

# Afficher les statistiques
Write-Log "`nRÃ©sumÃ© de l'organisation:" -Level "INFO"
Write-Log "  Total des fichiers: $($stats.Total)" -Level "INFO"
Write-Log "  Fichiers dÃ©placÃ©s: $($stats.Moved)" -Level "SUCCESS"
Write-Log "  Fichiers ignorÃ©s: $($stats.Skipped)" -Level "WARNING"
Write-Log "  Fichiers en Ã©chec: $($stats.Failed)" -Level "ERROR"

Write-Log "`nRÃ©partition par catÃ©gorie:" -Level "INFO"
foreach ($cat in $stats.Categories.GetEnumerator() | Sort-Object Value -Descending) {
    Write-Log "  $($cat.Key): $($cat.Value) fichier(s)" -Level "INFO"
}

Write-Log "`nOrganisation terminÃ©e." -Level "SUCCESS"
