#Requires -Version 5.1
<#
.SYNOPSIS
Exemples d'utilisation du module d'intégration de reporting.

.DESCRIPTION
Ce script contient des exemples d'utilisation du module d'intégration de reporting
pour générer des rapports à partir des informations extraites.

.NOTES
Date de création : 2025-05-15
Auteur : Augment Code
Version : 1.0.0
#>

# Importer les modules nécessaires
# . "$PSScriptRoot\Integration-Reporting-Core.ps1"
# . "$PSScriptRoot\Integration-Reporting-Sections.ps1"
# . "$PSScriptRoot\Integration-Reporting-Charts.ps1"
# . "$PSScriptRoot\Integration-Reporting-Tables.ps1"
# . "$PSScriptRoot\Integration-Reporting-Export.ps1"

<#
.SYNOPSIS
Génère un rapport de collection d'informations extraites.

.DESCRIPTION
La fonction Show-CollectionReport génère un rapport pour une collection d'informations extraites.
Elle crée un rapport avec des sections textuelles, des tableaux et des graphiques.

.PARAMETER OutputFolder
Le dossier de sortie pour le rapport. Par défaut, le dossier temporaire.

.PARAMETER CollectionName
Le nom de la collection. Par défaut, "Collection d'exemple".

.PARAMETER ItemCount
Le nombre d'éléments à inclure dans le rapport. Par défaut, 10.

.EXAMPLE
Show-CollectionReport -OutputFolder "C:\Temp\Reports" -CollectionName "Ma collection" -ItemCount 20

.NOTES
Cette fonction est fournie à titre d'exemple et peut être adaptée selon vos besoins.
#>
function Show-CollectionReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = [System.IO.Path]::GetTempPath(),

        [Parameter(Mandatory = $false)]
        [string]$CollectionName = "Collection d'exemple",

        [Parameter(Mandatory = $false)]
        [int]$ItemCount = 10
    )

    # Créer un dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    # Générer des données d'exemple
    $collection = @{
        Name = $CollectionName
        Description = "Collection d'informations extraites générée pour démonstration"
        CreatedAt = Get-Date
        Items = @{}
    }

    # Générer des éléments d'exemple
    for ($i = 1; $i -le $ItemCount; $i++) {
        $itemId = [guid]::NewGuid().ToString()
        $isTextual = ($i % 3 -ne 0) # 2/3 des éléments sont textuels, 1/3 sont structurés

        if ($isTextual) {
            $collection.Items[$itemId] = @{
                _Type = "TextExtractedInfo"
                Id = $itemId
                Source = "document_$i.txt"
                Text = "Contenu textuel extrait du document $i. Ceci est un exemple de texte extrait."
                Language = if ($i % 5 -eq 0) { "en" } else { "fr" }
                ConfidenceScore = 70 + ($i % 30)
                ExtractedAt = (Get-Date).AddHours(-$i)
                ProcessingState = "Processed"
                Metadata = @{
                    Author = "Auteur " + ($i % 5 + 1)
                    Category = "Catégorie " + [char](65 + ($i % 5))
                    Tags = @("texte", "document", "exemple", "tag" + $i)
                }
            }
        }
        else {
            $collection.Items[$itemId] = @{
                _Type = "StructuredDataExtractedInfo"
                Id = $itemId
                Source = "data_$i.json"
                Data = @{
                    Id = $i
                    Name = "Élément $i"
                    Value = $i * 10
                    Properties = @{
                        Property1 = "Valeur 1.$i"
                        Property2 = "Valeur 2.$i"
                        Property3 = $i * 5
                    }
                }
                DataFormat = if ($i % 2 -eq 0) { "Json" } else { "Xml" }
                ConfidenceScore = 80 + ($i % 20)
                ExtractedAt = (Get-Date).AddHours(-$i).AddMinutes(-($i * 5))
                ProcessingState = "Processed"
                Metadata = @{
                    Source = if ($i % 2 -eq 0) { "API" } else { "File" }
                    Version = "1." + ($i % 10)
                    Tags = @("data", if ($i % 2 -eq 0) { "json" } else { "xml" }, "exemple", "tag" + $i)
                }
            }
        }
    }

    # Créer un nouveau rapport
    $report = New-ExtractedInfoReport -Title "Rapport de collection : $CollectionName" -Description "Ce rapport présente une analyse de la collection d'informations extraites." -Author "Système de reporting" -Type "Standard"

    # Ajouter une section d'introduction
    $report = Add-ExtractedInfoReportTextSection -Report $report -Title "Introduction" -Text "Ce rapport présente une analyse détaillée de la collection d'informations extraites nommée '$CollectionName'. La collection contient $($collection.Items.Count) éléments, créée le $($collection.CreatedAt.ToString('dd/MM/yyyy à HH:mm:ss'))."

    # Ajouter une section de résumé
    $textualItems = $collection.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" }
    $structuredItems = $collection.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Résumé de la collection" -Content @"
