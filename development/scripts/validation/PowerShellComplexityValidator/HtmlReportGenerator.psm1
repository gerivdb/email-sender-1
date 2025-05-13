#Requires -Version 5.1
<#
.SYNOPSIS
    Module de génération de rapports HTML pour la visualisation de la complexité cyclomatique.
.DESCRIPTION
    Ce module fournit des fonctions pour générer des rapports HTML qui visualisent
    la complexité cyclomatique du code PowerShell.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

#region Variables globales

# Styles CSS par défaut pour les rapports
$script:DefaultCssStyles = @"
:root {
    --primary-color: #0078d4;
    --secondary-color: #2b88d8;
    --background-color: #f9f9f9;
    --text-color: #333;
    --border-color: #ddd;
    --success-color: #107c10;
    --warning-color: #ff8c00;
    --error-color: #d13438;
    --info-color: #0078d4;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: var(--text-color);
    background-color: var(--background-color);
    margin: 0;
    padding: 20px;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    background-color: white;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

h1, h2, h3, h4, h5, h6 {
    color: var(--primary-color);
    margin-top: 1.5em;
    margin-bottom: 0.5em;
}

h1 {
    font-size: 2em;
    border-bottom: 2px solid var(--primary-color);
    padding-bottom: 0.3em;
}

h2 {
    font-size: 1.5em;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 0.3em;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin: 1em 0;
}

th, td {
    padding: 8px 12px;
    text-align: left;
    border: 1px solid var(--border-color);
}

th {
    background-color: var(--primary-color);
    color: white;
}

tr:nth-child(even) {
    background-color: rgba(0, 0, 0, 0.05);
}

.complexity-low {
    background-color: #e6ffe6;
    color: var(--success-color);
}

.complexity-medium {
    background-color: #fff9e6;
    color: var(--warning-color);
}

.complexity-high {
    background-color: #ffe6e6;
    color: var(--error-color);
}

.complexity-very-high {
    background-color: #ffe6e6;
    color: var(--error-color);
    font-weight: bold;
}

.code-block {
    font-family: Consolas, Monaco, 'Andale Mono', 'Ubuntu Mono', monospace;
    background-color: #f5f5f5;
    border: 1px solid var(--border-color);
    border-radius: 3px;
    padding: 1em;
    overflow: auto;
    white-space: pre;
    line-height: 1.5;
    counter-reset: line;
}

.code-block .line {
    display: inline-block;
    width: 100%;
    position: relative;
    padding-left: 3.5em;
    min-height: 1.5em;
    counter-increment: line;
}

.code-block .line:before {
    content: counter(line);
    position: absolute;
    left: 0;
    width: 3em;
    text-align: right;
    color: #888;
    padding-right: 0.5em;
    border-right: 1px solid #ddd;
    user-select: none;
}

.highlight {
    background-color: rgba(255, 255, 0, 0.3);
}

.impact-none {
    /* Pas d'impact sur la complexité */
    background-color: transparent;
}

.impact-low {
    /* Impact faible sur la complexité */
    background-color: rgba(144, 238, 144, 0.3);
}

.impact-medium {
    /* Impact moyen sur la complexité */
    background-color: rgba(255, 255, 0, 0.3);
}

.impact-high {
    /* Impact élevé sur la complexité */
    background-color: rgba(255, 165, 0, 0.3);
}

.impact-critical {
    /* Impact critique sur la complexité */
    background-color: rgba(255, 0, 0, 0.3);
}

.structure-tooltip {
    position: relative;
    display: inline-block;
    cursor: pointer;
}

.structure-tooltip .tooltip-text {
    visibility: hidden;
    width: 200px;
    background-color: #333;
    color: #fff;
    text-align: center;
    border-radius: 6px;
    padding: 5px;
    position: absolute;
    z-index: 1;
    bottom: 125%;
    left: 50%;
    margin-left: -100px;
    opacity: 0;
    transition: opacity 0.3s;
}

.structure-tooltip .tooltip-text::after {
    content: "";
    position: absolute;
    top: 100%;
    left: 50%;
    margin-left: -5px;
    border-width: 5px;
    border-style: solid;
    border-color: #333 transparent transparent transparent;
}

.structure-tooltip:hover .tooltip-text {
    visibility: visible;
    opacity: 1;
}

.color-legend {
    margin: 1em 0;
    padding: 1em;
    border: 1px solid var(--border-color);
    border-radius: 3px;
    background-color: #f9f9f9;
}

.legend-items {
    display: flex;
    flex-wrap: wrap;
    gap: 1em;
}

.legend-item {
    display: flex;
    align-items: center;
    margin-right: 1em;
}

.color-box {
    display: inline-block;
    width: 20px;
    height: 20px;
    margin-right: 0.5em;
    border: 1px solid #ccc;
}

.filter-controls {
    margin: 1em 0;
    padding: 1em;
    border: 1px solid var(--border-color);
    border-radius: 3px;
    background-color: #f9f9f9;
}

.filter-controls select {
    padding: 0.5em;
    border: 1px solid var(--border-color);
    border-radius: 3px;
    background-color: white;
}

.structure-highlight {
    position: relative;
    display: inline-block;
}

.chart-container {
    width: 100%;
    height: 400px;
    margin: 1em 0;
}

.summary-box {
    border: 1px solid var(--border-color);
    border-radius: 3px;
    padding: 1em;
    margin: 1em 0;
    background-color: #f5f5f5;
}

.nav-tabs {
    display: flex;
    list-style: none;
    padding: 0;
    margin: 0;
    border-bottom: 1px solid var(--border-color);
}

.nav-tabs li {
    margin-right: 5px;
}

.nav-tabs a {
    display: block;
    padding: 8px 16px;
    text-decoration: none;
    color: var(--text-color);
    border: 1px solid transparent;
    border-bottom: none;
    border-radius: 3px 3px 0 0;
}

.nav-tabs a.active {
    background-color: white;
    border-color: var(--border-color);
    border-bottom-color: white;
    margin-bottom: -1px;
    color: var(--primary-color);
}

.tab-content {
    padding: 20px;
    border: 1px solid var(--border-color);
    border-top: none;
}

.tab-pane {
    display: none;
}

.tab-pane.active {
    display: block;
}

.footer {
    margin-top: 2em;
    padding-top: 1em;
    border-top: 1px solid var(--border-color);
    text-align: center;
    font-size: 0.9em;
    color: #666;
}
"@

# Scripts JavaScript par défaut pour les rapports
$script:DefaultJavaScript = @"
document.addEventListener('DOMContentLoaded', function() {
    // Gestion des onglets
    const tabs = document.querySelectorAll('.nav-tabs a');
    tabs.forEach(tab => {
        tab.addEventListener('click', function(e) {
            e.preventDefault();

            // Désactiver tous les onglets
            tabs.forEach(t => t.classList.remove('active'));

            // Masquer tous les contenus d'onglets
            document.querySelectorAll('.tab-pane').forEach(pane => {
                pane.classList.remove('active');
            });

            // Activer l'onglet cliqué
            this.classList.add('active');

            // Afficher le contenu de l'onglet
            const target = this.getAttribute('href').substring(1);
            document.getElementById(target).classList.add('active');
        });
    });

    // Activer le premier onglet par défaut
    if (tabs.length > 0) {
        tabs[0].click();
    }

    // Gestion des tooltips pour les structures de contrôle
    document.querySelectorAll('.structure-tooltip').forEach(tooltip => {
        tooltip.addEventListener('mouseenter', function() {
            const tooltipText = this.querySelector('.tooltip-text');
            if (tooltipText) {
                // Ajuster la position du tooltip pour qu'il reste visible
                const rect = tooltipText.getBoundingClientRect();
                if (rect.top < 0) {
                    tooltipText.style.bottom = 'auto';
                    tooltipText.style.top = '125%';
                    tooltipText.style.transform = 'translateX(-50%)';
                }
                if (rect.left < 0) {
                    tooltipText.style.left = '0';
                    tooltipText.style.marginLeft = '0';
                }
                if (rect.right > window.innerWidth) {
                    tooltipText.style.left = 'auto';
                    tooltipText.style.right = '0';
                    tooltipText.style.marginLeft = '0';
                }
            }
        });
    });

    // Légende des couleurs
    const legendContainer = document.querySelector('.color-legend');
    if (legendContainer) {
        const legend = document.createElement('div');
        legend.className = 'legend-items';

        const items = [
            { class: 'impact-none', label: 'Pas d\'impact' },
            { class: 'impact-low', label: 'Impact faible' },
            { class: 'impact-medium', label: 'Impact moyen' },
            { class: 'impact-high', label: 'Impact élevé' },
            { class: 'impact-critical', label: 'Impact critique' }
        ];

        items.forEach(item => {
            const legendItem = document.createElement('div');
            legendItem.className = 'legend-item';

            const colorBox = document.createElement('span');
            colorBox.className = 'color-box ' + item.class;

            const label = document.createElement('span');
            label.textContent = item.label;

            legendItem.appendChild(colorBox);
            legendItem.appendChild(label);
            legend.appendChild(legendItem);
        });

        legendContainer.appendChild(legend);
    }

    // Filtrer les structures par type
    const filterSelect = document.getElementById('structure-filter');
    if (filterSelect) {
        filterSelect.addEventListener('change', function() {
            const selectedType = this.value;
            const structures = document.querySelectorAll('.structure-highlight');

            structures.forEach(structure => {
                if (selectedType === 'all' || structure.dataset.type === selectedType) {
                    structure.style.display = '';
                } else {
                    structure.style.display = 'none';
                }
            });
        });
    }
});
"@

#endregion

#region Fonctions privées

# Fonction pour obtenir la classe CSS en fonction de la complexité
function Get-ComplexityClass {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Complexity,

        [Parameter(Mandatory = $false)]
        [hashtable]$Thresholds = @{
            Low      = 5
            Medium   = 10
            High     = 20
            VeryHigh = 30
        }
    )

    if ($Complexity -ge $Thresholds.VeryHigh) {
        return "complexity-very-high"
    } elseif ($Complexity -ge $Thresholds.High) {
        return "complexity-high"
    } elseif ($Complexity -ge $Thresholds.Medium) {
        return "complexity-medium"
    } else {
        return "complexity-low"
    }
}

