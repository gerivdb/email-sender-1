# DependencyCycleResolver - Documentation API

## Vue d'ensemble

Le module `DependencyCycleResolver` est conçu pour détecter et résoudre automatiquement les cycles de dépendances dans les scripts PowerShell et les workflows n8n. Il s'intègre avec le module `CycleDetector` pour identifier les cycles et propose plusieurs stratégies pour les résoudre.

## Installation

```powershell
# Importer le module

Import-Module -Path "chemin/vers/DependencyCycleResolver.psm1"

# Initialiser le module

Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
```plaintext
## Fonctions principales

### Initialize-DependencyCycleResolver

Initialise le module de résolution des cycles de dépendances avec les paramètres spécifiés.

#### Syntaxe

```powershell
Initialize-DependencyCycleResolver [[-Enabled] <Boolean>] [[-MaxIterations] <Int32>] [[-Strategy] <String>]
```plaintext
#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| Enabled | Boolean | Non | Indique si le résolveur est activé. La valeur par défaut est $true. |
| MaxIterations | Int32 | Non | Nombre maximum d'itérations pour résoudre les cycles. La valeur par défaut est 10. |
| Strategy | String | Non | Stratégie de résolution des cycles. Les valeurs possibles sont "MinimumImpact", "WeightBased" et "Random". La valeur par défaut est "MinimumImpact". |

#### Valeur de retour

Boolean. Retourne $true si l'initialisation a réussi, $false sinon.

#### Exemple

```powershell
# Initialiser le résolveur avec les paramètres par défaut

Initialize-DependencyCycleResolver

# Initialiser le résolveur avec des paramètres personnalisés

Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 5 -Strategy "Random"
```plaintext
### Resolve-DependencyCycle

Résout un cycle de dépendances dans un graphe.

#### Syntaxe

```powershell
Resolve-DependencyCycle [-CycleResult] <PSObject>
```plaintext
#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| CycleResult | PSObject | Oui | Résultat de la détection de cycle, tel que retourné par la fonction Find-Cycle du module CycleDetector. Doit contenir les propriétés HasCycle, CyclePath et Graph. |

#### Valeur de retour

PSObject ou Boolean. Si un cycle est détecté et résolu, retourne un objet avec les propriétés suivantes :
- Success : Boolean. Indique si la résolution a réussi.
- RemovedEdges : Array. Liste des arêtes supprimées pour résoudre le cycle.
- Graph : Hashtable. Graphe modifié sans cycle.

Si aucun cycle n'est détecté ou si le résolveur est désactivé, retourne $false.

#### Exemple

```powershell
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

if ($resolveResult.Success) {
    Write-Host "Cycle résolu avec succès"
    Write-Host "Arête supprimée: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
} else {
    Write-Host "Échec de la résolution du cycle"
}
```plaintext
### Resolve-ScriptDependencyCycle

Détecte et résout les cycles de dépendances dans les scripts PowerShell.

#### Syntaxe

```powershell
Resolve-ScriptDependencyCycle [-Path] <String>
```plaintext
#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| Path | String | Oui | Chemin du dossier contenant les scripts PowerShell à analyser. |

#### Valeur de retour

PSObject. Retourne un objet avec les propriétés suivantes :
- Success : Boolean. Indique si la résolution a réussi.
- CyclesDetected : Int32. Nombre de cycles détectés.
- CyclesResolved : Int32. Nombre de cycles résolus.
- RemovedEdges : Array. Liste des arêtes supprimées pour résoudre les cycles.

#### Exemple

```powershell
# Résoudre les cycles dans les scripts PowerShell

$resolveResult = Resolve-ScriptDependencyCycle -Path "C:\Scripts"

Write-Host "Cycles détectés: $($resolveResult.CyclesDetected)"
Write-Host "Cycles résolus: $($resolveResult.CyclesResolved)"
```plaintext
### Resolve-WorkflowCycle

Détecte et résout les cycles de dépendances dans les workflows n8n.

#### Syntaxe

```powershell
Resolve-WorkflowCycle [-WorkflowPath] <String>
```plaintext
#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| WorkflowPath | String | Oui | Chemin du fichier JSON du workflow n8n à analyser. |

