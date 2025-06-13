# Module de segmentation d'entrées (InputSegmenter)

## Vue d'ensemble

Le module `InputSegmentation` est un composant essentiel qui permet de segmenter automatiquement les entrées volumineuses en morceaux plus petits et gérables. Cette fonctionnalité est particulièrement utile pour traiter des données qui dépassent les limites de taille imposées par certains outils ou API, comme les modèles d'IA ou les services web.

Le module prend en charge différents types d'entrées (texte, JSON, fichiers) et offre plusieurs stratégies de segmentation pour préserver la structure et la cohérence des données. Il s'intègre également avec d'autres modules du système, comme Agent Auto et le cache prédictif, pour offrir une solution complète de traitement des données volumineuses.

## Installation

Le module est disponible dans le dossier `modules` du projet. Pour l'importer :

```powershell
Import-Module -Path ".\modules\InputSegmentation.psm1" -Force
```plaintext
## Initialisation

Avant d'utiliser le module, il est recommandé de l'initialiser avec les paramètres souhaités :

```powershell
Initialize-InputSegmentation -MaxInputSizeKB 15 -DefaultChunkSizeKB 7 -StateFilePath ".\cache\segmentation_state.json"
```plaintext
## Architecture

Le module `InputSegmentation` est conçu selon les principes SOLID et offre une architecture modulaire et extensible :

1. **Couche d'initialisation** : Configure les paramètres globaux du module
2. **Couche de mesure** : Évalue la taille des entrées
3. **Couche de segmentation** : Divise les entrées en segments selon leur type
4. **Couche d'état** : Gère la persistance de l'état de segmentation
5. **Couche d'exécution** : Traite les segments avec un script fourni par l'utilisateur

Cette architecture permet d'ajouter facilement de nouveaux types d'entrées ou de nouvelles stratégies de segmentation sans modifier le code existant.

## Fonctions principales

### Initialize-InputSegmentation

Initialise le module de segmentation avec les paramètres spécifiés.

#### Syntaxe

```powershell
Initialize-InputSegmentation [-MaxInputSizeKB <Int32>] [-DefaultChunkSizeKB <Int32>] [-StateFilePath <String>]
```plaintext
#### Paramètres

- **MaxInputSizeKB** : Taille maximale d'entrée en kilooctets avant segmentation. Par défaut : 10.
- **DefaultChunkSizeKB** : Taille par défaut des segments en kilooctets. Par défaut : 5.
- **StateFilePath** : Chemin du fichier pour stocker l'état de segmentation. Par défaut : dossier temporaire.

#### Exemple

```powershell
# Initialiser avec des valeurs personnalisées

Initialize-InputSegmentation -MaxInputSizeKB 20 -DefaultChunkSizeKB 8 -StateFilePath ".\cache\segmentation_state.json"

# Initialiser avec les valeurs par défaut

Initialize-InputSegmentation
```plaintext
### Measure-InputSize

Mesure la taille d'une entrée en kilooctets.

#### Syntaxe

```powershell
Measure-InputSize -Input <Object>
```plaintext
#### Paramètres

- **Input** : L'entrée à mesurer (texte, JSON, fichier, etc.).

#### Valeur de retour

La taille de l'entrée en kilooctets (KB).

#### Exemple

```powershell
$text = "A" * 10KB
$size = Measure-InputSize -Input $text
Write-Host "Taille de l'entrée: $size KB"

$json = @{ "data" = @(1..1000) } | ConvertTo-Json
$jsonSize = Measure-InputSize -Input $json
Write-Host "Taille du JSON: $jsonSize KB"
```plaintext
### Split-TextInput

Segmente une chaîne de texte en morceaux plus petits.

#### Syntaxe

```powershell
Split-TextInput -Text <String> [-ChunkSizeKB <Int32>] [-PreserveLines]
```plaintext
#### Paramètres

- **Text** : Le texte à segmenter.
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets. Si non spécifié, utilise la valeur par défaut.
- **PreserveLines** : Préserve les sauts de ligne lors de la segmentation.

#### Valeur de retour

Un tableau de chaînes de texte représentant les segments.

#### Exemple

```powershell
# Segmenter un texte sans préserver les lignes

$text = "A" * 20KB
$segments = Split-TextInput -Text $text -ChunkSizeKB 5
Write-Host "Nombre de segments: $($segments.Count)"

# Segmenter un texte en préservant les lignes

$multilineText = "Ligne 1`nLigne 2`nLigne 3" * 1000
$segments = Split-TextInput -Text $multilineText -ChunkSizeKB 5 -PreserveLines
Write-Host "Nombre de segments: $($segments.Count)"
```plaintext
### Split-JsonInput

