# Guide d'utilisation : Segmentation d'entrées

## Introduction

Ce guide explique comment utiliser les fonctionnalités de segmentation d'entrées pour traiter efficacement des données volumineuses avec Agent Auto et d'autres systèmes ayant des contraintes de taille d'entrée.

## Pourquoi segmenter les entrées ?

La segmentation d'entrées est utile dans plusieurs situations :

- **Limites de taille d'API** : De nombreuses API ont des limites sur la taille des requêtes.
- **Traitement de grands fichiers** : Les fichiers volumineux peuvent être difficiles à traiter en une seule fois.
- **Optimisation de la mémoire** : La segmentation permet de réduire l'utilisation de la mémoire.
- **Reprise sur erreur** : Si une partie échoue, seule cette partie doit être retraitée.

### Limites spécifiques d'Augment Code

Augment Code impose certaines limites sur la taille des inputs :

- **Limite stricte** : 5KB par input
- **Recommandation pratique** : 4KB par appel d'outil pour éviter les problèmes
- **Fenêtre de contexte** : 200 000 tokens (bien plus grande que la plupart des concurrents)
- **Guidelines** : Limitées à 2000 caractères maximum

Ces limitations rendent la segmentation d'entrées particulièrement importante pour travailler efficacement avec Augment Code, surtout pour les tâches complexes ou les modifications impliquant plusieurs fichiers.

## Installation

Aucune installation spéciale n'est requise. Les scripts de segmentation d'entrées sont inclus dans le projet.

## Configuration pour Agent Auto

Pour configurer la segmentation automatique pour Agent Auto :

1. Ouvrez PowerShell.
2. Exécutez le script d'initialisation :

```powershell
.\scripts\agent-auto\Initialize-AgentAutoSegmentation.ps1 -Enable -MaxInputSizeKB 15 -ChunkSizeKB 7
```

3. Cette commande activera la segmentation automatique avec une taille maximale d'entrée de 15 KB et une taille de segment de 7 KB.

## Utilisation de base

### Segmenter un texte

Pour segmenter une chaîne de texte volumineuse :

```powershell
Import-Module .\modules\InputSegmentation.psm1
Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5

$text = "A" * 20KB  # Texte de 20 KB
$segments = Split-TextInput -Text $text -ChunkSizeKB 5

Write-Host "Nombre de segments: $($segments.Count)"
```

### Segmenter un objet JSON

Pour segmenter un objet JSON volumineux :

```powershell
Import-Module .\modules\InputSegmentation.psm1
Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5

$json = @{
    items = @()
}

for ($i = 0; $i -lt 500; $i++) {
    $json.items += @{
        id = $i
        name = "Item $i"
    }
}

$segments = Split-JsonInput -JsonObject $json -ChunkSizeKB 5

Write-Host "Nombre de segments: $($segments.Count)"
```

### Segmenter un fichier

Pour segmenter un fichier volumineux :

```powershell
Import-Module .\modules\InputSegmentation.psm1
Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5

$segments = Split-FileInput -FilePath ".\data\large_file.txt" -ChunkSizeKB 5

Write-Host "Nombre de segments: $($segments.Count)"
```

### Utiliser la fonction générique

Pour segmenter automatiquement différents types d'entrées :

```powershell
Import-Module .\modules\InputSegmentation.psm1
Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5

$input = Get-Content -Path ".\data\large_file.txt" -Raw
$segments = Split-Input -Input $input -ChunkSizeKB 5

Write-Host "Nombre de segments: $($segments.Count)"
```

## Options avancées

### Préserver les sauts de ligne

Pour segmenter un texte en préservant les sauts de ligne :

```powershell
$text = "Ligne 1`nLigne 2`nLigne 3" * 1KB
$segments = Split-TextInput -Text $text -ChunkSizeKB 5 -PreserveLines
```

Cette option garantit que les segments se terminent par des sauts de ligne complets.

### Exécuter un script avec segmentation

Pour exécuter un script sur chaque segment d'une entrée volumineuse :

```powershell
$input = "A" * 20KB
$results = Invoke-WithSegmentation -Input $input -ScriptBlock {
    param($segment)
    return "Processed: $($segment.Length) bytes"
} -Id "my-task" -ChunkSizeKB 5
```

### Sauvegarder et récupérer l'état de segmentation

Pour sauvegarder l'état de segmentation et le récupérer plus tard :

```powershell
$id = "my-segmentation-task"
$segments = Split-Input -Input $largeInput -ChunkSizeKB 5
Save-SegmentationState -Id $id -Segments $segments -CurrentIndex 0

# Plus tard, récupérer l'état
$state = Get-SegmentationState -Id $id
if ($state) {
    $currentIndex = $state.CurrentIndex
    $segments = $state.Segments

    # Continuer le traitement à partir de l'index actuel
    for ($i = $currentIndex; $i -lt $segments.Count; $i++) {
        # Traiter le segment
        Process-Segment -Segment $segments[$i]

        # Mettre à jour l'état
        Save-SegmentationState -Id $id -Segments $segments -CurrentIndex ($i + 1)
    }
}
```

