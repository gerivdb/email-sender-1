#Requires -Version 5.1
<#
.SYNOPSIS
    Module de visualisation pour les rapports d'analyse de pull requests.
.DESCRIPTION
    Fournit des fonctions pour générer des visualisations graphiques
    des résultats d'analyse de pull requests.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Fonction pour générer un graphique à barres en HTML/CSS
function New-PRBarChart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Data,

        [Parameter()]
        [string]$Title = "Graphique à barres",

        [Parameter()]
        [int]$Width = 600,

        [Parameter()]
        [int]$Height = 400,

        [Parameter()]
        [string[]]$Colors = @("#4285F4", "#EA4335", "#FBBC05", "#34A853", "#FF6D01", "#46BDC6", "#7BAAF7")
    )

    $html = @"
<div class="pr-chart" style="width: ${Width}px; height: ${Height}px;">
    <h3 class="pr-chart-title">$Title</h3>
    <div class="pr-bar-chart">
"@

    # Vérifier si les données sont vides
    if ($Data.Count -eq 0) {
        $html += @"
    <div class="pr-no-data">Aucune donnée disponible</div>
"@
    } else {
        $maxValue = ($Data.Values | Measure-Object -Maximum).Maximum
        $i = 0

        foreach ($key in $Data.Keys) {
            $value = $Data[$key]
            $percentage = if ($maxValue -gt 0) { ($value / $maxValue) * 100 } else { 0 }
            $color = $Colors[$i % $Colors.Count]

            $html += @"
        <div class="pr-bar-item">
            <div class="pr-bar-label">$key</div>
            <div class="pr-bar-container">
                <div class="pr-bar" style="width: $percentage%; background-color: $color;">
                    <span class="pr-bar-value">$value</span>
                </div>
            </div>
        </div>
"@

            $i++
        }
    }

    $html += @"
    </div>
</div>
<style>
.pr-chart {
    font-family: Arial, sans-serif;
    margin: 20px 0;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 5px;
    background-color: #fff;
}
.pr-chart-title {
    text-align: center;
    margin-bottom: 15px;
    color: #333;
}
.pr-bar-chart {
    display: flex;
    flex-direction: column;
    gap: 10px;
}
.pr-bar-item {
    display: flex;
    align-items: center;
}
.pr-bar-label {
    width: 150px;
    text-align: right;
    padding-right: 10px;
    font-size: 14px;
    color: #555;
}
.pr-bar-container {
    flex-grow: 1;
    background-color: #f5f5f5;
    border-radius: 4px;
    overflow: hidden;
    height: 25px;
}
.pr-bar {
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: flex-end;
    padding-right: 10px;
    transition: width 0.5s ease;
}
.pr-bar-value {
    color: white;
    font-weight: bold;
    text-shadow: 1px 1px 1px rgba(0,0,0,0.3);
}
.pr-no-data {
    text-align: center;
    padding: 20px;
    color: #888;
    font-style: italic;
}
</style>
"@

    return $html
}

# Fonction pour générer un graphique circulaire en HTML/CSS
function New-PRPieChart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Data,

        [Parameter()]
        [string]$Title = "Graphique circulaire",

        [Parameter()]
        [int]$Size = 300,

        [Parameter()]
        [string[]]$Colors = @("#4285F4", "#EA4335", "#FBBC05", "#34A853", "#FF6D01", "#46BDC6", "#7BAAF7")
    )

    $html = @"
<div class="pr-chart" style="width: ${Size}px;">
    <h3 class="pr-chart-title">$Title</h3>
    <div class="pr-pie-container" style="width: ${Size}px; height: ${Size}px;">
        <div class="pr-pie-chart">
