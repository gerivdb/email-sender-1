<#
.SYNOPSIS
    Convertit une roadmap existante vers le nouveau format de template.

.DESCRIPTION
    Ce script analyse une roadmap existante au format Markdown, extrait les informations
    pertinentes et génère une nouvelle roadmap selon le template spécifié.

.PARAMETER SourcePath
    Chemin vers la roadmap existante.

.PARAMETER TemplatePath
    Chemin vers le fichier de template.

.PARAMETER OutputPath
    Chemin où la nouvelle roadmap sera enregistrée.

.EXAMPLE
    .\Convert-Roadmap.ps1 -SourcePath "Roadmap/roadmap_complete.md" -TemplatePath "Roadmap/roadmap_template.md" -OutputPath "Roadmap/roadmap_complete_new.md"

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-04-20
    Version: 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory = $true)]
    [string]$TemplatePath,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

# Importer le module RoadmapConverter
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapConverter.psm1"
Import-Module $modulePath -Force

try {
    # Étape 1: Analyser la roadmap existante
    Write-Host "Analyse de la roadmap existante..."
    $roadmapStructure = Get-RoadmapStructure -Path $SourcePath
    Write-Host "Analyse terminée. $($roadmapStructure.sections.Count) sections trouvées."
    
    # Étape 2: Obtenir la structure du template
    Write-Host "Extraction de la structure du template..."
    $templateContent = Get-TemplateContent -Path $TemplatePath
    Write-Host "Extraction terminée."
    
    # Étape 3: Transformer la structure selon le template
    Write-Host "Transformation de la roadmap selon le template..."
    $newRoadmap = ConvertTo-NewRoadmap -RoadmapStructure $roadmapStructure -TemplateContent $templateContent
    Write-Host "Transformation terminée."
    
    # Étape 4: Générer la nouvelle roadmap
    Write-Host "Génération de la nouvelle roadmap..."
    Out-RoadmapFile -Content $newRoadmap -Path $OutputPath
    
    Write-Host "Conversion terminée avec succès!" -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de la conversion de la roadmap: $_"
}
finally {
    # Décharger le module
    Remove-Module RoadmapConverter -ErrorAction SilentlyContinue
}
