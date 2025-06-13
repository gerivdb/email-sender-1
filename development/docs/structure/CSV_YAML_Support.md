# Support des formats CSV et YAML dans UnifiedSegmenter

Ce document décrit les fonctionnalités de support des formats CSV et YAML ajoutées au module UnifiedSegmenter.

## Table des matières

1. [Introduction](#introduction)

2. [Détection de format](#détection-de-format)

3. [Validation de fichier](#validation-de-fichier)

4. [Conversion entre formats](#conversion-entre-formats)

5. [Analyse de fichier](#analyse-de-fichier)

6. [Segmentation de fichier](#segmentation-de-fichier)

7. [Détection d'encodage](#détection-dencodage)

8. [Exemples d'utilisation](#exemples-dutilisation)

## Introduction

Le module UnifiedSegmenter a été étendu pour prendre en charge les formats CSV et YAML, en plus des formats JSON, XML et TEXT déjà supportés. Cette extension permet de :

- Détecter automatiquement les formats CSV et YAML
- Valider les fichiers CSV et YAML
- Convertir entre tous les formats (JSON, XML, TEXT, CSV, YAML)
- Analyser les fichiers CSV et YAML pour obtenir des informations détaillées
- Segmenter les fichiers CSV et YAML en morceaux plus petits
- Détecter l'encodage des fichiers

## Détection de format

La fonction `Get-FileFormat` a été mise à jour pour détecter les formats CSV et YAML :

```powershell
# Détecter le format d'un fichier

$format = Get-FileFormat -FilePath "C:\temp\data.csv"
Write-Host "Format détecté: $format"  # Affiche "Format détecté: CSV"

# Détecter le format avec détection d'encodage

$format = Get-FileFormat -FilePath "C:\temp\data.yaml" -UseEncodingDetector
Write-Host "Format détecté: $format"  # Affiche "Format détecté: YAML"

```plaintext
## Validation de fichier

La fonction `Test-FileValidity` a été mise à jour pour valider les fichiers CSV et YAML :

```powershell
# Valider un fichier CSV

$isValid = Test-FileValidity -FilePath "C:\temp\data.csv" -Format "CSV"
if ($isValid) {
    Write-Host "Le fichier CSV est valide"
} else {
    Write-Host "Le fichier CSV n'est pas valide"
}

# Valider un fichier YAML

$isValid = Test-FileValidity -FilePath "C:\temp\data.yaml" -Format "YAML"
if ($isValid) {
    Write-Host "Le fichier YAML est valide"
} else {
    Write-Host "Le fichier YAML n'est pas valide"
}
```plaintext
## Conversion entre formats

La fonction `Convert-FileFormat` a été mise à jour pour prendre en charge les conversions entre tous les formats (JSON, XML, TEXT, CSV, YAML) :

```powershell
# Convertir JSON en CSV

Convert-FileFormat -InputFile "C:\temp\data.json" -OutputFile "C:\temp\data.csv" -InputFormat "JSON" -OutputFormat "CSV"

# Convertir CSV en JSON

Convert-FileFormat -InputFile "C:\temp\data.csv" -OutputFile "C:\temp\data.json" -InputFormat "CSV" -OutputFormat "JSON"

# Convertir YAML en JSON

Convert-FileFormat -InputFile "C:\temp\data.yaml" -OutputFile "C:\temp\data.json" -InputFormat "YAML" -OutputFormat "JSON"

# Convertir JSON en YAML

Convert-FileFormat -InputFile "C:\temp\data.json" -OutputFile "C:\temp\data.yaml" -InputFormat "JSON" -OutputFormat "YAML"

# Convertir CSV en YAML

Convert-FileFormat -InputFile "C:\temp\data.csv" -OutputFile "C:\temp\data.yaml" -InputFormat "CSV" -OutputFormat "YAML"

# Convertir YAML en CSV

Convert-FileFormat -InputFile "C:\temp\data.yaml" -OutputFile "C:\temp\data.csv" -InputFormat "YAML" -OutputFormat "CSV"
```plaintext
### Traitement des objets imbriqués

La fonction `Convert-FileFormat` a été améliorée pour prendre en charge le traitement des objets imbriqués lors de la conversion vers CSV :

```powershell
# Convertir JSON en CSV avec aplatissement des objets imbriqués

Convert-FileFormat -InputFile "C:\temp\data.json" -OutputFile "C:\temp\data.csv" -InputFormat "JSON" -OutputFormat "CSV" -FlattenNestedObjects $true -NestedSeparator "."

# Convertir JSON en CSV sans aplatissement des objets imbriqués

Convert-FileFormat -InputFile "C:\temp\data.json" -OutputFile "C:\temp\data.csv" -InputFormat "JSON" -OutputFormat "CSV" -FlattenNestedObjects $false
```plaintext
#### Exemple d'aplatissement d'objets imbriqués

Avec un fichier JSON comme celui-ci :

```json
{
  "name": "John Doe",
  "age": 30,
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "country": "USA"
  },
  "phones": [
    "123-456-7890",
    "098-765-4321"
  ]
}
```plaintext
Avec `FlattenNestedObjects = $true` et `NestedSeparator = "."`, le CSV résultant sera :

```csv
name,age,address.street,address.city,address.country,phones
"John Doe",30,"123 Main St","New York","USA","123-456-7890, 098-765-4321"
```plaintext
Avec `FlattenNestedObjects = $false`, le CSV résultant sera :

```csv
name,age,address,phones
"John Doe",30,"{""street"": ""123 Main St"", ""city"": ""New York"", ""country"": ""USA""}","[""123-456-7890"", ""098-765-4321""]"
```plaintext
## Analyse de fichier

La fonction `Get-FileAnalysis` a été mise à jour pour analyser les fichiers CSV et YAML :

```powershell
# Analyser un fichier CSV

$analysis = Get-FileAnalysis -FilePath "C:\temp\data.csv" -Format "CSV"
$analysis.structure.total_rows  # Nombre total de lignes

$analysis.structure.total_columns  # Nombre total de colonnes

$analysis.structure.header  # En-tête du CSV

$analysis.statistics.fill_rate  # Taux de remplissage

# Analyser un fichier YAML

$analysis = Get-FileAnalysis -FilePath "C:\temp\data.yaml" -Format "YAML"
$analysis.structure.type  # Type de la structure (dict, list, etc.)

$analysis.structure.keys  # Clés de la structure (si c'est un dictionnaire)

```plaintext
### Informations d'analyse CSV

L'analyse CSV fournit les informations suivantes :

- **file_info** : Informations sur le fichier (chemin, taille, encodage)
- **structure** : Informations sur la structure du CSV (nombre de lignes, nombre de colonnes, en-tête)
- **statistics** : Statistiques générales (nombre total de cellules, nombre de cellules vides, taux de remplissage)
- **columns** : Informations détaillées sur chaque colonne (type détecté, nombre de valeurs vides, valeurs uniques, statistiques)

### Informations d'analyse YAML

L'analyse YAML fournit les informations suivantes :

- **file_info** : Informations sur le fichier (chemin, taille, encodage)
- **structure** : Informations sur la structure du YAML (type, chemin, clés, éléments imbriqués)

## Segmentation de fichier

La fonction `Split-File` a été mise à jour pour segmenter les fichiers CSV et YAML :

```powershell
# Segmenter un fichier CSV

$segments = Split-File -FilePath "C:\temp\data.csv" -Format "CSV" -OutputDir "C:\temp\segments" -ChunkSizeKB 10

# Segmenter un fichier YAML

$segments = Split-File -FilePath "C:\temp\data.yaml" -Format "YAML" -OutputDir "C:\temp\segments" -ChunkSizeKB 10
```plaintext
## Détection d'encodage

Une nouvelle fonction `Get-FileEncoding` a été ajoutée pour détecter l'encodage des fichiers :

```powershell
# Détecter l'encodage d'un fichier

$encodingInfo = Get-FileEncoding -FilePath "C:\temp\data.csv"
$encodingInfo.encoding  # Encodage détecté

$encodingInfo.has_bom  # Indique si le fichier a un BOM

$encodingInfo.file_type  # Type de fichier détecté (JSON, XML, TEXT, BINARY)

```plaintext
## Exemples d'utilisation

### Exemple 1 : Conversion d'un fichier CSV en JSON

```powershell
# Détecter le format du fichier

$format = Get-FileFormat -FilePath "C:\temp\data.csv"
Write-Host "Format détecté: $format"

# Valider le fichier CSV

$isValid = Test-FileValidity -FilePath "C:\temp\data.csv" -Format "CSV"
if (-not $isValid) {
    Write-Error "Le fichier CSV n'est pas valide"
    return
}

# Analyser le fichier CSV

$analysis = Get-FileAnalysis -FilePath "C:\temp\data.csv" -Format "CSV"
Write-Host "Nombre de lignes: $($analysis.structure.total_rows)"
Write-Host "Nombre de colonnes: $($analysis.structure.total_columns)"

# Convertir le fichier CSV en JSON

Convert-FileFormat -InputFile "C:\temp\data.csv" -OutputFile "C:\temp\data.json" -InputFormat "CSV" -OutputFormat "JSON"
Write-Host "Conversion terminée"
```plaintext
### Exemple 2 : Conversion d'un fichier JSON en CSV avec aplatissement des objets imbriqués

```powershell
# Convertir le fichier JSON en CSV avec aplatissement des objets imbriqués

Convert-FileFormat -InputFile "C:\temp\data.json" -OutputFile "C:\temp\data.csv" -InputFormat "JSON" -OutputFormat "CSV" -FlattenNestedObjects $true -NestedSeparator "_"
Write-Host "Conversion terminée"

# Valider le fichier CSV généré

$isValid = Test-FileValidity -FilePath "C:\temp\data.csv" -Format "CSV"
if ($isValid) {
    Write-Host "Le fichier CSV généré est valide"
} else {
    Write-Host "Le fichier CSV généré n'est pas valide"
}
```plaintext
### Exemple 3 : Segmentation d'un fichier CSV volumineux

```powershell
# Segmenter un fichier CSV volumineux

$segments = Split-File -FilePath "C:\temp\data.csv" -Format "CSV" -OutputDir "C:\temp\segments" -ChunkSizeKB 100
Write-Host "Nombre de segments créés: $($segments.Count)"

# Traiter chaque segment

foreach ($segment in $segments) {
    Write-Host "Traitement du segment: $segment"
    # Traitement du segment...

}
```plaintext
### Exemple 4 : Analyse d'un fichier YAML

```powershell
# Analyser un fichier YAML

$analysis = Get-FileAnalysis -FilePath "C:\temp\data.yaml" -Format "YAML"
Write-Host "Type de structure: $($analysis.structure.type)"

# Si c'est un dictionnaire, afficher les clés

if ($analysis.structure.type -eq "dict") {
    Write-Host "Clés: $($analysis.structure.keys -join ', ')"
}

# Si c'est une liste, afficher le nombre d'éléments

if ($analysis.structure.type -eq "list") {
    Write-Host "Nombre d'éléments: $($analysis.structure.item_count)"
}
```plaintext