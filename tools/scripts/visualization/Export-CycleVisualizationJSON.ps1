# Fonction pour exporter une visualisation JSON des cycles de dépendances
function Export-CycleVisualizationJSON {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$CycleData,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStatistics
    )

    # Vérifier si les données de cycle sont valides
    if (-not $CycleData.DependencyGraph) {
        Write-Error "Les données de cycle ne contiennent pas de graphe de dépendances."
        return $null
    }

    # Générer le chemin de sortie par défaut si non spécifié
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputPath = "reports/cycle_visualization_${timestamp}.json"
    }

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Générer un fichier JSON pour une utilisation ultérieure
    $jsonData = @{
        nodes = @()
        edges = @()
        statistics = if ($IncludeStatistics) {
            @{
                totalScripts = $CycleData.DependencyGraph.Keys.Count
                cyclicScripts = if ($CycleData.HasCycles) { $CycleData.Cycles.Count } else { 0 }
                nonCyclicScripts = $CycleData.NonCyclicScripts.Count
            }
        } else { $null }
        cycles = if ($CycleData.HasCycles) { $CycleData.Cycles } else { @() }
    }
    
    # Ajouter les nœuds
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        $isCyclic = $CycleData.HasCycles -and $CycleData.Cycles -contains $script
        $jsonData.nodes += @{
            id = $script
            label = $script
            isCyclic = $isCyclic
        }
    }
    
    # Ajouter les arêtes
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        foreach ($dependency in $CycleData.DependencyGraph[$script]) {
            $isCyclicEdge = $CycleData.HasCycles -and $CycleData.Cycles -contains $script -and $CycleData.Cycles -contains $dependency
            $jsonData.edges += @{
                source = $script
                target = $dependency
                isCyclic = $isCyclicEdge
            }
        }
    }
    
    # Enregistrer le fichier JSON
    $jsonData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "Fichier JSON généré: $OutputPath"

    return $OutputPath
}
