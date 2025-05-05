#Requires -Version 5.1
<#
.SYNOPSIS
Module pour la gestion des tableaux dans les rapports d'information extraite.

.DESCRIPTION
Ce module contient les fonctions pour ajouter et manipuler des tableaux dans les rapports
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
Ajoute un tableau à un rapport d'information extraite.

.DESCRIPTION
La fonction Add-ExtractedInfoReportTable ajoute un tableau à un rapport d'information extraite.

.PARAMETER Report
Le rapport auquel ajouter le tableau.

.PARAMETER Title
Le titre du tableau.

.PARAMETER Data
Les données du tableau. Peut être un tableau d'objets, une collection ou un tableau de tableaux.

.PARAMETER Headers
Les en-têtes du tableau. Si non spécifié, ils seront extraits des propriétés des objets.

.PARAMETER Options
Options supplémentaires pour le tableau (style, tri, etc.).

.PARAMETER Level
Le niveau de la section (1 à 4). Utilisé pour la numérotation hiérarchique.
Par défaut, 1.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de données"
$data = @(
    [PSCustomObject]@{ Name = "John"; Age = 30; City = "New York" },
    [PSCustomObject]@{ Name = "Jane"; Age = 25; City = "Boston" },
    [PSCustomObject]@{ Name = "Bob"; Age = 40; City = "Chicago" }
)
$report = Add-ExtractedInfoReportTable -Report $report -Title "Liste des personnes" -Data $data

.NOTES
Cette fonction crée une section de type Table dans le rapport et configure
les données pour le rendu du tableau.
#>
function Add-ExtractedInfoReportTable {
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
        [string[]]$Headers,

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
        throw "Le titre du tableau ne peut pas être vide."
    }

    if ($null -eq $Data) {
        throw "Les données du tableau ne peuvent pas être null."
    }

    # Vérifier que les données sont un tableau ou une collection
    if (-not ($Data -is [array] -or $Data -is [System.Collections.IEnumerable])) {
        throw "Les données du tableau doivent être un tableau ou une collection."
    }

    # Préparer les données du tableau
    $tableData = @{
        Data    = $Data
        Options = $Options
    }

    # Ajouter les en-têtes si spécifiés
    if ($PSBoundParameters.ContainsKey("Headers")) {
        $tableData["Headers"] = $Headers
    }
    # Sinon, essayer de les extraire des propriétés des objets
    elseif ($Data.Count -gt 0 -and $Data[0] -is [PSObject]) {
        $tableData["Headers"] = $Data[0].PSObject.Properties.Name
    }

    # Ajouter des options par défaut si nécessaire
    if (-not $Options.ContainsKey("Striped")) {
        $tableData.Options["Striped"] = $true
    }

    if (-not $Options.ContainsKey("Bordered")) {
        $tableData.Options["Bordered"] = $true
    }

    if (-not $Options.ContainsKey("Hover")) {
        $tableData.Options["Hover"] = $true
    }

    if (-not $Options.ContainsKey("Responsive")) {
        $tableData.Options["Responsive"] = $true
    }

    # Ajouter le tableau comme une section au rapport
    return Add-ExtractedInfoReportSection -Report $Report -Title $Title -Content $tableData -Type "Table" -Level $Level
}

<#
.SYNOPSIS
Ajoute un tableau de statistiques à un rapport d'information extraite.

.DESCRIPTION
La fonction Add-ExtractedInfoReportStatsTable ajoute un tableau de statistiques à un rapport d'information extraite.
Elle calcule automatiquement des statistiques de base (min, max, moyenne, etc.) sur les données numériques.

.PARAMETER Report
Le rapport auquel ajouter le tableau.

.PARAMETER Title
Le titre du tableau.

.PARAMETER Data
Les données pour lesquelles calculer les statistiques. Doit être un tableau d'objets avec des propriétés numériques.

.PARAMETER Properties
Les propriétés sur lesquelles calculer les statistiques. Si non spécifié, toutes les propriétés numériques seront utilisées.

.PARAMETER Statistics
Les statistiques à calculer. Par défaut : Min, Max, Average, Sum, Count.

.PARAMETER Level
Le niveau de la section (1 à 4). Utilisé pour la numérotation hiérarchique.
Par défaut, 1.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de données"
$data = @(
    [PSCustomObject]@{ Name = "John"; Age = 30; Salary = 50000 },
    [PSCustomObject]@{ Name = "Jane"; Age = 25; Salary = 60000 },
    [PSCustomObject]@{ Name = "Bob"; Age = 40; Salary = 70000 }
)
$report = Add-ExtractedInfoReportStatsTable -Report $report -Title "Statistiques" -Data $data -Properties @("Age", "Salary")

