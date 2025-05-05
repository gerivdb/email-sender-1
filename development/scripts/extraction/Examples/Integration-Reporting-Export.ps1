#Requires -Version 5.1
<#
.SYNOPSIS
Module pour l'exportation des rapports d'information extraite.

.DESCRIPTION
Ce module contient les fonctions pour exporter les rapports d'information extraite
dans différents formats (HTML, PDF, Excel, etc.).

.NOTES
Date de création : 2025-05-15
Auteur : Augment Code
Version : 1.0.0
#>

# Importer le module principal si nécessaire
# . "$PSScriptRoot\Integration-Reporting-Core.ps1"

<#
.SYNOPSIS
Exporte un rapport d'information extraite au format HTML.

.DESCRIPTION
La fonction Export-ExtractedInfoReportToHtml exporte un rapport d'information extraite
au format HTML. Elle génère un fichier HTML avec des styles CSS et du JavaScript pour
rendre le rapport interactif.

.PARAMETER Report
Le rapport à exporter.

.PARAMETER OutputPath
Le chemin du fichier de sortie.

.PARAMETER IncludeStyles
Indique si les styles CSS doivent être inclus dans le fichier HTML.

.PARAMETER IncludeScripts
Indique si les scripts JavaScript doivent être inclus dans le fichier HTML.

.PARAMETER Theme
Le thème à utiliser pour le rapport. Les valeurs possibles sont "Default", "Dark" et "Light".

.PARAMETER Title
Le titre à utiliser pour la page HTML. Par défaut, le titre du rapport est utilisé.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de texte"
$report = Add-ExtractedInfoReportTextSection -Report $report -Title "Introduction" -Text "Ce rapport présente une analyse détaillée..."
Export-ExtractedInfoReportToHtml -Report $report -OutputPath "C:\Temp\rapport.html"

.NOTES
Cette fonction génère un fichier HTML avec des styles CSS et du JavaScript pour
rendre le rapport interactif. Elle prend en charge les sections de texte, les tableaux
et les graphiques.
#>
function Export-ExtractedInfoReportToHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStyles,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeScripts,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Dark", "Light")]
        [string]$Theme = "Default",

        [Parameter(Mandatory = $false)]
        [string]$Title = ""
    )

    # Validation des paramètres
    if ($null -eq $Report -or -not $Report.ContainsKey("Metadata")) {
        throw "Le rapport fourni n'est pas valide."
    }

    # Utiliser le titre du rapport si aucun titre n'est spécifié
    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = $Report.Metadata.Title
    }

    # Créer le contenu HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
"@

    # Ajouter les styles CSS si demandé
    if ($IncludeStyles) {
        $css = Get-ExtractedInfoReportCss -Theme $Theme
        $html += @"
    <style>
$css
    </style>
"@
    }
    # Sinon, ajouter un lien vers une feuille de style externe
    else {
        $html += @"
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css">
"@
    }

    # Ajouter les scripts JavaScript si demandé
    if ($IncludeScripts) {
        $js = Get-ExtractedInfoReportJs
        $html += @"
    <script>
$js
    </script>
"@
    }
    # Sinon, ajouter des liens vers des scripts externes
    else {
        $html += @"
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
"@
    }

    $html += @"
</head>
<body class="report-body theme-$($Theme.ToLower())">
    <div class="container">
        <header class="report-header">
            <h1>$($Report.Metadata.Title)</h1>
            <p class="report-description">$($Report.Metadata.Description)</p>
            <div class="report-metadata">
                <p><strong>Auteur:</strong> $($Report.Metadata.Author)</p>
                <p><strong>Date:</strong> $($Report.Metadata.Date.ToString("dd/MM/yyyy"))</p>
                <p><strong>Type:</strong> $($Report.Metadata.Type)</p>
            </div>
        </header>

        <main class="report-content">