# Fonction pour déterminer l'impact d'une structure de contrôle sur la complexité
function Get-StructureImpactClass {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [int]$NestingLevel = 0,

        [Parameter(Mandatory = $false)]
        [hashtable]$Weights = @{
            "If"                  = 1.0
            "ElseIf"              = 1.0
            "For"                 = 1.0
            "ForEach"             = 1.0
            "While"               = 1.0
            "DoWhile"             = 1.0
            "Switch"              = 1.0
            "SwitchClause"        = 1.0
            "SwitchDefault"       = 1.0
            "Catch"               = 1.0
            "LogicalOperator_And" = 1.0
            "LogicalOperator_Or"  = 1.0
            "TernaryOperator"     = 1.0
            "Else"                = 0.0
        }
    )

    # Obtenir le poids de base pour ce type de structure
    $baseWeight = if ($Weights.ContainsKey($Type)) { $Weights[$Type] } else { 0.5 }

    # Ajuster le poids en fonction du niveau d'imbrication
    $adjustedWeight = $baseWeight
    if ($NestingLevel -gt 0) {
        $adjustedWeight += $NestingLevel * 0.2
    }

    # Déterminer la classe d'impact en fonction du poids ajusté
    if ($adjustedWeight -le 0) {
        return "impact-none"
    } elseif ($adjustedWeight -le 0.5) {
        return "impact-low"
    } elseif ($adjustedWeight -le 1.0) {
        return "impact-medium"
    } elseif ($adjustedWeight -le 1.5) {
        return "impact-high"
    } else {
        return "impact-critical"
    }
}

