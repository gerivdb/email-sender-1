# Module d'analyse avancée pour le Script Manager
# Ce module coordonne l'analyse approfondie des scripts
# Author: Script Manager
# Version: 1.0
# Tags: analysis, scripts, manager

# Importer les sous-modules
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$SubModules = @(
    "StaticAnalyzer.psm1",
    "DependencyDetector.psm1",
    "CodeQualityAnalyzer.psm1",
    "ProblemDetector.psm1"
)

foreach ($Module in $SubModules) {
    $ModulePath = Join-Path -Path $ScriptPath -ChildPath $Module
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        Write-Warning "Module $Module not found at $ModulePath"
    }
}

function Invoke-ScriptAnalysis {
    <#
    .SYNOPSIS
        Analyse approfondie des scripts
    .DESCRIPTION
        Effectue une analyse statique, détecte les dépendances et évalue la qualité du code
    .PARAMETER InventoryPath
        Chemin vers le fichier d'inventaire JSON
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats de l'analyse
    .PARAMETER Depth
        Niveau de profondeur de l'analyse (Basic, Standard, Advanced)
    .EXAMPLE
        Invoke-ScriptAnalysis -InventoryPath "data\inventory.json" -OutputPath "data\analysis.json"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$InventoryPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [ValidateSet("Basic", "Standard", "Advanced")]
        [string]$Depth = "Standard"
    )
    
    # Vérifier si le fichier d'inventaire existe
    if (-not (Test-Path -Path $InventoryPath)) {
        Write-Error "Fichier d'inventaire non trouvé: $InventoryPath"
        return $null
    }
    
    # Charger l'inventaire
    try {
        $Inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de l'inventaire: $_"
        return $null
    }
    
    Write-Host "Analyse des scripts en cours..." -ForegroundColor Cyan
    Write-Host "Nombre de scripts à analyser: $($Inventory.TotalScripts)" -ForegroundColor Cyan
    Write-Host "Niveau d'analyse: $Depth" -ForegroundColor Cyan
    
    # Créer un tableau pour stocker les résultats de l'analyse
    $AnalysisResults = @()
    
    # Traiter chaque script
    $Counter = 0
    $Total = $Inventory.Scripts.Count
    
    foreach ($Script in $Inventory.Scripts) {
        $Counter++
        $Progress = [math]::Round(($Counter / $Total) * 100)
        Write-Progress -Activity "Analyse des scripts" -Status "$Counter / $Total ($Progress%)" -PercentComplete $Progress
        
        # Lire le contenu du script
        $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $Content) {
            Write-Warning "Impossible de lire le contenu du script: $($Script.Path)"
            continue
        }
        
        # Effectuer l'analyse statique
        $StaticAnalysis = Invoke-StaticAnalysis -Content $Content -ScriptType $Script.Type -Depth $Depth
        
        # Détecter les dépendances
        $Dependencies = Get-ScriptDependencies -Content $Content -ScriptType $Script.Type -Path $Script.Path
        
        # Analyser la qualité du code
        $CodeQuality = Measure-CodeQuality -Content $Content -ScriptType $Script.Type
        
        # Détecter les problèmes potentiels
        $Problems = Find-CodeProblems -Content $Content -ScriptType $Script.Type -Path $Script.Path
        
        # Créer un objet avec les résultats de l'analyse
        $AnalysisResult = [PSCustomObject]@{
            Path = $Script.Path
            Name = $Script.Name
            Type = $Script.Type
            StaticAnalysis = $StaticAnalysis
            Dependencies = $Dependencies
            CodeQuality = $CodeQuality
            Problems = $Problems
            AnalysisDepth = $Depth
            AnalysisTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        # Ajouter l'objet au tableau
        $AnalysisResults += $AnalysisResult
    }
    
    Write-Progress -Activity "Analyse des scripts" -Completed
    
    # Créer un objet avec les résultats de l'analyse
    $Analysis = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $AnalysisResults.Count
        AnalysisDepth = $Depth
        ScriptsByType = $AnalysisResults | Group-Object -Property Type | ForEach-Object {
            [PSCustomObject]@{
                Type = $_.Name
                Count = $_.Count
            }
        }
        ScriptsWithProblems = ($AnalysisResults | Where-Object { $_.Problems.Count -gt 0 }).Count
        ScriptsWithDependencies = ($AnalysisResults | Where-Object { $_.Dependencies.Count -gt 0 }).Count
        AverageCodeQuality = ($AnalysisResults | Measure-Object -Property CodeQuality.Score -Average).Average
        Scripts = $AnalysisResults
    }
    
    # Convertir l'objet en JSON et l'enregistrer dans un fichier
    $Analysis | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    Write-Host "Analyse terminée. Résultats enregistrés dans: $OutputPath" -ForegroundColor Green
    
    return $Analysis
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-ScriptAnalysis