Segmente un objet JSON en morceaux plus petits.

#### Syntaxe

```powershell
Split-JsonInput -JsonObject <Object> [-ChunkSizeKB <Int32>]
```plaintext
#### Paramètres

- **JsonObject** : L'objet JSON à segmenter.
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets. Si non spécifié, utilise la valeur par défaut.

#### Valeur de retour

Un tableau d'objets représentant les segments du JSON d'origine.

#### Exemple

```powershell
# Segmenter un tableau JSON

$array = 1..1000 | ForEach-Object { @{ "id" = $_; "data" = "A" * 100 } }
$segments = Split-JsonInput -JsonObject $array -ChunkSizeKB 5
Write-Host "Nombre de segments: $($segments.Count)"

# Segmenter un objet JSON

$object = @{
    "header" = @{ "version" = "1.0"; "type" = "data" }
    "items" = 1..500 | ForEach-Object { @{ "id" = $_; "value" = "Item $_" } }
}
$segments = Split-JsonInput -JsonObject $object -ChunkSizeKB 5
Write-Host "Nombre de segments: $($segments.Count)"
```plaintext
### Split-FileInput

Segmente un fichier en morceaux plus petits.

#### Syntaxe

```powershell
Split-FileInput -FilePath <String> [-ChunkSizeKB <Int32>] [-PreserveLines]
```plaintext
#### Paramètres

- **FilePath** : Chemin du fichier à segmenter.
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets. Si non spécifié, utilise la valeur par défaut.
- **PreserveLines** : Préserve les sauts de ligne lors de la segmentation.

#### Valeur de retour

Un tableau de chaînes ou d'objets représentant les segments du fichier.

#### Exemple

```powershell
# Segmenter un fichier texte

$segments = Split-FileInput -FilePath ".\data\large_text_file.txt" -ChunkSizeKB 5 -PreserveLines
Write-Host "Nombre de segments: $($segments.Count)"

# Segmenter un fichier JSON

$segments = Split-FileInput -FilePath ".\data\large_data.json" -ChunkSizeKB 5
Write-Host "Nombre de segments: $($segments.Count)"

# Segmenter un fichier CSV

$segments = Split-FileInput -FilePath ".\data\large_data.csv" -ChunkSizeKB 5 -PreserveLines
Write-Host "Nombre de segments: $($segments.Count)"
```plaintext
### Split-Input

Fonction générique pour segmenter différents types d'entrées.

#### Syntaxe

```powershell
Split-Input -Input <Object> [-ChunkSizeKB <Int32>] [-PreserveLines]
```plaintext
#### Paramètres

- **Input** : L'entrée à segmenter (texte, JSON, fichier, etc.).
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets. Si non spécifié, utilise la valeur par défaut.
- **PreserveLines** : Préserve les sauts de ligne lors de la segmentation de texte.

#### Valeur de retour

Un tableau d'objets représentant les segments de l'entrée.

#### Exemple

```powershell
# Segmenter une chaîne de texte

$text = "A" * 20KB
$segments = Split-Input -Input $text -ChunkSizeKB 5
Write-Host "Nombre de segments: $($segments.Count)"

# Segmenter un objet JSON

$json = @{ "data" = @(1..1000) }
$segments = Split-Input -Input $json -ChunkSizeKB 5
Write-Host "Nombre de segments: $($segments.Count)"

# Segmenter un fichier

$segments = Split-Input -Input ".\data\large_file.txt" -ChunkSizeKB 5 -PreserveLines
Write-Host "Nombre de segments: $($segments.Count)"
```plaintext
### Save-SegmentationState

Sauvegarde l'état de segmentation pour une reprise ultérieure.

#### Syntaxe

```powershell
Save-SegmentationState -Id <String> -Segments <Array> -CurrentIndex <Int32>
```plaintext
#### Paramètres

- **Id** : Identifiant unique de l'état de segmentation.
- **Segments** : Tableau des segments.
- **CurrentIndex** : Index du segment en cours de traitement.

#### Valeur de retour

$true si l'état a été sauvegardé avec succès, $false sinon.

#### Exemple

```powershell
$id = "my-segmentation-task"
$segments = Split-Input -Input $largeInput -ChunkSizeKB 5
Save-SegmentationState -Id $id -Segments $segments -CurrentIndex 0
```plaintext
### Get-SegmentationState

Récupère un état de segmentation sauvegardé.

#### Syntaxe

```powershell
Get-SegmentationState -Id <String>
```plaintext
#### Paramètres

- **Id** : Identifiant unique de l'état de segmentation.

#### Valeur de retour

Un objet contenant l'état de segmentation, ou $null si l'état n'existe pas.

#### Exemple

