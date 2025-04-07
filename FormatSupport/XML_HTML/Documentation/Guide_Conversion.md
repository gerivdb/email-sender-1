# Guide de conversion entre formats

Ce guide explique comment convertir entre les différents formats supportés : Roadmap (Markdown), XML, HTML et JSON.

## Conversion entre Roadmap et XML

### Roadmap vers XML

```powershell
# Convertir un fichier Roadmap en XML
ConvertFrom-RoadmapFileToXmlFile -RoadmapPath "roadmap.md" -XmlPath "roadmap.xml"

# Convertir une chaîne Roadmap en XML
$roadmapContent = Get-Content -Path "roadmap.md" -Raw
$xmlContent = ConvertFrom-RoadmapToXml -RoadmapContent $roadmapContent
```

### XML vers Roadmap

```powershell
# Convertir un fichier XML en Roadmap
ConvertFrom-XmlFileToRoadmapFile -XmlPath "roadmap.xml" -RoadmapPath "roadmap.md"

# Convertir une chaîne XML en Roadmap
$xmlContent = Get-Content -Path "roadmap.xml" -Raw
$roadmapContent = ConvertFrom-XmlToRoadmap -XmlContent $xmlContent
```

## Conversion entre XML et HTML

### XML vers HTML

```powershell
# Convertir un fichier XML en HTML
$xmlDoc = Import-XmlFile -FilePath "data.xml"
$htmlDoc = ConvertFrom-XmlToHtml -XmlDocument $xmlDoc
Export-HtmlFile -HtmlDocument $htmlDoc -FilePath "data.html"

# Utiliser la fonction de conversion de fichier
Convert-FormatFile -InputPath "data.xml" -OutputPath "data.html" -InputFormat "xml" -OutputFormat "html"
```

### HTML vers XML

```powershell
# Convertir un fichier HTML en XML
$htmlDoc = Import-HtmlFile -FilePath "page.html"
$xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $htmlDoc
$xmlDoc.Save("page.xml")

# Utiliser la fonction de conversion de fichier
Convert-FormatFile -InputPath "page.html" -OutputPath "page.xml" -InputFormat "html" -OutputFormat "xml"
```

## Conversion entre XML et JSON

### XML vers JSON

```powershell
# Convertir un document XML en JSON
$xmlDoc = Import-XmlFile -FilePath "data.xml"
$json = ConvertFrom-XmlToJson -XmlDocument $xmlDoc
$json | Out-File -FilePath "data.json" -Encoding UTF8
```

### JSON vers XML

```powershell
# Convertir une chaîne JSON en XML
$jsonString = Get-Content -Path "data.json" -Raw
$xmlDoc = ConvertFrom-JsonToXml -JsonString $jsonString
$xmlDoc.Save("data.xml")
```

## Conversion entre HTML et texte

### HTML vers texte

```powershell
# Convertir un document HTML en texte brut
$htmlDoc = Import-HtmlFile -FilePath "page.html"
$text = ConvertTo-PlainText -HtmlDocument $htmlDoc
$text | Out-File -FilePath "page.txt" -Encoding UTF8
```

## Utilisation de la fonction Convert-FormatFile

La fonction `Convert-FormatFile` permet de convertir facilement entre les différents formats supportés.

```powershell
# Convertir un fichier Roadmap en XML
Convert-FormatFile -InputPath "roadmap.md" -OutputPath "roadmap.xml" -InputFormat "roadmap" -OutputFormat "xml"

# Convertir un fichier XML en Roadmap
Convert-FormatFile -InputPath "roadmap.xml" -OutputPath "roadmap.md" -InputFormat "xml" -OutputFormat "roadmap"

# Convertir un fichier XML en HTML
Convert-FormatFile -InputPath "data.xml" -OutputPath "data.html" -InputFormat "xml" -OutputFormat "html"

# Convertir un fichier HTML en XML
Convert-FormatFile -InputPath "page.html" -OutputPath "page.xml" -InputFormat "html" -OutputFormat "xml"
```

## Paramètres de conversion

Vous pouvez personnaliser la conversion en fournissant des paramètres supplémentaires.

### Paramètres pour la conversion Roadmap vers XML

```powershell
$settings = @{
    IncludeMetadata = $true
    IncludeNotes = $true
    IndentXml = $true
    XmlEncoding = "UTF-8"
}

ConvertFrom-RoadmapToXml -RoadmapContent $roadmapContent -Settings $settings
```

