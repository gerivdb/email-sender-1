# Guide de rÃ©fÃ©rence rapide - Format-Converters

## Installation

```powershell
Import-Module -Path "chemin\vers\Format-Converters\Format-Converters.psm1"
```plaintext
## Commandes principales

### DÃ©tection de format

```powershell
# DÃ©tection simple

Detect-FileFormat -FilePath "fichier.txt"

# DÃ©tection avec rÃ©solution automatique des cas ambigus

Detect-FileFormat -FilePath "fichier.txt" -AutoResolve

# DÃ©tection avec affichage des dÃ©tails

Detect-FileFormat -FilePath "fichier.txt" -ShowDetails

# DÃ©tection avec mÃ©morisation des choix

Detect-FileFormat -FilePath "fichier.txt" -RememberChoices

# DÃ©tection avec export des rÃ©sultats

Detect-FileFormat -FilePath "fichier.txt" -ShowDetails -ExportResults -ExportFormat "HTML"
```plaintext
### Conversion de format

```powershell
# Conversion avec dÃ©tection automatique du format d'entrÃ©e

Convert-FileFormat -InputPath "fichier.json" -OutputPath "fichier.xml" -OutputFormat "XML" -AutoDetect

# Conversion avec format d'entrÃ©e spÃ©cifiÃ©

Convert-FileFormat -InputPath "fichier.json" -OutputPath "fichier.xml" -InputFormat "JSON" -OutputFormat "XML"

# Conversion avec Ã©crasement du fichier de sortie

Convert-FileFormat -InputPath "fichier.json" -OutputPath "fichier.xml" -OutputFormat "XML" -Force

# Conversion avec affichage de la progression

Convert-FileFormat -InputPath "fichier.json" -OutputPath "fichier.xml" -OutputFormat "XML" -ShowProgress
```plaintext
### Analyse de format

```powershell
# Analyse avec dÃ©tection automatique du format

Analyze-FileFormat -FilePath "fichier.json" -AutoDetect

# Analyse avec format spÃ©cifiÃ©

Analyze-FileFormat -FilePath "fichier.json" -Format "JSON"

# Analyse avec inclusion du contenu

Analyze-FileFormat -FilePath "fichier.json" -IncludeContent

# Analyse avec export du rapport

Analyze-FileFormat -FilePath "fichier.json" -ExportReport
```plaintext
## Formats pris en charge

| Format | Extensions | Description |
|--------|------------|-------------|
| JSON | .json | JavaScript Object Notation |
| XML | .xml, .svg, .xhtml | eXtensible Markup Language |
| HTML | .html, .htm | HyperText Markup Language |
| CSV | .csv | Comma-Separated Values |
| YAML | .yaml, .yml | YAML Ain't Markup Language |
| MARKDOWN | .md, .markdown | Markdown Text Format |
| JAVASCRIPT | .js | JavaScript Code |
| CSS | .css | Cascading Style Sheets |
| POWERSHELL | .ps1, .psm1, .psd1 | PowerShell Script |
| PYTHON | .py | Python Script |
| INI | .ini, .cfg, .conf | Configuration File |
| TEXT | .txt, .text, .log | Plain Text |

## Gestion des cas ambigus

```powershell
# RÃ©solution automatique

Detect-FileFormat -FilePath "fichier.txt" -AutoResolve

# Confirmation utilisateur

Detect-FileFormat -FilePath "fichier.txt"

# MÃ©morisation des choix

Detect-FileFormat -FilePath "fichier.txt" -RememberChoices

# Personnalisation du seuil d'ambiguÃ¯tÃ©

Handle-AmbiguousFormats -FilePath "fichier.txt" -AmbiguityThreshold 15
```plaintext
## Exemples courants

```powershell
# DÃ©tecter le format d'un fichier et afficher les dÃ©tails

$result = Detect-FileFormat -FilePath "fichier.txt" -ShowDetails
Write-Host "Format dÃ©tectÃ© : $($result.DetectedFormat) (Score : $($result.ConfidenceScore)%)"

# Convertir un fichier JSON en XML

$result = Convert-FileFormat -InputPath "data.json" -OutputPath "data.xml" -OutputFormat "XML" -AutoDetect
if ($result.Success) {
    Write-Host "Conversion rÃ©ussie !"
}

# Analyser un fichier et exporter le rapport

$result = Analyze-FileFormat -FilePath "data.json" -AutoDetect -ExportReport
$result | Format-List
```plaintext
## Personnalisation

Les critÃ¨res de dÃ©tection peuvent Ãªtre personnalisÃ©s en modifiant le fichier `Detectors\FormatDetectionCriteria.json`.

## DÃ©pannage

1. **Format non dÃ©tectÃ©** : VÃ©rifiez que le fichier est valide et que son format est pris en charge.
2. **Erreur de conversion** : VÃ©rifiez que la conversion entre les formats spÃ©cifiÃ©s est prise en charge.
3. **Cas ambigu non rÃ©solu** : Utilisez l'option `-ShowDetails` pour voir les formats possibles et leurs scores de confiance.

## Documentation complÃ¨te

Pour plus d'informations, consultez les documents suivants :

- `Format-Converters.md` : Documentation complÃ¨te du module
- `Ambiguous-Format-Handling.md` : Guide de gestion des cas ambigus