"@

    # Vérifier si les données sont vides
    if ($Data.Count -eq 0) {
        $html += @"
            <div class="pr-no-data">Aucune donnée disponible</div>
"@
    } else {
        $total = ($Data.Values | Measure-Object -Sum).Sum
        $startAngle = 0
        $i = 0

        foreach ($key in $Data.Keys) {
            $value = $Data[$key]
            $percentage = if ($total -gt 0) { ($value / $total) * 100 } else { 0 }
            $angle = if ($total -gt 0) { ($value / $total) * 360 } else { 0 }
            $endAngle = $startAngle + $angle
            $color = $Colors[$i % $Colors.Count]

            # Générer le segment de cercle avec CSS conic-gradient
            $html += @"
            <div class="pr-pie-slice" style="--start: ${startAngle}deg; --end: ${endAngle}deg; --color: $color;" data-value="$value" data-label="$key" data-percentage="$([Math]::Round($percentage, 1))%"></div>
"@

            $startAngle = $endAngle
            $i++
        }
    }

    $html += @"
        </div>
    </div>
    <div class="pr-pie-legend">
"@

    # Vérifier si les données sont vides pour la légende
    if ($Data.Count -eq 0) {
        $html += @"
        <div class="pr-no-data">Aucune donnée disponible</div>
"@
    } else {
        $i = 0
        foreach ($key in $Data.Keys) {
            $value = $Data[$key]
            $percentage = if ($total -gt 0) { ($value / $total) * 100 } else { 0 }
            $color = $Colors[$i % $Colors.Count]

            $html += @"
        <div class="pr-legend-item">
            <span class="pr-legend-color" style="background-color: $color;"></span>
            <span class="pr-legend-label">$key</span>
            <span class="pr-legend-value">$value ($([Math]::Round($percentage, 1))%)</span>
        </div>
"@

            $i++
        }
    }

    $html += @"
    </div>
</div>
<style>
.pr-chart {
    font-family: Arial, sans-serif;
    margin: 20px auto;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 5px;
    background-color: #fff;
}
.pr-chart-title {
    text-align: center;
    margin-bottom: 15px;
    color: #333;
}
.pr-pie-container {
    position: relative;
    margin: 0 auto;
}
.pr-pie-chart {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    position: relative;
    overflow: hidden;
}
.pr-pie-slice {
    position: absolute;
    width: 100%;
    height: 100%;
    transform: rotate(var(--start));
    background: conic-gradient(var(--color) 0deg calc(var(--end) - var(--start)), transparent calc(var(--end) - var(--start)) 360deg);
}
.pr-pie-legend {
    margin-top: 20px;
    display: flex;
    flex-direction: column;
    gap: 5px;
}
.pr-legend-item {
    display: flex;
    align-items: center;
    font-size: 14px;
}
.pr-legend-color {
    width: 15px;
    height: 15px;
    border-radius: 3px;
    margin-right: 8px;
}
.pr-legend-label {
    flex-grow: 1;
}
.pr-legend-value {
    font-weight: bold;
}
.pr-no-data {
    text-align: center;
    padding: 20px;
    color: #888;
    font-style: italic;
}
</style>
"@

    return $html
}

