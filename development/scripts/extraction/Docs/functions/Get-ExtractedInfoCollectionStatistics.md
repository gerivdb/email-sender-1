# Get-ExtractedInfoCollectionStatistics

## SYNOPSIS
Génère des statistiques détaillées sur le contenu d'une collection d'informations extraites.

## SYNTAXE

```powershell
Get-ExtractedInfoCollectionStatistics
    -Collection <Hashtable>
    [-IncludeMetadataStatistics]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `Get-ExtractedInfoCollectionStatistics` analyse une collection d'informations extraites et génère un ensemble complet de statistiques sur son contenu. Ces statistiques incluent le nombre total d'éléments, la distribution des types, des sources, des états de traitement, ainsi que des statistiques sur les scores de confiance et les dates d'extraction.

Cette fonction est particulièrement utile pour obtenir une vue d'ensemble rapide du contenu d'une collection, pour l'analyse de données ou pour la génération de rapports.

## PARAMÈTRES

### -Collection
Spécifie la collection pour laquelle générer des statistiques. Ce paramètre est obligatoire.

```yaml
Type: Hashtable
Required: True
```

### -IncludeMetadataStatistics
Indique si des statistiques sur les métadonnées doivent être incluses dans les résultats. L'analyse des métadonnées peut être coûteuse en ressources pour les grandes collections.

```yaml
Type: SwitchParameter
Default: False
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
### System.Collections.Hashtable
Vous pouvez transmettre une collection via le pipeline.

## SORTIES
### System.Collections.Hashtable
Retourne une hashtable contenant les statistiques suivantes :

- **TotalCount** : Nombre total d'éléments dans la collection
- **TypeDistribution** : Distribution des éléments par type (hashtable)
- **SourceDistribution** : Distribution des éléments par source (hashtable)
- **ExtractorDistribution** : Distribution des éléments par extracteur (hashtable)
- **ProcessingStateDistribution** : Distribution des éléments par état de traitement (hashtable)
- **ConfidenceScoreStatistics** : Statistiques sur les scores de confiance (hashtable)
  - Min : Score minimum
  - Max : Score maximum
  - Average : Score moyen
  - Median : Score médian
  - Distribution : Distribution des scores par plage (0-25, 26-50, 51-75, 76-100)
- **ExtractionDateStatistics** : Statistiques sur les dates d'extraction (hashtable)
  - Oldest : Date la plus ancienne
  - Newest : Date la plus récente
  - AverageAge : Âge moyen en jours
  - Distribution : Distribution par période (jour, semaine, mois, année)
- **MetadataStatistics** : Statistiques sur les métadonnées (si IncludeMetadataStatistics est spécifié)
  - KeyDistribution : Distribution des clés de métadonnées
  - ValueTypeDistribution : Distribution des types de valeurs
  - CommonValues : Valeurs communes pour certaines clés

## NOTES
- Cette fonction ne modifie pas la collection originale.
- Pour les grandes collections, l'analyse peut prendre un certain temps, en particulier si l'option IncludeMetadataStatistics est activée.
- Les statistiques sur les dates sont calculées par rapport à la date actuelle.
- Pour les collections vides, des valeurs par défaut ou nulles sont retournées pour la plupart des statistiques.
- Cette fonction est particulièrement utile pour l'analyse exploratoire de données et la génération de rapports.

## EXEMPLES

### Exemple 1 : Générer des statistiques de base pour une collection
```powershell
# Créer une collection avec divers éléments
$collection = New-ExtractedInfoCollection -Name "StatisticsDemo"

# Ajouter des objets variés
$info1 = New-TextExtractedInfo -Source "document1.txt" -Text "Texte 1" -ProcessingState "Raw" -ConfidenceScore 30
$info2 = New-TextExtractedInfo -Source "document2.txt" -Text "Texte 2" -ProcessingState "Processed" -ConfidenceScore 75
$info3 = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Test" } -ProcessingState "Validated" -ConfidenceScore 90
$info4 = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\image.jpg" -ProcessingState "Error" -ConfidenceScore 20

$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2, $info3, $info4)

# Générer des statistiques
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Afficher les statistiques principales
Write-Host "Nombre total d'éléments : $($stats.TotalCount)"
Write-Host "Distribution par type :"
$stats.TypeDistribution.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "Distribution par état de traitement :"
$stats.ProcessingStateDistribution.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "Statistiques de score de confiance :"
Write-Host "  Min: $($stats.ConfidenceScoreStatistics.Min)"
Write-Host "  Max: $($stats.ConfidenceScoreStatistics.Max)"
Write-Host "  Moyenne: $($stats.ConfidenceScoreStatistics.Average)"
```

