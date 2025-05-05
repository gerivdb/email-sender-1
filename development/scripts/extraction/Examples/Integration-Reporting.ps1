#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'intégration du module ExtractedInfoModuleV2 avec un système de reporting.

.DESCRIPTION
Ce script montre comment intégrer le module ExtractedInfoModuleV2 avec un système de reporting
pour générer des rapports détaillés à partir des informations extraites. Il permet de créer
des rapports avec des sections textuelles, des tableaux et des graphiques, et de les exporter
dans différents formats (HTML, PDF, Excel).

Les fonctionnalités principales incluent :
- Création de rapports structurés à partir d'informations extraites
- Ajout de sections textuelles, tableaux et graphiques
- Exportation dans différents formats (HTML, PDF, Excel)
- Personnalisation de l'apparence et du contenu des rapports

.NOTES
Date de création : 2025-05-15
Auteur : Augment Code
Version : 1.0.0
#>

# Importer les modules nécessaires
# Import-Module ExtractedInfoModuleV2

# Modules optionnels pour l'exportation avancée
# Note: Ces modules sont optionnels mais recommandés pour les fonctionnalités avancées
# Import-Module PSWriteHTML -ErrorAction SilentlyContinue # Pour l'exportation HTML avancée
# Import-Module ImportExcel -ErrorAction SilentlyContinue # Pour l'exportation Excel avancée

#region Constantes et variables globales

# Types de rapport
$REPORT_TYPES = @{
    Standard  = "Standard"       # Rapport standard avec sections textuelles et tableaux
    Dashboard = "Dashboard"     # Rapport de type tableau de bord avec graphiques
    Executive = "Executive"     # Rapport exécutif avec résumé et points clés
    Technical = "Technical"     # Rapport technique avec détails avancés
}

# Types de section
$SECTION_TYPES = @{
    Text  = "Text"               # Section textuelle (paragraphes)
    Table = "Table"             # Section tabulaire (tableau de données)
    Chart = "Chart"             # Section graphique
    List  = "List"               # Section liste (à puces ou numérotée)
    Code  = "Code"               # Section code (avec coloration syntaxique)
}

# Types de graphique
$CHART_TYPES = @{
    Bar       = "Bar"                 # Graphique en barres
    Line      = "Line"               # Graphique en lignes
    Pie       = "Pie"                 # Graphique en camembert
    Scatter   = "Scatter"         # Nuage de points
    Area      = "Area"               # Graphique en aires
    Histogram = "Histogram"     # Histogramme
}

# Formats d'exportation
$EXPORT_FORMATS = @{
    HTML     = "HTML"               # Format HTML
    PDF      = "PDF"                 # Format PDF
    Excel    = "Excel"             # Format Excel
    Markdown = "Markdown"       # Format Markdown
    Text     = "Text"               # Format texte brut
}

#endregion

#region Fonctions de base pour la génération de rapports

<#
.SYNOPSIS
Crée un nouveau rapport d'information extraite.

.DESCRIPTION
La fonction New-ExtractedInfoReport crée un nouveau rapport d'information extraite
avec une structure de base comprenant un en-tête, un corps et un pied de page.

.PARAMETER Title
Le titre du rapport.

.PARAMETER Description
La description du rapport.

.PARAMETER Author
L'auteur du rapport.

.PARAMETER Date
La date du rapport. Par défaut, la date actuelle.

.PARAMETER Type
Le type de rapport. Les valeurs possibles sont définies dans $REPORT_TYPES.
Par défaut, "Standard".

.PARAMETER Tags
Les tags associés au rapport.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de texte" -Description "Analyse détaillée du texte extrait" -Author "John Doe"

.NOTES
Cette fonction crée la structure de base du rapport, qui peut ensuite être enrichie
avec des sections, des tableaux et des graphiques.
#>
function New-ExtractedInfoReport {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Title,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [string]$Author = "",

        [Parameter(Mandatory = $false)]
        [DateTime]$Date = (Get-Date),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Standard", "Dashboard", "Executive", "Technical")]
        [string]$Type = "Standard",

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @()
    )

    # Validation des paramètres
    if ([string]::IsNullOrWhiteSpace($Title)) {
        throw "Le titre du rapport ne peut pas être vide."
    }

    if (-not $REPORT_TYPES.ContainsKey($Type) -and -not $REPORT_TYPES.ContainsValue($Type)) {
        throw "Type de rapport non valide : $Type. Les types valides sont : $($REPORT_TYPES.Keys -join ', ')"
    }

    # Générer un ID unique pour le rapport
    $reportId = [guid]::NewGuid().ToString()

    # Créer la structure du rapport
    $report = @{
        # Métadonnées du rapport
        Metadata        = @{
            Id          = $reportId
            Title       = $Title
            Description = $Description
            Author      = $Author
            Date        = $Date
            Type        = $Type
            Tags        = $Tags
            CreatedAt   = Get-Date
            Version     = "1.0.0"
        }

        # Structure du rapport
        Header          = @{
            Title       = $Title
            Description = $Description
            Author      = $Author
            Date        = $Date
            Type        = $Type
        }

        # Corps du rapport (sections)
        Sections        = @()

        # Pied de page
        Footer          = @{
            GeneratedAt = Get-Date
            PageCount   = 1
        }

        # Compteurs pour la numérotation des sections
        SectionCounters = @{
            Level1 = 0
            Level2 = 0
            Level3 = 0
            Level4 = 0
        }
    }

    return $report
}

<#
.SYNOPSIS
Ajoute une section à un rapport d'information extraite.

.DESCRIPTION
La fonction Add-ExtractedInfoReportSection ajoute une section à un rapport d'information extraite.
Les sections peuvent être de différents types : texte, tableau, etc.

.PARAMETER Report
Le rapport auquel ajouter la section.

.PARAMETER Title
Le titre de la section.

.PARAMETER Content
Le contenu de la section. Peut être une chaîne de caractères, un tableau ou un objet.

.PARAMETER Type
Le type de section. Les valeurs possibles sont définies dans $SECTION_TYPES.
Par défaut, "Text".

.PARAMETER Level
Le niveau de la section (1 à 4). Utilisé pour la numérotation hiérarchique.
Par défaut, 1.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de texte"
$report = Add-ExtractedInfoReportSection -Report $report -Title "Introduction" -Content "Ce rapport présente une analyse détaillée..." -Type "Text" -Level 1

.NOTES
Cette fonction prend en charge différents types de sections et gère automatiquement
la numérotation hiérarchique des sections.
#>
function Add-ExtractedInfoReportSection {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Title,

        [Parameter(Mandatory = $true, Position = 2)]
        [object]$Content,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "Table", "Chart", "List", "Code")]
        [string]$Type = "Text",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 4)]
        [int]$Level = 1
    )

    # Validation des paramètres
    if ($null -eq $Report -or -not $Report.ContainsKey("Sections")) {
        throw "Le rapport fourni n'est pas valide."
    }

    if ([string]::IsNullOrWhiteSpace($Title)) {
        throw "Le titre de la section ne peut pas être vide."
    }

    if ($null -eq $Content) {
        throw "Le contenu de la section ne peut pas être null."
    }

    if (-not $SECTION_TYPES.ContainsKey($Type) -and -not $SECTION_TYPES.ContainsValue($Type)) {
        throw "Type de section non valide : $Type. Les types valides sont : $($SECTION_TYPES.Keys -join ', ')"
    }

    # Mettre à jour les compteurs de section
    switch ($Level) {
        1 {
            $Report.SectionCounters.Level1++
            $Report.SectionCounters.Level2 = 0
            $Report.SectionCounters.Level3 = 0
            $Report.SectionCounters.Level4 = 0
            $sectionNumber = "$($Report.SectionCounters.Level1)"
        }
        2 {
            $Report.SectionCounters.Level2++
            $Report.SectionCounters.Level3 = 0
            $Report.SectionCounters.Level4 = 0
            $sectionNumber = "$($Report.SectionCounters.Level1).$($Report.SectionCounters.Level2)"
        }
        3 {
            $Report.SectionCounters.Level3++
            $Report.SectionCounters.Level4 = 0
            $sectionNumber = "$($Report.SectionCounters.Level1).$($Report.SectionCounters.Level2).$($Report.SectionCounters.Level3)"
        }
        4 {
            $Report.SectionCounters.Level4++
            $sectionNumber = "$($Report.SectionCounters.Level1).$($Report.SectionCounters.Level2).$($Report.SectionCounters.Level3).$($Report.SectionCounters.Level4)"
        }
    }

    # Créer la section
    $section = @{
        Id        = [guid]::NewGuid().ToString()
        Number    = $sectionNumber
        Title     = $Title
        Content   = $Content
        Type      = $Type
        Level     = $Level
        CreatedAt = Get-Date
    }

    # Traitement spécifique selon le type de section
    switch ($Type) {
        "Text" {
            # Aucun traitement spécifique pour le texte
        }
        "Table" {
            # Vérifier que le contenu est un tableau
            if (-not ($Content -is [array] -or $Content -is [System.Collections.IEnumerable])) {
                throw "Le contenu d'une section de type Table doit être un tableau ou une collection."
            }

            # Extraire les en-têtes de colonnes si possible
            if ($Content.Count -gt 0 -and $Content[0] -is [PSObject]) {
                $section["Headers"] = $Content[0].PSObject.Properties.Name
            }
        }
        "Chart" {
            # Vérifier que le contenu est un objet avec des données pour un graphique
            if (-not ($Content -is [hashtable] -or $Content -is [PSObject])) {
                throw "Le contenu d'une section de type Chart doit être un objet ou une hashtable."
            }

            # Vérifier que le contenu a les propriétés requises
            if (-not ($Content.ContainsKey("ChartType") -or $Content.PSObject.Properties.Name -contains "ChartType")) {
                throw "Le contenu d'une section de type Chart doit contenir une propriété ChartType."
            }

            if (-not ($Content.ContainsKey("Data") -or $Content.PSObject.Properties.Name -contains "Data")) {
                throw "Le contenu d'une section de type Chart doit contenir une propriété Data."
            }
        }
        "List" {
            # Vérifier que le contenu est un tableau
            if (-not ($Content -is [array] -or $Content -is [System.Collections.IEnumerable])) {
                throw "Le contenu d'une section de type List doit être un tableau ou une collection."
            }
        }
        "Code" {
            # Vérifier que le contenu est une chaîne de caractères
            if (-not ($Content -is [string])) {
                throw "Le contenu d'une section de type Code doit être une chaîne de caractères."
            }

            # Ajouter la langue du code si spécifiée
            if ($PSBoundParameters.ContainsKey("Language")) {
                $section["Language"] = $PSBoundParameters["Language"]
            }
        }
    }

    # Ajouter la section au rapport
    $Report.Sections += $section

    return $Report
}

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
        [hashtable]$Options = @{}
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
        "Area" {
            # Configuration spécifique pour les graphiques en aires
            if (-not $Options.ContainsKey("Stacked")) {
                $chartData.Options["Stacked"] = $false
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
        "Histogram" {
            # Configuration spécifique pour les histogrammes
            if (-not $Options.ContainsKey("BinCount")) {
                $chartData.Options["BinCount"] = 10
            }

            # Extraire les valeurs si les données sont un tableau d'objets
            if ($Data -is [array]) {
                if ($Data[0] -is [hashtable] -or $Data[0] -is [PSObject]) {
                    $chartData["Values"] = @()

                    # Déterminer la propriété à utiliser comme valeur
                    $valueProperty = if ($Options.ContainsKey("ValueProperty")) { $Options.ValueProperty } else { $Data[0].PSObject.Properties.Name[0] }

                    foreach ($item in $Data) {
                        $chartData["Values"] += $item.$valueProperty
                    }
                } else {
                    # Si les données sont un simple tableau de valeurs
                    $chartData["Values"] = $Data
                }

                # Calculer les bins pour l'histogramme
                if (-not $Options.ContainsKey("SkipBinCalculation") -or -not $Options.SkipBinCalculation) {
                    $values = $chartData["Values"]
                    $min = ($values | Measure-Object -Minimum).Minimum
                    $max = ($values | Measure-Object -Maximum).Maximum
                    $binCount = $chartData.Options["BinCount"]
                    $binWidth = ($max - $min) / $binCount

                    $bins = @()
                    $binCounts = @(0) * $binCount

                    for ($i = 0; $i -lt $binCount; $i++) {
                        $binStart = $min + ($i * $binWidth)
                        $binEnd = $binStart + $binWidth
                        $bins += "$binStart - $binEnd"

                        foreach ($value in $values) {
                            if ($value -ge $binStart -and ($value -lt $binEnd -or ($i -eq $binCount - 1 -and $value -eq $binEnd))) {
                                $binCounts[$i]++
                            }
                        }
                    }

                    $chartData["Bins"] = $bins
                    $chartData["BinCounts"] = $binCounts
                }
            }
        }
    }

    # Créer une section de type Chart avec les données du graphique
    return Add-ExtractedInfoReportSection -Report $Report -Title $Title -Content $chartData -Type "Chart" -Level 1
}

#region Fonctions d'exportation de rapports

<#
.SYNOPSIS
Exporte un rapport d'information extraite au format HTML.

