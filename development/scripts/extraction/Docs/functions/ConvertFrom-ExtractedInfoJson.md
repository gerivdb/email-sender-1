# ConvertFrom-ExtractedInfoJson

## SYNOPSIS

Convertit une chaîne JSON en objet d'information extraite ou en collection.

## SYNTAXE

```powershell
ConvertFrom-ExtractedInfoJson
    -Json <String>
    [-AsHashtable]
    [-ValidateOnly]
    [<CommonParameters>]
```plaintext
## DESCRIPTION

La fonction `ConvertFrom-ExtractedInfoJson` convertit une chaîne JSON en objet d'information extraite ou en collection, selon le contenu du JSON. Cette fonction est le complément de `ConvertTo-ExtractedInfoJson` et permet de reconstituer des objets précédemment sérialisés.

La fonction détecte automatiquement le type d'objet (information extraite individuelle ou collection) en fonction de la propriété `_Type` dans le JSON et effectue la conversion appropriée.

## PARAMÈTRES

### -Json

Spécifie la chaîne JSON à convertir en objet d'information extraite ou en collection. Ce paramètre est obligatoire.

```yaml
Type: String
Required: True
```plaintext
### -AsHashtable

Indique si le résultat doit être retourné sous forme de hashtable plutôt que d'objet PSCustomObject.

```yaml
Type: SwitchParameter
Default: False
```plaintext
### -ValidateOnly

Indique si la fonction doit uniquement valider le JSON sans effectuer la conversion complète. Si ce paramètre est spécifié, la fonction retourne $true si le JSON est valide et peut être converti, ou $false dans le cas contraire.

```yaml
Type: SwitchParameter
Default: False
```plaintext
### <CommonParameters>

Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES

### System.String

Vous pouvez transmettre une chaîne JSON via le pipeline.

## SORTIES

### System.Collections.Hashtable, System.Management.Automation.PSCustomObject, ou System.Boolean

- Si le paramètre `-ValidateOnly` est spécifié, la fonction retourne un booléen indiquant si le JSON est valide.
- Si le paramètre `-AsHashtable` est spécifié, la fonction retourne une hashtable représentant l'objet d'information extraite ou la collection.
- Sinon, la fonction retourne un objet PSCustomObject représentant l'objet d'information extraite ou la collection.

## NOTES

- Cette fonction effectue une validation du JSON pour s'assurer qu'il représente un objet d'information extraite ou une collection valide.
- Les chaînes de date au format ISO 8601 sont automatiquement converties en objets DateTime.
- Pour les objets de type StructuredDataExtractedInfo, les données JSON sont converties en objets PowerShell.
- Si le JSON représente une collection avec des index, les index sont recréés automatiquement.
- Pour les grandes collections, la conversion peut prendre un certain temps, en particulier si la collection contient des index complexes.
- Si le JSON n'est pas valide ou ne représente pas un objet d'information extraite ou une collection, la fonction génère une erreur, sauf si le paramètre `-ValidateOnly` est spécifié.

## EXEMPLES

### Exemple 1 : Convertir un JSON en objet d'information extraite

```powershell
# Créer un objet d'information extraite et le convertir en JSON

$originalInfo = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$json = ConvertTo-ExtractedInfoJson -Info $originalInfo

# Convertir le JSON en objet d'information extraite

$convertedInfo = ConvertFrom-ExtractedInfoJson -Json $json

# Vérifier que l'objet a été correctement reconstitué

if ($convertedInfo.Id -eq $originalInfo.Id -and $convertedInfo.Source -eq $originalInfo.Source) {
    Write-Host "L'objet a été correctement reconstitué."
}
```plaintext
Cet exemple convertit un objet d'information extraite en JSON, puis reconstitue l'objet à partir du JSON.

### Exemple 2 : Convertir un JSON en collection

```powershell
# Créer une collection avec quelques objets

$originalCollection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
$info1 = New-TextExtractedInfo -Source "doc1.txt" -Text "Texte 1"
$info2 = New-TextExtractedInfo -Source "doc2.txt" -Text "Texte 2"
$originalCollection = Add-ExtractedInfoToCollection -Collection $originalCollection -InfoList @($info1, $info2)

# Convertir la collection en JSON

$json = ConvertTo-ExtractedInfoJson -Collection $originalCollection

# Convertir le JSON en collection

$convertedCollection = ConvertFrom-ExtractedInfoJson -Json $json

# Vérifier que la collection a été correctement reconstituée

Write-Host "Collection originale : $($originalCollection.Name) avec $($originalCollection.Items.Count) éléments"
Write-Host "Collection convertie : $($convertedCollection.Name) avec $($convertedCollection.Items.Count) éléments"
Write-Host "Index présents : $(if ($convertedCollection.Indexes) { 'Oui' } else { 'Non' })"
```plaintext
Cet exemple convertit une collection en JSON, puis reconstitue la collection à partir du JSON.

### Exemple 3 : Convertir un JSON en hashtable