Cet exemple génère et affiche des statistiques de base pour une collection contenant différents types d'objets d'information extraite.

### Exemple 2 : Générer des statistiques complètes avec analyse des métadonnées
```powershell
# Créer une collection
$collection = New-ExtractedInfoCollection -Name "MetadataStatsDemo"

# Ajouter des objets avec métadonnées
$info1 = New-TextExtractedInfo -Source "article1.html" -Text "Contenu 1"
$info1 = Add-ExtractedInfoMetadata -Info $info1 -Metadata @{
    Category = "News"
    Tags = @("important", "featured")
    Author = "John Doe"
    Views = 1250
}

$info2 = New-TextExtractedInfo -Source "article2.html" -Text "Contenu 2"
$info2 = Add-ExtractedInfoMetadata -Info $info2 -Metadata @{
    Category = "News"
    Tags = @("normal")
    Author = "Jane Smith"
    Views = 850
}

$info3 = New-TextExtractedInfo -Source "article3.html" -Text "Contenu 3"
$info3 = Add-ExtractedInfoMetadata -Info $info3 -Metadata @{
    Category = "Tutorial"
    Tags = @("important", "technical")
    Author = "John Doe"
    Views = 3200
}

$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2, $info3)

# Générer des statistiques avec analyse des métadonnées
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection -IncludeMetadataStatistics

# Afficher les statistiques de métadonnées
Write-Host "Statistiques de métadonnées :"
Write-Host "Distribution des clés :"
$stats.MetadataStatistics.KeyDistribution.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "Distribution des auteurs :"
$stats.MetadataStatistics.CommonValues.Author.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "Distribution des catégories :"
$stats.MetadataStatistics.CommonValues.Category.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "Statistiques des vues :"
Write-Host "  Min: $($stats.MetadataStatistics.NumericStats.Views.Min)"
Write-Host "  Max: $($stats.MetadataStatistics.NumericStats.Views.Max)"
Write-Host "  Moyenne: $($stats.MetadataStatistics.NumericStats.Views.Average)"
```

Cet exemple génère des statistiques complètes pour une collection, y compris une analyse détaillée des métadonnées.

### Exemple 3 : Utiliser les statistiques pour identifier les anomalies
```powershell
# Créer une collection avec de nombreux éléments
$collection = New-ExtractedInfoCollection -Name "AnomalyDetection"

# Ajouter 100 objets avec des scores de confiance normaux (50-90)
$normalInfos = @()
for ($i = 1; $i -le 100; $i++) {
    $score = Get-Random -Minimum 50 -Maximum 91
    $info = New-ExtractedInfo -Source "normal$i" -ConfidenceScore $score -ProcessingState "Processed"
    $normalInfos += $info
}

# Ajouter 5 objets avec des scores de confiance anormalement bas
$anomalyInfos = @()
for ($i = 1; $i -le 5; $i++) {
    $score = Get-Random -Minimum 10 -Maximum 30
    $info = New-ExtractedInfo -Source "anomaly$i" -ConfidenceScore $score -ProcessingState "Error"
    $anomalyInfos += $info
}

$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList ($normalInfos + $anomalyInfos)

# Générer des statistiques
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Identifier les anomalies
$threshold = $stats.ConfidenceScoreStatistics.Average - (2 * [Math]::Sqrt($stats.ConfidenceScoreStatistics.Variance))
Write-Host "Seuil d'anomalie pour le score de confiance : $threshold"

# Récupérer les éléments potentiellement anormaux
$anomalies = Get-ExtractedInfoFromCollection -Collection $collection -MaxConfidenceScore $threshold

Write-Host "Éléments potentiellement anormaux détectés : $($anomalies.Count)"
foreach ($anomaly in $anomalies) {
    Write-Host "- Source: $($anomaly.Source), Score: $($anomaly.ConfidenceScore), État: $($anomaly.ProcessingState)"
}
```

