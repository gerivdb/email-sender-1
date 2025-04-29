<#
.SYNOPSIS
    Script de mise Ã  jour des rÃ©fÃ©rences au mode manager et au roadmap manager.

.DESCRIPTION
    Ce script met Ã  jour les rÃ©fÃ©rences au mode manager et au roadmap manager dans les fichiers existants
    pour utiliser le gestionnaire intÃ©grÃ© Ã  la place.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER DryRun
    Indique si les modifications doivent Ãªtre simulÃ©es sans Ãªtre appliquÃ©es.

.PARAMETER BackupFiles
    Indique si les fichiers modifiÃ©s doivent Ãªtre sauvegardÃ©s avant d'Ãªtre modifiÃ©s.

.EXAMPLE
    .\update-manager-references.ps1
    Met Ã  jour les rÃ©fÃ©rences dans le rÃ©pertoire courant.

.EXAMPLE
    .\update-manager-references.ps1 -ProjectRoot "D:\MonProjet" -DryRun
    Simule la mise Ã  jour des rÃ©fÃ©rences dans le rÃ©pertoire D:\MonProjet sans appliquer les modifications.

.EXAMPLE
    .\update-manager-references.ps1 -BackupFiles
    Met Ã  jour les rÃ©fÃ©rences dans le rÃ©pertoire courant et sauvegarde les fichiers modifiÃ©s.
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

# DÃ©terminer le chemin du projet
if ($ProjectRoot -eq ".") {
    $ProjectRoot = $PWD.Path
    
    # Remonter jusqu'Ã  trouver le rÃ©pertoire .git
    while (-not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container) -and 
           -not [string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = Split-Path -Path $ProjectRoot -Parent
    }
    
    if ([string]::IsNullOrEmpty($ProjectRoot) -or -not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container)) {
        $ProjectRoot = $PWD.Path
    }
}

# VÃ©rifier que le rÃ©pertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire du projet n'existe pas : $ProjectRoot"
    exit 1
}

# Chemins des fichiers Ã  rechercher
$modeManagerPath = Join-Path -Path $ProjectRoot -ChildPath "development\\scripts\\mode-manager\mode-manager.ps1"
$roadmap-managerPath = Join-Path -Path $ProjectRoot -ChildPath "development\\managers\\roadmap-manager\\scripts\\roadmap-manager\.ps1"
$integratedManagerPath = Join-Path -Path $ProjectRoot -ChildPath "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1"

# VÃ©rifier que les fichiers existent
if (-not (Test-Path -Path $modeManagerPath)) {
    Write-Warning "Le script du mode manager est introuvable : $modeManagerPath"
}

if (-not (Test-Path -Path $roadmap-managerPath)) {
    Write-Warning "Le script du roadmap manager est introuvable : $roadmap-managerPath"
}

if (-not (Test-Path -Path $integratedManagerPath)) {
    Write-Error "Le script du gestionnaire intÃ©grÃ© est introuvable : $integratedManagerPath"
    exit 1
}

