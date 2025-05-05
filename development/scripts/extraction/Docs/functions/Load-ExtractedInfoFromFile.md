# Load-ExtractedInfoFromFile

## SYNOPSIS
Charge un objet d'information extraite ou une collection depuis un fichier JSON.

## SYNTAXE

```powershell
Load-ExtractedInfoFromFile
    -FilePath <String>
    [-AsHashtable]
    [-ValidateOnly]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `Load-ExtractedInfoFromFile` charge un objet d'information extraite ou une collection depuis un fichier JSON. Cette fonction est le complément de `Save-ExtractedInfoToFile` et permet de reconstituer des objets précédemment sauvegardés.

La fonction détecte automatiquement le type d'objet (information extraite individuelle ou collection) en fonction de la propriété `_Type` dans le fichier JSON et effectue le chargement approprié.

## PARAMÈTRES

### -FilePath
Spécifie le chemin du fichier JSON à charger. Ce paramètre est obligatoire.

```yaml
Type: String
Required: True
```

### -AsHashtable
Indique si le résultat doit être retourné sous forme de hashtable plutôt que d'objet PSCustomObject.

```yaml
Type: SwitchParameter
Default: False
```

### -ValidateOnly
Indique si la fonction doit uniquement valider le fichier JSON sans effectuer le chargement complet. Si ce paramètre est spécifié, la fonction retourne $true si le fichier contient un JSON valide qui peut être chargé, ou $false dans le cas contraire.

```yaml
Type: SwitchParameter
Default: False
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
### System.String
Vous pouvez transmettre un chemin de fichier via le pipeline.

## SORTIES
### System.Collections.Hashtable, System.Management.Automation.PSCustomObject, ou System.Boolean
- Si le paramètre `-ValidateOnly` est spécifié, la fonction retourne un booléen indiquant si le fichier contient un JSON valide qui peut être chargé.
- Si le paramètre `-AsHashtable` est spécifié, la fonction retourne une hashtable représentant l'objet d'information extraite ou la collection.
- Sinon, la fonction retourne un objet PSCustomObject représentant l'objet d'information extraite ou la collection.

## NOTES
- Cette fonction effectue une validation du contenu du fichier pour s'assurer qu'il représente un objet d'information extraite ou une collection valide.
- Les chaînes de date au format ISO 8601 sont automatiquement converties en objets DateTime.
- Pour les objets de type StructuredDataExtractedInfo, les données JSON sont converties en objets PowerShell.
- Si le fichier contient une collection avec des index, les index sont recréés automatiquement.
- Pour les grandes collections, le chargement peut prendre un certain temps, en particulier si la collection contient des index complexes.
- Si le fichier n'existe pas, n'est pas accessible, ou ne contient pas un JSON valide représentant un objet d'information extraite ou une collection, la fonction génère une erreur, sauf si le paramètre `-ValidateOnly` est spécifié.
- Le fichier est supposé être encodé en UTF-8 (avec ou sans BOM).

## EXEMPLES

### Exemple 1 : Charger un objet d'information extraite depuis un fichier
```powershell
# Créer et sauvegarder un objet d'information extraite
$originalInfo = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$filePath = Join-Path $env:TEMP "info.json"
Save-ExtractedInfoToFile -Info $originalInfo -FilePath $filePath -Force | Out-Null

# Charger l'objet depuis le fichier
$loadedInfo = Load-ExtractedInfoFromFile -FilePath $filePath

# Vérifier que l'objet a été correctement chargé
if ($loadedInfo.Id -eq $originalInfo.Id -and $loadedInfo.Source -eq $originalInfo.Source) {
    Write-Host "L'objet a été correctement chargé."
}
```

Cet exemple sauvegarde un objet d'information extraite dans un fichier, puis le charge à nouveau.

