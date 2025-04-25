# Guide d'utilisation des segmenteurs de formats

Ce guide explique comment utiliser les modules de segmentation pour les formats JSON, XML et texte.

## Table des matières

1. [Introduction](#introduction)
2. [Installation et prérequis](#installation-et-prérequis)
3. [Interface unifiée (UnifiedSegmenter.ps1)](#interface-unifiée-unifiedsegmenterps1)
4. [Segmenteur JSON (JsonSegmenter.py)](#segmenteur-json-jsonsegmenterpy)
5. [Segmenteur XML (XmlSegmenter.py)](#segmenteur-xml-xmlsegmenterpy)
6. [Segmenteur de texte (TextSegmenter.py)](#segmenteur-de-texte-textsegmenterpy)
7. [Intégration avec InputSegmentation.psm1](#intégration-avec-inputsegmentationpsm1)
8. [Exemples d'utilisation](#exemples-dutilisation)
9. [Dépannage](#dépannage)

## Introduction

Les modules de segmentation permettent de traiter des fichiers volumineux dans différents formats (JSON, XML, texte) en les divisant en segments plus petits. Cela est particulièrement utile pour les systèmes qui ont des limites de taille d'entrée, comme les API ou les outils de traitement de données.

Les principales fonctionnalités sont :

- Segmentation de fichiers JSON, XML et texte
- Analyse de la structure et des statistiques des fichiers
- Validation des fichiers selon des schémas
- Conversion entre différents formats
- Interface unifiée pour tous les formats

## Installation et prérequis

### Prérequis

- PowerShell 5.1 ou supérieur
- Python 3.6 ou supérieur
- Modules Python requis : `lxml`

### Installation des modules Python requis

```powershell
python -m pip install lxml
```

### Vérification de l'installation

```powershell
# Importer le module UnifiedSegmenter
. .\modules\UnifiedSegmenter.ps1

# Initialiser le segmenteur unifié
$result = Initialize-UnifiedSegmenter
if ($result) {
    Write-Host "Installation réussie !" -ForegroundColor Green
} else {
    Write-Host "Problème d'installation. Vérifiez les prérequis." -ForegroundColor Red
}
```

## Interface unifiée (UnifiedSegmenter.ps1)

Le module `UnifiedSegmenter.ps1` fournit une interface PowerShell unifiée pour tous les segmenteurs.

### Initialisation

```powershell
# Importer le module
. .\modules\UnifiedSegmenter.ps1

# Initialiser avec les paramètres par défaut
Initialize-UnifiedSegmenter

# Initialiser avec des paramètres personnalisés
Initialize-UnifiedSegmenter -PythonPath "C:\Python39\python.exe" -MaxInputSizeKB 20 -DefaultChunkSizeKB 10
```

### Détection de format

```powershell
# Détecter automatiquement le format d'un fichier
$format = Get-FileFormat -FilePath "data.json"
Write-Host "Format détecté : $format"
```

### Segmentation de fichier

```powershell
# Segmenter un fichier avec détection automatique du format
$segments = Split-File -FilePath "data.json" -OutputDir ".\output"

# Segmenter un fichier JSON avec des paramètres personnalisés
$segments = Split-File -FilePath "data.json" -Format "JSON" -OutputDir ".\output\json" -ChunkSizeKB 5 -PreserveStructure

# Segmenter un fichier XML avec une expression XPath
$segments = Split-File -FilePath "data.xml" -Format "XML" -OutputDir ".\output\xml" -XPathExpression "//items/item"

# Segmenter un fichier texte par paragraphes
$segments = Split-File -FilePath "data.txt" -Format "TEXT" -OutputDir ".\output\text" -TextMethod "paragraph"
```

### Analyse de fichier

```powershell
# Analyser un fichier avec détection automatique du format
$analysis = Get-FileAnalysis -FilePath "data.json"

# Analyser un fichier et enregistrer les résultats
$outputFile = Get-FileAnalysis -FilePath "data.xml" -Format "XML" -OutputFile "analysis.json"
```

### Validation de fichier

```powershell
# Valider un fichier JSON
$isValid = Test-FileValidity -FilePath "data.json" -Format "JSON"

# Valider un fichier XML avec un schéma XSD
$isValid = Test-FileValidity -FilePath "data.xml" -Format "XML" -SchemaFile "schema.xsd"
```

### Requêtes XPath (XML uniquement)

```powershell
# Exécuter une requête XPath sur un fichier XML
$results = Invoke-XPathQuery -FilePath "data.xml" -XPathExpression "//items/item[@id='2']"

# Enregistrer les résultats dans un fichier
$outputFile = Invoke-XPathQuery -FilePath "data.xml" -XPathExpression "//items/item" -OutputFile "results.xml"
```

### Conversion entre formats

```powershell
# Convertir un fichier JSON en XML
$result = Convert-FileFormat -InputFile "data.json" -OutputFile "data.xml" -InputFormat "JSON" -OutputFormat "XML"

# Convertir un fichier XML en JSON
$result = Convert-FileFormat -InputFile "data.xml" -OutputFile "data.json" -InputFormat "XML" -OutputFormat "JSON"

# Convertir un fichier JSON en texte
$result = Convert-FileFormat -InputFile "data.json" -OutputFile "data.txt" -InputFormat "JSON" -OutputFormat "TEXT"
```

## Segmenteur JSON (JsonSegmenter.py)

Le module `JsonSegmenter.py` peut être utilisé directement en Python pour des fonctionnalités plus avancées.

### Utilisation en ligne de commande

```powershell
# Segmenter un fichier JSON
python .\modules\JsonSegmenter.py segment data.json --output-dir .\output\json --max-chunk-size 5

# Analyser un fichier JSON
python .\modules\JsonSegmenter.py analyze data.json --output analysis.json

# Valider un fichier JSON avec un schéma
python .\modules\JsonSegmenter.py validate data.json --schema schema.json
```

### Utilisation dans un script Python

```python
from modules.JsonSegmenter import JsonSegmenter

# Créer une instance du segmenteur
segmenter = JsonSegmenter(max_chunk_size_kb=5, preserve_structure=True)

# Charger un fichier JSON
data = segmenter.load_file("data.json")

# Segmenter les données
segments = segmenter.segment()

# Enregistrer les segments dans des fichiers
file_paths = segmenter.segment_to_files("output/json")

# Analyser les données
analysis = segmenter.analyze()

# Valider les données
is_valid, errors = segmenter.validate(schema=None)
```

## Segmenteur XML (XmlSegmenter.py)

Le module `XmlSegmenter.py` peut être utilisé directement en Python pour des fonctionnalités plus avancées.

### Utilisation en ligne de commande

```powershell
# Segmenter un fichier XML
python .\modules\XmlSegmenter.py segment data.xml --output-dir .\output\xml --max-chunk-size 5

# Segmenter un fichier XML avec une expression XPath
python .\modules\XmlSegmenter.py segment data.xml --output-dir .\output\xml --xpath "//items/item"

# Analyser un fichier XML
python .\modules\XmlSegmenter.py analyze data.xml --output analysis.json

# Valider un fichier XML avec un schéma XSD
python .\modules\XmlSegmenter.py validate data.xml --schema schema.xsd

# Exécuter une requête XPath
python .\modules\XmlSegmenter.py xpath data.xml "//items/item[@id='2']" --output results.xml
```

### Utilisation dans un script Python

```python
from modules.XmlSegmenter import XmlSegmenter

# Créer une instance du segmenteur
segmenter = XmlSegmenter(max_chunk_size_kb=5, preserve_structure=True)

# Charger un fichier XML
tree = segmenter.load_file("data.xml")

# Segmenter les données
segments = segmenter.segment(xpath_expression="//items/item")

# Enregistrer les segments dans des fichiers
file_paths = segmenter.segment_to_files("output/xml", xpath_expression="//items/item")

# Analyser les données
analysis = segmenter.analyze()

# Valider les données
is_valid, errors = segmenter.validate(schema_path="schema.xsd")

# Exécuter une requête XPath
elements = segmenter.xpath_query("//items/item[@id='2']")
```

## Segmenteur de texte (TextSegmenter.py)

Le module `TextSegmenter.py` peut être utilisé directement en Python pour des fonctionnalités plus avancées.

### Utilisation en ligne de commande

```powershell
# Segmenter un fichier texte
python .\modules\TextSegmenter.py segment data.txt --output-dir .\output\text --max-chunk-size 5

# Segmenter un fichier texte par paragraphes
python .\modules\TextSegmenter.py segment data.txt --output-dir .\output\text --method paragraph

# Analyser un fichier texte
python .\modules\TextSegmenter.py analyze data.txt --output analysis.json
```

### Utilisation dans un script Python

```python
from modules.TextSegmenter import TextSegmenter

# Créer une instance du segmenteur
segmenter = TextSegmenter(max_chunk_size_kb=5, preserve_paragraphs=True, preserve_sentences=True, smart_segmentation=True)

# Charger un fichier texte
text = segmenter.load_file("data.txt")

# Segmenter le texte
segments = segmenter.segment(method="paragraph")

# Enregistrer les segments dans des fichiers
file_paths = segmenter.segment_to_files("output/text", method="paragraph")

# Analyser le texte
analysis = segmenter.analyze()
```

## Intégration avec InputSegmentation.psm1

Les segmenteurs de formats peuvent être intégrés avec le module `InputSegmentation.psm1` existant pour une segmentation plus avancée.

### Exemple d'intégration

```powershell
# Importer les modules
Import-Module .\modules\InputSegmentation.psm1 -Force
. .\modules\UnifiedSegmenter.ps1

# Initialiser les modules
Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5
Initialize-UnifiedSegmenter -MaxInputSizeKB 10 -DefaultChunkSizeKB 5

# Fonction pour segmenter une entrée avec détection de format
function Split-FormatAwareInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Input,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 0
    )
    
    # Si l'entrée est un fichier, utiliser Split-File
    if ($Input -is [string] -and (Test-Path -Path $Input -PathType Leaf)) {
        return Split-File -FilePath $Input -ChunkSizeKB $ChunkSizeKB
    }
    
    # Si l'entrée est un objet JSON, utiliser Split-JsonInput
    if ($Input -is [PSCustomObject] -or $Input -is [hashtable] -or $Input -is [array]) {
        return Split-JsonInput -JsonObject $Input -ChunkSizeKB $ChunkSizeKB
    }
    
    # Si l'entrée est une chaîne, essayer de détecter le format
    if ($Input -is [string]) {
        # Essayer de parser comme JSON
        try {
            $json = $Input | ConvertFrom-Json
            return Split-JsonInput -JsonObject $json -ChunkSizeKB $ChunkSizeKB
        }
        catch {}
        
        # Essayer de parser comme XML
        try {
            $xml = [xml]$Input
            $tempFile = [System.IO.Path]::GetTempFileName()
            $xml.Save($tempFile)
            $result = Split-File -FilePath $tempFile -Format "XML" -ChunkSizeKB $ChunkSizeKB
            Remove-Item -Path $tempFile -Force
            return $result
        }
        catch {}
        
        # Traiter comme du texte
        return Split-TextInput -Text $Input -ChunkSizeKB $ChunkSizeKB
    }
    
    # Par défaut, utiliser Split-Input
    return Split-Input -Input $Input -ChunkSizeKB $ChunkSizeKB
}

# Exemple d'utilisation
$input = Get-Content -Path "data.json" -Raw
$segments = Split-FormatAwareInput -Input $input -ChunkSizeKB 5
```

## Exemples d'utilisation

### Exemple 1 : Segmentation d'un fichier JSON volumineux

```powershell
# Importer le module UnifiedSegmenter
. .\modules\UnifiedSegmenter.ps1

# Initialiser le segmenteur unifié
Initialize-UnifiedSegmenter -MaxInputSizeKB 10 -DefaultChunkSizeKB 5

# Segmenter un fichier JSON volumineux
$segments = Split-File -FilePath "large_data.json" -Format "JSON" -OutputDir ".\output\json" -ChunkSizeKB 5

# Afficher les segments créés
Write-Host "Segments créés :"
foreach ($segment in $segments) {
    Write-Host "- $segment"
}
```

### Exemple 2 : Extraction d'éléments spécifiques d'un fichier XML

```powershell
# Importer le module UnifiedSegmenter
. .\modules\UnifiedSegmenter.ps1

# Initialiser le segmenteur unifié
Initialize-UnifiedSegmenter

# Extraire tous les éléments "item" avec un attribut "id" égal à 2
$results = Invoke-XPathQuery -FilePath "data.xml" -XPathExpression "//items/item[@id='2']"

# Afficher les résultats
Write-Host "Éléments extraits :"
$results | ForEach-Object { Write-Host $_ }
```

### Exemple 3 : Analyse de la lisibilité d'un texte

```powershell
# Importer le module UnifiedSegmenter
. .\modules\UnifiedSegmenter.ps1

# Initialiser le segmenteur unifié
Initialize-UnifiedSegmenter

# Analyser un fichier texte
$analysis = Get-FileAnalysis -FilePath "document.txt" -Format "TEXT"

# Afficher les scores de lisibilité
$readability = $analysis.readability
Write-Host "Scores de lisibilité :"
Write-Host "- Flesch Reading Ease : $($readability.flesch_reading_ease)"
Write-Host "- Flesch-Kincaid Grade : $($readability.flesch_kincaid_grade)"
Write-Host "- Gunning Fog : $($readability.gunning_fog)"
```

### Exemple 4 : Conversion entre formats

```powershell
# Importer le module UnifiedSegmenter
. .\modules\UnifiedSegmenter.ps1

# Initialiser le segmenteur unifié
Initialize-UnifiedSegmenter

# Convertir un fichier JSON en XML
$result = Convert-FileFormat -InputFile "data.json" -OutputFile "data.xml" -InputFormat "JSON" -OutputFormat "XML"

if ($result) {
    Write-Host "Conversion réussie !" -ForegroundColor Green
    
    # Valider le fichier XML généré
    $isValid = Test-FileValidity -FilePath "data.xml" -Format "XML"
    
    if ($isValid) {
        Write-Host "Le fichier XML généré est valide." -ForegroundColor Green
    } else {
        Write-Host "Le fichier XML généré n'est pas valide." -ForegroundColor Red
    }
} else {
    Write-Host "Échec de la conversion." -ForegroundColor Red
}
```

## Dépannage

### Problèmes courants

#### Python n'est pas disponible

Si vous obtenez une erreur indiquant que Python n'est pas disponible, vérifiez que Python est installé et accessible dans le chemin système. Vous pouvez spécifier le chemin complet vers l'exécutable Python lors de l'initialisation :

```powershell
Initialize-UnifiedSegmenter -PythonPath "C:\Python39\python.exe"
```

#### Modules Python manquants

Si vous obtenez une erreur concernant des modules Python manquants, installez-les avec pip :

```powershell
python -m pip install lxml
```

#### Erreurs de segmentation

Si la segmentation échoue, essayez de réduire la taille des segments :

```powershell
Split-File -FilePath "data.json" -ChunkSizeKB 2
```

#### Erreurs de validation XML

Si la validation XML échoue, vérifiez que le schéma XSD est correct et que le fichier XML est bien formé :

```powershell
# Vérifier que le fichier XML est bien formé
$isValid = Test-FileValidity -FilePath "data.xml" -Format "XML"
```

### Journalisation et débogage

Pour activer la journalisation détaillée, utilisez le paramètre `-Verbose` :

```powershell
Initialize-UnifiedSegmenter -Verbose
Split-File -FilePath "data.json" -OutputDir ".\output" -Verbose
```

### Obtenir de l'aide

Pour obtenir de l'aide sur une fonction spécifique, utilisez `Get-Help` :

```powershell
Get-Help Split-File -Detailed
```
