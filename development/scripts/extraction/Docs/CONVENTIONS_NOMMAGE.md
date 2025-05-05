# Conventions de nommage pour le module ExtractedInfoModuleV2

Ce document présente les conventions de nommage à suivre pour le développement et l'extension du module ExtractedInfoModuleV2.

## Conventions pour les noms de fonctions

Les noms de fonctions doivent suivre les conventions PowerShell standard et être clairs sur leur objectif.

### Verbes approuvés

Toutes les fonctions doivent commencer par un verbe approuvé par PowerShell. Voici les principaux verbes utilisés dans ce module :

| Verbe | Utilisation | Exemple |
|-------|-------------|---------|
| `New` | Créer un nouvel objet | `New-ExtractedInfo`, `New-TextExtractedInfo` |
| `Get` | Récupérer des informations | `Get-ExtractedInfoMetadata`, `Get-ValidationErrors` |
| `Add` | Ajouter quelque chose à un objet existant | `Add-ExtractedInfoMetadata`, `Add-ValidationRule` |
| `Remove` | Supprimer quelque chose d'un objet | `Remove-ExtractedInfoMetadata` |
| `Set` | Définir une propriété ou un état | `Set-ExtractedInfoProperty` |
| `Convert` | Convertir d'un format à un autre | `ConvertTo-ExtractedInfoJson`, `ConvertFrom-ExtractedInfoJson` |
| `Export` | Exporter vers un format externe | `Export-GeoLocationExtractedInfo` |
| `Import` | Importer depuis un format externe | `Import-ExtractedInfoFromFile` |
| `Test` | Valider ou vérifier | `Test-ExtractedInfo` |
| `Save` | Enregistrer dans un fichier | `Save-ExtractedInfoToFile` |
| `Copy` | Créer une copie d'un objet | `Copy-ExtractedInfo` |

### Structure des noms de fonctions

Les noms de fonctions suivent généralement cette structure :

```
Verbe-[Type]Nom[Action]
```

- **Verbe** : Un verbe approuvé par PowerShell
- **Type** (optionnel) : Le type d'objet sur lequel la fonction opère
- **Nom** : Le nom de l'objet principal
- **Action** (optionnel) : L'action spécifique effectuée

### Exemples de noms de fonctions

| Fonction | Description |
|----------|-------------|
| `New-ExtractedInfo` | Crée un nouvel objet d'information extraite générique |
| `New-TextExtractedInfo` | Crée un nouvel objet d'information extraite de type texte |
| `Add-ExtractedInfoMetadata` | Ajoute des métadonnées à un objet d'information extraite |
| `Get-ExtractedInfoFromCollection` | Récupère des objets d'information extraite d'une collection |
| `Export-GeoLocationExtractedInfo` | Exporte un objet d'information géographique dans un format spécifique |
| `ConvertTo-ExtractedInfoJson` | Convertit un objet d'information extraite en format JSON |

### Règles spécifiques

1. **Cohérence** : Utiliser les mêmes termes pour les mêmes concepts dans tout le module
2. **Singulier** : Utiliser le singulier pour les noms d'objets (ExtractedInfo, not ExtractedInfos)
3. **PascalCase** : Utiliser le PascalCase pour les noms de fonctions
4. **Préfixes** : Éviter les préfixes redondants comme "Get-GetData"
5. **Clarté** : Le nom doit clairement indiquer ce que fait la fonction
6. **Éviter les abréviations** : Sauf si elles sont très courantes et claires

## Conventions pour les noms de paramètres

Les noms de paramètres doivent être clairs, cohérents et suivre les conventions PowerShell.

### Règles générales

1. **PascalCase** : Utiliser le PascalCase pour les noms de paramètres
2. **Singulier** : Utiliser le singulier pour les noms de paramètres, sauf s'ils représentent une collection
3. **Descriptif** : Le nom doit décrire clairement ce que le paramètre représente
4. **Cohérence** : Utiliser les mêmes noms de paramètres pour les mêmes concepts dans tout le module
5. **Éviter les abréviations** : Sauf si elles sont très courantes et claires

