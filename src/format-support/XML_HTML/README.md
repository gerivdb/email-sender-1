# Support des formats XML et HTML

Ce module fournit un support complet pour les formats XML et HTML, permettant de convertir, analyser et valider des fichiers dans ces formats, ainsi que de convertir entre ces formats et le format Roadmap (Markdown).

## Installation

Pour utiliser ce module, vous devez d'abord l'importer :

```powershell
# Importer le module principal

$scriptPath = "chemin/vers/FormatSupport/XML_HTML"
. "$scriptPath/XmlSupport.ps1"

# Afficher l'aide

Show-XmlSupportHelp
```plaintext
## Fonctionnalités principales

### Support XML

- Conversion entre Roadmap (Markdown) et XML
- Analyse et validation de fichiers XML
- Génération de rapports de structure XML
- Détection des éléments XML (balises, attributs)
- Génération de schémas XSD

### Support HTML

- Conversion entre HTML et XML
- Sanitisation de documents HTML
- Extraction de texte à partir de HTML
- Requêtes CSS sur des documents HTML

### Conversion entre formats

- XML vers Roadmap (Markdown)
- Roadmap (Markdown) vers XML
- XML vers HTML
- HTML vers XML
- XML vers JSON
- JSON vers XML

## Documentation

La documentation complète est disponible dans le dossier `Documentation` :

- [Guide Utilisateur](Documentation/Guide_Utilisateur.md) - Guide complet pour l'utilisation du module
- [Référence API](Documentation/Reference_API.md) - Référence de toutes les fonctions disponibles

## Exemples

Des exemples sont disponibles dans le dossier `Examples` :

- [Exemple de Roadmap en XML](Examples/example-roadmap.xml)
- [Exemple de Roadmap en HTML](Examples/example-roadmap.html)
- [README des exemples](Examples/README.md)

## Tests

Des tests unitaires et d'intégration sont disponibles dans le dossier `Tests` :

- [Tests unitaires](Tests/Test-UnitTests.ps1)
- [Tests du convertisseur Roadmap-XML](Tests/Test-RoadmapXmlConverter.ps1)
- [Tests des outils XML](Tests/Test-XmlTools.ps1)

## Intégration

Ce module peut être intégré avec le module Format-Converters et l'interface utilisateur :

- [Script d'intégration Format-Converters](Integration/Format-Converters-Integration.ps1)
- [Script de mise à jour de l'interface utilisateur](Integration/Update-UserInterface.ps1)
- [Script de test d'intégration](Integration/Test-Integration.ps1)

## Utilisation rapide

### Convertir un fichier Roadmap en XML

```powershell
ConvertFrom-RoadmapFileToXmlFile -RoadmapPath "roadmap.md" -XmlPath "roadmap.xml"
```plaintext
### Convertir un fichier XML en Roadmap

```powershell
ConvertFrom-XmlFileToRoadmapFile -XmlPath "roadmap.xml" -RoadmapPath "roadmap.md"
```plaintext
### Analyser un fichier XML

```powershell
Get-XmlStructureReportFromFile -XmlPath "roadmap.xml" -OutputPath "structure_report.html" -AsHtml
```plaintext
### Valider un fichier XML

```powershell
Test-XmlFileWithReport -XmlPath "roadmap.xml" -OutputPath "validation_report.html" -AsHtml
```plaintext
### Convertir un fichier XML en HTML

```powershell
$xmlDoc = Import-XmlFile -FilePath "data.xml"
$htmlDoc = ConvertFrom-XmlToHtml -XmlDocument $xmlDoc
Export-HtmlFile -HtmlDocument $htmlDoc -FilePath "data.html"
```plaintext
### Extraire le texte d'un fichier HTML

```powershell
$htmlDoc = Import-HtmlFile -FilePath "page.html"
$text = ConvertTo-PlainText -HtmlDocument $htmlDoc
$text | Out-File -FilePath "page.txt" -Encoding UTF8
```plaintext