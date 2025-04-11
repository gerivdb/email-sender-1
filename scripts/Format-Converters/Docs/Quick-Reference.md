# Guide de référence rapide - Format-Converters

## Installation

```powershell
Import-Module -Path "chemin\vers\Format-Converters\Format-Converters.psm1"
```

## Commandes principales

### Détection de format

```powershell
# Détection simple
Detect-FileFormat -FilePath "fichier.txt"

# Détection avec résolution automatique des cas ambigus
Detect-FileFormat -FilePath "fichier.txt" -AutoResolve

# Détection avec affichage des détails
Detect-FileFormat -FilePath "fichier.txt" -ShowDetails

# Détection avec mémorisation des choix
Detect-FileFormat -FilePath "fichier.txt" -RememberChoices

# Détection avec export des résultats
Detect-FileFormat -FilePath "fichier.txt" -ShowDetails -ExportResults -ExportFormat "HTML"
```

### Conversion de format

```powershell
# Conversion avec détection automatique du format d'entrée
Convert-FileFormat -InputPath "fichier.json" -OutputPath "fichier.xml" -OutputFormat "XML" -AutoDetect

# Conversion avec format d'entrée spécifié
Convert-FileFormat -InputPath "fichier.json" -OutputPath "fichier.xml" -InputFormat "JSON" -OutputFormat "XML"

# Conversion avec écrasement du fichier de sortie
Convert-FileFormat -InputPath "fichier.json" -OutputPath "fichier.xml" -OutputFormat "XML" -Force

# Conversion avec affichage de la progression
Convert-FileFormat -InputPath "fichier.json" -OutputPath "fichier.xml" -OutputFormat "XML" -ShowProgress
```

### Analyse de format

```powershell
# Analyse avec détection automatique du format
Analyze-FileFormat -FilePath "fichier.json" -AutoDetect

# Analyse avec format spécifié
Analyze-FileFormat -FilePath "fichier.json" -Format "JSON"

# Analyse avec inclusion du contenu
Analyze-FileFormat -FilePath "fichier.json" -IncludeContent

# Analyse avec export du rapport
Analyze-FileFormat -FilePath "fichier.json" -ExportReport
```

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
# Résolution automatique
Detect-FileFormat -FilePath "fichier.txt" -AutoResolve

# Confirmation utilisateur
Detect-FileFormat -FilePath "fichier.txt"

# Mémorisation des choix
Detect-FileFormat -FilePath "fichier.txt" -RememberChoices

# Personnalisation du seuil d'ambiguïté
Handle-AmbiguousFormats -FilePath "fichier.txt" -AmbiguityThreshold 15
```

## Exemples courants

```powershell
# Détecter le format d'un fichier et afficher les détails
$result = Detect-FileFormat -FilePath "fichier.txt" -ShowDetails
Write-Host "Format détecté : $($result.DetectedFormat) (Score : $($result.ConfidenceScore)%)"

# Convertir un fichier JSON en XML
$result = Convert-FileFormat -InputPath "data.json" -OutputPath "data.xml" -OutputFormat "XML" -AutoDetect
if ($result.Success) {
    Write-Host "Conversion réussie !"
}

# Analyser un fichier et exporter le rapport
$result = Analyze-FileFormat -FilePath "data.json" -AutoDetect -ExportReport
$result | Format-List
```

## Personnalisation

Les critères de détection peuvent être personnalisés en modifiant le fichier `Detectors\FormatDetectionCriteria.json`.

## Dépannage

1. **Format non détecté** : Vérifiez que le fichier est valide et que son format est pris en charge.
2. **Erreur de conversion** : Vérifiez que la conversion entre les formats spécifiés est prise en charge.
3. **Cas ambigu non résolu** : Utilisez l'option `-ShowDetails` pour voir les formats possibles et leurs scores de confiance.

## Documentation complète

Pour plus d'informations, consultez les documents suivants :

- `Format-Converters.md` : Documentation complète du module
- `Ambiguous-Format-Handling.md` : Guide de gestion des cas ambigus