### Paramètres communs

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `Info` | Un objet d'information extraite | `Get-ExtractedInfoMetadata -Info $info` |
| `Collection` | Une collection d'objets d'information extraite | `Add-ExtractedInfoToCollection -Collection $collection -Info $info` |
| `Path` | Chemin d'un fichier | `Save-ExtractedInfoToFile -Info $info -Path "C:\data\info.json"` |
| `Format` | Format de sortie ou d'entrée | `Export-GeoLocationExtractedInfo -Info $info -Format "HTML"` |
| `Metadata` | Métadonnées à ajouter ou à manipuler | `Add-ExtractedInfoMetadata -Info $info -Metadata @{Author = "John"}` |
| `Filter` | Filtre à appliquer | `Get-ExtractedInfoFromCollection -Collection $collection -Filter { $_.Source -eq "document.txt" }` |
| `IncludeMetadata` | Indique si les métadonnées doivent être incluses | `ConvertTo-ExtractedInfoJson -Info $info -IncludeMetadata` |
| `Force` | Force une opération potentiellement dangereuse | `Remove-ExtractedInfoMetadata -Info $info -Key "Author" -Force` |
| `PassThru` | Indique si l'objet modifié doit être retourné | `Add-ExtractedInfoMetadata -Info $info -Metadata $metadata -PassThru` |

### Paramètres spécifiques aux types

#### TextExtractedInfo

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `Text` | Le contenu textuel | `New-TextExtractedInfo -Source "document.txt" -Text "Contenu"` |
| `Language` | La langue du texte | `New-TextExtractedInfo -Source "document.txt" -Text "Contenu" -Language "fr"` |

#### StructuredDataExtractedInfo

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `Data` | Les données structurées | `New-StructuredDataExtractedInfo -Source "data.json" -Data $data` |
| `DataFormat` | Le format des données | `New-StructuredDataExtractedInfo -Source "data.json" -Data $data -DataFormat "Hashtable"` |

#### GeoLocationExtractedInfo

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `Latitude` | La latitude | `New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522` |
| `Longitude` | La longitude | `New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522` |
| `City` | La ville | `New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris"` |
| `Country` | Le pays | `New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -Country "France"` |

#### MediaExtractedInfo

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `MediaPath` | Le chemin du fichier média | `New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\images\image.jpg"` |
| `MediaType` | Le type de média | `New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\images\image.jpg" -MediaType "Image"` |

### Paramètres d'exportation

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `ExportOptions` | Options d'exportation | `Export-GenericExtractedInfo -Info $info -Format "HTML" -ExportOptions @{ Theme = "Dark" }` |
| `OutputPath` | Chemin de sortie | `Export-GeoLocationExtractedInfo -Info $info -Format "HTML" -OutputPath "C:\output\map.html"` |
| `Encoding` | Encodage à utiliser | `Export-GenericExtractedInfo -Info $info -Format "TXT" -Encoding "UTF8"` |

## Conventions pour les noms de variables internes

Les variables internes sont utilisées dans le corps des fonctions et ne sont pas exposées à l'utilisateur. Elles doivent suivre des conventions cohérentes pour faciliter la maintenance du code.

### Règles générales

1. **camelCase** : Utiliser le camelCase pour les noms de variables internes
2. **Descriptif** : Le nom doit décrire clairement ce que la variable représente
3. **Portée limitée** : Limiter la portée des variables au minimum nécessaire
4. **Éviter les noms génériques** : Éviter les noms comme `temp`, `x`, `data` sans contexte
5. **Préfixes pour les types spéciaux** : Utiliser des préfixes pour certains types de variables

### Variables temporaires et de boucle

