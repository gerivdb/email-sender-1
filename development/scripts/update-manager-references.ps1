<#
.SYNOPSIS
    Script de mise à jour des références au mode manager et au roadmap manager.

.DESCRIPTION
    Ce script met à jour les références au mode manager et au roadmap manager dans les fichiers existants
    pour utiliser le gestionnaire intégré à la place.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire courant.

.PARAMETER DryRun
    Indique si les modifications doivent être simulées sans être appliquées.

.PARAMETER BackupFiles
    Indique si les fichiers modifiés doivent être sauvegardés avant d'être modifiés.

.EXAMPLE
    .\update-manager-references.ps1
    Met à jour les références dans le répertoire courant.

.EXAMPLE
    .\update-manager-references.ps1 -ProjectRoot "D:\MonProjet" -DryRun
    Simule la mise à jour des références dans le répertoire D:\MonProjet sans appliquer les modifications.

.EXAMPLE
    .\update-manager-references.ps1 -BackupFiles
    Met à jour les références dans le répertoire courant et sauvegarde les fichiers modifiés.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = ".",
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$BackupFiles
)

# Déterminer le chemin du projet
if ($ProjectRoot -eq ".") {
    $ProjectRoot = $PWD.Path
    
    # Remonter jusqu'à trouver le répertoire .git
    while (-not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container) -and 
           -not [string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = Split-Path -Path $ProjectRoot -Parent
    }
    
    if ([string]::IsNullOrEmpty($ProjectRoot) -or -not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container)) {
        $ProjectRoot = $PWD.Path
    }
}

# Vérifier que le répertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le répertoire du projet n'existe pas : $ProjectRoot"
    exit 1
}

# Chemins des fichiers à rechercher
$modeManagerPath = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\manager\mode-manager.ps1"
$roadmapManagerPath = Join-Path -Path $ProjectRoot -ChildPath "projet\roadmaps\scripts\RoadmapManager.ps1"
$integratedManagerPath = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\integrated-manager.ps1"

# Vérifier que les fichiers existent
if (-not (Test-Path -Path $modeManagerPath)) {
    Write-Warning "Le script du mode manager est introuvable : $modeManagerPath"
}

if (-not (Test-Path -Path $roadmapManagerPath)) {
    Write-Warning "Le script du roadmap manager est introuvable : $roadmapManagerPath"
}

if (-not (Test-Path -Path $integratedManagerPath)) {
    Write-Error "Le script du gestionnaire intégré est introuvable : $integratedManagerPath"
    exit 1
}

