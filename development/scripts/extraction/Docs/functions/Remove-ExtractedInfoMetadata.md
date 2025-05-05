# Remove-ExtractedInfoMetadata

## SYNOPSIS
Supprime une ou plusieurs métadonnées d'un objet d'information extraite.

## SYNTAXE

```powershell
Remove-ExtractedInfoMetadata
    -Info <Hashtable>
    -Key <String>
    [-UpdateLastModifiedDate]
    [<CommonParameters>]
```

```powershell
Remove-ExtractedInfoMetadata
    -Info <Hashtable>
    -Keys <String[]>
    [-UpdateLastModifiedDate]
    [<CommonParameters>]
```

```powershell
Remove-ExtractedInfoMetadata
    -Info <Hashtable>
    -All
    [-UpdateLastModifiedDate]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `Remove-ExtractedInfoMetadata` permet de supprimer des métadonnées d'un objet d'information extraite. Elle prend en charge trois modes d'utilisation :

1. Suppression d'une métadonnée spécifique en utilisant le paramètre `-Key`.
2. Suppression de plusieurs métadonnées en une seule opération en utilisant le paramètre `-Keys`.
3. Suppression de toutes les métadonnées en utilisant le paramètre `-All`.

Dans tous les cas, la fonction retourne une nouvelle instance de l'objet d'information extraite avec les métadonnées mises à jour.

## PARAMÈTRES

### -Info
Spécifie l'objet d'information extraite dont on souhaite supprimer des métadonnées. Ce paramètre est obligatoire.

```yaml
Type: Hashtable
Required: True
```

### -Key
Spécifie la clé (nom) de la métadonnée à supprimer. Ce paramètre est obligatoire pour le premier jeu de paramètres.

```yaml
Type: String
Required: True (pour le premier jeu de paramètres)
```

### -Keys
Spécifie un tableau de clés (noms) des métadonnées à supprimer. Ce paramètre est obligatoire pour le deuxième jeu de paramètres.

```yaml
Type: String[]
Required: True (pour le deuxième jeu de paramètres)
```

### -All
Indique que toutes les métadonnées doivent être supprimées. Ce paramètre est obligatoire pour le troisième jeu de paramètres.

```yaml
Type: SwitchParameter
Required: True (pour le troisième jeu de paramètres)
```

### -UpdateLastModifiedDate
Indique si la propriété LastModifiedDate de l'objet d'information extraite doit être mise à jour avec la date et l'heure actuelles.

```yaml
Type: SwitchParameter
Default: True
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
### System.Collections.Hashtable
Vous pouvez transmettre un objet d'information extraite via le pipeline.

## SORTIES
Retourne une hashtable PowerShell représentant l'objet d'information extraite avec les métadonnées mises à jour (certaines ou toutes supprimées).

## NOTES
- Cette fonction crée une copie de l'objet d'information extraite original et en supprime les métadonnées spécifiées. L'objet original n'est pas modifié.
- Si une métadonnée spécifiée n'existe pas, la fonction ne génère pas d'erreur et continue avec les autres métadonnées.
- Par défaut, la date de dernière modification (LastModifiedDate) est mise à jour à la date et l'heure actuelles. Utilisez -UpdateLastModifiedDate:$false pour conserver la date de l'objet original.
- L'identifiant (Id) de l'objet est préservé lors de la suppression de métadonnées.
- Lorsque toutes les métadonnées sont supprimées avec le paramètre `-All`, la propriété Metadata est réinitialisée à une hashtable vide.

## EXEMPLES

### Exemple 1 : Supprimer une métadonnée spécifique
```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$info = Add-ExtractedInfoMetadata -Info $info -Key "PageCount" -Value 42
$info = Add-ExtractedInfoMetadata -Info $info -Key "Author" -Value "John Doe"

# Supprimer la métadonnée "Author"
$info = Remove-ExtractedInfoMetadata -Info $info -Key "Author"

# Vérifier que la métadonnée a été supprimée
$metadata = Get-ExtractedInfoMetadata -Info $info
Write-Host "Métadonnées restantes : $($metadata.Keys -join ', ')"
```

Cet exemple supprime la métadonnée "Author" d'un objet d'information extraite.