| Type | Convention | Exemple |
|------|------------|---------|
| Compteurs de boucle | `i`, `j`, `k` pour les boucles simples | `for ($i = 0; $i -lt $array.Length; $i++) { ... }` |
| Éléments d'itération | Nom singulier descriptif | `foreach ($item in $items) { ... }` |
| Variables temporaires | Préfixe `temp` ou nom descriptif | `$tempResult = Calculate-Something` |

### Variables par type de données

| Type | Convention | Exemple |
|------|------------|---------|
| Booléens | Préfixe `is`, `has`, `should` | `$isValid = Test-Condition` |
| Collections | Nom pluriel | `$extractedInfos = @()` |
| Hashtables | Suffixe `Map` ou `Table` | `$metadataMap = @{}` |
| Fonctions | Suffixe `Func` ou `Function` | `$validationFunc = { param($x) $x -gt 0 }` |

### Variables pour les objets du module

| Type | Convention | Exemple |
|------|------------|---------|
| Objets d'information extraite | `$info`, `$extractedInfo` | `$info = New-ExtractedInfo` |
| Collections | `$collection` | `$collection = New-ExtractedInfoCollection` |
| Métadonnées | `$metadata` | `$metadata = @{ Author = "John" }` |
| Résultats de validation | `$validationResults` | `$validationResults = Test-ExtractedInfo -Info $info` |

### Variables spéciales

| Type | Convention | Exemple |
|------|------------|---------|
| Chemins de fichiers | Suffixe `Path` | `$outputPath = Join-Path -Path $dir -ChildPath "output.json"` |
| Expressions régulières | Préfixe `regex` | `$regexEmail = [regex]::new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")` |
| Délégués et callbacks | Suffixe `Callback` | `$validationCallback = { param($result) Write-Host $result }` |

### Variables de module

Les variables de module sont définies au niveau du module et sont accessibles par toutes les fonctions du module.

| Type | Convention | Exemple |
|------|------------|---------|
| Constantes | `MAJUSCULES_AVEC_UNDERSCORES` | `$script:DEFAULT_CONFIDENCE_SCORE = 50` |
| Variables de module | Préfixe `script:` | `$script:moduleRoot = $PSScriptRoot` |
| Variables privées | Préfixe `private:` | `$private:sensitiveData = "secret"` |

### Exemples de nommage de variables

```powershell
function Process-ExtractedInfo {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )

    # Variables de base
    $isValid = Test-ExtractedInfo -Info $Info
    $processingResult = @{}

    # Traitement conditionnel
    if ($isValid) {
        # Variables de collection
        $metadataKeys = $Info.Metadata.Keys
        $processedItems = @()

        # Boucle avec compteur
        for ($i = 0; $i -lt $metadataKeys.Count; $i++) {
            $currentKey = $metadataKeys[$i]
            $currentValue = $Info.Metadata[$currentKey]

            # Variable temporaire
            $tempProcessedValue = Convert-Value -Value $currentValue

            # Ajout à la collection
            $processedItems += @{
                Key = $currentKey
                Value = $tempProcessedValue
                Index = $i
            }
        }

        # Résultat final
        $processingResult = @{
            OriginalInfo = $Info
            ProcessedItems = $processedItems
            ProcessedAt = [datetime]::Now
            IsSuccessful = $true
        }
    }

    return $processingResult
}
```

## Préfixes et suffixes standards

Les préfixes et suffixes sont utilisés pour indiquer le type, la portée ou la fonction d'un élément. Voici les conventions à suivre pour le module ExtractedInfoModuleV2.

### Préfixes pour les fonctions

