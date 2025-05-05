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
        Name = "Collection Temporelle"
        Description = "Collection d'informations extraites sur une période de $MonthsOfData mois"
        CreatedAt = (Get-Date).AddMonths(-$MonthsOfData)
        Items = @{}
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
            Date = $startDate.AddMonths(2).AddDays(15)
            Name = "Mise à jour majeure du système d'extraction"
            Impact = 1.5
            Duration = 3
        },
        @{
            Date = $startDate.AddMonths(5).AddDays(10)
            Name = "Intégration de nouvelles sources de données"
            Impact = 2.0
            Duration = 5
        },
        @{
            Date = $startDate.AddMonths(8).AddDays(20)
            Name = "Maintenance du système"
            Impact = 0.5
            Duration = 2
        },
        @{
            Date = $startDate.AddMonths(10).AddDays(5)
            Name = "Optimisation des algorithmes d'extraction"
            Impact = 1.3
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
                    _Type = "TextExtractedInfo"
                    Id = [guid]::NewGuid().ToString()
                    Source = "document_$($currentDate.ToString('yyyyMMdd'))_$i.txt"
                    Text = "Contenu extrait le $($currentDate.ToString('dd/MM/yyyy')). Élément $i de la journée."
                    Language = if ((Get-Random -Minimum 0 -Maximum 100) -lt 80) { "fr" } else { "en" }
                    ConfidenceScore = 70 + (Get-Random -Minimum 0 -Maximum 30)
                    ExtractedAt = $currentDate.AddHours((Get-Random -Minimum 0 -Maximum 24)).AddMinutes((Get-Random -Minimum 0 -Maximum 60))
                    ProcessingState = "Processed"
                    Metadata = @{
                        Author = "Auteur " + (Get-Random -Minimum 1 -Maximum 20)
                        Category = "Catégorie " + [char](64 + (Get-Random -Minimum 1 -Maximum 6))
                        Tags = @("texte", "document", "jour" + $currentDate.Day, "mois" + $currentDate.Month)
                    }
                }
                
                $collection.Items[$textInfo.Id] = $textInfo
            } 
            else {
                # Créer un élément structuré
                $structuredInfo = @{
                    _Type = "StructuredDataExtractedInfo"
                    Id = [guid]::NewGuid().ToString()
                    Source = "data_$($currentDate.ToString('yyyyMMdd'))_$i.json"
                    Data = @(
                        @{ Name = "Métrique A"; Value = 100 + (Get-Random -Minimum 0 -Maximum 100); Category = "Catégorie A" }
                        @{ Name = "Métrique B"; Value = 200 + (Get-Random -Minimum 0 -Maximum 150); Category = "Catégorie B" }
                        @{ Name = "Métrique C"; Value = 150 + (Get-Random -Minimum 0 -Maximum 120); Category = "Catégorie A" }
                    )
                    DataFormat = if ((Get-Random -Minimum 0 -Maximum 100) -lt 70) { "Json" } else { "Xml" }
                    ConfidenceScore = 80 + (Get-Random -Minimum 0 -Maximum 20)
                    ExtractedAt = $currentDate.AddHours((Get-Random -Minimum 0 -Maximum 24)).AddMinutes((Get-Random -Minimum 0 -Maximum 60))
                    ProcessingState = "Processed"
                    Metadata = @{
                        Source = if ((Get-Random -Minimum 0 -Maximum 100) -lt 60) { "API" } else { "File" }
                        Version = "1." + (Get-Random -Minimum 0 -Maximum 10)
                        Tags = @("data") + @(if ((Get-Random -Minimum 0 -Maximum 100) -lt 70) { "json" } else { "xml" }) + @("jour" + $currentDate.Day, "mois" + $currentDate.Month)
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
                    Period = $periodKey
                    Date = $date
                    TotalCount = 0
                    TextCount = 0
                    StructuredCount = 0
                    ConfidenceScores = @()
                    Categories = @{}
                }
            }
            
            # Mettre à jour les compteurs
            $aggregatedData[$periodKey].TotalCount++
            
            if ($item._Type -eq "TextExtractedInfo") {
                $aggregatedData[$periodKey].TextCount++
            }
            else {
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
            }
            else {
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
        Labels = $dailyData.Period
        Series = @{
            "Total" = $dailyData.TotalCount
            "Textuels" = $dailyData.TextCount
            "Structurés" = $dailyData.StructuredCount
        }
        Options = @{
            Title = "Évolution quotidienne du nombre d'extractions"
            Colors = @("#4e79a7", "#f28e2c", "#59a14f")
            Smooth = $true
        }
    }
    
    $report = Add-ExtractedInfoReportChart -Report $report -Title "Évolution quotidienne du nombre d'extractions" -Data $dailyTrendData -ChartType "Line" -Options @{
        Smooth = $true
        FillArea = $false
    }
    
    # Créer un graphique de tendance de la qualité quotidienne
    $dailyQualityData = @{
        ChartType = "Line"
        Labels = $dailyData.Period
        Series = @{
            "Score moyen" = $dailyData.AvgConfidence
            "Score minimum" = $dailyData.MinConfidence
            "Score maximum" = $dailyData.MaxConfidence
        }
        Options = @{
            Title = "Évolution quotidienne des scores de confiance"
            Colors = @("#4e79a7", "#f28e2c", "#59a14f")
            Smooth = $true
        }
    }
    
    $report = Add-ExtractedInfoReportChart -Report $report -Title "Évolution quotidienne des scores de confiance" -Data $dailyQualityData -ChartType "Line" -Options @{
        Smooth = $true
        FillArea = $false
    }
    
    # Ajouter une section d'analyse hebdomadaire
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Analyse hebdomadaire" -Content "Cette section présente l'analyse des extractions par semaine." -Type "Text" -Level 1
    
    # Créer un graphique de tendance hebdomadaire
    $weeklyTrendData = @{
        ChartType = "Line"
        Labels = $weeklyData.Period
        Series = @{
            "Total" = $weeklyData.TotalCount
            "Textuels" = $weeklyData.TextCount
            "Structurés" = $weeklyData.StructuredCount
        }
        Options = @{
            Title = "Évolution hebdomadaire du nombre d'extractions"
            Colors = @("#4e79a7", "#f28e2c", "#59a14f")
            Smooth = $true
        }
    }
    
    $report = Add-ExtractedInfoReportChart -Report $report -Title "Évolution hebdomadaire du nombre d'extractions" -Data $weeklyTrendData -ChartType "Line" -Options @{
        Smooth = $true
        FillArea = $true
    }
    
    # Créer un graphique en barres pour la répartition hebdomadaire
    $weeklyBarData = @{
        ChartType = "Bar"
        Labels = $weeklyData.Period
        Values = $weeklyData.TotalCount
        Options = @{
            Title = "Nombre d'extractions par semaine"
            Colors = @("#4e79a7")
        }
    }
    
    $report = Add-ExtractedInfoReportChart -Report $report -Title "Nombre d'extractions par semaine" -Data $weeklyBarData -ChartType "Bar"
    
    # Ajouter une section d'analyse mensuelle
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Analyse mensuelle" -Content "Cette section présente l'analyse des extractions par mois." -Type "Text" -Level 1
    
    # Créer un tableau des statistiques mensuelles
    $monthlyStats = $monthlyData | ForEach-Object {
        [PSCustomObject]@{
            Mois = $_.Period
            "Nombre total" = $_.TotalCount
            "Textuels" = $_.TextCount
            "Structurés" = $_.StructuredCount
            "Score moyen" = $_.AvgConfidence
            "Catégorie principale" = $_.MainCategory
        }
    }
    
    $report = Add-ExtractedInfoReportSection -Report $report -Title "Statistiques mensuelles" -Content $monthlyStats -Type "Table" -Level 2
    
    # Créer un graphique en aires pour la tendance mensuelle
    $monthlyAreaData = @{
        ChartType = "Area"
        Labels = $monthlyData.Period
        Series = @{
            "Textuels" = $monthlyData.TextCount
            "Structurés" = $monthlyData.StructuredCount
        }
        Options = @{
            Title = "Évolution mensuelle par type d'extraction"
            Colors = @("#f28e2c", "#59a14f")
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
        }
        else {
            100
        }
        
        $qualityGrowth = if ($previousMonth.AvgConfidence -gt 0) {
            [math]::Round(($currentMonth.AvgConfidence - $previousMonth.AvgConfidence) / $previousMonth.AvgConfidence * 100, 1)
        }
        else {
            0
        }
        
        $growthRates += [PSCustomObject]@{
            "Période" = "$($previousMonth.Period) → $($currentMonth.Period)"
            "Croissance du volume" = "$totalGrowth%"
            "Tendance volume" = if ($totalGrowth -gt 0) { "↑" } elseif ($totalGrowth -lt 0) { "↓" } else { "→" }
            "Croissance de la qualité" = "$qualityGrowth%"
            "Tendance qualité" = if ($qualityGrowth -gt 0) { "↑" } elseif ($qualityGrowth -lt 0) { "↓" } else { "→" }
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
            "Date" = $date.ToString("yyyy-MM-dd")
            "Moyenne mobile (volume)" = $avgTotal
            "Moyenne mobile (qualité)" = $avgConfidence
        }
    }
    
    # Créer un graphique pour les moyennes mobiles
    $movingAvgData = @{
        ChartType = "Line"
        Labels = $movingAverages."Date"
        Series = @{
            "Volume quotidien" = $dailyData | Select-Object -Skip ($windowSize - 1) | ForEach-Object { $_.TotalCount }
            "Moyenne mobile (7 jours)" = $movingAverages."Moyenne mobile (volume)"
        }
        Options = @{
            Title = "Volume quotidien vs. Moyenne mobile (7 jours)"
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