```powershell
# Créer un objet d'information extraite et le convertir en JSON

$originalInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Test"; Value = 123 }
$json = ConvertTo-ExtractedInfoJson -Info $originalInfo

# Convertir le JSON en hashtable

$convertedInfo = ConvertFrom-ExtractedInfoJson -Json $json -AsHashtable

# Vérifier le type de l'objet converti

$convertedInfo.GetType().Name | Should -Be "Hashtable"
Write-Host "Type de l'objet converti : $($convertedInfo.GetType().Name)"
Write-Host "Propriétés : $($convertedInfo.Keys -join ', ')"
```plaintext
Cet exemple convertit un objet d'information extraite en JSON, puis reconstitue l'objet sous forme de hashtable à partir du JSON.

### Exemple 4 : Valider un JSON sans le convertir

```powershell
# Créer un JSON valide

$validInfo = New-ExtractedInfo -Source "valid.txt"
$validJson = ConvertTo-ExtractedInfoJson -Info $validInfo

# Créer un JSON invalide

$invalidJson = '{"NotAnExtractedInfo": true}'

# Valider les JSON

$isValidJson = ConvertFrom-ExtractedInfoJson -Json $validJson -ValidateOnly
$isInvalidJson = ConvertFrom-ExtractedInfoJson -Json $invalidJson -ValidateOnly -ErrorAction SilentlyContinue

Write-Host "JSON valide : $isValidJson"
Write-Host "JSON invalide : $isInvalidJson"
```plaintext
Cet exemple utilise le paramètre `-ValidateOnly` pour vérifier si des chaînes JSON représentent des objets d'information extraite valides sans effectuer la conversion complète.

### Exemple 5 : Gérer les erreurs de conversion

```powershell
# Créer différents JSON invalides

$jsonMissingType = '{"Source": "missing.txt", "Id": "12345"}'
$jsonInvalidType = '{"_Type": "InvalidType", "Source": "invalid.txt", "Id": "12345"}'
$jsonMalformed = 'This is not valid JSON'

# Fonction pour tester la conversion avec gestion d'erreur

function Test-JsonConversion {
    param (
        [string]$Json,
        [string]$Description
    )
    
    try {
        $result = ConvertFrom-ExtractedInfoJson -Json $Json -ErrorAction Stop
        Write-Host "Conversion réussie pour '$Description'"
        return $true
    }
    catch {
        Write-Host "Erreur de conversion pour '$Description': $($_.Exception.Message)"
        return $false
    }
}

# Tester les différents JSON

Test-JsonConversion -Json $jsonMissingType -Description "JSON sans propriété _Type"
Test-JsonConversion -Json $jsonInvalidType -Description "JSON avec type invalide"
Test-JsonConversion -Json $jsonMalformed -Description "JSON mal formé"
```plaintext
Cet exemple montre comment gérer les erreurs lors de la conversion de JSON invalides.

### Exemple 6 : Convertir un JSON avec des dates

```powershell
# Créer un objet avec des dates

$originalInfo = New-ExtractedInfo -Source "dates.txt"
$originalExtractionDate = $originalInfo.ExtractionDate
$originalLastModifiedDate = $originalInfo.LastModifiedDate

# Convertir en JSON puis reconvertir en objet

$json = ConvertTo-ExtractedInfoJson -Info $originalInfo
$convertedInfo = ConvertFrom-ExtractedInfoJson -Json $json

# Vérifier les types et valeurs des dates

Write-Host "Date d'extraction originale : $originalExtractionDate (Type: $($originalExtractionDate.GetType().Name))"
Write-Host "Date d'extraction convertie : $($convertedInfo.ExtractionDate) (Type: $($convertedInfo.ExtractionDate.GetType().Name))"

if ($convertedInfo.ExtractionDate -eq $originalExtractionDate -and 
    $convertedInfo.LastModifiedDate -eq $originalLastModifiedDate) {
    Write-Host "Les dates ont été correctement converties."
}
```plaintext
Cet exemple montre comment les dates sont correctement converties lors de la sérialisation et désérialisation.

### Exemple 7 : Convertir un JSON avec des caractères spéciaux

```powershell
# Créer un objet avec des caractères spéciaux

$specialCharsText = "Texte avec caractères spéciaux: àéèêëìíîïòóôõöùúûüýÿ et symboles: !@#$%^&*()_+-=[]{}|;':\",./<>?"

$originalInfo = New-TextExtractedInfo -Source "special.txt" -Text $specialCharsText

# Convertir en JSON puis reconvertir en objet

$json = ConvertTo-ExtractedInfoJson -Info $originalInfo
$convertedInfo = ConvertFrom-ExtractedInfoJson -Json $json

# Vérifier que le texte a été correctement préservé

if ($convertedInfo.Text -eq $specialCharsText) {
    Write-Host "Les caractères spéciaux ont été correctement préservés."
}
else {
    Write-Host "Erreur: les caractères spéciaux n'ont pas été correctement préservés."
    Write-Host "Original: $specialCharsText"
    Write-Host "Converti: $($convertedInfo.Text)"
}
```plaintext
Cet exemple montre comment les caractères spéciaux sont correctement préservés lors de la sérialisation et désérialisation.

## LIENS CONNEXES

- [ConvertTo-ExtractedInfoJson](ConvertTo-ExtractedInfoJson.md)
- [Save-ExtractedInfoToFile](Save-ExtractedInfoToFile.md)
- [Load-ExtractedInfoFromFile](Load-ExtractedInfoFromFile.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
- [New-ExtractedInfoCollection](New-ExtractedInfoCollection.md)