.DESCRIPTION
La fonction Export-ExtractedInfoReportToHtml exporte un rapport d'information extraite
au format HTML. Elle génère un fichier HTML complet avec des styles CSS et du JavaScript
pour les graphiques interactifs.

.PARAMETER Report
Le rapport à exporter.

.PARAMETER OutputPath
Le chemin du fichier de sortie.

.PARAMETER IncludeStyles
Indique si les styles CSS doivent être inclus dans le fichier HTML.
Par défaut, $true.

.PARAMETER IncludeScripts
Indique si les scripts JavaScript doivent être inclus dans le fichier HTML.
Par défaut, $true.

.PARAMETER Theme
Le thème à utiliser pour le rapport. Les valeurs possibles sont "Default", "Dark", "Light".
Par défaut, "Default".

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de données"
$report = Add-ExtractedInfoReportSection -Report $report -Title "Introduction" -Content "Ce rapport présente une analyse détaillée..." -Type "Text"
Export-ExtractedInfoReportToHtml -Report $report -OutputPath "C:\Temp\rapport.html"

.NOTES
Cette fonction utilise Chart.js pour les graphiques interactifs.
#>
function Export-ExtractedInfoReportToHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStyles = $true,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeScripts = $true,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Dark", "Light")]
        [string]$Theme = "Default"
    )

    # Validation des paramètres
    if ($null -eq $Report -or -not $Report.ContainsKey("Metadata")) {
        throw "Le rapport fourni n'est pas valide."
    }

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        throw "Le chemin de sortie ne peut pas être vide."
    }

    # Créer le dossier de sortie s'il n'existe pas
    $outputFolder = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputFolder) -and -not (Test-Path -Path $outputFolder)) {
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    }

    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($Report.Metadata.Title)</title>
"@

    # Ajouter les styles CSS
    if ($IncludeStyles) {
        $css = @"
    <style>
        /* Styles de base */
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f8f8f8;
        }

        /* Styles spécifiques au thème */
"@

        # Ajouter les styles spécifiques au thème
        switch ($Theme) {
            "Dark" {
                $css += @"
        body {
            color: #eee;
            background-color: #222;
        }
        h1, h2, h3, h4, h5, h6 {
            color: #fff;
        }
        a {
            color: #4da6ff;
        }
        table {
            border-color: #444;
        }
        th {
            background-color: #333;
            color: #fff;
        }
        tr:nth-child(even) {
            background-color: #2a2a2a;
        }
        tr:hover {
            background-color: #383838;
        }
        .report-header, .report-footer {
            background-color: #333;
            color: #fff;
        }
        .chart-container {
            background-color: #2a2a2a;
            border-color: #444;
        }
"@
            }
            "Light" {
                $css += @"
        body {
            color: #333;
            background-color: #fff;
        }
        h1, h2, h3, h4, h5, h6 {
            color: #222;
        }
        a {
            color: #0066cc;
        }
        table {
            border-color: #ddd;
        }
        th {
            background-color: #f2f2f2;
            color: #333;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        tr:hover {
            background-color: #f2f2f2;
        }
        .report-header, .report-footer {
            background-color: #f2f2f2;
            color: #333;
        }
        .chart-container {
            background-color: #fff;
            border-color: #ddd;
        }
"@
            }
            default {
                $css += @"
        body {
            color: #333;
            background-color: #f8f8f8;
        }
        h1, h2, h3, h4, h5, h6 {
            color: #222;
        }
        a {
            color: #0066cc;
        }
        table {
            border-color: #ddd;
        }
        th {
            background-color: #f2f2f2;
            color: #333;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        tr:hover {
            background-color: #f2f2f2;
        }
        .report-header, .report-footer {
            background-color: #f2f2f2;
            color: #333;
        }
        .chart-container {
            background-color: #fff;
            border-color: #ddd;
        }
"@
            }
        }

        # Ajouter les styles communs
        $css += @"

        /* En-tête et pied de page */
        .report-header, .report-footer {
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 5px;
        }

        .report-header h1 {
            margin-top: 0;
        }

        .report-footer {
            margin-top: 20px;
            font-size: 0.9em;
            text-align: center;
        }

        /* Sections */
        .report-section {
            margin-bottom: 30px;
            padding: 20px;
            background-color: #fff;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }

        .report-section h2 {
            margin-top: 0;
            border-bottom: 1px solid #ddd;
            padding-bottom: 10px;
        }

        /* Tableaux */
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }

        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }

        th {
            font-weight: bold;
        }

        /* Graphiques */
        .chart-container {
            margin: 20px 0;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
        }

        /* Listes */
        ul, ol {
            margin-left: 20px;
        }

        /* Code */
        pre {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            font-family: monospace;
        }

        /* Responsive */
        @media (max-width: 768px) {
            body {
                padding: 10px;
            }

            .report-section {
                padding: 15px;
            }

            table {
                display: block;
                overflow-x: auto;
            }
        }
    </style>
"@

        $html += $css
    }

    # Ajouter les scripts JavaScript
    if ($IncludeScripts) {
        $html += @"
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
    <script>
        // Fonction pour initialiser les graphiques
        function initCharts() {
            const chartContainers = document.querySelectorAll('.chart-container');
            chartContainers.forEach((container, index) => {
                const canvas = container.querySelector('canvas');
                const chartType = container.getAttribute('data-chart-type');
                const chartData = JSON.parse(container.getAttribute('data-chart-data'));
                const chartOptions = JSON.parse(container.getAttribute('data-chart-options'));

                if (canvas && chartType && chartData) {
                    createChart(canvas, chartType, chartData, chartOptions);
                }
            });
        }

        // Fonction pour créer un graphique
        function createChart(canvas, chartType, data, options) {
            const ctx = canvas.getContext('2d');
            let chartConfig = {
                type: chartType.toLowerCase(),
                options: options || {}
            };

            // Configuration spécifique selon le type de graphique
            switch (chartType.toLowerCase()) {
                case 'bar':
                    chartConfig.data = {
                        labels: data.labels || [],
                        datasets: [{
                            label: 'Valeurs',
                            data: data.values || [],
                            backgroundColor: options.colors || [
                                '#4e79a7', '#f28e2c', '#e15759', '#76b7b2', '#59a14f',
                                '#edc949', '#af7aa1', '#ff9da7', '#9c755f', '#bab0ab'
                            ]
                        }]
                    };
                    break;
                case 'line':
                    chartConfig.data = {
                        labels: data.labels || [],
                        datasets: []
                    };

                    if (data.series) {
                        let colorIndex = 0;
                        const colors = options.colors || [
                            '#4e79a7', '#f28e2c', '#e15759', '#76b7b2', '#59a14f',
                            '#edc949', '#af7aa1', '#ff9da7', '#9c755f', '#bab0ab'
                        ];

                        for (const [key, values] of Object.entries(data.series)) {
                            chartConfig.data.datasets.push({
                                label: key,
                                data: values,
                                borderColor: colors[colorIndex % colors.length],
                                backgroundColor: colors[colorIndex % colors.length] + '33',
                                tension: options.smooth ? 0.4 : 0
                            });
                            colorIndex++;
                        }
                    } else {
                        chartConfig.data.datasets.push({
                            label: 'Valeurs',
                            data: data.values || [],
                            borderColor: options.colors ? options.colors[0] : '#4e79a7',
                            backgroundColor: (options.colors ? options.colors[0] : '#4e79a7') + '33',
                            tension: options.smooth ? 0.4 : 0
                        });
                    }
                    break;
                case 'pie':
                    chartConfig.data = {
                        labels: data.labels || [],
                        datasets: [{
                            data: data.values || [],
                            backgroundColor: options.colors || [
                                '#4e79a7', '#f28e2c', '#e15759', '#76b7b2', '#59a14f',
                                '#edc949', '#af7aa1', '#ff9da7', '#9c755f', '#bab0ab'
                            ]
                        }]
                    };

                    if (options.donut) {
                        chartConfig.options.cutout = '50%';
                    }
                    break;
                case 'scatter':
                    chartConfig.data = {
                        datasets: [{
                            label: 'Points',
                            data: data.points || [],
                            backgroundColor: options.colors ? options.colors[0] : '#4e79a7'
                        }]
                    };

                    chartConfig.options.scales = {
                        x: {
                            type: 'linear',
                            position: 'bottom'
                        }
                    };
                    break;
                case 'area':
                    chartConfig.type = 'line';
                    chartConfig.data = {
                        labels: data.labels || [],
                        datasets: []
                    };

                    if (data.series) {
                        let colorIndex = 0;
                        const colors = options.colors || [
                            '#4e79a7', '#f28e2c', '#e15759', '#76b7b2', '#59a14f',
                            '#edc949', '#af7aa1', '#ff9da7', '#9c755f', '#bab0ab'
                        ];

                        for (const [key, values] of Object.entries(data.series)) {
                            chartConfig.data.datasets.push({
                                label: key,
                                data: values,
                                borderColor: colors[colorIndex % colors.length],
                                backgroundColor: colors[colorIndex % colors.length] + '80',
                                fill: true,
                                tension: 0.4
                            });
                            colorIndex++;
                        }
                    } else {
                        chartConfig.data.datasets.push({
                            label: 'Valeurs',
                            data: data.values || [],
                            borderColor: options.colors ? options.colors[0] : '#4e79a7',
                            backgroundColor: (options.colors ? options.colors[0] : '#4e79a7') + '80',
                            fill: true,
                            tension: 0.4
                        });
                    }

                    if (options.stacked) {
                        chartConfig.options.scales = {
                            y: {
                                stacked: true
                            }
                        };
                    }
                    break;
                case 'histogram':
                    chartConfig.type = 'bar';
                    chartConfig.data = {
                        labels: data.bins || [],
                        datasets: [{
                            label: 'Fréquence',
                            data: data.binCounts || [],
                            backgroundColor: options.colors ? options.colors[0] : '#4e79a7'
                        }]
                    };
                    break;
            }

            new Chart(ctx, chartConfig);
        }

        // Initialiser les graphiques au chargement de la page
        document.addEventListener('DOMContentLoaded', initCharts);

        // Fonction pour trier les tableaux
        function sortTable(tableId, columnIndex) {
            const table = document.getElementById(tableId);
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('tr'));
            const direction = table.getAttribute('data-sort-direction') === 'asc' ? -1 : 1;

            rows.sort((a, b) => {
                const aValue = a.cells[columnIndex].textContent.trim();
                const bValue = b.cells[columnIndex].textContent.trim();

                // Essayer de convertir en nombre si possible
                const aNum = parseFloat(aValue);
                const bNum = parseFloat(bValue);

                if (!isNaN(aNum) && !isNaN(bNum)) {
                    return direction * (aNum - bNum);
                }

                return direction * aValue.localeCompare(bValue);
            });

            // Mettre à jour la direction pour le prochain clic
            table.setAttribute('data-sort-direction', direction === 1 ? 'asc' : 'desc');

            // Réorganiser les lignes
            rows.forEach(row => tbody.appendChild(row));
        }
    </script>
"@
    }

    $html += @"
</head>
<body>
    <div class="report-header">
        <h1>$($Report.Metadata.Title)</h1>
        <p>$($Report.Metadata.Description)</p>
        <p><strong>Auteur :</strong> $($Report.Metadata.Author)</p>
        <p><strong>Date :</strong> $($Report.Metadata.Date.ToString("dd/MM/yyyy"))</p>
    </div>

    <div class="report-content">
