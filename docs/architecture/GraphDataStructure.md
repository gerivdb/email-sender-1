# Structure de données pour la représentation des graphes

## Introduction

Ce document définit la structure de données utilisée pour représenter les graphes dans le module `CycleDetector.psm1`. Une conception efficace de cette structure est essentielle pour les performances et la flexibilité du module.

## Représentation des graphes

### Structure principale

Les graphes sont représentés à l'aide de tables de hachage (hashtables) PowerShell, où :
- Les **clés** sont les identifiants des nœuds
- Les **valeurs** sont des tableaux contenant les identifiants des nœuds adjacents (voisins)

Cette représentation est connue sous le nom de **liste d'adjacence**.

### Exemple de graphe simple

```
A → B → C
↓   ↑
D → E
```

Ce graphe serait représenté par la table de hachage suivante :

```powershell
$graph = @{
    "A" = @("B", "D")
    "B" = @("C")
    "C" = @()
    "D" = @("E")
    "E" = @("B")
}
```

### Avantages de cette représentation

1. **Efficacité spatiale** : Pour les graphes clairsemés (peu d'arêtes par rapport au nombre de nœuds), cette représentation est économe en mémoire.
2. **Accès rapide** : L'accès aux voisins d'un nœud est en O(1).
3. **Simplicité** : Structure native de PowerShell, facile à manipuler.
4. **Flexibilité** : Peut représenter des graphes dirigés et non dirigés.

### Inconvénients

1. **Vérification d'arête** : Vérifier l'existence d'une arête spécifique est en O(d) où d est le degré du nœud.
2. **Suppression d'arête** : La suppression d'une arête nécessite de recréer le tableau de voisins.

## Types de graphes supportés

### Graphes dirigés

Les graphes dirigés sont représentés naturellement par cette structure. Une arête de A vers B est représentée par la présence de B dans la liste des voisins de A.

```powershell
$directedGraph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @()
}
```

### Graphes non dirigés

Pour les graphes non dirigés, chaque arête est représentée deux fois : une fois dans chaque direction.

```powershell
$undirectedGraph = @{
    "A" = @("B")
    "B" = @("A", "C")
    "C" = @("B")
}
```

### Graphes pondérés

Pour les graphes pondérés, nous utilisons une structure légèrement différente où les voisins sont représentés par des objets contenant l'identifiant du nœud et le poids de l'arête.

```powershell
$weightedGraph = @{
    "A" = @(
        [PSCustomObject]@{ Node = "B"; Weight = 5 },
        [PSCustomObject]@{ Node = "C"; Weight = 3 }
    )
    "B" = @(
        [PSCustomObject]@{ Node = "D"; Weight = 2 }
    )
    "C" = @()
    "D" = @()
}
```

## Représentations spécifiques

### Dépendances de scripts

Pour les dépendances de scripts, les nœuds sont les chemins des fichiers et les arêtes représentent les relations de dépendance.

```powershell
$scriptDependencies = @{
    ".\scripts\A.ps1" = @(".\scripts\B.ps1", ".\scripts\C.ps1")
    ".\scripts\B.ps1" = @(".\scripts\D.ps1")
    ".\scripts\C.ps1" = @()
    ".\scripts\D.ps1" = @(".\scripts\C.ps1")
}
```

### Workflows n8n

Pour les workflows n8n, les nœuds sont les identifiants des nœuds du workflow et les arêtes représentent les connexions entre les nœuds.

```powershell
$n8nWorkflow = @{
    "node1" = @("node2", "node3")
    "node2" = @("node4")
    "node3" = @("node4")
    "node4" = @()
}
```

## Opérations sur les graphes

### Création d'un graphe

```powershell
function New-Graph {
    [CmdletBinding()]
    param ()
    
    return @{}
}
```

### Ajout d'un nœud

```powershell
function Add-GraphNode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $true)]
        [string]$Node
    )
    
    if (-not $Graph.ContainsKey($Node)) {
        $Graph[$Node] = @()
    }
    
    return $Graph
}
```

### Ajout d'une arête

```powershell
function Add-GraphEdge {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $true)]
        [string]$FromNode,
        
        [Parameter(Mandatory = $true)]
        [string]$ToNode
    )
    
    # Ajouter les nœuds s'ils n'existent pas
    if (-not $Graph.ContainsKey($FromNode)) {
        $Graph[$FromNode] = @()
    }
    
    if (-not $Graph.ContainsKey($ToNode)) {
        $Graph[$ToNode] = @()
    }
    
    # Ajouter l'arête si elle n'existe pas déjà
    if ($Graph[$FromNode] -notcontains $ToNode) {
        $Graph[$FromNode] = $Graph[$FromNode] + $ToNode
    }
    
    return $Graph
}
```

### Suppression d'une arête

```powershell
function Remove-GraphEdge {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $true)]
        [string]$FromNode,
        
        [Parameter(Mandatory = $true)]
        [string]$ToNode
    )
    
    if ($Graph.ContainsKey($FromNode)) {
        $Graph[$FromNode] = $Graph[$FromNode] | Where-Object { $_ -ne $ToNode }
    }
    
    return $Graph
}
```

### Conversion d'un graphe en chaîne

```powershell
function ConvertTo-GraphString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    $result = ""
    
    foreach ($node in $Graph.Keys | Sort-Object) {
        $neighbors = $Graph[$node] -join ", "
        $result += "$node -> [$neighbors]`n"
    }
    
    return $result
}
```

## Optimisations

### Mise en cache des résultats

Pour améliorer les performances, nous utiliserons une table de hachage pour mettre en cache les résultats de détection de cycles.

```powershell
$script:CycleCache = @{}