# Fonction pour échapper les caractères HTML
function ConvertTo-HtmlEscaped {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    return $Text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&#39;")
}

# Fonction pour générer un identifiant unique
function New-UniqueId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Prefix = "id"
    )

    return "$Prefix-$(Get-Random -Minimum 10000 -Maximum 99999)"
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Génère un rapport HTML pour la complexité cyclomatique.
.DESCRIPTION
    Cette fonction génère un rapport HTML qui visualise la complexité cyclomatique
    du code PowerShell.
.PARAMETER Results
    Résultats de l'analyse de complexité cyclomatique.
.PARAMETER OutputPath
    Chemin du fichier HTML de sortie.
.PARAMETER Title
    Titre du rapport.
.PARAMETER CustomCss
    Styles CSS personnalisés à ajouter au rapport.
.PARAMETER CustomJavaScript
    Scripts JavaScript personnalisés à ajouter au rapport.
.EXAMPLE
    New-ComplexityHtmlReport -Results $results -OutputPath "report.html" -Title "Rapport de complexité"
    Génère un rapport HTML pour les résultats d'analyse de complexité spécifiés.
.OUTPUTS
    System.String
    Retourne le chemin du fichier HTML généré.
#>
function New-ComplexityHtmlReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de complexité cyclomatique",

        [Parameter(Mandatory = $false)]
        [string]$CustomCss = "",

        [Parameter(Mandatory = $false)]
        [string]$CustomJavaScript = ""
    )

    # Générer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>
    <style>
$script:DefaultCssStyles
$CustomCss
    </style>
</head>
<body>
    <div class="container">
        <h1>$Title</h1>
        <div class="summary-box">
            <h2>Résumé</h2>
            <p>Nombre total de fonctions analysées : $($Results.Count)</p>
            <p>Complexité moyenne : $([Math]::Round(($Results | Measure-Object -Property Value -Average).Average, 2))</p>
            <p>Complexité maximale : $($Results | Measure-Object -Property Value -Maximum | Select-Object -ExpandProperty Maximum)</p>
        </div>

        <div class="nav-tabs">
            <li><a href="#tab-overview" class="active">Vue d'ensemble</a></li>
            <li><a href="#tab-details">Détails</a></li>
            <li><a href="#tab-charts">Graphiques</a></li>
        </div>

        <div class="tab-content">
            <div id="tab-overview" class="tab-pane active">
                <h2>Vue d'ensemble</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Fonction</th>
                            <th>Type</th>
                            <th>Ligne</th>
                            <th>Complexité</th>
                            <th>Sévérité</th>
                        </tr>
                    </thead>
                    <tbody>