Cet exemple utilise les statistiques pour identifier des anomalies potentielles dans une collection, en se basant sur les scores de confiance.

### Exemple 4 : Générer un rapport de statistiques formaté
```powershell
# Créer une collection avec divers éléments
$collection = New-ExtractedInfoCollection -Name "ReportDemo"

# Ajouter des objets variés (code simplifié pour l'exemple)
$infoList = @()
$types = @("TextExtractedInfo", "StructuredDataExtractedInfo", "MediaExtractedInfo")
$sources = @("web", "api", "file", "database")
$states = @("Raw", "Processed", "Validated", "Error")

for ($i = 0; $i -lt 50; $i++) {
    $type = $types[$i % $types.Count]
    $source = $sources[$i % $sources.Count]
    $state = $states[$i % $states.Count]
    $score = ($i * 2) % 100
    
    switch ($type) {
        "TextExtractedInfo" {
            $info = New-TextExtractedInfo -Source $source -Text "Text $i" -ProcessingState $state -ConfidenceScore $score
        }
        "StructuredDataExtractedInfo" {
            $info = New-StructuredDataExtractedInfo -Source $source -Data @{ Index = $i } -ProcessingState $state -ConfidenceScore $score
        }
        "MediaExtractedInfo" {
            $info = New-MediaExtractedInfo -Source $source -MediaPath "C:\path\to\file$i" -ProcessingState $state -ConfidenceScore $score
        }
    }
    
    $infoList += $info
}

$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $infoList

# Générer des statistiques
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Générer un rapport formaté
$report = @"
# Rapport de statistiques pour la collection "$($collection.Name)"

## Informations générales
- **Nombre total d'éléments** : $($stats.TotalCount)
- **Date de création** : $($collection.CreationDate)
- **Dernière modification** : $($collection.LastModifiedDate)

## Distribution par type
| Type | Nombre | Pourcentage |
|------|--------|-------------|
$(foreach ($type in $stats.TypeDistribution.Keys | Sort-Object) {
    $count = $stats.TypeDistribution[$type]
    $percentage = [Math]::Round(($count / $stats.TotalCount) * 100, 1)
    "| $type | $count | $percentage% |"
})

## Distribution par état de traitement
| État | Nombre | Pourcentage |
|------|--------|-------------|
$(foreach ($state in $stats.ProcessingStateDistribution.Keys | Sort-Object) {
    $count = $stats.ProcessingStateDistribution[$state]
    $percentage = [Math]::Round(($count / $stats.TotalCount) * 100, 1)
    "| $state | $count | $percentage% |"
})

## Statistiques de score de confiance
- **Minimum** : $($stats.ConfidenceScoreStatistics.Min)
- **Maximum** : $($stats.ConfidenceScoreStatistics.Max)
- **Moyenne** : $([Math]::Round($stats.ConfidenceScoreStatistics.Average, 1))
- **Médiane** : $($stats.ConfidenceScoreStatistics.Median)

### Distribution des scores
| Plage | Nombre | Pourcentage |
|-------|--------|-------------|
$(foreach ($range in $stats.ConfidenceScoreStatistics.Distribution.Keys | Sort-Object) {
    $count = $stats.ConfidenceScoreStatistics.Distribution[$range]
    $percentage = [Math]::Round(($count / $stats.TotalCount) * 100, 1)
    "| $range | $count | $percentage% |"
})

## Statistiques temporelles
- **Extraction la plus ancienne** : $($stats.ExtractionDateStatistics.Oldest)
- **Extraction la plus récente** : $($stats.ExtractionDateStatistics.Newest)
- **Âge moyen** : $([Math]::Round($stats.ExtractionDateStatistics.AverageAge, 1)) jours
"@

# Afficher le rapport
Write-Host $report

# Sauvegarder le rapport dans un fichier
$reportPath = Join-Path $env:TEMP "CollectionStats.md"
$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Rapport sauvegardé dans $reportPath"
```

