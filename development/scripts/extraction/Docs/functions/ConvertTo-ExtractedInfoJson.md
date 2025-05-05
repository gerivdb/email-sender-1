# ConvertTo-ExtractedInfoJson

## SYNOPSIS
Convertit un objet d'information extraite ou une collection en format JSON.

## SYNTAXE

```powershell
ConvertTo-ExtractedInfoJson
    -Info <Hashtable>
    [-Indent]
    [-Depth <Int32>]
    [-ExcludeMetadata]
    [<CommonParameters>]
```

```powershell
ConvertTo-ExtractedInfoJson
    -Collection <Hashtable>
    [-Indent]
    [-Depth <Int32>]
    [-ExcludeMetadata]
    [-ExcludeIndexes]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `ConvertTo-ExtractedInfoJson` convertit un objet d'information extraite ou une collection d'informations extraites en format JSON. Cette fonction prend en charge deux modes d'utilisation :

1. Conversion d'un objet d'information extraite individuel en utilisant le paramètre `-Info`.
2. Conversion d'une collection d'informations extraites en utilisant le paramètre `-Collection`.

La fonction offre plusieurs options pour contrôler le format et le contenu de la sortie JSON, comme l'indentation, la profondeur de sérialisation, et l'exclusion de certaines propriétés.

## PARAMÈTRES

### -Info
Spécifie l'objet d'information extraite à convertir en JSON. Ce paramètre est obligatoire pour le premier jeu de paramètres.

```yaml
Type: Hashtable
Required: True (pour le premier jeu de paramètres)
```

### -Collection
Spécifie la collection d'informations extraites à convertir en JSON. Ce paramètre est obligatoire pour le deuxième jeu de paramètres.

```yaml
Type: Hashtable
Required: True (pour le deuxième jeu de paramètres)
```

### -Indent
Indique si le JSON généré doit être formaté avec des indentations et des sauts de ligne pour une meilleure lisibilité.

```yaml
Type: SwitchParameter
Default: False
```

### -Depth
Spécifie la profondeur maximale de sérialisation pour les objets imbriqués.

```yaml
Type: Int32
Default: 100
```

### -ExcludeMetadata
Indique si les métadonnées doivent être exclues de la sortie JSON.

```yaml
Type: SwitchParameter
Default: False
```

### -ExcludeIndexes
Indique si les index de la collection doivent être exclus de la sortie JSON. Ce paramètre n'est applicable que lors de la conversion d'une collection.

```yaml
Type: SwitchParameter
Default: False
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
### System.Collections.Hashtable
Vous pouvez transmettre un objet d'information extraite ou une collection via le pipeline.

## SORTIES
### System.String
Retourne une chaîne de caractères contenant la représentation JSON de l'objet d'information extraite ou de la collection.

## NOTES
- Cette fonction ne modifie pas l'objet d'information extraite ou la collection originale.
- Les dates (ExtractionDate, LastModifiedDate, CreationDate) sont converties en chaînes ISO 8601 pour assurer la compatibilité JSON.
- Pour les objets de type StructuredDataExtractedInfo, les données structurées sont converties en JSON de manière récursive.
- L'option -ExcludeMetadata peut être utile pour réduire la taille du JSON si les métadonnées ne sont pas nécessaires.
- Pour les collections, l'option -ExcludeIndexes peut réduire considérablement la taille du JSON, mais les index devront être recréés lors de la désérialisation.
- La profondeur par défaut de 100 est généralement suffisante pour la plupart des cas d'utilisation, mais peut être ajustée pour des structures de données très complexes.

## EXEMPLES

### Exemple 1 : Convertir un objet d'information extraite simple en JSON
```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor" -ProcessingState "Processed" -ConfidenceScore 85
$json = ConvertTo-ExtractedInfoJson -Info $info
Write-Host $json
```

Cet exemple convertit un objet d'information extraite simple en JSON sans indentation.

### Exemple 2 : Convertir un objet d'information extraite en JSON indenté
```powershell
$info = New-TextExtractedInfo -Source "article.html" -Text "Ceci est un exemple de texte extrait d'un article." -Language "fr"
$info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
    URL = "https://example.com/article"
    Author = "John Doe"
    PublicationDate = Get-Date -Year 2023 -Month 5 -Day 15
}

$json = ConvertTo-ExtractedInfoJson -Info $info -Indent
Write-Host $json
```

Cet exemple convertit un objet d'information extraite de type texte avec métadonnées en JSON indenté pour une meilleure lisibilité.

