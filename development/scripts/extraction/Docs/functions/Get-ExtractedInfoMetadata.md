# Get-ExtractedInfoMetadata

## SYNOPSIS
Récupère les métadonnées d'un objet d'information extraite.

## SYNTAXE

```powershell
Get-ExtractedInfoMetadata
    -Info <Hashtable>
    [-Key <String>]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `Get-ExtractedInfoMetadata` permet de récupérer les métadonnées associées à un objet d'information extraite. Elle peut être utilisée pour obtenir toutes les métadonnées ou une métadonnée spécifique identifiée par sa clé.

Les métadonnées sont des informations supplémentaires qui peuvent être associées à l'objet principal pour fournir du contexte, des détails ou des propriétés personnalisées.

## PARAMÈTRES

### -Info
Spécifie l'objet d'information extraite dont on souhaite récupérer les métadonnées. Ce paramètre est obligatoire.

```yaml
Type: Hashtable
Required: True
```

### -Key
Spécifie la clé (nom) de la métadonnée à récupérer. Si ce paramètre n'est pas spécifié, toutes les métadonnées sont retournées.

```yaml
Type: String
Required: False
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
### System.Collections.Hashtable
Vous pouvez transmettre un objet d'information extraite via le pipeline.

## SORTIES
Si le paramètre `-Key` est spécifié, la fonction retourne la valeur de la métadonnée correspondante. Si la clé n'existe pas, la fonction retourne `$null`.

Si le paramètre `-Key` n'est pas spécifié, la fonction retourne une hashtable contenant toutes les métadonnées de l'objet d'information extraite. Si l'objet ne contient aucune métadonnée, une hashtable vide est retournée.

## NOTES
- Cette fonction ne modifie pas l'objet d'information extraite original.
- Les métadonnées peuvent être de n'importe quel type d'objet PowerShell, y compris des types complexes comme des hashtables ou des tableaux.
- Si vous récupérez une métadonnée de type complexe (hashtable, tableau), vous obtenez une référence à l'objet original. Toute modification de cet objet affectera l'objet d'information extraite original.

## EXEMPLES

### Exemple 1 : Récupérer toutes les métadonnées d'un objet d'information extraite
```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$info = Add-ExtractedInfoMetadata -Info $info -Key "PageCount" -Value 42
$info = Add-ExtractedInfoMetadata -Info $info -Key "Author" -Value "John Doe"

$allMetadata = Get-ExtractedInfoMetadata -Info $info
Write-Host "Nombre de métadonnées : $($allMetadata.Count)"
foreach ($key in $allMetadata.Keys) {
    Write-Host "$key : $($allMetadata[$key])"
}
```

Cet exemple récupère toutes les métadonnées d'un objet d'information extraite et les affiche.

### Exemple 2 : Récupérer une métadonnée spécifique
```powershell
$info = New-TextExtractedInfo -Source "article.html" -Text "Contenu de l'article"
$info = Add-ExtractedInfoMetadata -Info $info -Key "URL" -Value "https://example.com/article"
$info = Add-ExtractedInfoMetadata -Info $info -Key "Author" -Value "John Doe"

$author = Get-ExtractedInfoMetadata -Info $info -Key "Author"
Write-Host "Auteur : $author"
```

Cet exemple récupère spécifiquement la métadonnée "Author" d'un objet d'information extraite.

### Exemple 3 : Vérifier l'existence d'une métadonnée
```powershell
$info = New-ExtractedInfo -Source "data.json" -ExtractorName "JsonExtractor"
$info = Add-ExtractedInfoMetadata -Info $info -Key "Version" -Value "1.0"

$version = Get-ExtractedInfoMetadata -Info $info -Key "Version"
$creationDate = Get-ExtractedInfoMetadata -Info $info -Key "CreationDate"

if ($version -ne $null) {
    Write-Host "Version : $version"
}
else {
    Write-Host "La métadonnée 'Version' n'existe pas."
}

if ($creationDate -ne $null) {
    Write-Host "Date de création : $creationDate"
}
else {
    Write-Host "La métadonnée 'CreationDate' n'existe pas."
}
```

Cet exemple vérifie l'existence de deux métadonnées différentes et affiche un message approprié.

### Exemple 4 : Récupérer et manipuler une métadonnée complexe
```powershell
$info = New-MediaExtractedInfo -MediaPath "C:\Images\photo.jpg" -MediaType "Image"
$exifData = @{
    Camera = "Canon EOS R5"
    Resolution = @{
        Width = 8192
        Height = 5464
    }
    Settings = @{
        ISO = 100
        Aperture = "f/2.8"
        ShutterSpeed = "1/250"
    }
}
$info = Add-ExtractedInfoMetadata -Info $info -Key "EXIF" -Value $exifData

$exif = Get-ExtractedInfoMetadata -Info $info -Key "EXIF"
Write-Host "Appareil photo : $($exif.Camera)"
Write-Host "Résolution : $($exif.Resolution.Width) x $($exif.Resolution.Height)"
Write-Host "ISO : $($exif.Settings.ISO)"
```

Cet exemple récupère une métadonnée complexe (hashtable imbriquée) et accède à ses propriétés.

### Exemple 5 : Utiliser Get-ExtractedInfoMetadata avec le pipeline
```powershell
$infos = @(
    (New-ExtractedInfo -Source "source1"),
    (New-ExtractedInfo -Source "source2")
)

$infos[0] = Add-ExtractedInfoMetadata -Info $infos[0] -Key "Tag" -Value "Important"
$infos[1] = Add-ExtractedInfoMetadata -Info $infos[1] -Key "Tag" -Value "Normal"

$infos | ForEach-Object {
    $tag = Get-ExtractedInfoMetadata -Info $_ -Key "Tag"
    Write-Host "Source: $($_.Source), Tag: $tag"
}
```

Cet exemple utilise le pipeline pour récupérer une métadonnée spécifique de plusieurs objets d'information extraite.

### Exemple 6 : Récupérer des métadonnées d'un objet sans métadonnées
```powershell
$info = New-ExtractedInfo -Source "empty.txt" -ExtractorName "TextExtractor"

$allMetadata = Get-ExtractedInfoMetadata -Info $info
Write-Host "Nombre de métadonnées : $($allMetadata.Count)"

$nonExistentKey = Get-ExtractedInfoMetadata -Info $info -Key "NonExistent"
if ($nonExistentKey -eq $null) {
    Write-Host "La métadonnée 'NonExistent' n'existe pas."
}
```

Cet exemple montre le comportement de la fonction lorsqu'elle est utilisée sur un objet sans métadonnées ou avec une clé inexistante.

## LIENS CONNEXES
- [Add-ExtractedInfoMetadata](Add-ExtractedInfoMetadata.md)
- [Remove-ExtractedInfoMetadata](Remove-ExtractedInfoMetadata.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
- [Copy-ExtractedInfo](Copy-ExtractedInfo.md)
