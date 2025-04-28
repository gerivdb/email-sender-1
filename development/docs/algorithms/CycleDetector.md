# Module de détection de cycles

## Vue d'ensemble

Le module `CycleDetector` fournit des fonctionnalités pour détecter et corriger les cycles dans différents types de graphes, notamment les dépendances de scripts et les workflows n8n. Ce module est essentiel pour prévenir les boucles infinies et les dépendances circulaires qui peuvent causer des problèmes dans les systèmes complexes.

## Installation

Le module est disponible dans le dossier `modules` du projet. Pour l'importer :

```powershell
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\CycleDetector.psm1"
Import-Module $modulePath -Force
```

## Fonctions principales

### Detect-Cycle

Détecte les cycles dans un graphe générique.

#### Syntaxe

```powershell
Detect-Cycle -Graph <Hashtable>
```

#### Paramètres

- **Graph** : Une table de hachage représentant le graphe. Les clés sont les nœuds et les valeurs sont des tableaux de nœuds adjacents.

#### Valeur de retour

Un objet avec les propriétés suivantes :
- **HasCycle** : Booléen indiquant si un cycle a été détecté.
- **CyclePath** : Tableau des nœuds formant le cycle (si un cycle a été détecté).

#### Exemple

```powershell
$graph = @{
    "A" = @("B", "C")
    "B" = @("D")
    "C" = @("E")
    "D" = @("F")
    "E" = @("D")
    "F" = @()
}

$result = Detect-Cycle -Graph $graph
if ($result.HasCycle) {
    Write-Host "Cycle détecté: $($result.CyclePath -join ' -> ')"
}
```

### Find-DependencyCycles

Analyse les dépendances entre les scripts PowerShell pour détecter les cycles.

#### Syntaxe

```powershell
Find-DependencyCycles -Path <String> [-Recursive]
```

#### Paramètres

- **Path** : Chemin du dossier ou fichier à analyser.
- **Recursive** : Analyse récursivement les sous-dossiers.

#### Valeur de retour

Un objet avec les propriétés suivantes :
- **HasCycles** : Booléen indiquant si des cycles ont été détectés.
- **Cycles** : Tableau des cycles détectés.
- **DependencyGraph** : Graphe de dépendances complet.
- **NonCyclicScripts** : Scripts sans dépendances cycliques.

#### Exemple

```powershell
$result = Find-DependencyCycles -Path ".\development\scripts" -Recursive
if ($result.HasCycles) {
    foreach ($cycle in $result.Cycles) {
        Write-Host "Cycle de dépendance détecté: $($cycle -join ' -> ')"
    }
}
```

### Test-WorkflowCycles

Analyse les workflows n8n pour détecter les cycles.

#### Syntaxe

```powershell
Test-WorkflowCycles -WorkflowPath <String>
```

#### Paramètres

- **WorkflowPath** : Chemin du fichier de workflow n8n à analyser.

#### Valeur de retour

Un objet avec les propriétés suivantes :
- **HasCycles** : Booléen indiquant si des cycles ont été détectés.
- **Cycles** : Tableau des cycles détectés.
- **WorkflowName** : Nom du workflow analysé.

#### Exemple

```powershell
$result = Test-WorkflowCycles -WorkflowPath ".\workflows\my_workflow.json"
if ($result.HasCycles) {
    foreach ($cycle in $result.Cycles) {
        Write-Host "Cycle de workflow détecté: $($cycle -join ' -> ')"
    }
}
```

### Remove-Cycle

Supprime un cycle d'un graphe en retirant une arête.

#### Syntaxe

```powershell
Remove-Cycle -Graph <Hashtable> -Cycle <String[]>
```

#### Paramètres

- **Graph** : Une table de hachage représentant le graphe.
- **Cycle** : Tableau des nœuds formant le cycle à supprimer.

#### Valeur de retour

Une table de hachage représentant le graphe modifié sans le cycle.

#### Exemple

```powershell
$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}

$cycle = @("A", "B", "C")
$modifiedGraph = Remove-Cycle -Graph $graph -Cycle $cycle

# Vérifier que le cycle a été supprimé
$result = Detect-Cycle -Graph $modifiedGraph
if (-not $result.HasCycle) {
    Write-Host "Le cycle a été supprimé avec succès."
}
```

## Intégration avec n8n

Le module `CycleDetector` s'intègre avec n8n via le script `Validate-WorkflowCycles.ps1` qui permet de valider et corriger automatiquement les cycles dans les workflows n8n.

### Exemple d'utilisation avec n8n

```powershell
# Valider un workflow n8n
$result = & ".\development\scripts\n8n\workflow-validation\Validate-WorkflowCycles.ps1" -WorkflowsPath ".\workflows\my_workflow.json"

# Valider et corriger automatiquement les cycles
$result = & ".\development\scripts\n8n\workflow-validation\Validate-WorkflowCycles.ps1" -WorkflowsPath ".\workflows\my_workflow.json" -FixCycles
```

## Algorithmes utilisés

Le module utilise l'algorithme de recherche en profondeur (DFS) pour détecter les cycles dans les graphes. Cet algorithme est efficace pour les graphes de taille moyenne à grande.

## Performance

Les performances du module dépendent de la taille et de la complexité des graphes analysés :

- **Petits graphes** (< 100 nœuds) : Temps d'exécution négligeable.
- **Graphes moyens** (100-1000 nœuds) : Temps d'exécution de quelques secondes.
- **Grands graphes** (> 1000 nœuds) : Temps d'exécution pouvant atteindre plusieurs minutes.

## Compatibilité

- PowerShell 5.1 et versions ultérieures.
- Compatible avec PowerShell 7.

## Limitations connues

- Les graphes très volumineux (> 10 000 nœuds) peuvent entraîner des problèmes de mémoire.
- L'analyse des dépendances de scripts ne détecte que les dépendances explicites (via dot-sourcing).

## Exemples avancés

### Analyse complète d'un projet

```powershell
# Analyser tous les scripts d'un projet
$result = Find-DependencyCycles -Path ".\development\scripts" -Recursive

# Générer un rapport
$report = [PSCustomObject]@{
    HasCycles = $result.HasCycles
    CyclesCount = $result.Cycles.Count
    ScriptsCount = $result.DependencyGraph.Keys.Count
    NonCyclicScriptsCount = $result.NonCyclicScripts.Count
    Cycles = $result.Cycles
}

$report | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\reports\dependency_cycles.json" -Encoding utf8
```

### Validation de tous les workflows n8n

```powershell
# Obtenir tous les workflows n8n
$workflows = Get-ChildItem -Path ".\workflows" -Filter "*.json" -Recurse

# Valider chaque workflow
$results = @()
foreach ($workflow in $workflows) {
    $result = Test-WorkflowCycles -WorkflowPath $workflow.FullName
    $results += [PSCustomObject]@{
        Path = $workflow.FullName
        Name = $workflow.BaseName
        HasCycles = $result.HasCycles
        CyclesCount = $result.Cycles.Count
        Cycles = $result.Cycles
    }
}

# Générer un rapport
$report = [PSCustomObject]@{
    TotalWorkflows = $workflows.Count
    WorkflowsWithCycles = ($results | Where-Object { $_.HasCycles }).Count
    Results = $results
}

$report | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\reports\workflow_cycles.json" -Encoding utf8
```