"@

    # Ajouter les sections
    foreach ($section in $Report.Sections) {
        $html += @"
        <div class="report-section">
            <h2>$($section.Number) $($section.Title)</h2>
"@

        # Traitement spécifique selon le type de section
        switch ($section.Type) {
            "Text" {
                $html += @"
            <div class="section-content">
                $($section.Content)
            </div>
"@
            }
            "Table" {
                $tableId = "table-$($section.Id)"
                $html += @"
            <div class="section-content">
                <table id="$tableId" data-sort-direction="asc">
                    <thead>
                        <tr>
"@

                # Ajouter les en-têtes de colonnes
                if ($section.ContainsKey("Headers") -and $section.Headers.Count -gt 0) {
                    foreach ($header in $section.Headers) {
                        $html += @"
                            <th onclick="sortTable('$tableId', $($section.Headers.IndexOf($header)))">$header</th>
"@
                    }
                } elseif ($section.Content.Count -gt 0 -and $section.Content[0] -is [PSObject]) {
                    foreach ($property in $section.Content[0].PSObject.Properties.Name) {
                        $html += @"
                            <th onclick="sortTable('$tableId', $($section.Content[0].PSObject.Properties.Name.IndexOf($property)))">$property</th>
"@
                    }
                }

                $html += @"
                        </tr>
                    </thead>
                    <tbody>
"@

                # Ajouter les lignes de données
                foreach ($row in $section.Content) {
                    $html += @"
                        <tr>
"@

                    if ($row -is [PSObject]) {
                        foreach ($property in $row.PSObject.Properties) {
                            $html += @"
                            <td>$($property.Value)</td>
"@
                        }
                    } elseif ($row -is [hashtable]) {
                        foreach ($key in $row.Keys) {
                            $html += @"
                            <td>$($row[$key])</td>
"@
                        }
                    } else {
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
                $chartData = ConvertTo-Json -InputObject $section.Content -Depth 10 -Compress
                $chartOptions = ConvertTo-Json -InputObject $section.Content.Options -Depth 5 -Compress

                $html += @"
            <div class="section-content">
                <div class="chart-container" data-chart-type="$($section.Content.ChartType)" data-chart-data='$chartData' data-chart-options='$chartOptions'>
                    <canvas id="$chartId" width="400" height="200"></canvas>
                </div>
            </div>
"@
            }
            "List" {
                $html += @"
            <div class="section-content">
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
                $language = if ($section.ContainsKey("Language")) { $section.Language } else { "" }

                $html += @"
            <div class="section-content">
                <pre><code class="language-$language">$($section.Content)</code></pre>
            </div>
"@
            }
        }

        $html += @"
        </div>
"@
    }

    $html += @"
    </div>

    <div class="report-footer">
        <p>Rapport généré le $((Get-Date).ToString("dd/MM/yyyy HH:mm:ss"))</p>
        <p>ID du rapport : $($Report.Metadata.Id)</p>
    </div>
</body>
</html>
"@

    # Écrire le HTML dans le fichier de sortie
    $html | Out-File -FilePath $OutputPath -Encoding utf8

    return $OutputPath
}

#endregion

#region Exemples d'utilisation

<#
.SYNOPSIS
Exemple de rapport sur une collection d'informations extraites.

.DESCRIPTION
Cette fonction crée un exemple de rapport sur une collection d'informations extraites.
Elle montre comment utiliser les fonctions de génération de rapports pour créer un
rapport complet avec des sections textuelles, des tableaux et des graphiques.

.PARAMETER OutputFolder
Le dossier de sortie pour les rapports générés.

.EXAMPLE
Example-CollectionReport -OutputFolder "C:\Temp\Reports"

.NOTES
Cette fonction est fournie à titre d'exemple et peut être adaptée selon vos besoins.
#>
function Example-CollectionReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = ".\output"
    )

    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    # Créer une collection d'informations extraites d'exemple
    $collection = @{
        Name  = "Collection d'exemple"
        Items = @{}
    }

    # Ajouter des informations textuelles
    for ($i = 1; $i -le 5; $i++) {
        $textInfo = @{
            _Type           = "TextExtractedInfo"
            Id              = [guid]::NewGuid().ToString()
            Source          = "document$i.txt"
            Text            = "Ceci est le contenu du document $i. Il contient des informations importantes pour l'analyse."
            Language        = "fr"
            ConfidenceScore = 80 + $i
            ExtractedAt     = (Get-Date).AddDays(-$i)
            ProcessingState = "Processed"
            Metadata        = @{
                Author   = "Auteur $i"
                Category = "Catégorie " + [char](64 + $i)
                Tags     = @("tag1", "tag2", "document$i")
            }
        }

        $collection.Items[$textInfo.Id] = $textInfo
    }

    # Ajouter des informations structurées
    for ($i = 1; $i -le 3; $i++) {
        $structuredInfo = @{
            _Type           = "StructuredDataExtractedInfo"
            Id              = [guid]::NewGuid().ToString()
            Source          = "data$i.json"
            Data            = @(
                @{ Name = "Produit A"; Value = 100 + $i * 10; Category = "Catégorie A" }
                @{ Name = "Produit B"; Value = 200 + $i * 15; Category = "Catégorie B" }
                @{ Name = "Produit C"; Value = 150 + $i * 5; Category = "Catégorie A" }
            )
            DataFormat      = "Json"
            ConfidenceScore = 90 + $i
            ExtractedAt     = (Get-Date).AddDays(-$i)
            ProcessingState = "Processed"
            Metadata        = @{
                Source  = "API"
                Version = "1.$i"
                Tags    = @("data", "json", "structured")
            }
        }

        $collection.Items[$structuredInfo.Id] = $structuredInfo
    }

    # Créer un rapport
    $report = New-ExtractedInfoReport -Title "Rapport d'analyse de la collection" -Description "Ce rapport présente une analyse détaillée des informations extraites de la collection." -Author "Système de reporting" -Type "Standard"

    # Ajouter une section d'introduction
    $introductionText = @"
