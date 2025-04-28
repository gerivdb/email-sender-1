# Spécification d'API du module DependencyCycleResolver

## Vue d'ensemble

Le module `DependencyCycleResolver.psm1` fournit des fonctionnalités pour résoudre automatiquement les cycles de dépendances détectés dans les scripts PowerShell et les workflows n8n. Cette spécification définit l'interface publique du module, les paramètres et les valeurs de retour de chaque fonction.

## Fonctions publiques

### Initialize-DependencyCycleResolver

Initialise le résolveur de cycles avec les paramètres spécifiés.

#### Syntaxe

```powershell
Initialize-DependencyCycleResolver [-Enabled <Boolean>] [-MaxIterations <Int32>] [-Strategy <String>]
```

#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| Enabled | Boolean | Non | Active ou désactive le résolveur de cycles. Valeur par défaut : $true |
| MaxIterations | Int32 | Non | Nombre maximal d'itérations pour résoudre un cycle. Valeur par défaut : 10 |
| Strategy | String | Non | Stratégie de résolution des cycles. Valeurs possibles : "MinimumImpact", "WeightBased", "Random". Valeur par défaut : "MinimumImpact" |

#### Valeur de retour

Booléen indiquant si l'initialisation a réussi.

#### Exemple

```powershell
# Initialiser le résolveur de cycles avec une stratégie basée sur le poids
Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 5 -Strategy "WeightBased"
```

### Resolve-DependencyCycle

Résout automatiquement les cycles de dépendances dans un graphe.

#### Syntaxe

```powershell
Resolve-DependencyCycle -CycleResult <PSObject> [-Strategy <String>] [-MaxIterations <Int32>] [-Force]
```

#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| CycleResult | PSObject | Oui | Résultat de la détection de cycle (obtenu via Find-Cycle ou Find-ScriptDependencyCycles) |
| Strategy | String | Non | Stratégie de résolution des cycles. Valeurs possibles : "MinimumImpact", "WeightBased", "Random". Valeur par défaut : valeur définie lors de l'initialisation |
| MaxIterations | Int32 | Non | Nombre maximal d'itérations pour résoudre un cycle. Valeur par défaut : valeur définie lors de l'initialisation |
| Force | Switch | Non | Force la suppression des arêtes sans confirmation |

#### Valeur de retour

Un objet PSCustomObject avec les propriétés suivantes :
- **Success** : Booléen indiquant si la résolution a réussi
- **Graph** : Graphe modifié sans cycle
- **RemovedEdges** : Tableau des arêtes supprimées
- **Iterations** : Nombre d'itérations effectuées
- **ExecutionTime** : Temps d'exécution en millisecondes

#### Exemple

```powershell
# Détecter les cycles dans un graphe
$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}
$cycleResult = Find-Cycle -Graph $graph

# Résoudre le cycle
$resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult -Strategy "MinimumImpact"
if ($resolveResult.Success) {
    Write-Host "Cycle résolu en supprimant l'arête: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
}
```

### Resolve-ScriptDependencyCycle

Résout automatiquement les cycles de dépendances dans des scripts PowerShell.

#### Syntaxe

```powershell
Resolve-ScriptDependencyCycle -Path <String> [-Recursive] [-Strategy <String>] [-MaxIterations <Int32>] [-Force] [-GenerateReport] [-ReportPath <String>]
```

#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| Path | String | Oui | Chemin du dossier ou fichier à analyser |
| Recursive | Switch | Non | Analyse récursivement les sous-dossiers |
| Strategy | String | Non | Stratégie de résolution des cycles. Valeurs possibles : "MinimumImpact", "WeightBased", "Random". Valeur par défaut : valeur définie lors de l'initialisation |
| MaxIterations | Int32 | Non | Nombre maximal d'itérations pour résoudre un cycle. Valeur par défaut : valeur définie lors de l'initialisation |
| Force | Switch | Non | Force la suppression des arêtes sans confirmation |
| GenerateReport | Switch | Non | Génère un rapport de résolution |
| ReportPath | String | Non | Chemin du fichier de rapport |

#### Valeur de retour