### Exemple 2 : Charger une collection depuis un fichier
```powershell
# Créer et sauvegarder une collection
$originalCollection = New-ExtractedInfoCollection -Name "TestCollection" -CreateIndexes
$info1 = New-TextExtractedInfo -Source "doc1.txt" -Text "Texte 1"
$info2 = New-TextExtractedInfo -Source "doc2.txt" -Text "Texte 2"
$originalCollection = Add-ExtractedInfoToCollection -Collection $originalCollection -InfoList @($info1, $info2)

$filePath = Join-Path $env:TEMP "collection.json"
Save-ExtractedInfoToFile -Collection $originalCollection -FilePath $filePath -Force | Out-Null

# Charger la collection depuis le fichier
$loadedCollection = Load-ExtractedInfoFromFile -FilePath $filePath

# Vérifier que la collection a été correctement chargée
Write-Host "Collection originale : $($originalCollection.Name) avec $($originalCollection.Items.Count) éléments"
Write-Host "Collection chargée : $($loadedCollection.Name) avec $($loadedCollection.Items.Count) éléments"
Write-Host "Index présents : $(if ($loadedCollection.Indexes) { 'Oui' } else { 'Non' })"
```

Cet exemple sauvegarde une collection dans un fichier, puis la charge à nouveau.

### Exemple 3 : Charger un objet en tant que hashtable
```powershell
# Créer et sauvegarder un objet d'information extraite
$originalInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Test"; Value = 123 }
$filePath = Join-Path $env:TEMP "structured_info.json"
Save-ExtractedInfoToFile -Info $originalInfo -FilePath $filePath -Force | Out-Null

# Charger l'objet en tant que hashtable
$loadedInfo = Load-ExtractedInfoFromFile -FilePath $filePath -AsHashtable

# Vérifier le type de l'objet chargé
$loadedInfo.GetType().Name | Should -Be "Hashtable"
Write-Host "Type de l'objet chargé : $($loadedInfo.GetType().Name)"
Write-Host "Propriétés : $($loadedInfo.Keys -join ', ')"
```

Cet exemple charge un objet d'information extraite sous forme de hashtable.

### Exemple 4 : Valider un fichier sans le charger
```powershell
# Créer et sauvegarder un objet d'information extraite valide
$validInfo = New-ExtractedInfo -Source "valid.txt"
$validFilePath = Join-Path $env:TEMP "valid_info.json"
Save-ExtractedInfoToFile -Info $validInfo -FilePath $validFilePath -Force | Out-Null

# Créer un fichier JSON invalide
$invalidFilePath = Join-Path $env:TEMP "invalid_info.json"
'{"NotAnExtractedInfo": true}' | Out-File -FilePath $invalidFilePath -Encoding utf8

# Valider les fichiers
$isValidFile = Load-ExtractedInfoFromFile -FilePath $validFilePath -ValidateOnly
$isInvalidFile = Load-ExtractedInfoFromFile -FilePath $invalidFilePath -ValidateOnly -ErrorAction SilentlyContinue

Write-Host "Fichier valide : $isValidFile"
Write-Host "Fichier invalide : $isInvalidFile"
```

Cet exemple utilise le paramètre `-ValidateOnly` pour vérifier si des fichiers contiennent des objets d'information extraite valides sans effectuer le chargement complet.

### Exemple 5 : Gérer les erreurs de chargement
```powershell
# Créer différents fichiers invalides
$nonExistentFilePath = Join-Path $env:TEMP "non_existent.json"
$malformedFilePath = Join-Path $env:TEMP "malformed.json"
"This is not valid JSON" | Out-File -FilePath $malformedFilePath -Encoding utf8

# Fonction pour tester le chargement avec gestion d'erreur
function Test-FileLoading {
    param (
        [string]$FilePath,
        [string]$Description
    )
    
    try {
        $result = Load-ExtractedInfoFromFile -FilePath $FilePath -ErrorAction Stop
        Write-Host "Chargement réussi pour '$Description'"
        return $true
    }
    catch {
        Write-Host "Erreur de chargement pour '$Description': $($_.Exception.Message)"
        return $false
    }
}

# Tester les différents fichiers
Test-FileLoading -FilePath $nonExistentFilePath -Description "Fichier inexistant"
Test-FileLoading -FilePath $malformedFilePath -Description "Fichier mal formé"
```

