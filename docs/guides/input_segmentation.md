# Guide de segmentation des entrées

## Introduction

La segmentation des entrées est une technique essentielle pour traiter efficacement de grandes quantités de données qui dépassent les limites de taille imposées par certains outils ou API. Le module `InputSegmenter` fournit des outils puissants pour segmenter automatiquement les entrées volumineuses en morceaux plus petits et gérables, tout en préservant leur structure et leur contexte.

Ce guide vous expliquera comment utiliser efficacement le module `InputSegmenter` pour gérer les entrées volumineuses dans vos projets.

## Prérequis

Avant de commencer, assurez-vous de disposer des éléments suivants :

- PowerShell 5.1 ou PowerShell 7+ installé
- Le module `InputSegmenter.psm1` disponible dans votre projet
- Connaissances de base sur les types de données (texte, JSON, fichiers)

## Installation et configuration

### Installation du module

Pour utiliser le module `InputSegmenter`, vous devez d'abord l'importer dans votre session PowerShell :

```powershell
# Importer le module
Import-Module -Path ".\modules\InputSegmenter.psm1" -Force
```

### Initialisation du module

Après avoir importé le module, vous devez l'initialiser avec les paramètres souhaités :

```powershell
# Initialisation avec les paramètres par défaut
Initialize-InputSegmentation

# Ou avec des paramètres personnalisés
Initialize-InputSegmentation -Enabled $true -MaxInputSizeKB 200 -SegmentSizeKB 100 -OverlapSizeKB 10 -StateStoragePath ".\data\segmentation"
```

Les paramètres disponibles sont :

- `Enabled` : Active ou désactive la segmentation des entrées (par défaut : $true)
- `MaxInputSizeKB` : Taille maximale d'entrée en kilo-octets avant segmentation (par défaut : 100)
- `SegmentSizeKB` : Taille de chaque segment en kilo-octets (par défaut : 50)
- `OverlapSizeKB` : Taille de chevauchement entre segments en kilo-octets (par défaut : 5)
- `StateStoragePath` : Chemin du dossier de stockage de l'état de segmentation (par défaut : ".\temp\segmentation")

## Concepts de base

### Pourquoi segmenter les entrées ?

La segmentation des entrées est nécessaire dans plusieurs cas :

1. **Limites de taille des API** : De nombreuses API imposent des limites sur la taille des requêtes.
2. **Traitement par lots** : Certains traitements sont plus efficaces lorsqu'ils sont effectués par lots.
3. **Gestion de la mémoire** : Éviter les problèmes de mémoire lors du traitement de grandes quantités de données.
4. **Parallélisation** : Permettre le traitement parallèle des segments pour améliorer les performances.

### Types de segmentation

Le module `InputSegmenter` prend en charge plusieurs types de segmentation :

1. **Segmentation de texte** : Divise un texte en segments plus petits, avec possibilité de préserver les paragraphes.
2. **Segmentation de JSON** : Divise un objet JSON en segments plus petits, avec possibilité de préserver la structure.
3. **Segmentation de fichiers** : Divise un fichier en segments plus petits, avec détection automatique du format.

## Utilisation de base

### Mesure de la taille des entrées

Avant de segmenter une entrée, vous pouvez mesurer sa taille pour déterminer si la segmentation est nécessaire :

```powershell
# Mesurer la taille d'une chaîne de caractères
$text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
$textSize = Measure-InputSize -Input $text -InputType "Text"

Write-Host "Taille du texte: $($textSize.SizeKB) KB"
Write-Host "Segmentation nécessaire: $($textSize.NeedsSegmentation)"

# Mesurer la taille d'un fichier
$fileSize = Measure-InputSize -Input ".\data\large_file.json" -InputType "File"

Write-Host "Taille du fichier: $($fileSize.SizeKB) KB"
Write-Host "Segmentation nécessaire: $($fileSize.NeedsSegmentation)"
```

Les paramètres disponibles sont :