Un objet PSCustomObject avec les propriétés suivantes :
- **Success** : Booléen indiquant si la résolution a réussi
- **Path** : Chemin analysé
- **CyclesDetected** : Nombre de cycles détectés
- **CyclesResolved** : Nombre de cycles résolus
- **RemovedEdges** : Tableau des arêtes supprimées

#### Exemple

```powershell
# Résoudre les cycles de dépendances dans un dossier de scripts
$result = Resolve-ScriptDependencyCycle -Path ".\development\scripts" -Recursive -GenerateReport -ReportPath ".\reports\cycle_resolution.json"
if ($result.Success) {
    Write-Host "Cycles résolus: $($result.CyclesResolved)/$($result.CyclesDetected)"
}
```

### Resolve-WorkflowCycle

Résout automatiquement les cycles dans un workflow n8n.

#### Syntaxe

```powershell
Resolve-WorkflowCycle -WorkflowPath <String> [-Strategy <String>] [-MaxIterations <Int32>] [-Force] [-GenerateReport] [-ReportPath <String>]
```

#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| WorkflowPath | String | Oui | Chemin du fichier de workflow n8n à analyser |
| Strategy | String | Non | Stratégie de résolution des cycles. Valeurs possibles : "MinimumImpact", "WeightBased", "Random". Valeur par défaut : valeur définie lors de l'initialisation |
| MaxIterations | Int32 | Non | Nombre maximal d'itérations pour résoudre un cycle. Valeur par défaut : valeur définie lors de l'initialisation |
| Force | Switch | Non | Force la suppression des connexions sans confirmation |
| GenerateReport | Switch | Non | Génère un rapport de résolution |
| ReportPath | String | Non | Chemin du fichier de rapport |

#### Valeur de retour

Un objet PSCustomObject avec les propriétés suivantes :
- **Success** : Booléen indiquant si la résolution a réussi
- **WorkflowPath** : Chemin du workflow
- **CyclesDetected** : Nombre de cycles détectés
- **CyclesResolved** : Nombre de cycles résolus
- **RemovedEdges** : Tableau des connexions supprimées

#### Exemple

```powershell
# Résoudre les cycles dans un workflow n8n
$result = Resolve-WorkflowCycle -WorkflowPath ".\workflows\my_workflow.json" -GenerateReport -ReportPath ".\reports\workflow_resolution.json"
if ($result.Success) {
    Write-Host "Cycles résolus: $($result.CyclesResolved)/$($result.CyclesDetected)"
}
```

### Get-CycleResolverStatistics

Obtient les statistiques du résolveur de cycles.

#### Syntaxe

```powershell
Get-CycleResolverStatistics
```

#### Paramètres

Aucun.

#### Valeur de retour

Un objet PSCustomObject avec les propriétés suivantes :
- **Enabled** : Booléen indiquant si le résolveur est activé
- **MaxIterations** : Nombre maximal d'itérations
- **Strategy** : Stratégie de résolution
- **TotalResolutions** : Nombre total de tentatives de résolution
- **SuccessfulResolutions** : Nombre de résolutions réussies
- **FailedResolutions** : Nombre de résolutions échouées
- **SuccessRate** : Taux de réussite en pourcentage
- **AverageIterations** : Nombre moyen d'itérations par résolution réussie
- **LastResolutionTime** : Temps d'exécution de la dernière résolution en millisecondes

#### Exemple

```powershell
# Obtenir les statistiques du résolveur de cycles
$stats = Get-CycleResolverStatistics
Write-Host "Taux de réussite: $($stats.SuccessRate)%"
Write-Host "Nombre moyen d'itérations: $($stats.AverageIterations)"
```

## Stratégies de résolution

Le module `DependencyCycleResolver` propose trois stratégies de résolution des cycles :

### MinimumImpact

Cette stratégie sélectionne l'arête dont la suppression aura le moins d'impact sur le graphe. L'impact est mesuré par le nombre de chemins qui passent par cette arête.

### WeightBased

Cette stratégie sélectionne l'arête avec le poids le plus faible. Le poids peut être défini par l'utilisateur ou est par défaut égal à 1 pour toutes les arêtes.

### Random

Cette stratégie sélectionne une arête aléatoire dans le cycle.

## Exemples d'utilisation

### Résolution de cycles dans un graphe de dépendances