#### Valeur de retour

PSObject. Retourne un objet avec les propriétés suivantes :
- Success : Boolean. Indique si la résolution a réussi.
- CyclesDetected : Int32. Nombre de cycles détectés.
- CyclesResolved : Int32. Nombre de cycles résolus.
- RemovedEdges : Array. Liste des arêtes supprimées pour résoudre les cycles.

#### Exemple

```powershell
# Résoudre les cycles dans un workflow n8n

$resolveResult = Resolve-WorkflowCycle -WorkflowPath "C:\Workflows\workflow.json"

Write-Host "Cycles détectés: $($resolveResult.CyclesDetected)"
Write-Host "Cycles résolus: $($resolveResult.CyclesResolved)"
```plaintext
### Get-CycleResolverStatistics

Récupère les statistiques du résolveur de cycles.

#### Syntaxe

```powershell
Get-CycleResolverStatistics
```plaintext
#### Paramètres

Aucun.

#### Valeur de retour

PSObject. Retourne un objet avec les propriétés suivantes :
- Enabled : Boolean. Indique si le résolveur est activé.
- MaxIterations : Int32. Nombre maximum d'itérations pour résoudre les cycles.
- Strategy : String. Stratégie de résolution des cycles.
- TotalResolutions : Int32. Nombre total de résolutions tentées.
- SuccessfulResolutions : Int32. Nombre de résolutions réussies.
- FailedResolutions : Int32. Nombre de résolutions échouées.
- SuccessRate : Double. Taux de réussite des résolutions (en pourcentage).

#### Exemple

```powershell
# Obtenir les statistiques du résolveur

$stats = Get-CycleResolverStatistics

Write-Host "Nombre total de résolutions: $($stats.TotalResolutions)"
Write-Host "Résolutions réussies: $($stats.SuccessfulResolutions)"
Write-Host "Taux de réussite: $($stats.SuccessRate)%"
```plaintext
## Stratégies de résolution

Le module propose plusieurs stratégies pour résoudre les cycles de dépendances :

### MinimumImpact

Cette stratégie vise à minimiser l'impact de la résolution en supprimant les arêtes les moins utilisées ou les moins importantes. C'est la stratégie par défaut.

### WeightBased

Cette stratégie supprime les arêtes en fonction de leur poids. Les arêtes avec le poids le plus faible sont supprimées en premier.

### Random

Cette stratégie supprime une arête aléatoire du cycle. Elle peut être utile lorsque toutes les arêtes ont la même importance.

## Intégration avec CycleDetector

Le module `DependencyCycleResolver` s'intègre avec le module `CycleDetector` pour détecter les cycles de dépendances. Pour utiliser les deux modules ensemble, vous devez d'abord importer et initialiser les deux modules :

```powershell
# Importer les modules

Import-Module -Path "chemin/vers/CycleDetector.psm1"
Import-Module -Path "chemin/vers/DependencyCycleResolver.psm1"

# Initialiser les modules

Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
```plaintext
## Exemples d'utilisation

### Résolution d'un cycle simple

```powershell
# Créer un graphe avec un cycle

$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}

# Détecter le cycle

$cycleResult = Find-Cycle -Graph $graph

# Vérifier que le cycle est détecté

if ($cycleResult.HasCycle) {
    Write-Host "Cycle détecté: $($cycleResult.CyclePath -join ' -> ')"
    
    # Résoudre le cycle

    $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult
    
    # Vérifier que le cycle est résolu

    if ($resolveResult.Success) {
        Write-Host "Cycle résolu avec succès"
        Write-Host "Arête supprimée: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
        
        # Vérifier que le graphe modifié n'a plus de cycle

        $newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
        if (-not $newCycleCheck.HasCycle) {
            Write-Host "Le graphe modifié ne contient plus de cycle"
        } else {
            Write-Host "Le graphe modifié contient encore un cycle"
        }
    } else {
        Write-Host "Échec de la résolution du cycle"
    }
} else {
    Write-Host "Aucun cycle détecté"
}
```plaintext
### Résolution des cycles dans les scripts PowerShell