```powershell
$id = "my-segmentation-task"
$state = Get-SegmentationState -Id $id
if ($state) {
    Write-Host "État récupéré. Segments: $($state.Segments.Count), Index: $($state.CurrentIndex)"
}
```plaintext
### Invoke-WithSegmentation

Traite une entrée avec segmentation automatique.

#### Syntaxe

```powershell
Invoke-WithSegmentation -Input <Object> -ScriptBlock <ScriptBlock> [-Id <String>] [-ChunkSizeKB <Int32>] [-PreserveLines] [-ContinueFromLastState]
```plaintext
#### Paramètres

- **Input** : L'entrée à traiter.
- **ScriptBlock** : Le script à exécuter pour chaque segment.
- **Id** : Identifiant unique pour sauvegarder l'état de segmentation.
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets.
- **PreserveLines** : Préserve les sauts de ligne lors de la segmentation de texte.
- **ContinueFromLastState** : Continue le traitement à partir du dernier état sauvegardé.

#### Valeur de retour

Un tableau contenant les résultats du traitement de chaque segment.

#### Exemple

```powershell
# Traiter un texte volumineux

$text = "A" * 50KB
$results = Invoke-WithSegmentation -Input $text -ScriptBlock {
    param($segment)
    # Traiter le segment

    return "Segment traité: $($segment.Length) caractères"
} -Id "text-processing" -ChunkSizeKB 5

# Traiter un fichier JSON volumineux et continuer en cas d'interruption

$results = Invoke-WithSegmentation -Input ".\data\large_data.json" -ScriptBlock {
    param($segment)
    # Traiter le segment

    return $segment | ConvertTo-Json -Depth 10
} -Id "json-processing" -ChunkSizeKB 5 -ContinueFromLastState
```plaintext
## Intégration avec d'autres modules

### Intégration avec Agent Auto

Le module `InputSegmentation` s'intègre avec Agent Auto via le script `Initialize-AgentAutoSegmentation.ps1` qui configure la segmentation automatique pour Agent Auto.

```powershell
# Initialiser la segmentation pour Agent Auto

.\development\scripts\agent-auto\Initialize-AgentAutoSegmentation.ps1 -Enable -MaxInputSizeKB 15 -ChunkSizeKB 7 -PreserveLines

# Utiliser la segmentation avec Agent Auto

$largeInput = Get-Content -Path ".\data\large_file.txt" -Raw
$result = .\development\scripts\agent-auto\Example-AgentAutoSegmentation.ps1 -Input $largeInput -InputType "Text" -OutputPath ".\output"
```plaintext
### Intégration avec le traitement parallèle

Le module `InputSegmentation` peut être combiné avec le traitement parallèle pour une efficacité maximale :

```powershell
Import-Module .\modules\InputSegmentation.psm1
. .\development\scripts\performance\Optimize-ParallelExecution.ps1

$input = Get-Content -Path ".\data\large_file.txt" -Raw
$segments = Split-Input -Input $input -ChunkSizeKB 5

$results = Optimize-ParallelExecution -Data $segments -ScriptBlock {
    param($segment)
    # Traiter le segment

    return "Processed: $($segment.Length) bytes"
} -MaxThreads 4
```plaintext
### Intégration avec le cache prédictif

Le module `InputSegmentation` peut être combiné avec le cache prédictif pour éviter de recalculer les segments :

```powershell
Import-Module .\modules\InputSegmentation.psm1
Import-Module .\modules\PredictiveCache.psm1

Initialize-PredictiveCache -Enabled $true -CachePath ".\cache" -ModelPath ".\models" -MaxCacheSize 100MB -DefaultTTL 3600

$input = Get-Content -Path ".\data\large_file.txt" -Raw
$inputHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($input))
$cacheKey = [System.BitConverter]::ToString($inputHash).Replace("-", "")

$segments = Get-PredictiveCache -Key $cacheKey
if ($segments -eq $null) {
    $segments = Split-Input -Input $input -ChunkSizeKB 5
    Set-PredictiveCache -Key $cacheKey -Value $segments
}

foreach ($segment in $segments) {
    # Traiter le segment

}
```plaintext
### Intégration avec les segmenteurs de formats

Le module `InputSegmentation` peut être étendu avec des segmenteurs spécifiques à certains formats via le module `FormatSegmentation` :

