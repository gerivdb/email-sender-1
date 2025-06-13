# New-MediaExtractedInfo

## SYNOPSIS

Crée un nouvel objet d'information extraite pour les fichiers média.

## SYNTAXE

```powershell
New-MediaExtractedInfo
    -MediaPath <String>
    [-MediaType <String>]
    [-MediaSize <Int64>]
    [-Source <String>]
    [-ExtractorName <String>]
    [-ProcessingState <String>]
    [-ConfidenceScore <Int32>]
    [<CommonParameters>]
```plaintext
## DESCRIPTION

La fonction `New-MediaExtractedInfo` crée un nouvel objet d'information extraite spécialisé pour les fichiers média comme des images, des vidéos, des fichiers audio ou des documents. Cet objet étend le type de base `ExtractedInfo` avec des propriétés spécifiques aux médias, comme le chemin du fichier, le type de média et la taille du fichier.

Cette fonction est particulièrement utile pour stocker et manipuler des références à des fichiers média extraits ou générés lors du traitement d'informations.

## PARAMÈTRES

### -MediaPath

Spécifie le chemin vers le fichier média. Ce paramètre est obligatoire.

```yaml
Type: String
Required: True
```plaintext
### -MediaType

Spécifie le type de média. Les valeurs valides sont : "Image", "Video", "Audio", "Document".

```yaml
Type: String
Default: "Image"
```plaintext
### -MediaSize

Spécifie la taille du fichier média en octets.

```yaml
Type: Int64
Default: 0
```plaintext
### -Source

Spécifie la source de l'information extraite (par exemple, un nom de fichier, une URL, ou une description de la source).

```yaml
Type: String
Default: "Unknown"
```plaintext
### -ExtractorName

Spécifie le nom de l'extracteur utilisé pour obtenir cette information.

```yaml
Type: String
Default: "MediaExtractor"
```plaintext
### -ProcessingState

Spécifie l'état de traitement actuel de l'information extraite.
Les valeurs valides sont : "Raw", "Processed", "Validated", "Error".

```yaml
Type: String
Default: "Raw"
```plaintext
### -ConfidenceScore

Spécifie le score de confiance associé à l'information extraite, sur une échelle de 0 à 100.

```yaml
Type: Int32
Default: 50
```plaintext
### <CommonParameters>

Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES

Aucune. Cette fonction ne prend pas d'entrée depuis le pipeline.

## SORTIES

Retourne une hashtable PowerShell représentant l'objet d'information extraite de type média avec les propriétés suivantes :

- **_Type** : Type de l'information extraite (toujours "MediaExtractedInfo")
- **Id** : Identifiant unique (GUID) généré automatiquement
- **Source** : Source de l'information
- **ExtractorName** : Nom de l'extracteur utilisé
- **ExtractionDate** : Date et heure de l'extraction (définie automatiquement)
- **LastModifiedDate** : Date et heure de la dernière modification (définie automatiquement)
- **ProcessingState** : État de traitement actuel
- **ConfidenceScore** : Score de confiance (0-100)
- **Metadata** : Hashtable vide pour stocker des métadonnées additionnelles
- **MediaPath** : Chemin vers le fichier média
- **MediaType** : Type de média (Image, Video, Audio, Document)
- **MediaSize** : Taille du fichier en octets

## NOTES

- L'identifiant (Id) est généré automatiquement sous forme de GUID pour garantir l'unicité.
- Les dates d'extraction et de dernière modification sont définies automatiquement à la date et l'heure actuelles.
- La hashtable Metadata est initialisée vide et peut être utilisée pour stocker des informations supplémentaires.
- Le paramètre MediaPath est obligatoire car il constitue l'information principale de ce type d'objet.
- Cette fonction ne vérifie pas l'existence du fichier spécifié par MediaPath.
- Si MediaSize n'est pas spécifié et que le fichier existe, il est recommandé de récupérer la taille réelle du fichier.

## EXEMPLES

### Exemple 1 : Créer un objet d'information extraite pour une image

```powershell
$mediaInfo = New-MediaExtractedInfo -MediaPath "C:\Images\photo.jpg" -MediaType "Image"
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type média pour une image avec le chemin spécifié et les autres valeurs par défaut.

### Exemple 2 : Créer un objet d'information extraite pour une vidéo avec taille spécifiée

```powershell
$mediaInfo = New-MediaExtractedInfo -MediaPath "C:\Videos\recording.mp4" -MediaType "Video" -MediaSize 15728640
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type média pour une vidéo en spécifiant le chemin, le type et la taille (15 Mo).

### Exemple 3 : Créer un objet d'information extraite pour un document avec toutes les propriétés

```powershell
$mediaInfo = New-MediaExtractedInfo -MediaPath "C:\Documents\report.pdf" `
                                   -MediaType "Document" `
                                   -MediaSize 2097152 `
                                   -Source "FileSystem" `
                                   -ExtractorName "DocumentScanner" `
                                   -ProcessingState "Processed" `
                                   -ConfidenceScore 85
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type média pour un document PDF en spécifiant toutes les propriétés disponibles.

### Exemple 4 : Créer un objet d'information extraite pour un fichier audio et ajouter des métadonnées

```powershell
# Obtenir la taille réelle du fichier

$filePath = "C:\Music\song.mp3"
$fileSize = (Get-Item -Path $filePath).Length

$mediaInfo = New-MediaExtractedInfo -MediaPath $filePath -MediaType "Audio" -MediaSize $fileSize
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Duration" -Value "3:45"
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Artist" -Value "Example Artist"
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Album" -Value "Example Album"
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type média pour un fichier audio en récupérant d'abord la taille réelle du fichier, puis en ajoutant des métadonnées spécifiques à l'audio comme la durée, l'artiste et l'album.

## LIENS CONNEXES

- [New-ExtractedInfo](New-ExtractedInfo.md)
- [New-TextExtractedInfo](New-TextExtractedInfo.md)
- [New-StructuredDataExtractedInfo](New-StructuredDataExtractedInfo.md)
- [Copy-ExtractedInfo](Copy-ExtractedInfo.md)
- [Add-ExtractedInfoMetadata](Add-ExtractedInfoMetadata.md)
