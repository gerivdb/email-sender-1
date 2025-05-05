#Requires -Version 5.1
<#
.SYNOPSIS
Génère des statistiques sur des objets d'information extraite.

.DESCRIPTION
La fonction Get-ExtractedInfoStatistics analyse un objet d'information extraite ou une collection
d'objets d'information extraite et génère des statistiques sur ces objets. Les statistiques peuvent
inclure des informations sur le nombre d'éléments, les types, les sources, la distribution temporelle,
les scores de confiance, la taille et la complexité du contenu, ainsi que les métadonnées.

.PARAMETER Info
Un objet d'information extraite individuel à analyser. Ce paramètre est mutuellement exclusif avec
le paramètre Collection.

.PARAMETER Collection
Une collection d'objets d'information extraite à analyser. Ce paramètre est mutuellement exclusif avec
le paramètre Info.

.PARAMETER StatisticsType
Le type de statistiques à générer. Les valeurs possibles sont :
- Basic : Statistiques de base (nombre d'éléments, types, sources)
- Temporal : Statistiques temporelles (distribution par date d'extraction)
- Confidence : Statistiques de confiance (distribution des scores)
- Content : Statistiques de contenu (taille, complexité)
- All : Toutes les statistiques

La valeur par défaut est "Basic".

.PARAMETER IncludeMetadata
Indique si les métadonnées doivent être incluses dans l'analyse statistique.

.PARAMETER OutputFormat
Le format de sortie des statistiques. Les valeurs possibles sont :
- Text : Format texte brut
- HTML : Format HTML
- JSON : Format JSON

La valeur par défaut est "Text".

.EXAMPLE
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document" -Language "fr"
Get-ExtractedInfoStatistics -Info $info -StatisticsType Basic

Génère des statistiques de base sur un objet d'information extraite individuel.

.EXAMPLE
$collection = New-ExtractedInfoCollection -Name "Documents"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info2
Get-ExtractedInfoStatistics -Collection $collection -StatisticsType All -OutputFormat HTML

Génère toutes les statistiques sur une collection d'objets d'information extraite et les formate en HTML.

.EXAMPLE
$collection = Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_.ProcessingState -eq "Processed" }
$stats = Get-ExtractedInfoStatistics -Collection $collection -StatisticsType Confidence -OutputFormat JSON
$stats | Out-File -FilePath "confidence_stats.json" -Encoding utf8

Génère des statistiques de confiance sur une collection filtrée d'objets d'information extraite,
les formate en JSON et les enregistre dans un fichier.
#>
function Get-ExtractedInfoStatistics {
    [CmdletBinding(DefaultParameterSetName = 'SingleInfo')]
    [OutputType([hashtable], [string])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'SingleInfo', Position = 0)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true, ParameterSetName = 'Collection', Position = 0)]
        [hashtable]$Collection,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Basic', 'Temporal', 'Confidence', 'Content', 'All')]
        [string]$StatisticsType = 'Basic',

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Text', 'HTML', 'JSON')]
        [string]$OutputFormat = 'Text'
    )

    begin {
        # Initialisation des variables
        $statistics = @{
            GeneratedAt    = [datetime]::Now
            StatisticsType = $StatisticsType
        }
        $items = @()

        # Validation des paramètres
        if ($PSCmdlet.ParameterSetName -eq 'SingleInfo') {
            # Validation de l'objet Info
            if (-not $Info.ContainsKey('_Type') -or -not $Info._Type.EndsWith('ExtractedInfo')) {
                throw "L'objet fourni n'est pas un objet d'information extraite valide."
            }

            # Ajouter l'objet à la liste des éléments à analyser
            $items += $Info
            $statistics.ItemCount = 1
        } else {
            # Validation de la collection
            if (-not $Collection.ContainsKey('_Type') -or $Collection._Type -ne 'ExtractedInfoCollection') {
                throw "L'objet fourni n'est pas une collection d'informations extraites valide."
            }

            if (-not $Collection.ContainsKey('Items') -or $Collection.Items.Count -eq 0) {
                Write-Warning "La collection est vide. Les statistiques seront limitées."
            }

            # Ajouter les éléments de la collection à la liste des éléments à analyser
            $items += $Collection.Items
            $statistics.ItemCount = $items.Count
            $statistics.CollectionName = $Collection.Name
        }
    }

    process {
        # Cette fonction ne traite pas les objets en pipeline, donc le bloc process est vide
    }

    end {
        # Structure conditionnelle pour les différents types de statistiques
        if ($StatisticsType -eq 'Basic' -or $StatisticsType -eq 'All') {
            # Analyse de base (nombre d'éléments, types, sources)
            $typeDistribution = @{}
            $sourceDistribution = @{}
            $processingStateDistribution = @{}

            foreach ($item in $items) {
                # Analyser la distribution des types
                $type = $item._Type
                if (-not $typeDistribution.ContainsKey($type)) {
                    $typeDistribution[$type] = 0
                }
                $typeDistribution[$type]++

                # Analyser la distribution des sources
                $source = $item.Source
                if (-not $sourceDistribution.ContainsKey($source)) {
                    $sourceDistribution[$source] = 0
                }
                $sourceDistribution[$source]++

                # Analyser la distribution des états de traitement
                $processingState = $item.ProcessingState
                if (-not $processingStateDistribution.ContainsKey($processingState)) {
                    $processingStateDistribution[$processingState] = 0
                }
                $processingStateDistribution[$processingState]++
            }

            # Calculer les pourcentages
            $typePercentages = @{}
            $sourcePercentages = @{}
            $processingStatePercentages = @{}

            foreach ($type in $typeDistribution.Keys) {
                $typePercentages[$type] = [math]::Round(($typeDistribution[$type] / $items.Count) * 100, 2)
            }

            foreach ($source in $sourceDistribution.Keys) {
                $sourcePercentages[$source] = [math]::Round(($sourceDistribution[$source] / $items.Count) * 100, 2)
            }

            foreach ($state in $processingStateDistribution.Keys) {
                $processingStatePercentages[$state] = [math]::Round(($processingStateDistribution[$state] / $items.Count) * 100, 2)
            }

            # Stocker les statistiques de base
            $statistics.BasicStats = @{
                TypeDistribution            = $typeDistribution
                TypePercentages             = $typePercentages
                SourceDistribution          = $sourceDistribution
                SourcePercentages           = $sourcePercentages
                ProcessingStateDistribution = $processingStateDistribution
                ProcessingStatePercentages  = $processingStatePercentages
                UniqueTypes                 = $typeDistribution.Keys.Count
                UniqueSources               = $sourceDistribution.Keys.Count
                UniqueProcessingStates      = $processingStateDistribution.Keys.Count
            }
        }

        if ($StatisticsType -eq 'Temporal' -or $StatisticsType -eq 'All') {
            # Analyse temporelle (distribution par date d'extraction)
            $dayDistribution = @{}
            $monthDistribution = @{}
            $yearDistribution = @{}
            $hourDistribution = @{}
            $weekdayDistribution = @{
                "Dimanche" = 0
                "Lundi"    = 0
                "Mardi"    = 0
                "Mercredi" = 0
                "Jeudi"    = 0
                "Vendredi" = 0
                "Samedi"   = 0
            }

            # Calculer l'âge moyen des informations
            $totalAgeInDays = 0
            $now = [datetime]::Now

            foreach ($item in $items) {
                if ($item.ContainsKey("ExtractedAt") -and $item.ExtractedAt -is [datetime]) {
                    $extractionDate = $item.ExtractedAt

                    # Calculer l'âge en jours
                    $ageInDays = ($now - $extractionDate).TotalDays
                    $totalAgeInDays += $ageInDays

                    # Distribution par jour
                    $day = $extractionDate.ToString("yyyy-MM-dd")
                    if (-not $dayDistribution.ContainsKey($day)) {
                        $dayDistribution[$day] = 0
                    }
                    $dayDistribution[$day]++

                    # Distribution par mois
                    $month = $extractionDate.ToString("yyyy-MM")
                    if (-not $monthDistribution.ContainsKey($month)) {
                        $monthDistribution[$month] = 0
                    }
                    $monthDistribution[$month]++

                    # Distribution par année
                    $year = $extractionDate.Year.ToString()
                    if (-not $yearDistribution.ContainsKey($year)) {
                        $yearDistribution[$year] = 0
                    }
                    $yearDistribution[$year]++

                    # Distribution par heure
                    $hour = $extractionDate.Hour.ToString("00") + "h"
                    if (-not $hourDistribution.ContainsKey($hour)) {
                        $hourDistribution[$hour] = 0
                    }
                    $hourDistribution[$hour]++

                    # Distribution par jour de la semaine
                    $weekday = switch ($extractionDate.DayOfWeek) {
                        0 { "Dimanche" }
                        1 { "Lundi" }
                        2 { "Mardi" }
                        3 { "Mercredi" }
                        4 { "Jeudi" }
                        5 { "Vendredi" }
                        6 { "Samedi" }
                    }
                    $weekdayDistribution[$weekday]++
                }
            }

            # Calculer l'âge moyen
            $averageAgeInDays = if ($items.Count -gt 0) { $totalAgeInDays / $items.Count } else { 0 }

            # Trouver les périodes les plus actives
            $mostActiveDay = if ($dayDistribution.Count -gt 0) {
                $dayDistribution.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
            } else { $null }

            $mostActiveMonth = if ($monthDistribution.Count -gt 0) {
                $monthDistribution.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
            } else { $null }

            $mostActiveHour = if ($hourDistribution.Count -gt 0) {
                $hourDistribution.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
            } else { $null }

            $mostActiveWeekday = if ($weekdayDistribution.Count -gt 0) {
                $weekdayDistribution.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
            } else { $null }

            # Stocker les statistiques temporelles
            $statistics.TemporalStats = @{
                DayDistribution     = $dayDistribution
                MonthDistribution   = $monthDistribution
                YearDistribution    = $yearDistribution
                HourDistribution    = $hourDistribution
                WeekdayDistribution = $weekdayDistribution
                AverageAgeInDays    = [math]::Round($averageAgeInDays, 2)
                AverageAgeInMonths  = [math]::Round($averageAgeInDays / 30, 2)
                MostActiveDay       = if ($mostActiveDay) { @{ Date = $mostActiveDay.Key; Count = $mostActiveDay.Value } } else { $null }
                MostActiveMonth     = if ($mostActiveMonth) { @{ Month = $mostActiveMonth.Key; Count = $mostActiveMonth.Value } } else { $null }
                MostActiveHour      = if ($mostActiveHour) { @{ Hour = $mostActiveHour.Key; Count = $mostActiveHour.Value } } else { $null }
                MostActiveWeekday   = if ($mostActiveWeekday) { @{ Weekday = $mostActiveWeekday.Key; Count = $mostActiveWeekday.Value } } else { $null }
            }
        }

        if ($StatisticsType -eq 'Confidence' -or $StatisticsType -eq 'All') {
            # Analyse de confiance (distribution des scores)
            $confidenceScores = @()
            $confidenceRanges = @{
                "Très faible (0-20)"  = 0
                "Faible (21-40)"      = 0
                "Moyen (41-60)"       = 0
                "Élevé (61-80)"       = 0
                "Très élevé (81-100)" = 0
            }

            foreach ($item in $items) {
                if ($item.ContainsKey("ConfidenceScore")) {
                    $score = $item.ConfidenceScore
                    $confidenceScores += $score

                    # Classer le score dans une plage
                    if ($score -ge 0 -and $score -le 20) {
                        $confidenceRanges["Très faible (0-20)"]++
                    } elseif ($score -gt 20 -and $score -le 40) {
                        $confidenceRanges["Faible (21-40)"]++
                    } elseif ($score -gt 40 -and $score -le 60) {
                        $confidenceRanges["Moyen (41-60)"]++
                    } elseif ($score -gt 60 -and $score -le 80) {
                        $confidenceRanges["Élevé (61-80)"]++
                    } elseif ($score -gt 80 -and $score -le 100) {
                        $confidenceRanges["Très élevé (81-100)"]++
                    }
                }
            }

            # Calculer les statistiques de confiance
            $averageConfidence = if ($confidenceScores.Count -gt 0) {
                ($confidenceScores | Measure-Object -Average).Average
            } else { 0 }

            $medianConfidence = if ($confidenceScores.Count -gt 0) {
                $sortedScores = $confidenceScores | Sort-Object
                $middle = [int]($sortedScores.Count / 2)

                if ($sortedScores.Count % 2 -eq 0) {
                    ($sortedScores[$middle - 1] + $sortedScores[$middle]) / 2
                } else {
                    $sortedScores[$middle]
                }
            } else { 0 }

            $minConfidence = if ($confidenceScores.Count -gt 0) {
                ($confidenceScores | Measure-Object -Minimum).Minimum
            } else { 0 }

            $maxConfidence = if ($confidenceScores.Count -gt 0) {
                ($confidenceScores | Measure-Object -Maximum).Maximum
            } else { 0 }

            # Calculer les pourcentages par plage
            $confidenceRangePercentages = @{}
            foreach ($range in $confidenceRanges.Keys) {
                $confidenceRangePercentages[$range] = if ($items.Count -gt 0) {
                    [math]::Round(($confidenceRanges[$range] / $items.Count) * 100, 2)
                } else { 0 }
            }

            # Déterminer la plage dominante
            $dominantRange = if ($confidenceRanges.Count -gt 0) {
                $confidenceRanges.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1
            } else { $null }

            # Stocker les statistiques de confiance
            $statistics.ConfidenceStats = @{
                ConfidenceScores           = $confidenceScores
                ConfidenceRanges           = $confidenceRanges
                ConfidenceRangePercentages = $confidenceRangePercentages
                AverageConfidence          = [math]::Round($averageConfidence, 2)
                MedianConfidence           = [math]::Round($medianConfidence, 2)
                MinConfidence              = $minConfidence
                MaxConfidence              = $maxConfidence
                ConfidenceRange            = $maxConfidence - $minConfidence
                DominantRange              = if ($dominantRange) { @{ Range = $dominantRange.Key; Count = $dominantRange.Value } } else { $null }
            }
        }

        if ($StatisticsType -eq 'Content' -or $StatisticsType -eq 'All') {
            # Analyse de contenu (taille, complexité)
            $contentSizes = @()
            $contentSizeRanges = @{
                "Très petit (0-100 caractères)"  = 0
                "Petit (101-500 caractères)"     = 0
                "Moyen (501-2000 caractères)"    = 0
                "Grand (2001-10000 caractères)"  = 0
                "Très grand (>10000 caractères)" = 0
            }

            $typeSpecificStats = @{}

            foreach ($item in $items) {
                $type = $item._Type

                # Initialiser les statistiques spécifiques au type si nécessaire
                if (-not $typeSpecificStats.ContainsKey($type)) {
                    $typeSpecificStats[$type] = @{
                        Count     = 0
                        TotalSize = 0
                        Sizes     = @()
                    }
                }

                $typeSpecificStats[$type].Count++

                # Analyser la taille du contenu selon le type
                $contentSize = 0

                switch ($type) {
                    "TextExtractedInfo" {
                        if ($item.ContainsKey("Text")) {
                            $contentSize = $item.Text.Length

                            # Ajouter des statistiques spécifiques au texte
                            if (-not $typeSpecificStats[$type].ContainsKey("WordCounts")) {
                                $typeSpecificStats[$type].WordCounts = @()
                            }

                            $wordCount = ($item.Text -split '\s+').Count
                            $typeSpecificStats[$type].WordCounts += $wordCount
                        }
                    }
                    "StructuredDataExtractedInfo" {
                        if ($item.ContainsKey("Data")) {
                            # Estimer la taille en convertissant en JSON
                            $contentSize = (ConvertTo-Json -InputObject $item.Data -Compress).Length

                            # Ajouter des statistiques spécifiques aux données structurées
                            if (-not $typeSpecificStats[$type].ContainsKey("DataFormats")) {
                                $typeSpecificStats[$type].DataFormats = @{}
                            }

                            if ($item.ContainsKey("DataFormat")) {
                                $dataFormat = $item.DataFormat
                                if (-not $typeSpecificStats[$type].DataFormats.ContainsKey($dataFormat)) {
                                    $typeSpecificStats[$type].DataFormats[$dataFormat] = 0
                                }
                                $typeSpecificStats[$type].DataFormats[$dataFormat]++
                            }
                        }
                    }
                    "MediaExtractedInfo" {
                        if ($item.ContainsKey("MediaPath") -and (Test-Path -Path $item.MediaPath)) {
                            # Obtenir la taille du fichier média
                            $contentSize = (Get-Item -Path $item.MediaPath).Length

                            # Ajouter des statistiques spécifiques aux médias
                            if (-not $typeSpecificStats[$type].ContainsKey("MediaTypes")) {
                                $typeSpecificStats[$type].MediaTypes = @{}
                            }

                            if ($item.ContainsKey("MediaType")) {
                                $mediaType = $item.MediaType
                                if (-not $typeSpecificStats[$type].MediaTypes.ContainsKey($mediaType)) {
                                    $typeSpecificStats[$type].MediaTypes[$mediaType] = 0
                                }
                                $typeSpecificStats[$type].MediaTypes[$mediaType]++
                            }
                        }
                    }
                    "GeoLocationExtractedInfo" {
                        # Pour les géolocalisations, estimer la taille en fonction des propriétés
                        $contentSize = 0
                        foreach ($key in $item.Keys) {
                            if ($key -ne "_Type" -and $key -ne "Id" -and $key -ne "Source" -and
                                $key -ne "ExtractedAt" -and $key -ne "LastModifiedDate" -and
                                $key -ne "ProcessingState" -and $key -ne "ConfidenceScore" -and
                                $key -ne "Metadata") {

                                $value = $item[$key]
                                if ($value -is [string]) {
                                    $contentSize += $value.Length
                                } else {
                                    $contentSize += 10 # Valeur arbitraire pour les propriétés non-string
                                }
                            }
                        }
                    }
                    default {
                        # Pour les autres types, estimer la taille en fonction du nombre de propriétés
                        $contentSize = $item.Keys.Count * 10 # Valeur arbitraire
                    }
                }

                # Ajouter la taille aux statistiques
                $contentSizes += $contentSize
                $typeSpecificStats[$type].TotalSize += $contentSize
                $typeSpecificStats[$type].Sizes += $contentSize

                # Classer la taille dans une plage
                if ($contentSize -ge 0 -and $contentSize -le 100) {
                    $contentSizeRanges["Très petit (0-100 caractères)"]++
                } elseif ($contentSize -gt 100 -and $contentSize -le 500) {
                    $contentSizeRanges["Petit (101-500 caractères)"]++
                } elseif ($contentSize -gt 500 -and $contentSize -le 2000) {
                    $contentSizeRanges["Moyen (501-2000 caractères)"]++
                } elseif ($contentSize -gt 2000 -and $contentSize -le 10000) {
                    $contentSizeRanges["Grand (2001-10000 caractères)"]++
                } elseif ($contentSize -gt 10000) {
                    $contentSizeRanges["Très grand (>10000 caractères)"]++
                }
            }

            # Calculer les statistiques de taille
            $averageSize = if ($contentSizes.Count -gt 0) {
                ($contentSizes | Measure-Object -Average).Average
            } else { 0 }

            $medianSize = if ($contentSizes.Count -gt 0) {
                $sortedSizes = $contentSizes | Sort-Object
                $middle = [int]($sortedSizes.Count / 2)

                if ($sortedSizes.Count % 2 -eq 0) {
                    ($sortedSizes[$middle - 1] + $sortedSizes[$middle]) / 2
                } else {
                    $sortedSizes[$middle]
                }
            } else { 0 }

            $minSize = if ($contentSizes.Count -gt 0) {
                ($contentSizes | Measure-Object -Minimum).Minimum
            } else { 0 }

            $maxSize = if ($contentSizes.Count -gt 0) {
                ($contentSizes | Measure-Object -Maximum).Maximum
            } else { 0 }

            $totalSize = if ($contentSizes.Count -gt 0) {
                ($contentSizes | Measure-Object -Sum).Sum
            } else { 0 }

            # Calculer les pourcentages par plage
            $contentSizeRangePercentages = @{}
            foreach ($range in $contentSizeRanges.Keys) {
                $contentSizeRangePercentages[$range] = if ($items.Count -gt 0) {
                    [math]::Round(($contentSizeRanges[$range] / $items.Count) * 100, 2)
                } else { 0 }
            }

            # Calculer les statistiques spécifiques aux types
            foreach ($type in $typeSpecificStats.Keys) {
                if ($typeSpecificStats[$type].Count -gt 0) {
                    $typeSpecificStats[$type].AverageSize = [math]::Round($typeSpecificStats[$type].TotalSize / $typeSpecificStats[$type].Count, 2)

                    if ($type -eq "TextExtractedInfo" -and $typeSpecificStats[$type].ContainsKey("WordCounts") -and $typeSpecificStats[$type].WordCounts.Count -gt 0) {
                        $typeSpecificStats[$type].TotalWords = ($typeSpecificStats[$type].WordCounts | Measure-Object -Sum).Sum
                        $typeSpecificStats[$type].AverageWords = [math]::Round($typeSpecificStats[$type].TotalWords / $typeSpecificStats[$type].Count, 2)
                    }
                }
            }

            # Stocker les statistiques de contenu
            $statistics.ContentStats = @{
                ContentSizes                = $contentSizes
                ContentSizeRanges           = $contentSizeRanges
                ContentSizeRangePercentages = $contentSizeRangePercentages
                AverageSize                 = [math]::Round($averageSize, 2)
                MedianSize                  = [math]::Round($medianSize, 2)
                MinSize                     = $minSize
                MaxSize                     = $maxSize
                TotalSize                   = $totalSize
                SizeRange                   = $maxSize - $minSize
                TypeSpecificStats           = $typeSpecificStats
            }
        }

        if ($IncludeMetadata) {
            # Analyse de métadonnées
            $metadataKeyDistribution = @{}
            $metadataValueTypes = @{}
            $metadataItemsCount = 0
            $itemsWithMetadata = 0

            foreach ($item in $items) {
                if ($item.ContainsKey("Metadata") -and $item.Metadata -is [hashtable] -and $item.Metadata.Count -gt 0) {
                    $itemsWithMetadata++
                    $metadataItemsCount += $item.Metadata.Count

                    # Analyser les clés de métadonnées
                    foreach ($key in $item.Metadata.Keys) {
                        if (-not $metadataKeyDistribution.ContainsKey($key)) {
                            $metadataKeyDistribution[$key] = 0
                        }
                        $metadataKeyDistribution[$key]++

                        # Analyser les types de valeurs
                        $value = $item.Metadata[$key]
                        $valueType = if ($null -eq $value) {
                            "Null"
                        } elseif ($value -is [string]) {
                            "String"
                        } elseif ($value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal]) {
                            "Number"
                        } elseif ($value -is [bool]) {
                            "Boolean"
                        } elseif ($value -is [datetime]) {
                            "DateTime"
                        } elseif ($value -is [array] -or $value -is [System.Collections.ArrayList]) {
                            "Array"
                        } elseif ($value -is [hashtable] -or $value -is [System.Collections.IDictionary]) {
                            "Object"
                        } else {
                            "Other"
                        }

                        if (-not $metadataValueTypes.ContainsKey($key)) {
                            $metadataValueTypes[$key] = @{}
                        }

                        if (-not $metadataValueTypes[$key].ContainsKey($valueType)) {
                            $metadataValueTypes[$key][$valueType] = 0
                        }
                        $metadataValueTypes[$key][$valueType]++
                    }
                }
            }

            # Calculer les statistiques de métadonnées
            $averageMetadataPerItem = if ($itemsWithMetadata -gt 0) {
                $metadataItemsCount / $itemsWithMetadata
            } else { 0 }

            $percentItemsWithMetadata = if ($items.Count -gt 0) {
                ($itemsWithMetadata / $items.Count) * 100
            } else { 0 }

            # Trouver les clés de métadonnées les plus courantes
            $mostCommonMetadataKeys = if ($metadataKeyDistribution.Count -gt 0) {
                $metadataKeyDistribution.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5
            } else { @() }

            # Analyser les valeurs pour les clés les plus courantes
            $commonKeyValueAnalysis = @{}
            foreach ($keyEntry in $mostCommonMetadataKeys) {
                $key = $keyEntry.Key
                $valueDistribution = @{}

                foreach ($item in $items) {
                    if ($item.ContainsKey("Metadata") -and $item.Metadata -is [hashtable] -and $item.Metadata.ContainsKey($key)) {
                        $value = $item.Metadata[$key]
                        $valueStr = if ($null -eq $value) {
                            "null"
                        } elseif ($value -is [string] -or $value -is [int] -or $value -is [long] -or
                            $value -is [double] -or $value -is [decimal] -or $value -is [bool]) {
                            $value.ToString()
                        } elseif ($value -is [datetime]) {
                            $value.ToString("o")
                        } else {
                            "complex"
                        }

                        if (-not $valueDistribution.ContainsKey($valueStr)) {
                            $valueDistribution[$valueStr] = 0
                        }
                        $valueDistribution[$valueStr]++
                    }
                }

                $commonKeyValueAnalysis[$key] = $valueDistribution
            }

            # Stocker les statistiques de métadonnées
            $statistics.MetadataStats = @{
                MetadataKeyDistribution  = $metadataKeyDistribution
                MetadataValueTypes       = $metadataValueTypes
                TotalMetadataItems       = $metadataItemsCount
                ItemsWithMetadata        = $itemsWithMetadata
                PercentItemsWithMetadata = [math]::Round($percentItemsWithMetadata, 2)
                AverageMetadataPerItem   = [math]::Round($averageMetadataPerItem, 2)
                UniqueMetadataKeys       = $metadataKeyDistribution.Keys.Count
                MostCommonMetadataKeys   = $mostCommonMetadataKeys | ForEach-Object {
                    @{ Key = $_.Key; Count = $_.Value; Percentage = [math]::Round(($_.Value / $itemsWithMetadata) * 100, 2) }
                }
                CommonKeyValueAnalysis   = $commonKeyValueAnalysis
            }
        }

        # Formatage de la sortie selon le format demandé
        switch ($OutputFormat) {
            'Text' {
                # Format texte brut
                $report = @"
=======================================================
RAPPORT D'ANALYSE STATISTIQUE DES INFORMATIONS EXTRAITES
=======================================================
Généré le : $($statistics.GeneratedAt)
Type d'analyse : $($statistics.StatisticsType)
Nombre d'éléments : $($statistics.ItemCount)
"@

                if ($PSCmdlet.ParameterSetName -eq 'Collection') {
                    $report += "`nNom de la collection : $($statistics.CollectionName)"
                }

                if ($statistics.ContainsKey('BasicStats')) {
                    $report += @"

-------------------------------------------------------
STATISTIQUES DE BASE
-------------------------------------------------------
"@

                    # Distribution des types
                    $report += "`n* Distribution des types :"
                    foreach ($type in $statistics.BasicStats.TypeDistribution.Keys) {
                        $count = $statistics.BasicStats.TypeDistribution[$type]
                        $percent = $statistics.BasicStats.TypePercentages[$type]
                        $report += "`n  - $type : $count ($percent%)"
                    }

                    # Distribution des sources
                    $report += "`n`n* Distribution des sources :"
                    foreach ($source in $statistics.BasicStats.SourceDistribution.Keys) {
                        $count = $statistics.BasicStats.SourceDistribution[$source]
                        $percent = $statistics.BasicStats.SourcePercentages[$source]
                        $report += "`n  - $source : $count ($percent%)"
                    }

                    # Distribution des états de traitement
                    $report += "`n`n* Distribution des états de traitement :"
                    foreach ($state in $statistics.BasicStats.ProcessingStateDistribution.Keys) {
                        $count = $statistics.BasicStats.ProcessingStateDistribution[$state]
                        $percent = $statistics.BasicStats.ProcessingStatePercentages[$state]
                        $report += "`n  - $state : $count ($percent%)"
                    }
                }

                if ($statistics.ContainsKey('TemporalStats')) {
                    $report += @"

-------------------------------------------------------
STATISTIQUES TEMPORELLES
-------------------------------------------------------
* Âge moyen : $($statistics.TemporalStats.AverageAgeInDays) jours ($($statistics.TemporalStats.AverageAgeInMonths) mois)
"@

                    if ($statistics.TemporalStats.MostActiveDay) {
                        $report += "`n* Jour le plus actif : $($statistics.TemporalStats.MostActiveDay.Date) ($($statistics.TemporalStats.MostActiveDay.Count) éléments)"
                    }

                    if ($statistics.TemporalStats.MostActiveMonth) {
                        $report += "`n* Mois le plus actif : $($statistics.TemporalStats.MostActiveMonth.Month) ($($statistics.TemporalStats.MostActiveMonth.Count) éléments)"
                    }

                    if ($statistics.TemporalStats.MostActiveWeekday) {
                        $report += "`n* Jour de la semaine le plus actif : $($statistics.TemporalStats.MostActiveWeekday.Weekday) ($($statistics.TemporalStats.MostActiveWeekday.Count) éléments)"
                    }

                    if ($statistics.TemporalStats.MostActiveHour) {
                        $report += "`n* Heure la plus active : $($statistics.TemporalStats.MostActiveHour.Hour) ($($statistics.TemporalStats.MostActiveHour.Count) éléments)"
                    }
                }

                if ($statistics.ContainsKey('ConfidenceStats')) {
                    $report += @"

-------------------------------------------------------
STATISTIQUES DE CONFIANCE
-------------------------------------------------------
* Score de confiance moyen : $($statistics.ConfidenceStats.AverageConfidence)
* Score de confiance médian : $($statistics.ConfidenceStats.MedianConfidence)
* Plage de confiance : $($statistics.ConfidenceStats.MinConfidence) - $($statistics.ConfidenceStats.MaxConfidence)
"@

                    # Distribution des plages de confiance
                    $report += "`n`n* Distribution des scores de confiance :"
                    foreach ($range in $statistics.ConfidenceStats.ConfidenceRanges.Keys) {
                        $count = $statistics.ConfidenceStats.ConfidenceRanges[$range]
                        $percent = $statistics.ConfidenceStats.ConfidenceRangePercentages[$range]
                        $report += "`n  - $range : $count ($percent%)"
                    }

                    if ($statistics.ConfidenceStats.DominantRange) {
                        $report += "`n`n* Plage dominante : $($statistics.ConfidenceStats.DominantRange.Range) ($($statistics.ConfidenceStats.DominantRange.Count) éléments)"
                    }
                }

                if ($statistics.ContainsKey('ContentStats')) {
                    $report += @"

-------------------------------------------------------
STATISTIQUES DE CONTENU
-------------------------------------------------------
* Taille moyenne : $($statistics.ContentStats.AverageSize) caractères
* Taille médiane : $($statistics.ContentStats.MedianSize) caractères
* Plage de taille : $($statistics.ContentStats.MinSize) - $($statistics.ContentStats.MaxSize) caractères
* Taille totale : $($statistics.ContentStats.TotalSize) caractères
"@

                    # Distribution des plages de taille
                    $report += "`n`n* Distribution des tailles de contenu :"
                    foreach ($range in $statistics.ContentStats.ContentSizeRanges.Keys) {
                        $count = $statistics.ContentStats.ContentSizeRanges[$range]
                        $percent = $statistics.ContentStats.ContentSizeRangePercentages[$range]
                        $report += "`n  - $range : $count ($percent%)"
                    }

                    # Statistiques spécifiques aux types
                    $report += "`n`n* Statistiques par type :"
                    foreach ($type in $statistics.ContentStats.TypeSpecificStats.Keys) {
                        $typeStats = $statistics.ContentStats.TypeSpecificStats[$type]
                        $report += "`n  - $type :"
                        $report += "`n    * Nombre d'éléments : $($typeStats.Count)"
                        $report += "`n    * Taille moyenne : $($typeStats.AverageSize) caractères"

                        if ($type -eq "TextExtractedInfo" -and $typeStats.ContainsKey("AverageWords")) {
                            $report += "`n    * Nombre moyen de mots : $($typeStats.AverageWords)"
                        }
                    }
                }

                if ($statistics.ContainsKey('MetadataStats')) {
                    $report += @"

-------------------------------------------------------
STATISTIQUES DE MÉTADONNÉES
-------------------------------------------------------
* Éléments avec métadonnées : $($statistics.MetadataStats.ItemsWithMetadata) ($($statistics.MetadataStats.PercentItemsWithMetadata)%)
* Nombre total d'éléments de métadonnées : $($statistics.MetadataStats.TotalMetadataItems)
* Moyenne de métadonnées par élément : $($statistics.MetadataStats.AverageMetadataPerItem)
* Nombre de clés uniques : $($statistics.MetadataStats.UniqueMetadataKeys)
"@

                    # Clés de métadonnées les plus courantes
                    $report += "`n`n* Clés de métadonnées les plus courantes :"
                    foreach ($keyInfo in $statistics.MetadataStats.MostCommonMetadataKeys) {
                        $report += "`n  - $($keyInfo.Key) : $($keyInfo.Count) ($($keyInfo.Percentage)%)"

                        # Types de valeurs pour cette clé
                        if ($statistics.MetadataStats.MetadataValueTypes.ContainsKey($keyInfo.Key)) {
                            $report += "`n    * Types de valeurs :"
                            foreach ($valueType in $statistics.MetadataStats.MetadataValueTypes[$keyInfo.Key].Keys) {
                                $count = $statistics.MetadataStats.MetadataValueTypes[$keyInfo.Key][$valueType]
                                $report += "`n      - $valueType : $count"
                            }
                        }
                    }
                }

                $report += "`n`n======================================================="

                return $report
            }
            'HTML' {
                # Format HTML
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport d'analyse statistique des informations extraites</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #2980b9;
            margin-top: 30px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .stats-section {
            background-color: #f9f9f9;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .stats-header {
            background-color: #3498db;
            color: white;
            padding: 10px;
            border-radius: 5px 5px 0 0;
            margin: -15px -15px 15px -15px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 0.8em;
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport d'analyse statistique des informations extraites</h1>
        <p><strong>Généré le :</strong> $($statistics.GeneratedAt)</p>
        <p><strong>Type d'analyse :</strong> $($statistics.StatisticsType)</p>
        <p><strong>Nombre d'éléments :</strong> $($statistics.ItemCount)</p>
"@

                if ($PSCmdlet.ParameterSetName -eq 'Collection') {
                    $html += "<p><strong>Nom de la collection :</strong> $($statistics.CollectionName)</p>"
                }

                if ($statistics.ContainsKey('BasicStats')) {
                    $html += @"
        <div class="stats-section">
            <div class="stats-header">
                <h2>Statistiques de base</h2>
            </div>

            <h3>Distribution des types</h3>
            <table>
                <tr>
                    <th>Type</th>
                    <th>Nombre</th>
                    <th>Pourcentage</th>
                </tr>
"@

                    foreach ($type in $statistics.BasicStats.TypeDistribution.Keys) {
                        $count = $statistics.BasicStats.TypeDistribution[$type]
                        $percent = $statistics.BasicStats.TypePercentages[$type]
                        $html += @"
                <tr>
                    <td>$type</td>
                    <td>$count</td>
                    <td>$percent%</td>
                </tr>
"@
                    }

                    $html += @"
            </table>

            <h3>Distribution des sources</h3>
            <table>
                <tr>
                    <th>Source</th>
                    <th>Nombre</th>
                    <th>Pourcentage</th>
                </tr>
"@

                    foreach ($source in $statistics.BasicStats.SourceDistribution.Keys) {
                        $count = $statistics.BasicStats.SourceDistribution[$source]
                        $percent = $statistics.BasicStats.SourcePercentages[$source]
                        $html += @"
                <tr>
                    <td>$source</td>
                    <td>$count</td>
                    <td>$percent%</td>
                </tr>
"@
                    }

                    $html += @"
            </table>

            <h3>Distribution des états de traitement</h3>
            <table>
                <tr>
                    <th>État</th>
                    <th>Nombre</th>
                    <th>Pourcentage</th>
                </tr>
"@

                    foreach ($state in $statistics.BasicStats.ProcessingStateDistribution.Keys) {
                        $count = $statistics.BasicStats.ProcessingStateDistribution[$state]
                        $percent = $statistics.BasicStats.ProcessingStatePercentages[$state]
                        $html += @"
                <tr>
                    <td>$state</td>
                    <td>$count</td>
                    <td>$percent%</td>
                </tr>
"@
                    }

                    $html += @"
            </table>
        </div>
"@
                }

                if ($statistics.ContainsKey('TemporalStats')) {
                    $html += @"
        <div class="stats-section">
            <div class="stats-header">
                <h2>Statistiques temporelles</h2>
            </div>

            <p><strong>Âge moyen :</strong> $($statistics.TemporalStats.AverageAgeInDays) jours ($($statistics.TemporalStats.AverageAgeInMonths) mois)</p>
"@

                    if ($statistics.TemporalStats.MostActiveDay) {
                        $html += "<p><strong>Jour le plus actif :</strong> $($statistics.TemporalStats.MostActiveDay.Date) ($($statistics.TemporalStats.MostActiveDay.Count) éléments)</p>"
                    }

                    if ($statistics.TemporalStats.MostActiveMonth) {
                        $html += "<p><strong>Mois le plus actif :</strong> $($statistics.TemporalStats.MostActiveMonth.Month) ($($statistics.TemporalStats.MostActiveMonth.Count) éléments)</p>"
                    }

                    if ($statistics.TemporalStats.MostActiveWeekday) {
                        $html += "<p><strong>Jour de la semaine le plus actif :</strong> $($statistics.TemporalStats.MostActiveWeekday.Weekday) ($($statistics.TemporalStats.MostActiveWeekday.Count) éléments)</p>"
                    }

                    if ($statistics.TemporalStats.MostActiveHour) {
                        $html += "<p><strong>Heure la plus active :</strong> $($statistics.TemporalStats.MostActiveHour.Hour) ($($statistics.TemporalStats.MostActiveHour.Count) éléments)</p>"
                    }

                    $html += @"
        </div>
"@
                }

                if ($statistics.ContainsKey('ConfidenceStats')) {
                    $html += @"
        <div class="stats-section">
            <div class="stats-header">
                <h2>Statistiques de confiance</h2>
            </div>

            <p><strong>Score de confiance moyen :</strong> $($statistics.ConfidenceStats.AverageConfidence)</p>
            <p><strong>Score de confiance médian :</strong> $($statistics.ConfidenceStats.MedianConfidence)</p>
            <p><strong>Plage de confiance :</strong> $($statistics.ConfidenceStats.MinConfidence) - $($statistics.ConfidenceStats.MaxConfidence)</p>

            <h3>Distribution des scores de confiance</h3>
            <table>
                <tr>
                    <th>Plage</th>
                    <th>Nombre</th>
                    <th>Pourcentage</th>
                </tr>
"@

                    foreach ($range in $statistics.ConfidenceStats.ConfidenceRanges.Keys) {
                        $count = $statistics.ConfidenceStats.ConfidenceRanges[$range]
                        $percent = $statistics.ConfidenceStats.ConfidenceRangePercentages[$range]
                        $html += @"
                <tr>
                    <td>$range</td>
                    <td>$count</td>
                    <td>$percent%</td>
                </tr>
"@
                    }

                    $html += @"
            </table>
"@

                    if ($statistics.ConfidenceStats.DominantRange) {
                        $html += "<p><strong>Plage dominante :</strong> $($statistics.ConfidenceStats.DominantRange.Range) ($($statistics.ConfidenceStats.DominantRange.Count) éléments)</p>"
                    }

                    $html += @"
        </div>
"@
                }

                if ($statistics.ContainsKey('ContentStats')) {
                    $html += @"
        <div class="stats-section">
            <div class="stats-header">
                <h2>Statistiques de contenu</h2>
            </div>

            <p><strong>Taille moyenne :</strong> $($statistics.ContentStats.AverageSize) caractères</p>
            <p><strong>Taille médiane :</strong> $($statistics.ContentStats.MedianSize) caractères</p>
            <p><strong>Plage de taille :</strong> $($statistics.ContentStats.MinSize) - $($statistics.ContentStats.MaxSize) caractères</p>
            <p><strong>Taille totale :</strong> $($statistics.ContentStats.TotalSize) caractères</p>

            <h3>Distribution des tailles de contenu</h3>
            <table>
                <tr>
                    <th>Plage</th>
                    <th>Nombre</th>
                    <th>Pourcentage</th>
                </tr>
"@

                    foreach ($range in $statistics.ContentStats.ContentSizeRanges.Keys) {
                        $count = $statistics.ContentStats.ContentSizeRanges[$range]
                        $percent = $statistics.ContentStats.ContentSizeRangePercentages[$range]
                        $html += @"
                <tr>
                    <td>$range</td>
                    <td>$count</td>
                    <td>$percent%</td>
                </tr>
"@
                    }

                    $html += @"
            </table>

            <h3>Statistiques par type</h3>
"@

                    foreach ($type in $statistics.ContentStats.TypeSpecificStats.Keys) {
                        $typeStats = $statistics.ContentStats.TypeSpecificStats[$type]
                        $html += @"
            <h4>$type</h4>
            <ul>
                <li><strong>Nombre d'éléments :</strong> $($typeStats.Count)</li>
                <li><strong>Taille moyenne :</strong> $($typeStats.AverageSize) caractères</li>
"@

                        if ($type -eq "TextExtractedInfo" -and $typeStats.ContainsKey("AverageWords")) {
                            $html += "<li><strong>Nombre moyen de mots :</strong> $($typeStats.AverageWords)</li>"
                        }

                        $html += @"
            </ul>
"@
                    }

                    $html += @"
        </div>
"@
                }

                if ($statistics.ContainsKey('MetadataStats')) {
                    $html += @"
        <div class="stats-section">
            <div class="stats-header">
                <h2>Statistiques de métadonnées</h2>
            </div>

            <p><strong>Éléments avec métadonnées :</strong> $($statistics.MetadataStats.ItemsWithMetadata) ($($statistics.MetadataStats.PercentItemsWithMetadata)%)</p>
            <p><strong>Nombre total d'éléments de métadonnées :</strong> $($statistics.MetadataStats.TotalMetadataItems)</p>
            <p><strong>Moyenne de métadonnées par élément :</strong> $($statistics.MetadataStats.AverageMetadataPerItem)</p>
            <p><strong>Nombre de clés uniques :</strong> $($statistics.MetadataStats.UniqueMetadataKeys)</p>

            <h3>Clés de métadonnées les plus courantes</h3>
            <table>
                <tr>
                    <th>Clé</th>
                    <th>Nombre</th>
                    <th>Pourcentage</th>
                </tr>
"@

                    foreach ($keyInfo in $statistics.MetadataStats.MostCommonMetadataKeys) {
                        $html += @"
                <tr>
                    <td>$($keyInfo.Key)</td>
                    <td>$($keyInfo.Count)</td>
                    <td>$($keyInfo.Percentage)%</td>
                </tr>
"@
                    }

                    $html += @"
            </table>
"@

                    foreach ($keyInfo in $statistics.MetadataStats.MostCommonMetadataKeys) {
                        if ($statistics.MetadataStats.MetadataValueTypes.ContainsKey($keyInfo.Key)) {
                            $html += @"
            <h4>Types de valeurs pour "$($keyInfo.Key)"</h4>
            <table>
                <tr>
                    <th>Type</th>
                    <th>Nombre</th>
                </tr>
"@

                            foreach ($valueType in $statistics.MetadataStats.MetadataValueTypes[$keyInfo.Key].Keys) {
                                $count = $statistics.MetadataStats.MetadataValueTypes[$keyInfo.Key][$valueType]
                                $html += @"
                <tr>
                    <td>$valueType</td>
                    <td>$count</td>
                </tr>
"@
                            }

                            $html += @"
            </table>
"@
                        }
                    }

                    $html += @"
        </div>
"@
                }

                $html += @"
        <div class="footer">
            <p>Rapport généré par Get-ExtractedInfoStatistics le $($statistics.GeneratedAt)</p>
        </div>
    </div>
</body>
</html>
"@

                return $html
            }
            'JSON' {
                # Format JSON
                return ConvertTo-Json -InputObject $statistics -Depth 5
            }
            default {
                # Format par défaut (hashtable)
                return $statistics
            }
        }
    }
}

# Exporter la fonction
Export-ModuleMember -Function Get-ExtractedInfoStatistics
