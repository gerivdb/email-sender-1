# Add-ExtractedInfoToCollection

## SYNOPSIS
Ajoute un ou plusieurs objets d'information extraite à une collection.

## SYNTAXE

```powershell
Add-ExtractedInfoToCollection
    -Collection <Hashtable>
    -Info <Hashtable>
    [-UpdateLastModifiedDate]
    [<CommonParameters>]
```

```powershell
Add-ExtractedInfoToCollection
    -Collection <Hashtable>
    -InfoList <Hashtable[]>
    [-UpdateLastModifiedDate]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `Add-ExtractedInfoToCollection` ajoute un ou plusieurs objets d'information extraite à une collection existante. Elle prend en charge deux modes d'utilisation :

1. Ajout d'un seul objet d'information extraite en utilisant le paramètre `-Info`.
2. Ajout de plusieurs objets d'information extraite en une seule opération en utilisant le paramètre `-InfoList`.

La fonction gère automatiquement la mise à jour des index si la collection est indexée, et retourne une nouvelle instance de la collection avec les éléments ajoutés.

## PARAMÈTRES

### -Collection
Spécifie la collection à laquelle ajouter des objets d'information extraite. Ce paramètre est obligatoire.

```yaml
Type: Hashtable
Required: True
```

### -Info
Spécifie l'objet d'information extraite à ajouter à la collection. Ce paramètre est obligatoire pour le premier jeu de paramètres.

```yaml
Type: Hashtable
Required: True (pour le premier jeu de paramètres)
```

### -InfoList
Spécifie un tableau d'objets d'information extraite à ajouter à la collection. Ce paramètre est obligatoire pour le deuxième jeu de paramètres.

```yaml
Type: Hashtable[]
Required: True (pour le deuxième jeu de paramètres)
```

### -UpdateLastModifiedDate
Indique si la propriété LastModifiedDate de la collection doit être mise à jour avec la date et l'heure actuelles.

```yaml
Type: SwitchParameter
Default: True
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
### System.Collections.Hashtable
Vous pouvez transmettre une collection via le pipeline.

## SORTIES
Retourne une hashtable PowerShell représentant la collection mise à jour avec les nouveaux objets d'information extraite ajoutés.

## NOTES
- Cette fonction crée une copie de la collection originale et y ajoute les objets d'information extraite spécifiés. La collection originale n'est pas modifiée.
- Si un objet avec le même ID existe déjà dans la collection, il sera remplacé par le nouvel objet. Cela permet de mettre à jour des éléments existants.
- Si la collection est indexée (possède une propriété Indexes), les index sont automatiquement mis à jour pour inclure les nouveaux objets.
- Par défaut, la date de dernière modification (LastModifiedDate) de la collection est mise à jour à la date et l'heure actuelles. Utilisez -UpdateLastModifiedDate:$false pour conserver la date de la collection originale.
- Cette fonction ne valide pas les objets d'information extraite avant de les ajouter. Pour garantir l'intégrité des données, il est recommandé de valider les objets avec `Test-ExtractedInfo` avant de les ajouter à une collection.

## EXEMPLES

### Exemple 1 : Ajouter un objet d'information extraite à une collection
```powershell
# Créer une collection
$collection = New-ExtractedInfoCollection -Name "MaCollection"

# Créer un objet d'information extraite
$info = New-TextExtractedInfo -Source "document.txt" -Text "Contenu du document"

# Ajouter l'objet à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
```

Cet exemple crée une collection et y ajoute un objet d'information extraite de type texte.

### Exemple 2 : Ajouter plusieurs objets d'information extraite en une seule opération
```powershell
# Créer une collection
$collection = New-ExtractedInfoCollection -Name "WebDataCollection" -CreateIndexes

# Créer plusieurs objets d'information extraite
$info1 = New-TextExtractedInfo -Source "page1.html" -Text "Contenu de la page 1"
$info2 = New-TextExtractedInfo -Source "page2.html" -Text "Contenu de la page 2"
$info3 = New-TextExtractedInfo -Source "page3.html" -Text "Contenu de la page 3"

# Ajouter les objets à la collection en une seule opération
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2, $info3)

# Vérifier le nombre d'éléments dans la collection
Write-Host "La collection contient $($collection.Items.Count) éléments."
```