"@

    # Ajouter les sections du rapport
    foreach ($section in $Report.Sections) {
        $html += @"
            <section class="report-section level-$($section.Level)" id="section-$($section.Id)">
                <h$($section.Level) class="section-title">$($section.Number) $($section.Title)</h$($section.Level)>
"@

        # Ajouter le contenu selon le type de section
        switch ($section.Type) {
            "Text" {
                $html += @"
                <div class="section-content text-content">
                    <p>$($section.Content)</p>
                </div>
"@
            }
            "Table" {
                $html += @"
                <div class="section-content table-content">
                    <table class="table table-striped table-bordered table-hover">
                        <thead>
                            <tr>
"@
                # Ajouter les en-têtes du tableau
                if ($section.Headers) {
                    foreach ($header in $section.Headers) {
                        $html += @"
                                <th>$header</th>
"@
                    }
                }
                elseif ($section.Content.Headers) {
                    foreach ($header in $section.Content.Headers) {
                        $html += @"
                                <th>$header</th>
"@
                    }
                }
                $html += @"
                            </tr>
                        </thead>
                        <tbody>
"@
                # Ajouter les lignes du tableau
                $data = if ($section.Content.Data) { $section.Content.Data } else { $section.Content }
                foreach ($row in $data) {
                    $html += @"
                            <tr>
"@
                    if ($row -is [PSObject]) {
                        foreach ($prop in $row.PSObject.Properties) {
                            $html += @"
                                <td>$($prop.Value)</td>
"@
                        }
                    }
                    elseif ($row -is [hashtable]) {
                        foreach ($key in $row.Keys) {
                            $html += @"
                                <td>$($row[$key])</td>
"@
                        }
                    }
                    elseif ($row -is [array]) {
                        foreach ($cell in $row) {
                            $html += @"
                                <td>$cell</td>
"@
                        }
                    }
                    else {
                        $html += @"
                                <td>$row</td>
"@
                    }
                    $html += @"
                            </tr>
"@
                }
                $html += @"
                        </tbody>
                    </table>
                </div>
"@
            }
            "Chart" {
                $chartId = "chart-$($section.Id)"
                $chartType = if ($section.Content.ChartType) { $section.Content.ChartType } else { "Bar" }
                $html += @"
                <div class="section-content chart-content">
                    <canvas id="$chartId" width="800" height="400"></canvas>
                    <script>
                        document.addEventListener('DOMContentLoaded', function() {
                            var ctx = document.getElementById('$chartId').getContext('2d');
                            var chart = new Chart(ctx, {
                                type: '$(($chartType).ToLower())',
                                data: {
"@
                # Ajouter les données du graphique
                if ($section.Content.Labels) {
                    $labelsJson = $section.Content.Labels | ConvertTo-Json
                    $html += @"
                                    labels: $labelsJson,
"@
                }
                if ($section.Content.Values) {
                    $valuesJson = $section.Content.Values | ConvertTo-Json
                    $html += @"
                                    datasets: [{
                                        label: '$($section.Title)',
                                        data: $valuesJson,
                                        backgroundColor: [
                                            'rgba(78, 121, 167, 0.7)',
                                            'rgba(242, 142, 44, 0.7)',
                                            'rgba(225, 87, 89, 0.7)',
                                            'rgba(118, 183, 178, 0.7)',
                                            'rgba(89, 161, 79, 0.7)',
                                            'rgba(237, 201, 73, 0.7)',
                                            'rgba(175, 122, 161, 0.7)',
                                            'rgba(255, 157, 167, 0.7)',
                                            'rgba(156, 117, 95, 0.7)',
                                            'rgba(186, 176, 171, 0.7)'
                                        ],
                                        borderColor: [
                                            'rgba(78, 121, 167, 1)',
                                            'rgba(242, 142, 44, 1)',
                                            'rgba(225, 87, 89, 1)',
                                            'rgba(118, 183, 178, 1)',
                                            'rgba(89, 161, 79, 1)',
                                            'rgba(237, 201, 73, 1)',
                                            'rgba(175, 122, 161, 1)',
                                            'rgba(255, 157, 167, 1)',
                                            'rgba(156, 117, 95, 1)',
                                            'rgba(186, 176, 171, 1)'
                                        ],
                                        borderWidth: 1
                                    }]
"@
                }
                elseif ($section.Content.Series) {
                    $html += @"
                                    datasets: [
"@
                    $i = 0
                    foreach ($seriesName in $section.Content.Series.Keys) {
                        $seriesData = $section.Content.Series[$seriesName] | ConvertTo-Json
                        $color = $i % 10
                        $html += @"
                                        {
                                            label: '$seriesName',
                                            data: $seriesData,
                                            backgroundColor: 'rgba(78, 121, 167, 0.7)',
                                            borderColor: 'rgba(78, 121, 167, 1)',
                                            borderWidth: 1
                                        },
"@
                        $i++
                    }
                    $html = $html.TrimEnd(",`n")
                    $html += @"
                                    ]
"@
                }
                $html += @"
                                },
                                options: {
                                    responsive: true,
                                    plugins: {
                                        legend: {
                                            position: 'top',
                                        },
                                        title: {
                                            display: true,
                                            text: '$($section.Title)'
                                        }
                                    }
                                }
                            });
                        });
                    </script>
                </div>
"@
            }
            "List" {
                $html += @"
                <div class="section-content list-content">
                    <ul>
"@
                foreach ($item in $section.Content) {
                    $html += @"
                        <li>$item</li>
"@
                }
                $html += @"
                    </ul>
                </div>
"@
            }
            "Code" {
                $language = if ($section.Language) { $section.Language } else { "plaintext" }
                $html += @"
                <div class="section-content code-content">
                    <pre><code class="language-$language">$($section.Content)</code></pre>
                </div>
"@
            }
        }

        $html += @"
            </section>
"@
    }

    $html += @"
        </main>

        <footer class="report-footer">
            <p>Rapport généré le $($Report.Footer.GeneratedAt.ToString("dd/MM/yyyy HH:mm:ss"))</p>
        </footer>
    </div>