# Fonction pour générer un graphique en ligne en HTML/CSS
function New-PRLineChart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Data,

        [Parameter()]
        [string]$Title = "Graphique en ligne",

        [Parameter()]
        [int]$Width = 600,

        [Parameter()]
        [int]$Height = 400,

        [Parameter()]
        [string[]]$Colors = @("#4285F4", "#EA4335", "#FBBC05", "#34A853", "#FF6D01")
    )

    # Vérifier si les données sont vides
    if ($Data.Count -eq 0) {
        $html = @"
<div class="pr-chart" style="width: ${Width}px; height: ${Height}px;">
    <h3 class="pr-chart-title">$Title</h3>
    <div class="pr-line-chart" style="height: $(${Height} - 100)px;">
        <div class="pr-grid-line" style="bottom: 100%;">
            <span class="pr-grid-label">0</span>
        </div>
        <div class="pr-grid-line" style="bottom: 75%;">
            <span class="pr-grid-label">0</span>
        </div>
        <div class="pr-grid-line" style="bottom: 50%;">
            <span class="pr-grid-label">0</span>
        </div>
        <div class="pr-grid-line" style="bottom: 25%;">
            <span class="pr-grid-label">0</span>
        </div>
        <div class="pr-grid-line" style="bottom: 0%;">
            <span class="pr-grid-label">0</span>
        </div>
"@
    } else {
        # Déterminer les valeurs min et max pour l'axe Y
        $allValues = @()
        foreach ($series in $Data.Values) {
            $allValues += $series.Values
        }

        $minValue = ($allValues | Measure-Object -Minimum).Minimum
        $maxValue = ($allValues | Measure-Object -Maximum).Maximum

        # Ajuster pour avoir une marge
        $range = $maxValue - $minValue
        $minValue = [Math]::Max(0, $minValue - ($range * 0.1))
        $maxValue = $maxValue + ($range * 0.1)

        # Obtenir toutes les clés (étiquettes de l'axe X)
        $allKeys = @()
        foreach ($series in $Data.Values) {
            $allKeys += $series.Keys
        }
        $uniqueKeys = $allKeys | Select-Object -Unique | Sort-Object

        $html = @"
<div class="pr-chart" style="width: ${Width}px; height: ${Height}px;">
    <h3 class="pr-chart-title">$Title</h3>
    <div class="pr-line-chart" style="height: $(${Height} - 100)px;">
"@

        # Générer les lignes de la grille
        $gridLines = 5
        for ($i = 0; $i -lt $gridLines; $i++) {
            $percentage = 100 - (($i / ($gridLines - 1)) * 100)
            $value = $minValue + (($maxValue - $minValue) * ($i / ($gridLines - 1)))

            $html += @"
        <div class="pr-grid-line" style="bottom: ${percentage}%;">
            <span class="pr-grid-label">$([Math]::Round($value, 1))</span>
        </div>
"@
        }

        # Générer les séries
        $i = 0
        foreach ($seriesName in $Data.Keys) {
            $series = $Data[$seriesName]
            $color = $Colors[$i % $Colors.Count]

            $html += @"
        <div class="pr-line-series" data-name="$seriesName">
"@

            # Générer les points
            foreach ($key in $uniqueKeys) {
                if ($series.ContainsKey($key)) {
                    $value = $series[$key]
                    $percentage = if ($maxValue -ne $minValue) { (($value - $minValue) / ($maxValue - $minValue)) * 100 } else { 50 }

                    $html += @"
            <div class="pr-line-point" style="left: $(100 * [array]::IndexOf($uniqueKeys, $key) / [Math]::Max(1, ($uniqueKeys.Count - 1)))%; bottom: ${percentage}%;" data-label="$key" data-value="$value">
                <div class="pr-point" style="background-color: $color;"></div>
            </div>
"@
                }
            }

            $html += @"
        </div>
"@

            $i++
        }
    }

    # Générer l'axe X
    $html += @"
    </div>
    <div class="pr-x-axis">
"@

    foreach ($key in $uniqueKeys) {
        $percentage = 100 * [array]::IndexOf($uniqueKeys, $key) / ($uniqueKeys.Count - 1)

        $html += @"
        <div class="pr-x-label" style="left: ${percentage}%;">$key</div>
"@
    }

    # Générer la légende
    $html += @"
    </div>
    <div class="pr-line-legend">
"@

    $i = 0
    foreach ($seriesName in $Data.Keys) {
        $color = $Colors[$i % $Colors.Count]

        $html += @"
        <div class="pr-legend-item">
            <span class="pr-legend-color" style="background-color: $color;"></span>
            <span class="pr-legend-label">$seriesName</span>
        </div>
"@

        $i++
    }

    $html += @"
    </div>