La collection contient un total de $($collection.Items.Count) éléments, répartis comme suit :
- $($textualItems.Count) éléments textuels
- $($structuredItems.Count) éléments structurés

Les éléments ont été extraits entre le $($collection.Items.Values | ForEach-Object { $_.ExtractedAt } | Sort-Object | Select-Object -First 1 | ForEach-Object { $_.ToString('dd/MM/yyyy HH:mm:ss') }) et le $($collection.Items.Values | ForEach-Object { $_.ExtractedAt } | Sort-Object -Descending | Select-Object -First 1 | ForEach-Object { $_.ToString('dd/MM/yyyy HH:mm:ss') }).
"@ -Type "Text" -Level 1

    # Ajouter un graphique de répartition par type
    $typeData = @(
        [PSCustomObject]@{ Type = "Textuel"; Count = $textualItems.Count },
        [PSCustomObject]@{ Type = "Structuré"; Count = $structuredItems.Count }
    )
    $report = Add-ExtractedInfoReportPieChart -Report $report -Title "Répartition par type d'élément" -Data $typeData -Level 2

    # Ajouter un tableau des éléments textuels
    $textualItemsTable = $textualItems | Select-Object @{Name="ID"; Expression={$_.Id}}, @{Name="Source"; Expression={$_.Source}}, @{Name="Langue"; Expression={$_.Language}}, @{Name="Score"; Expression={$_.ConfidenceScore}}, @{Name="Extrait le"; Expression={$_.ExtractedAt.ToString('dd/MM/yyyy HH:mm:ss')}}
    $report = Add-ExtractedInfoReportTable -Report $report -Title "Éléments textuels" -Data $textualItemsTable -Level 2

    # Ajouter un tableau des éléments structurés
    $structuredItemsTable = $structuredItems | Select-Object @{Name="ID"; Expression={$_.Id}}, @{Name="Source"; Expression={$_.Source}}, @{Name="Format"; Expression={$_.DataFormat}}, @{Name="Score"; Expression={$_.ConfidenceScore}}, @{Name="Extrait le"; Expression={$_.ExtractedAt.ToString('dd/MM/yyyy HH:mm:ss')}}
    $report = Add-ExtractedInfoReportTable -Report $report -Title "Éléments structurés" -Data $structuredItemsTable -Level 2

    # Ajouter un graphique d'évolution temporelle
    $timeData = @()
    $startDate = ($collection.Items.Values | ForEach-Object { $_.ExtractedAt } | Sort-Object | Select-Object -First 1).Date
    $endDate = ($collection.Items.Values | ForEach-Object { $_.ExtractedAt } | Sort-Object -Descending | Select-Object -First 1).Date.AddDays(1)

    for ($date = $startDate; $date -le $endDate; $date = $date.AddDays(1)) {
        $textCount = ($textualItems | Where-Object { $_.ExtractedAt.Date -eq $date }).Count
        $structCount = ($structuredItems | Where-Object { $_.ExtractedAt.Date -eq $date }).Count
        
        $timeData += [PSCustomObject]@{
            Date = $date.ToString('dd/MM/yyyy')
            Textuels = $textCount
            Structurés = $structCount
            Total = $textCount + $structCount
        }
    }

    $report = Add-ExtractedInfoReportChart -Report $report -Title "Évolution temporelle des extractions" -Data $timeData -ChartType "Line" -Level 2 -Options @{
        LabelProperty = "Date"
        SeriesProperties = @("Textuels", "Structurés", "Total")
    }

    # Ajouter une section d'analyse des scores de confiance
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Analyse des scores de confiance" -Content @"
Les scores de confiance des éléments extraits varient entre $($collection.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum) et $($collection.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum), avec une moyenne de $([math]::Round(($collection.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Average | Select-Object -ExpandProperty Average), 2)).

