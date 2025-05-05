#Requires -Version 5.1
<#
.SYNOPSIS
Module pour la gestion des graphiques dans les rapports d'information extraite.

.DESCRIPTION
Ce module contient les fonctions pour ajouter et manipuler des graphiques dans les rapports
d'information extraite.

.NOTES
Date de création : 2025-05-15
Auteur : Augment Code
Version : 1.0.0
#>

# Importer le module principal si nécessaire
# . "$PSScriptRoot\Integration-Reporting-Core.ps1"
# . "$PSScriptRoot\Integration-Reporting-Sections.ps1"

<#
.SYNOPSIS
Ajoute un graphique à un rapport d'information extraite.

.DESCRIPTION
La fonction Add-ExtractedInfoReportChart ajoute un graphique à un rapport d'information extraite.
Elle prend en charge différents types de graphiques : barres, lignes, camembert, etc.

.PARAMETER Report
Le rapport auquel ajouter le graphique.

.PARAMETER Title
Le titre du graphique.

.PARAMETER Data
Les données du graphique. Peut être un tableau, une hashtable ou un objet.

.PARAMETER ChartType
Le type de graphique. Les valeurs possibles sont définies dans $CHART_TYPES.
Par défaut, "Bar".

.PARAMETER Options
Options supplémentaires pour le graphique (couleurs, légendes, etc.).

.PARAMETER Level
Le niveau de la section (1 à 4). Utilisé pour la numérotation hiérarchique.
Par défaut, 1.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de données"
$data = @(
    @{ Category = "A"; Value = 10 },
    @{ Category = "B"; Value = 20 },
    @{ Category = "C"; Value = 15 }
)
$report = Add-ExtractedInfoReportChart -Report $report -Title "Répartition par catégorie" -Data $data -ChartType "Bar"

.NOTES
Cette fonction crée une section de type Chart dans le rapport et configure
les données pour le rendu du graphique.
#>
function Add-ExtractedInfoReportChart {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Title,

        [Parameter(Mandatory = $true, Position = 2)]
        [object]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Bar", "Line", "Pie", "Scatter", "Area", "Histogram")]
        [string]$ChartType = "Bar",

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{},

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 4)]
        [int]$Level = 1
    )

    # Validation des paramètres
    if ($null -eq $Report -or -not $Report.ContainsKey("Sections")) {
        throw "Le rapport fourni n'est pas valide."
    }

    if ([string]::IsNullOrWhiteSpace($Title)) {
        throw "Le titre du graphique ne peut pas être vide."
    }

    if ($null -eq $Data) {
        throw "Les données du graphique ne peuvent pas être null."
    }

    if (-not $CHART_TYPES.ContainsKey($ChartType) -and -not $CHART_TYPES.ContainsValue($ChartType)) {
        throw "Type de graphique non valide : $ChartType. Les types valides sont : $($CHART_TYPES.Keys -join ', ')"
    }

    # Préparer les données du graphique
    $chartData = @{
        ChartType = $ChartType
        Data      = $Data
        Options   = $Options
    }

    # Ajouter des options par défaut si nécessaire
    if (-not $Options.ContainsKey("Colors")) {
        $chartData.Options["Colors"] = @(
            "#4e79a7", "#f28e2c", "#e15759", "#76b7b2", "#59a14f",
            "#edc949", "#af7aa1", "#ff9da7", "#9c755f", "#bab0ab"
        )
    }

    # Traitement spécifique selon le type de graphique
    switch ($ChartType) {
        "Bar" {
            # Configuration spécifique pour les graphiques en barres
            if (-not $Options.ContainsKey("Orientation")) {
                $chartData.Options["Orientation"] = "vertical"
            }

            # Extraire les labels et les valeurs si les données sont un tableau d'objets
            if ($Data -is [array] -and $Data.Count -gt 0 -and ($Data[0] -is [hashtable] -or $Data[0] -is [PSObject])) {
                $chartData["Labels"] = @()
                $chartData["Values"] = @()

                # Déterminer les propriétés à utiliser comme label et valeur
                $labelProperty = if ($Options.ContainsKey("LabelProperty")) { $Options.LabelProperty } else { $Data[0].PSObject.Properties.Name[0] }
                $valueProperty = if ($Options.ContainsKey("ValueProperty")) { $Options.ValueProperty } else { $Data[0].PSObject.Properties.Name[1] }

                foreach ($item in $Data) {
                    $chartData["Labels"] += $item.$labelProperty
                    $chartData["Values"] += $item.$valueProperty
                }
            }
        }
        "Line" {
            # Configuration spécifique pour les graphiques en lignes
            if (-not $Options.ContainsKey("Smooth")) {
                $chartData.Options["Smooth"] = $false
            }

            # Extraire les séries temporelles si les données sont un tableau d'objets
            if ($Data -is [array] -and $Data.Count -gt 0 -and ($Data[0] -is [hashtable] -or $Data[0] -is [PSObject])) {
                $chartData["Labels"] = @()
                $chartData["Series"] = @{}

                # Déterminer les propriétés à utiliser
                $labelProperty = if ($Options.ContainsKey("LabelProperty")) { $Options.LabelProperty } else { $Data[0].PSObject.Properties.Name[0] }
                $seriesProperties = if ($Options.ContainsKey("SeriesProperties")) { $Options.SeriesProperties } else { $Data[0].PSObject.Properties.Name | Where-Object { $_ -ne $labelProperty } }

                # Initialiser les séries
                foreach ($prop in $seriesProperties) {
                    $chartData["Series"][$prop] = @()
                }

                # Remplir les données
                foreach ($item in $Data) {
                    $chartData["Labels"] += $item.$labelProperty

                    foreach ($prop in $seriesProperties) {
                        $chartData["Series"][$prop] += $item.$prop
                    }
                }
            }
        }
        "Pie" {
            # Configuration spécifique pour les graphiques en camembert
            if (-not $Options.ContainsKey("Donut")) {
                $chartData.Options["Donut"] = $false
            }

            # Extraire les labels et les valeurs si les données sont un tableau d'objets
            if ($Data -is [array] -and $Data.Count -gt 0 -and ($Data[0] -is [hashtable] -or $Data[0] -is [PSObject])) {
                $chartData["Labels"] = @()
                $chartData["Values"] = @()

                # Déterminer les propriétés à utiliser comme label et valeur
                $labelProperty = if ($Options.ContainsKey("LabelProperty")) { $Options.LabelProperty } else { $Data[0].PSObject.Properties.Name[0] }
                $valueProperty = if ($Options.ContainsKey("ValueProperty")) { $Options.ValueProperty } else { $Data[0].PSObject.Properties.Name[1] }

                foreach ($item in $Data) {
                    $chartData["Labels"] += $item.$labelProperty
                    $chartData["Values"] += $item.$valueProperty
                }
            }
        }
        "Scatter" {
            # Configuration spécifique pour les nuages de points
            if (-not $Options.ContainsKey("ShowLine")) {
                $chartData.Options["ShowLine"] = $false
            }

            # Extraire les coordonnées x et y si les données sont un tableau d'objets
            if ($Data -is [array] -and $Data.Count -gt 0 -and ($Data[0] -is [hashtable] -or $Data[0] -is [PSObject])) {
                $chartData["Points"] = @()

                # Déterminer les propriétés à utiliser comme x et y
                $xProperty = if ($Options.ContainsKey("XProperty")) { $Options.XProperty } else { $Data[0].PSObject.Properties.Name[0] }
                $yProperty = if ($Options.ContainsKey("YProperty")) { $Options.YProperty } else { $Data[0].PSObject.Properties.Name[1] }

                foreach ($item in $Data) {
                    $chartData["Points"] += @{
                        x = $item.$xProperty
                        y = $item.$yProperty
                    }
                }
            }
        }
    }

    # Ajouter le graphique comme une section au rapport
    return Add-ExtractedInfoReportSection -Report $Report -Title $Title -Content $chartData -Type "Chart" -Level $Level
}