# CrÃ©er un rÃ©pertoire de sauvegarde si nÃ©cessaire
$backupDir = Join-Path -Path $ProjectRoot -ChildPath "backup\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
if ($BackupFiles) {
    if (-not (Test-Path -Path $backupDir -PathType Container)) {
        Write-Host "CrÃ©ation du rÃ©pertoire de sauvegarde : $backupDir" -ForegroundColor Green
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour mettre Ã  jour les rÃ©fÃ©rences dans un fichier
function Update-References {
    param (
        [string]$FilePath,
        [hashtable]$Replacements
    )
    
    # VÃ©rifier que le fichier existe
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
    
    # VÃ©rifier si le contenu a Ã©tÃ© modifiÃ©
    if ($content -eq $originalContent) {
        Write-Host "Aucune modification nÃ©cessaire dans le fichier : $FilePath" -ForegroundColor Gray
        return $false
    }
    
    # Sauvegarder le fichier si nÃ©cessaire
    if ($BackupFiles) {
        $backupPath = Join-Path -Path $backupDir -ChildPath (Split-Path -Path $FilePath -Leaf)
        Write-Host "Sauvegarde du fichier : $FilePath -> $backupPath" -ForegroundColor Yellow
        Copy-Item -Path $FilePath -Destination $backupPath -Force
    }
    
    # Appliquer les modifications si ce n'est pas une simulation
    if (-not $DryRun) {
        Write-Host "Mise Ã  jour du fichier : $FilePath" -ForegroundColor Green
        Set-Content -Path $FilePath -Value $content -Encoding UTF8
    } else {
        Write-Host "Simulation de la mise Ã  jour du fichier : $FilePath" -ForegroundColor Cyan
    }
    
    return $true
}

# DÃ©finir les remplacements Ã  effectuer
$replacements = @{
    # Remplacements pour le mode manager
    "& .*?mode-manager\.ps1" = "& `"development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1`""
    "& .*?\\mode-manager\.ps1" = "& `"development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1`""
    "& .*?/mode-manager\.ps1" = "& `"development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1`""
    "Invoke-Expression .*?mode-manager\.ps1" = "Invoke-Expression `"& 'development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1'`""
    "Invoke-Expression .*?\\mode-manager\.ps1" = "Invoke-Expression `"& 'development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1'`""
    "Invoke-Expression .*?/mode-manager\.ps1" = "Invoke-Expression `"& 'development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1'`""
    
    # Remplacements pour le roadmap manager
    "& .*?roadmap-manager\.ps1" = "& `"development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1`" -Interactive"
    "& .*?\\roadmap-manager\.ps1" = "& `"development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1`" -Interactive"
    "& .*?/roadmap-manager\.ps1" = "& `"development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1`" -Interactive"
    "Invoke-Expression .*?roadmap-manager\.ps1" = "Invoke-Expression `"& 'development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1' -Interactive`""
    "Invoke-Expression .*?\\roadmap-manager\.ps1" = "Invoke-Expression `"& 'development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1' -Interactive`""
    "Invoke-Expression .*?/roadmap-manager\.ps1" = "Invoke-Expression `"& 'development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1' -Interactive`""
    
    # Remplacements pour les paramÃ¨tres spÃ©cifiques
    "-Mode (.*?) -FilePath" = "-Mode `$1 -RoadmapPath"
    "-FilePath (.*?) -TaskIdentifier" = "-RoadmapPath `$1 -TaskIdentifier"
    "-Organize" = "-Interactive"
    "-Execute" = "-Interactive"
    "-Analyze" = "-Analyze"
    "-GitUpdate" = "-GitUpdate"
    "-Cleanup" = "-Interactive"
    "-FixScripts" = "-Interactive"
}

# Rechercher les fichiers qui contiennent des rÃ©fÃ©rences au mode manager ou au roadmap manager
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
        $content -match "mode-manager\.ps1" -or $content -match "roadmap-manager\.ps1"
    }
    
    $filesToUpdate += $files
}

# Mettre Ã  jour les rÃ©fÃ©rences dans les fichiers trouvÃ©s
$updatedFiles = 0
$totalFiles = $filesToUpdate.Count

Write-Host "Fichiers Ã  mettre Ã  jour : $totalFiles" -ForegroundColor Cyan

foreach ($file in $filesToUpdate) {
    $updated = Update-References -FilePath $file.FullName -Replacements $replacements
    
    if ($updated) {
        $updatedFiles++
    }
}

# Afficher un rÃ©sumÃ©
if ($DryRun) {
    Write-Host "Simulation terminÃ©e. $updatedFiles fichiers sur $totalFiles seraient mis Ã  jour." -ForegroundColor Cyan
} else {
    Write-Host "Mise Ã  jour terminÃ©e. $updatedFiles fichiers sur $totalFiles ont Ã©tÃ© mis Ã  jour." -ForegroundColor Green
}

if ($BackupFiles -and $updatedFiles -gt 0) {
    Write-Host "Les fichiers originaux ont Ã©tÃ© sauvegardÃ©s dans le rÃ©pertoire : $backupDir" -ForegroundColor Yellow
}



