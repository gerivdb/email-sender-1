# Fonction pour exporter une visualisation JSON des cycles de dÃ©pendances
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

    # VÃ©rifier si les donnÃ©es de cycle sont valides
    if (-not $CycleData.DependencyGraph) {
        Write-Error "Les donnÃ©es de cycle ne contiennent pas de graphe de dÃ©pendances."
        return $null
    }

    # GÃ©nÃ©rer le chemin de sortie par dÃ©faut si non spÃ©cifiÃ©
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputPath = "reports/cycle_visualization_${timestamp}.json"
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # GÃ©nÃ©rer un fichier JSON pour une utilisation ultÃ©rieure
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
    
    # Ajouter les nÅ“uds
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        $isCyclic = $CycleData.HasCycles -and $CycleData.Cycles -contains $script
        $jsonData.nodes += @{
            id = $script
            label = $script
            isCyclic = $isCyclic
        }
    }
    
    # Ajouter les arÃªtes
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
    Write-Host "Fichier JSON gÃ©nÃ©rÃ©: $OutputPath"

    return $OutputPath
}