</body>
</html>
"@

    # Écrire le contenu HTML dans le fichier de sortie
    try {
        $html | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "Le rapport a été exporté avec succès vers $OutputPath"
    }
    catch {
        Write-Error "Erreur lors de l'exportation du rapport : $_"
    }
}

<#
.SYNOPSIS
Obtient le code CSS pour les rapports d'information extraite.

.DESCRIPTION
La fonction Get-ExtractedInfoReportCss retourne le code CSS utilisé pour styliser
les rapports d'information extraite au format HTML.

.PARAMETER Theme
Le thème à utiliser pour le rapport. Les valeurs possibles sont "Default", "Dark" et "Light".

.EXAMPLE
$css = Get-ExtractedInfoReportCss -Theme "Dark"

.NOTES
Cette fonction est utilisée en interne par Export-ExtractedInfoReportToHtml.
#>
function Get-ExtractedInfoReportCss {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Dark", "Light")]
        [string]$Theme = "Default"
    )

    # Définir les couleurs selon le thème
    $colors = @{}
    switch ($Theme) {
        "Dark" {
            $colors["background"] = "#1e1e1e"
            $colors["text"] = "#f0f0f0"
            $colors["header"] = "#2d2d2d"
            $colors["border"] = "#444444"
            $colors["link"] = "#61afef"
            $colors["hover"] = "#c678dd"
        }
        "Light" {
            $colors["background"] = "#ffffff"
            $colors["text"] = "#333333"
            $colors["header"] = "#f8f9fa"
            $colors["border"] = "#dee2e6"
            $colors["link"] = "#007bff"
            $colors["hover"] = "#0056b3"
        }
        default {
            $colors["background"] = "#f8f9fa"
            $colors["text"] = "#212529"
            $colors["header"] = "#e9ecef"
            $colors["border"] = "#ced4da"
            $colors["link"] = "#007bff"
            $colors["hover"] = "#0056b3"
        }
    }

    # Retourner le code CSS
    return @"
/* Styles généraux */
.report-body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: $($colors["text"]);
    background-color: $($colors["background"]);
    margin: 0;
    padding: 20px;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    background-color: $($colors["background"]);
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
    border-radius: 5px;
}

/* En-tête du rapport */
.report-header {
    margin-bottom: 30px;
    padding-bottom: 20px;
    border-bottom: 1px solid $($colors["border"]);
}

.report-header h1 {
    font-size: 2.5rem;
    margin-bottom: 10px;
    color: $($colors["text"]);
}

.report-description {
    font-size: 1.2rem;
    margin-bottom: 20px;
    color: $($colors["text"]);
    opacity: 0.8;
}

.report-metadata {
    display: flex;
    flex-wrap: wrap;
    gap: 20px;
    font-size: 0.9rem;
    color: $($colors["text"]);
    opacity: 0.7;
}

/* Sections du rapport */
.report-section {
    margin-bottom: 30px;
    padding: 20px;
    background-color: $($colors["header"]);
    border-radius: 5px;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);
}

.section-title {
    margin-top: 0;
    margin-bottom: 20px;
    color: $($colors["text"]);
    border-bottom: 1px solid $($colors["border"]);
    padding-bottom: 10px;
}

.section-content {
    margin-bottom: 20px;
}

/* Niveaux de section */
.level-1 .section-title {
    font-size: 2rem;
}

.level-2 .section-title {
    font-size: 1.75rem;
}

.level-3 .section-title {
    font-size: 1.5rem;
}

.level-4 .section-title {
    font-size: 1.25rem;
}

/* Contenu textuel */
.text-content p {
    margin-bottom: 15px;
    text-align: justify;
}

/* Tableaux */
.table-content table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
}

.table-content th,
.table-content td {
    padding: 12px 15px;
    text-align: left;
    border: 1px solid $($colors["border"]);
}

.table-content th {
    background-color: $($colors["header"]);
    font-weight: bold;
}

.table-content tr:nth-child(even) {
    background-color: rgba(0, 0, 0, 0.05);
}

