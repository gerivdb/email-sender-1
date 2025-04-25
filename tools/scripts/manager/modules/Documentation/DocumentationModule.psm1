# Module de documentation pour le Script Manager
# Ce module coordonne la génération de documentation pour les scripts
# Author: Script Manager
# Version: 1.0
# Tags: documentation, scripts, manager

# Importer les sous-modules
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$SubModules = @(
    "ReadmeGenerator.psm1",
    "ScriptDocumenter.psm1",
    "IndexGenerator.psm1",
    "ExampleGenerator.psm1"
)

foreach ($Module in $SubModules) {
    $ModulePath = Join-Path -Path $ScriptPath -ChildPath $Module
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        Write-Warning "Module $Module not found at $ModulePath"
    }
}

function Invoke-ScriptDocumentation {
    <#
    .SYNOPSIS
        Génère la documentation pour les scripts
    .DESCRIPTION
        Génère des README, de la documentation pour les scripts et un index global
    .PARAMETER AnalysisPath
        Chemin vers le fichier d'analyse JSON
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats de la documentation
    .PARAMETER IncludeExamples
        Inclut des exemples d'utilisation dans la documentation
    .EXAMPLE
        Invoke-ScriptDocumentation -AnalysisPath "data\analysis.json" -OutputPath "docs"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$AnalysisPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [switch]$IncludeExamples
    )
    
    # Vérifier si le fichier d'analyse existe
    if (-not (Test-Path -Path $AnalysisPath)) {
        Write-Error "Fichier d'analyse non trouvé: $AnalysisPath"
        return $null
    }
    
    # Charger l'analyse
    try {
        $Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de l'analyse: $_"
        return $null
    }
    
    Write-Host "Génération de la documentation en cours..." -ForegroundColor Cyan
    Write-Host "Nombre de scripts à documenter: $($Analysis.TotalScripts)" -ForegroundColor Cyan
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Créer un tableau pour stocker les résultats de la documentation
    $DocumentationResults = @()
    
    # Générer les README pour chaque dossier
    $FolderReadmes = New-FolderReadmes -Analysis $Analysis -OutputPath $OutputPath
    
    # Générer la documentation pour chaque script
    $ScriptDocs = New-ScriptDocumentation -Analysis $Analysis -OutputPath $OutputPath -IncludeExamples:$IncludeExamples
    
    # Générer l'index global
    $GlobalIndex = New-GlobalIndex -Analysis $Analysis -OutputPath $OutputPath -FolderReadmes $FolderReadmes -ScriptDocs $ScriptDocs
    
    # Créer un objet avec les résultats de la documentation
    $Documentation = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Analysis.TotalScripts
        FolderReadmes = $FolderReadmes
        ScriptDocs = $ScriptDocs
        GlobalIndex = $GlobalIndex
    }
    
    # Convertir l'objet en JSON et l'enregistrer dans un fichier
    $DocumentationPath = Join-Path -Path $OutputPath -ChildPath "documentation.json"
    $Documentation | ConvertTo-Json -Depth 10 | Set-Content -Path $DocumentationPath
    
    Write-Host "Documentation terminée. Résultats enregistrés dans: $OutputPath" -ForegroundColor Green
    
    return $Documentation
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-ScriptDocumentation