```powershell
Import-Module .\modules\InputSegmentation.psm1
Import-Module .\modules\FormatSegmentation.psm1

# Segmenter un document XML avec préservation de la structure

$xmlFile = ".\data\large_document.xml"
$segments = Split-FormatAwareInput -Input $xmlFile -Format "XML" -ChunkSizeKB 5 -PreserveStructure -XPathExpression "//items/item"

# Segmenter un document JSON avec préservation de la structure

$jsonFile = ".\data\large_data.json"
$segments = Split-FormatAwareInput -Input $jsonFile -Format "JSON" -ChunkSizeKB 5 -PreserveStructure

# Traiter un document avec segmentation automatique selon le format

$results = Invoke-WithFormatSegmentation -Input $largeDocument -Format "AUTO" -ScriptBlock {
    param($segment)
    # Traiter le segment

    return "Segment traité"
} -ChunkSizeKB 5 -PreserveStructure
```plaintext
## Bonnes pratiques

### Pour une segmentation efficace

1. **Choisissez la bonne taille de segment** : Une taille trop petite augmente le nombre de segments et le temps de traitement, tandis qu'une taille trop grande peut dépasser les limites des outils utilisés.

2. **Préservez la structure des données** : Utilisez l'option `-PreserveLines` pour les fichiers texte et CSV, et les segmenteurs de formats spécifiques pour les documents XML et JSON.

3. **Utilisez des identifiants uniques** : Lorsque vous utilisez `Invoke-WithSegmentation`, fournissez un identifiant unique pour pouvoir reprendre le traitement en cas d'interruption.

4. **Combinez avec d'autres optimisations** : Utilisez le traitement parallèle et le cache prédictif pour améliorer les performances.

5. **Gérez les erreurs** : Utilisez des blocs try/catch pour gérer les erreurs lors du traitement des segments et sauvegarder l'état pour une reprise ultérieure.

## Limitations

1. **Segmentation de JSON complexes** : La segmentation d'objets JSON très imbriqués peut ne pas préserver parfaitement la structure.

2. **Taille maximale des segments** : La taille maximale des segments est limitée par la mémoire disponible.

3. **Performances avec de très grands fichiers** : Le traitement de fichiers très volumineux (plusieurs Go) peut être lent et consommer beaucoup de mémoire.

## Exemples d'utilisation

### Exemple 1 : Traiter un fichier CSV volumineux

```powershell
Import-Module .\modules\InputSegmentation.psm1
Initialize-InputSegmentation -MaxInputSizeKB 100 -DefaultChunkSizeKB 50

$csvFile = ".\data\large_data.csv"
$segments = Split-FileInput -FilePath $csvFile -ChunkSizeKB 50 -PreserveLines

$results = @()
foreach ($segment in $segments) {
    # Convertir le segment en objet CSV

    $csvData = $segment | ConvertFrom-Csv
    
    # Traiter les données CSV

    foreach ($row in $csvData) {
        # Traitement...

        $results += $row
    }
}

Write-Host "Nombre total de lignes traitées: $($results.Count)"
```plaintext
### Exemple 2 : Appels API par lots

```powershell
Import-Module .\modules\InputSegmentation.psm1
Initialize-InputSegmentation -MaxInputSizeKB 50 -DefaultChunkSizeKB 10

$data = Get-Content -Path ".\data\api_requests.json" -Raw | ConvertFrom-Json
$segments = Split-JsonInput -JsonObject $data -ChunkSizeKB 10

$responses = @()
foreach ($segment in $segments) {
    # Convertir le segment en JSON

    $jsonData = $segment | ConvertTo-Json -Depth 10
    
    # Appeler l'API

    $response = Invoke-RestMethod -Uri "https://api.example.com/data" -Method Post -Body $jsonData -ContentType "application/json"
    $responses += $response
}

Write-Host "Nombre de requêtes API: $($segments.Count)"
Write-Host "Réponses reçues: $($responses.Count)"
```plaintext
### Exemple 3 : Traitement parallèle de fichiers volumineux

```powershell
Import-Module .\modules\InputSegmentation.psm1
. .\development\scripts\performance\Optimize-ParallelExecution.ps1

$files = Get-ChildItem -Path ".\data" -Filter "*.log" | Where-Object { $_.Length -gt 10MB }

foreach ($file in $files) {
    Write-Host "Traitement du fichier: $($file.Name)"
    
    $segments = Split-FileInput -FilePath $file.FullName -ChunkSizeKB 500 -PreserveLines
    
    $results = Optimize-ParallelExecution -Data $segments -ScriptBlock {
        param($segment)
        
        # Analyser le segment pour trouver des erreurs

        $errorLines = $segment -split "`n" | Where-Object { $_ -match "ERROR" }
        
        return $errorLines
    } -MaxThreads 4
    
    $errorCount = ($results | Measure-Object).Count
    Write-Host "Nombre d'erreurs trouvées: $errorCount"
}
```plaintext
## Auteur

EMAIL_SENDER_1 Team

## Version

1.0.0

## Date de création

2025-04-17
