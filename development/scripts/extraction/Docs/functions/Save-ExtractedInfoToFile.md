# Save-ExtractedInfoToFile

## SYNOPSIS

Sauvegarde un objet d'information extraite ou une collection dans un fichier JSON.

## SYNTAXE

```powershell
Save-ExtractedInfoToFile
    -Info <Hashtable>
    -FilePath <String>
    [-Indent]
    [-ExcludeMetadata]
    [-CreateDirectories]
    [-Force]
    [<CommonParameters>]
```plaintext
```powershell
Save-ExtractedInfoToFile
    -Collection <Hashtable>
    -FilePath <String>
    [-Indent]
    [-ExcludeMetadata]
    [-ExcludeIndexes]
    [-CreateDirectories]
    [-Force]
    [<CommonParameters>]
```plaintext
## DESCRIPTION

La fonction `Save-ExtractedInfoToFile` sauvegarde un objet d'information extraite ou une collection d'informations extraites dans un fichier au format JSON. Cette fonction prend en charge deux modes d'utilisation :

1. Sauvegarde d'un objet d'information extraite individuel en utilisant le paramètre `-Info`.
2. Sauvegarde d'une collection d'informations extraites en utilisant le paramètre `-Collection`.

La fonction offre plusieurs options pour contrôler le format et le contenu du fichier JSON, comme l'indentation, l'exclusion de certaines propriétés, et la création automatique des répertoires parents.

## PARAMÈTRES

### -Info

Spécifie l'objet d'information extraite à sauvegarder. Ce paramètre est obligatoire pour le premier jeu de paramètres.

```yaml
Type: Hashtable
Required: True (pour le premier jeu de paramètres)
```plaintext
### -Collection

Spécifie la collection d'informations extraites à sauvegarder. Ce paramètre est obligatoire pour le deuxième jeu de paramètres.

```yaml
Type: Hashtable
Required: True (pour le deuxième jeu de paramètres)
```plaintext
### -FilePath

Spécifie le chemin du fichier dans lequel sauvegarder l'objet ou la collection. Ce paramètre est obligatoire.

```yaml
Type: String
Required: True
```plaintext
### -Indent

Indique si le JSON généré doit être formaté avec des indentations et des sauts de ligne pour une meilleure lisibilité.

```yaml
Type: SwitchParameter
Default: False
```plaintext
### -ExcludeMetadata

Indique si les métadonnées doivent être exclues du fichier JSON.

```yaml
Type: SwitchParameter
Default: False
```plaintext
### -ExcludeIndexes

Indique si les index de la collection doivent être exclus du fichier JSON. Ce paramètre n'est applicable que lors de la sauvegarde d'une collection.

```yaml
Type: SwitchParameter
Default: False
```plaintext
### -CreateDirectories

Indique si les répertoires parents du fichier doivent être créés automatiquement s'ils n'existent pas.

```yaml
Type: SwitchParameter
Default: False
```plaintext
### -Force

Indique si le fichier doit être écrasé s'il existe déjà.

```yaml
Type: SwitchParameter
Default: False
```plaintext
### <CommonParameters>

Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES

### System.Collections.Hashtable

Vous pouvez transmettre un objet d'information extraite ou une collection via le pipeline.

## SORTIES

### System.Boolean

Retourne $true si la sauvegarde a réussi, ou $false en cas d'échec.

## NOTES

- Cette fonction ne modifie pas l'objet d'information extraite ou la collection originale.
- Si le fichier spécifié existe déjà et que le paramètre `-Force` n'est pas spécifié, la fonction génère une erreur.
- Si le répertoire parent du fichier n'existe pas et que le paramètre `-CreateDirectories` n'est pas spécifié, la fonction génère une erreur.
- L'option `-ExcludeMetadata` peut être utile pour réduire la taille du fichier si les métadonnées ne sont pas nécessaires.
- Pour les collections, l'option `-ExcludeIndexes` peut réduire considérablement la taille du fichier, mais les index devront être recréés lors du chargement.
- Le fichier est encodé en UTF-8 sans BOM pour assurer une compatibilité maximale.

