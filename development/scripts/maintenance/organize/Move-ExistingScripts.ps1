#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©place les scripts existants Ã  la racine du dossier maintenance vers les sous-dossiers appropriÃ©s.
.DESCRIPTION
    Ce script analyse les scripts PowerShell Ã  la racine du dossier maintenance
    et les dÃ©place vers les sous-dossiers appropriÃ©s en fonction de leur contenu et de leur nom.
    Il utilise une classification prÃ©dÃ©finie pour dÃ©terminer le sous-dossier de destination.
.PARAMETER Force
    Force le dÃ©placement des fichiers sans demander de confirmation.
.PARAMETER CreateBackups
    CrÃ©e des copies de sauvegarde des fichiers avant de les dÃ©placer.
.EXAMPLE
    .\Move-ExistingScripts.ps1 -Force
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

# Classification prÃ©dÃ©finie des scripts
$scriptClassification = @{
    "Analyze-Feedback.ps1"                          = "api"
    "autoprefixer.ps1"                              = "utils"
    "Consolidate-AnalysisDirectories-Final.ps1"     = "cleanup"
    "Consolidate-AnalysisDirectories.ps1"           = "cleanup"
    "create-checkbox-symlinks.ps1"                  = "modes"
    "create-checkbox-symlinks.ps1.bak"              = "backups"
    "Fix-RoadmapScripts.ps1"                        = "roadmap"
    "init-maintenance.ps1"                          = "environment-compatibility"
    "install-check-enhanced.ps1"                    = "modes"
    "normalize-project-paths.ps1"                   = "paths"
    "normalize-project-paths.ps1.bak"               = "backups"
    "Test-ConsolidateAnalysisDirectories-Final.ps1" = "test"
    "test-script-at-root.ps1"                       = "test"
    "test-script-at-root2.ps1"                      = "test"
    "update-checkbox-function.ps1"                  = "modes"
    "update-checkbox-function.ps1.bak"              = "backups"
    "update-project-paths.ps1"                      = "paths"
    "Update-Roadmap.ps1"                            = "roadmap"
    "update-vscode-cache.ps1"                       = "vscode"
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
    $_.Name -ne 'Initialize-MaintenanceEnvironment.ps1' -and
    $_.Name -ne 'README.md'
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

    # DÃ©terminer la catÃ©gorie
    $category = $scriptClassification[$file.Name]
    if (-not $category) {
        $category = "utils"
        Write-Log "Aucune catÃ©gorie prÃ©dÃ©finie pour $($file.Name), utilisation de 'utils'" -Level "WARNING"
    } else {
        Write-Log "CatÃ©gorie prÃ©dÃ©finie: $category" -Level "INFO"
    }

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
