# Add-ExtractedInfoMetadata

## SYNOPSIS

Ajoute ou met à jour des métadonnées dans un objet d'information extraite.

## SYNTAXE

```powershell
Add-ExtractedInfoMetadata
    -Info <Hashtable>
    -Key <String>
    -Value <Object>
    [-UpdateLastModifiedDate]
    [<CommonParameters>]
```plaintext
```powershell
Add-ExtractedInfoMetadata
    -Info <Hashtable>
    -Metadata <Hashtable>
    [-UpdateLastModifiedDate]
    [<CommonParameters>]
```plaintext
## DESCRIPTION

La fonction `Add-ExtractedInfoMetadata` permet d'ajouter ou de mettre à jour des métadonnées dans un objet d'information extraite. Les métadonnées sont des informations supplémentaires qui peuvent être associées à l'objet principal pour fournir du contexte, des détails ou des propriétés personnalisées.

Cette fonction prend en charge deux modes d'utilisation :
1. Ajout d'une seule paire clé-valeur de métadonnées en utilisant les paramètres `-Key` et `-Value`.
2. Ajout de plusieurs métadonnées en une seule opération en utilisant le paramètre `-Metadata`.

Dans les deux cas, la fonction retourne une nouvelle instance de l'objet d'information extraite avec les métadonnées mises à jour.

## PARAMÈTRES

### -Info

Spécifie l'objet d'information extraite auquel ajouter des métadonnées. Ce paramètre est obligatoire.

```yaml
Type: Hashtable
Required: True
```plaintext
### -Key

Spécifie la clé (nom) de la métadonnée à ajouter ou mettre à jour. Ce paramètre est obligatoire lorsque le paramètre `-Metadata` n'est pas utilisé.

```yaml
Type: String
Required: True (pour le premier jeu de paramètres)
```plaintext
### -Value

Spécifie la valeur de la métadonnée à ajouter ou mettre à jour. Ce paramètre est obligatoire lorsque le paramètre `-Metadata` n'est pas utilisé.

```yaml
Type: Object
Required: True (pour le premier jeu de paramètres)
```plaintext
### -Metadata

Spécifie une hashtable contenant plusieurs paires clé-valeur de métadonnées à ajouter ou mettre à jour. Ce paramètre est obligatoire lorsque les paramètres `-Key` et `-Value` ne sont pas utilisés.

```yaml
Type: Hashtable
Required: True (pour le deuxième jeu de paramètres)
```plaintext
### -UpdateLastModifiedDate

Indique si la propriété LastModifiedDate de l'objet d'information extraite doit être mise à jour avec la date et l'heure actuelles.

```yaml
Type: SwitchParameter
Default: True
```plaintext
### <CommonParameters>

Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES

### System.Collections.Hashtable

Vous pouvez transmettre un objet d'information extraite via le pipeline.

## SORTIES

Retourne une hashtable PowerShell représentant l'objet d'information extraite avec les métadonnées mises à jour.

## NOTES

- Cette fonction crée une copie de l'objet d'information extraite original et y ajoute les métadonnées spécifiées. L'objet original n'est pas modifié.
- Si une métadonnée avec la même clé existe déjà, sa valeur sera remplacée par la nouvelle valeur.
- Les métadonnées peuvent être de n'importe quel type d'objet PowerShell, y compris des types complexes comme des hashtables ou des tableaux.
- Par défaut, la date de dernière modification (LastModifiedDate) est mise à jour à la date et l'heure actuelles. Utilisez -UpdateLastModifiedDate:$false pour conserver la date de l'objet original.
- L'identifiant (Id) de l'objet est préservé lors de l'ajout de métadonnées.

## EXEMPLES

### Exemple 1 : Ajouter une métadonnée simple à un objet d'information extraite

```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$info = Add-ExtractedInfoMetadata -Info $info -Key "PageCount" -Value 42
```plaintext
Cet exemple ajoute une métadonnée "PageCount" avec la valeur 42 à un objet d'information extraite.

### Exemple 2 : Ajouter plusieurs métadonnées en une seule opération

```powershell
$info = New-TextExtractedInfo -Source "article.html" -Text "Contenu de l'article"
$metadata = @{
    URL = "https://example.com/article"
    Author = "John Doe"
    PublicationDate = Get-Date -Year 2023 -Month 5 -Day 15
    Tags = @("news", "technology", "example")
}
$info = Add-ExtractedInfoMetadata -Info $info -Metadata $metadata
```plaintext
Cet exemple ajoute plusieurs métadonnées (URL, auteur, date de publication et tags) en une seule opération à un objet d'information extraite de type texte.

### Exemple 3 : Mettre à jour une métadonnée existante

```powershell
$info = New-ExtractedInfo -Source "data.json" -ExtractorName "JsonExtractor"
$info = Add-ExtractedInfoMetadata -Info $info -Key "Version" -Value "1.0"
# Plus tard, mettre à jour la version

$info = Add-ExtractedInfoMetadata -Info $info -Key "Version" -Value "1.1"
```plaintext
Cet exemple ajoute d'abord une métadonnée "Version" avec la valeur "1.0", puis la met à jour avec la valeur "1.1".

### Exemple 4 : Ajouter des métadonnées sans mettre à jour la date de dernière modification

```powershell
$info = New-StructuredDataExtractedInfo -Source "api.example.com" -Data @{ Result = "Success" }
$info = Add-ExtractedInfoMetadata -Info $info -Key "RequestTime" -Value (Get-Date) -UpdateLastModifiedDate:$false
```plaintext
Cet exemple ajoute une métadonnée "RequestTime" à un objet d'information extraite de type données structurées sans mettre à jour la date de dernière modification.

### Exemple 5 : Utiliser Add-ExtractedInfoMetadata avec le pipeline

```powershell
$infos = @(
    (New-ExtractedInfo -Source "source1"),
    (New-ExtractedInfo -Source "source2"),
    (New-ExtractedInfo -Source "source3")
)

$taggedInfos = $infos | Add-ExtractedInfoMetadata -Key "Tag" -Value "Batch1"
```plaintext
Cet exemple utilise le pipeline pour ajouter la même métadonnée "Tag" à plusieurs objets d'information extraite.

### Exemple 6 : Ajouter des métadonnées complexes

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
    GPS = @{
        Latitude = 48.8566
        Longitude = 2.3522
    }
}
$info = Add-ExtractedInfoMetadata -Info $info -Key "EXIF" -Value $exifData
```plaintext
Cet exemple ajoute une métadonnée complexe "EXIF" contenant des informations imbriquées sur une image.

## LIENS CONNEXES

- [Get-ExtractedInfoMetadata](Get-ExtractedInfoMetadata.md)
- [Remove-ExtractedInfoMetadata](Remove-ExtractedInfoMetadata.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
- [Copy-ExtractedInfo](Copy-ExtractedInfo.md)