Cet exemple crée une collection indexée et y ajoute trois objets d'information extraite en une seule opération.

### Exemple 3 : Mettre à jour un élément existant dans une collection
```powershell
# Créer une collection
$collection = New-ExtractedInfoCollection -Name "DataCollection"

# Créer et ajouter un objet d'information extraite
$info = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Status = "Pending" } -ProcessingState "Raw"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info

# Créer une version mise à jour de l'objet (même ID)
$updatedInfo = Copy-ExtractedInfo -Info $info -ProcessingState "Processed"
$updatedInfo.Data.Status = "Completed"

# Mettre à jour l'objet dans la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $updatedInfo

# Vérifier que la collection contient toujours un seul élément (mis à jour)
Write-Host "La collection contient $($collection.Items.Count) élément(s)."
Write-Host "État de traitement : $($collection.Items[0].ProcessingState)"
Write-Host "Statut des données : $($collection.Items[0].Data.Status)"
```

Cet exemple montre comment mettre à jour un élément existant dans une collection en ajoutant un objet avec le même ID.

### Exemple 4 : Ajouter des objets à une collection sans mettre à jour la date de dernière modification
```powershell
# Créer une collection
$collection = New-ExtractedInfoCollection -Name "ArchiveCollection"
$originalDate = $collection.LastModifiedDate

# Ajouter un objet sans mettre à jour la date de dernière modification
$info = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\Images\image.jpg" -MediaType "Image"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info -UpdateLastModifiedDate:$false

# Vérifier que la date n'a pas été mise à jour
if ($collection.LastModifiedDate -eq $originalDate) {
    Write-Host "La date de dernière modification n'a pas été mise à jour."
}
else {
    Write-Host "La date de dernière modification a été mise à jour."
}
```

Cet exemple ajoute un objet à une collection sans mettre à jour la date de dernière modification.

### Exemple 5 : Utiliser Add-ExtractedInfoToCollection avec le pipeline
```powershell
# Créer plusieurs collections
$collections = @(
    (New-ExtractedInfoCollection -Name "Collection1"),
    (New-ExtractedInfoCollection -Name "Collection2")
)

# Créer un objet d'information extraite
$info = New-TextExtractedInfo -Source "shared.txt" -Text "Information partagée"

# Ajouter le même objet à toutes les collections via le pipeline
$updatedCollections = $collections | Add-ExtractedInfoToCollection -Info $info

# Vérifier que l'objet a été ajouté à toutes les collections
foreach ($collection in $updatedCollections) {
    Write-Host "Collection '$($collection.Name)' contient $($collection.Items.Count) élément(s)."
}
```

Cet exemple utilise le pipeline pour ajouter le même objet d'information extraite à plusieurs collections.

### Exemple 6 : Ajouter des objets de différents types à une collection indexée
```powershell
# Créer une collection indexée
$collection = New-ExtractedInfoCollection -Name "MixedDataCollection" -CreateIndexes

# Créer des objets de différents types
$textInfo = New-TextExtractedInfo -Source "document.txt" -Text "Exemple de texte"
$structuredInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Test"; Value = 123 }
$mediaInfo = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\Images\image.jpg" -MediaType "Image"

# Ajouter tous les objets à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($textInfo, $structuredInfo, $mediaInfo)

# Vérifier les index
Write-Host "La collection contient $($collection.Items.Count) éléments."
Write-Host "Index par type :"
foreach ($type in $collection.Indexes.Type.Keys) {
    $count = $collection.Indexes.Type[$type].Count
    Write-Host "- $type : $count élément(s)"
}
```

Cet exemple ajoute des objets de différents types à une collection indexée et vérifie les index par type.

## LIENS CONNEXES
- [New-ExtractedInfoCollection](New-ExtractedInfoCollection.md)
- [Get-ExtractedInfoFromCollection](Get-ExtractedInfoFromCollection.md)
- [Get-ExtractedInfoCollectionStatistics](Get-ExtractedInfoCollectionStatistics.md)
- [Copy-ExtractedInfoCollection](Copy-ExtractedInfoCollection.md)
- [Test-ExtractedInfo](Test-ExtractedInfo.md)
