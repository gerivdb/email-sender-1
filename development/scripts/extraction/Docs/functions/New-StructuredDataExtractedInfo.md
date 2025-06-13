# New-StructuredDataExtractedInfo

## SYNOPSIS

Crée un nouvel objet d'information extraite contenant des données structurées.

## SYNTAXE

```powershell
New-StructuredDataExtractedInfo
    -Data <Object>
    [-DataFormat <String>]
    [-Source <String>]
    [-ExtractorName <String>]
    [-ProcessingState <String>]
    [-ConfidenceScore <Int32>]
    [<CommonParameters>]
```plaintext
## DESCRIPTION

La fonction `New-StructuredDataExtractedInfo` crée un nouvel objet d'information extraite spécialisé pour les données structurées comme des objets JSON, XML, ou des structures de données hiérarchiques. Cet objet étend le type de base `ExtractedInfo` avec des propriétés spécifiques aux données structurées, comme les données elles-mêmes et leur format.

Cette fonction est particulièrement utile pour stocker et manipuler des données structurées extraites de diverses sources comme des API, des fichiers de configuration, ou des bases de données.

## PARAMÈTRES

### -Data

Spécifie les données structurées extraites. Ce paramètre est obligatoire et peut être une hashtable, un tableau, ou tout autre objet PowerShell.

```yaml
Type: Object
Required: True
```plaintext
### -DataFormat

Spécifie le format des données structurées (par exemple, "JSON", "XML", "CSV", "PSObject").

```yaml
Type: String
Default: "JSON"
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
Default: "StructuredDataExtractor"
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

Retourne une hashtable PowerShell représentant l'objet d'information extraite de type données structurées avec les propriétés suivantes :

- **_Type** : Type de l'information extraite (toujours "StructuredDataExtractedInfo")
- **Id** : Identifiant unique (GUID) généré automatiquement
- **Source** : Source de l'information
- **ExtractorName** : Nom de l'extracteur utilisé
- **ExtractionDate** : Date et heure de l'extraction (définie automatiquement)
- **LastModifiedDate** : Date et heure de la dernière modification (définie automatiquement)
- **ProcessingState** : État de traitement actuel
- **ConfidenceScore** : Score de confiance (0-100)
- **Metadata** : Hashtable vide pour stocker des métadonnées additionnelles
- **Data** : Données structurées extraites
- **DataFormat** : Format des données structurées

## NOTES

- L'identifiant (Id) est généré automatiquement sous forme de GUID pour garantir l'unicité.
- Les dates d'extraction et de dernière modification sont définies automatiquement à la date et l'heure actuelles.
- La hashtable Metadata est initialisée vide et peut être utilisée pour stocker des informations supplémentaires.
- Le paramètre Data est obligatoire car il constitue l'information principale de ce type d'objet.
- Lors de la sérialisation, les données structurées sont converties en JSON, ce qui peut entraîner des pertes d'information pour certains types d'objets complexes.

## EXEMPLES

### Exemple 1 : Créer un objet d'information extraite avec des données structurées simples

```powershell
$data = @{
    Name = "John Doe"
    Age = 30
    Email = "john.doe@example.com"
}
$structuredInfo = New-StructuredDataExtractedInfo -Data $data
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type données structurées avec une hashtable simple et les autres valeurs par défaut.

### Exemple 2 : Créer un objet d'information extraite avec des données structurées complexes

```powershell
$data = @{
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
    Active = $true
}
$structuredInfo = New-StructuredDataExtractedInfo -Data $data -DataFormat "JSON" -Source "api.example.com" -ConfidenceScore 90
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type données structurées avec une structure de données complexe, en spécifiant le format, la source et le score de confiance.

### Exemple 3 : Créer un objet d'information extraite à partir de données JSON

```powershell
$jsonString = '{"name":"John Doe","age":30,"skills":["Programming","Design","Communication"]}'
$data = ConvertFrom-Json -InputObject $jsonString
$structuredInfo = New-StructuredDataExtractedInfo -Data $data -DataFormat "JSON" -Source "config.json" -ExtractorName "JsonFileExtractor"
```plaintext
Cet exemple convertit d'abord une chaîne JSON en objet PowerShell, puis crée un nouvel objet d'information extraite de type données structurées à partir de cet objet.

### Exemple 4 : Créer un objet d'information extraite et ajouter des métadonnées

```powershell
$data = Import-Csv -Path "data.csv"
$structuredInfo = New-StructuredDataExtractedInfo -Data $data -DataFormat "CSV" -Source "data.csv"
$structuredInfo = Add-ExtractedInfoMetadata -Info $structuredInfo -Key "RowCount" -Value $data.Count
$structuredInfo = Add-ExtractedInfoMetadata -Info $structuredInfo -Key "ColumnNames" -Value ($data[0].PSObject.Properties.Name)
```plaintext
Cet exemple crée un nouvel objet d'information extraite de type données structurées à partir d'un fichier CSV, puis ajoute des métadonnées sur le nombre de lignes et les noms de colonnes.

## LIENS CONNEXES

- [New-ExtractedInfo](New-ExtractedInfo.md)
- [New-TextExtractedInfo](New-TextExtractedInfo.md)
- [New-MediaExtractedInfo](New-MediaExtractedInfo.md)
- [Copy-ExtractedInfo](Copy-ExtractedInfo.md)
- [Add-ExtractedInfoMetadata](Add-ExtractedInfoMetadata.md)
