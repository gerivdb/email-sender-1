# Module de segmentation d'entrées

## Vue d'ensemble

Le module `InputSegmentation` fournit des fonctionnalités pour segmenter automatiquement les entrées volumineuses en morceaux plus petits, évitant ainsi les interruptions dues aux limites de taille d'entrée. Ce module est particulièrement utile pour les interactions avec Agent Auto et d'autres systèmes ayant des contraintes de taille d'entrée.

## Installation

Le module est disponible dans le dossier `modules` du projet. Pour l'importer :

```powershell
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\InputSegmentation.psm1"
Import-Module $modulePath -Force
```

## Initialisation

Avant d'utiliser le module, il est recommandé de l'initialiser avec les paramètres souhaités :

```powershell
Initialize-InputSegmentation -MaxInputSizeKB 15 -DefaultChunkSizeKB 7
```

## Fonctions principales

### Measure-InputSize

Mesure la taille d'une entrée en kilooctets.

#### Syntaxe

```powershell
Measure-InputSize -Input <Object>
```

#### Paramètres

- **Input** : L'entrée à mesurer (texte, JSON ou chemin de fichier).

#### Valeur de retour

La taille de l'entrée en kilooctets (KB).

#### Exemple

```powershell
$text = "A" * 10KB
$size = Measure-InputSize -Input $text
Write-Host "Taille de l'entrée: $size KB"
```

### Split-TextInput

Segmente une chaîne de texte en morceaux plus petits.

#### Syntaxe

```powershell
Split-TextInput -Text <String> [-ChunkSizeKB <Int32>] [-PreserveLines]
```

#### Paramètres

- **Text** : Le texte à segmenter.
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets.
- **PreserveLines** : Préserve les sauts de ligne lors de la segmentation.

#### Valeur de retour

Un tableau de chaînes de texte représentant les segments.

#### Exemple

```powershell
$text = "A" * 20KB
$segments = Split-TextInput -Text $text -ChunkSizeKB 5 -PreserveLines
Write-Host "Nombre de segments: $($segments.Count)"
```

### Split-JsonInput

Segmente un objet JSON en morceaux plus petits.

#### Syntaxe

```powershell
Split-JsonInput -JsonObject <Object> [-ChunkSizeKB <Int32>]
```

#### Paramètres

- **JsonObject** : L'objet JSON à segmenter.
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets.

#### Valeur de retour

Un tableau d'objets JSON représentant les segments.

#### Exemple

```powershell
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

### Split-FileInput

Segmente un fichier en morceaux plus petits.

#### Syntaxe

```powershell
Split-FileInput -FilePath <String> [-ChunkSizeKB <Int32>] [-PreserveLines]
```

#### Paramètres

- **FilePath** : Chemin du fichier à segmenter.
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets.
- **PreserveLines** : Préserve les sauts de ligne lors de la segmentation.

#### Valeur de retour

Un tableau de chaînes de texte représentant les segments.

#### Exemple

```powershell
$segments = Split-FileInput -FilePath ".\data\large_file.txt" -ChunkSizeKB 5 -PreserveLines
Write-Host "Nombre de segments: $($segments.Count)"
```

### Split-Input

Fonction générique pour segmenter différents types d'entrées.

#### Syntaxe

```powershell
Split-Input -Input <Object> [-ChunkSizeKB <Int32>] [-PreserveLines]
```

#### Paramètres

- **Input** : L'entrée à segmenter (texte, JSON ou chemin de fichier).
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets.
- **PreserveLines** : Préserve les sauts de ligne lors de la segmentation de texte.

#### Valeur de retour

Un tableau d'objets représentant les segments.

#### Exemple

```powershell
$input = Get-Content -Path ".\data\large_file.txt" -Raw
$segments = Split-Input -Input $input -ChunkSizeKB 5
Write-Host "Nombre de segments: $($segments.Count)"
```

### Save-SegmentationState et Get-SegmentationState

Fonctions pour sauvegarder et récupérer l'état de segmentation, permettant de reprendre le traitement.

#### Syntaxe

```powershell
Save-SegmentationState -Id <String> -Segments <Array> -CurrentIndex <Int32>
$state = Get-SegmentationState -Id <String>
```

#### Paramètres

- **Id** : Identifiant unique pour l'état de segmentation.
- **Segments** : Tableau des segments.
- **CurrentIndex** : Index du segment actuel.

#### Exemple

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

### Invoke-WithSegmentation

Exécute un script avec segmentation automatique.

#### Syntaxe

```powershell
Invoke-WithSegmentation -Input <Object> -ScriptBlock <ScriptBlock> [-Id <String>] [-ChunkSizeKB <Int32>] [-PreserveLines]
```

#### Paramètres

- **Input** : L'entrée à segmenter.
- **ScriptBlock** : Le script à exécuter pour chaque segment.
- **Id** : Identifiant unique pour l'état de segmentation.
- **ChunkSizeKB** : Taille maximale de chaque segment en kilooctets.
- **PreserveLines** : Préserve les sauts de ligne lors de la segmentation de texte.

#### Valeur de retour

Un tableau des résultats de l'exécution du script pour chaque segment.

#### Exemple

```powershell
$input = "A" * 20KB
$results = Invoke-WithSegmentation -Input $input -ScriptBlock {
    param($segment)
    return "Processed: $($segment.Length) bytes"
} -Id "my-task" -ChunkSizeKB 5
```

## Intégration avec Agent Auto

Le module `InputSegmentation` s'intègre avec Agent Auto via le script `Initialize-AgentAutoSegmentation.ps1` qui configure la segmentation automatique pour Agent Auto.

### Exemple d'utilisation avec Agent Auto

```powershell
# Initialiser la segmentation pour Agent Auto
& ".\scripts\agent-auto\Initialize-AgentAutoSegmentation.ps1" -Enable -MaxInputSizeKB 15 -ChunkSizeKB 7 -PreserveLines

