# Support des formats JSON, XML et texte

Ce module fournit un support complet pour la segmentation, l'analyse et la conversion des formats JSON, XML et texte.

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Modules](#modules)
3. [Installation](#installation)
4. [Utilisation de base](#utilisation-de-base)
5. [Fonctionnalités avancées](#fonctionnalités-avancées)
6. [Optimisation des performances](#optimisation-des-performances)
7. [Intégration avec d'autres modules](#intégration-avec-dautres-modules)
8. [Exemples](#exemples)
9. [Dépannage](#dépannage)

## Vue d'ensemble

Le support des formats JSON, XML et texte permet de traiter des fichiers volumineux en les segmentant en morceaux plus petits, tout en préservant leur structure. Il offre également des fonctionnalités d'analyse, de validation et de conversion entre formats.

### Principales fonctionnalités

- **Segmentation intelligente** : Divise les fichiers volumineux en segments plus petits tout en préservant leur structure.
- **Analyse de structure** : Fournit des informations détaillées sur la structure et les statistiques des fichiers.
- **Validation** : Vérifie la validité des fichiers selon des schémas (JSON Schema, XSD).
- **Conversion** : Convertit entre différents formats (JSON, XML, texte).
- **Optimisation** : Traitement en streaming et en parallèle pour les fichiers très volumineux.
- **Compression** : Compression des segments pour économiser de l'espace disque.

## Modules

Le support des formats est composé de plusieurs modules :

- **JsonSegmenter.py** : Module Python pour la segmentation et l'analyse de données JSON.
- **XmlSegmenter.py** : Module Python pour la segmentation et l'analyse de données XML, avec support XPath.
- **TextSegmenter.py** : Module Python pour la segmentation et l'analyse de texte.
- **UnifiedSegmenter.ps1** : Interface PowerShell unifiée pour tous les segmenteurs.
- **FormatSegmentation.psm1** : Module d'intégration avec InputSegmentation.psm1.
- **FormatOptimizer.ps1** : Module d'optimisation pour les fichiers très volumineux.

## Installation

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

## Utilisation de base

### Segmentation d'un fichier

```powershell
# Importer le module UnifiedSegmenter
. .\modules\UnifiedSegmenter.ps1

# Initialiser le segmenteur unifié
Initialize-UnifiedSegmenter

# Segmenter un fichier avec détection automatique du format
$segments = Split-File -FilePath "data.json" -OutputDir ".\output"

# Afficher les segments créés
Write-Host "Segments créés :"
foreach ($segment in $segments) {
    Write-Host "- $segment"
}
```

### Analyse d'un fichier

```powershell
# Analyser un fichier avec détection automatique du format
$analysis = Get-FileAnalysis -FilePath "data.json"

# Afficher les résultats
$analysis | ConvertTo-Json -Depth 5
```

### Validation d'un fichier

```powershell
# Valider un fichier JSON
$isValid = Test-FileValidity -FilePath "data.json" -Format "JSON"

if ($isValid) {
    Write-Host "Le fichier est valide." -ForegroundColor Green
} else {
    Write-Host "Le fichier n'est pas valide." -ForegroundColor Red
}
```

### Conversion entre formats

```powershell
# Convertir un fichier JSON en XML
$result = Convert-FileFormat -InputFile "data.json" -OutputFile "data.xml" -InputFormat "JSON" -OutputFormat "XML"

if ($result) {
    Write-Host "Conversion réussie !" -ForegroundColor Green
} else {
    Write-Host "Échec de la conversion." -ForegroundColor Red
}
```

## Fonctionnalités avancées

### Requêtes XPath (XML uniquement)

```powershell
# Exécuter une requête XPath sur un fichier XML
$results = Invoke-XPathQuery -FilePath "data.xml" -XPathExpression "//items/item[@id='2']"

# Afficher les résultats
$results
```

### Segmentation avec préservation de structure

```powershell
# Segmenter un fichier JSON en préservant sa structure
$segments = Split-File -FilePath "data.json" -Format "JSON" -OutputDir ".\output\json" -ChunkSizeKB 5 -PreserveStructure

# Segmenter un fichier XML avec une expression XPath
$segments = Split-File -FilePath "data.xml" -Format "XML" -OutputDir ".\output\xml" -XPathExpression "//items/item"

# Segmenter un fichier texte par paragraphes
$segments = Split-File -FilePath "data.txt" -Format "TEXT" -OutputDir ".\output\text" -TextMethod "paragraph"
```

## Optimisation des performances

### Traitement en streaming

```powershell
# Importer le module FormatOptimizer
. .\modules\FormatOptimizer.ps1

# Traiter un fichier volumineux en mode streaming
$segments = Split-StreamingFile -FilePath "large_data.json" -OutputDir ".\output\streaming" -Format "JSON" -BufferSizeKB 1024 -ChunkSizeKB 10
```

### Traitement en parallèle

```powershell
# Traiter un fichier volumineux en parallèle
$segments = Split-ParallelFile -FilePath "large_data.json" -OutputDir ".\output\parallel" -Format "JSON" -ChunkSizeKB 10 -MaxThreads 4
```

### Compression des segments

```powershell
# Compresser les segments
$archivePath = Compress-Segments -FilePaths $segments -OutputFile "segments.zip" -CompressionMethod "Zip"

# Décompresser les segments
$extractedSegments = Expand-Segments -ArchivePath $archivePath -OutputDir ".\output\extracted" -CompressionMethod "Zip"
```

## Intégration avec d'autres modules

### Intégration avec InputSegmentation.psm1

```powershell
# Importer le module FormatSegmentation
Import-Module .\modules\FormatSegmentation.psm1

# Initialiser le module d'intégration
Initialize-FormatSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5

# Segmenter une entrée avec détection de format
$segments = Split-FormatAwareInput -Input "data.json" -Format "AUTO" -OutputDir ".\output\integrated" -ChunkSizeKB 5

# Traiter une entrée avec segmentation automatique
$results = Invoke-WithFormatSegmentation -Input "data.json" -Format "JSON" -ScriptBlock {
    param($segment)
    # Traiter le segment
    return "Segment traité: $($segment.GetType().Name)"
}
```

## Exemples

### Exemple 1 : Segmentation d'un fichier JSON volumineux

```powershell
# Importer les modules
. .\modules\UnifiedSegmenter.ps1
. .\modules\FormatOptimizer.ps1

# Initialiser le segmenteur unifié
Initialize-UnifiedSegmenter

# Segmenter un fichier JSON volumineux en mode streaming
$segments = Split-StreamingFile -FilePath "large_data.json" -OutputDir ".\output\streaming" -Format "JSON" -BufferSizeKB 1024 -ChunkSizeKB 10

# Compresser les segments
$archivePath = Compress-Segments -FilePaths $segments -OutputFile "segments.zip" -CompressionMethod "Zip"

Write-Host "Segments créés et compressés dans $archivePath"
```

### Exemple 2 : Analyse et validation d'un fichier XML

```powershell
# Importer le module UnifiedSegmenter
. .\modules\UnifiedSegmenter.ps1

# Initialiser le segmenteur unifié
Initialize-UnifiedSegmenter

# Analyser un fichier XML
$analysis = Get-FileAnalysis -FilePath "data.xml" -Format "XML"

# Afficher les informations sur la structure
$analysis.structure | ConvertTo-Json -Depth 3

# Valider le fichier XML avec un schéma XSD
$isValid = Test-FileValidity -FilePath "data.xml" -Format "XML" -SchemaFile "schema.xsd"

if ($isValid) {
    Write-Host "Le fichier XML est valide selon le schéma XSD." -ForegroundColor Green
} else {
    Write-Host "Le fichier XML n'est pas valide selon le schéma XSD." -ForegroundColor Red
}
```

### Exemple 3 : Traitement d'un fichier texte volumineux

```powershell
# Importer les modules
Import-Module .\modules\FormatSegmentation.psm1

# Initialiser le module d'intégration
Initialize-FormatSegmentation

# Traiter un fichier texte volumineux avec segmentation automatique
$results = Invoke-WithFormatSegmentation -Input "large_text.txt" -Format "TEXT" -ScriptBlock {
    param($segment)
    
    # Compter les mots dans le segment
    $wordCount = ($segment -split '\W+' | Where-Object { $_ -ne '' }).Count
    
    return [PSCustomObject]@{
        SegmentSize = $segment.Length
        WordCount = $wordCount
    }
}

# Afficher les résultats
$totalWords = ($results | Measure-Object -Property WordCount -Sum).Sum
Write-Host "Nombre total de mots: $totalWords"
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