# Créer un répertoire de sauvegarde si nécessaire
$backupDir = Join-Path -Path $ProjectRoot -ChildPath "backup\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
if ($BackupFiles) {
    if (-not (Test-Path -Path $backupDir -PathType Container)) {
        Write-Host "Création du répertoire de sauvegarde : $backupDir" -ForegroundColor Green
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour mettre à jour les références dans un fichier
function Update-References {
    param (
        [string]$FilePath,
        [hashtable]$Replacements
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Warning "Le fichier est introuvable : $FilePath"
        return $false
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    $originalContent = $content
    
    # Appliquer les remplacements
    foreach ($pattern in $Replacements.Keys) {
        $replacement = $Replacements[$pattern]
        $content = $content -replace $pattern, $replacement
    }
    
    # Vérifier si le contenu a été modifié
    if ($content -eq $originalContent) {
        Write-Host "Aucune modification nécessaire dans le fichier : $FilePath" -ForegroundColor Gray
        return $false
    }
    
    # Sauvegarder le fichier si nécessaire
    if ($BackupFiles) {
        $backupPath = Join-Path -Path $backupDir -ChildPath (Split-Path -Path $FilePath -Leaf)
        Write-Host "Sauvegarde du fichier : $FilePath -> $backupPath" -ForegroundColor Yellow
        Copy-Item -Path $FilePath -Destination $backupPath -Force
    }
    
    # Appliquer les modifications si ce n'est pas une simulation
    if (-not $DryRun) {
        Write-Host "Mise à jour du fichier : $FilePath" -ForegroundColor Green
        Set-Content -Path $FilePath -Value $content -Encoding UTF8
    } else {
        Write-Host "Simulation de la mise à jour du fichier : $FilePath" -ForegroundColor Cyan
    }
    
    return $true
}

# Définir les remplacements à effectuer
$replacements = @{
    # Remplacements pour le mode manager
    "& .*?mode-manager\.ps1" = "& `"development\scripts\integrated-manager.ps1`""
    "& .*?\\mode-manager\.ps1" = "& `"development\scripts\integrated-manager.ps1`""
    "& .*?/mode-manager\.ps1" = "& `"development\scripts\integrated-manager.ps1`""
    "Invoke-Expression .*?mode-manager\.ps1" = "Invoke-Expression `"& 'development\scripts\integrated-manager.ps1'`""
    "Invoke-Expression .*?\\mode-manager\.ps1" = "Invoke-Expression `"& 'development\scripts\integrated-manager.ps1'`""
    "Invoke-Expression .*?/mode-manager\.ps1" = "Invoke-Expression `"& 'development\scripts\integrated-manager.ps1'`""
    
    # Remplacements pour le roadmap manager
    "& .*?RoadmapManager\.ps1" = "& `"development\scripts\integrated-manager.ps1`" -Interactive"
    "& .*?\\RoadmapManager\.ps1" = "& `"development\scripts\integrated-manager.ps1`" -Interactive"
    "& .*?/RoadmapManager\.ps1" = "& `"development\scripts\integrated-manager.ps1`" -Interactive"
    "Invoke-Expression .*?RoadmapManager\.ps1" = "Invoke-Expression `"& 'development\scripts\integrated-manager.ps1' -Interactive`""
    "Invoke-Expression .*?\\RoadmapManager\.ps1" = "Invoke-Expression `"& 'development\scripts\integrated-manager.ps1' -Interactive`""
    "Invoke-Expression .*?/RoadmapManager\.ps1" = "Invoke-Expression `"& 'development\scripts\integrated-manager.ps1' -Interactive`""
    
    # Remplacements pour les paramètres spécifiques
    "-Mode (.*?) -FilePath" = "-Mode `$1 -RoadmapPath"
    "-FilePath (.*?) -TaskIdentifier" = "-RoadmapPath `$1 -TaskIdentifier"
    "-Organize" = "-Interactive"
    "-Execute" = "-Interactive"
    "-Analyze" = "-Analyze"
    "-GitUpdate" = "-GitUpdate"
    "-Cleanup" = "-Interactive"
    "-FixScripts" = "-Interactive"
}

# Rechercher les fichiers qui contiennent des références au mode manager ou au roadmap manager
$filesToSearch = @(
    "*.ps1",
    "*.psm1",
    "*.psd1",
    "*.md",
    "*.txt",
    "*.json",
    "*.yaml",
    "*.yml"
)

$filesToUpdate = @()
foreach ($pattern in $filesToSearch) {
    $files = Get-ChildItem -Path $ProjectRoot -Recurse -File -Include $pattern | Where-Object {
        $content = Get-Content -Path $_.FullName -Raw
        $content -match "mode-manager\.ps1" -or $content -match "RoadmapManager\.ps1"
    }
    
    $filesToUpdate += $files
}

# Mettre à jour les références dans les fichiers trouvés
$updatedFiles = 0
$totalFiles = $filesToUpdate.Count

Write-Host "Fichiers à mettre à jour : $totalFiles" -ForegroundColor Cyan

foreach ($file in $filesToUpdate) {
    $updated = Update-References -FilePath $file.FullName -Replacements $replacements
    
    if ($updated) {
        $updatedFiles++
    }
}

# Afficher un résumé
if ($DryRun) {
    Write-Host "Simulation terminée. $updatedFiles fichiers sur $totalFiles seraient mis à jour." -ForegroundColor Cyan
} else {
    Write-Host "Mise à jour terminée. $updatedFiles fichiers sur $totalFiles ont été mis à jour." -ForegroundColor Green
}

if ($BackupFiles -and $updatedFiles -gt 0) {
    Write-Host "Les fichiers originaux ont été sauvegardés dans le répertoire : $backupDir" -ForegroundColor Yellow
}