$(
    $tableRows = foreach ($result in $Results) {
        $complexityClass = Get-ComplexityClass -Complexity $result.Value
        "<tr class=`"$complexityClass`">
            <td>$($result.Function)</td>
            <td>$($result.Type)</td>
            <td>$($result.Line)</td>
            <td>$($result.Value)</td>
            <td>$($result.Severity)</td>
        </tr>"
    }
    $tableRows -join "`n"
)
                    </tbody>
                </table>
            </div>

            <div id="tab-details" class="tab-pane">
                <h2>Détails</h2>
$(
    $detailsContent = foreach ($result in $Results) {
        $complexityClass = Get-ComplexityClass -Complexity $result.Value

        "<div class=`"$complexityClass`">
            <h3>$($result.Function) (Complexité: $($result.Value))</h3>
            <p>Type: $($result.Type), Ligne: $($result.Line), Sévérité: $($result.Severity)</p>
            <p>$($result.Message)</p>

            <h4>Structures de contrôle</h4>
            <table>
                <thead>
                    <tr>
                        <th>Type</th>
                        <th>Ligne</th>
                        <th>Colonne</th>
                    </tr>
                </thead>
                <tbody>"

        if ($result.ControlStructures -and $result.ControlStructures.Count -gt 0) {
            foreach ($structure in $result.ControlStructures) {
                "<tr>
                    <td>$($structure.Type)</td>
                    <td>$($structure.Line)</td>
                    <td>$($structure.Column)</td>
                </tr>"
            }
        }
        else {
            "<tr><td colspan=`"3`">Aucune structure de contrôle détectée</td></tr>"
        }

        "</tbody>
            </table>
        </div>"
    }
    $detailsContent -join "`n"
)
            </div>

            <div id="tab-charts" class="tab-pane">
                <h2>Graphiques</h2>

                <div class="chart-container">
                    <h3>Distribution de la complexité cyclomatique</h3>
                    <canvas id="complexityDistributionChart"></canvas>
                </div>

                <div class="chart-container">
                    <h3>Répartition des types de structures</h3>
                    <canvas id="structureTypesChart"></canvas>
                </div>

                <div class="chart-container">
                    <h3>Top 10 des fonctions les plus complexes</h3>
                    <canvas id="topComplexFunctionsChart"></canvas>
                </div>

                <script>
                // Données pour les graphiques
                const complexityData = {
                    labels: ['1-5', '6-10', '11-15', '16-20', '21-25', '26-30', '30+'],
                    datasets: [{
                        label: 'Nombre de fonctions',
                        data: [
                            $($Results | Where-Object { $_.Value -le 5 } | Measure-Object | Select-Object -ExpandProperty Count),
                            $($Results | Where-Object { $_.Value -gt 5 -and $_.Value -le 10 } | Measure-Object | Select-Object -ExpandProperty Count),
                            $($Results | Where-Object { $_.Value -gt 10 -and $_.Value -le 15 } | Measure-Object | Select-Object -ExpandProperty Count),
                            $($Results | Where-Object { $_.Value -gt 15 -and $_.Value -le 20 } | Measure-Object | Select-Object -ExpandProperty Count),
                            $($Results | Where-Object { $_.Value -gt 20 -and $_.Value -le 25 } | Measure-Object | Select-Object -ExpandProperty Count),
                            $($Results | Where-Object { $_.Value -gt 25 -and $_.Value -le 30 } | Measure-Object | Select-Object -ExpandProperty Count),
                            $($Results | Where-Object { $_.Value -gt 30 } | Measure-Object | Select-Object -ExpandProperty Count)
                        ],
                        backgroundColor: [
                            'rgba(75, 192, 192, 0.6)',
                            'rgba(54, 162, 235, 0.6)',
                            'rgba(255, 206, 86, 0.6)',
                            'rgba(255, 159, 64, 0.6)',
                            'rgba(255, 99, 132, 0.6)',
                            'rgba(153, 102, 255, 0.6)',
                            'rgba(255, 99, 132, 0.6)'
                        ],
                        borderColor: [
                            'rgba(75, 192, 192, 1)',
                            'rgba(54, 162, 235, 1)',
                            'rgba(255, 206, 86, 1)',
                            'rgba(255, 159, 64, 1)',
                            'rgba(255, 99, 132, 1)',
                            'rgba(153, 102, 255, 1)',
                            'rgba(255, 99, 132, 1)'
                        ],
                        borderWidth: 1
                    }]
                };

                // Données pour le graphique des types de structures
                const structureTypes = {};
                $Results | ForEach-Object {
                    if ($_.ControlStructures) {
                        $_.ControlStructures | ForEach-Object {
                            if ($structureTypes.ContainsKey($_.Type)) {
                                $structureTypes[$_.Type]++;
                            } else {
                                $structureTypes[$_.Type] = 1;
                            }
                        }
                    }
                };

                const structureTypesData = {
                    labels: Object.keys(structureTypes),
                    datasets: [{
                        label: 'Nombre de structures',
                        data: Object.values(structureTypes),
                        backgroundColor: [
                            'rgba(75, 192, 192, 0.6)',
                            'rgba(54, 162, 235, 0.6)',
                            'rgba(255, 206, 86, 0.6)',
                            'rgba(255, 159, 64, 0.6)',
                            'rgba(255, 99, 132, 0.6)',
                            'rgba(153, 102, 255, 0.6)',
                            'rgba(201, 203, 207, 0.6)',
                            'rgba(255, 99, 132, 0.6)',
                            'rgba(54, 162, 235, 0.6)',
                            'rgba(255, 206, 86, 0.6)'
                        ],
                        borderColor: [
                            'rgba(75, 192, 192, 1)',
                            'rgba(54, 162, 235, 1)',
                            'rgba(255, 206, 86, 1)',
                            'rgba(255, 159, 64, 1)',
                            'rgba(255, 99, 132, 1)',
                            'rgba(153, 102, 255, 1)',
                            'rgba(201, 203, 207, 1)',
                            'rgba(255, 99, 132, 1)',
                            'rgba(54, 162, 235, 1)',
                            'rgba(255, 206, 86, 1)'
                        ],
                        borderWidth: 1
                    }]
                };

                // Données pour le graphique des fonctions les plus complexes
                // Créer les données pour le graphique des fonctions les plus complexes
                const topFunctionsData = {
                    labels: [
$(
    $topFunctions = $Results | Sort-Object -Property Value -Descending | Select-Object -First 10
    $labels = foreach ($func in $topFunctions) {
        "'$($func.Function)'"
    }
    $labels -join ', '
)
                    ],
                    datasets: [{
                        label: 'Complexité cyclomatique',
                        data: [
$(
    $values = foreach ($func in $topFunctions) {
        "$($func.Value)"
    }
    $values -join ', '
)
                        ],
                        backgroundColor: 'rgba(255, 99, 132, 0.6)',
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: 1
                    }]
                };

                // Créer les graphiques
                document.addEventListener('DOMContentLoaded', function() {
                    // Graphique de distribution de complexité
                    const complexityCtx = document.getElementById('complexityDistributionChart').getContext('2d');
                    const complexityChart = new Chart(complexityCtx, {
                        type: 'bar',
                        data: complexityData,
                        options: {
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: 'top',
                                },
                                title: {
                                    display: true,
                                    text: 'Distribution de la complexité cyclomatique'
                                }
                            },
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    title: {
                                        display: true,
                                        text: 'Nombre de fonctions'
                                    }
                                },
                                x: {
                                    title: {
                                        display: true,
                                        text: 'Complexité cyclomatique'
                                    }
                                }
                            }
                        }
                    });

                    // Graphique des types de structures
                    const structureTypesCtx = document.getElementById('structureTypesChart').getContext('2d');
                    const structureTypesChart = new Chart(structureTypesCtx, {
                        type: 'pie',
                        data: structureTypesData,
                        options: {
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: 'right',
                                },
                                title: {
                                    display: true,
                                    text: 'Répartition des types de structures'
                                }
                            }
                        }
                    });

                    // Graphique des fonctions les plus complexes
                    const topFunctionsCtx = document.getElementById('topComplexFunctionsChart').getContext('2d');
                    const topFunctionsChart = new Chart(topFunctionsCtx, {
                        type: 'bar',
                        data: topFunctionsData,
                        options: {
                            indexAxis: 'y',
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: 'top',
                                },
                                title: {
                                    display: true,
                                    text: 'Top 10 des fonctions les plus complexes'
                                }
                            },
                            scales: {
                                x: {
                                    beginAtZero: true,
                                    title: {
                                        display: true,
                                        text: 'Complexité cyclomatique'
                                    }
                                },
                                y: {
                                    title: {
                                        display: true,
                                        text: 'Fonction'
                                    }
                                }
                            }
                        }
                    });
                });
                </script>
            </div>
        </div>

        <div class="footer">
            <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") avec PowerShellComplexityValidator</p>
        </div>
    </div>

    <script>
