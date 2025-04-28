# Module de documentation pour le Script Manager
# Ce module coordonne la gÃ©nÃ©ration de documentation pour les scripts
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
        GÃ©nÃ¨re la documentation pour les scripts
    .DESCRIPTION
        GÃ©nÃ¨re des README, de la documentation pour les scripts et un index global
    .PARAMETER AnalysisPath
        Chemin vers le fichier d'analyse JSON
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les rÃ©sultats de la documentation
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
    
    # VÃ©rifier si le fichier d'analyse existe
    if (-not (Test-Path -Path $AnalysisPath)) {
        Write-Error "Fichier d'analyse non trouvÃ©: $AnalysisPath"
        return $null
    }
    
    # Charger l'analyse
    try {
        $Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de l'analyse: $_"
        return $null
    }
    
    Write-Host "GÃ©nÃ©ration de la documentation en cours..." -ForegroundColor Cyan
    Write-Host "Nombre de scripts Ã  documenter: $($Analysis.TotalScripts)" -ForegroundColor Cyan
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # CrÃ©er un tableau pour stocker les rÃ©sultats de la documentation
    $DocumentationResults = @()
    
    # GÃ©nÃ©rer les README pour chaque dossier
    $FolderReadmes = New-FolderReadmes -Analysis $Analysis -OutputPath $OutputPath
    
    # GÃ©nÃ©rer la documentation pour chaque script
    $ScriptDocs = New-ScriptDocumentation -Analysis $Analysis -OutputPath $OutputPath -IncludeExamples:$IncludeExamples
    
    # GÃ©nÃ©rer l'index global
    $GlobalIndex = New-GlobalIndex -Analysis $Analysis -OutputPath $OutputPath -FolderReadmes $FolderReadmes -ScriptDocs $ScriptDocs
    
    # CrÃ©er un objet avec les rÃ©sultats de la documentation
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
    
    Write-Host "Documentation terminÃ©e. RÃ©sultats enregistrÃ©s dans: $OutputPath" -ForegroundColor Green
    
    return $Documentation
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-ScriptDocumentation
