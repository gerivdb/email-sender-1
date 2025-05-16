# Simple-Split-Roadmap.ps1
# Script simplifiÃ© pour sÃ©parer la roadmap en fichiers actif et complÃ©tÃ©

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourceRoadmapPath = "projet\roadmaps\roadmap_complete_converted.md",
    
    [Parameter(Mandatory = $false)]
    [string]$ActiveRoadmapPath = "projet\roadmaps\active\roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$CompletedRoadmapPath = "projet\roadmaps\archive\roadmap_completed.md"
)

# VÃ©rifier que le fichier source existe
if (-not (Test-Path -Path $SourceRoadmapPath)) {
    Write-Host "Le fichier source $SourceRoadmapPath n'existe pas."
    exit 1
}

# CrÃ©er les dossiers de destination si nÃ©cessaires
$activeFolder = Split-Path -Path $ActiveRoadmapPath -Parent
$completedFolder = Split-Path -Path $CompletedRoadmapPath -Parent

if (-not (Test-Path -Path $activeFolder)) {
    New-Item -Path $activeFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier crÃ©Ã©: $activeFolder"
}

if (-not (Test-Path -Path $completedFolder)) {
    New-Item -Path $completedFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier crÃ©Ã©: $completedFolder"
}

# Lire le contenu du fichier source
try {
    $content = Get-Content -Path $SourceRoadmapPath -Raw
    Write-Host "Fichier source lu: $SourceRoadmapPath"
}
catch {
    Write-Host "Erreur lors de la lecture du fichier source: $_"
    exit 1
}

# CrÃ©er le contenu des fichiers de destination
$activeContent = @"
# Roadmap Active - EMAIL_SENDER_1

Ce fichier contient les tÃ¢ches actives et Ã  venir de la roadmap.
GÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## TÃ¢ches actives

"@

$completedContent = @"
# Roadmap ComplÃ©tÃ©e - EMAIL_SENDER_1

Ce fichier contient les tÃ¢ches complÃ©tÃ©es de la roadmap.
GÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## TÃ¢ches complÃ©tÃ©es

"@

# Extraire les tÃ¢ches actives et complÃ©tÃ©es
$lines = $content -split "`r`n"
$activeTasks = @()
$completedTasks = @()

foreach ($line in $lines) {
    if ($line -match '- \[ \]') {
        $activeTasks += $line
    }
    elseif ($line -match '- \[x\]') {
        $completedTasks += $line
    }
}

# Ajouter les tÃ¢ches aux fichiers de destination
$activeContent += "`r`n" + ($activeTasks -join "`r`n")
$completedContent += "`r`n" + ($completedTasks -join "`r`n")

# Sauvegarder les fichiers
try {
    Set-Content -Path $ActiveRoadmapPath -Value $activeContent -Encoding UTF8
    Write-Host "Fichier actif crÃ©Ã©: $ActiveRoadmapPath ($(($activeTasks | Measure-Object).Count) tÃ¢ches)"
    
    Set-Content -Path $CompletedRoadmapPath -Value $completedContent -Encoding UTF8
    Write-Host "Fichier complÃ©tÃ© crÃ©Ã©: $CompletedRoadmapPath ($(($completedTasks | Measure-Object).Count) tÃ¢ches)"
    
    Write-Host "SÃ©paration de la roadmap terminÃ©e avec succÃ¨s."
}
catch {
    Write-Host "Erreur lors de la sauvegarde des fichiers: $_"
    exit 1
}
