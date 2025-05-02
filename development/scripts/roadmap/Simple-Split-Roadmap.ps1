# Simple-Split-Roadmap.ps1
# Script simplifié pour séparer la roadmap en fichiers actif et complété

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourceRoadmapPath = "projet\roadmaps\roadmap_complete_converted.md",
    
    [Parameter(Mandatory = $false)]
    [string]$ActiveRoadmapPath = "projet\roadmaps\active\roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$CompletedRoadmapPath = "projet\roadmaps\archive\roadmap_completed.md"
)

# Vérifier que le fichier source existe
if (-not (Test-Path -Path $SourceRoadmapPath)) {
    Write-Host "Le fichier source $SourceRoadmapPath n'existe pas."
    exit 1
}

# Créer les dossiers de destination si nécessaires
$activeFolder = Split-Path -Path $ActiveRoadmapPath -Parent
$completedFolder = Split-Path -Path $CompletedRoadmapPath -Parent

if (-not (Test-Path -Path $activeFolder)) {
    New-Item -Path $activeFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier créé: $activeFolder"
}

if (-not (Test-Path -Path $completedFolder)) {
    New-Item -Path $completedFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier créé: $completedFolder"
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

# Créer le contenu des fichiers de destination
$activeContent = @"
# Roadmap Active - EMAIL_SENDER_1

Ce fichier contient les tâches actives et à venir de la roadmap.
Généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Tâches actives

"@

$completedContent = @"
# Roadmap Complétée - EMAIL_SENDER_1

Ce fichier contient les tâches complétées de la roadmap.
Généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Tâches complétées

"@

# Extraire les tâches actives et complétées
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

# Ajouter les tâches aux fichiers de destination
$activeContent += "`r`n" + ($activeTasks -join "`r`n")
$completedContent += "`r`n" + ($completedTasks -join "`r`n")

# Sauvegarder les fichiers
try {
    Set-Content -Path $ActiveRoadmapPath -Value $activeContent -Encoding UTF8
    Write-Host "Fichier actif créé: $ActiveRoadmapPath ($(($activeTasks | Measure-Object).Count) tâches)"
    
    Set-Content -Path $CompletedRoadmapPath -Value $completedContent -Encoding UTF8
    Write-Host "Fichier complété créé: $CompletedRoadmapPath ($(($completedTasks | Measure-Object).Count) tâches)"
    
    Write-Host "Séparation de la roadmap terminée avec succès."
}
catch {
    Write-Host "Erreur lors de la sauvegarde des fichiers: $_"
    exit 1
}