# Utiliser la segmentation avec Agent Auto
$largeInput = Get-Content -Path ".\data\large_file.txt" -Raw
$result = & ".\scripts\agent-auto\Example-AgentAutoSegmentation.ps1" -Input $largeInput -InputType "Text"
```

## Performance

Les performances du module dépendent de la taille et du type des entrées :

- **Texte** : Segmentation rapide, même pour de grandes entrées.
- **JSON** : La segmentation peut être plus lente pour les objets JSON complexes.
- **Fichiers** : La performance dépend de la taille du fichier et des opérations d'E/S.

## Compatibilité

- PowerShell 5.1 et versions ultérieures.
- Compatible avec PowerShell 7.

## Limitations connues

- La segmentation d'objets JSON complexes peut ne pas préserver toutes les relations entre les objets.
- Les fichiers très volumineux (> 1 GB) peuvent entraîner des problèmes de mémoire.

## Exemples avancés

### Traitement parallèle des segments

```powershell
$input = Get-Content -Path ".\data\large_file.txt" -Raw
$segments = Split-Input -Input $input -ChunkSizeKB 5

# Créer un runspace pool
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
$runspacePool.Open()

# Créer les runspaces
$runspaces = @()
foreach ($segment in $segments) {
    $powershell = [powershell]::Create().AddScript({
        param($segment)
        # Traiter le segment
        return "Processed: $($segment.Length) bytes"
    }).AddArgument($segment)
    
    $powershell.RunspacePool = $runspacePool
    
    $runspaces += [PSCustomObject]@{
        PowerShell = $powershell
        Handle = $powershell.BeginInvoke()
    }
}

# Récupérer les résultats
$results = @()
foreach ($runspace in $runspaces) {
    $results += $runspace.PowerShell.EndInvoke($runspace.Handle)
    $runspace.PowerShell.Dispose()
}

# Fermer le runspace pool
$runspacePool.Close()
$runspacePool.Dispose()
```

### Segmentation avec préservation du contexte

```powershell
$json = @{
    metadata = @{
        title = "Test"
        description = "Description de test"
    }
    items = @()
}

for ($i = 0; $i -lt 500; $i++) {
    $json.items += @{
        id = $i
        name = "Item $i"
    }
}

# Segmenter l'objet JSON en préservant les métadonnées
$segments = Split-JsonInput -JsonObject $json -ChunkSizeKB 5

# Vérifier que chaque segment contient les métadonnées
foreach ($segment in $segments) {
    if ($segment.metadata.title -ne "Test") {
        Write-Error "Les métadonnées n'ont pas été préservées correctement."
    }
}
```