### Exemple 2 : Supprimer plusieurs métadonnées en une seule opération
```powershell
$info = New-TextExtractedInfo -Source "article.html" -Text "Contenu de l'article"
$info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
    URL = "https://example.com/article"
    Author = "John Doe"
    PublicationDate = Get-Date -Year 2023 -Month 5 -Day 15
    Tags = @("news", "technology", "example")
}

# Supprimer plusieurs métadonnées
$info = Remove-ExtractedInfoMetadata -Info $info -Keys @("Author", "PublicationDate", "NonExistentKey")

# Vérifier les métadonnées restantes
$metadata = Get-ExtractedInfoMetadata -Info $info
Write-Host "Métadonnées restantes : $($metadata.Keys -join ', ')"
```

Cet exemple supprime plusieurs métadonnées ("Author", "PublicationDate") en une seule opération. Notez que la clé "NonExistentKey" n'existe pas, mais cela n'empêche pas la fonction de fonctionner correctement.

### Exemple 3 : Supprimer toutes les métadonnées
```powershell
$info = New-StructuredDataExtractedInfo -Source "api.example.com" -Data @{ Result = "Success" }
$info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
    RequestTime = Get-Date
    ResponseCode = 200
    Endpoint = "/api/data"
}

# Supprimer toutes les métadonnées
$info = Remove-ExtractedInfoMetadata -Info $info -All

# Vérifier que toutes les métadonnées ont été supprimées
$metadata = Get-ExtractedInfoMetadata -Info $info
Write-Host "Nombre de métadonnées : $($metadata.Count)"
```

Cet exemple supprime toutes les métadonnées d'un objet d'information extraite de type données structurées.

### Exemple 4 : Supprimer des métadonnées sans mettre à jour la date de dernière modification
```powershell
$info = New-MediaExtractedInfo -MediaPath "C:\Images\photo.jpg" -MediaType "Image"
$info = Add-ExtractedInfoMetadata -Info $info -Key "Resolution" -Value "1920x1080"

$originalDate = $info.LastModifiedDate

# Supprimer une métadonnée sans mettre à jour la date de dernière modification
$info = Remove-ExtractedInfoMetadata -Info $info -Key "Resolution" -UpdateLastModifiedDate:$false

# Vérifier que la date n'a pas été mise à jour
if ($info.LastModifiedDate -eq $originalDate) {
    Write-Host "La date de dernière modification n'a pas été mise à jour."
}
else {
    Write-Host "La date de dernière modification a été mise à jour."
}
```

Cet exemple supprime une métadonnée sans mettre à jour la date de dernière modification de l'objet.

### Exemple 5 : Utiliser Remove-ExtractedInfoMetadata avec le pipeline
```powershell
$infos = @(
    (New-ExtractedInfo -Source "source1"),
    (New-ExtractedInfo -Source "source2")
)

# Ajouter des métadonnées aux objets
$infos[0] = Add-ExtractedInfoMetadata -Info $infos[0] -Metadata @{
    Tag = "Important"
    Priority = "High"
}
$infos[1] = Add-ExtractedInfoMetadata -Info $infos[1] -Metadata @{
    Tag = "Normal"
    Priority = "Medium"
}

# Supprimer la métadonnée "Priority" de tous les objets
$updatedInfos = $infos | Remove-ExtractedInfoMetadata -Key "Priority"

# Vérifier les métadonnées restantes
foreach ($info in $updatedInfos) {
    $metadata = Get-ExtractedInfoMetadata -Info $info
    Write-Host "Source: $($info.Source), Métadonnées restantes : $($metadata.Keys -join ', ')"
}
```

Cet exemple utilise le pipeline pour supprimer une métadonnée spécifique de plusieurs objets d'information extraite.

### Exemple 6 : Supprimer des métadonnées d'un objet sans métadonnées
```powershell
$info = New-ExtractedInfo -Source "empty.txt" -ExtractorName "TextExtractor"

# Tenter de supprimer une métadonnée inexistante
$info = Remove-ExtractedInfoMetadata -Info $info -Key "NonExistent"

# Vérifier les métadonnées
$metadata = Get-ExtractedInfoMetadata -Info $info
Write-Host "Nombre de métadonnées : $($metadata.Count)"
```

Cet exemple montre que la suppression d'une métadonnée inexistante ne génère pas d'erreur.

## LIENS CONNEXES
- [Add-ExtractedInfoMetadata](Add-ExtractedInfoMetadata.md)
- [Get-ExtractedInfoMetadata](Get-ExtractedInfoMetadata.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
- [Copy-ExtractedInfo](Copy-ExtractedInfo.md)
