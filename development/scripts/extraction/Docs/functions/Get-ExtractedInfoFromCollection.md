# Get-ExtractedInfoFromCollection

## SYNOPSIS

Récupère un ou plusieurs objets d'information extraite d'une collection selon différents critères de filtrage.

## SYNTAXE

```powershell
Get-ExtractedInfoFromCollection
    -Collection <Hashtable>
    [-Id <String>]
    [-Type <String>]
    [-Source <String>]
    [-ExtractorName <String>]
    [-ProcessingState <String>]
    [-MinConfidenceScore <Int32>]
    [-MaxConfidenceScore <Int32>]
    [-MetadataFilter <Hashtable>]
    [-First <Int32>]
    [-Skip <Int32>]
    [-SortBy <String>]
    [-Descending]
    [<CommonParameters>]
```plaintext
## DESCRIPTION

La fonction `Get-ExtractedInfoFromCollection` permet de rechercher et récupérer des objets d'information extraite dans une collection selon divers critères de filtrage. Elle offre des fonctionnalités avancées de filtrage, de tri et de pagination.

Cette fonction utilise automatiquement les index de la collection (si disponibles) pour optimiser les performances des recherches.

## PARAMÈTRES

### -Collection

Spécifie la collection dans laquelle effectuer la recherche. Ce paramètre est obligatoire.

```yaml
Type: Hashtable
Required: True
```plaintext
### -Id

Spécifie l'identifiant unique (GUID) de l'objet à récupérer. Si ce paramètre est spécifié, les autres critères de filtrage sont ignorés.

```yaml
Type: String
Required: False
```plaintext
### -Type

Filtre les objets par type. Les valeurs valides sont : "ExtractedInfo", "TextExtractedInfo", "StructuredDataExtractedInfo", "MediaExtractedInfo".

```yaml
Type: String
Required: False
```plaintext
### -Source

Filtre les objets par source.

```yaml
Type: String
Required: False
```plaintext
### -ExtractorName

Filtre les objets par nom d'extracteur.

```yaml
Type: String
Required: False
```plaintext
### -ProcessingState

Filtre les objets par état de traitement. Les valeurs valides sont : "Raw", "Processed", "Validated", "Error".

```yaml
Type: String
Required: False
```plaintext
### -MinConfidenceScore

Filtre les objets ayant un score de confiance supérieur ou égal à la valeur spécifiée.

```yaml
Type: Int32
Required: False
Default: 0
```plaintext
### -MaxConfidenceScore

Filtre les objets ayant un score de confiance inférieur ou égal à la valeur spécifiée.

```yaml
Type: Int32
Required: False
Default: 100
```plaintext
### -MetadataFilter

Filtre les objets selon leurs métadonnées. Spécifiez une hashtable où les clés sont les noms des métadonnées et les valeurs sont les valeurs à rechercher.

```yaml
Type: Hashtable
Required: False
```plaintext
### -First

Limite le nombre de résultats retournés aux n premiers éléments.

```yaml
Type: Int32
Required: False
```plaintext
### -Skip

Ignore les n premiers éléments des résultats.

```yaml
Type: Int32
Required: False
Default: 0
```plaintext
### -SortBy

Spécifie la propriété selon laquelle trier les résultats. Les valeurs valides sont : "Id", "Source", "ExtractorName", "ExtractionDate", "LastModifiedDate", "ProcessingState", "ConfidenceScore".

```yaml
Type: String
Required: False
Default: "ExtractionDate"
```plaintext
### -Descending

Indique si le tri doit être effectué dans l'ordre décroissant.

```yaml
Type: SwitchParameter
Required: False
Default: False
```plaintext
### <CommonParameters>

Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES

### System.Collections.Hashtable

Vous pouvez transmettre une collection via le pipeline.

## SORTIES

### System.Collections.Hashtable ou System.Collections.Hashtable[]

Si le paramètre `-Id` est spécifié, la fonction retourne un seul objet d'information extraite ou $null si aucun objet correspondant n'est trouvé.

Dans tous les autres cas, la fonction retourne un tableau d'objets d'information extraite correspondant aux critères de filtrage. Si aucun objet ne correspond, un tableau vide est retourné.

## NOTES

