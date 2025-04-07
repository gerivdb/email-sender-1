# Exemples de formats XML et HTML

Ce dossier contient des exemples de fichiers XML et HTML pour illustrer les fonctionnalités de conversion et d'analyse.

## Fichiers d'exemple

### example-roadmap.xml

Un exemple de roadmap au format XML. Ce fichier illustre la structure XML utilisée pour représenter une roadmap avec des sections, des phases, des tâches et des sous-tâches.

Pour convertir ce fichier en format Roadmap (Markdown) :

```powershell
ConvertFrom-XmlFileToRoadmapFile -XmlPath "example-roadmap.xml" -RoadmapPath "example-roadmap.md"
```

Pour analyser la structure de ce fichier :

```powershell
Get-XmlStructureReportFromFile -XmlPath "example-roadmap.xml" -OutputPath "example-roadmap-structure.html" -AsHtml
```

### example-roadmap.html

Un exemple de roadmap au format HTML. Ce fichier illustre la représentation HTML d'une roadmap avec des styles CSS pour une meilleure présentation.

Pour convertir ce fichier en format XML :

```powershell
$htmlDoc = Import-HtmlFile -FilePath "example-roadmap.html"
$xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $htmlDoc
$xmlDoc.Save("example-roadmap-from-html.xml")
```

Pour extraire le texte de ce fichier :

```powershell
$htmlDoc = Import-HtmlFile -FilePath "example-roadmap.html"
$text = ConvertTo-PlainText -HtmlDocument $htmlDoc
$text | Out-File -FilePath "example-roadmap-text.txt" -Encoding UTF8
```

## Utilisation des exemples

Ces exemples peuvent être utilisés pour tester les fonctionnalités de conversion et d'analyse des formats XML et HTML. Ils illustrent également la structure attendue pour ces formats.

Pour afficher la structure d'un fichier XML :

```powershell
Show-XmlTree -XmlPath "example-roadmap.xml"
```

Pour afficher un fichier XML formaté :

```powershell
Show-XmlFormatted -XmlPath "example-roadmap.xml"
```

Pour afficher la structure d'un fichier HTML :

```powershell
Show-HtmlStructure -HtmlPath "example-roadmap.html"
```

## Conversion entre formats

Pour convertir entre les différents formats :

```powershell
# XML vers HTML
Convert-FormatFile -InputPath "example-roadmap.xml" -OutputPath "example-roadmap-from-xml.html" -InputFormat "xml" -OutputFormat "html"

# HTML vers XML
Convert-FormatFile -InputPath "example-roadmap.html" -OutputPath "example-roadmap-from-html.xml" -InputFormat "html" -OutputFormat "xml"

# XML vers Roadmap (Markdown)
Convert-FormatFile -InputPath "example-roadmap.xml" -OutputPath "example-roadmap.md" -InputFormat "xml" -OutputFormat "roadmap"
```
