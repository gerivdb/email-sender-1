<#
.SYNOPSIS
    Script pour exécuter le mode ARCHI du système de roadmap.
.DESCRIPTION
    Ce script exécute le mode ARCHI du système de roadmap, qui permet de générer des diagrammes d'architecture
    et d'analyser les dépendances entre les composants du système.
.PARAMETER FilePath
    Chemin vers le fichier de roadmap à analyser.
.PARAMETER OutputPath
    Chemin vers le répertoire de sortie pour les diagrammes générés.
.PARAMETER DiagramFormat
    Format des diagrammes générés (PlantUML, Mermaid, etc.).
.PARAMETER WhatIf
    Si spécifié, simule les actions sans les exécuter.
.EXAMPLE
    .\archi-mode.ps1 -FilePath "Roadmap/roadmap.md" -OutputPath "output/diagrams" -DiagramFormat "PlantUML"
    Génère des diagrammes d'architecture au format PlantUML à partir du fichier de roadmap spécifié.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter()]
    [string]$FilePath = "Roadmap/roadmap_complete_converted.md",
    
    [Parameter()]
    [string]$OutputPath = "output/diagrams",
    
    [Parameter()]
    [ValidateSet("PlantUML", "Mermaid", "Graphviz")]
    [string]$DiagramFormat = "PlantUML"
)

# Définir le chemin du script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module\Functions"
$publicFunctionsPath = Join-Path -Path $modulePath -ChildPath "Public"

# Importer les fonctions nécessaires
$invokeRoadmapArchitecturePath = Join-Path -Path $publicFunctionsPath -ChildPath "Invoke-RoadmapArchitecture.ps1"

if (Test-Path -Path $invokeRoadmapArchitecturePath) {
    . $invokeRoadmapArchitecturePath
} else {
    Write-Error "Le fichier Invoke-RoadmapArchitecture.ps1 est introuvable à l'emplacement : $invokeRoadmapArchitecturePath"
    exit 1
}

# Afficher les informations de démarrage
Write-Host "Exécution du mode ARCHI..." -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
Write-Host "Répertoire de sortie : $OutputPath" -ForegroundColor Cyan
Write-Host "Format des diagrammes : $DiagramFormat" -ForegroundColor Cyan

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "Créer le répertoire de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de sortie créé : $OutputPath" -ForegroundColor Green
    }
}

# Exécuter le mode ARCHI
try {
    if ($PSCmdlet.ShouldProcess($FilePath, "Générer des diagrammes d'architecture")) {
        $result = Invoke-RoadmapArchitecture -FilePath $FilePath -OutputPath $OutputPath -DiagramFormat $DiagramFormat
        
        if ($result) {
            Write-Host "Diagrammes d'architecture générés avec succès." -ForegroundColor Green
            Write-Host "Nombre de diagrammes générés : $($result.DiagramCount)" -ForegroundColor Green
            Write-Host "Nombre de composants analysés : $($result.ComponentCount)" -ForegroundColor Green
            Write-Host "Nombre de dépendances détectées : $($result.DependencyCount)" -ForegroundColor Green
        } else {
            Write-Warning "Aucun diagramme n'a été généré."
        }
    }
} catch {
    Write-Error "Erreur lors de l'exécution du mode ARCHI : $_"
    exit 1
}

# Afficher les informations de fin
Write-Host "Mode ARCHI terminé." -ForegroundColor Cyan