```powershell
# Importer les modules
Import-Module .\modules\CycleDetector.psm1
Import-Module .\modules\DependencyCycleResolver.psm1

# Initialiser les modules
Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"

# Créer un graphe avec un cycle
$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}

# Détecter le cycle
$cycleResult = Find-Cycle -Graph $graph

# Résoudre le cycle
$resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

# Afficher le résultat
if ($resolveResult.Success) {
    Write-Host "Cycle résolu en supprimant l'arête: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
    
    # Vérifier que le graphe modifié n'a plus de cycle
    $newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
    if (-not $newCycleCheck.HasCycle) {
        Write-Host "Le graphe ne contient plus de cycle."
    }
}
```

### Résolution de cycles dans des scripts PowerShell

```powershell
# Importer les modules
Import-Module .\modules\CycleDetector.psm1
Import-Module .\modules\DependencyCycleResolver.psm1

# Initialiser les modules
Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"

# Résoudre les cycles de dépendances dans un dossier de scripts
$result = Resolve-ScriptDependencyCycle -Path ".\development\scripts" -Recursive -GenerateReport -ReportPath ".\reports\cycle_resolution.json"

# Afficher le résultat
if ($result.Success) {
    Write-Host "Cycles détectés: $($result.CyclesDetected)"
    Write-Host "Cycles résolus: $($result.CyclesResolved)"
    
    foreach ($edge in $result.RemovedEdges) {
        Write-Host "Arête supprimée: $($edge.Source) -> $($edge.Target)"
    }
}
```

### Résolution de cycles dans des workflows n8n

```powershell
# Importer les modules
Import-Module .\modules\CycleDetector.psm1
Import-Module .\modules\DependencyCycleResolver.psm1

# Initialiser les modules
Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"

# Résoudre les cycles dans un workflow n8n
$result = Resolve-WorkflowCycle -WorkflowPath ".\workflows\my_workflow.json" -GenerateReport -ReportPath ".\reports\workflow_resolution.json"

# Afficher le résultat
if ($result.Success) {
    Write-Host "Cycles détectés: $($result.CyclesDetected)"
    Write-Host "Cycles résolus: $($result.CyclesResolved)"
    
    foreach ($edge in $result.RemovedEdges) {
        Write-Host "Connexion supprimée: $($edge.Source) -> $($edge.Target)"
    }
}
```

## Intégration avec le module CycleDetector

Le module `DependencyCycleResolver` s'intègre étroitement avec le module `CycleDetector` pour détecter et résoudre les cycles de dépendances. Voici comment les deux modules interagissent :

1. Le module `CycleDetector` détecte les cycles dans un graphe via la fonction `Find-Cycle`.
2. Le module `DependencyCycleResolver` utilise le résultat de cette détection pour résoudre les cycles via la fonction `Resolve-DependencyCycle`.
3. Le module `DependencyCycleResolver` peut également détecter et résoudre les cycles dans des scripts PowerShell via la fonction `Resolve-ScriptDependencyCycle`, qui utilise en interne la fonction `Find-ScriptDependencyCycles` du module `CycleDetector`.
4. Le module `DependencyCycleResolver` peut également détecter et résoudre les cycles dans des workflows n8n via la fonction `Resolve-WorkflowCycle`, qui utilise en interne la fonction `Test-WorkflowCycles` du module `CycleDetector`.

## Bonnes pratiques

- Initialisez toujours les deux modules (`CycleDetector` et `DependencyCycleResolver`) avant de les utiliser.
- Utilisez la stratégie "MinimumImpact" pour minimiser l'impact de la résolution des cycles sur le graphe.
- Générez toujours un rapport lors de la résolution des cycles pour garder une trace des modifications effectuées.
- Vérifiez toujours que le graphe modifié ne contient plus de cycle après la résolution.
- Utilisez la fonction `Get-CycleResolverStatistics` pour surveiller les performances du résolveur de cycles.

## Limitations

- Le résolveur de cycles ne peut pas résoudre tous les types de cycles, notamment les cycles complexes avec des dépendances indirectes.
- La stratégie "MinimumImpact" peut être coûteuse en termes de performance pour les grands graphes.
- La résolution automatique des cycles peut supprimer des arêtes importantes pour le fonctionnement du système. Utilisez avec précaution.
- Le module ne gère pas les dépendances dynamiques (créées à l'exécution).
