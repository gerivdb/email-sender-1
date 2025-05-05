# New-ExtractedInfo

## SYNOPSIS
Crée un nouvel objet d'information extraite de base.

## SYNTAXE

```powershell
New-ExtractedInfo
    [-Source <String>]
    [-ExtractorName <String>]
    [-ProcessingState <String>]
    [-ConfidenceScore <Int32>]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `New-ExtractedInfo` crée un nouvel objet d'information extraite de base qui peut être utilisé pour stocker des informations extraites de diverses sources. Cet objet contient les propriétés fondamentales communes à tous les types d'informations extraites.

L'objet créé est une hashtable PowerShell avec des propriétés prédéfinies, ce qui permet une manipulation flexible tout en maintenant une structure cohérente.

## PARAMÈTRES

### -Source
Spécifie la source de l'information extraite (par exemple, un nom de fichier, une URL, ou une description de la source).

```yaml
Type: String
Default: "Unknown"
```

### -ExtractorName
Spécifie le nom de l'extracteur utilisé pour obtenir cette information.

```yaml
Type: String
Default: "GenericExtractor"
```

### -ProcessingState
Spécifie l'état de traitement actuel de l'information extraite.
Les valeurs valides sont : "Raw", "Processed", "Validated", "Error".

```yaml
Type: String
Default: "Raw"
```

### -ConfidenceScore
Spécifie le score de confiance associé à l'information extraite, sur une échelle de 0 à 100.

```yaml
Type: Int32
Default: 50
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
Aucune. Cette fonction ne prend pas d'entrée depuis le pipeline.

## SORTIES
Retourne une hashtable PowerShell représentant l'objet d'information extraite avec les propriétés suivantes :

- **_Type** : Type de l'information extraite (toujours "ExtractedInfo" pour le type de base)
- **Id** : Identifiant unique (GUID) généré automatiquement
- **Source** : Source de l'information
- **ExtractorName** : Nom de l'extracteur utilisé
- **ExtractionDate** : Date et heure de l'extraction (définie automatiquement)
- **LastModifiedDate** : Date et heure de la dernière modification (définie automatiquement)
- **ProcessingState** : État de traitement actuel
- **ConfidenceScore** : Score de confiance (0-100)
- **Metadata** : Hashtable vide pour stocker des métadonnées additionnelles

## NOTES
- L'identifiant (Id) est généré automatiquement sous forme de GUID pour garantir l'unicité.
- Les dates d'extraction et de dernière modification sont définies automatiquement à la date et l'heure actuelles.
- La hashtable Metadata est initialisée vide et peut être utilisée pour stocker des informations supplémentaires.

## EXEMPLES

### Exemple 1 : Créer un objet d'information extraite de base avec les valeurs par défaut
```powershell
$info = New-ExtractedInfo
```

Cet exemple crée un nouvel objet d'information extraite avec toutes les valeurs par défaut.

### Exemple 2 : Créer un objet d'information extraite avec des valeurs spécifiques
```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor" -ProcessingState "Raw" -ConfidenceScore 75
```

Cet exemple crée un nouvel objet d'information extraite en spécifiant la source, le nom de l'extracteur, l'état de traitement et le score de confiance.

### Exemple 3 : Créer un objet d'information extraite et ajouter des métadonnées
```powershell
$info = New-ExtractedInfo -Source "webpage.html" -ExtractorName "WebExtractor"
$info = Add-ExtractedInfoMetadata -Info $info -Key "URL" -Value "https://example.com"
$info = Add-ExtractedInfoMetadata -Info $info -Key "Title" -Value "Example Page"
```

Cet exemple crée un nouvel objet d'information extraite, puis ajoute des métadonnées à l'aide de la fonction `Add-ExtractedInfoMetadata`.

## LIENS CONNEXES
- [New-TextExtractedInfo](New-TextExtractedInfo.md)
- [New-StructuredDataExtractedInfo](New-StructuredDataExtractedInfo.md)
- [New-MediaExtractedInfo](New-MediaExtractedInfo.md)
- [Copy-ExtractedInfo](Copy-ExtractedInfo.md)
- [Add-ExtractedInfoMetadata](Add-ExtractedInfoMetadata.md)