## EXEMPLES

### Exemple 1 : Sauvegarder un objet d'information extraite dans un fichier

```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor" -ProcessingState "Processed" -ConfidenceScore 85
$filePath = Join-Path $env:TEMP "info.json"

$result = Save-ExtractedInfoToFile -Info $info -FilePath $filePath -Force
if ($result) {
    Write-Host "L'objet a été sauvegardé avec succès dans $filePath"
}
```plaintext
Cet exemple sauvegarde un objet d'information extraite simple dans un fichier JSON, en écrasant le fichier s'il existe déjà.

### Exemple 2 : Sauvegarder un objet d'information extraite avec indentation

```powershell
$info = New-TextExtractedInfo -Source "article.html" -Text "Ceci est un exemple de texte extrait d'un article." -Language "fr"
$info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
    URL = "https://example.com/article"
    Author = "John Doe"
    PublicationDate = Get-Date -Year 2023 -Month 5 -Day 15
}

$filePath = Join-Path $env:TEMP "text_info.json"
$result = Save-ExtractedInfoToFile -Info $info -FilePath $filePath -Indent -Force
if ($result) {
    Write-Host "L'objet a été sauvegardé avec succès dans $filePath"
    Write-Host "Taille du fichier : $((Get-Item $filePath).Length) octets"
}
```plaintext
Cet exemple sauvegarde un objet d'information extraite de type texte avec métadonnées dans un fichier JSON indenté pour une meilleure lisibilité.

### Exemple 3 : Sauvegarder une collection dans un fichier

```powershell
# Créer une collection

$collection = New-ExtractedInfoCollection -Name "FileDemo" -Description "Collection pour démonstration de sauvegarde" -CreateIndexes

# Ajouter quelques objets

$info1 = New-TextExtractedInfo -Source "doc1.txt" -Text "Texte 1"
$info2 = New-TextExtractedInfo -Source "doc2.txt" -Text "Texte 2"
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)

# Sauvegarder la collection

$filePath = Join-Path $env:TEMP "collection.json"
$result = Save-ExtractedInfoToFile -Collection $collection -FilePath $filePath -Indent -Force
if ($result) {
    Write-Host "La collection a été sauvegardée avec succès dans $filePath"
    Write-Host "Taille du fichier : $((Get-Item $filePath).Length) octets"
}
```plaintext
Cet exemple sauvegarde une collection d'informations extraites dans un fichier JSON indenté.

### Exemple 4 : Sauvegarder une collection sans index

```powershell
# Créer une collection indexée

$collection = New-ExtractedInfoCollection -Name "LargeCollection" -CreateIndexes

# Ajouter de nombreux objets

$infoList = @()
for ($i = 1; $i -le 20; $i++) {
    $info = New-ExtractedInfo -Source "source$i" -ConfidenceScore ($i * 5)
    $infoList += $info
}
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $infoList

# Sauvegarder avec et sans index

$filePathWithIndexes = Join-Path $env:TEMP "collection_with_indexes.json"
$filePathWithoutIndexes = Join-Path $env:TEMP "collection_without_indexes.json"

Save-ExtractedInfoToFile -Collection $collection -FilePath $filePathWithIndexes -Indent -Force | Out-Null
Save-ExtractedInfoToFile -Collection $collection -FilePath $filePathWithoutIndexes -Indent -ExcludeIndexes -Force | Out-Null

# Comparer les tailles

$withSize = (Get-Item $filePathWithIndexes).Length
$withoutSize = (Get-Item $filePathWithoutIndexes).Length
$reduction = [Math]::Round(100 - ($withoutSize / $withSize * 100), 2)

Write-Host "Taille avec index : $withSize octets"
Write-Host "Taille sans index : $withoutSize octets"
Write-Host "Réduction : $reduction%"
```plaintext
Cet exemple compare la taille des fichiers générés pour une collection avec et sans index, montrant la réduction de taille obtenue en excluant les index.

### Exemple 5 : Sauvegarder un objet dans un nouveau répertoire