</div>
<style>
.pr-chart {
    font-family: Arial, sans-serif;
    margin: 20px 0;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 5px;
    background-color: #fff;
}
.pr-chart-title {
    text-align: center;
    margin-bottom: 15px;
    color: #333;
}
.pr-line-chart {
    position: relative;
    margin: 20px 40px 0 40px;
    border-left: 1px solid #ddd;
    border-bottom: 1px solid #ddd;
}
.pr-grid-line {
    position: absolute;
    left: 0;
    right: 0;
    border-top: 1px dashed #eee;
}
.pr-grid-label {
    position: absolute;
    left: -35px;
    top: -10px;
    font-size: 12px;
    color: #888;
}
.pr-line-series {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
}
.pr-line-point {
    position: absolute;
    width: 0;
    height: 0;
}
.pr-point {
    position: absolute;
    width: 8px;
    height: 8px;
    border-radius: 50%;
    transform: translate(-50%, 50%);
}
.pr-x-axis {
    position: relative;
    height: 30px;
    margin: 0 40px;
}
.pr-x-label {
    position: absolute;
    transform: translateX(-50%);
    font-size: 12px;
    color: #555;
}
.pr-line-legend {
    display: flex;
    justify-content: center;
    flex-wrap: wrap;
    gap: 15px;
    margin-top: 10px;
}
.pr-legend-item {
    display: flex;
    align-items: center;
    font-size: 14px;
}
.pr-legend-color {
    width: 15px;
    height: 15px;
    border-radius: 3px;
    margin-right: 8px;
}
.pr-no-data {
    text-align: center;
    padding: 20px;
    color: #888;
    font-style: italic;
}
</style>
"@

    return $html
}

# Fonction pour générer une carte de chaleur en HTML/CSS
function New-PRHeatMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[, ]]$Data,

        [Parameter(Mandatory = $true)]
        [string[]]$RowLabels,

        [Parameter(Mandatory = $true)]
        [string[]]$ColumnLabels,

        [Parameter()]
        [string]$Title = "Carte de chaleur",

        [Parameter()]
        [int]$CellSize = 40,

        [Parameter()]
        [string]$LowColor = "#FFFFFF",

        [Parameter()]
        [string]$HighColor = "#FF0000"
    )

    # Vérifier si les données sont vides ou nulles
    if ($null -eq $Data -or $Data.GetLength(0) -eq 0 -or $Data.GetLength(1) -eq 0) {
        $html = @"
<div class="pr-chart">
    <h3 class="pr-chart-title">$Title</h3>
    <div class="pr-heatmap">
        <div class="pr-no-data">Aucune donnée disponible</div>
    </div>
</div>
<style>
.pr-chart {
    font-family: Arial, sans-serif;
    margin: 20px 0;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 5px;
    background-color: #fff;
}
.pr-chart-title {
    text-align: center;
    margin-bottom: 15px;
    color: #333;
}
.pr-no-data {
    text-align: center;
    padding: 20px;
    color: #888;
    font-style: italic;
}
</style>
"@
        return $html
    }

    # Déterminer les valeurs min et max
    $minValue = [double]::MaxValue
    $maxValue = [double]::MinValue

    for ($i = 0; $i -lt $Data.GetLength(0); $i++) {
        for ($j = 0; $j -lt $Data.GetLength(1); $j++) {
            $value = $Data[$i, $j]
            if ($value -lt $minValue) { $minValue = $value }
            if ($value -gt $maxValue) { $maxValue = $value }
        }
    }

    $html = @"
<div class="pr-chart">
    <h3 class="pr-chart-title">$Title</h3>
    <div class="pr-heatmap">
        <div class="pr-heatmap-corner"></div>
        <div class="pr-heatmap-columns">
"@

    # Générer les étiquettes de colonnes
    foreach ($label in $ColumnLabels) {
        $html += @"
            <div class="pr-heatmap-column-label" style="width: ${CellSize}px;">$label</div>
"@
    }

    $html += @"
        </div>
        <div class="pr-heatmap-rows">
"@

    # Générer les étiquettes de lignes
    foreach ($label in $RowLabels) {
        $html += @"
            <div class="pr-heatmap-row-label">$label</div>
"@
    }

    $html += @"
        </div>
        <div class="pr-heatmap-grid" style="grid-template-columns: repeat($($ColumnLabels.Count), ${CellSize}px); grid-template-rows: repeat($($RowLabels.Count), ${CellSize}px);">
