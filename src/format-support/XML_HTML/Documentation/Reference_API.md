# Référence API - Support des formats XML et HTML

Ce document fournit une référence complète de toutes les fonctions disponibles dans les modules de support XML et HTML.

## Table des matières

1. [Module RoadmapXmlConverter](#module-roadmapxmlconverter)
2. [Module XmlElementDetector](#module-xmlelementdetector)
3. [Module XmlValidator](#module-xmlvalidator)
4. [Module HTMLFormatHandler](#module-htmlformathandler)
5. [Module FormatConverter](#module-formatconverter)
6. [Module XmlSupport](#module-xmlsupport)

## Module RoadmapXmlConverter

Ce module fournit des fonctions pour convertir entre le format Roadmap (Markdown) et XML.

### ConvertFrom-RoadmapToXml

Convertit une chaîne Roadmap en XML.

```powershell
ConvertFrom-RoadmapToXml -RoadmapContent <string> [-Settings <hashtable>]
```

#### Paramètres

- **RoadmapContent** : Le contenu de la roadmap au format Markdown.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la conversion.

#### Exemple

```powershell
$roadmapContent = Get-Content -Path "roadmap.md" -Raw
$xmlContent = ConvertFrom-RoadmapToXml -RoadmapContent $roadmapContent
```

### ConvertFrom-XmlToRoadmap

Convertit une chaîne XML en Roadmap.

```powershell
ConvertFrom-XmlToRoadmap -XmlContent <string> [-Settings <hashtable>]
```

#### Paramètres

- **XmlContent** : Le contenu XML à convertir.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la conversion.

#### Exemple

```powershell
$xmlContent = Get-Content -Path "roadmap.xml" -Raw
$roadmapContent = ConvertFrom-XmlToRoadmap -XmlContent $xmlContent
```

### ConvertFrom-RoadmapFileToXmlFile

Convertit un fichier Roadmap en fichier XML.

```powershell
ConvertFrom-RoadmapFileToXmlFile -RoadmapPath <string> -XmlPath <string> [-Settings <hashtable>]
```

#### Paramètres

- **RoadmapPath** : Le chemin du fichier Roadmap à convertir.
- **XmlPath** : Le chemin du fichier XML à créer.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la conversion.

#### Exemple

```powershell
ConvertFrom-RoadmapFileToXmlFile -RoadmapPath "roadmap.md" -XmlPath "roadmap.xml"
```

### ConvertFrom-XmlFileToRoadmapFile

Convertit un fichier XML en fichier Roadmap.

```powershell
ConvertFrom-XmlFileToRoadmapFile -XmlPath <string> -RoadmapPath <string> [-Settings <hashtable>]
```

#### Paramètres

- **XmlPath** : Le chemin du fichier XML à convertir.
- **RoadmapPath** : Le chemin du fichier Roadmap à créer.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la conversion.

#### Exemple

```powershell
ConvertFrom-XmlFileToRoadmapFile -XmlPath "roadmap.xml" -RoadmapPath "roadmap.md"
```

## Module XmlElementDetector

Ce module fournit des fonctions pour détecter et analyser les éléments XML.

### Get-XmlElements

Détecte les éléments XML dans une chaîne.

```powershell
Get-XmlElements -XmlContent <string> [-Settings <hashtable>]
```

#### Paramètres

- **XmlContent** : Le contenu XML à analyser.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la détection.

#### Exemple

```powershell
$xmlContent = Get-Content -Path "roadmap.xml" -Raw
$elements = Get-XmlElements -XmlContent $xmlContent
```

### Get-XmlElementsFromFile

Détecte les éléments XML dans un fichier.

```powershell
Get-XmlElementsFromFile -XmlPath <string> [-Settings <hashtable>]
```

#### Paramètres

- **XmlPath** : Le chemin du fichier XML à analyser.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la détection.

#### Exemple

```powershell
$elements = Get-XmlElementsFromFile -XmlPath "roadmap.xml"
```

### Get-XmlStructureReport

Génère un rapport sur la structure XML.

```powershell
Get-XmlStructureReport -XmlContent <string> [-Settings <hashtable>] [-AsHtml]
```

#### Paramètres

- **XmlContent** : Le contenu XML à analyser.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser le rapport.
- **AsHtml** : (Optionnel) Génère le rapport au format HTML.

#### Exemple

```powershell
$xmlContent = Get-Content -Path "roadmap.xml" -Raw
$report = Get-XmlStructureReport -XmlContent $xmlContent -AsHtml
```

### Get-XmlStructureReportFromFile

Génère un rapport sur la structure XML d'un fichier.

```powershell
Get-XmlStructureReportFromFile -XmlPath <string> [-Settings <hashtable>] [-AsHtml] [-OutputPath <string>]
```

#### Paramètres

- **XmlPath** : Le chemin du fichier XML à analyser.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser le rapport.
- **AsHtml** : (Optionnel) Génère le rapport au format HTML.
- **OutputPath** : (Optionnel) Le chemin du fichier de sortie pour le rapport.

#### Exemple

```powershell
$report = Get-XmlStructureReportFromFile -XmlPath "roadmap.xml" -OutputPath "report.html" -AsHtml
```

### ConvertTo-RoadmapMapping

Mappe les éléments XML vers la structure de roadmap.

```powershell
ConvertTo-RoadmapMapping -XmlContent <string>
```

#### Paramètres

- **XmlContent** : Le contenu XML à mapper.

#### Exemple

```powershell
$xmlContent = Get-Content -Path "roadmap.xml" -Raw
$mapping = ConvertTo-RoadmapMapping -XmlContent $xmlContent
```

## Module XmlValidator

Ce module fournit des fonctions pour valider les fichiers XML.

### Test-XmlContent

Valide une chaîne XML.

```powershell
Test-XmlContent -XmlContent <string> [-Settings <hashtable>]
```

#### Paramètres

- **XmlContent** : Le contenu XML à valider.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la validation.

#### Exemple

```powershell
$xmlContent = Get-Content -Path "roadmap.xml" -Raw
$result = Test-XmlContent -XmlContent $xmlContent
```

### Test-XmlFile

Valide un fichier XML.

```powershell
Test-XmlFile -XmlPath <string> [-Settings <hashtable>]
```

#### Paramètres

- **XmlPath** : Le chemin du fichier XML à valider.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la validation.

#### Exemple

```powershell
$result = Test-XmlFile -XmlPath "roadmap.xml"
```

### Get-XmlValidationReport

Génère un rapport de validation XML.

```powershell
Get-XmlValidationReport -ValidationResult <XmlValidationResult> [-AsHtml]
```

#### Paramètres

- **ValidationResult** : Le résultat de la validation XML.
- **AsHtml** : (Optionnel) Génère le rapport au format HTML.

#### Exemple

```powershell
$result = Test-XmlFile -XmlPath "roadmap.xml"
$report = Get-XmlValidationReport -ValidationResult $result -AsHtml
```

### Test-XmlFileWithReport

Valide un fichier XML et génère un rapport.

```powershell
Test-XmlFileWithReport -XmlPath <string> [-Settings <hashtable>] [-AsHtml] [-OutputPath <string>]
```

#### Paramètres

- **XmlPath** : Le chemin du fichier XML à valider.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la validation.
- **AsHtml** : (Optionnel) Génère le rapport au format HTML.
- **OutputPath** : (Optionnel) Le chemin du fichier de sortie pour le rapport.

#### Exemple

```powershell
$result = Test-XmlFileWithReport -XmlPath "roadmap.xml" -OutputPath "validation.html" -AsHtml
```

### Test-XmlFileAgainstSchema

Valide un fichier XML par rapport à un schéma XSD.

```powershell
Test-XmlFileAgainstSchema -XmlPath <string> -SchemaPath <string> [-Settings <hashtable>]
```

#### Paramètres

- **XmlPath** : Le chemin du fichier XML à valider.
- **SchemaPath** : Le chemin du fichier de schéma XSD.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la validation.

#### Exemple

```powershell
$result = Test-XmlFileAgainstSchema -XmlPath "roadmap.xml" -SchemaPath "roadmap.xsd"
```

### New-XsdSchemaFromXml

Génère un schéma XSD à partir d'un fichier XML.

```powershell
New-XsdSchemaFromXml -XmlPath <string> -SchemaPath <string>
```

#### Paramètres

- **XmlPath** : Le chemin du fichier XML à analyser.
- **SchemaPath** : Le chemin du fichier de schéma XSD à créer.

#### Exemple

```powershell
New-XsdSchemaFromXml -XmlPath "roadmap.xml" -SchemaPath "roadmap.xsd"
```

## Module HTMLFormatHandler

Ce module fournit des fonctions pour travailler avec les fichiers HTML.

### ConvertFrom-Html

Convertit une chaîne HTML en document HTML.

```powershell
ConvertFrom-Html -HtmlString <string> [-Sanitize]
```

#### Paramètres

- **HtmlString** : La chaîne HTML à convertir.
- **Sanitize** : (Optionnel) Sanitise le HTML pour supprimer les éléments dangereux.

#### Exemple

```powershell
$htmlString = Get-Content -Path "page.html" -Raw
$htmlDoc = ConvertFrom-Html -HtmlString $htmlString -Sanitize
```

### Import-HtmlFile

Importe un fichier HTML.

```powershell
Import-HtmlFile -FilePath <string> [-Sanitize]
```

#### Paramètres

- **FilePath** : Le chemin du fichier HTML à importer.
- **Sanitize** : (Optionnel) Sanitise le HTML pour supprimer les éléments dangereux.

#### Exemple

```powershell
$htmlDoc = Import-HtmlFile -FilePath "page.html" -Sanitize
```

### Export-HtmlFile

Exporte un document HTML vers un fichier.

```powershell
Export-HtmlFile -HtmlDocument <HtmlDocument> -FilePath <string>
```

#### Paramètres

- **HtmlDocument** : Le document HTML à exporter.
- **FilePath** : Le chemin du fichier HTML à créer.

#### Exemple

```powershell
Export-HtmlFile -HtmlDocument $htmlDoc -FilePath "page.html"
```

### Invoke-CssQuery

Exécute une requête CSS sur un document HTML.

```powershell
Invoke-CssQuery -HtmlDocument <HtmlDocument> -CssSelector <string>
```

#### Paramètres

- **HtmlDocument** : Le document HTML à interroger.
- **CssSelector** : Le sélecteur CSS à utiliser.

#### Exemple

```powershell
$elements = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector "h1, h2, h3"
```

### ConvertTo-PlainText

Convertit un document HTML en texte brut.

```powershell
ConvertTo-PlainText -HtmlDocument <HtmlDocument>
```

#### Paramètres

- **HtmlDocument** : Le document HTML à convertir.

#### Exemple

```powershell
$text = ConvertTo-PlainText -HtmlDocument $htmlDoc
```

## Module FormatConverter

Ce module fournit des fonctions pour convertir entre différents formats.

### ConvertFrom-XmlToHtml

Convertit un document XML en HTML.

```powershell
ConvertFrom-XmlToHtml -XmlDocument <XmlDocument> [-Settings <hashtable>]
```

#### Paramètres

- **XmlDocument** : Le document XML à convertir.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la conversion.

#### Exemple

```powershell
$xmlDoc = Import-XmlFile -FilePath "data.xml"
$htmlDoc = ConvertFrom-XmlToHtml -XmlDocument $xmlDoc
```

### ConvertFrom-HtmlToXml

Convertit un document HTML en XML.

```powershell
ConvertFrom-HtmlToXml -HtmlDocument <HtmlDocument> [-Settings <hashtable>]
```

#### Paramètres

- **HtmlDocument** : Le document HTML à convertir.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la conversion.

#### Exemple

```powershell
$htmlDoc = Import-HtmlFile -FilePath "page.html"
$xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $htmlDoc
```

### ConvertFrom-XmlToJson

Convertit un document XML en JSON.

```powershell
ConvertFrom-XmlToJson -XmlDocument <XmlDocument> [-Settings <hashtable>]
```

#### Paramètres

- **XmlDocument** : Le document XML à convertir.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la conversion.

#### Exemple

```powershell
$xmlDoc = Import-XmlFile -FilePath "data.xml"
$json = ConvertFrom-XmlToJson -XmlDocument $xmlDoc
```

### ConvertFrom-JsonToXml

Convertit une chaîne JSON en XML.

```powershell
ConvertFrom-JsonToXml -JsonString <string> [-Settings <hashtable>]
```

#### Paramètres

- **JsonString** : La chaîne JSON à convertir.
- **Settings** : (Optionnel) Un hashtable de paramètres pour personnaliser la conversion.

#### Exemple

```powershell
$jsonString = Get-Content -Path "data.json" -Raw
$xmlDoc = ConvertFrom-JsonToXml -JsonString $jsonString
```

## Module XmlSupport

Ce module sert de point d'entrée pour utiliser toutes les fonctionnalités XML et HTML.

### Show-XmlSupportHelp

Affiche l'aide pour le module XmlSupport.

```powershell
Show-XmlSupportHelp
```

#### Exemple

```powershell
Show-XmlSupportHelp
```

### Invoke-XmlSupportTests

Exécute les tests du module XmlSupport.

```powershell
Invoke-XmlSupportTests
```

#### Exemple

```powershell
Invoke-XmlSupportTests
```

### Convert-FormatFile

Convertit un fichier d'un format à un autre.

```powershell
Convert-FormatFile -InputPath <string> -OutputPath <string> -InputFormat <string> -OutputFormat <string> [-ConversionSettings <hashtable>]
```

#### Paramètres

- **InputPath** : Le chemin du fichier d'entrée.
- **OutputPath** : Le chemin du fichier de sortie.
- **InputFormat** : Le format du fichier d'entrée (roadmap, xml).
- **OutputFormat** : Le format du fichier de sortie (roadmap, xml).
- **ConversionSettings** : (Optionnel) Un hashtable de paramètres pour personnaliser la conversion.

#### Exemple

```powershell
Convert-FormatFile -InputPath "roadmap.md" -OutputPath "roadmap.xml" -InputFormat "roadmap" -OutputFormat "xml"
```

### Invoke-XmlAnalysis

Analyse un fichier XML.

```powershell
Invoke-XmlAnalysis -XmlPath <string> [-OutputPath <string>] [-AsHtml] [-IncludeValidation] [-IncludeStructure] [-IncludeMapping]
```

#### Paramètres

- **XmlPath** : Le chemin du fichier XML à analyser.
- **OutputPath** : (Optionnel) Le chemin du fichier de sortie pour le rapport.
- **AsHtml** : (Optionnel) Génère le rapport au format HTML.
- **IncludeValidation** : (Optionnel) Inclut la validation XML dans le rapport.
- **IncludeStructure** : (Optionnel) Inclut la structure XML dans le rapport.
- **IncludeMapping** : (Optionnel) Inclut le mapping XML vers Roadmap dans le rapport.

#### Exemple

```powershell
Invoke-XmlAnalysis -XmlPath "roadmap.xml" -OutputPath "analysis.html" -AsHtml -IncludeValidation -IncludeStructure -IncludeMapping
```