$script:DefaultJavaScript
$CustomJavaScript
    </script>
</body>
</html>
"@

    # Écrire le contenu dans le fichier de sortie
    $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8 -NoNewline

    Write-Verbose "Rapport HTML généré : $OutputPath"

    return $OutputPath
}

<#
.SYNOPSIS
    Génère un rapport HTML pour une fonction spécifique.
.DESCRIPTION
    Cette fonction génère un rapport HTML détaillé pour une fonction spécifique,
    mettant en évidence les structures de contrôle et leur impact sur la complexité.
.PARAMETER Result
    Résultat de l'analyse de complexité cyclomatique pour une fonction.
.PARAMETER SourceCode
    Code source de la fonction.
.PARAMETER OutputPath
    Chemin du fichier HTML de sortie.
.PARAMETER Title
    Titre du rapport.
.PARAMETER CustomCss
    Styles CSS personnalisés à ajouter au rapport.
.PARAMETER CustomJavaScript
    Scripts JavaScript personnalisés à ajouter au rapport.
.EXAMPLE
    New-FunctionComplexityReport -Result $result -SourceCode $sourceCode -OutputPath "function-report.html"
    Génère un rapport HTML détaillé pour la fonction spécifiée.
.OUTPUTS
    System.String
    Retourne le chemin du fichier HTML généré.
#>
function New-FunctionComplexityReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Result,

        [Parameter(Mandatory = $true)]
        [string]$SourceCode,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de complexité de fonction",

        [Parameter(Mandatory = $false)]
        [string]$CustomCss = "",

        [Parameter(Mandatory = $false)]
        [string]$CustomJavaScript = ""
    )

    # Échapper le code source pour l'affichage HTML
    $escapedSourceCode = ConvertTo-HtmlEscaped -Text $SourceCode

    # Générer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title - $($Result.Function)</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>
    <style>
$script:DefaultCssStyles
$CustomCss
    </style>
