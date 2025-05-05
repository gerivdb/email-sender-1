# Get-ExtractedInfoSummary

## SYNOPSIS
Génère un résumé des propriétés et métadonnées d'un objet d'information extraite.

## SYNTAXE

```powershell
Get-ExtractedInfoSummary
    -Info <Hashtable>
    [-Format <String>]
    [-IncludeMetadata]
    [-IncludeContent]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `Get-ExtractedInfoSummary` génère un résumé des propriétés et, optionnellement, des métadonnées d'un objet d'information extraite. Ce résumé peut être formaté en texte simple, en liste ou en table, selon les besoins.

Cette fonction est particulièrement utile pour obtenir une vue d'ensemble rapide d'un objet d'information extraite, pour le débogage ou pour l'affichage dans des rapports.

## PARAMÈTRES

### -Info
Spécifie l'objet d'information extraite dont on souhaite générer un résumé. Ce paramètre est obligatoire.

```yaml
Type: Hashtable
Required: True
```

### -Format
Spécifie le format du résumé. Les valeurs valides sont :
- "Text" : Format texte simple avec une propriété par ligne
- "List" : Format liste avec puces
- "Table" : Format tableau avec deux colonnes (propriété et valeur)

```yaml
Type: String
Default: "Text"
ValidateSet: "Text", "List", "Table"
```

### -IncludeMetadata
Indique si les métadonnées doivent être incluses dans le résumé.

```yaml
Type: SwitchParameter
Default: False
```

### -IncludeContent
Indique si le contenu spécifique au type (texte, données structurées, chemin média) doit être inclus dans le résumé.

```yaml
Type: SwitchParameter
Default: False
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
### System.Collections.Hashtable
Vous pouvez transmettre un objet d'information extraite via le pipeline.

## SORTIES
### System.String
Retourne une chaîne de caractères contenant le résumé formaté de l'objet d'information extraite.

## NOTES
- Cette fonction ne modifie pas l'objet d'information extraite original.
- Pour les objets de type TextExtractedInfo, le contenu textuel peut être tronqué si trop long.
- Pour les objets de type StructuredDataExtractedInfo, les données structurées sont converties en JSON pour l'affichage.
- Pour les objets de type MediaExtractedInfo, le chemin du fichier média est inclus dans le résumé.
- Les métadonnées complexes (hashtables, tableaux) sont converties en JSON pour l'affichage.

## EXEMPLES

### Exemple 1 : Générer un résumé simple d'un objet d'information extraite
```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor" -ProcessingState "Processed" -ConfidenceScore 85
$summary = Get-ExtractedInfoSummary -Info $info
Write-Host $summary
```

Cet exemple génère un résumé au format texte par défaut d'un objet d'information extraite de base.

### Exemple 2 : Générer un résumé au format liste avec métadonnées
```powershell
$info = New-TextExtractedInfo -Source "article.html" -Text "Ceci est un exemple de texte extrait d'un article." -Language "fr"
$info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
    URL = "https://example.com/article"
    Author = "John Doe"
    PublicationDate = Get-Date -Year 2023 -Month 5 -Day 15
}

$summary = Get-ExtractedInfoSummary -Info $info -Format "List" -IncludeMetadata
Write-Host $summary
```

Cet exemple génère un résumé au format liste d'un objet d'information extraite de type texte, en incluant ses métadonnées.

### Exemple 3 : Générer un résumé au format tableau avec contenu
```powershell
$data = @{
    Name = "John Doe"
    Age = 30
    Email = "john.doe@example.com"
}
$info = New-StructuredDataExtractedInfo -Source "api.example.com" -Data $data -DataFormat "JSON"

$summary = Get-ExtractedInfoSummary -Info $info -Format "Table" -IncludeContent
Write-Host $summary
```

Cet exemple génère un résumé au format tableau d'un objet d'information extraite de type données structurées, en incluant le contenu des données.

### Exemple 4 : Générer un résumé complet avec métadonnées et contenu
```powershell
$info = New-MediaExtractedInfo -MediaPath "C:\Images\photo.jpg" -MediaType "Image" -MediaSize 1048576
$info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
    Resolution = "1920x1080"
    Format = "JPEG"
    Camera = "Canon EOS R5"
}

$summary = Get-ExtractedInfoSummary -Info $info -Format "Text" -IncludeMetadata -IncludeContent
Write-Host $summary
```

Cet exemple génère un résumé complet d'un objet d'information extraite de type média, en incluant à la fois les métadonnées et le contenu.

### Exemple 5 : Utiliser Get-ExtractedInfoSummary avec le pipeline
```powershell
$infos = @(
    (New-ExtractedInfo -Source "source1" -ProcessingState "Raw"),
    (New-TextExtractedInfo -Source "source2" -Text "Exemple de texte" -ProcessingState "Processed")
)

$infos | ForEach-Object {
    $summary = Get-ExtractedInfoSummary -Info $_ -Format "List"
    Write-Host "Résumé de l'objet de type $($_.Type):"
    Write-Host $summary
    Write-Host "------------------------"
}
```

Cet exemple utilise le pipeline pour générer des résumés au format liste pour plusieurs objets d'information extraite.

### Exemple 6 : Générer un résumé pour un rapport
```powershell
$info = New-TextExtractedInfo -Source "rapport.docx" -Text "Contenu du rapport..." -Language "fr"
$info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
    Title = "Rapport annuel"
    Author = "Département Finance"
    CreationDate = Get-Date -Year 2023 -Month 12 -Day 31
    Status = "Final"
}

$reportHeader = "=== RÉSUMÉ DU DOCUMENT ==="
$reportFooter = "=========================="
$reportContent = Get-ExtractedInfoSummary -Info $info -Format "Text" -IncludeMetadata

$report = $reportHeader + "`n" + $reportContent + "`n" + $reportFooter
Write-Host $report
```

Cet exemple utilise la fonction pour générer un résumé formaté qui est ensuite intégré dans un rapport plus large.

## LIENS CONNEXES
- [Get-ExtractedInfoMetadata](Get-ExtractedInfoMetadata.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
- [New-TextExtractedInfo](New-TextExtractedInfo.md)
- [New-StructuredDataExtractedInfo](New-StructuredDataExtractedInfo.md)
- [New-MediaExtractedInfo](New-MediaExtractedInfo.md)