Les éléments textuels ont un score moyen de $([math]::Round(($textualItems | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Average | Select-Object -ExpandProperty Average), 2)), tandis que les éléments structurés ont un score moyen de $([math]::Round(($structuredItems | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Average | Select-Object -ExpandProperty Average), 2)).
"@ -Type "Text" -Level 1

    # Ajouter un graphique de distribution des scores
    $scoreRanges = @(
        [PSCustomObject]@{ Range = "60-70"; Count = ($collection.Items.Values | Where-Object { $_.ConfidenceScore -ge 60 -and $_.ConfidenceScore -lt 70 }).Count },
        [PSCustomObject]@{ Range = "70-80"; Count = ($collection.Items.Values | Where-Object { $_.ConfidenceScore -ge 70 -and $_.ConfidenceScore -lt 80 }).Count },
        [PSCustomObject]@{ Range = "80-90"; Count = ($collection.Items.Values | Where-Object { $_.ConfidenceScore -ge 80 -and $_.ConfidenceScore -lt 90 }).Count },
        [PSCustomObject]@{ Range = "90-100"; Count = ($collection.Items.Values | Where-Object { $_.ConfidenceScore -ge 90 -and $_.ConfidenceScore -le 100 }).Count }
    )
    $report = Add-ExtractedInfoReportBarChart -Report $report -Title "Distribution des scores de confiance" -Data $scoreRanges -Level 2

    # Ajouter une section de conclusion
    $report = Add-ExtractedInfoReportTextSection -Report $report -Title "Conclusion" -Text "Cette analyse de la collection '$CollectionName' montre une répartition de $($textualItems.Count) éléments textuels et $($structuredItems.Count) éléments structurés, avec des scores de confiance généralement élevés. Les extractions ont été réalisées sur une période de $((New-TimeSpan -Start $startDate -End $endDate).Days) jours." -Level 1

    # Exporter le rapport au format HTML
    $htmlPath = Join-Path -Path $OutputFolder -ChildPath "rapport_collection_$([System.IO.Path]::GetFileNameWithoutExtension($CollectionName))_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    Export-ExtractedInfoReportToHtml -Report $report -OutputPath $htmlPath -IncludeStyles -IncludeScripts

    Write-Host "Rapport de collection généré avec succès : $htmlPath"

    return $report
}

<#
.SYNOPSIS
Génère un rapport de comparaison entre deux collections d'informations extraites.

.DESCRIPTION
La fonction Show-ComparisonReport génère un rapport de comparaison entre deux collections
d'informations extraites. Elle met en évidence les différences et les similitudes.

.PARAMETER OutputFolder
Le dossier de sortie pour le rapport. Par défaut, le dossier temporaire.

.PARAMETER Collection1Name
Le nom de la première collection. Par défaut, "Collection 1".

.PARAMETER Collection2Name
Le nom de la deuxième collection. Par défaut, "Collection 2".

.PARAMETER ItemCount
Le nombre d'éléments à inclure dans chaque collection. Par défaut, 10.

.EXAMPLE
Show-ComparisonReport -OutputFolder "C:\Temp\Reports" -Collection1Name "Collection A" -Collection2Name "Collection B" -ItemCount 15