Cet exemple montre comment gérer les erreurs lors du chargement de fichiers invalides ou inexistants.

### Exemple 6 : Charger et manipuler une collection
```powershell
# Créer et sauvegarder une collection avec différents types d'objets
$collection = New-ExtractedInfoCollection -Name "MixedCollection" -CreateIndexes
$textInfo = New-TextExtractedInfo -Source "document.txt" -Text "Exemple de texte"
$structuredInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Test"; Value = 123 }
$mediaInfo = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\Images\image.jpg" -MediaType "Image"

$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($textInfo, $structuredInfo, $mediaInfo)

$filePath = Join-Path $env:TEMP "mixed_collection.json"
Save-ExtractedInfoToFile -Collection $collection -FilePath $filePath -Force | Out-Null

# Charger la collection
$loadedCollection = Load-ExtractedInfoFromFile -FilePath $filePath

# Analyser le contenu de la collection chargée
Write-Host "Collection chargée : $($loadedCollection.Name)"
Write-Host "Nombre d'éléments : $($loadedCollection.Items.Count)"

# Grouper les éléments par type
$groupedItems = $loadedCollection.Items | Group-Object -Property _Type

foreach ($group in $groupedItems) {
    Write-Host "Type: $($group.Name), Nombre: $($group.Count)"
    foreach ($item in $group.Group) {
        Write-Host "  - ID: $($item.Id), Source: $($item.Source)"
    }
}
```

Cet exemple charge une collection contenant différents types d'objets et analyse son contenu.

### Exemple 7 : Charger une collection et effectuer des opérations sur ses éléments
```powershell
# Créer et sauvegarder une collection
$collection = New-ExtractedInfoCollection -Name "ProcessingCollection" -CreateIndexes
$infoList = @()
for ($i = 1; $i -le 10; $i++) {
    $info = New-ExtractedInfo -Source "source$i" -ProcessingState "Raw" -ConfidenceScore ($i * 10)
    $infoList += $info
}
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList $infoList

$filePath = Join-Path $env:TEMP "processing_collection.json"
Save-ExtractedInfoToFile -Collection $collection -FilePath $filePath -Force | Out-Null

# Charger la collection
$loadedCollection = Load-ExtractedInfoFromFile -FilePath $filePath

# Traiter les éléments de la collection
$processedCollection = $loadedCollection
foreach ($item in $loadedCollection.Items) {
    if ($item.ProcessingState -eq "Raw" -and $item.ConfidenceScore -ge 50) {
        # Créer une version mise à jour de l'élément
        $updatedItem = Copy-ExtractedInfo -Info $item -ProcessingState "Processed"
        # Mettre à jour la collection
        $processedCollection = Add-ExtractedInfoToCollection -Collection $processedCollection -Info $updatedItem
    }
}

# Vérifier les résultats
$rawCount = ($processedCollection.Items | Where-Object { $_.ProcessingState -eq "Raw" }).Count
$processedCount = ($processedCollection.Items | Where-Object { $_.ProcessingState -eq "Processed" }).Count

Write-Host "Éléments bruts : $rawCount"
Write-Host "Éléments traités : $processedCount"

# Sauvegarder la collection mise à jour
$updatedFilePath = Join-Path $env:TEMP "processed_collection.json"
Save-ExtractedInfoToFile -Collection $processedCollection -FilePath $updatedFilePath -Force | Out-Null
Write-Host "Collection mise à jour sauvegardée dans $updatedFilePath"
```

Cet exemple charge une collection, effectue des opérations sur ses éléments, puis sauvegarde la collection mise à jour.

## LIENS CONNEXES
- [Save-ExtractedInfoToFile](Save-ExtractedInfoToFile.md)
- [ConvertTo-ExtractedInfoJson](ConvertTo-ExtractedInfoJson.md)
- [ConvertFrom-ExtractedInfoJson](ConvertFrom-ExtractedInfoJson.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
- [New-ExtractedInfoCollection](New-ExtractedInfoCollection.md)