Cet exemple génère un rapport de statistiques formaté en Markdown à partir des statistiques d'une collection.

### Exemple 5 : Comparer les statistiques de deux collections
```powershell
# Fonction pour créer une collection de test
function New-TestCollection {
    param (
        [string]$Name,
        [int]$ItemCount,
        [int]$MinScore,
        [int]$MaxScore
    )
    
    $collection = New-ExtractedInfoCollection -Name $Name
    $infoList = @()
    
    for ($i = 1; $i -le $ItemCount; $i++) {
        $score = Get-Random -Minimum $MinScore -Maximum ($MaxScore + 1)
        $state = @("Raw", "Processed", "Validated", "Error")[Get-Random -Maximum 4]
        $info = New-ExtractedInfo -Source "source$i" -ConfidenceScore $score -ProcessingState $state
        $infoList += $info
    }
    
    $collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $infoList
    return $collection
}

# Créer deux collections avec des caractéristiques différentes
$collection1 = New-TestCollection -Name "Collection1" -ItemCount 100 -MinScore 60 -MaxScore 90
$collection2 = New-TestCollection -Name "Collection2" -ItemCount 100 -MinScore 30 -MaxScore 70

# Générer des statistiques pour les deux collections
$stats1 = Get-ExtractedInfoCollectionStatistics -Collection $collection1
$stats2 = Get-ExtractedInfoCollectionStatistics -Collection $collection2

# Comparer les statistiques
Write-Host "Comparaison des collections :"
Write-Host "Collection 1 vs Collection 2"
Write-Host "-------------------------"
Write-Host "Nombre d'éléments : $($stats1.TotalCount) vs $($stats2.TotalCount)"
Write-Host "Score moyen : $([Math]::Round($stats1.ConfidenceScoreStatistics.Average, 1)) vs $([Math]::Round($stats2.ConfidenceScoreStatistics.Average, 1))"
Write-Host "Score médian : $($stats1.ConfidenceScoreStatistics.Median) vs $($stats2.ConfidenceScoreStatistics.Median)"
Write-Host "Score minimum : $($stats1.ConfidenceScoreStatistics.Min) vs $($stats2.ConfidenceScoreStatistics.Min)"
Write-Host "Score maximum : $($stats1.ConfidenceScoreStatistics.Max) vs $($stats2.ConfidenceScoreStatistics.Max)"

# Comparer la distribution des états
Write-Host "`nDistribution des états :"
$allStates = ($stats1.ProcessingStateDistribution.Keys + $stats2.ProcessingStateDistribution.Keys) | Select-Object -Unique | Sort-Object
foreach ($state in $allStates) {
    $count1 = if ($stats1.ProcessingStateDistribution.ContainsKey($state)) { $stats1.ProcessingStateDistribution[$state] } else { 0 }
    $count2 = if ($stats2.ProcessingStateDistribution.ContainsKey($state)) { $stats2.ProcessingStateDistribution[$state] } else { 0 }
    $diff = $count1 - $count2
    $diffStr = if ($diff -gt 0) { "+$diff" } else { $diff }
    
    Write-Host "$state : $count1 vs $count2 ($diffStr)"
}
```

Cet exemple compare les statistiques de deux collections différentes pour identifier les similitudes et les différences.

## LIENS CONNEXES
- [New-ExtractedInfoCollection](New-ExtractedInfoCollection.md)
- [Add-ExtractedInfoToCollection](Add-ExtractedInfoToCollection.md)
- [Get-ExtractedInfoFromCollection](Get-ExtractedInfoFromCollection.md)
- [Copy-ExtractedInfoCollection](Copy-ExtractedInfoCollection.md)
- [ConvertTo-ExtractedInfoJson](ConvertTo-ExtractedInfoJson.md)