- Cette fonction ne modifie pas la collection originale.
- Si la collection est indexée, la fonction utilise automatiquement les index pour optimiser les recherches par ID, type, source et état de traitement.
- Pour les collections non indexées, tous les éléments sont parcourus séquentiellement, ce qui peut être moins performant pour les grandes collections.
- Le filtrage par métadonnées est toujours effectué séquentiellement, même pour les collections indexées.
- La combinaison des paramètres `-First` et `-Skip` permet d'implémenter une pagination des résultats.
- Pour des recherches plus complexes ou des filtres personnalisés, vous pouvez utiliser la fonction `Where-Object` de PowerShell sur les résultats.

## EXEMPLES

### Exemple 1 : Récupérer un objet par son ID

```powershell
# Créer une collection et y ajouter un élément

$collection = New-ExtractedInfoCollection -Name "MaCollection"
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info

# Récupérer l'objet par son ID

$retrievedInfo = Get-ExtractedInfoFromCollection -Collection $collection -Id $info.Id

# Vérifier que l'objet récupéré est le bon

if ($retrievedInfo.Id -eq $info.Id) {
    Write-Host "Objet récupéré avec succès."
}
```plaintext
Cet exemple récupère un objet spécifique dans une collection en utilisant son ID.

### Exemple 2 : Filtrer les objets par type

```powershell
# Créer une collection avec différents types d'objets

$collection = New-ExtractedInfoCollection -Name "MixedCollection" -CreateIndexes

# Ajouter des objets de différents types

$textInfo = New-TextExtractedInfo -Source "document.txt" -Text "Exemple de texte"
$structuredInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Test"; Value = 123 }
$mediaInfo = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\Images\image.jpg" -MediaType "Image"

$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($textInfo, $structuredInfo, $mediaInfo)

# Récupérer uniquement les objets de type texte

$textInfos = Get-ExtractedInfoFromCollection -Collection $collection -Type "TextExtractedInfo"

Write-Host "Nombre d'objets de type texte : $($textInfos.Count)"
```plaintext
Cet exemple filtre les objets d'une collection pour ne récupérer que ceux de type TextExtractedInfo.

### Exemple 3 : Filtrer par état de traitement et score de confiance

```powershell
# Créer une collection

$collection = New-ExtractedInfoCollection -Name "ProcessingCollection" -CreateIndexes

# Ajouter des objets avec différents états et scores

$info1 = New-ExtractedInfo -Source "source1" -ProcessingState "Raw" -ConfidenceScore 30
$info2 = New-ExtractedInfo -Source "source2" -ProcessingState "Processed" -ConfidenceScore 70
$info3 = New-ExtractedInfo -Source "source3" -ProcessingState "Validated" -ConfidenceScore 90
$info4 = New-ExtractedInfo -Source "source4" -ProcessingState "Error" -ConfidenceScore 20

$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2, $info3, $info4)

# Récupérer les objets traités ou validés avec un score de confiance d'au moins 60

$highConfidenceProcessedInfos = Get-ExtractedInfoFromCollection -Collection $collection `
                                                              -ProcessingState "Processed", "Validated" `
                                                              -MinConfidenceScore 60

Write-Host "Nombre d'objets traités ou validés avec un score élevé : $($highConfidenceProcessedInfos.Count)"
foreach ($info in $highConfidenceProcessedInfos) {
    Write-Host "- Source: $($info.Source), État: $($info.ProcessingState), Score: $($info.ConfidenceScore)"
}
```plaintext
Cet exemple filtre les objets par état de traitement (Processed ou Validated) et par score de confiance (au moins 60).

### Exemple 4 : Filtrer par métadonnées