### Paramètres pour la conversion XML vers Roadmap

```powershell
$settings = @{
    IncludeMetadata = $true
    IncludeNotes = $true
    IncludeOverview = $true
    MarkdownIndentation = "  "
}

ConvertFrom-XmlToRoadmap -XmlContent $xmlContent -Settings $settings
```

### Paramètres pour la conversion XML vers HTML

```powershell
$settings = @{
    IncludeStyles = $true
    IncludeJavaScript = $false
    HtmlEncoding = "UTF-8"
    AddCheckboxes = $true
}

ConvertFrom-XmlToHtml -XmlDocument $xmlDoc -Settings $settings
```

## Exemples pratiques

### Exemple 1 : Convertir une roadmap en XML puis en HTML

```powershell
# Convertir la roadmap en XML
ConvertFrom-RoadmapFileToXmlFile -RoadmapPath "roadmap.md" -XmlPath "roadmap.xml"

# Convertir le XML en HTML
$xmlDoc = Import-XmlFile -FilePath "roadmap.xml"
$htmlDoc = ConvertFrom-XmlToHtml -XmlDocument $xmlDoc
Export-HtmlFile -HtmlDocument $htmlDoc -FilePath "roadmap.html"

# Ouvrir le fichier HTML dans le navigateur
Start-Process "roadmap.html"
```

### Exemple 2 : Extraire le texte d'une page web et le convertir en XML

```powershell
# Importer le fichier HTML
$htmlDoc = Import-HtmlFile -FilePath "page.html"

# Extraire le texte
$text = ConvertTo-PlainText -HtmlDocument $htmlDoc

# Créer un document XML
$xmlDoc = New-Object System.Xml.XmlDocument
$root = $xmlDoc.CreateElement("content")
$xmlDoc.AppendChild($root) | Out-Null

# Ajouter le texte au document XML
$textElement = $xmlDoc.CreateElement("text")
$textElement.InnerText = $text
$root.AppendChild($textElement) | Out-Null

# Enregistrer le document XML
$xmlDoc.Save("page_text.xml")
```

### Exemple 3 : Convertir un fichier XML en JSON et vice versa

```powershell
# Convertir un fichier XML en JSON
$xmlDoc = Import-XmlFile -FilePath "data.xml"
$json = ConvertFrom-XmlToJson -XmlDocument $xmlDoc
$json | Out-File -FilePath "data.json" -Encoding UTF8

# Modifier le JSON
$jsonObj = $json | ConvertFrom-Json
$jsonObj.roadmap.title = "Nouveau titre"
$updatedJson = $jsonObj | ConvertTo-Json -Depth 10

# Convertir le JSON modifié en XML
$xmlDoc = ConvertFrom-JsonToXml -JsonString $updatedJson
$xmlDoc.Save("data_updated.xml")
```

## Dépannage

### Problèmes courants

#### Erreur lors de la conversion entre formats

Si vous rencontrez une erreur lors de la conversion entre formats, vérifiez que les fichiers source sont valides et correctement formatés.

```powershell
# Valider un fichier XML avant la conversion
$result = Test-XmlFile -XmlPath "roadmap.xml"
if (-not $result.IsValid) {
    Write-Host "Erreurs de validation XML :"
    $result.Errors | ForEach-Object { $_.ToString() }
}
```

#### Caractères spéciaux dans les fichiers

Si vous rencontrez des problèmes avec des caractères spéciaux lors de la conversion, assurez-vous que les fichiers sont encodés en UTF-8 :

```powershell
# Lire le contenu du fichier
$content = Get-Content -Path "file.xml" -Raw

# Enregistrer le fichier en UTF-8
Set-Content -Path "file.xml" -Value $content -Encoding UTF8
```

#### Perte de données lors de la conversion

Si vous constatez une perte de données lors de la conversion, vérifiez que les formats source et destination supportent les mêmes types de données. Certaines conversions peuvent entraîner une perte d'informations en raison des limitations des formats.

```powershell
# Utiliser des paramètres de conversion pour préserver les données
$settings = @{
    IncludeMetadata = $true
    IncludeNotes = $true
    PreserveFormatting = $true
}

ConvertFrom-RoadmapToXml -RoadmapContent $roadmapContent -Settings $settings
```
