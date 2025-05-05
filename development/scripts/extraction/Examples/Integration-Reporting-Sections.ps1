#Requires -Version 5.1
<#
.SYNOPSIS
Module pour la gestion des sections dans les rapports d'information extraite.

.DESCRIPTION
Ce module contient les fonctions pour ajouter et manipuler des sections dans les rapports
d'information extraite.

.NOTES
Date de création : 2025-05-15
Auteur : Augment Code
Version : 1.0.0
#>

# Importer le module principal si nécessaire
# . "$PSScriptRoot\Integration-Reporting-Core.ps1"

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
Ajoute une section de texte à un rapport d'information extraite.

.DESCRIPTION
La fonction Add-ExtractedInfoReportTextSection est un wrapper autour de Add-ExtractedInfoReportSection
spécifiquement pour les sections de texte.

.PARAMETER Report
Le rapport auquel ajouter la section.

.PARAMETER Title
Le titre de la section.

.PARAMETER Text
Le texte à ajouter à la section.

.PARAMETER Level
Le niveau de la section (1 à 4). Utilisé pour la numérotation hiérarchique.
Par défaut, 1.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de texte"
$report = Add-ExtractedInfoReportTextSection -Report $report -Title "Introduction" -Text "Ce rapport présente une analyse détaillée..."

.NOTES
Cette fonction est un wrapper autour de Add-ExtractedInfoReportSection avec le type "Text".
#>
function Add-ExtractedInfoReportTextSection {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Title,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 4)]
        [int]$Level = 1
    )

    return Add-ExtractedInfoReportSection -Report $Report -Title $Title -Content $Text -Type "Text" -Level $Level
}

<#
.SYNOPSIS
Ajoute une section de liste à un rapport d'information extraite.

.DESCRIPTION
La fonction Add-ExtractedInfoReportListSection est un wrapper autour de Add-ExtractedInfoReportSection
spécifiquement pour les sections de liste.

.PARAMETER Report
Le rapport auquel ajouter la section.

.PARAMETER Title
Le titre de la section.

.PARAMETER Items
Les éléments de la liste.

.PARAMETER Level
Le niveau de la section (1 à 4). Utilisé pour la numérotation hiérarchique.
Par défaut, 1.

.EXAMPLE
$report = New-ExtractedInfoReport -Title "Rapport d'analyse de texte"
$items = @("Item 1", "Item 2", "Item 3")
$report = Add-ExtractedInfoReportListSection -Report $report -Title "Liste des éléments" -Items $items

.NOTES
Cette fonction est un wrapper autour de Add-ExtractedInfoReportSection avec le type "List".
#>
function Add-ExtractedInfoReportListSection {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Report,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Title,

        [Parameter(Mandatory = $true, Position = 2)]
        [array]$Items,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 4)]
        [int]$Level = 1
    )

    return Add-ExtractedInfoReportSection -Report $Report -Title $Title -Content $Items -Type "List" -Level $Level
}

# Exporter les fonctions
Export-ModuleMember -Function Add-ExtractedInfoReportSection, Add-ExtractedInfoReportTextSection, Add-ExtractedInfoReportListSection