```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$dirPath = Join-Path $env:TEMP "ExtractedInfo\SubDir"
$filePath = Join-Path $dirPath "info.json"

# Tentative de sauvegarde sans création de répertoire

try {
    $result = Save-ExtractedInfoToFile -Info $info -FilePath $filePath -ErrorAction Stop
    Write-Host "L'objet a été sauvegardé avec succès dans $filePath"
}
catch {
    Write-Host "Erreur : $($_.Exception.Message)"
    
    # Nouvelle tentative avec création de répertoire

    $result = Save-ExtractedInfoToFile -Info $info -FilePath $filePath -CreateDirectories
    if ($result) {
        Write-Host "L'objet a été sauvegardé avec succès dans $filePath après création des répertoires"
    }
}
```plaintext
Cet exemple montre comment utiliser le paramètre `-CreateDirectories` pour sauvegarder un objet dans un répertoire qui n'existe pas encore.

### Exemple 6 : Sauvegarder un objet sans métadonnées

```powershell
$info = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
    Person = @{
        FirstName = "John"
        LastName = "Doe"
        Age = 30
    }
}
$info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
    DataSource = "API"
    ImportDate = Get-Date
    Confidential = $true
}

# Sauvegarder avec et sans métadonnées

$filePathWithMetadata = Join-Path $env:TEMP "info_with_metadata.json"
$filePathWithoutMetadata = Join-Path $env:TEMP "info_without_metadata.json"

Save-ExtractedInfoToFile -Info $info -FilePath $filePathWithMetadata -Indent -Force | Out-Null
Save-ExtractedInfoToFile -Info $info -FilePath $filePathWithoutMetadata -Indent -ExcludeMetadata -Force | Out-Null

# Comparer les tailles

$withSize = (Get-Item $filePathWithMetadata).Length
$withoutSize = (Get-Item $filePathWithoutMetadata).Length
$reduction = [Math]::Round(100 - ($withoutSize / $withSize * 100), 2)

Write-Host "Taille avec métadonnées : $withSize octets"
Write-Host "Taille sans métadonnées : $withoutSize octets"
Write-Host "Réduction : $reduction%"
```plaintext
Cet exemple compare la taille des fichiers générés pour un objet avec et sans métadonnées, montrant la réduction de taille obtenue en excluant les métadonnées.

### Exemple 7 : Utiliser Save-ExtractedInfoToFile avec le pipeline

```powershell
# Créer plusieurs objets

$infos = @(
    (New-ExtractedInfo -Source "source1"),
    (New-TextExtractedInfo -Source "source2" -Text "Texte"),
    (New-StructuredDataExtractedInfo -Source "source3" -Data @{ Key = "Value" })
)

# Sauvegarder tous les objets via le pipeline

$baseDir = Join-Path $env:TEMP "PipelineDemo"
if (-not (Test-Path $baseDir)) {
    New-Item -Path $baseDir -ItemType Directory | Out-Null
}

$infos | ForEach-Object {
    $fileName = "$($_.Source)_$($_.Id).json"
    $filePath = Join-Path $baseDir $fileName
    $_ | Save-ExtractedInfoToFile -FilePath $filePath -Indent -Force
    Write-Host "Sauvegardé $($_.Source) dans $filePath"
}

# Vérifier les fichiers créés

Get-ChildItem -Path $baseDir -Filter "*.json" | ForEach-Object {
    Write-Host "Fichier : $($_.Name), Taille : $($_.Length) octets"
}
```plaintext
Cet exemple utilise le pipeline pour sauvegarder plusieurs objets d'information extraite dans des fichiers séparés.

## LIENS CONNEXES

- [Load-ExtractedInfoFromFile](Load-ExtractedInfoFromFile.md)
- [ConvertTo-ExtractedInfoJson](ConvertTo-ExtractedInfoJson.md)
- [ConvertFrom-ExtractedInfoJson](ConvertFrom-ExtractedInfoJson.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
- [New-ExtractedInfoCollection](New-ExtractedInfoCollection.md)