### Exemple 3 : Convertir un objet d'information extraite en JSON sans métadonnées
```powershell
$info = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
    Person = @{
        FirstName = "John"
        LastName = "Doe"
        Age = 30
        Contact = @{
            Email = "john.doe@example.com"
            Phone = "+1234567890"
        }
    }
    Addresses = @(
        @{
            Type = "Home"
            Street = "123 Main St"
            City = "Anytown"
            Country = "USA"
        },
        @{
            Type = "Work"
            Street = "456 Business Ave"
            City = "Worktown"
            Country = "USA"
        }
    )
}
$info = Add-ExtractedInfoMetadata -Info $info -Key "DataSource" -Value "API"

# Convertir en JSON sans métadonnées
$json = ConvertTo-ExtractedInfoJson -Info $info -ExcludeMetadata -Indent
Write-Host $json
```

Cet exemple convertit un objet d'information extraite de type données structurées en JSON indenté, en excluant les métadonnées.

### Exemple 4 : Convertir une collection en JSON
```powershell
# Créer une collection
$collection = New-ExtractedInfoCollection -Name "JsonDemo" -Description "Collection pour démonstration JSON" -CreateIndexes

# Ajouter quelques objets
$info1 = New-TextExtractedInfo -Source "doc1.txt" -Text "Texte 1"
$info2 = New-TextExtractedInfo -Source "doc2.txt" -Text "Texte 2"
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)

# Convertir en JSON
$json = ConvertTo-ExtractedInfoJson -Collection $collection -Indent
Write-Host $json
```

Cet exemple convertit une collection d'informations extraites en JSON indenté.

### Exemple 5 : Convertir une collection en JSON sans index
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

# Convertir en JSON avec et sans index
$jsonWithIndexes = ConvertTo-ExtractedInfoJson -Collection $collection
$jsonWithoutIndexes = ConvertTo-ExtractedInfoJson -Collection $collection -ExcludeIndexes

# Comparer les tailles
$withSize = $jsonWithIndexes.Length
$withoutSize = $jsonWithoutIndexes.Length
$reduction = [Math]::Round(100 - ($withoutSize / $withSize * 100), 2)

Write-Host "Taille avec index : $withSize caractères"
Write-Host "Taille sans index : $withoutSize caractères"
Write-Host "Réduction : $reduction%"
```

Cet exemple compare la taille du JSON généré pour une collection avec et sans index, montrant la réduction de taille obtenue en excluant les index.

### Exemple 6 : Contrôler la profondeur de sérialisation
```powershell
# Créer un objet avec des données profondément imbriquées
$deepData = @{
    Level1 = @{
        Level2 = @{
            Level3 = @{
                Level4 = @{
                    Level5 = @{
                        Value = "Valeur profondément imbriquée"
                    }
                }
            }
        }
    }
}
$info = New-StructuredDataExtractedInfo -Source "deep.json" -Data $deepData

# Convertir avec différentes profondeurs
$jsonFullDepth = ConvertTo-ExtractedInfoJson -Info $info -Indent
$jsonLimitedDepth = ConvertTo-ExtractedInfoJson -Info $info -Indent -Depth 3

Write-Host "JSON avec profondeur complète :"
Write-Host $jsonFullDepth
Write-Host "`nJSON avec profondeur limitée à 3 :"
Write-Host $jsonLimitedDepth
```

Cet exemple montre comment contrôler la profondeur de sérialisation pour des objets avec des structures de données profondément imbriquées.

### Exemple 7 : Utiliser ConvertTo-ExtractedInfoJson avec le pipeline
```powershell
# Créer plusieurs objets
$infos = @(
    (New-ExtractedInfo -Source "source1"),
    (New-TextExtractedInfo -Source "source2" -Text "Texte"),
    (New-StructuredDataExtractedInfo -Source "source3" -Data @{ Key = "Value" })
)

# Convertir tous les objets en JSON via le pipeline
$jsons = $infos | ForEach-Object {
    $json = $_ | ConvertTo-ExtractedInfoJson -Indent
    [PSCustomObject]@{
        Type = $_._Type
        Id = $_.Id
        JsonLength = $json.Length
        Json = $json
    }
}

# Afficher les résultats
$jsons | Format-Table -Property Type, Id, JsonLength -AutoSize
```

Cet exemple utilise le pipeline pour convertir plusieurs objets d'information extraite en JSON et analyser les résultats.

## LIENS CONNEXES
- [ConvertFrom-ExtractedInfoJson](ConvertFrom-ExtractedInfoJson.md)
- [Save-ExtractedInfoToFile](Save-ExtractedInfoToFile.md)
- [Load-ExtractedInfoFromFile](Load-ExtractedInfoFromFile.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
- [New-ExtractedInfoCollection](New-ExtractedInfoCollection.md)