## Exemples pratiques

### Exemple 1 : Traiter un fichier CSV volumineux

Supposons que vous avez un fichier CSV volumineux que vous devez traiter :

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
```

### Exemple 2 : Appels API avec segmentation

Si vous devez envoyer des données volumineuses à une API avec une limite de taille :

```powershell
Import-Module .\modules\InputSegmentation.psm1
Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5

$data = @{
    items = @()
}

for ($i = 0; $i -lt 1000; $i++) {
    $data.items += @{
        id = $i
        name = "Item $i"
        value = "Value $i"
    }
}

$segments = Split-JsonInput -JsonObject $data -ChunkSizeKB 5

$responses = @()
foreach ($segment in $segments) {
    # Convertir le segment en JSON
    $jsonData = $segment | ConvertTo-Json -Compress

    # Envoyer à l'API
    $response = Invoke-RestMethod -Uri "https://api.example.com/data" -Method Post -Body $jsonData -ContentType "application/json"
    $responses += $response
}

Write-Host "Nombre de requêtes API: $($segments.Count)"
Write-Host "Réponses reçues: $($responses.Count)"
```

### Exemple 3 : Utilisation avec Agent Auto

Pour utiliser la segmentation avec Agent Auto :

```powershell
# Initialiser la segmentation pour Agent Auto
.\scripts\agent-auto\Initialize-AgentAutoSegmentation.ps1 -Enable -MaxInputSizeKB 15 -ChunkSizeKB 7 -PreserveLines

# Utiliser la segmentation avec Agent Auto
$largeInput = Get-Content -Path ".\data\large_file.txt" -Raw
$result = .\scripts\agent-auto\Example-AgentAutoSegmentation.ps1 -Input $largeInput -InputType "Text" -OutputPath ".\output"
```

## Bonnes pratiques

### Pour une segmentation efficace

1. **Choisissez la bonne taille de segment** : Une taille trop petite augmente la surcharge, une taille trop grande peut dépasser les limites.
2. **Préservez les sauts de ligne** pour les données textuelles structurées.
3. **Utilisez des IDs uniques** pour les tâches de segmentation afin d'éviter les conflits.
4. **Sauvegardez régulièrement l'état** pour les traitements longs.
5. **Vérifiez la taille des entrées** avant de les traiter pour éviter les erreurs.

### Pour l'intégration avec Agent Auto

1. **Configurez des limites appropriées** en fonction des capacités de votre système.
2. **Testez avec des données réelles** pour vérifier que la segmentation fonctionne correctement.
3. **Surveillez les performances** pour ajuster les paramètres si nécessaire.

## Dépannage

### Problème : Segments incorrects

**Solution** : Vérifiez si l'option `-PreserveLines` est nécessaire pour votre type de données.

### Problème : Erreurs de mémoire

**Solution** : Réduisez la taille des segments et traitez-les séquentiellement plutôt qu'en parallèle.

### Problème : Perte de contexte entre les segments

**Solution** : Pour les objets JSON, assurez-vous que les métadonnées importantes sont incluses dans chaque segment.

### Problème : Erreur "Input trop volumineux" dans Augment Code

**Solution** :
- Divisez votre requête en plusieurs requêtes plus petites et spécifiques
- Structurez le code de manière claire et utilisez des listes de tâches numérotées
- Fournissez des exemples concrets pour les modifications souhaitées
- Utilisez l'approche "une fonction à la fois" pour les modifications complexes

## Intégration avec d'autres outils

### Intégration avec le traitement parallèle

Vous pouvez combiner la segmentation avec le traitement parallèle pour une efficacité maximale :

```powershell
Import-Module .\modules\InputSegmentation.psm1
. .\scripts\performance\Optimize-ParallelExecution.ps1

$input = Get-Content -Path ".\data\large_file.txt" -Raw
$segments = Split-Input -Input $input -ChunkSizeKB 5

$results = Optimize-ParallelExecution -Data $segments -ScriptBlock {
    param($segment)
    # Traiter le segment
    return "Processed: $($segment.Length) bytes"
} -MaxThreads 4
```

### Intégration avec le cache prédictif

Vous pouvez mettre en cache les résultats de segmentation pour éviter de recalculer les segments :

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
```

## Conclusion

La segmentation d'entrées est un outil puissant pour traiter des données volumineuses de manière efficace. En utilisant les fonctionnalités de segmentation, vous pouvez surmonter les limites de taille et optimiser les performances de vos scripts.

Pour plus d'informations techniques, consultez la [documentation technique du module InputSegmentation](../technical/InputSegmentation.md).
