# New-TextExtractedInfo

## SYNOPSIS

Crée un nouvel objet d'information extraite de type texte.

## SYNTAXE

```powershell
New-TextExtractedInfo
    -Text <String>
    [-Language <String>]
    [-Source <String>]
    [-ExtractorName <String>]
    [-ProcessingState <String>]
    [-ConfidenceScore <Int32>]
    [<CommonParameters>]
```plaintext
## DESCRIPTION

La fonction `New-TextExtractedInfo` crée un nouvel objet d'information extraite spécialisé pour le contenu textuel. Cet objet étend le type de base `ExtractedInfo` avec des propriétés spécifiques au texte, comme le contenu textuel lui-même et la langue du texte.

Cette fonction est particulièrement utile pour stocker et manipuler du texte extrait de diverses sources comme des documents, des pages web, ou des transcriptions.

## PARAMÈTRES

### -Text

Spécifie le contenu textuel extrait. Ce paramètre est obligatoire.

```yaml
Type: String
Required: True
```plaintext
### -Language

Spécifie le code de langue du texte (par exemple, "en" pour l'anglais, "fr" pour le français).

```yaml
Type: String
Default: "unknown"
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
Default: "TextExtractor"
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

Retourne une hashtable PowerShell représentant l'objet d'information extraite de type texte avec les propriétés suivantes :

- **_Type** : Type de l'information extraite (toujours "TextExtractedInfo")
- **Id** : Identifiant unique (GUID) généré automatiquement
- **Source** : Source de l'information
- **ExtractorName** : Nom de l'extracteur utilisé
- **ExtractionDate** : Date et heure de l'extraction (définie automatiquement)
- **LastModifiedDate** : Date et heure de la dernière modification (définie automatiquement)
- **ProcessingState** : État de traitement actuel
- **ConfidenceScore** : Score de confiance (0-100)
- **Metadata** : Hashtable vide pour stocker des métadonnées additionnelles
- **Text** : Contenu textuel extrait
- **Language** : Code de langue du texte

## NOTES

- L'identifiant (Id) est généré automatiquement sous forme de GUID pour garantir l'unicité.
- Les dates d'extraction et de dernière modification sont définies automatiquement à la date et l'heure actuelles.
- La hashtable Metadata est initialisée vide et peut être utilisée pour stocker des informations supplémentaires.
- Le paramètre Text est obligatoire car il constitue l'information principale de ce type d'objet.

## EXEMPLES

### Exemple 1 : Créer un objet d'information extraite de type texte simple

```powershell
$textInfo = New-TextExtractedInfo -Text "Ceci est un exemple de texte extrait."
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type texte avec le contenu textuel spécifié et les autres valeurs par défaut.

### Exemple 2 : Créer un objet d'information extraite de type texte avec langue spécifiée

```powershell
$textInfo = New-TextExtractedInfo -Text "This is an example of extracted text." -Language "en"
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type texte en spécifiant le contenu textuel et la langue (anglais).

### Exemple 3 : Créer un objet d'information extraite de type texte complet

```powershell
$textInfo = New-TextExtractedInfo -Text "Voici un exemple de texte extrait d'un document." `
                                 -Language "fr" `
                                 -Source "document.txt" `
                                 -ExtractorName "FileTextExtractor" `
                                 -ProcessingState "Processed" `
                                 -ConfidenceScore 85
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type texte en spécifiant toutes les propriétés disponibles.

### Exemple 4 : Créer un objet d'information extraite de type texte et ajouter des métadonnées

```powershell
$textInfo = New-TextExtractedInfo -Text "Example text from a web page." -Language "en" -Source "webpage.html"
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "URL" -Value "https://example.com"
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "Title" -Value "Example Page"
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "CharacterCount" -Value $textInfo.Text.Length
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type texte, puis ajoute plusieurs métadonnées à l'aide de la fonction `Add-ExtractedInfoMetadata`.

## LIENS CONNEXES

- [New-ExtractedInfo](New-ExtractedInfo.md)
- [New-StructuredDataExtractedInfo](New-StructuredDataExtractedInfo.md)
- [New-MediaExtractedInfo](New-MediaExtractedInfo.md)
- [Copy-ExtractedInfo](Copy-ExtractedInfo.md)
- [Add-ExtractedInfoMetadata](Add-ExtractedInfoMetadata.md)