.NOTES
Cette fonction est fournie à titre d'exemple et peut être adaptée selon vos besoins.
#>
function Show-ComparisonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = [System.IO.Path]::GetTempPath(),

        [Parameter(Mandatory = $false)]
        [string]$Collection1Name = "Collection 1",

        [Parameter(Mandatory = $false)]
        [string]$Collection2Name = "Collection 2",

        [Parameter(Mandatory = $false)]
        [int]$ItemCount = 10
    )

    # Créer un dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    # Générer des données d'exemple pour la première collection
    $collection1 = @{
        Name = $Collection1Name
        Description = "Première collection d'informations extraites pour comparaison"
        CreatedAt = (Get-Date).AddDays(-7)
        Items = @{}
    }

    # Générer des données d'exemple pour la deuxième collection
    $collection2 = @{
        Name = $Collection2Name
        Description = "Deuxième collection d'informations extraites pour comparaison"
        CreatedAt = Get-Date
        Items = @{}
    }

    # Générer des éléments pour la première collection
    for ($i = 1; $i -le $ItemCount; $i++) {
        $itemId = [guid]::NewGuid().ToString()
        $isTextual = ($i % 3 -ne 0)

        if ($isTextual) {
            $collection1.Items[$itemId] = @{
                _Type = "TextExtractedInfo"
                Id = $itemId
                Source = "document_$i.txt"
                Text = "Contenu textuel extrait du document $i dans la collection 1."
                Language = if ($i % 5 -eq 0) { "en" } else { "fr" }
                ConfidenceScore = 65 + ($i % 30)
                ExtractedAt = (Get-Date).AddDays(-7).AddHours(-$i)
                ProcessingState = "Processed"
                Metadata = @{
                    Author = "Auteur " + ($i % 5 + 1)
                    Category = "Catégorie " + [char](65 + ($i % 5))
                    Tags = @("texte", "document", "collection1", "tag" + $i)
                }
            }
        }
        else {
            $collection1.Items[$itemId] = @{
                _Type = "StructuredDataExtractedInfo"
                Id = $itemId
                Source = "data_$i.json"
                Data = @{
                    Id = $i
                    Name = "Élément $i (Collection 1)"
                    Value = $i * 10
                    Properties = @{
                        Property1 = "Valeur 1.$i"
                        Property2 = "Valeur 2.$i"
                        Property3 = $i * 5
                    }
                }
                DataFormat = if ($i % 2 -eq 0) { "Json" } else { "Xml" }
                ConfidenceScore = 75 + ($i % 20)
                ExtractedAt = (Get-Date).AddDays(-7).AddHours(-$i).AddMinutes(-($i * 5))
                ProcessingState = "Processed"
                Metadata = @{
                    Source = if ($i % 2 -eq 0) { "API" } else { "File" }
                    Version = "1." + ($i % 10)
                    Tags = @("data", if ($i % 2 -eq 0) { "json" } else { "xml" }, "collection1", "tag" + $i)
                }
            }
        }
    }

    # Générer des éléments pour la deuxième collection
    # Certains éléments seront similaires à ceux de la première collection, d'autres seront différents
    for ($i = 1; $i -le $ItemCount; $i++) {
        $itemId = [guid]::NewGuid().ToString()
        $isTextual = ($i % 3 -ne 0)

        if ($isTextual) {
            $collection2.Items[$itemId] = @{
                _Type = "TextExtractedInfo"
                Id = $itemId
                Source = "document_$i.txt"
                Text = "Contenu textuel extrait du document $i dans la collection 2."
                Language = if ($i % 5 -eq 0) { "en" } else { "fr" }
                ConfidenceScore = 70 + ($i % 25) # Scores légèrement différents
                ExtractedAt = (Get-Date).AddHours(-$i)
                ProcessingState = "Processed"
                Metadata = @{
                    Author = "Auteur " + ($i % 5 + 1)
                    Category = "Catégorie " + [char](65 + ($i % 5))
                    Tags = @("texte", "document", "collection2", "tag" + $i)
                }
            }
        }
        else {
            $collection2.Items[$itemId] = @{
                _Type = "StructuredDataExtractedInfo"
                Id = $itemId
                Source = "data_$i.json"
                Data = @{
                    Id = $i
                    Name = "Élément $i (Collection 2)"
                    Value = $i * 12 # Valeurs légèrement différentes
                    Properties = @{
                        Property1 = "Valeur 1.$i"
                        Property2 = "Valeur 2.$i (modifiée)" # Propriété modifiée
                        Property3 = $i * 6 # Valeur modifiée
                    }
                }
                DataFormat = if ($i % 2 -eq 0) { "Json" } else { "Xml" }
                ConfidenceScore = 80 + ($i % 15) # Scores légèrement différents
                ExtractedAt = (Get-Date).AddHours(-$i).AddMinutes(-($i * 5))
                ProcessingState = "Processed"
                Metadata = @{
                    Source = if ($i % 2 -eq 0) { "API" } else { "File" }
                    Version = "1." + ($i % 10)
                    Tags = @("data", if ($i % 2 -eq 0) { "json" } else { "xml" }, "collection2", "tag" + $i)
                }
            }
        }
    }

    # Créer un nouveau rapport
    $report = New-ExtractedInfoReport -Title "Rapport de comparaison : $Collection1Name vs $Collection2Name" -Description "Ce rapport compare deux collections d'informations extraites." -Author "Système de reporting" -Type "Comparison"

    # Ajouter une section d'introduction
    $report = Add-ExtractedInfoReportTextSection -Report $report -Title "Introduction" -Text "Ce rapport présente une comparaison détaillée entre deux collections d'informations extraites : '$Collection1Name' et '$Collection2Name'. La première collection contient $($collection1.Items.Count) éléments, créée le $($collection1.CreatedAt.ToString('dd/MM/yyyy à HH:mm:ss')). La deuxième collection contient $($collection2.Items.Count) éléments, créée le $($collection2.CreatedAt.ToString('dd/MM/yyyy à HH:mm:ss'))."

    # Ajouter une section de résumé comparatif
    $textualItems1 = $collection1.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" }
    $structuredItems1 = $collection1.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }
    $textualItems2 = $collection2.Items.Values | Where-Object { $_._Type -eq "TextExtractedInfo" }
    $structuredItems2 = $collection2.Items.Values | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }

    $report = Add-ExtractedInfoReportSection -Report $report -Title "Résumé comparatif" -Content @"