.NOTES
Cette fonction calcule automatiquement des statistiques sur les données numériques
et les présente dans un tableau.
#>
function Add-ExtractedInfoReportStatsTable {
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
        [string[]]$Properties,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Min", "Max", "Average", "Sum", "Count", "Median", "StdDev")]
        [string[]]$Statistics = @("Min", "Max", "Average", "Sum", "Count"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 4)]
        [int]$Level = 1
    )

    # Validation des paramètres
    if ($null -eq $Report -or -not $Report.ContainsKey("Sections")) {
        throw "Le rapport fourni n'est pas valide."
    }

    if ([string]::IsNullOrWhiteSpace($Title)) {
        throw "Le titre du tableau ne peut pas être vide."
    }

    if ($null -eq $Data -or $Data.Count -eq 0) {
        throw "Les données ne peuvent pas être null ou vides."
    }

    # Vérifier que les données sont un tableau d'objets
    if (-not ($Data -is [array] -and $Data[0] -is [PSObject])) {
        throw "Les données doivent être un tableau d'objets."
    }

    # Si les propriétés ne sont pas spécifiées, utiliser toutes les propriétés numériques
    if (-not $PSBoundParameters.ContainsKey("Properties")) {
        $Properties = $Data[0].PSObject.Properties | Where-Object {
            $value = $Data[0].($_.Name)
            $value -is [int] -or $value -is [double] -or $value -is [decimal] -or $value -is [long]
        } | Select-Object -ExpandProperty Name
    }

    # Vérifier qu'il y a au moins une propriété numérique
    if ($Properties.Count -eq 0) {
        throw "Aucune propriété numérique trouvée dans les données."
    }

    # Calculer les statistiques
    $statsData = @()
    foreach ($property in $Properties) {
        $values = $Data | ForEach-Object { $_.$property }
        
        # Vérifier que les valeurs sont numériques
        if ($values | Where-Object { -not ($_ -is [int] -or $_ -is [double] -or $_ -is [decimal] -or $_ -is [long]) }) {
            Write-Warning "La propriété '$property' contient des valeurs non numériques. Les statistiques peuvent être incorrectes."
        }

        $stats = [PSCustomObject]@{
            Property = $property
        }

        # Calculer chaque statistique demandée
        foreach ($stat in $Statistics) {
            switch ($stat) {
                "Min" {
                    $stats | Add-Member -MemberType NoteProperty -Name "Min" -Value ($values | Measure-Object -Minimum).Minimum
                }
                "Max" {
                    $stats | Add-Member -MemberType NoteProperty -Name "Max" -Value ($values | Measure-Object -Maximum).Maximum
                }
                "Average" {
                    $stats | Add-Member -MemberType NoteProperty -Name "Average" -Value ($values | Measure-Object -Average).Average
                }
                "Sum" {
                    $stats | Add-Member -MemberType NoteProperty -Name "Sum" -Value ($values | Measure-Object -Sum).Sum
                }
                "Count" {
                    $stats | Add-Member -MemberType NoteProperty -Name "Count" -Value ($values | Measure-Object).Count
                }
                "Median" {
                    $sortedValues = $values | Sort-Object
                    $count = $sortedValues.Count
                    if ($count -eq 0) {
                        $median = 0
                    }
                    elseif ($count % 2 -eq 0) {
                        $median = ($sortedValues[($count / 2) - 1] + $sortedValues[$count / 2]) / 2
                    }
                    else {
                        $median = $sortedValues[[math]::Floor($count / 2)]
                    }
                    $stats | Add-Member -MemberType NoteProperty -Name "Median" -Value $median
                }
                "StdDev" {
                    $avg = ($values | Measure-Object -Average).Average
                    $sumOfSquares = 0
                    foreach ($value in $values) {
                        $sumOfSquares += [math]::Pow($value - $avg, 2)
                    }
                    $stdDev = [math]::Sqrt($sumOfSquares / $values.Count)
                    $stats | Add-Member -MemberType NoteProperty -Name "StdDev" -Value $stdDev
                }
            }
        }

        $statsData += $stats
    }

    # Ajouter le tableau de statistiques au rapport
    return Add-ExtractedInfoReportTable -Report $Report -Title $Title -Data $statsData -Level $Level
}

# Exporter les fonctions
Export-ModuleMember -Function Add-ExtractedInfoReportTable, Add-ExtractedInfoReportStatsTable