- `Input` : L'entrée à mesurer (chaîne de caractères, objet JSON, fichier, etc.)
- `InputType` : Type d'entrée (Text, JSON, File, Object)

### Segmentation de texte

Pour segmenter un texte en morceaux plus petits, utilisez la fonction `Split-TextInput` :

```powershell
# Segmenter un texte
$text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
$segments = Split-TextInput -Text $text -SegmentSizeKB 10 -OverlapSizeKB 1 -PreserveParagraphs

Write-Host "Nombre de segments: $($segments.Count)"

# Afficher les premiers caractères de chaque segment
for ($i = 0; $i -lt $segments.Count; $i++) {
    $preview = $segments[$i].Substring(0, [Math]::Min(50, $segments[$i].Length))
    Write-Host "Segment $($i+1): $preview..."
}
```

Les paramètres disponibles sont :

- `Text` : Le texte à segmenter
- `SegmentSizeKB` : Taille de chaque segment en kilo-octets
- `OverlapSizeKB` : Taille de chevauchement entre segments en kilo-octets
- `PreserveParagraphs` : Préserve les paragraphes lors de la segmentation

### Segmentation de JSON

Pour segmenter un objet JSON en morceaux plus petits, utilisez la fonction `Split-JsonInput` :

```powershell
# Créer un objet JSON avec un grand tableau
$largeArray = @()
for ($i = 0; $i -lt 1000; $i++) {
    $largeArray += @{
        id = $i
        name = "Item $i"
        description = "Description of item $i"
    }
}
$jsonObject = @{
    items = $largeArray
    metadata = @{
        count = $largeArray.Count
        type = "test"
    }
}

# Segmenter l'objet JSON
$jsonSegments = Split-JsonInput -Json $jsonObject -SegmentSizeKB 10 -PreserveStructure -SplitArrays

Write-Host "Nombre de segments JSON: $($jsonSegments.Count)"

# Afficher la structure de chaque segment
for ($i = 0; $i -lt $jsonSegments.Count; $i++) {
    $segment = $jsonSegments[$i]
    $itemCount = if ($segment.items) { $segment.items.Count } else { 0 }
    Write-Host "Segment $($i+1): $itemCount items"
}
```

Les paramètres disponibles sont :

- `Json` : L'objet JSON à segmenter (chaîne de caractères ou objet déjà désérialisé)
- `SegmentSizeKB` : Taille de chaque segment en kilo-octets
- `PreserveStructure` : Préserve la structure JSON lors de la segmentation
- `SplitArrays` : Segmente les tableaux JSON
- `SplitObjects` : Segmente les objets JSON

### Segmentation de fichiers

Pour segmenter un fichier en morceaux plus petits, utilisez la fonction `Split-FileInput` :

```powershell
# Segmenter un fichier texte
$segmentFiles = Split-FileInput -FilePath ".\data\large_file.txt" -OutputDirectory ".\data\segments" -SegmentSizeKB 50 -DetectFormat

Write-Host "Nombre de fichiers de segments créés: $($segmentFiles.Count)"

# Afficher les chemins des fichiers de segments
foreach ($segmentFile in $segmentFiles) {
    Write-Host "Fichier de segment: $segmentFile"
}
```

Les paramètres disponibles sont :

- `FilePath` : Chemin du fichier à segmenter
- `OutputDirectory` : Dossier de sortie pour les segments
- `SegmentSizeKB` : Taille de chaque segment en kilo-octets
- `OverlapSizeKB` : Taille de chevauchement entre segments en kilo-octets
- `DetectFormat` : Détecte automatiquement le format du fichier et utilise la méthode de segmentation appropriée

### Segmentation générique

Pour segmenter une entrée en fonction de son type, utilisez la fonction `Split-Input` :