<#
.SYNOPSIS
Ajoute un graphique en barres à un rapport d'information extraite.

.DESCRIPTION
La fonction Add-ExtractedInfoReportBarChart est un wrapper autour de Add-ExtractedInfoReportChart
spécifiquement pour les graphiques en barres.

.PARAMETER Report
Le rapport auquel ajouter le graphique.

.PARAMETER Title
Le titre du graphique.

.PARAMETER Data
Les données du graphique. Peut être un tableau, une hashtable ou un objet.

.PARAMETER Options
Options supplémentaires pour le graphique (couleurs, légendes, etc.).

.PARAMETER Level
Le niveau de la section (1 à 4). Utilisé pour la numérotation hiérarchique.
Par défaut, 1.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de données"
$data = @(
    @{ Category = "A"; Value = 10 },
    @{ Category = "B"; Value = 20 },
    @{ Category = "C"; Value = 15 }
)
$report = Add-ExtractedInfoReportBarChart -Report $report -Title "Répartition par catégorie" -Data $data

.NOTES
Cette fonction est un wrapper autour de Add-ExtractedInfoReportChart avec le type "Bar".
#>
function Add-ExtractedInfoReportBarChart {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Title,

        [Parameter(Mandatory = $true, Position = 2)]
        [object]$Data,

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{},

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 4)]
        [int]$Level = 1
    )

    return Add-ExtractedInfoReportChart -Report $Report -Title $Title -Data $Data -ChartType "Bar" -Options $Options -Level $Level
}

<#
.SYNOPSIS
Ajoute un graphique en camembert à un rapport d'information extraite.

.DESCRIPTION
La fonction Add-ExtractedInfoReportPieChart est un wrapper autour de Add-ExtractedInfoReportChart
spécifiquement pour les graphiques en camembert.

.PARAMETER Report
Le rapport auquel ajouter le graphique.

.PARAMETER Title
Le titre du graphique.

.PARAMETER Data
Les données du graphique. Peut être un tableau, une hashtable ou un objet.

.PARAMETER Options
Options supplémentaires pour le graphique (couleurs, légendes, etc.).

.PARAMETER Level
Le niveau de la section (1 à 4). Utilisé pour la numérotation hiérarchique.
Par défaut, 1.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de données"
$data = @(
    @{ Category = "A"; Value = 10 },
    @{ Category = "B"; Value = 20 },
    @{ Category = "C"; Value = 15 }
)
$report = Add-ExtractedInfoReportPieChart -Report $report -Title "Répartition par catégorie" -Data $data

.NOTES
Cette fonction est un wrapper autour de Add-ExtractedInfoReportChart avec le type "Pie".
#>
function Add-ExtractedInfoReportPieChart {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Title,

        [Parameter(Mandatory = $true, Position = 2)]
        [object]$Data,

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{},

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 4)]
        [int]$Level = 1
    )

    return Add-ExtractedInfoReportChart -Report $Report -Title $Title -Data $Data -ChartType "Pie" -Options $Options -Level $Level
}

# Exporter les fonctions
Export-ModuleMember -Function Add-ExtractedInfoReportChart, Add-ExtractedInfoReportBarChart, Add-ExtractedInfoReportPieChart