"@

    # Générer les cellules
    for ($i = 0; $i -lt $Data.GetLength(0); $i++) {
        for ($j = 0; $j -lt $Data.GetLength(1); $j++) {
            $value = $Data[$i, $j]
            $intensity = if ($maxValue -ne $minValue) { ($value - $minValue) / ($maxValue - $minValue) } else { 0.5 }

            $cellColor = Get-ColorGradient -StartColor $LowColor -EndColor $HighColor -Intensity $intensity
            $html += @"
            <div class="pr-heatmap-cell" style="background-color: $cellColor;" data-value="$value"></div>
"@
        }
    }

    $html += @"
        </div>
    </div>
    <div class="pr-heatmap-legend">
        <div class="pr-heatmap-gradient" style="background: linear-gradient(to right, $LowColor, $HighColor);"></div>
        <div class="pr-heatmap-legend-labels">
            <span>$minValue</span>
            <span>$maxValue</span>
        </div>
    </div>
</div>
<style>
.pr-chart {
    font-family: Arial, sans-serif;
    margin: 20px 0;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 5px;
    background-color: #fff;
}
.pr-chart-title {
    text-align: center;
    margin-bottom: 15px;
    color: #333;
}
.pr-heatmap {
    display: grid;
    grid-template-columns: auto 1fr;
    grid-template-rows: auto 1fr;
    gap: 0;
}
.pr-heatmap-corner {
    grid-column: 1;
    grid-row: 1;
}
.pr-heatmap-columns {
    grid-column: 2;
    grid-row: 1;
    display: flex;
}
.pr-heatmap-column-label {
    text-align: center;
    padding: 5px;
    font-size: 12px;
    color: #555;
    transform: rotate(-45deg);
    transform-origin: bottom left;
    height: 60px;
    display: flex;
    align-items: flex-end;
}
.pr-heatmap-rows {
    grid-column: 1;
    grid-row: 2;
    display: flex;
    flex-direction: column;
}
.pr-heatmap-row-label {
    padding: 5px 10px;
    font-size: 12px;
    color: #555;
    height: ${CellSize}px;
    display: flex;
    align-items: center;
    justify-content: flex-end;
}
.pr-heatmap-grid {
    grid-column: 2;
    grid-row: 2;
    display: grid;
}
.pr-heatmap-cell {
    border: 1px solid #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    color: #333;
    transition: transform 0.2s;
}
.pr-heatmap-cell:hover {
    transform: scale(1.1);
    z-index: 1;
}
.pr-heatmap-legend {
    margin-top: 20px;
    padding: 0 20px;
}
.pr-heatmap-gradient {
    height: 20px;
    border-radius: 3px;
}
.pr-heatmap-legend-labels {
    display: flex;
    justify-content: space-between;
    font-size: 12px;
    color: #555;
    margin-top: 5px;
}
</style>
"@

    return $html
}

# Fonction utilitaire pour calculer une couleur dans un dégradé
function Get-ColorGradient {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartColor,

        [Parameter(Mandatory = $true)]
        [string]$EndColor,

        [Parameter(Mandatory = $true)]
        [double]$Intensity
    )

    # Convertir les couleurs hexadécimales en composantes RGB
    $startR = [Convert]::ToInt32($StartColor.Substring(1, 2), 16)
    $startG = [Convert]::ToInt32($StartColor.Substring(3, 2), 16)
    $startB = [Convert]::ToInt32($StartColor.Substring(5, 2), 16)

    $endR = [Convert]::ToInt32($EndColor.Substring(1, 2), 16)
    $endG = [Convert]::ToInt32($EndColor.Substring(3, 2), 16)
    $endB = [Convert]::ToInt32($EndColor.Substring(5, 2), 16)

    # Calculer la couleur intermédiaire
    $r = [Math]::Round($startR + ($endR - $startR) * $Intensity)
    $g = [Math]::Round($startG + ($endG - $startG) * $Intensity)
    $b = [Math]::Round($startB + ($endB - $startB) * $Intensity)

    # Convertir en hexadécimal
    return "#{0:X2}{1:X2}{2:X2}" -f [int]$r, [int]$g, [int]$b
}

# Exporter les fonctions
Export-ModuleMember -Function New-PRBarChart, New-PRPieChart, New-PRLineChart, New-PRHeatMap, Get-ColorGradient