```powershell
# Segmenter une entrée (type détecté automatiquement)
$input = Get-Content -Path ".\data\large_file.json" -Raw
$segments = Split-Input -Input $input -SegmentSizeKB 50 -PreserveStructure

Write-Host "Nombre de segments: $($segments.Count)"

# Segmenter un fichier
$fileSegments = Split-Input -Input ".\data\large_file.csv" -InputType "File" -OutputDirectory ".\data\segments" -SegmentSizeKB 100

Write-Host "Nombre de fichiers de segments créés: $($fileSegments.Count)"
```

Les paramètres disponibles sont :

- `Input` : L'entrée à segmenter (chaîne de caractères, objet JSON, fichier, etc.)
- `InputType` : Type d'entrée (Text, JSON, File, Object)
- `SegmentSizeKB` : Taille de chaque segment en kilo-octets
- `OverlapSizeKB` : Taille de chevauchement entre segments en kilo-octets
- `OutputDirectory` : Dossier de sortie pour les segments de fichiers
- `PreserveStructure` : Préserve la structure lors de la segmentation

## Exemples avancés

### Exemple 1 : Gestion de l'état de segmentation

Vous pouvez sauvegarder et récupérer l'état de segmentation pour une utilisation ultérieure :

```powershell
# Segmenter un texte
$text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
$segments = Split-TextInput -Text $text -SegmentSizeKB 10

# Créer un état de segmentation
$state = @{
    OriginalInput = $text
    Segments = $segments
    CurrentSegmentIndex = 0
    TotalSegments = $segments.Count
    Timestamp = Get-Date
}

# Sauvegarder l'état
$stateId = Save-SegmentationState -State $state -StoragePath ".\data\segmentation_states"

Write-Host "État de segmentation sauvegardé avec l'ID: $stateId"

# Récupérer l'état
$retrievedState = Get-SegmentationState -StateId $stateId -StoragePath ".\data\segmentation_states"

if ($retrievedState) {
    Write-Host "État de segmentation récupéré"
    Write-Host "Nombre total de segments: $($retrievedState.TotalSegments)"
    Write-Host "Segment actuel: $($retrievedState.CurrentSegmentIndex + 1)"
    
    # Utiliser le segment actuel
    $currentSegment = $retrievedState.Segments[$retrievedState.CurrentSegmentIndex]
    Write-Host "Taille du segment actuel: $([Math]::Round((([System.Text.Encoding]::UTF8.GetBytes($currentSegment)).Length / 1024), 2)) KB"
}
```

### Exemple 2 : Traitement par lots avec segmentation

Vous pouvez utiliser la fonction `Invoke-WithSegmentation` pour exécuter un bloc de script sur chaque segment :

```powershell
# Fonction de traitement qui compte les mots dans un texte
function Count-Words {
    param (
        [string]$Text
    )
    
    $words = $Text -split '\W+' | Where-Object { $_ -ne '' }
    return $words.Count
}

# Texte volumineux
$text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000

# Compter les mots avec segmentation
$wordCounts = Invoke-WithSegmentation -Input $text -ScriptBlock {
    param($segment)
    return Count-Words -Text $segment
} -InputType "Text" -SegmentSizeKB 10 -CombineResults

Write-Host "Nombre total de mots: $wordCounts"

# Traitement plus complexe avec JSON
$largeJson = @{
    items = 1..1000 | ForEach-Object {
        @{
            id = $_
            name = "Item $_"
            value = $_ * 10
        }
    }
}

# Calculer la somme des valeurs
$results = Invoke-WithSegmentation -Input $largeJson -ScriptBlock {
    param($segment)
    
    $sum = 0
    if ($segment.items) {
        foreach ($item in $segment.items) {
            $sum += $item.value
        }
    }
    
    return $sum
} -InputType "JSON" -SegmentSizeKB 10 -PreserveStructure

$totalSum = ($results | Measure-Object -Sum).Sum
Write-Host "Somme totale des valeurs: $totalSum"
```

Les paramètres disponibles sont :