.table-content tr:hover {
    background-color: rgba(0, 0, 0, 0.1);
}

/* Listes */
.list-content ul,
.list-content ol {
    margin-left: 20px;
    margin-bottom: 20px;
}

.list-content li {
    margin-bottom: 5px;
}

/* Code */
.code-content pre {
    background-color: #282c34;
    color: #abb2bf;
    padding: 15px;
    border-radius: 5px;
    overflow-x: auto;
    font-family: 'Consolas', 'Monaco', monospace;
    font-size: 0.9rem;
    line-height: 1.4;
}

/* Pied de page */
.report-footer {
    margin-top: 50px;
    padding-top: 20px;
    border-top: 1px solid $($colors["border"]);
    text-align: center;
    font-size: 0.9rem;
    color: $($colors["text"]);
    opacity: 0.7;
}

/* Responsive */
@media (max-width: 768px) {
    .container {
        padding: 10px;
    }
    
    .report-header h1 {
        font-size: 2rem;
    }
    
    .report-section {
        padding: 15px;
    }
    
    .level-1 .section-title {
        font-size: 1.75rem;
    }
    
    .level-2 .section-title {
        font-size: 1.5rem;
    }
    
    .level-3 .section-title {
        font-size: 1.25rem;
    }
    
    .level-4 .section-title {
        font-size: 1.1rem;
    }
}
"@
}

<#
.SYNOPSIS
Obtient le code JavaScript pour les rapports d'information extraite.

.DESCRIPTION
La fonction Get-ExtractedInfoReportJs retourne le code JavaScript utilisé pour
rendre les rapports d'information extraite interactifs au format HTML.

.EXAMPLE
$js = Get-ExtractedInfoReportJs

.NOTES
Cette fonction est utilisée en interne par Export-ExtractedInfoReportToHtml.
#>
function Get-ExtractedInfoReportJs {
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    # Retourner le code JavaScript
    return @"
// Fonction pour initialiser les tableaux interactifs
function initTables() {
    const tables = document.querySelectorAll('.table');
    tables.forEach(table => {
        // Ajouter la classe table-responsive si elle n'existe pas déjà
        if (!table.parentElement.classList.contains('table-responsive')) {
            const wrapper = document.createElement('div');
            wrapper.classList.add('table-responsive');
            table.parentNode.insertBefore(wrapper, table);
            wrapper.appendChild(table);
        }
    });
}

// Fonction pour initialiser la navigation
function initNavigation() {
    // Créer la table des matières
    const toc = document.createElement('div');
    toc.classList.add('report-toc');
    toc.innerHTML = '<h2>Table des matières</h2><ul></ul>';
    
    const tocList = toc.querySelector('ul');
    const sections = document.querySelectorAll('.report-section');
    
    sections.forEach(section => {
        const title = section.querySelector('.section-title');
        const id = section.id;
        const level = section.classList.contains('level-1') ? 1 :
                     section.classList.contains('level-2') ? 2 :
                     section.classList.contains('level-3') ? 3 : 4;
        
        const listItem = document.createElement('li');
        listItem.classList.add(`toc-level-${level}`);
        listItem.innerHTML = `<a href="#${id}">${title.textContent}</a>`;
        
        tocList.appendChild(listItem);
    });
    
    // Insérer la table des matières après l'en-tête
    const header = document.querySelector('.report-header');
    header.parentNode.insertBefore(toc, header.nextSibling);
    
    // Ajouter des styles pour la table des matières
    const style = document.createElement('style');
    style.textContent = `
        .report-toc {
            margin-bottom: 30px;
            padding: 20px;
            background-color: rgba(0, 0, 0, 0.05);
            border-radius: 5px;
        }
        
        .report-toc h2 {
            margin-top: 0;
            margin-bottom: 15px;
        }
        
        .report-toc ul {
            list-style-type: none;
            padding-left: 0;
        }
        
        .toc-level-1 {
            margin-bottom: 10px;
        }
        
        .toc-level-2 {
            margin-left: 20px;
            margin-bottom: 5px;
        }
        
        .toc-level-3 {
            margin-left: 40px;
            margin-bottom: 5px;
        }
        
        .toc-level-4 {
            margin-left: 60px;
            margin-bottom: 5px;
        }
    `;
    document.head.appendChild(style);
}

// Initialiser les fonctionnalités lorsque le DOM est chargé
document.addEventListener('DOMContentLoaded', function() {
    initTables();
    initNavigation();
});
"@
}

# Exporter les fonctions
Export-ModuleMember -Function Export-ExtractedInfoReportToHtml, Get-ExtractedInfoReportCss, Get-ExtractedInfoReportJs
