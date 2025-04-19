# Importer les fonctions de visualisation
. "$PSScriptRoot\..\Export-CycleVisualizationHTML.ps1"
. "$PSScriptRoot\..\Export-CycleVisualizationDOT.ps1"
. "$PSScriptRoot\..\Export-CycleVisualizationJSON.ps1"
. "$PSScriptRoot\..\Export-CycleVisualizationMERMAID.ps1"

# Fonction principale pour exporter une visualisation des cycles de dépendances
function Export-CycleVisualization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$CycleData,

        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "DOT", "JSON", "MERMAID")]
        [string]$Format = "HTML",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStatistics,

        [Parameter(Mandatory = $false)]
        [switch]$OpenInBrowser
    )

    # Générer le chemin de sortie par défaut si non spécifié
    if (-not $OutputPath) {
        $extension = switch ($Format) {
            "HTML" { ".html" }
            "DOT" { ".dot" }
            "JSON" { ".json" }
            "MERMAID" { ".md" }
        }
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputPath = "reports/cycle_visualization_${timestamp}${extension}"
    }

    # Appeler la fonction appropriée selon le format demandé
    switch ($Format) {
        "HTML" {
            $result = Export-CycleVisualizationHTML -CycleData $CycleData -OutputPath $OutputPath -HighlightCycles:$HighlightCycles -IncludeStatistics:$IncludeStatistics -OpenInBrowser:$OpenInBrowser
        }
        "DOT" {
            $result = Export-CycleVisualizationDOT -CycleData $CycleData -OutputPath $OutputPath -HighlightCycles:$HighlightCycles -IncludeStatistics:$IncludeStatistics
        }
        "JSON" {
            $result = Export-CycleVisualizationJSON -CycleData $CycleData -OutputPath $OutputPath -HighlightCycles:$HighlightCycles -IncludeStatistics:$IncludeStatistics
        }
        "MERMAID" {
            $result = Export-CycleVisualizationMERMAID -CycleData $CycleData -OutputPath $OutputPath -HighlightCycles:$HighlightCycles -IncludeStatistics:$IncludeStatistics
        }
        default {
            Write-Warning "Le format '$Format' n'est pas encore implémenté. Utilisation du format HTML par défaut."
            $result = Export-CycleVisualizationHTML -CycleData $CycleData -OutputPath $OutputPath -HighlightCycles:$HighlightCycles -IncludeStatistics:$IncludeStatistics -OpenInBrowser:$OpenInBrowser
        }
    }

    return $result
}

# Fonction pour afficher un graphe de dépendances dans le navigateur par défaut
function Show-CycleGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$CycleData,

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStatistics,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Générer la visualisation HTML
    $htmlPath = Export-CycleVisualization -CycleData $CycleData -Format "HTML" -HighlightCycles:$HighlightCycles -IncludeStatistics:$IncludeStatistics -OutputPath $OutputPath -OpenInBrowser

    return $htmlPath
}

# Exporter les fonctions
Export-ModuleMember -Function Export-CycleVisualization, Show-CycleGraph