- `Input` : L'entrée à segmenter et à traiter
- `ScriptBlock` : Le bloc de script à exécuter sur chaque segment
- `InputType` : Type d'entrée (Text, JSON, File, Object)
- `SegmentSizeKB` : Taille de chaque segment en kilo-octets
- `OverlapSizeKB` : Taille de chevauchement entre segments en kilo-octets
- `PreserveStructure` : Préserve la structure lors de la segmentation
- `CombineResults` : Combine les résultats de chaque segment en un seul résultat
- `ContinueOnError` : Continue l'exécution même si une erreur se produit lors du traitement d'un segment

### Exemple 3 : Traitement parallèle avec segmentation

Vous pouvez combiner la segmentation avec le traitement parallèle pour améliorer les performances :

```powershell
# Fonction de traitement qui simule un traitement intensif
function Process-Data {
    param (
        [string]$Data
    )
    
    # Simuler un traitement intensif
    Start-Sleep -Milliseconds 500
    
    # Compter les caractères
    return $Data.Length
}

# Créer des données volumineuses
$data = "X" * 1000000  # Environ 1 MB de données

# Mesurer la taille des données
$dataSize = Measure-InputSize -Input $data -InputType "Text"
Write-Host "Taille des données: $($dataSize.SizeKB) KB"

# Traitement séquentiel avec segmentation
Write-Host "`nTraitement séquentiel avec segmentation:"
$startTime = Get-Date
$results = Invoke-WithSegmentation -Input $data -ScriptBlock {
    param($segment)
    return Process-Data -Data $segment
} -InputType "Text" -SegmentSizeKB 100
$totalProcessed = ($results | Measure-Object -Sum).Sum
$endTime = Get-Date
$sequentialTime = ($endTime - $startTime).TotalSeconds

Write-Host "Nombre total de caractères traités: $totalProcessed"
Write-Host "Temps d'exécution: $sequentialTime secondes"
Write-Host "Nombre de segments traités: $($results.Count)"

# Traitement parallèle avec segmentation
Write-Host "`nTraitement parallèle avec segmentation:"
$startTime = Get-Date

# Segmenter les données
$segments = Split-TextInput -Text $data -SegmentSizeKB 100

# Traiter les segments en parallèle
$parallelResults = $segments | ForEach-Object -Parallel {
    # Importer la fonction dans le runspace
    function Process-Data {
        param (
            [string]$Data
        )
        
        # Simuler un traitement intensif
        Start-Sleep -Milliseconds 500
        
        # Compter les caractères
        return $Data.Length
    }
    
    # Traiter le segment
    Process-Data -Data $_
} -ThrottleLimit 10

$totalProcessedParallel = ($parallelResults | Measure-Object -Sum).Sum
$endTime = Get-Date
$parallelTime = ($endTime - $startTime).TotalSeconds

Write-Host "Nombre total de caractères traités: $totalProcessedParallel"
Write-Host "Temps d'exécution: $parallelTime secondes"
Write-Host "Nombre de segments traités: $($segments.Count)"
Write-Host "Accélération: $([Math]::Round($sequentialTime / $parallelTime, 2))x"
```

### Exemple 4 : Intégration avec une API externe

Vous pouvez utiliser la segmentation pour interagir avec des API qui imposent des limites de taille :

```powershell
# Fonction simulant un appel à une API externe avec une limite de taille
function Invoke-ExternalAPI {
    param (
        [string]$Data,
        [int]$MaxSizeKB = 2
    )
    
    # Vérifier la taille des données
    $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
    $dataSizeKB = $dataBytes.Length / 1024
    
    if ($dataSizeKB -gt $MaxSizeKB) {
        Write-Error "Les données dépassent la taille maximale autorisée de $MaxSizeKB KB (taille actuelle: $([Math]::Round($dataSizeKB, 2)) KB)"
        return $null
    }
    
    # Simuler un traitement par l'API
    Start-Sleep -Milliseconds 200
    
    # Retourner un résultat simulé
    return @{
        status = "success"
        processed_size_kb = $dataSizeKB
        word_count = ($Data -split '\W+').Count
        character_count = $Data.Length
    }
}

# Créer un texte volumineux
$text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 100

