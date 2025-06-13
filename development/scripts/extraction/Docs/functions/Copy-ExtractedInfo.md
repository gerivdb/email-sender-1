# Copy-ExtractedInfo

## SYNOPSIS

Crée une copie d'un objet d'information extraite avec possibilité de modifier certaines propriétés.

## SYNTAXE

```powershell
Copy-ExtractedInfo
    -Info <Hashtable>
    [-NewId]
    [-Source <String>]
    [-ExtractorName <String>]
    [-ProcessingState <String>]
    [-ConfidenceScore <Int32>]
    [-UpdateLastModifiedDate]
    [<CommonParameters>]
```plaintext
## DESCRIPTION

La fonction `Copy-ExtractedInfo` crée une copie profonde d'un objet d'information extraite existant, tout en permettant de modifier certaines propriétés spécifiques. Cette fonction préserve le type spécifique de l'objet d'origine (ExtractedInfo, TextExtractedInfo, StructuredDataExtractedInfo, MediaExtractedInfo) ainsi que toutes ses propriétés spécifiques.

Cette fonction est particulièrement utile pour créer des versions modifiées d'objets d'information extraite sans altérer les objets originaux, ce qui permet de conserver un historique des modifications ou de créer des variantes d'une même information.

## PARAMÈTRES

### -Info

Spécifie l'objet d'information extraite à copier. Ce paramètre est obligatoire.

```yaml
Type: Hashtable
Required: True
```plaintext
### -NewId

Indique si un nouvel identifiant (GUID) doit être généré pour la copie. Par défaut, l'identifiant de l'objet original est conservé.

```yaml
Type: SwitchParameter
Default: False
```plaintext
### -Source

Spécifie une nouvelle valeur pour la propriété Source de la copie.

```yaml
Type: String
Default: Valeur de l'objet original
```plaintext
### -ExtractorName

Spécifie une nouvelle valeur pour la propriété ExtractorName de la copie.

```yaml
Type: String
Default: Valeur de l'objet original
```plaintext
### -ProcessingState

Spécifie une nouvelle valeur pour la propriété ProcessingState de la copie.
Les valeurs valides sont : "Raw", "Processed", "Validated", "Error".

```yaml
Type: String
Default: Valeur de l'objet original
```plaintext
### -ConfidenceScore

Spécifie une nouvelle valeur pour la propriété ConfidenceScore de la copie.

```yaml
Type: Int32
Default: Valeur de l'objet original
```plaintext
### -UpdateLastModifiedDate

Indique si la propriété LastModifiedDate doit être mise à jour avec la date et l'heure actuelles.

```yaml
Type: SwitchParameter
Default: True
```plaintext
### <CommonParameters>

Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES

### System.Collections.Hashtable

Vous pouvez transmettre un objet d'information extraite à copier via le pipeline.

## SORTIES

Retourne une hashtable PowerShell représentant la copie de l'objet d'information extraite avec les propriétés modifiées si spécifiées.

## NOTES

- Par défaut, l'identifiant (Id) de l'objet original est conservé, ce qui signifie que la copie est considérée comme une version mise à jour du même objet. Utilisez le paramètre -NewId pour créer un objet distinct avec son propre identifiant.
- La date d'extraction (ExtractionDate) est toujours conservée de l'objet original.
- Par défaut, la date de dernière modification (LastModifiedDate) est mise à jour à la date et l'heure actuelles. Utilisez -UpdateLastModifiedDate:$false pour conserver la date de l'objet original.
- Les métadonnées sont copiées intégralement de l'objet original.
- Pour les types spécialisés (TextExtractedInfo, StructuredDataExtractedInfo, MediaExtractedInfo), toutes les propriétés spécifiques sont également copiées.
- Cette fonction effectue une copie profonde des objets complexes comme les hashtables et les tableaux pour éviter les références partagées.

## EXEMPLES

### Exemple 1 : Créer une copie exacte d'un objet d'information extraite

```powershell
$originalInfo = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$copiedInfo = Copy-ExtractedInfo -Info $originalInfo
```plaintext
Cet exemple crée une copie de l'objet d'information extraite avec le même identifiant mais une date de dernière modification mise à jour.

### Exemple 2 : Créer une copie avec un nouvel identifiant

```powershell
$originalInfo = New-TextExtractedInfo -Source "document.txt" -Text "Texte original"
$copiedInfo = Copy-ExtractedInfo -Info $originalInfo -NewId
```plaintext
Cet exemple crée une copie de l'objet d'information extraite de type texte avec un nouvel identifiant, ce qui en fait un objet distinct de l'original.

### Exemple 3 : Créer une copie avec un état de traitement modifié

```powershell
$originalInfo = New-ExtractedInfo -Source "api.example.com" -ProcessingState "Raw"
$processedInfo = Copy-ExtractedInfo -Info $originalInfo -ProcessingState "Processed" -ConfidenceScore 85
```plaintext
Cet exemple crée une copie de l'objet d'information extraite en modifiant son état de traitement de "Raw" à "Processed" et en augmentant son score de confiance.

### Exemple 4 : Créer une copie d'un objet de type StructuredDataExtractedInfo

```powershell
$originalData = @{
    Name = "John Doe"
    Age = 30
}
$originalInfo = New-StructuredDataExtractedInfo -Data $originalData -Source "database"

# Modifier les données

$updatedData = $originalData.Clone()
$updatedData.Age = 31
$updatedData.Status = "Active"

# Créer une copie avec les données modifiées

$updatedInfo = Copy-ExtractedInfo -Info $originalInfo
$updatedInfo.Data = $updatedData
$updatedInfo.ProcessingState = "Validated"
```plaintext
Cet exemple crée une copie d'un objet d'information extraite de type données structurées, puis modifie manuellement les données après la copie.

### Exemple 5 : Utiliser Copy-ExtractedInfo avec le pipeline

```powershell
$infos = @(
    (New-ExtractedInfo -Source "source1"),
    (New-ExtractedInfo -Source "source2"),
    (New-ExtractedInfo -Source "source3")
)

$processedInfos = $infos | Copy-ExtractedInfo -ProcessingState "Processed" -ConfidenceScore 80
```plaintext
Cet exemple utilise le pipeline pour créer des copies de plusieurs objets d'information extraite, en modifiant l'état de traitement et le score de confiance pour tous.

## LIENS CONNEXES

- [New-ExtractedInfo](New-ExtractedInfo.md)
- [New-TextExtractedInfo](New-TextExtractedInfo.md)
- [New-StructuredDataExtractedInfo](New-StructuredDataExtractedInfo.md)
- [New-MediaExtractedInfo](New-MediaExtractedInfo.md)
- [Add-ExtractedInfoMetadata](Add-ExtractedInfoMetadata.md)
