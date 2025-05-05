<#
.SYNOPSIS
    Script pour exÃ©cuter le mode ARCHI du systÃ¨me de roadmap.
.DESCRIPTION
    Ce script exÃ©cute le mode ARCHI du systÃ¨me de roadmap, qui permet de gÃ©nÃ©rer des diagrammes d'architecture
    et d'analyser les dÃ©pendances entre les composants du systÃ¨me.
.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  analyser.
.PARAMETER OutputPath
    Chemin vers le rÃ©pertoire de sortie pour les diagrammes gÃ©nÃ©rÃ©s.
.PARAMETER DiagramFormat
    Format des diagrammes gÃ©nÃ©rÃ©s (PlantUML, Mermaid, etc.).
.PARAMETER WhatIf
    Si spÃ©cifiÃ©, simule les actions sans les exÃ©cuter.
.EXAMPLE
    .\archi-mode.ps1 -FilePath "Roadmap/roadmap.md" -OutputPath "output/diagrams" -DiagramFormat "PlantUML"
    GÃ©nÃ¨re des diagrammes d'architecture au format PlantUML Ã  partir du fichier de roadmap spÃ©cifiÃ©.
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

# DÃ©finir le chemin du script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module\Functions"
$publicFunctionsPath = Join-Path -Path $modulePath -ChildPath "Public"

# Importer les fonctions nÃ©cessaires
$invokeRoadmapArchitecturePath = Join-Path -Path $publicFunctionsPath -ChildPath "Invoke-RoadmapArchitecture.ps1"

if (Test-Path -Path $invokeRoadmapArchitecturePath) {
    . $invokeRoadmapArchitecturePath
} else {
    Write-Error "Le fichier Invoke-RoadmapArchitecture.ps1 est introuvable Ã  l'emplacement : $invokeRoadmapArchitecturePath"
    exit 1
}

# Afficher les informations de dÃ©marrage
Write-Host "ExÃ©cution du mode ARCHI..." -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
Write-Host "RÃ©pertoire de sortie : $OutputPath" -ForegroundColor Cyan
Write-Host "Format des diagrammes : $DiagramFormat" -ForegroundColor Cyan

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃ©er le rÃ©pertoire de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath" -ForegroundColor Green
    }
}

# ExÃ©cuter le mode ARCHI
try {
    if ($PSCmdlet.ShouldProcess($FilePath, "GÃ©nÃ©rer des diagrammes d'architecture")) {
        $result = Invoke-RoadmapArchitecture -FilePath $FilePath -OutputPath $OutputPath -DiagramFormat $DiagramFormat
        
        if ($result) {
            Write-Host "Diagrammes d'architecture gÃ©nÃ©rÃ©s avec succÃ¨s." -ForegroundColor Green
            Write-Host "Nombre de diagrammes gÃ©nÃ©rÃ©s : $($result.DiagramCount)" -ForegroundColor Green
            Write-Host "Nombre de composants analysÃ©s : $($result.ComponentCount)" -ForegroundColor Green
            Write-Host "Nombre de dÃ©pendances dÃ©tectÃ©es : $($result.DependencyCount)" -ForegroundColor Green
        } else {
            Write-Warning "Aucun diagramme n'a Ã©tÃ© gÃ©nÃ©rÃ©."
        }
    }
} catch {
    Write-Error "Erreur lors de l'exÃ©cution du mode ARCHI : $_"
    exit 1
}

# Afficher les informations de fin
Write-Host "Mode ARCHI terminÃ©." -ForegroundColor Cyan
