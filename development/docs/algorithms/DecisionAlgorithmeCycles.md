# Document de décision technique : Choix de l'algorithme de détection de cycles

## Résumé

Après analyse des différents algorithmes de détection de cycles disponibles, nous avons sélectionné l'**algorithme DFS (Depth-First Search)** comme base pour notre implémentation du module `CycleDetector.psm1`. Ce document présente les raisons de ce choix et les adaptations prévues pour notre cas d'usage spécifique.

## Contexte

Le module `CycleDetector.psm1` doit permettre de détecter les cycles dans différents types de graphes, notamment :
- Les dépendances entre scripts PowerShell
- Les workflows n8n
- Les graphes génériques représentés par des tables de hachage

Les principaux critères de sélection étaient :
- L'efficacité de l'algorithme
- La facilité d'implémentation en PowerShell
- La précision dans l'identification des cycles
- L'adaptabilité à différents types de graphes
- La performance sur des graphes de taille variable

## Algorithmes considérés

Nous avons évalué quatre algorithmes principaux :
1. **DFS (Depth-First Search)**
2. **BFS (Breadth-First Search)**
3. **Algorithme de Tarjan**
4. **Détection par coloration**

## Justification du choix

L'algorithme DFS a été sélectionné pour les raisons suivantes :

### 1. Simplicité d'implémentation

- L'algorithme DFS peut être implémenté de manière concise et claire en PowerShell
- La logique récursive est intuitive et facile à comprendre
- Possibilité d'implémenter une version itérative pour éviter les limitations de récursion

### 2. Efficacité

- Complexité temporelle optimale de O(V+E)
- Consommation mémoire raisonnable de O(V)
- Performances excellentes pour les graphes de petite et moyenne taille

### 3. Précision dans l'identification des cycles

- Permet d'identifier exactement les nœuds impliqués dans un cycle
- Facilite la construction du chemin complet du cycle
- Permet de détecter tous les cycles avec des modifications mineures

### 4. Adaptabilité

- S'adapte bien aux différents types de graphes que nous devons analyser
- Peut être modifié pour des besoins spécifiques (détection de tous les cycles, limitation de profondeur)
- Compatible avec notre représentation des graphes par tables de hachage

### 5. Compatibilité avec PowerShell

- Bien adapté aux structures de données PowerShell (hashtables)
- Peut être optimisé pour respecter les conventions PowerShell
- Facile à intégrer dans notre architecture modulaire

## Adaptations prévues

Pour optimiser l'algorithme DFS pour notre cas d'usage, nous prévoyons les adaptations suivantes :

### 1. Implémentation itérative

Pour éviter les problèmes de débordement de pile sur les grands graphes, nous implémenterons une version itérative de l'algorithme DFS en utilisant une pile explicite.

```powershell
function Find-GraphCycle {
    param (
        [hashtable]$Graph
    )
    
    $visited = @{}
    $inStack = @{}
    $result = [PSCustomObject]@{
        HasCycle = $false
        CyclePath = @()
    }
    
    foreach ($node in $Graph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            $stack = New-Object System.Collections.Stack
            $pathStack = New-Object System.Collections.Stack
            
            $stack.Push(@{
                Node = $node
                Neighbors = $Graph[$node]
                Index = 0
            })
            $inStack[$node] = $true
            $pathStack.Push($node)
            
            while ($stack.Count -gt 0) {
                $current = $stack.Peek()
                
                if ($current.Index -ge $current.Neighbors.Count) {
                    $stack.Pop()
                    $inStack[$current.Node] = $false
                    $pathStack.Pop()
                    continue
                }
                
                $neighbor = $current.Neighbors[$current.Index]
                $current.Index++
                
                if ($inStack.ContainsKey($neighbor) -and $inStack[$neighbor]) {
                    # Cycle détecté

                    $result.HasCycle = $true
                    
                    # Construire le chemin du cycle

                    $cyclePath = @($neighbor)
                    $pathArray = $pathStack.ToArray()
                    [array]::Reverse($pathArray)
                    
                    $startIndex = [array]::IndexOf($pathArray, $neighbor)
                    for ($i = 0; $i -lt $startIndex; $i++) {
                        $cyclePath += $pathArray[$i]
                    }
                    $cyclePath += $neighbor
                    
                    $result.CyclePath = $cyclePath
                    return $result
                }
                
                if (-not $visited.ContainsKey($neighbor)) {
                    $visited[$neighbor] = $true
                    $inStack[$neighbor] = $true
                    $pathStack.Push($neighbor)
                    
                    $stack.Push(@{
                        Node = $neighbor
                        Neighbors = $Graph[$neighbor]
                        Index = 0
                    })
                }
            }
        }
    }
    
    return $result
}
```plaintext
### 2. Mise en cache des résultats intermédiaires

Pour améliorer les performances sur les grands graphes, nous implémenterons un système de mise en cache des résultats intermédiaires.

```powershell
$script:CycleCache = @{}

function Clear-CycleCache {
    $script:CycleCache = @{}
}

function Get-CachedCycleResult {
    param (
        [string]$GraphKey
    )
    
    if ($script:CycleCache.ContainsKey($GraphKey)) {
        return $script:CycleCache[$GraphKey]
    }
    
    return $null
}

function Set-CachedCycleResult {
    param (
        [string]$GraphKey,
        [PSCustomObject]$Result
    )
    
    $script:CycleCache[$GraphKey] = $Result
}
```plaintext
### 3. Limitation de profondeur configurable

Pour éviter les problèmes sur les graphes très profonds, nous ajouterons une option de limitation de profondeur.

```powershell
function Find-GraphCycleWithDepthLimit {
    param (
        [hashtable]$Graph,
        [int]$MaxDepth = 1000
    )
    
    # Implémentation similaire à Find-GraphCycle avec une vérification de profondeur

}
```plaintext
### 4. Optimisations spécifiques aux types de graphes

Nous implémenterons des optimisations spécifiques pour chaque type de graphe :

- **Dépendances de scripts** : Prétraitement pour extraire efficacement les dépendances
- **Workflows n8n** : Analyse optimisée de la structure JSON des workflows
- **Graphes génériques** : Optimisations générales de l'algorithme DFS

## Conclusion

L'algorithme DFS, avec les adaptations prévues, représente la solution optimale pour notre module `CycleDetector.psm1`. Il offre le meilleur compromis entre simplicité d'implémentation, efficacité et précision pour notre cas d'usage.

Les optimisations prévues permettront d'assurer de bonnes performances même sur des graphes de grande taille, tout en maintenant la clarté et la maintenabilité du code.

## Approbation

Ce document de décision technique a été approuvé le 01/06/2025.

**Approuvé par** : Équipe EMAIL_SENDER_1