## Composition des collections

| Métrique | $Collection1Name | $Collection2Name | Différence |
|----------|-----------------|-----------------|------------|
| Total d'éléments | $($collection1.Items.Count) | $($collection2.Items.Count) | $($collection2.Items.Count - $collection1.Items.Count) |
| Éléments textuels | $($textualItems1.Count) | $($textualItems2.Count) | $($textualItems2.Count - $textualItems1.Count) |
| Éléments structurés | $($structuredItems1.Count) | $($structuredItems2.Count) | $($structuredItems2.Count - $structuredItems1.Count) |
| Score moyen | $([math]::Round(($collection1.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Average | Select-Object -ExpandProperty Average), 2)) | $([math]::Round(($collection2.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Average | Select-Object -ExpandProperty Average), 2)) | $([math]::Round(($collection2.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Average | Select-Object -ExpandProperty Average) - ($collection1.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Average | Select-Object -ExpandProperty Average), 2)) |

## Principales différences

- La collection '$Collection2Name' a été créée $([math]::Round(((Get-Date) - $collection1.CreatedAt).TotalDays)) jours après la collection '$Collection1Name'.
- Les scores de confiance sont généralement $([math]::Round(($collection2.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Average | Select-Object -ExpandProperty Average) - ($collection1.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Average | Select-Object -ExpandProperty Average), 2)) points plus élevés dans la collection '$Collection2Name'.
- Les valeurs des éléments structurés sont environ 20% plus élevées dans la collection '$Collection2Name'.
"@ -Type "Text" -Level 1

    # Ajouter un graphique comparatif de la répartition par type
    $typeComparisonData = @(
        [PSCustomObject]@{ Collection = $Collection1Name; Type = "Textuel"; Count = $textualItems1.Count },
        [PSCustomObject]@{ Collection = $Collection1Name; Type = "Structuré"; Count = $structuredItems1.Count },
        [PSCustomObject]@{ Collection = $Collection2Name; Type = "Textuel"; Count = $textualItems2.Count },
        [PSCustomObject]@{ Collection = $Collection2Name; Type = "Structuré"; Count = $structuredItems2.Count }
    )
    $report = Add-ExtractedInfoReportBarChart -Report $report -Title "Comparaison de la répartition par type" -Data $typeComparisonData -Level 2 -Options @{
        LabelProperty = "Type"
        SeriesProperties = @($Collection1Name, $Collection2Name)
    }

    # Ajouter une analyse comparative détaillée
    $differenceAnalysis = @"