# Mesurer la taille du texte
$textSize = Measure-InputSize -Input $text -InputType "Text"
Write-Host "Taille du texte: $($textSize.SizeKB) KB"

# Essayer d'appeler l'API directement (devrait échouer)
Write-Host "`nAppel direct à l'API (sans segmentation):"
try {
    $result = Invoke-ExternalAPI -Data $text
    Write-Host "Résultat: $($result | ConvertTo-Json -Compress)"
} catch {
    Write-Host "Erreur: $_"
}

# Appeler l'API avec segmentation
Write-Host "`nAppel à l'API avec segmentation:"
$apiResults = Invoke-WithSegmentation -Input $text -ScriptBlock {
    param($segment)
    return Invoke-ExternalAPI -Data $segment
} -InputType "Text" -SegmentSizeKB 2 -ContinueOnError

# Afficher les résultats
Write-Host "Nombre d'appels à l'API: $($apiResults.Count)"

$totalWords = 0
$totalChars = 0

foreach ($result in $apiResults) {
    $totalWords += $result.word_count
    $totalChars += $result.character_count
}

Write-Host "Nombre total de mots traités: $totalWords"
Write-Host "Nombre total de caractères traités: $totalChars"

# Calculer les statistiques
$averageSize = ($apiResults | Measure-Object -Property processed_size_kb -Average).Average
Write-Host "Taille moyenne des segments: $([Math]::Round($averageSize, 2)) KB"
```

## Intégration avec d'autres modules

### Intégration avec le module MCPManager

Vous pouvez intégrer le module `InputSegmenter` avec le module `MCPManager` pour traiter des entrées volumineuses avec MCP :

```powershell
# Importer les modules
Import-Module -Path ".\modules\InputSegmenter.psm1" -Force
Import-Module -Path ".\modules\MCPManager.psm1" -Force

# Initialiser les modules
Initialize-InputSegmentation
Initialize-MCPManager

# Démarrer un serveur MCP local
$server = Start-MCPServer -ServerType "local" -Port 8000 -Wait