```powershell
# Résoudre les cycles dans les scripts PowerShell

$resolveResult = Resolve-ScriptDependencyCycle -Path "C:\Scripts"

# Afficher les résultats

Write-Host "Cycles détectés: $($resolveResult.CyclesDetected)"
Write-Host "Cycles résolus: $($resolveResult.CyclesResolved)"

if ($resolveResult.Success) {
    Write-Host "Résolution réussie"
    
    # Afficher les arêtes supprimées

    if ($resolveResult.RemovedEdges.Count -gt 0) {
        Write-Host "Arêtes supprimées:"
        foreach ($edge in $resolveResult.RemovedEdges) {
            Write-Host "  $($edge.Source) -> $($edge.Target)"
        }
    } else {
        Write-Host "Aucune arête supprimée"
    }
} else {
    Write-Host "Échec de la résolution"
}
```plaintext
### Résolution des cycles dans les workflows n8n

```powershell
# Résoudre les cycles dans un workflow n8n

$resolveResult = Resolve-WorkflowCycle -WorkflowPath "C:\Workflows\workflow.json"

# Afficher les résultats

Write-Host "Cycles détectés: $($resolveResult.CyclesDetected)"
Write-Host "Cycles résolus: $($resolveResult.CyclesResolved)"

if ($resolveResult.Success) {
    Write-Host "Résolution réussie"
    
    # Afficher les arêtes supprimées

    if ($resolveResult.RemovedEdges.Count -gt 0) {
        Write-Host "Arêtes supprimées:"
        foreach ($edge in $resolveResult.RemovedEdges) {
            Write-Host "  $($edge.Source) -> $($edge.Target)"
        }
    } else {
        Write-Host "Aucune arête supprimée"
    }
} else {
    Write-Host "Échec de la résolution"
}
```plaintext
## Bonnes pratiques

1. **Initialiser les modules** : Toujours initialiser les modules `CycleDetector` et `DependencyCycleResolver` avant de les utiliser.

2. **Choisir la bonne stratégie** : Sélectionner la stratégie de résolution en fonction de vos besoins spécifiques. La stratégie "MinimumImpact" est généralement un bon choix par défaut.

3. **Vérifier les résultats** : Toujours vérifier que les cycles ont été correctement résolus après l'exécution des fonctions de résolution.

4. **Surveiller les statistiques** : Utiliser la fonction `Get-CycleResolverStatistics` pour surveiller les performances du résolveur et identifier les problèmes potentiels.

5. **Gérer les erreurs** : Implémenter une gestion des erreurs robuste pour traiter les cas où la résolution échoue.

## Dépannage

### Problème : Le module ne détecte pas les cycles

**Solution** : Vérifier que le module `CycleDetector` est correctement importé et initialisé. Vérifier également que le graphe contient bien des cycles.

### Problème : Le module ne résout pas les cycles

**Solution** : Vérifier que le module `DependencyCycleResolver` est activé (paramètre `Enabled` à `$true`). Vérifier également que le nombre maximum d'itérations (`MaxIterations`) est suffisant pour résoudre les cycles complexes.

### Problème : Erreur "Le terme 'Find-Cycle' n'est pas reconnu"

**Solution** : Ce problème peut survenir lorsque le module `CycleDetector` n'est pas correctement importé. Utiliser la fonction wrapper `Find-CycleWrapper` fournie dans les exemples de test, ou réimporter le module avec l'option `-Force`.

### Problème : Dépassement de la profondeur des appels (stack overflow)

**Solution** : Ce problème peut survenir lors de l'exécution des tests avec Pester. Utiliser les scripts de test simplifiés qui n'utilisent pas Pester, ou augmenter la limite de profondeur de la pile dans PowerShell.

## Conclusion

Le module `DependencyCycleResolver` offre une solution robuste pour détecter et résoudre automatiquement les cycles de dépendances dans les scripts PowerShell et les workflows n8n. En l'intégrant avec le module `CycleDetector`, vous pouvez facilement identifier et résoudre les problèmes de dépendances circulaires dans vos projets.

---

*Documentation générée le 20/04/2025*