function Get-CachedCycleResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$GraphKey
    )
    
    if ($script:CycleCache.ContainsKey($GraphKey)) {
        return $script:CycleCache[$GraphKey]
    }
    
    return $null
}

function Set-CachedCycleResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$GraphKey,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Result
    )
    
    $script:CycleCache[$GraphKey] = $Result
}
```

### Hachage de graphe

Pour utiliser efficacement le cache, nous avons besoin d'une fonction de hachage pour les graphes.

```powershell
function Get-GraphHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    $stringBuilder = New-Object System.Text.StringBuilder
    
    foreach ($node in $Graph.Keys | Sort-Object) {
        [void]$stringBuilder.Append($node)
        [void]$stringBuilder.Append(":")
        
        foreach ($neighbor in $Graph[$node] | Sort-Object) {
            [void]$stringBuilder.Append($neighbor)
            [void]$stringBuilder.Append(",")
        }
        
        [void]$stringBuilder.Append(";")
    }
    
    $graphString = $stringBuilder.ToString()
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($graphString)
    )
    
    return [System.Convert]::ToBase64String($hash)
}
```

## Considérations de performance

### Taille des graphes

| Taille du graphe | Nombre de nœuds | Nombre d'arêtes | Mémoire estimée |
|------------------|-----------------|-----------------|-----------------|
| Petit            | < 100           | < 500           | < 1 MB          |
| Moyen            | 100 - 1 000     | 500 - 5 000     | 1 - 10 MB       |
| Grand            | 1 000 - 10 000  | 5 000 - 50 000  | 10 - 100 MB     |
| Très grand       | > 10 000        | > 50 000        | > 100 MB        |

### Optimisations pour les grands graphes

Pour les grands graphes, nous utiliserons les optimisations suivantes :

1. **Implémentation itérative** de l'algorithme DFS pour éviter les problèmes de débordement de pile
2. **Mise en cache des résultats intermédiaires** pour éviter les calculs redondants
3. **Limitation de profondeur configurable** pour éviter les recherches trop profondes
4. **Traitement par lots** pour les graphes très grands

## Conclusion

La représentation des graphes par liste d'adjacence offre un bon compromis entre efficacité spatiale, performance et simplicité d'implémentation. Cette structure sera utilisée comme base pour le module `CycleDetector.psm1`.

Les optimisations proposées permettront d'assurer de bonnes performances même sur des graphes de grande taille, tout en maintenant la clarté et la maintenabilité du code.