</head>
<body>
    <div class="container">
        <h1>$Title - $($Result.Function)</h1>

        <div class="summary-box">
            <h2>Résumé</h2>
            <p>Fonction: $($Result.Function)</p>
            <p>Type: $($Result.Type)</p>
            <p>Ligne: $($Result.Line)</p>
            <p>Complexité: $($Result.Value)</p>
            <p>Sévérité: $($Result.Severity)</p>
            <p>Message: $($Result.Message)</p>
        </div>

        <div class="nav-tabs">
            <li><a href="#tab-code" class="active">Code source</a></li>
            <li><a href="#tab-structures">Structures de contrôle</a></li>
            <li><a href="#tab-details">Détails de complexité</a></li>
            <li><a href="#tab-charts">Graphiques</a></li>
        </div>

        <div class="tab-content">
            <div id="tab-code" class="tab-pane active">
                <h2>Code source</h2>
                <div class="filter-controls">
                    <label for="structure-filter">Filtrer par type de structure : </label>
                    <select id="structure-filter">
                        <option value="all">Toutes les structures</option>
$(
    if ($Result.ControlStructures -and $Result.ControlStructures.Count -gt 0) {
        $uniqueTypes = $Result.ControlStructures | Select-Object -ExpandProperty Type -Unique | Sort-Object
        foreach ($type in $uniqueTypes) {
            "                        <option value=`"$type`">$type</option>"
        }
    }
)
                    </select>
                </div>

                <div class="color-legend">
                    <h3>Légende des impacts sur la complexité</h3>
                    <!-- La légende sera générée par JavaScript -->
                </div>

                <pre class="code-block">$(
    # Diviser le code source en lignes
    $lines = $escapedSourceCode -split "`n"

    # Créer un dictionnaire des structures par ligne
    $structuresByLine = @{}
    if ($Result.ControlStructures -and $Result.ControlStructures.Count -gt 0) {
        foreach ($structure in $Result.ControlStructures) {
            $line = $structure.Line
            if (-not $structuresByLine.ContainsKey($line)) {
                $structuresByLine[$line] = @()
            }
            $structuresByLine[$line] += $structure
        }
    }

    # Calculer les niveaux d'imbrication
    $nestingLevels = @{}
    $currentNestingLevel = 0
    $openingTypes = @("If", "ElseIf", "Else", "For", "ForEach", "While", "DoWhile", "Switch", "SwitchClause", "SwitchDefault", "Catch", "Try")
    $closingPattern = '^\s*}\s*$'

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNumber = $i + 1

        # Vérifier si cette ligne contient des structures d'ouverture
        if ($structuresByLine.ContainsKey($lineNumber)) {
            $structures = $structuresByLine[$lineNumber]
            foreach ($structure in $structures) {
                if ($structure.Type -in $openingTypes) {
                    $currentNestingLevel++
                }
            }
        }

        # Enregistrer le niveau d'imbrication pour cette ligne
        $nestingLevels[$lineNumber] = $currentNestingLevel

        # Vérifier si cette ligne contient une accolade fermante
        if ($lines[$i] -match $closingPattern) {
            $currentNestingLevel = [Math]::Max(0, $currentNestingLevel - 1)
        }
    }

    # Générer le HTML pour chaque ligne
    $lineHtml = for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNumber = $i + 1
        $line = $lines[$i]

        # Déterminer si cette ligne contient des structures de contrôle
        if ($structuresByLine.ContainsKey($lineNumber)) {
            $structures = $structuresByLine[$lineNumber]
            $nestingLevel = $nestingLevels[$lineNumber]

            # Créer des spans pour chaque structure
            foreach ($structure in $structures) {
                $impactClass = Get-StructureImpactClass -Type $structure.Type -NestingLevel $nestingLevel
                $tooltipText = "Type: $($structure.Type)`nLigne: $($structure.Line)`nColonne: $($structure.Column)`nNiveau d'imbrication: $nestingLevel"

                # Remplacer la structure par une version avec tooltip et coloration
                # Utiliser une approche plus robuste pour le remplacement
                try {
                    $escapedText = [regex]::Escape($structure.Text)
                    # Ajouter des limites de mot pour éviter les remplacements partiels
                    $pattern = "(?<!\w)$escapedText(?!\w)"
                    $replacement = "<span class=`"structure-highlight structure-tooltip $impactClass`" data-type=`"$($structure.Type)`"><span class=`"tooltip-text`">$tooltipText</span>$($structure.Text)</span>"

                    # Vérifier si le pattern existe dans la ligne
                    if ($line -match $pattern) {
                        $line = $line -replace $pattern, $replacement
                    }
                    else {
                        # Fallback au remplacement simple si le pattern avec limites de mot ne fonctionne pas
                        $simplePattern = [regex]::Escape($structure.Text)
                        $line = $line -replace $simplePattern, $replacement
                    }
                }
                catch {
                    # En cas d'erreur, utiliser une approche plus simple
                    Write-Verbose "Erreur lors du remplacement de la structure : $_"
                    # Simplement entourer la ligne entière
                    $line = "<span class=`"structure-highlight structure-tooltip $impactClass`" data-type=`"$($structure.Type)`"><span class=`"tooltip-text`">$tooltipText</span>$line</span>"
                }
            }
        }

        "<span class=`"line`">$line</span>"
    }

    $lineHtml -join "`n"
)</pre>
            </div>

            <div id="tab-structures" class="tab-pane">
                <h2>Structures de contrôle</h2>
                <table>
                    <thead>
                        <tr>
                            <th>Type</th>
                            <th>Ligne</th>
                            <th>Colonne</th>
                            <th>Impact</th>
                            <th>Texte</th>
                        </tr>
                    </thead>
                    <tbody>
$(
    if ($Result.ControlStructures -and $Result.ControlStructures.Count -gt 0) {
        $structureRows = foreach ($structure in $Result.ControlStructures) {
            $nestingLevel = $nestingLevels[$structure.Line]
            $impactClass = Get-StructureImpactClass -Type $structure.Type -NestingLevel $nestingLevel

            "<tr class=`"$impactClass`">
                <td>$($structure.Type)</td>
                <td>$($structure.Line)</td>
                <td>$($structure.Column)</td>
                <td>$impactClass</td>
                <td>$(ConvertTo-HtmlEscaped -Text $structure.Text)</td>
            </tr>"
        }
        $structureRows -join "`n"
    }
    else {
        "<tr><td colspan=`"5`">Aucune structure de contrôle détectée</td></tr>"
    }
)
                    </tbody>
                </table>
            </div>

            <div id="tab-details" class="tab-pane">
                <h2>Détails de complexité</h2>
$(
    if ($Result.ComplexityDetails) {
        "<h3>Score de base</h3>
        <p>$($Result.ComplexityDetails.BaseScore)</p>

        <h3>Structures détectées</h3>
        <table>
            <thead>
                <tr>
                    <th>Type</th>
                    <th>Nombre</th>
                    <th>Contribution</th>
                </tr>
            </thead>
            <tbody>"

        if ($Result.ComplexityDetails.StructureContributions.Count -gt 0) {
            $detailRows = foreach ($type in $Result.ComplexityDetails.StructureContributions.Keys) {
                $count = $Result.ComplexityDetails.StructureContributions[$type]
                $contribution = $Result.ComplexityDetails.WeightedStructures[$type]

                "<tr>
                    <td>$type</td>
                    <td>$count</td>
                    <td>$contribution</td>
                </tr>"
            }
            $detailRows -join "`n"
        }
        else {
            "<tr><td colspan=`"3`">Aucune structure détectée</td></tr>"
        }

        "</tbody>
        </table>

        <h3>Pénalité d'imbrication</h3>
        <p>$($Result.ComplexityDetails.NestingPenalty)</p>

        <h3>Score total</h3>
        <p>$($Result.ComplexityDetails.TotalScore)</p>"
    }
    else {
        "<p>Aucun détail de complexité disponible</p>"
    }
)
            </div>

            <div id="tab-charts" class="tab-pane">
                <h2>Graphiques</h2>

                <div class="chart-container">
                    <h3>Répartition des structures de contrôle</h3>
                    <canvas id="structureTypesChart"></canvas>
                </div>

                <div class="chart-container">
                    <h3>Impact des structures sur la complexité</h3>
                    <canvas id="structureImpactChart"></canvas>
                </div>

                <div class="chart-container">
                    <h3>Niveaux d'imbrication</h3>
                    <canvas id="nestingLevelsChart"></canvas>
                </div>

                <script>
                // Données pour les graphiques

                // Répartition des types de structures
                const structureTypes = {};
$(
    if ($Result.ControlStructures -and $Result.ControlStructures.Count -gt 0) {
        foreach ($structure in $Result.ControlStructures) {
            "                if (structureTypes['$($structure.Type)']) {
                    structureTypes['$($structure.Type)']++;
                } else {
                    structureTypes['$($structure.Type)'] = 1;
                }"
        }
    }
)

                const structureTypesData = {
                    labels: Object.keys(structureTypes),
                    datasets: [{
                        label: 'Nombre de structures',
                        data: Object.values(structureTypes),
                        backgroundColor: [
                            'rgba(75, 192, 192, 0.6)',
                            'rgba(54, 162, 235, 0.6)',
                            'rgba(255, 206, 86, 0.6)',
                            'rgba(255, 159, 64, 0.6)',
                            'rgba(255, 99, 132, 0.6)',
                            'rgba(153, 102, 255, 0.6)',
                            'rgba(201, 203, 207, 0.6)',
                            'rgba(255, 99, 132, 0.6)',
                            'rgba(54, 162, 235, 0.6)',
                            'rgba(255, 206, 86, 0.6)'
                        ],
                        borderColor: [
                            'rgba(75, 192, 192, 1)',
                            'rgba(54, 162, 235, 1)',
                            'rgba(255, 206, 86, 1)',
                            'rgba(255, 159, 64, 1)',
                            'rgba(255, 99, 132, 1)',
                            'rgba(153, 102, 255, 1)',
                            'rgba(201, 203, 207, 1)',
                            'rgba(255, 99, 132, 1)',
                            'rgba(54, 162, 235, 1)',
                            'rgba(255, 206, 86, 1)'
                        ],
                        borderWidth: 1
                    }]
                };

                // Impact des structures sur la complexité
                const impactCategories = {
                    'impact-none': 'Pas d\'impact',
                    'impact-low': 'Impact faible',
                    'impact-medium': 'Impact moyen',
                    'impact-high': 'Impact élevé',
                    'impact-critical': 'Impact critique'
                };

                const impactCounts = {
                    'impact-none': 0,
                    'impact-low': 0,
                    'impact-medium': 0,
                    'impact-high': 0,
                    'impact-critical': 0
                };

$(
    if ($Result.ControlStructures -and $Result.ControlStructures.Count -gt 0) {
        foreach ($structure in $Result.ControlStructures) {
            $nestingLevel = 0
            $impactClass = Get-StructureImpactClass -Type $structure.Type -NestingLevel $nestingLevel
            "                impactCounts['$impactClass']++;"
        }
    }
)

                const impactData = {
                    labels: Object.values(impactCategories),
                    datasets: [{
                        label: 'Nombre de structures',
                        data: [
                            impactCounts['impact-none'],
                            impactCounts['impact-low'],
                            impactCounts['impact-medium'],
                            impactCounts['impact-high'],
                            impactCounts['impact-critical']
                        ],
                        backgroundColor: [
                            'rgba(200, 200, 200, 0.6)',
                            'rgba(75, 192, 192, 0.6)',
                            'rgba(255, 206, 86, 0.6)',
                            'rgba(255, 159, 64, 0.6)',
                            'rgba(255, 99, 132, 0.6)'
                        ],
                        borderColor: [
                            'rgba(200, 200, 200, 1)',
                            'rgba(75, 192, 192, 1)',
                            'rgba(255, 206, 86, 1)',
                            'rgba(255, 159, 64, 1)',
                            'rgba(255, 99, 132, 1)'
                        ],
                        borderWidth: 1
                    }]
                };

                // Niveaux d'imbrication
                const nestingLevels = {};
$(
    if ($Result.ControlStructures -and $Result.ControlStructures.Count -gt 0) {
        # Calculer les niveaux d'imbrication
        $nestingLevels = @{}
        $currentNestingLevel = 0
        $openingTypes = @("If", "ElseIf", "Else", "For", "ForEach", "While", "DoWhile", "Switch", "SwitchClause", "SwitchDefault", "Catch", "Try")

        foreach ($structure in $Result.ControlStructures) {
            if ($structure.Type -in $openingTypes) {
                $currentNestingLevel++
            }

            $nestingLevels[$structure.Line] = $currentNestingLevel

            "                if (nestingLevels[$($currentNestingLevel)]) {
                    nestingLevels[$($currentNestingLevel)]++;
                } else {
                    nestingLevels[$($currentNestingLevel)] = 1;
                }"
        }
    }
)

                const nestingData = {
                    labels: Object.keys(nestingLevels),
                    datasets: [{
                        label: 'Nombre de structures',
                        data: Object.values(nestingLevels),
                        backgroundColor: 'rgba(54, 162, 235, 0.6)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    }]
                };

                // Créer les graphiques
                document.addEventListener('DOMContentLoaded', function() {
                    // Graphique des types de structures
                    const structureTypesCtx = document.getElementById('structureTypesChart').getContext('2d');
                    const structureTypesChart = new Chart(structureTypesCtx, {
                        type: 'pie',
                        data: structureTypesData,
                        options: {
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: 'right',
                                },
                                title: {
                                    display: true,
                                    text: 'Répartition des types de structures'
                                }
                            }
                        }
                    });

                    // Graphique de l'impact des structures
                    const impactCtx = document.getElementById('structureImpactChart').getContext('2d');
                    const impactChart = new Chart(impactCtx, {
                        type: 'bar',
                        data: impactData,
                        options: {
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: 'top',
                                },
                                title: {
                                    display: true,
                                    text: 'Impact des structures sur la complexité'
                                }
                            },
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    title: {
                                        display: true,
                                        text: 'Nombre de structures'
                                    }
                                },
                                x: {
                                    title: {
                                        display: true,
                                        text: 'Niveau d\'impact'
                                    }
                                }
                            }
                        }
                    });

                    // Graphique des niveaux d'imbrication
                    const nestingCtx = document.getElementById('nestingLevelsChart').getContext('2d');
                    const nestingChart = new Chart(nestingCtx, {
                        type: 'bar',
                        data: nestingData,
                        options: {
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: 'top',
                                },
                                title: {
                                    display: true,
                                    text: 'Niveaux d\'imbrication'
                                }
                            },
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    title: {
                                        display: true,
                                        text: 'Nombre de structures'
                                    }
                                },
                                x: {
                                    title: {
                                        display: true,
                                        text: 'Niveau d\'imbrication'
                                    }
                                }
                            }
                        }
                    });
                });
                </script>
            </div>
        </div>

        <div class="footer">
            <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") avec PowerShellComplexityValidator</p>
        </div>
    </div>

    <script>
$script:DefaultJavaScript
$CustomJavaScript
    </script>
</body>
</html>
"@

    # Écrire le contenu dans le fichier de sortie
    $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8 -NoNewline

    Write-Verbose "Rapport HTML de fonction généré : $OutputPath"

    return $OutputPath
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function New-ComplexityHtmlReport, New-FunctionComplexityReport
