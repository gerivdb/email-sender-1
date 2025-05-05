# New-ExtractedInfoCollection

## SYNOPSIS
Crée une nouvelle collection d'informations extraites.

## SYNTAXE

```powershell
New-ExtractedInfoCollection
    -Name <String>
    [-Description <String>]
    [-CreateIndexes]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `New-ExtractedInfoCollection` crée une nouvelle collection vide d'informations extraites. Une collection est un conteneur qui permet d'organiser, de gérer et d'interroger efficacement un ensemble d'objets d'information extraite.

Les collections peuvent être créées avec ou sans indexation. L'indexation améliore considérablement les performances des opérations de recherche et de filtrage, mais consomme plus de mémoire.

## PARAMÈTRES

### -Name
Spécifie le nom de la collection. Ce paramètre est obligatoire.

```yaml
Type: String
Required: True
```

### -Description
Spécifie une description de la collection.

```yaml
Type: String
Default: ""
```

### -CreateIndexes
Indique si des index doivent être créés pour améliorer les performances des opérations de recherche et de filtrage.

```yaml
Type: SwitchParameter
Default: False
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
Aucune. Cette fonction ne prend pas d'entrée depuis le pipeline.

## SORTIES
Retourne une hashtable PowerShell représentant la collection d'informations extraites avec les propriétés suivantes :

- **_Type** : Type de l'objet (toujours "ExtractedInfoCollection")
- **Name** : Nom de la collection
- **Description** : Description de la collection
- **Items** : Tableau vide pour stocker les objets d'information extraite
- **Metadata** : Hashtable vide pour stocker des métadonnées additionnelles
- **CreationDate** : Date et heure de création de la collection
- **LastModifiedDate** : Date et heure de la dernière modification
- **Indexes** : Hashtable d'index (présente uniquement si CreateIndexes est spécifié)

## NOTES
- Les dates de création et de dernière modification sont définies automatiquement à la date et l'heure actuelles.
- La collection est initialement vide (tableau Items vide).
- Si le paramètre CreateIndexes est spécifié, la collection inclut une structure d'index pour accélérer les recherches par ID, type, source et état de traitement.
- Les collections indexées consomment plus de mémoire mais offrent des performances de recherche bien meilleures, surtout pour les grandes collections.
- Pour ajouter des éléments à la collection, utilisez la fonction `Add-ExtractedInfoToCollection`.

## EXEMPLES

### Exemple 1 : Créer une collection simple
```powershell
$collection = New-ExtractedInfoCollection -Name "MaCollection"
```

Cet exemple crée une nouvelle collection vide nommée "MaCollection" sans indexation.

### Exemple 2 : Créer une collection avec description
```powershell
$collection = New-ExtractedInfoCollection -Name "DocumentsCollection" -Description "Collection de documents extraits de diverses sources"
```

Cet exemple crée une nouvelle collection avec un nom et une description.

### Exemple 3 : Créer une collection avec indexation
```powershell
$collection = New-ExtractedInfoCollection -Name "LargeDataCollection" -CreateIndexes
```

Cet exemple crée une nouvelle collection avec indexation pour améliorer les performances des opérations de recherche et de filtrage.

### Exemple 4 : Créer une collection et ajouter des métadonnées
```powershell
$collection = New-ExtractedInfoCollection -Name "ProjectCollection" -Description "Données du projet XYZ"
$collection.Metadata["Project"] = "XYZ"
$collection.Metadata["Owner"] = "Département R&D"
$collection.Metadata["CreatedBy"] = $env:USERNAME
```

Cet exemple crée une nouvelle collection et ajoute manuellement des métadonnées à la collection.

### Exemple 5 : Créer une collection et y ajouter des éléments
```powershell
# Créer une collection indexée
$collection = New-ExtractedInfoCollection -Name "WebDataCollection" -CreateIndexes

# Créer quelques objets d'information extraite
$info1 = New-TextExtractedInfo -Source "page1.html" -Text "Contenu de la page 1"
$info2 = New-TextExtractedInfo -Source "page2.html" -Text "Contenu de la page 2"

# Ajouter les objets à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)

# Vérifier le nombre d'éléments dans la collection
Write-Host "La collection contient $($collection.Items.Count) éléments."
```

Cet exemple crée une collection indexée, puis y ajoute deux objets d'information extraite.

### Exemple 6 : Créer plusieurs collections pour différents types de données
```powershell
# Collection pour les données textuelles
$textCollection = New-ExtractedInfoCollection -Name "TextData" -Description "Données textuelles extraites" -CreateIndexes

# Collection pour les données structurées
$structuredCollection = New-ExtractedInfoCollection -Name "StructuredData" -Description "Données structurées extraites" -CreateIndexes

# Collection pour les références média
$mediaCollection = New-ExtractedInfoCollection -Name "MediaData" -Description "Références aux fichiers média" -CreateIndexes

# Fonction pour ajouter un élément à la collection appropriée selon son type
function Add-ToAppropriateCollection {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )
    
    switch ($Info._Type) {
        "TextExtractedInfo" {
            $script:textCollection = Add-ExtractedInfoToCollection -Collection $textCollection -Info $Info
        }
        "StructuredDataExtractedInfo" {
            $script:structuredCollection = Add-ExtractedInfoToCollection -Collection $structuredCollection -Info $Info
        }
        "MediaExtractedInfo" {
            $script:mediaCollection = Add-ExtractedInfoToCollection -Collection $mediaCollection -Info $Info
        }
    }
}

# Exemple d'utilisation
$textInfo = New-TextExtractedInfo -Source "document.txt" -Text "Exemple de texte"
Add-ToAppropriateCollection -Info $textInfo

$structuredInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Test"; Value = 123 }
Add-ToAppropriateCollection -Info $structuredInfo

$mediaInfo = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\Images\image.jpg" -MediaType "Image"
Add-ToAppropriateCollection -Info $mediaInfo

# Afficher le nombre d'éléments dans chaque collection
Write-Host "Collection de textes : $($textCollection.Items.Count) éléments"
Write-Host "Collection de données structurées : $($structuredCollection.Items.Count) éléments"
Write-Host "Collection de médias : $($mediaCollection.Items.Count) éléments"
```

Cet exemple crée trois collections distinctes pour différents types d'informations extraites et définit une fonction pour ajouter automatiquement chaque élément à la collection appropriée en fonction de son type.

## LIENS CONNEXES
- [Add-ExtractedInfoToCollection](Add-ExtractedInfoToCollection.md)
- [Get-ExtractedInfoFromCollection](Get-ExtractedInfoFromCollection.md)
- [Get-ExtractedInfoCollectionStatistics](Get-ExtractedInfoCollectionStatistics.md)
- [Copy-ExtractedInfoCollection](Copy-ExtractedInfoCollection.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
