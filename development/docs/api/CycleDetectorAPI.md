# Spécification d'API du module CycleDetector

## Vue d'ensemble

Le module `CycleDetector.psm1` fournit des fonctionnalités pour détecter et corriger les cycles dans différents types de graphes, notamment les dépendances de scripts et les workflows n8n. Cette spécification définit l'interface publique du module, les paramètres et les valeurs de retour de chaque fonction.

## Fonctions publiques

### Initialize-CycleDetector

Initialise le détecteur de cycles avec les paramètres spécifiés.

#### Syntaxe

```powershell
Initialize-CycleDetector [-Enabled <Boolean>] [-MaxDepth <Int32>] [-CacheEnabled <Boolean>]
```

#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| Enabled | Boolean | Non | Active ou désactive le détecteur de cycles. Valeur par défaut : $true |
| MaxDepth | Int32 | Non | Profondeur maximale de recherche. Valeur par défaut : 1000 |
| CacheEnabled | Boolean | Non | Active ou désactive la mise en cache des résultats. Valeur par défaut : $true |

#### Valeur de retour

Aucune valeur de retour.

#### Exemple

```powershell
# Initialiser le détecteur de cycles avec une profondeur maximale de 500
Initialize-CycleDetector -Enabled $true -MaxDepth 500 -CacheEnabled $true
```

### Detect-Cycle

Détecte les cycles dans un graphe générique.

#### Syntaxe

```powershell
Detect-Cycle -Graph <Hashtable> [-MaxDepth <Int32>]
```

#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| Graph | Hashtable | Oui | Table de hachage représentant le graphe. Les clés sont les nœuds et les valeurs sont des tableaux de nœuds adjacents. |
| MaxDepth | Int32 | Non | Profondeur maximale de recherche. Si non spécifié, utilise la valeur définie par Initialize-CycleDetector. |

#### Valeur de retour

Un objet PSCustomObject avec les propriétés suivantes :
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

### Find-GraphCycle

Fonction interne qui implémente l'algorithme DFS pour détecter les cycles. Cette fonction est utilisée par Detect-Cycle mais peut également être appelée directement pour des cas d'utilisation avancés.

#### Syntaxe

```powershell
Find-GraphCycle -Graph <Hashtable> [-MaxDepth <Int32>] [-UseIterative]
```

#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| Graph | Hashtable | Oui | Table de hachage représentant le graphe. |
| MaxDepth | Int32 | Non | Profondeur maximale de recherche. |
| UseIterative | SwitchParameter | Non | Utilise l'implémentation itérative au lieu de la récursion. |

#### Valeur de retour

Un objet PSCustomObject avec les propriétés suivantes :
- **HasCycle** : Booléen indiquant si un cycle a été détecté.
- **CyclePath** : Tableau des nœuds formant le cycle (si un cycle a été détecté).

#### Exemple

```powershell
$result = Find-GraphCycle -Graph $graph -UseIterative
```

### Find-DependencyCycles

Analyse les dépendances entre les scripts PowerShell pour détecter les cycles.

#### Syntaxe

```powershell
Find-DependencyCycles -Path <String> [-Recursive] [-OutputPath <String>]
```

#### Paramètres

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| Path | String | Oui | Chemin du dossier ou fichier à analyser. |
| Recursive | SwitchParameter | Non | Analyse récursivement les sous-dossiers. |
| OutputPath | String | Non | Chemin du fichier de sortie pour le rapport JSON. |

#### Valeur de retour

Un objet PSCustomObject avec les propriétés suivantes :
- **HasCycles** : Booléen indiquant si des cycles ont été détectés.
- **Cycles** : Tableau des cycles détectés.
- **DependencyGraph** : Graphe de dépendances complet.
- **NonCyclicScripts** : Scripts sans dépendances cycliques.

#### Exemple

```powershell
$result = Find-DependencyCycles -Path ".\development\scripts" -Recursive -OutputPath ".\reports\dependencies.json"
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

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| WorkflowPath | String | Oui | Chemin du fichier de workflow n8n à analyser. |

#### Valeur de retour

Un objet PSCustomObject avec les propriétés suivantes :
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

| Nom | Type | Obligatoire | Description |
|-----|------|-------------|-------------|
| Graph | Hashtable | Oui | Table de hachage représentant le graphe. |
| Cycle | String[] | Oui | Tableau des nœuds formant le cycle à supprimer. |

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

### Get-CycleDetectionStatistics

Récupère les statistiques d'utilisation du détecteur de cycles.

#### Syntaxe

```powershell
Get-CycleDetectionStatistics
```

#### Paramètres

Aucun.

#### Valeur de retour

Un objet PSCustomObject avec les propriétés suivantes :
- **TotalCalls** : Nombre total d'appels au détecteur de cycles.
- **TotalCycles** : Nombre total de cycles détectés.
- **AverageExecutionTime** : Temps d'exécution moyen en millisecondes.
- **CacheHits** : Nombre de fois où le cache a été utilisé.
- **CacheMisses** : Nombre de fois où le cache n'a pas été utilisé.

#### Exemple

```powershell
$stats = Get-CycleDetectionStatistics
Write-Host "Nombre total de cycles détectés: $($stats.TotalCycles)"
Write-Host "Temps d'exécution moyen: $($stats.AverageExecutionTime) ms"
```

### Clear-CycleDetectionCache

Efface le cache du détecteur de cycles.

#### Syntaxe

```powershell
Clear-CycleDetectionCache
```

#### Paramètres

Aucun.

#### Valeur de retour

Aucune valeur de retour.

#### Exemple

```powershell
Clear-CycleDetectionCache
```

## Variables globales

Le module utilise les variables globales suivantes :

| Nom | Type | Description |
|-----|------|-------------|
| $script:CycleDetectorEnabled | Boolean | Indique si le détecteur de cycles est activé. |
| $script:CycleDetectorMaxDepth | Int32 | Profondeur maximale de recherche. |
| $script:CycleDetectorCacheEnabled | Boolean | Indique si la mise en cache est activée. |
| $script:CycleDetectorCache | Hashtable | Cache des résultats de détection de cycles. |
| $script:CycleDetectorStats | PSCustomObject | Statistiques d'utilisation du détecteur de cycles. |

## Conventions de nommage

Le module suit les conventions de nommage PowerShell :
- Les noms de fonctions utilisent le format Verbe-Nom.
- Les verbes sont des verbes PowerShell approuvés.
- Les paramètres utilisent le format PascalCase.
- Les variables internes utilisent le format camelCase.

## Gestion des erreurs

Le module utilise le système de gestion des erreurs de PowerShell :
- Les erreurs non récupérables sont signalées avec `Write-Error`.
- Les avertissements sont signalés avec `Write-Warning`.
- Les informations sont signalées avec `Write-Verbose`.

## Compatibilité

Le module est compatible avec :
- PowerShell 5.1 et versions ultérieures
- PowerShell 7.x

## Dépendances

Le module n'a pas de dépendances externes.