Ce rapport présente une analyse détaillée des informations extraites de la collection "$($collection.Name)".
La collection contient $($collection.Items.Count) éléments, dont :
- $($collection.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count informations textuelles
- $($collection.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count informations structurées

L'analyse a été générée le $(Get-Date -Format "dd/MM/yyyy HH:mm:ss").
"@

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Introduction" -Content $introductionText -Type "Text" -Level 1

    # Ajouter une section sur les informations textuelles
    $textInfos = $collection.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" }

    $textInfosTable = $textInfos | ForEach-Object {
        [PSCustomObject]@{
            Source         = $_.Source
            Langue         = $_.Language
            Confiance      = $_.ConfidenceScore
            DateExtraction = $_.ExtractedAt.ToString("dd/MM/yyyy")
            Auteur         = $_.Metadata.Author
            Catégorie      = $_.Metadata.Category
        }
    }

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Informations textuelles" -Content $textInfosTable -Type "Table" -Level 1

    # Ajouter un graphique de répartition par catégorie
    $categoryCounts = @{}
    foreach ($info in $textInfos) {
        $category = $info.Metadata.Category
        if (-not $categoryCounts.ContainsKey($category)) {
            $categoryCounts[$category] = 0
        }
        $categoryCounts[$category]++
    }

    $categoryData = @()
    foreach ($category in $categoryCounts.Keys) {
        $categoryData += [PSCustomObject]@{
            Category = $category
            Count    = $categoryCounts[$category]
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Répartition par catégorie" -Data $categoryData -ChartType "Pie" -Options @{
        LabelProperty = "Category"
        ValueProperty = "Count"
    }

    # Ajouter une section sur les informations structurées
    $structuredInfos = $collection.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }

    $structuredInfosTable = $structuredInfos | ForEach-Object {
        [PSCustomObject]@{
            Source         = $_.Source
            Format         = $_.DataFormat
            Confiance      = $_.ConfidenceScore
            DateExtraction = $_.ExtractedAt.ToString("dd/MM/yyyy")
            NombreElements = $_.Data.Count
            Version        = $_.Metadata.Version
        }
    }

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Informations structurées" -Content $structuredInfosTable -Type "Table" -Level 1

    # Ajouter un graphique des valeurs par produit
    $productData = @()
    foreach ($info in $structuredInfos) {
        foreach ($item in $info.Data) {
            $productData += [PSCustomObject]@{
                Product  = $item.Name
                Value    = $item.Value
                Category = $item.Category
            }
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Valeurs par produit" -Data $productData -ChartType "Bar" -Options @{
        LabelProperty = "Product"
        ValueProperty = "Value"
    }

    # Ajouter une section d'analyse temporelle
    $extractionDates = $collection.Items.Values | ForEach-Object { $_.ExtractedAt } | Sort-Object
    $dateRange = ($extractionDates | Select-Object -First 1).ToString("dd/MM/yyyy") + " - " + ($extractionDates | Select-Object -Last 1).ToString("dd/MM/yyyy")

    $timeAnalysisText = @"
Les informations ont été extraites sur une période de $dateRange.
La répartition temporelle des extractions est présentée dans le graphique ci-dessous.
"@

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Analyse temporelle" -Content $timeAnalysisText -Type "Text" -Level 1

    # Ajouter un graphique de répartition temporelle
    $dateData = @{}
    foreach ($date in $extractionDates) {
        $dateStr = $date.ToString("yyyy-MM-dd")
        if (-not $dateData.ContainsKey($dateStr)) {
            $dateData[$dateStr] = 0
        }
        $dateData[$dateStr]++
    }

    $timeData = @()
    foreach ($date in $dateData.Keys | Sort-Object) {
        $timeData += [PSCustomObject]@{
            Date  = $date
            Count = $dateData[$date]
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Répartition temporelle des extractions" -Data $timeData -ChartType "Line" -Options @{
        LabelProperty = "Date"
        ValueProperty = "Count"
        Smooth        = $true
    }

    # Ajouter une section de conclusion
    $conclusionText = @"
Cette analyse montre que la collection "$($collection.Name)" contient des informations variées,
avec une répartition équilibrée entre les différentes catégories.

Les points clés à retenir sont :
- La majorité des informations textuelles appartiennent à la catégorie $(($categoryCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key)
- Les produits de la catégorie A ont généralement des valeurs plus élevées que ceux de la catégorie B
- La plupart des extractions ont été réalisées le $(($dateData.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key)

Des analyses plus approfondies pourraient être réalisées pour explorer davantage ces tendances.
"@

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Conclusion" -Content $conclusionText -Type "Text" -Level 1

    # Exporter le rapport au format HTML
    $htmlPath = Join-Path -Path $OutputFolder -ChildPath "collection_report.html"
    Export-ExtractedInfoReportToHtml -Report $report -OutputPath $htmlPath

    Write-Host "Rapport généré avec succès : $htmlPath"

    return $report
}

# Exemple d'utilisation
# Example-CollectionReport -OutputFolder "C:\Temp\Reports"

<#
.SYNOPSIS
Exemple de rapport de comparaison entre plusieurs collections d'informations extraites.

.DESCRIPTION
Cette fonction crée un exemple de rapport comparant plusieurs collections d'informations extraites.
Elle montre comment utiliser les fonctions de génération de rapports pour créer un
rapport comparatif avec des tableaux et des graphiques de comparaison.

.PARAMETER OutputFolder
Le dossier de sortie pour les rapports générés.

.EXAMPLE
Example-ComparisonReport -OutputFolder "C:\Temp\Reports"

.NOTES
Cette fonction est fournie à titre d'exemple et peut être adaptée selon vos besoins.
#>
function Example-ComparisonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = ".\output"
    )

    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    # Créer trois collections d'informations extraites d'exemple avec des caractéristiques différentes
    $collections = @{}

    # Collection 1 : Données textuelles principalement
    $collection1 = @{
        Name        = "Collection Textuelle"
        Description = "Collection contenant principalement des données textuelles"
        CreatedAt   = (Get-Date).AddDays(-30)
        Items       = @{}
    }

    # Ajouter des informations textuelles à la collection 1
    for ($i = 1; $i -le 15; $i++) {
        $textInfo = @{
            _Type           = "TextExtractedInfo"
            Id              = [guid]::NewGuid().ToString()
            Source          = "document$i.txt"
            Text            = "Ceci est le contenu du document $i de la collection textuelle. Il contient des informations importantes pour l'analyse."
            Language        = "fr"
            ConfidenceScore = 75 + ($i % 20)
            ExtractedAt     = (Get-Date).AddDays(-30 + $i)
            ProcessingState = "Processed"
            Metadata        = @{
                Author   = "Auteur $i"
                Category = "Catégorie " + [char](64 + ($i % 5 + 1))
                Tags     = @("texte", "document", "collection1")
            }
        }

        $collection1.Items[$textInfo.Id] = $textInfo
    }

    # Ajouter quelques informations structurées à la collection 1 (minoritaires)
    for ($i = 1; $i -le 3; $i++) {
        $structuredInfo = @{
            _Type           = "StructuredDataExtractedInfo"
            Id              = [guid]::NewGuid().ToString()
            Source          = "data$i-collection1.json"
            Data            = @(
                @{ Name = "Produit A"; Value = 80 + $i * 5; Category = "Catégorie A" }
                @{ Name = "Produit B"; Value = 120 + $i * 8; Category = "Catégorie B" }
            )
            DataFormat      = "Json"
            ConfidenceScore = 85 + $i
            ExtractedAt     = (Get-Date).AddDays(-25 + $i)
            ProcessingState = "Processed"
            Metadata        = @{
                Source  = "API"
                Version = "1.$i"
                Tags    = @("data", "json", "collection1")
            }
        }

        $collection1.Items[$structuredInfo.Id] = $structuredInfo
    }

    # Collection 2 : Données structurées principalement
    $collection2 = @{
        Name        = "Collection Structurée"
        Description = "Collection contenant principalement des données structurées"
        CreatedAt   = (Get-Date).AddDays(-20)
        Items       = @{}
    }

    # Ajouter des informations structurées à la collection 2
    for ($i = 1; $i -le 12; $i++) {
        $structuredInfo = @{
            _Type           = "StructuredDataExtractedInfo"
            Id              = [guid]::NewGuid().ToString()
            Source          = "data$i-collection2.json"
            Data            = @(
                @{ Name = "Produit A"; Value = 100 + $i * 10; Category = "Catégorie A" }
                @{ Name = "Produit B"; Value = 200 + $i * 15; Category = "Catégorie B" }
                @{ Name = "Produit C"; Value = 150 + $i * 8; Category = "Catégorie A" }
                @{ Name = "Produit D"; Value = 180 + $i * 12; Category = "Catégorie C" }
            )
            DataFormat      = "Json"
            ConfidenceScore = 90 + ($i % 10)
            ExtractedAt     = (Get-Date).AddDays(-20 + $i)
            ProcessingState = "Processed"
            Metadata        = @{
                Source  = "API"
                Version = "2.$i"
                Tags    = @("data", "json", "structured", "collection2")
            }
        }

        $collection2.Items[$structuredInfo.Id] = $structuredInfo
    }

    # Ajouter quelques informations textuelles à la collection 2 (minoritaires)
    for ($i = 1; $i -le 4; $i++) {
        $textInfo = @{
            _Type           = "TextExtractedInfo"
            Id              = [guid]::NewGuid().ToString()
            Source          = "document$i-collection2.txt"
            Text            = "Ceci est le contenu du document $i de la collection structurée. Il contient des informations complémentaires."
            Language        = "fr"
            ConfidenceScore = 80 + ($i % 15)
            ExtractedAt     = (Get-Date).AddDays(-18 + $i)
            ProcessingState = "Processed"
            Metadata        = @{
                Author   = "Auteur " + ($i + 10)
                Category = "Catégorie " + [char](64 + ($i % 3 + 1))
                Tags     = @("texte", "document", "collection2")
            }
        }

        $collection2.Items[$textInfo.Id] = $textInfo
    }

    # Collection 3 : Données mixtes avec des caractéristiques différentes
    $collection3 = @{
        Name        = "Collection Mixte"
        Description = "Collection contenant un mélange équilibré de données textuelles et structurées"
        CreatedAt   = (Get-Date).AddDays(-10)
        Items       = @{}
    }

    # Ajouter des informations textuelles à la collection 3
    for ($i = 1; $i -le 8; $i++) {
        $textInfo = @{
            _Type           = "TextExtractedInfo"
            Id              = [guid]::NewGuid().ToString()
            Source          = "document$i-collection3.txt"
            Text            = "Ceci est le contenu du document $i de la collection mixte. Il contient des informations variées pour l'analyse comparative."
            Language        = if ($i % 3 -eq 0) { "en" } else { "fr" }
            ConfidenceScore = 85 + ($i % 12)
            ExtractedAt     = (Get-Date).AddDays(-10 + $i)
            ProcessingState = "Processed"
            Metadata        = @{
                Author   = "Auteur " + ($i + 20)
                Category = "Catégorie " + [char](64 + ($i % 6 + 1))
                Tags     = @("texte", "document", "collection3") + @(if ($i % 3 -eq 0) { "english" } else { "french" })
            }
        }

        $collection3.Items[$textInfo.Id] = $textInfo
    }

    # Ajouter des informations structurées à la collection 3
    for ($i = 1; $i -le 8; $i++) {
        $structuredInfo = @{
            _Type           = "StructuredDataExtractedInfo"
            Id              = [guid]::NewGuid().ToString()
            Source          = "data$i-collection3.json"
            Data            = @(
                @{ Name = "Produit A"; Value = 120 + $i * 8; Category = "Catégorie A" }
                @{ Name = "Produit B"; Value = 220 + $i * 12; Category = "Catégorie B" }
                @{ Name = "Produit C"; Value = 170 + $i * 6; Category = "Catégorie A" }
                @{ Name = "Produit E"; Value = 200 + $i * 10; Category = "Catégorie D" }
            )
            DataFormat      = if ($i % 2 -eq 0) { "Json" } else { "Xml" }
            ConfidenceScore = 88 + ($i % 10)
            ExtractedAt     = (Get-Date).AddDays(-8 + $i)
            ProcessingState = "Processed"
            Metadata        = @{
                Source  = if ($i % 2 -eq 0) { "API" } else { "File" }
                Version = "3.$i"
                Tags    = @("data") + @(if ($i % 2 -eq 0) { "json" } else { "xml" }) + @("collection3")
            }
        }

        $collection3.Items[$structuredInfo.Id] = $structuredInfo
    }

    # Ajouter les collections au dictionnaire
    $collections["Collection1"] = $collection1
    $collections["Collection2"] = $collection2
    $collections["Collection3"] = $collection3

    # Créer un rapport de comparaison
    $report = New-ExtractedInfoReport -Title "Rapport de comparaison entre collections" -Description "Ce rapport compare trois collections d'informations extraites avec des caractéristiques différentes." -Author "Système de reporting" -Type "Comparison"

    # Ajouter une section d'introduction
    $introductionText = @"
Ce rapport présente une analyse comparative de trois collections d'informations extraites :
- **$($collection1.Name)** : $($collection1.Description)
- **$($collection2.Name)** : $($collection2.Description)
- **$($collection3.Name)** : $($collection3.Description)

L'analyse a été générée le $(Get-Date -Format "dd/MM/yyyy HH:mm:ss") et compare les collections sur plusieurs aspects :
- Composition et volume des données
- Distribution des types d'informations
- Scores de confiance
- Distribution temporelle des extractions
- Caractéristiques spécifiques à chaque type de données

Cette comparaison permet d'identifier les points forts et les particularités de chaque collection.
"@

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Introduction" -Content $introductionText -Type "Text" -Level 1

    # Ajouter une section de statistiques générales
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Statistiques générales" -Content "Cette section présente les statistiques générales des trois collections." -Type "Text" -Level 1

    # Créer un tableau comparatif des statistiques générales
    $generalStats = @(
        [PSCustomObject]@{
            Collection                 = $collection1.Name
            "Nombre total d'éléments"  = $collection1.Items.Count
            "Éléments textuels"        = ($collection1.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count
            "Éléments structurés"      = ($collection1.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count
            "Score de confiance moyen" = [math]::Round(($collection1.Items.Values | Measure-Object -Property ConfidenceScore -Average).Average, 2)
            "Date de création"         = $collection1.CreatedAt.ToString("dd/MM/yyyy")
            "Période d'extraction"     = "$((($collection1.Items.Values | Sort-Object -Property ExtractedAt | Select-Object -First 1).ExtractedAt).ToString("dd/MM/yyyy")) - $((($collection1.Items.Values | Sort-Object -Property ExtractedAt -Descending | Select-Object -First 1).ExtractedAt).ToString("dd/MM/yyyy"))"
        },
        [PSCustomObject]@{
            Collection                 = $collection2.Name
            "Nombre total d'éléments"  = $collection2.Items.Count
            "Éléments textuels"        = ($collection2.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count
            "Éléments structurés"      = ($collection2.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count
            "Score de confiance moyen" = [math]::Round(($collection2.Items.Values | Measure-Object -Property ConfidenceScore -Average).Average, 2)
            "Date de création"         = $collection2.CreatedAt.ToString("dd/MM/yyyy")
            "Période d'extraction"     = "$((($collection2.Items.Values | Sort-Object -Property ExtractedAt | Select-Object -First 1).ExtractedAt).ToString("dd/MM/yyyy")) - $((($collection2.Items.Values | Sort-Object -Property ExtractedAt -Descending | Select-Object -First 1).ExtractedAt).ToString("dd/MM/yyyy"))"
        },
        [PSCustomObject]@{
            Collection                 = $collection3.Name
            "Nombre total d'éléments"  = $collection3.Items.Count
            "Éléments textuels"        = ($collection3.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count
            "Éléments structurés"      = ($collection3.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count
            "Score de confiance moyen" = [math]::Round(($collection3.Items.Values | Measure-Object -Property ConfidenceScore -Average).Average, 2)
            "Date de création"         = $collection3.CreatedAt.ToString("dd/MM/yyyy")
            "Période d'extraction"     = "$((($collection3.Items.Values | Sort-Object -Property ExtractedAt | Select-Object -First 1).ExtractedAt).ToString("dd/MM/yyyy")) - $((($collection3.Items.Values | Sort-Object -Property ExtractedAt -Descending | Select-Object -First 1).ExtractedAt).ToString("dd/MM/yyyy"))"
        }
    )

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Tableau comparatif des statistiques générales" -Content $generalStats -Type "Table" -Level 2

    # Ajouter un graphique en barres groupées pour comparer les volumes
    $volumeData = @(
        [PSCustomObject]@{
            Type                   = "Éléments textuels"
            "$($collection1.Name)" = ($collection1.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count
            "$($collection2.Name)" = ($collection2.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count
            "$($collection3.Name)" = ($collection3.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count
        },
        [PSCustomObject]@{
            Type                   = "Éléments structurés"
            "$($collection1.Name)" = ($collection1.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count
            "$($collection2.Name)" = ($collection2.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count
            "$($collection3.Name)" = ($collection3.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count
        },
        [PSCustomObject]@{
            Type                   = "Total"
            "$($collection1.Name)" = $collection1.Items.Count
            "$($collection2.Name)" = $collection2.Items.Count
            "$($collection3.Name)" = $collection3.Items.Count
        }
    )

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Comparaison des volumes par type d'élément" -Data $volumeData -ChartType "Bar" -Options @{
        LabelProperty    = "Type"
        SeriesProperties = @("$($collection1.Name)", "$($collection2.Name)", "$($collection3.Name)")
        Colors           = @("#4e79a7", "#f28e2c", "#59a14f")
    }

    # Ajouter un graphique radar pour comparer les scores de confiance
    $confidenceData = @{
        Labels = @("Score moyen", "Score minimum", "Score maximum", "Écart-type")
        Series = @{
            "$($collection1.Name)" = @(
                [math]::Round(($collection1.Items.Values | Measure-Object -Property ConfidenceScore -Average).Average, 2),
                ($collection1.Items.Values | Measure-Object -Property ConfidenceScore -Minimum).Minimum,
                ($collection1.Items.Values | Measure-Object -Property ConfidenceScore -Maximum).Maximum,
                [math]::Round(($collection1.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -StandardDeviation).StandardDeviation, 2)
            )
            "$($collection2.Name)" = @(
                [math]::Round(($collection2.Items.Values | Measure-Object -Property ConfidenceScore -Average).Average, 2),
                ($collection2.Items.Values | Measure-Object -Property ConfidenceScore -Minimum).Minimum,
                ($collection2.Items.Values | Measure-Object -Property ConfidenceScore -Maximum).Maximum,
                [math]::Round(($collection2.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -StandardDeviation).StandardDeviation, 2)
            )
            "$($collection3.Name)" = @(
                [math]::Round(($collection3.Items.Values | Measure-Object -Property ConfidenceScore -Average).Average, 2),
                ($collection3.Items.Values | Measure-Object -Property ConfidenceScore -Minimum).Minimum,
                ($collection3.Items.Values | Measure-Object -Property ConfidenceScore -Maximum).Maximum,
                [math]::Round(($collection3.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -StandardDeviation).StandardDeviation, 2)
            )
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Comparaison des scores de confiance" -Data $confidenceData -ChartType "Radar" -Options @{
        Colors = @("#4e79a7", "#f28e2c", "#59a14f")
    }

    # Ajouter une section d'analyse des différences
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Analyse des différences" -Content "Cette section analyse les différences significatives entre les collections." -Type "Text" -Level 1

    # Calculer les différences statistiques entre les collections
    $differenceAnalysis = @"
## Différences de composition

- **$($collection1.Name)** est composée à $(([math]::Round(($collection1.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count / $collection1.Items.Count * 100, 1)))% d'éléments textuels, ce qui en fait la collection la plus orientée vers le texte.
- **$($collection2.Name)** est composée à $(([math]::Round(($collection2.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count / $collection2.Items.Count * 100, 1)))% d'éléments structurés, ce qui en fait la collection la plus orientée vers les données structurées.
- **$($collection3.Name)** présente un équilibre plus prononcé avec $(([math]::Round(($collection3.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count / $collection3.Items.Count * 100, 1)))% d'éléments textuels et $(([math]::Round(($collection3.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count / $collection3.Items.Count * 100, 1)))% d'éléments structurés.

## Différences de qualité

- **$($collection2.Name)** présente le score de confiance moyen le plus élevé ($(([math]::Round(($collection2.Items.Values | Measure-Object -Property ConfidenceScore -Average).Average, 2)))), ce qui suggère une meilleure qualité globale des extractions.
- **$($collection1.Name)** a le score moyen le plus bas ($(([math]::Round(($collection1.Items.Values | Measure-Object -Property ConfidenceScore -Average).Average, 2)))), mais avec une variabilité plus faible, indiquant une qualité plus constante.
- **$($collection3.Name)** présente une plus grande variabilité dans les scores de confiance, ce qui reflète la diversité des sources et des formats.

## Différences temporelles

- **$($collection1.Name)** est la plus ancienne, avec des extractions réparties sur une période plus longue.
- **$($collection3.Name)** est la plus récente, avec des extractions concentrées sur une période plus courte.
- La densité d'extraction (nombre d'éléments par jour) est plus élevée pour **$($collection2.Name)** ($(([math]::Round($collection2.Items.Count / (($collection2.Items.Values | Sort-Object -Property ExtractedAt -Descending | Select-Object -First 1).ExtractedAt - ($collection2.Items.Values | Sort-Object -Property ExtractedAt | Select-Object -First 1).ExtractedAt).TotalDays, 1)))) éléments/jour) que pour les autres collections.
"@

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Analyse comparative détaillée" -Content $differenceAnalysis -Type "Text" -Level 2

    # Ajouter un graphique en camembert pour comparer les distributions par catégorie
    $categoryData = @()

    # Fonction pour extraire les catégories d'une collection
    function Get-CategoryDistribution {
        param (
            [Parameter(Mandatory = $true)]
            [hashtable]$Collection
        )

        $categories = @{}

        foreach ($item in $Collection.Items.Values) {
            if ($item.Metadata.ContainsKey("Category")) {
                $category = $item.Metadata.Category
                if (-not $categories.ContainsKey($category)) {
                    $categories[$category] = 0
                }
                $categories[$category]++
            }
        }

        return $categories
    }

    $categories1 = Get-CategoryDistribution -Collection $collection1
    $categories2 = Get-CategoryDistribution -Collection $collection2
    $categories3 = Get-CategoryDistribution -Collection $collection3

    # Créer des graphiques en camembert pour chaque collection
    $pieData1 = @{
        ChartType = "Pie"
        Labels    = $categories1.Keys
        Values    = $categories1.Values
        Options   = @{
            Title  = "Distribution par catégorie - $($collection1.Name)"
            Colors = @("#4e79a7", "#f28e2c", "#e15759", "#76b7b2", "#59a14f")
        }
    }

    $pieData2 = @{
        ChartType = "Pie"
        Labels    = $categories2.Keys
        Values    = $categories2.Values
        Options   = @{
            Title  = "Distribution par catégorie - $($collection2.Name)"
            Colors = @("#4e79a7", "#f28e2c", "#e15759", "#76b7b2", "#59a14f")
        }
    }

    $pieData3 = @{
        ChartType = "Pie"
        Labels    = $categories3.Keys
        Values    = $categories3.Values
        Options   = @{
            Title  = "Distribution par catégorie - $($collection3.Name)"
            Colors = @("#4e79a7", "#f28e2c", "#e15759", "#76b7b2", "#59a14f")
        }
    }

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Distribution par catégorie - $($collection1.Name)" -Content $pieData1 -Type "Chart" -Level 2
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Distribution par catégorie - $($collection2.Name)" -Content $pieData2 -Type "Chart" -Level 2
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Distribution par catégorie - $($collection3.Name)" -Content $pieData3 -Type "Chart" -Level 2

    # Ajouter une section de conclusion
    $conclusionText = @"
## Synthèse des comparaisons

L'analyse comparative des trois collections révèle des différences significatives en termes de composition, de qualité et de distribution temporelle :

1. **Composition** : Les collections présentent des orientations différentes, avec une prédominance de données textuelles pour la Collection Textuelle, de données structurées pour la Collection Structurée, et un équilibre pour la Collection Mixte.

2. **Qualité** : La Collection Structurée présente globalement les scores de confiance les plus élevés, ce qui peut s'expliquer par la nature plus formalisée des données structurées. La Collection Mixte montre une plus grande variabilité, reflétant la diversité de ses sources.

3. **Temporalité** : Les collections couvrent des périodes différentes, avec des densités d'extraction variables. La Collection Structurée présente la densité la plus élevée, suggérant un processus d'extraction plus intensif.

4. **Catégories** : La distribution des catégories varie considérablement entre les collections, avec une plus grande diversité dans la Collection Mixte.

## Recommandations

Sur la base de cette analyse comparative, voici quelques recommandations :

- Pour les analyses nécessitant une grande quantité de données textuelles, privilégier la **Collection Textuelle**.
- Pour les analyses quantitatives nécessitant des données de haute qualité, privilégier la **Collection Structurée**.
- Pour les analyses mixtes ou exploratoires, privilégier la **Collection Mixte** qui offre une plus grande diversité.
- Envisager de combiner les collections pour des analyses plus complètes, en tenant compte des différences de qualité et de composition.
"@

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Conclusion et recommandations" -Content $conclusionText -Type "Text" -Level 1

    # Exporter le rapport au format HTML interactif
    $htmlPath = Join-Path -Path $OutputFolder -ChildPath "comparison_report.html"
    Export-ExtractedInfoReportToHtml -Report $report -OutputPath $htmlPath -Theme "Light"

    Write-Host "Rapport de comparaison généré avec succès : $htmlPath"

    return $report
}

# Exemple d'utilisation
# Example-ComparisonReport -OutputFolder "C:\Temp\Reports"

# Charger la fonction d'exemple de rapport d'analyse temporelle
. "$PSScriptRoot\Integration-Reporting-TimeAnalysis.ps1"

# Exemple d'utilisation
# Example-TimeAnalysisReport -OutputFolder "C:\Temp\Reports" -MonthsOfData 6

<#
.SYNOPSIS
Exemple de rapport d'analyse temporelle des informations extraites.

.DESCRIPTION
Cette fonction crée un exemple de rapport d'analyse temporelle des informations extraites.
Elle montre comment utiliser les fonctions de génération de rapports pour créer un
rapport d'analyse temporelle avec des graphiques de tendance et des indicateurs de progression.

.PARAMETER OutputFolder
Le dossier de sortie pour les rapports générés.

.PARAMETER MonthsOfData
Le nombre de mois de données à générer pour l'analyse.
Par défaut, 12 mois.

.EXAMPLE
Example-TimeAnalysisReport -OutputFolder "C:\Temp\Reports" -MonthsOfData 6

.NOTES
Cette fonction est fournie à titre d'exemple et peut être adaptée selon vos besoins.
#>
function Example-TimeAnalysisReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = ".\output",

        [Parameter(Mandatory = $false)]
        [int]$MonthsOfData = 12
    )

    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    # Créer une collection d'informations avec des horodatages variés
    $collection = @{
        Name        = "Collection Temporelle"
        Description = "Collection d'informations extraites sur une période de $MonthsOfData mois"
        CreatedAt   = (Get-Date).AddMonths(-$MonthsOfData)
        Items       = @{}
    }

    # Définir la période de données
    $startDate = (Get-Date).AddMonths(-$MonthsOfData)
    $endDate = Get-Date

    # Définir les paramètres de variation saisonnière
    $seasonalFactors = @{
        1  = 0.8   # Janvier
        2  = 0.9   # Février
        3  = 1.0   # Mars
        4  = 1.1   # Avril
        5  = 1.2   # Mai
        6  = 1.3   # Juin
        7  = 1.4   # Juillet
        8  = 1.3   # Août
        9  = 1.2   # Septembre
        10 = 1.1   # Octobre
        11 = 1.0   # Novembre
        12 = 0.9   # Décembre
    }

    # Définir les événements ponctuels
    $specialEvents = @(
        @{
            Date     = $startDate.AddMonths(2).AddDays(15)
            Name     = "Mise à jour majeure du système d'extraction"
            Impact   = 1.5
            Duration = 3
        },
        @{
            Date     = $startDate.AddMonths(5).AddDays(10)
            Name     = "Intégration de nouvelles sources de données"
            Impact   = 2.0
            Duration = 5
        },
        @{
            Date     = $startDate.AddMonths(8).AddDays(20)
            Name     = "Maintenance du système"
            Impact   = 0.5
            Duration = 2
        },
        @{
            Date     = $startDate.AddMonths(10).AddDays(5)
            Name     = "Optimisation des algorithmes d'extraction"
            Impact   = 1.3
            Duration = 4
        }
    )

    # Générer des données pour chaque jour de la période
    $currentDate = $startDate
    $dayCounter = 0

    while ($currentDate -le $endDate) {
        $dayCounter++

        # Calculer le nombre d'éléments à générer pour ce jour
        $baseCount = [math]::Max(1, [math]::Round(10 * $seasonalFactors[$currentDate.Month] * (1 + 0.5 * [math]::Sin($dayCounter / 30 * [math]::PI))))

        # Appliquer l'impact des événements spéciaux
        foreach ($event in $specialEvents) {
            $daysSinceEvent = ($currentDate - $event.Date).TotalDays
            if ($daysSinceEvent -ge 0 -and $daysSinceEvent -lt $event.Duration) {
                $baseCount = [math]::Round($baseCount * $event.Impact)
            }
        }

        # Ajouter une variation aléatoire
        $itemCount = [math]::Max(1, [math]::Round($baseCount * (0.8 + 0.4 * (Get-Random -Minimum 0 -Maximum 100) / 100)))

        # Générer les éléments pour ce jour
        for ($i = 1; $i -le $itemCount; $i++) {
            # Déterminer le type d'élément (textuel ou structuré)
            $isTextual = (Get-Random -Minimum 0 -Maximum 100) -lt 60

            if ($isTextual) {
                # Créer un élément textuel
                $textInfo = @{
                    _Type           = "TextExtractedInfo"
                    Id              = [guid]::NewGuid().ToString()
                    Source          = "document_$($currentDate.ToString('yyyyMMdd'))_$i.txt"
                    Text            = "Contenu extrait le $($currentDate.ToString('dd/MM/yyyy')). Élément $i de la journée."
                    Language        = if ((Get-Random -Minimum 0 -Maximum 100) -lt 80) { "fr" } else { "en" }
                    ConfidenceScore = 70 + (Get-Random -Minimum 0 -Maximum 30)
                    ExtractedAt     = $currentDate.AddHours(Get-Random -Minimum 0 -Maximum 24).AddMinutes(Get-Random -Minimum 0 -Maximum 60)
                    ProcessingState = "Processed"
                    Metadata = @{
                        Author   = "Auteur " + (Get-Random -Minimum 1 -Maximum 20)
                        Category = "Catégorie " + [char](64 + (Get-Random -Minimum 1 -Maximum 6))
                        Tags     = @("texte", "document", "jour" + $currentDate.Day, "mois" + $currentDate.Month)
                    }
                }

                $collection.Items[$textInfo.Id] = $textInfo
            } else {
                # Créer un élément structuré
                $structuredInfo = @{
                    _Type           = "StructuredDataExtractedInfo"
                    Id              = [guid]::NewGuid().ToString()
                    Source          = "data_$($currentDate.ToString('yyyyMMdd'))_$i.json"
                    Data            = @(
                        @{ Name = "Métrique A"; Value = 100 + (Get-Random -Minimum 0 -Maximum 100); Category = "Catégorie A" }
                        @{ Name = "Métrique B"; Value = 200 + (Get-Random -Minimum 0 -Maximum 150); Category = "Catégorie B" }
                        @{ Name = "Métrique C"; Value = 150 + (Get-Random -Minimum 0 -Maximum 120); Category = "Catégorie A" }
                    )
                    DataFormat      = if ((Get-Random -Minimum 0 -Maximum 100) -lt 70) { "Json" } else { "Xml" }
                    ConfidenceScore = 80 + (Get-Random -Minimum 0 -Maximum 20)
                    ExtractedAt     = $currentDate.AddHours(Get-Random -Minimum 0 -Maximum 24).AddMinutes(Get-Random -Minimum 0 -Maximum 60)
                    ProcessingState = "Processed"
                    Metadata = @{
                        Source  = if ((Get-Random -Minimum 0 -Maximum 100) -lt 60) { "API" } else { "File" }
                        Version = "1." + (Get-Random -Minimum 0 -Maximum 10)
                        Tags    = @("data", if ((Get-Random -Minimum 0 -Maximum 100) -lt 70) { "json" } else { "xml" }, "jour" + $currentDate.Day, "mois" + $currentDate.Month)
                    }
                }

                $collection.Items[$structuredInfo.Id] = $structuredInfo
            }
        }

        # Passer au jour suivant
        $currentDate = $currentDate.AddDays(1)
    }

    # Créer un rapport d'analyse temporelle
    $report = New-ExtractedInfoReport -Title "Analyse temporelle des extractions" -Description "Ce rapport présente une analyse temporelle des informations extraites sur une période de $MonthsOfData mois." -Author "Système de reporting" -Type "TimeAnalysis"

    # Ajouter une section d'introduction
    $introductionText = @"
Ce rapport présente une analyse temporelle détaillée des informations extraites de la collection "$($collection.Name)" sur la période du $($startDate.ToString("dd/MM/yyyy")) au $($endDate.ToString("dd/MM/yyyy")).

La collection contient un total de $($collection.Items.Count) éléments, dont :
- $($collection.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" } | Measure-Object).Count informations textuelles
- $($collection.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" } | Measure-Object).Count informations structurées

Cette analyse temporelle permet d'identifier les tendances, les variations saisonnières et les événements ponctuels qui ont influencé le volume et la qualité des extractions.
"@

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Introduction" -Content $introductionText -Type "Text" -Level 1

    # Ajouter une section sur les événements importants
    $eventsText = @"
## Événements majeurs ayant influencé les extractions

Au cours de la période analysée, plusieurs événements ont eu un impact significatif sur le volume et la qualité des extractions :

"@

    foreach ($event in $specialEvents) {
        $eventsText += @"
- **$($event.Name)** ($($event.Date.ToString("dd/MM/yyyy"))) : Impact de $($event.Impact)x sur le volume d'extraction pendant $($event.Duration) jours.

"@
    }

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Événements majeurs" -Content $eventsText -Type "Text" -Level 1

    # Implémenter l'analyse par période (jour, semaine, mois)

    # Fonction pour agréger les données par période
    function Get-AggregatedData {
        param (
            [Parameter(Mandatory = $true)]
            [hashtable]$Collection,

            [Parameter(Mandatory = $true)]
            [ValidateSet("Day", "Week", "Month")]
            [string]$Period
        )

        $aggregatedData = @{}

        foreach ($item in $Collection.Items.Values) {
            $date = $item.ExtractedAt

            # Déterminer la clé de période
            $periodKey = switch ($Period) {
                "Day" { $date.ToString("yyyy-MM-dd") }
                "Week" {
                    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
                    $calendar = $cultureInfo.Calendar
                    $weekNum = $calendar.GetWeekOfYear($date, $cultureInfo.DateTimeFormat.CalendarWeekRule, $cultureInfo.DateTimeFormat.FirstDayOfWeek)
                    "$($date.Year)-W$($weekNum.ToString("00"))"
                }
                "Month" { $date.ToString("yyyy-MM") }
            }

            # Initialiser l'entrée si elle n'existe pas
            if (-not $aggregatedData.ContainsKey($periodKey)) {
                $aggregatedData[$periodKey] = @{
                    Period           = $periodKey
                    Date             = $date
                    TotalCount       = 0
                    TextCount        = 0
                    StructuredCount  = 0
                    ConfidenceScores = @()
                    Categories       = @{}
                }
            }

            # Mettre à jour les compteurs
            $aggregatedData[$periodKey].TotalCount++

            if ($item._Type -eq "TextExtractedInfo") {
                $aggregatedData[$periodKey].TextCount++
            } else {
                $aggregatedData[$periodKey].StructuredCount++
            }

            # Ajouter le score de confiance
            $aggregatedData[$periodKey].ConfidenceScores += $item.ConfidenceScore

            # Mettre à jour les catégories
            if ($item.Metadata.ContainsKey("Category")) {
                $category = $item.Metadata.Category
                if (-not $aggregatedData[$periodKey].Categories.ContainsKey($category)) {
                    $aggregatedData[$periodKey].Categories[$category] = 0
                }
                $aggregatedData[$periodKey].Categories[$category]++
            }
        }

        # Calculer les statistiques pour chaque période
        foreach ($key in $aggregatedData.Keys) {
            $entry = $aggregatedData[$key]

            # Calculer la moyenne des scores de confiance
            if ($entry.ConfidenceScores.Count -gt 0) {
                $entry.AvgConfidence = [math]::Round(($entry.ConfidenceScores | Measure-Object -Average).Average, 2)
                $entry.MinConfidence = ($entry.ConfidenceScores | Measure-Object -Minimum).Minimum
                $entry.MaxConfidence = ($entry.ConfidenceScores | Measure-Object -Maximum).Maximum
            } else {
                $entry.AvgConfidence = 0
                $entry.MinConfidence = 0
                $entry.MaxConfidence = 0
            }

            # Trouver la catégorie principale
            $mainCategory = ""
            $mainCategoryCount = 0

            foreach ($category in $entry.Categories.Keys) {
                if ($entry.Categories[$category] -gt $mainCategoryCount) {
                    $mainCategory = $category
                    $mainCategoryCount = $entry.Categories[$category]
                }
            }

            $entry.MainCategory = $mainCategory
            $entry.MainCategoryCount = $mainCategoryCount
        }

        # Convertir en tableau trié par date
        $result = $aggregatedData.Values | Sort-Object -Property Date

        return $result
    }

    # Obtenir les données agrégées par jour, semaine et mois
    $dailyData = Get-AggregatedData -Collection $collection -Period "Day"
    $weeklyData = Get-AggregatedData -Collection $collection -Period "Week"
    $monthlyData = Get-AggregatedData -Collection $collection -Period "Month"

    # Ajouter une section d'analyse quotidienne
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Analyse quotidienne" -Content "Cette section présente l'analyse des extractions par jour." -Type "Text" -Level 1

    # Créer un graphique de tendance quotidienne
    $dailyTrendData = @{
        ChartType = "Line"
        Labels    = $dailyData.Period
        Series    = @{
            "Total"      = $dailyData.TotalCount
            "Textuels"   = $dailyData.TextCount
            "Structurés" = $dailyData.StructuredCount
        }
        Options   = @{
            Title  = "Évolution quotidienne du nombre d'extractions"
            Colors = @("#4e79a7", "#f28e2c", "#59a14f")
            Smooth = $true
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Évolution quotidienne du nombre d'extractions" -Data $dailyTrendData -ChartType "Line" -Options @{
        Smooth   = $true
        FillArea = $false
    }

    # Créer un graphique de tendance de la qualité quotidienne
    $dailyQualityData = @{
        ChartType = "Line"
        Labels    = $dailyData.Period
        Series    = @{
            "Score moyen"   = $dailyData.AvgConfidence
            "Score minimum" = $dailyData.MinConfidence
            "Score maximum" = $dailyData.MaxConfidence
        }
        Options   = @{
            Title  = "Évolution quotidienne des scores de confiance"
            Colors = @("#4e79a7", "#f28e2c", "#59a14f")
            Smooth = $true
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Évolution quotidienne des scores de confiance" -Data $dailyQualityData -ChartType "Line" -Options @{
        Smooth   = $true
        FillArea = $false
    }

    # Ajouter une section d'analyse hebdomadaire
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Analyse hebdomadaire" -Content "Cette section présente l'analyse des extractions par semaine." -Type "Text" -Level 1

    # Créer un graphique de tendance hebdomadaire
    $weeklyTrendData = @{
        ChartType = "Line"
        Labels    = $weeklyData.Period
        Series    = @{
            "Total"      = $weeklyData.TotalCount
            "Textuels"   = $weeklyData.TextCount
            "Structurés" = $weeklyData.StructuredCount
        }
        Options   = @{
            Title  = "Évolution hebdomadaire du nombre d'extractions"
            Colors = @("#4e79a7", "#f28e2c", "#59a14f")
            Smooth = $true
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Évolution hebdomadaire du nombre d'extractions" -Data $weeklyTrendData -ChartType "Line" -Options @{
        Smooth   = $true
        FillArea = $true
    }

    # Créer un graphique en barres pour la répartition hebdomadaire
    $weeklyBarData = @{
        ChartType = "Bar"
        Labels    = $weeklyData.Period
        Values    = $weeklyData.TotalCount
        Options   = @{
            Title  = "Nombre d'extractions par semaine"
            Colors = @("#4e79a7")
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Nombre d'extractions par semaine" -Data $weeklyBarData -ChartType "Bar"

    # Ajouter une section d'analyse mensuelle
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Analyse mensuelle" -Content "Cette section présente l'analyse des extractions par mois." -Type "Text" -Level 1

    # Créer un tableau des statistiques mensuelles
    $monthlyStats = $monthlyData | ForEach-Object {
        [PSCustomObject]@{
            Mois                   = $_.Period
            "Nombre total"         = $_.TotalCount
            "Textuels"             = $_.TextCount
            "Structurés"           = $_.StructuredCount
            "Score moyen"          = $_.AvgConfidence
            "Catégorie principale" = $_.MainCategory
        }
    }

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Statistiques mensuelles" -Content $monthlyStats -Type "Table" -Level 2

    # Créer un graphique en aires pour la tendance mensuelle
    $monthlyAreaData = @{
        ChartType = "Area"
        Labels    = $monthlyData.Period
        Series    = @{
            "Textuels"   = $monthlyData.TextCount
            "Structurés" = $monthlyData.StructuredCount
        }
        Options   = @{
            Title   = "Évolution mensuelle par type d'extraction"
            Colors  = @("#f28e2c", "#59a14f")
            Stacked = $true
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Évolution mensuelle par type d'extraction" -Data $monthlyAreaData -ChartType "Area" -Options @{
        Stacked = $true
    }

    # Ajouter une section d'indicateurs de progression et de régression
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Indicateurs de progression et de régression" -Content "Cette section présente les indicateurs de progression et de régression des extractions." -Type "Text" -Level 1

    # Calculer les taux de croissance
    $growthRates = @()

    for ($i = 1; $i -lt $monthlyData.Count; $i++) {
        $currentMonth = $monthlyData[$i]
        $previousMonth = $monthlyData[$i - 1]

        $totalGrowth = if ($previousMonth.TotalCount -gt 0) {
            [math]::Round(($currentMonth.TotalCount - $previousMonth.TotalCount) / $previousMonth.TotalCount * 100, 1)
        } else {
            100
        }

        $qualityGrowth = if ($previousMonth.AvgConfidence -gt 0) {
            [math]::Round(($currentMonth.AvgConfidence - $previousMonth.AvgConfidence) / $previousMonth.AvgConfidence * 100, 1)
        } else {
            0
        }

        $growthRates += [PSCustomObject]@{
            "Période"                  = "$($previousMonth.Period) → $($currentMonth.Period)"
            "Croissance du volume"     = "$totalGrowth%"
            "Tendance volume"          = if ($totalGrowth -gt 0) { "↑" } elseif ($totalGrowth -lt 0) { "↓" } else { "→" }
            "Croissance de la qualité" = "$qualityGrowth%"
            "Tendance qualité"         = if ($qualityGrowth -gt 0) { "↑" } elseif ($qualityGrowth -lt 0) { "↓" } else { "→" }
        }
    }

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Taux de croissance mensuels" -Content $growthRates -Type "Table" -Level 2

    # Calculer les moyennes mobiles
    $movingAverages = @()
    $windowSize = 7 # Taille de la fenêtre pour la moyenne mobile (7 jours)

    for ($i = $windowSize - 1; $i -lt $dailyData.Count; $i++) {
        $window = $dailyData[($i - $windowSize + 1)..$i]
        $date = $dailyData[$i].Date

        $avgTotal = [math]::Round(($window | Measure-Object -Property TotalCount -Average).Average, 1)
        $avgConfidence = [math]::Round(($window | Measure-Object -Property AvgConfidence -Average).Average, 1)

        $movingAverages += [PSCustomObject]@{
            "Date"                     = $date.ToString("yyyy-MM-dd")
            "Moyenne mobile (volume)"  = $avgTotal
            "Moyenne mobile (qualité)" = $avgConfidence
        }
    }

    # Créer un graphique pour les moyennes mobiles
    $movingAvgData = @{
        ChartType = "Line"
        Labels    = $movingAverages."Date"
        Series    = @{
            "Volume quotidien"         = $dailyData | Select-Object -Skip ($windowSize - 1) | ForEach-Object { $_.TotalCount }
            "Moyenne mobile (7 jours)" = $movingAverages."Moyenne mobile (volume)"
        }
        Options   = @{
            Title  = "Volume quotidien vs. Moyenne mobile (7 jours)"
            Colors = @("#e15759", "#4e79a7")
            Smooth = $true
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Volume quotidien vs. Moyenne mobile (7 jours)" -Data $movingAvgData -ChartType "Line" -Options @{
        Smooth = $true
    }

    # Ajouter une section de conclusion
    $conclusionText = @"
## Synthèse de l'analyse temporelle

L'analyse temporelle des extractions sur la période de $MonthsOfData mois révèle plusieurs tendances et patterns significatifs :

1. **Tendance générale** : On observe une tendance $(if (($monthlyData[-1].TotalCount - $monthlyData[0].TotalCount) -gt 0) { "à la hausse" } else { "à la baisse" }) du volume d'extractions sur l'ensemble de la période.

2. **Variations saisonnières** : Les mois d'été (juin-août) présentent généralement des volumes d'extraction plus élevés, tandis que les mois d'hiver (décembre-février) montrent des volumes plus faibles.

3. **Impact des événements** : Les événements majeurs identifiés ont eu un impact significatif sur le volume et la qualité des extractions, notamment :
   - "$($specialEvents[0].Name)" qui a entraîné une augmentation de $(($specialEvents[0].Impact - 1) * 100)% du volume d'extraction
   - "$($specialEvents[1].Name)" qui a entraîné une augmentation de $(($specialEvents[1].Impact - 1) * 100)% du volume d'extraction

4. **Qualité des extractions** : La qualité moyenne des extractions (mesurée par le score de confiance) est restée relativement $(if ([math]::Abs(($monthlyData[-1].AvgConfidence - $monthlyData[0].AvgConfidence)) -lt 5) { "stable" } else { if (($monthlyData[-1].AvgConfidence - $monthlyData[0].AvgConfidence) -gt 0) { "en amélioration" } else { "en diminution" } }) sur la période.

## Recommandations

Sur la base de cette analyse temporelle, voici quelques recommandations :

1. **Planification des ressources** : Ajuster les ressources d'extraction en fonction des variations saisonnières identifiées.
2. **Optimisation des processus** : Capitaliser sur les améliorations observées suite aux événements "$($specialEvents[1].Name)" et "$($specialEvents[3].Name)".
3. **Surveillance continue** : Mettre en place un suivi régulier des indicateurs de progression pour détecter rapidement les anomalies.
4. **Analyse approfondie** : Réaliser une analyse plus détaillée des périodes présentant des variations significatives pour identifier les facteurs sous-jacents.
"@

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Conclusion et recommandations" -Content $conclusionText -Type "Text" -Level 1

    # Exporter le rapport avec des graphiques interactifs
    $htmlPath = Join-Path -Path $OutputFolder -ChildPath "time_analysis_report.html"
    Export-ExtractedInfoReportToHtml -Report $report -OutputPath $htmlPath -Theme "Light"

    Write-Host "Rapport d'analyse temporelle généré avec succès : $htmlPath"

    return $report
}

# Exemple d'utilisation
# Example-TimeAnalysisReport -OutputFolder "C:\Temp\Reports" -MonthsOfData 6

<#
.SYNOPSIS
Exporte un rapport d'information extraite au format PDF.

.DESCRIPTION
La fonction Export-ExtractedInfoReportToPdf exporte un rapport d'information extraite
au format PDF. Elle utilise une conversion HTML vers PDF pour générer le fichier PDF.

.PARAMETER Report
Le rapport à exporter.

.PARAMETER OutputPath
Le chemin du fichier de sortie.

.PARAMETER PageSize
La taille de la page. Les valeurs possibles sont "A4", "Letter", "Legal", etc.
Par défaut, "A4".

.PARAMETER Orientation
L'orientation de la page. Les valeurs possibles sont "Portrait" et "Landscape".
Par défaut, "Portrait".

.PARAMETER Margins
Les marges de la page en millimètres (tableau avec Top, Right, Bottom, Left).
Par défaut, @(10, 10, 10, 10).

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de données"
$report = Add-ExtractedInfoReportSection -Report $report -Title "Introduction" -Content "Ce rapport présente une analyse détaillée..." -Type "Text"
Export-ExtractedInfoReportToPdf -Report $report -OutputPath "C:\Temp\rapport.pdf"

.NOTES
Cette fonction nécessite l'installation de wkhtmltopdf (https://wkhtmltopdf.org/) ou
une autre bibliothèque de conversion HTML vers PDF.
#>
function Export-ExtractedInfoReportToPdf {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("A4", "Letter", "Legal", "A3", "A5")]
        [string]$PageSize = "A4",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Portrait", "Landscape")]
        [string]$Orientation = "Portrait",

        [Parameter(Mandatory = $false)]
        [int[]]$Margins = @(10, 10, 10, 10)
    )

    # Validation des paramètres
    if ($null -eq $Report -or -not $Report.ContainsKey("Metadata")) {
        throw "Le rapport fourni n'est pas valide."
    }

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        throw "Le chemin de sortie ne peut pas être vide."
    }

    # Créer le dossier de sortie s'il n'existe pas
    $outputFolder = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputFolder) -and -not (Test-Path -Path $outputFolder)) {
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    }

    # Générer un fichier HTML temporaire
    $tempHtmlPath = [System.IO.Path]::GetTempFileName() + ".html"

    # Exporter le rapport au format HTML
    Export-ExtractedInfoReportToHtml -Report $Report -OutputPath $tempHtmlPath -Theme "Default"

    # Vérifier si wkhtmltopdf est installé
    $wkhtmltopdfPath = $null

    # Rechercher wkhtmltopdf dans le PATH
    $wkhtmltopdfCommand = Get-Command "wkhtmltopdf" -ErrorAction SilentlyContinue
    if ($null -ne $wkhtmltopdfCommand) {
        $wkhtmltopdfPath = $wkhtmltopdfCommand.Source
    } else {
        # Rechercher dans les emplacements courants
        $possiblePaths = @(
            "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe",
            "C:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe",
            "${env:ProgramFiles}\wkhtmltopdf\bin\wkhtmltopdf.exe",
            "${env:ProgramFiles(x86)}\wkhtmltopdf\bin\wkhtmltopdf.exe"
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path -Path $path) {
                $wkhtmltopdfPath = $path
                break
            }
        }
    }

    if ($null -eq $wkhtmltopdfPath) {
        Write-Warning "wkhtmltopdf n'est pas installé. Utilisation d'une méthode alternative."

        # Méthode alternative : utiliser le module PSWriteHTML s'il est disponible
        $psWriteHtmlModule = Get-Module -Name PSWriteHTML -ListAvailable

        if ($null -ne $psWriteHtmlModule) {
            Write-Verbose "Utilisation du module PSWriteHTML pour la conversion HTML vers PDF."

            # Importer le module
            Import-Module PSWriteHTML

            # Lire le contenu HTML
            $htmlContent = Get-Content -Path $tempHtmlPath -Raw

            # Convertir en PDF avec PSWriteHTML
            $htmlContent | ConvertTo-PDF -OutputPath $OutputPath -Options @{
                PageSize     = $PageSize
                Orientation  = $Orientation
                MarginTop    = $Margins[0]
                MarginRight  = $Margins[1]
                MarginBottom = $Margins[2]
                MarginLeft   = $Margins[3]
            }
        } else {
            # Méthode de secours : utiliser System.Windows.Forms.WebBrowser
            Write-Verbose "Utilisation de System.Windows.Forms.WebBrowser pour la conversion HTML vers PDF."

            # Charger les assemblies nécessaires
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type -AssemblyName System.Drawing

            # Créer un WebBrowser
            $webBrowser = New-Object System.Windows.Forms.WebBrowser
            $webBrowser.ScrollBarsEnabled = $false
            $webBrowser.ScriptErrorsSuppressed = $true

            # Définir la taille du WebBrowser selon le format de page
            $pageSizes = @{
                "A4"     = @{Width = 210; Height = 297 }
                "Letter" = @{Width = 216; Height = 279 }
                "Legal"  = @{Width = 216; Height = 356 }
                "A3"     = @{Width = 297; Height = 420 }
                "A5"     = @{Width = 148; Height = 210 }
            }

            $pageWidth = $pageSizes[$PageSize].Width
            $pageHeight = $pageSizes[$PageSize].Height

            if ($Orientation -eq "Landscape") {
                $temp = $pageWidth
                $pageWidth = $pageHeight
                $pageHeight = $temp
            }

            # Convertir mm en pixels (approximativement 3.8 pixels par mm à 96 DPI)
            $widthInPixels = $pageWidth * 3.8
            $heightInPixels = $pageHeight * 3.8

            $webBrowser.Width = $widthInPixels
            $webBrowser.Height = $heightInPixels

            # Charger le HTML
            $webBrowser.Navigate("file:///$tempHtmlPath")

            # Attendre que la page soit chargée
            while ($webBrowser.ReadyState -ne 4) {
                Start-Sleep -Milliseconds 100
            }

            # Créer une image de la page
            $bitmap = New-Object System.Drawing.Bitmap $webBrowser.Width, $webBrowser.Height
            $webBrowser.DrawToBitmap($bitmap, (New-Object System.Drawing.Rectangle 0, 0, $webBrowser.Width, $webBrowser.Height))

            # Sauvegarder l'image en PDF
            $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Pdf)

            # Libérer les ressources
            $bitmap.Dispose()
            $webBrowser.Dispose()
        }
    } else {
        Write-Verbose "Utilisation de wkhtmltopdf pour la conversion HTML vers PDF."

        # Construire les arguments pour wkhtmltopdf
        $wkhtmltopdfArgs = @(
            "--page-size", $PageSize,
            "--orientation", $Orientation,
            "--margin-top", "$($Margins[0])mm",
            "--margin-right", "$($Margins[1])mm",
            "--margin-bottom", "$($Margins[2])mm",
            "--margin-left", "$($Margins[3])mm",
            "--encoding", "UTF-8",
            "--enable-local-file-access",
            $tempHtmlPath,
            $OutputPath
        )

        # Exécuter wkhtmltopdf
        & $wkhtmltopdfPath $wkhtmltopdfArgs
    }

    # Supprimer le fichier HTML temporaire
    if (Test-Path -Path $tempHtmlPath) {
        Remove-Item -Path $tempHtmlPath -Force
    }

    return $OutputPath
}

<#
.SYNOPSIS
Exporte un rapport d'information extraite au format Excel.

.DESCRIPTION
La fonction Export-ExtractedInfoReportToExcel exporte un rapport d'information extraite
au format Excel. Elle crée un classeur Excel avec plusieurs feuilles pour les différentes
sections du rapport, y compris des graphiques si demandé.

.PARAMETER Report
Le rapport à exporter.

.PARAMETER OutputPath
Le chemin du fichier de sortie.

.PARAMETER IncludeCharts
Indique si les graphiques doivent être inclus dans le fichier Excel.
Par défaut, $true.

.PARAMETER WorksheetName
Le nom de la feuille principale du classeur Excel.
Par défaut, "Rapport".

.PARAMETER AutoFilter
Indique si des filtres automatiques doivent être ajoutés aux tableaux.
Par défaut, $true.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de données"
$report = Add-ExtractedInfoReportSection -Report $report -Title "Données" -Content $data -Type "Table"
Export-ExtractedInfoReportToExcel -Report $report -OutputPath "C:\Temp\rapport.xlsx"

.NOTES
Cette fonction nécessite le module ImportExcel pour fonctionner correctement.
Si le module n'est pas disponible, une version simplifiée sera utilisée.
#>
function Export-ExtractedInfoReportToExcel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCharts = $true,

        [Parameter(Mandatory = $false)]
        [string]$WorksheetName = "Rapport",

        [Parameter(Mandatory = $false)]
        [switch]$AutoFilter = $true
    )

    # Validation des paramètres
    if ($null -eq $Report -or -not $Report.ContainsKey("Metadata")) {
        throw "Le rapport fourni n'est pas valide."
    }

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        throw "Le chemin de sortie ne peut pas être vide."
    }

    # Créer le dossier de sortie s'il n'existe pas
    $outputFolder = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputFolder) -and -not (Test-Path -Path $outputFolder)) {
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    }

    # Vérifier si le module ImportExcel est disponible
    $importExcelAvailable = $false
    $importExcelModule = Get-Module -Name ImportExcel -ListAvailable

    if ($null -ne $importExcelModule) {
        $importExcelAvailable = $true
        Import-Module ImportExcel
    } else {
        Write-Warning "Le module ImportExcel n'est pas disponible. Utilisation d'une méthode alternative."
    }

    # Fonction pour créer un classeur Excel avec le module ImportExcel
    function New-ExcelWorkbookWithImportExcel {
        param (
            [Parameter(Mandatory = $true)]
            [hashtable]$Report,

            [Parameter(Mandatory = $true)]
            [string]$OutputPath,

            [Parameter(Mandatory = $false)]
            [switch]$IncludeCharts = $true,

            [Parameter(Mandatory = $false)]
            [string]$WorksheetName = "Rapport",

            [Parameter(Mandatory = $false)]
            [switch]$AutoFilter = $true
        )

        # Créer une feuille pour les informations générales
        $excelPackage = New-ExcelPackage -Path $OutputPath

        # Ajouter une feuille d'informations
        $infoSheet = Add-ExcelWorksheet -ExcelPackage $excelPackage -WorksheetName "Informations"

        # Ajouter les informations du rapport
        $row = 1
        Add-ExcelRow -Worksheet $infoSheet -Row $row -Value @("Titre:", $Report.Metadata.Title) -Bold
        $row++
        Add-ExcelRow -Worksheet $infoSheet -Row $row -Value @("Description:", $Report.Metadata.Description)
        $row++
        Add-ExcelRow -Worksheet $infoSheet -Row $row -Value @("Auteur:", $Report.Metadata.Author)
        $row++
        Add-ExcelRow -Worksheet $infoSheet -Row $row -Value @("Date:", $Report.Metadata.Date.ToString("dd/MM/yyyy"))
        $row++
        Add-ExcelRow -Worksheet $infoSheet -Row $row -Value @("Type:", $Report.Metadata.Type)
        $row++
        Add-ExcelRow -Worksheet $infoSheet -Row $row -Value @("ID:", $Report.Metadata.Id)
        $row++

        if ($Report.Metadata.ContainsKey("Tags") -and $Report.Metadata.Tags.Count -gt 0) {
            Add-ExcelRow -Worksheet $infoSheet -Row $row -Value @("Tags:", ($Report.Metadata.Tags -join ", "))
            $row++
        }

        # Formater la feuille d'informations
        Set-ExcelRange -Worksheet $infoSheet -Range "A1:A$($row-1)" -Bold
        Set-ExcelRange -Worksheet $infoSheet -Range "A1:B1" -BackgroundColor LightBlue

        # Ajuster la largeur des colonnes
        Set-ExcelColumn -Worksheet $infoSheet -Column 1 -Width 15
        Set-ExcelColumn -Worksheet $infoSheet -Column 2 -Width 50

        # Ajouter une feuille pour chaque section de type Table
        $tableSections = $Report.Sections | Where-Object { $_.Type -eq "Table" }

        foreach ($section in $tableSections) {
            # Créer un nom de feuille valide (max 31 caractères, pas de caractères spéciaux)
            $sheetName = $section.Title -replace '[\\\/\[\]\:\*\?]', '_'
            if ($sheetName.Length -gt 31) {
                $sheetName = $sheetName.Substring(0, 28) + "..."
            }

            # Vérifier si le nom de la feuille existe déjà
            $counter = 1
            $originalSheetName = $sheetName
            while ($excelPackage.Workbook.Worksheets | Where-Object { $_.Name -eq $sheetName }) {
                $sheetName = "$originalSheetName$counter"
                if ($sheetName.Length -gt 31) {
                    $sheetName = $originalSheetName.Substring(0, 28 - $counter.ToString().Length) + "..." + $counter
                }
                $counter++
            }

            # Créer la feuille
            $tableSheet = Add-ExcelWorksheet -ExcelPackage $excelPackage -WorksheetName $sheetName

            # Ajouter le titre de la section
            Add-ExcelRow -Worksheet $tableSheet -Row 1 -Value @($section.Title) -Bold
            Set-ExcelRange -Worksheet $tableSheet -Range "A1" -FontSize 14

            # Déterminer les en-têtes de colonnes
            $headers = @()
            if ($section.ContainsKey("Headers") -and $section.Headers.Count -gt 0) {
                $headers = $section.Headers
            } elseif ($section.Content.Count -gt 0) {
                if ($section.Content[0] -is [PSObject]) {
                    $headers = $section.Content[0].PSObject.Properties.Name
                } elseif ($section.Content[0] -is [hashtable]) {
                    $headers = $section.Content[0].Keys
                }
            }

            # Ajouter les en-têtes de colonnes
            if ($headers.Count -gt 0) {
                Add-ExcelRow -Worksheet $tableSheet -Row 3 -Value $headers -Bold
                Set-ExcelRange -Worksheet $tableSheet -Range "A3:$([char](64 + $headers.Count))3" -BackgroundColor LightGray

                # Ajouter les données
                $row = 4
                foreach ($item in $section.Content) {
                    $rowData = @()

                    if ($item -is [PSObject]) {
                        foreach ($header in $headers) {
                            $rowData += $item.$header
                        }
                    } elseif ($item -is [hashtable]) {
                        foreach ($header in $headers) {
                            $rowData += $item[$header]
                        }
                    } else {
                        $rowData += $item
                    }

                    Add-ExcelRow -Worksheet $tableSheet -Row $row -Value $rowData
                    $row++
                }

                # Ajouter un filtre automatique si demandé
                if ($AutoFilter) {
                    Add-ExcelFilter -Worksheet $tableSheet -Range "A3:$([char](64 + $headers.Count))$($row-1)"
                }

                # Ajuster la largeur des colonnes
                for ($i = 1; $i -le $headers.Count; $i++) {
                    Set-ExcelColumn -Worksheet $tableSheet -Column $i -AutoFit
                }

                # Ajouter une mise en forme conditionnelle pour les colonnes numériques
                for ($i = 0; $i -lt $headers.Count; $i++) {
                    $columnLetter = [char](65 + $i)
                    $columnRange = "$columnLetter`4:$columnLetter`$($row-1)"

                    # Vérifier si la colonne contient des valeurs numériques
                    $hasNumericValues = $false
                    foreach ($item in $section.Content) {
                        $value = if ($item -is [PSObject]) { $item.($headers[$i]) } else { $item[$headers[$i]] }
                        if ($value -is [int] -or $value -is [double] -or $value -is [decimal]) {
                            $hasNumericValues = $true
                            break
                        }
                    }

                    if ($hasNumericValues) {
                        # Appliquer une mise en forme conditionnelle
                        Add-ConditionalFormatting -Worksheet $tableSheet -Range $columnRange -DataBarColor Green
                    }
                }
            }
        }

        # Ajouter une feuille pour les graphiques si demandé
        if ($IncludeCharts) {
            $chartSections = $Report.Sections | Where-Object { $_.Type -eq "Chart" }

            if ($chartSections.Count -gt 0) {
                $chartSheet = Add-ExcelWorksheet -ExcelPackage $excelPackage -WorksheetName "Graphiques"

                # Ajouter le titre de la feuille
                Add-ExcelRow -Worksheet $chartSheet -Row 1 -Value @("Graphiques") -Bold
                Set-ExcelRange -Worksheet $chartSheet -Range "A1" -FontSize 14

                $chartRow = 3
                $chartCol = 1

                foreach ($section in $chartSections) {
                    # Ajouter le titre du graphique
                    Add-ExcelRow -Worksheet $chartSheet -Row $chartRow -Value @($section.Title) -Bold
                    $chartRow += 2

                    # Préparer les données du graphique
                    $chartData = $section.Content
                    $chartType = $chartData.ChartType

                    # Ajouter les données du graphique
                    $dataStartRow = $chartRow

                    switch ($chartType) {
                        "Bar" {
                            # Ajouter les en-têtes
                            Add-ExcelRow -Worksheet $chartSheet -Row $chartRow -Value @("Catégorie", "Valeur") -Bold
                            $chartRow++

                            # Ajouter les données
                            if ($chartData.ContainsKey("Labels") -and $chartData.ContainsKey("Values")) {
                                for ($i = 0; $i -lt $chartData.Labels.Count; $i++) {
                                    Add-ExcelRow -Worksheet $chartSheet -Row $chartRow -Value @($chartData.Labels[$i], $chartData.Values[$i])
                                    $chartRow++
                                }

                                # Créer le graphique
                                $chartDef = New-ExcelChartDefinition -Title $section.Title -ChartType ColumnClustered `
                                    -XRange "A$($dataStartRow+1):A$($chartRow-1)" -YRange "B$($dataStartRow+1):B$($chartRow-1)" `
                                    -Width 500 -Height 300 -Row ($chartRow + 1) -Column 1

                                Add-ExcelChart -Worksheet $chartSheet -ChartDefinition $chartDef
                                $chartRow += 20
                            }
                        }
                        "Pie" {
                            # Ajouter les en-têtes
                            Add-ExcelRow -Worksheet $chartSheet -Row $chartRow -Value @("Catégorie", "Valeur") -Bold
                            $chartRow++

                            # Ajouter les données
                            if ($chartData.ContainsKey("Labels") -and $chartData.ContainsKey("Values")) {
                                for ($i = 0; $i -lt $chartData.Labels.Count; $i++) {
                                    Add-ExcelRow -Worksheet $chartSheet -Row $chartRow -Value @($chartData.Labels[$i], $chartData.Values[$i])
                                    $chartRow++
                                }

                                # Créer le graphique
                                $chartDef = New-ExcelChartDefinition -Title $section.Title -ChartType Pie `
                                    -XRange "A$($dataStartRow+1):A$($chartRow-1)" -YRange "B$($dataStartRow+1):B$($chartRow-1)" `
                                    -Width 500 -Height 300 -Row ($chartRow + 1) -Column 1

                                Add-ExcelChart -Worksheet $chartSheet -ChartDefinition $chartDef
                                $chartRow += 20
                            }
                        }
                        "Line" {
                            # Ajouter les en-têtes
                            $headers = @("Catégorie")
                            if ($chartData.ContainsKey("Series")) {
                                $headers += $chartData.Series.Keys
                            } else {
                                $headers += "Valeur"
                            }

                            Add-ExcelRow -Worksheet $chartSheet -Row $chartRow -Value $headers -Bold
                            $chartRow++

                            # Ajouter les données
                            if ($chartData.ContainsKey("Labels")) {
                                for ($i = 0; $i -lt $chartData.Labels.Count; $i++) {
                                    $rowData = @($chartData.Labels[$i])

                                    if ($chartData.ContainsKey("Series")) {
                                        foreach ($seriesKey in $chartData.Series.Keys) {
                                            $rowData += $chartData.Series[$seriesKey][$i]
                                        }
                                    } else {
                                        $rowData += $chartData.Values[$i]
                                    }

                                    Add-ExcelRow -Worksheet $chartSheet -Row $chartRow -Value $rowData
                                    $chartRow++
                                }

                                # Créer le graphique
                                $chartDef = New-ExcelChartDefinition -Title $section.Title -ChartType Line `
                                    -XRange "A$($dataStartRow+1):A$($chartRow-1)" -YRange "B$($dataStartRow+1):$([char](65 + $headers.Count - 1))$($chartRow-1)" `
                                    -Width 500 -Height 300 -Row ($chartRow + 1) -Column 1

                                Add-ExcelChart -Worksheet $chartSheet -ChartDefinition $chartDef
                                $chartRow += 20
                            }
                        }
                        # Autres types de graphiques...
                    }

                    $chartRow += 2
                }
            }
        }

        # Sauvegarder le classeur Excel
        Close-ExcelPackage -ExcelPackage $excelPackage
    }

    # Fonction pour créer un classeur Excel sans le module ImportExcel
    function New-ExcelWorkbookWithoutImportExcel {
        param (
            [Parameter(Mandatory = $true)]
            [hashtable]$Report,

            [Parameter(Mandatory = $true)]
            [string]$OutputPath
        )

        # Créer un objet COM Excel
        try {
            $excel = New-Object -ComObject Excel.Application
            $excel.Visible = $false
            $excel.DisplayAlerts = $false

            $workbook = $excel.Workbooks.Add()

            # Ajouter une feuille d'informations
            $infoSheet = $workbook.Worksheets.Item(1)
            $infoSheet.Name = "Informations"

            # Ajouter les informations du rapport
            $infoSheet.Cells.Item(1, 1).Value = "Titre:"
            $infoSheet.Cells.Item(1, 2).Value = $Report.Metadata.Title
            $infoSheet.Cells.Item(2, 1).Value = "Description:"
            $infoSheet.Cells.Item(2, 2).Value = $Report.Metadata.Description
            $infoSheet.Cells.Item(3, 1).Value = "Auteur:"
            $infoSheet.Cells.Item(3, 2).Value = $Report.Metadata.Author
            $infoSheet.Cells.Item(4, 1).Value = "Date:"
            $infoSheet.Cells.Item(4, 2).Value = $Report.Metadata.Date.ToString("dd/MM/yyyy")
            $infoSheet.Cells.Item(5, 1).Value = "Type:"
            $infoSheet.Cells.Item(5, 2).Value = $Report.Metadata.Type
            $infoSheet.Cells.Item(6, 1).Value = "ID:"
            $infoSheet.Cells.Item(6, 2).Value = $Report.Metadata.Id

            if ($Report.Metadata.ContainsKey("Tags") -and $Report.Metadata.Tags.Count -gt 0) {
                $infoSheet.Cells.Item(7, 1).Value = "Tags:"
                $infoSheet.Cells.Item(7, 2).Value = ($Report.Metadata.Tags -join ", ")
            }

            # Formater la feuille d'informations
            $infoSheet.Range("A1:A7").Font.Bold = $true
            $infoSheet.Range("A1:B1").Interior.ColorIndex = 37

            # Ajuster la largeur des colonnes
            $infoSheet.Columns.Item(1).ColumnWidth = 15
            $infoSheet.Columns.Item(2).ColumnWidth = 50

            # Ajouter une feuille pour chaque section de type Table
            $tableSections = $Report.Sections | Where-Object { $_.Type -eq "Table" }
            $sheetIndex = 2

            foreach ($section in $tableSections) {
                # Créer un nom de feuille valide (max 31 caractères, pas de caractères spéciaux)
                $sheetName = $section.Title -replace '[\\\/\[\]\:\*\?]', '_'
                if ($sheetName.Length -gt 31) {
                    $sheetName = $sheetName.Substring(0, 28) + "..."
                }

                # Ajouter une nouvelle feuille
                $tableSheet = $workbook.Worksheets.Add()
                $tableSheet.Name = $sheetName

                # Ajouter le titre de la section
                $tableSheet.Cells.Item(1, 1).Value = $section.Title
                $tableSheet.Cells.Item(1, 1).Font.Bold = $true
                $tableSheet.Cells.Item(1, 1).Font.Size = 14

                # Déterminer les en-têtes de colonnes
                $headers = @()
                if ($section.ContainsKey("Headers") -and $section.Headers.Count -gt 0) {
                    $headers = $section.Headers
                } elseif ($section.Content.Count -gt 0) {
                    if ($section.Content[0] -is [PSObject]) {
                        $headers = $section.Content[0].PSObject.Properties.Name
                    } elseif ($section.Content[0] -is [hashtable]) {
                        $headers = $section.Content[0].Keys
                    }
                }

                # Ajouter les en-têtes de colonnes
                if ($headers.Count -gt 0) {
                    for ($i = 0; $i -lt $headers.Count; $i++) {
                        $tableSheet.Cells.Item(3, $i + 1).Value = $headers[$i]
                        $tableSheet.Cells.Item(3, $i + 1).Font.Bold = $true
                    }

                    $headerRange = $tableSheet.Range($tableSheet.Cells.Item(3, 1), $tableSheet.Cells.Item(3, $headers.Count))
                    $headerRange.Interior.ColorIndex = 15

                    # Ajouter les données
                    $row = 4
                    foreach ($item in $section.Content) {
                        for ($i = 0; $i -lt $headers.Count; $i++) {
                            $value = if ($item -is [PSObject]) { $item.($headers[$i]) } else { $item[$headers[$i]] }
                            $tableSheet.Cells.Item($row, $i + 1).Value = $value
                        }
                        $row++
                    }

                    # Ajouter un filtre automatique si demandé
                    if ($AutoFilter) {
                        $dataRange = $tableSheet.Range($tableSheet.Cells.Item(3, 1), $tableSheet.Cells.Item($row - 1, $headers.Count))
                        $dataRange.AutoFilter()
                    }

                    # Ajuster la largeur des colonnes
                    for ($i = 1; $i -le $headers.Count; $i++) {
                        $tableSheet.Columns.Item($i).AutoFit()
                    }
                }

                $sheetIndex++
            }

            # Sauvegarder le classeur Excel
            $workbook.SaveAs($OutputPath)
            $workbook.Close($true)
            $excel.Quit()

            # Libérer les ressources COM
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        } catch {
            Write-Error "Erreur lors de la création du classeur Excel : $_"

            # Essayer de libérer les ressources COM en cas d'erreur
            if ($null -ne $workbook) {
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
            }

            if ($null -ne $excel) {
                $excel.Quit()
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
            }

            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()

            throw
        }
    }

    # Créer le classeur Excel
    if ($importExcelAvailable) {
        New-ExcelWorkbookWithImportExcel -Report $Report -OutputPath $OutputPath -IncludeCharts:$IncludeCharts -WorksheetName $WorksheetName -AutoFilter:$AutoFilter
    } else {
        New-ExcelWorkbookWithoutImportExcel -Report $Report -OutputPath $OutputPath
    }

    return $OutputPath
}
