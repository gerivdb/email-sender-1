#Requires -Version 5.1
<#
.SYNOPSIS
    Organise les scripts du manager dans une structure de dossiers cohÃ©rente.
.DESCRIPTION
    Ce script analyse les scripts existants dans le dossier manager et les dÃ©place
    dans les sous-dossiers appropriÃ©s en fonction de leur contenu et de leur nom.
.PARAMETER Force
    Force le dÃ©placement des fichiers sans demander de confirmation.
.PARAMETER CreateBackups
    CrÃ©e des copies de sauvegarde des fichiers avant de les dÃ©placer.
.EXAMPLE
    .\Organize-ManagerScripts.ps1 -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
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
    "ScriptManager.ps1" = "core"
    "Reorganize-Scripts.ps1" = "organization"
    "Show-ScriptInventory.ps1" = "inventory"
    "README.md" = "core"
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
    
    # VÃ©rifier si le script a une classification prÃ©dÃ©finie
    if ($scriptClassification.ContainsKey($FileName)) {
        return $scriptClassification[$FileName]
    }
    
    $lowerName = $FileName.ToLower()
    
    # CatÃ©gorisation basÃ©e sur des mots-clÃ©s dans le nom du fichier
    if ($lowerName -match 'analyze|analysis') { return 'analysis' }
    if ($lowerName -match 'organize|organization') { return 'organization' }
    if ($lowerName -match 'inventory|catalog') { return 'inventory' }
    if ($lowerName -match 'document|doc') { return 'documentation' }
    if ($lowerName -match 'monitor|watch') { return 'monitoring' }
    if ($lowerName -match 'optimize|improve') { return 'optimization' }
    if ($lowerName -match 'test|validate') { return 'testing' }
    if ($lowerName -match 'config|setting') { return 'configuration' }
    if ($lowerName -match 'generate|create') { return 'generation' }
    if ($lowerName -match 'integrate|connect') { return 'integration' }
    if ($lowerName -match 'ui|interface') { return 'ui' }
    
    # Analyse du contenu si disponible
    if ($Content) {
        if ($Content -match 'analyze|analysis') { return 'analysis' }
        if ($Content -match 'organize|organization') { return 'organization' }
        if ($Content -match 'inventory|catalog') { return 'inventory' }
        if ($Content -match 'document|doc') { return 'documentation' }
        if ($Content -match 'monitor|watch') { return 'monitoring' }
        if ($Content -match 'optimize|improve') { return 'optimization' }
        if ($Content -match 'test|validate') { return 'testing' }
        if ($Content -match 'config|setting') { return 'configuration' }
        if ($Content -match 'generate|create') { return 'generation' }
        if ($Content -match 'integrate|connect') { return 'integration' }
        if ($Content -match 'ui|interface') { return 'ui' }
    }
    
    # Par dÃ©faut, retourner 'core'
    return 'core'
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
    }
    catch {
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
    }
    catch {
        Write-Log "Erreur lors du dÃ©placement de $FilePath : $_" -Level "ERROR"
        return $false
    }
}

# Chemin du dossier manager
$managerDir = $PSScriptRoot | Split-Path -Parent
Write-Log "Dossier manager: $managerDir" -Level "INFO"

# RÃ©cupÃ©rer tous les fichiers PowerShell Ã  la racine du dossier manager
$rootFiles = Get-ChildItem -Path $managerDir -File | Where-Object { 
    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
    $_.Name -ne 'script-manager.ps1'
}

Write-Log "Nombre de fichiers Ã  organiser: $($rootFiles.Count)" -Level "INFO"

# Statistiques
$stats = @{
    Total = $rootFiles.Count
    Moved = 0
    Skipped = 0
    Failed = 0
    Categories = @{}
}

# Traiter chaque fichier
foreach ($file in $rootFiles) {
    Write-Log "Traitement du fichier: $($file.Name)" -Level "INFO"
    
    # Lire le contenu du fichier pour une meilleure catÃ©gorisation
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    }
    catch {
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
    }
    else {
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