| Préfixe | Description | Exemple |
|---------|-------------|---------|
| `New-` | Crée un nouvel objet | `New-ExtractedInfo` |
| `Get-` | Récupère des informations | `Get-ExtractedInfoMetadata` |
| `Add-` | Ajoute quelque chose à un objet existant | `Add-ExtractedInfoMetadata` |
| `Remove-` | Supprime quelque chose d'un objet | `Remove-ExtractedInfoMetadata` |
| `Set-` | Définit une propriété ou un état | `Set-ExtractedInfoProperty` |
| `Convert-` | Convertit d'un format à un autre | `ConvertTo-ExtractedInfoJson` |
| `Export-` | Exporte vers un format externe | `Export-GeoLocationExtractedInfo` |
| `Import-` | Importe depuis un format externe | `Import-ExtractedInfoFromFile` |
| `Test-` | Valide ou vérifie | `Test-ExtractedInfo` |
| `Save-` | Enregistre dans un fichier | `Save-ExtractedInfoToFile` |
| `Copy-` | Crée une copie d'un objet | `Copy-ExtractedInfo` |

### Préfixes pour les variables

| Préfixe | Description | Exemple |
|---------|-------------|---------|
| `is` | Variable booléenne indiquant un état | `$isValid`, `$isProcessed` |
| `has` | Variable booléenne indiquant une possession | `$hasMetadata`, `$hasErrors` |
| `should` | Variable booléenne indiquant une action conditionnelle | `$shouldProcess`, `$shouldContinue` |
| `temp` | Variable temporaire | `$tempResult`, `$tempFile` |
| `regex` | Expression régulière | `$regexEmail`, `$regexUrl` |
| `script:` | Variable de portée script | `$script:moduleRoot` |
| `private:` | Variable privée | `$private:sensitiveData` |

### Suffixes pour les variables

| Suffixe | Description | Exemple |
|---------|-------------|---------|
| `Path` | Chemin de fichier ou de répertoire | `$outputPath`, `$modulePath` |
| `Map` ou `Table` | Hashtable ou dictionnaire | `$metadataMap`, `$configTable` |
| `Func` ou `Function` | Fonction ou délégué | `$validationFunc`, `$processFunction` |
| `Callback` | Fonction de rappel | `$completionCallback` |
| `List` ou `Array` | Collection ou tableau | `$itemsList`, `$resultsArray` |
| `Count` | Compteur | `$itemsCount`, `$errorsCount` |
| `Index` | Index dans une collection | `$currentIndex`, `$startIndex` |

### Préfixes pour les types d'objets

| Préfixe | Description | Exemple |
|---------|-------------|---------|
| `Text` | Objet lié au texte | `TextExtractedInfo` |
| `Structured` | Objet lié aux données structurées | `StructuredDataExtractedInfo` |
| `GeoLocation` | Objet lié à la géolocalisation | `GeoLocationExtractedInfo` |
| `Media` | Objet lié aux médias | `MediaExtractedInfo` |

### Suffixes pour les types d'objets

| Suffixe | Description | Exemple |
|---------|-------------|---------|
| `ExtractedInfo` | Objet d'information extraite | `TextExtractedInfo` |
| `Collection` | Collection d'objets | `ExtractedInfoCollection` |
| `Result` | Résultat d'une opération | `ValidationResult` |
| `Exception` | Exception personnalisée | `ExtractedInfoValidationException` |
| `Options` | Options de configuration | `ExportOptions` |
| `Settings` | Paramètres de configuration | `ModuleSettings` |

### Exemples d'utilisation des préfixes et suffixes

```powershell
# Fonction avec préfixe New-
function New-ExtractedInfoCollection {
    param (
        [string]$Name
    )

    # Variable avec préfixe script:
    $script:collectionCount++

    # Variable avec suffixe Map
    $itemsMap = @{}

    # Variable avec préfixe is
    $isNameValid = -not [string]::IsNullOrWhiteSpace($Name)

    # Objet avec suffixe Collection
    $collection = @{
        _Type = "ExtractedInfoCollection"
        Id = [guid]::NewGuid().ToString()
        Name = if ($isNameValid) { $Name } else { "Collection-$script:collectionCount" }
        Items = @()
        CreatedAt = [datetime]::Now
    }

    return $collection
}
```
