<#
.SYNOPSIS
    Script pour exÃ©cuter le mode C-BREAK du systÃ¨me de roadmap.
.DESCRIPTION
    Ce script exÃ©cute le mode C-BREAK du systÃ¨me de roadmap, qui permet de dÃ©tecter et de corriger
    les dÃ©pendances circulaires dans le systÃ¨me.
.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  analyser.
.PARAMETER OutputPath
    Chemin vers le rÃ©pertoire de sortie pour les rapports gÃ©nÃ©rÃ©s.
.PARAMETER MaxIterations
    Nombre maximum d'itÃ©rations pour la dÃ©tection des cycles.
.PARAMETER WhatIf
    Si spÃ©cifiÃ©, simule les actions sans les exÃ©cuter.
.EXAMPLE
    .\c-break-mode.ps1 -FilePath "Roadmap/roadmap.md" -OutputPath "output/reports" -MaxIterations 10
    DÃ©tecte et corrige les dÃ©pendances circulaires dans le fichier de roadmap spÃ©cifiÃ©.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter()]
    [string]$FilePath = "Roadmap/roadmap_complete_converted.md",
    
    [Parameter()]
    [string]$OutputPath = "output/reports",
    
    [Parameter()]
    [int]$MaxIterations = 10
)

# DÃ©finir le chemin du script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module\Functions"
$publicFunctionsPath = Join-Path -Path $modulePath -ChildPath "Public"

# Importer les fonctions nÃ©cessaires
$invokeRoadmapCycleBreakerPath = Join-Path -Path $publicFunctionsPath -ChildPath "Invoke-RoadmapCycleBreaker.ps1"

if (Test-Path -Path $invokeRoadmapCycleBreakerPath) {
    . $invokeRoadmapCycleBreakerPath
} else {
    Write-Error "Le fichier Invoke-RoadmapCycleBreaker.ps1 est introuvable Ã  l'emplacement : $invokeRoadmapCycleBreakerPath"
    exit 1
}

# Afficher les informations de dÃ©marrage
Write-Host "ExÃ©cution du mode C-BREAK..." -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
Write-Host "RÃ©pertoire de sortie : $OutputPath" -ForegroundColor Cyan
Write-Host "Nombre maximum d'itÃ©rations : $MaxIterations" -ForegroundColor Cyan

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃ©er le rÃ©pertoire de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath" -ForegroundColor Green
    }
}

# ExÃ©cuter le mode C-BREAK
try {
    if ($PSCmdlet.ShouldProcess($FilePath, "DÃ©tecter et corriger les dÃ©pendances circulaires")) {
        $result = Invoke-RoadmapCycleBreaker -FilePath $FilePath -OutputPath $OutputPath -MaxIterations $MaxIterations
        
        if ($result) {
            Write-Host "Analyse des dÃ©pendances circulaires terminÃ©e avec succÃ¨s." -ForegroundColor Green
            Write-Host "Nombre de cycles dÃ©tectÃ©s : $($result.CycleCount)" -ForegroundColor Green
            Write-Host "Nombre de dÃ©pendances brisÃ©es : $($result.BrokenDependencyCount)" -ForegroundColor Green
            
            if ($result.CycleCount -gt 0) {
                Write-Host "Rapport de dÃ©tection des cycles gÃ©nÃ©rÃ© : $($result.ReportPath)" -ForegroundColor Yellow
            } else {
                Write-Host "Aucun cycle dÃ©tectÃ© dans le systÃ¨me." -ForegroundColor Green
            }
        } else {
            Write-Warning "Aucun rÃ©sultat n'a Ã©tÃ© gÃ©nÃ©rÃ©."
        }
    }
} catch {
    Write-Error "Erreur lors de l'exÃ©cution du mode C-BREAK : $_"
    exit 1
}

# Afficher les informations de fin
Write-Host "Mode C-BREAK terminÃ©." -ForegroundColor Cyan