```powershell
# Créer une collection

$collection = New-ExtractedInfoCollection -Name "TaggedCollection"

# Ajouter des objets avec différentes métadonnées

$info1 = New-TextExtractedInfo -Source "doc1.txt" -Text "Texte 1"
$info1 = Add-ExtractedInfoMetadata -Info $info1 -Metadata @{
    Category = "Documentation"
    Tags = @("important", "urgent")
    Priority = "High"
}

$info2 = New-TextExtractedInfo -Source "doc2.txt" -Text "Texte 2"
$info2 = Add-ExtractedInfoMetadata -Info $info2 -Metadata @{
    Category = "Documentation"
    Tags = @("normal")
    Priority = "Medium"
}

$info3 = New-TextExtractedInfo -Source "doc3.txt" -Text "Texte 3"
$info3 = Add-ExtractedInfoMetadata -Info $info3 -Metadata @{
    Category = "Notes"
    Tags = @("important")
    Priority = "Low"
}

$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2, $info3)

# Filtrer par métadonnées

$metadataFilter = @{
    Category = "Documentation"
    Priority = "High"
}

$filteredInfos = Get-ExtractedInfoFromCollection -Collection $collection -MetadataFilter $metadataFilter

Write-Host "Nombre d'objets correspondant au filtre de métadonnées : $($filteredInfos.Count)"
foreach ($info in $filteredInfos) {
    Write-Host "- Source: $($info.Source), Catégorie: $($info.Metadata.Category), Priorité: $($info.Metadata.Priority)"
}
```plaintext
Cet exemple filtre les objets selon leurs métadonnées, en recherchant ceux qui ont une catégorie "Documentation" et une priorité "High".

### Exemple 5 : Utiliser la pagination

```powershell
# Créer une collection avec de nombreux éléments

$collection = New-ExtractedInfoCollection -Name "LargeCollection" -CreateIndexes

# Ajouter 100 objets

$infoList = @()
for ($i = 1; $i -le 100; $i++) {
    $info = New-ExtractedInfo -Source "source$i" -ConfidenceScore ($i % 100)
    $infoList += $info
}
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $infoList

# Implémenter une pagination (10 éléments par page)

$pageSize = 10
$totalPages = [Math]::Ceiling($collection.Items.Count / $pageSize)

for ($page = 1; $page -le 3; $page++) { # Afficher seulement les 3 premières pages

    $skip = ($page - 1) * $pageSize
    $pageItems = Get-ExtractedInfoFromCollection -Collection $collection -Skip $skip -First $pageSize -SortBy "ConfidenceScore" -Descending
    
    Write-Host "Page $page sur $totalPages (éléments avec le score le plus élevé d'abord):"
    foreach ($item in $pageItems) {
        Write-Host "- Source: $($item.Source), Score: $($item.ConfidenceScore)"
    }
    Write-Host ""
}
```plaintext
Cet exemple montre comment implémenter une pagination des résultats en utilisant les paramètres `-Skip` et `-First`, avec un tri par score de confiance décroissant.

### Exemple 6 : Combiner plusieurs critères de filtrage

```powershell
# Créer une collection

$collection = New-ExtractedInfoCollection -Name "FilteredCollection" -CreateIndexes

# Ajouter des objets variés

$infoList = @()
$sources = @("web", "api", "file", "database")
$extractors = @("WebExtractor", "ApiExtractor", "FileExtractor", "DbExtractor")
$states = @("Raw", "Processed", "Validated", "Error")

for ($i = 0; $i -lt 20; $i++) {
    $source = $sources[$i % $sources.Count]
    $extractor = $extractors[$i % $extractors.Count]
    $state = $states[$i % $states.Count]
    $score = ($i * 5) % 100
    
    $info = New-ExtractedInfo -Source $source -ExtractorName $extractor -ProcessingState $state -ConfidenceScore $score
    $infoList += $info
}
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $infoList

# Filtrage complexe

$filteredInfos = Get-ExtractedInfoFromCollection -Collection $collection `
                                               -Source "web", "api" `
                                               -ExtractorName "WebExtractor" `
                                               -ProcessingState "Processed", "Validated" `
                                               -MinConfidenceScore 50 `
                                               -SortBy "ConfidenceScore" `
                                               -Descending

Write-Host "Résultats du filtrage complexe :"
foreach ($info in $filteredInfos) {
    Write-Host "- Source: $($info.Source), Extracteur: $($info.ExtractorName), État: $($info.ProcessingState), Score: $($info.ConfidenceScore)"
}
```plaintext
Cet exemple combine plusieurs critères de filtrage pour effectuer une recherche complexe dans une collection.

## LIENS CONNEXES

- [New-ExtractedInfoCollection](New-ExtractedInfoCollection.md)
- [Add-ExtractedInfoToCollection](Add-ExtractedInfoToCollection.md)
- [Get-ExtractedInfoCollectionStatistics](Get-ExtractedInfoCollectionStatistics.md)
- [Copy-ExtractedInfoCollection](Copy-ExtractedInfoCollection.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