## Analyse des scores de confiance

La distribution des scores de confiance montre des différences significatives entre les deux collections :

- Collection '$Collection1Name' : scores entre $($collection1.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum) et $($collection1.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
- Collection '$Collection2Name' : scores entre $($collection2.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum) et $($collection2.Items.Values | ForEach-Object { $_.ConfidenceScore } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)

La collection '$Collection2Name' présente généralement des scores plus élevés, ce qui pourrait indiquer une amélioration des algorithmes d'extraction ou une meilleure qualité des sources.

## Analyse des métadonnées

Les tags utilisés dans les deux collections sont similaires, mais la collection '$Collection2Name' utilise systématiquement le tag 'collection2' au lieu de 'collection1'.

## Analyse des données structurées

Les éléments structurés de la collection '$Collection2Name' présentent des valeurs environ 20% plus élevées que ceux de la collection '$Collection1Name'. De plus, la propriété 'Property2' a été modifiée dans tous les éléments de la collection '$Collection2Name'.
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
            if ($item.Metadata -and $item.Metadata.Category) {
                $category = $item.Metadata.Category
                if (-not $categories.ContainsKey($category)) {
                    $categories[$category] = 0
                }
                $categories[$category]++
            }
        }

        $result = @()
        foreach ($category in $categories.Keys) {
            $result += [PSCustomObject]@{
                Category = $category
                Count = $categories[$category]
            }
        }

        return $result
    }

    $categories1 = Get-CategoryDistribution -Collection $collection1
    $categories2 = Get-CategoryDistribution -Collection $collection2

    # Ajouter un graphique pour chaque collection
    $report = Add-ExtractedInfoReportPieChart -Report $report -Title "Distribution par catégorie - $Collection1Name" -Data $categories1 -Level 2
    $report = Add-ExtractedInfoReportPieChart -Report $report -Title "Distribution par catégorie - $Collection2Name" -Data $categories2 -Level 2

    # Ajouter une section de conclusion
    $report = Add-ExtractedInfoReportTextSection -Report $report -Title "Conclusion" -Text "Cette analyse comparative entre les collections '$Collection1Name' et '$Collection2Name' révèle plusieurs différences significatives, notamment en termes de scores de confiance et de valeurs des données structurées. La collection '$Collection2Name', plus récente, présente généralement des scores plus élevés, ce qui pourrait indiquer une amélioration des algorithmes d'extraction ou une meilleure qualité des sources." -Level 1

    # Exporter le rapport au format HTML
    $htmlPath = Join-Path -Path $OutputFolder -ChildPath "rapport_comparaison_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    Export-ExtractedInfoReportToHtml -Report $report -OutputPath $htmlPath -IncludeStyles -IncludeScripts

    Write-Host "Rapport de comparaison généré avec succès : $htmlPath"

    return $report
}

# Exporter les fonctions
Export-ModuleMember -Function Show-CollectionReport, Show-ComparisonReport