if ($server.Status -eq "running") {
    Write-Host "Serveur MCP démarré avec succès: $($server.Url)"
    
    # Créer un texte volumineux
    $text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
    
    # Segmenter le texte
    $segments = Split-TextInput -Text $text -SegmentSizeKB 10
    
    Write-Host "Nombre de segments: $($segments.Count)"
    
    # Traiter chaque segment avec MCP
    $results = @()
    foreach ($segment in $segments) {
        $result = Invoke-MCPCommand -Command "process_text" -Parameters @{ 
            text = $segment
        } -ServerType "local" -Port 8000
        
        $results += $result
    }
    
    Write-Host "Résultats du traitement: $($results.Count) segments traités"
    
    # Arrêter le serveur
    $stopped = Stop-MCPServer -ServerType "local" -Port 8000
    
    if ($stopped) {
        Write-Host "Serveur MCP arrêté avec succès"
    } else {
        Write-Host "Erreur lors de l'arrêt du serveur MCP"
    }
} else {
    Write-Host "Erreur lors du démarrage du serveur MCP: $($server.Error)"
}
```

## Dépannage

### Problème : Segmentation incorrecte du texte

Si la segmentation du texte ne préserve pas correctement les paragraphes ou les phrases, utilisez le paramètre `PreserveParagraphs` :

```powershell
$segments = Split-TextInput -Text $text -SegmentSizeKB 10 -PreserveParagraphs
```

### Problème : Segmentation incorrecte du JSON

Si la segmentation du JSON ne préserve pas correctement la structure, utilisez le paramètre `PreserveStructure` :

```powershell
$jsonSegments = Split-JsonInput -Json $jsonObject -SegmentSizeKB 10 -PreserveStructure
```

### Problème : Erreurs lors de la segmentation de fichiers

Si vous rencontrez des erreurs lors de la segmentation de fichiers, vérifiez que vous avez les droits d'écriture dans le dossier de sortie et que le chemin est valide.

## Bonnes pratiques

- **Adaptez la taille des segments** à vos besoins spécifiques. Une taille trop petite peut entraîner un surcoût de traitement, tandis qu'une taille trop grande peut dépasser les limites.
- **Utilisez le chevauchement** pour préserver le contexte entre les segments, en particulier pour le traitement de texte.
- **Préservez la structure** lors de la segmentation de données structurées comme JSON.
- **Sauvegardez l'état de segmentation** pour les traitements longs ou susceptibles d'être interrompus.
- **Combinez avec le traitement parallèle** pour améliorer les performances sur les grands volumes de données.
- **Testez avec des données réelles** pour vous assurer que la segmentation fonctionne correctement dans votre cas d'utilisation.

## FAQ

### Quelle est la différence entre Split-TextInput, Split-JsonInput et Split-FileInput ?

- `Split-TextInput` est spécifique à la segmentation de texte et offre des options comme la préservation des paragraphes.
- `Split-JsonInput` est spécifique à la segmentation d'objets JSON et offre des options comme la préservation de la structure.
- `Split-FileInput` est spécifique à la segmentation de fichiers et peut détecter automatiquement le format du fichier.

### Comment choisir la taille optimale des segments ?

La taille optimale des segments dépend de plusieurs facteurs :

1. **Limites de l'API ou de l'outil** : Respectez les limites imposées par l'API ou l'outil que vous utilisez.
2. **Nature des données** : Pour le texte, essayez de préserver les paragraphes ou les phrases. Pour JSON, essayez de préserver la structure.
3. **Performances** : Des segments trop petits peuvent entraîner un surcoût de traitement, tandis que des segments trop grands peuvent être inefficaces.
4. **Mémoire disponible** : Assurez-vous que les segments peuvent être traités avec la mémoire disponible.

En général, commencez avec une taille de segment de 50-100 KB et ajustez en fonction de vos besoins.

### Comment gérer les erreurs lors du traitement des segments ?

Vous pouvez utiliser le paramètre `ContinueOnError` avec la fonction `Invoke-WithSegmentation` pour continuer le traitement même si une erreur se produit lors du traitement d'un segment :

```powershell
$results = Invoke-WithSegmentation -Input $data -ScriptBlock {
    param($segment)
    # Traitement qui peut échouer
    return Process-Data -Data $segment
} -InputType "Text" -SegmentSizeKB 10 -ContinueOnError
```

Vous pouvez également implémenter votre propre gestion des erreurs dans le bloc de script :

```powershell
$results = Invoke-WithSegmentation -Input $data -ScriptBlock {
    param($segment)
    try {
        return Process-Data -Data $segment
    } catch {
        Write-Warning "Erreur lors du traitement du segment: $_"
        return $null
    }
} -InputType "Text" -SegmentSizeKB 10
```

### Comment combiner les résultats du traitement des segments ?

Vous pouvez utiliser le paramètre `CombineResults` avec la fonction `Invoke-WithSegmentation` pour combiner automatiquement les résultats :

```powershell
$combinedResult = Invoke-WithSegmentation -Input $data -ScriptBlock {
    param($segment)
    return Process-Data -Data $segment
} -InputType "Text" -SegmentSizeKB 10 -CombineResults
```

Vous pouvez également implémenter votre propre logique de combinaison :

```powershell
$results = Invoke-WithSegmentation -Input $data -ScriptBlock {
    param($segment)
    return Process-Data -Data $segment
} -InputType "Text" -SegmentSizeKB 10

# Combiner les résultats
$combinedResult = $results | Measure-Object -Sum | Select-Object -ExpandProperty Sum
```

## Ressources supplémentaires

- [Documentation API du module InputSegmenter](../api/InputSegmenter.html)
- [Exemples d'utilisation du module InputSegmenter](../api/examples/InputSegmenter_Examples.html)
- [Documentation technique sur la segmentation des entrées](../technical/InputSegmenter.md)
- [Guide d'intégration MCP](mcp_integration.md)
