# Guide de gestion des dépendances

## Introduction

La gestion des dépendances est un aspect crucial du développement logiciel moderne. Elle permet de comprendre, organiser et optimiser les relations entre les différents composants d'un système. Le module `DependencyManager` fournit des outils puissants pour gérer les dépendances entre les scripts, les modules et les workflows dans votre projet.

Ce guide vous expliquera comment utiliser efficacement le module `DependencyManager` pour analyser, résoudre et optimiser les dépendances dans vos projets.

## Prérequis

Avant de commencer, assurez-vous de disposer des éléments suivants :

- PowerShell 5.1 ou PowerShell 7+ installé
- Le module `DependencyManager.psm1` disponible dans votre projet
- Connaissances de base sur les dépendances logicielles

## Installation et configuration

### Installation du module

Pour utiliser le module `DependencyManager`, vous devez d'abord l'importer dans votre session PowerShell :

```powershell
# Importer le module
Import-Module -Path ".\modules\DependencyManager.psm1" -Force
```

### Initialisation du module

Après avoir importé le module, vous devez l'initialiser avec les paramètres souhaités :

```powershell
# Initialisation avec les paramètres par défaut
Initialize-DependencyManager

# Ou avec des paramètres personnalisés
Initialize-DependencyManager -Enabled $true -CacheEnabled $true -MaxDepth 100 -ConfigPath ".\config\custom_dependency_config.json"
```

Les paramètres disponibles sont :

- `Enabled` : Active ou désactive le gestionnaire de dépendances (par défaut : $true)
- `CacheEnabled` : Active ou désactive la mise en cache des résultats (par défaut : $true)
- `MaxDepth` : Profondeur maximale de recherche pour l'analyse des dépendances (par défaut : 100)
- `ConfigPath` : Chemin du fichier de configuration (par défaut : ".\config\dependency_manager.json")

## Concepts de base

### Qu'est-ce qu'une dépendance ?

Une dépendance est une relation entre deux composants logiciels où l'un (le dépendant) a besoin de l'autre (la dépendance) pour fonctionner correctement. Dans le contexte de PowerShell, les dépendances peuvent être :

- Un script qui appelle un autre script
- Un script qui importe un module
- Un module qui dépend d'un autre module
- Un workflow qui utilise un autre workflow

### Types de dépendances gérées

Le module `DependencyManager` peut gérer différents types de dépendances :

1. **Dépendances de scripts** : Dépendances entre scripts PowerShell.
2. **Dépendances de modules** : Dépendances entre modules PowerShell.
3. **Dépendances externes** : Dépendances vers des composants externes (assemblies .NET, modules tiers, etc.).

## Utilisation de base

### Analyse des dépendances d'un script

Pour analyser les dépendances d'un script, utilisez la fonction `Get-ScriptDependencies` :

```powershell
# Analyser les dépendances d'un script
$dependencies = Get-ScriptDependencies -Path ".\scripts\main.ps1" -IncludeExternal

# Afficher les dépendances
Write-Host "Dépendances du script $($dependencies.ScriptPath):"
foreach ($dep in $dependencies.Dependencies) {
    Write-Host "- $dep"
}

Write-Host "`nDépendances externes:"
foreach ($extDep in $dependencies.ExternalDependencies) {
    Write-Host "- $extDep"
}
```

Les paramètres disponibles sont :

- `Path` : Chemin du script ou du dossier à analyser
- `Recursive` : Analyse récursivement les sous-dossiers
- `IncludeExternal` : Inclut les dépendances externes (modules, assemblies, etc.)
- `ExcludePattern` : Expression régulière pour exclure certains fichiers ou dossiers

### Résolution de l'ordre d'exécution des scripts

Pour résoudre l'ordre d'exécution des scripts en fonction de leurs dépendances, utilisez la fonction `Resolve-DependencyOrder` :

```powershell
# Résoudre l'ordre d'exécution des scripts
$order = Resolve-DependencyOrder -Path ".\scripts" -Recursive -OutputPath ".\execution_order.json" -Format "JSON"

# Afficher l'ordre d'exécution
Write-Host "Ordre d'exécution des scripts:"
foreach ($script in $order.ExecutionOrder) {
    Write-Host "- $script"
}

if ($order.CyclicDependencies.Count -gt 0) {
    Write-Host "`nAttention: Dépendances cycliques détectées:"
    foreach ($cycle in $order.CyclicDependencies) {
        Write-Host "- $($cycle -join ' -> ')"
    }
}
```

Les paramètres disponibles sont :

- `Path` : Chemin du dossier contenant les scripts à analyser
- `Recursive` : Analyse récursivement les sous-dossiers
- `OutputPath` : Chemin de sortie pour le fichier d'ordre d'exécution
- `Format` : Format de sortie (JSON, CSV, TXT)

### Test des dépendances d'un module

Pour tester les dépendances d'un module PowerShell, utilisez la fonction `Test-ModuleDependencies` :

```powershell
# Tester les dépendances d'un module
$moduleDeps = Test-ModuleDependencies -ModulePath ".\modules\MyModule" -IncludeVersion -CheckAvailability

# Afficher les dépendances
Write-Host "Dépendances du module $($moduleDeps.ModuleName):"
foreach ($dep in $moduleDeps.Dependencies) {
    $status = if ($moduleDeps.MissingDependencies -contains $dep) { "Manquant" } else { "Disponible" }
    Write-Host "- $($dep.Name) $(if ($dep.Version) { "($($dep.Version))" }) - $status"
}
```

Les paramètres disponibles sont :

- `ModulePath` : Chemin du module à analyser
- `IncludeVersion` : Inclut les informations de version des dépendances
- `CheckAvailability` : Vérifie la disponibilité des dépendances

## Exemples avancés

### Exemple 1 : Installation automatique des dépendances manquantes

Vous pouvez utiliser la fonction `Install-Dependencies` pour installer automatiquement les dépendances manquantes :

```powershell
# Tester les dépendances d'un module
$moduleDeps = Test-ModuleDependencies -ModulePath ".\modules\MyModule" -IncludeVersion -CheckAvailability

# Installer les dépendances manquantes
if ($moduleDeps.MissingDependencies.Count -gt 0) {
    Write-Host "Installation des dépendances manquantes..."
    $result = Install-Dependencies -Path ".\modules\MyModule" -Scope "CurrentUser"
    
    Write-Host "Dépendances installées:"
    foreach ($dep in $result.InstalledDependencies) {
        Write-Host "- $($dep.Name) $($dep.Version)"
    }
    
    if ($result.FailedDependencies.Count -gt 0) {
        Write-Host "`nDépendances dont l'installation a échoué:"
        foreach ($failedDep in $result.FailedDependencies) {
            Write-Host "- $($failedDep.Name) : $($failedDep.Error)"
        }
    }
}
```

### Exemple 2 : Génération de statistiques sur les dépendances

Vous pouvez générer des statistiques détaillées sur les dépendances avec la fonction `Get-DependencyStatistics` :

```powershell
# Générer des statistiques sur les dépendances
$stats = Get-DependencyStatistics -Path ".\scripts" -Recursive -IncludeExternal

# Afficher les statistiques
Write-Host "Statistiques de dépendances:"
Write-Host "Nombre de scripts: $($stats.ScriptCount)"
Write-Host "Nombre total de dépendances: $($stats.TotalDependencies)"
Write-Host "Nombre moyen de dépendances par script: $($stats.AverageDependenciesPerScript)"

if ($stats.MaxDependencies) {
    Write-Host "Script avec le plus de dépendances: $($stats.MaxDependencies.Script) ($($stats.MaxDependencies.Count) dépendances)"
}

if ($stats.MinDependencies) {
    Write-Host "Script avec le moins de dépendances: $($stats.MinDependencies.Script) ($($stats.MinDependencies.Count) dépendances)"
}

if ($stats.CyclicDependencies.Count -gt 0) {
    Write-Host "`nDépendances cycliques détectées:"
    foreach ($cycle in $stats.CyclicDependencies) {
        Write-Host "- $($cycle -join ' -> ')"
    }
}
```

### Exemple 3 : Visualisation du graphe de dépendances

Vous pouvez générer une visualisation du graphe de dépendances avec la fonction `Export-DependencyGraph` :

```powershell
# Exporter le graphe de dépendances
$graph = Export-DependencyGraph -Path ".\scripts" -OutputPath ".\dependency_graph.html" -Format "HTML" -IncludeExternal -Recursive

# Afficher les informations sur le graphe
Write-Host "Graphe de dépendances exporté: $($graph.OutputPath)"
Write-Host "Format: $($graph.Format)"
Write-Host "Nombre de nœuds: $($graph.NodeCount)"
Write-Host "Nombre d'arêtes: $($graph.EdgeCount)"
```

### Exemple 4 : Optimisation des dépendances

Vous pouvez optimiser les dépendances de vos scripts avec la fonction `Optimize-Dependencies` :

```powershell
# Analyser et obtenir des suggestions d'optimisation
$optimization = Optimize-Dependencies -Path ".\scripts" -Recursive -OutputPath ".\optimization_report.json"

# Afficher les suggestions d'optimisation
Write-Host "Nombre de scripts analysés: $($optimization.ScriptsAnalyzed)"
Write-Host "Suggestions d'optimisation:"
foreach ($suggestion in $optimization.OptimizationSuggestions) {
    Write-Host "- $($suggestion.Script): $($suggestion.Description)"
}

# Demander confirmation pour appliquer les changements
$confirmation = Read-Host "Voulez-vous appliquer les changements recommandés? (O/N)"
if ($confirmation -eq "O") {
    # Appliquer les changements recommandés
    $appliedOptimization = Optimize-Dependencies -Path ".\scripts" -Recursive -ApplyChanges
    
    # Afficher les changements appliqués
    Write-Host "`nChangements appliqués:"
    foreach ($change in $appliedOptimization.AppliedChanges) {
        Write-Host "- $($change.Script): $($change.Description)"
    }
}
```

## Intégration avec d'autres modules

### Intégration avec le module CycleDetector

Le module `DependencyManager` s'intègre parfaitement avec le module `CycleDetector` pour détecter et résoudre les cycles de dépendances :

```powershell
# Importer les modules
Import-Module -Path ".\modules\CycleDetector.psm1" -Force
Import-Module -Path ".\modules\DependencyManager.psm1" -Force

# Initialiser les modules
Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
Initialize-DependencyManager -Enabled $true -CacheEnabled $true -MaxDepth 100

# Analyser les dépendances dans un dossier de scripts
$dependencies = Get-ScriptDependencies -Path ".\scripts" -Recursive

# Détecter les cycles dans le graphe de dépendances
$cycleResult = Find-Cycle -Graph $dependencies.DependencyGraph

if ($cycleResult.HasCycle) {
    Write-Host "Cycle détecté dans les dépendances: $($cycleResult.CyclePath -join ' -> ')"
    
    # Résoudre l'ordre d'exécution en tenant compte des cycles
    $order = Resolve-DependencyOrder -Path ".\scripts" -Recursive -OutputPath ".\execution_order.json" -Format "JSON"
    
    Write-Host "`nOrdre d'exécution résolu:"
    foreach ($script in $order.ExecutionOrder) {
        Write-Host "- $script"
    }
    
    # Optimiser les dépendances pour éliminer les cycles
    Write-Host "`nOptimisation des dépendances pour éliminer les cycles..."
    $optimization = Optimize-Dependencies -Path ".\scripts" -Recursive -ApplyChanges
    
    # Vérifier si les cycles ont été éliminés
    $newDependencies = Get-ScriptDependencies -Path ".\scripts" -Recursive
    $newCycleResult = Find-Cycle -Graph $newDependencies.DependencyGraph
    
    if (-not $newCycleResult.HasCycle) {
        Write-Host "Les cycles ont été éliminés avec succès!"
    } else {
        Write-Host "Des cycles persistent dans les dépendances: $($newCycleResult.CyclePath -join ' -> ')"
    }
}
```

## Dépannage

### Problème : Dépendances non détectées

Si certaines dépendances ne sont pas détectées, vérifiez que les chemins sont corrects et que les fichiers sont accessibles. Vous pouvez également augmenter la profondeur maximale de recherche :

```powershell
Initialize-DependencyManager -MaxDepth 200
```

### Problème : Erreurs lors de l'installation des dépendances

Si vous rencontrez des erreurs lors de l'installation des dépendances, vérifiez que vous avez les droits d'administrateur nécessaires et que les sources de modules sont configurées correctement.

### Problème : Performances lentes sur de grands projets

Si les performances sont lentes sur de grands projets, assurez-vous que le cache est activé :

```powershell
Initialize-DependencyManager -CacheEnabled $true
```

## Bonnes pratiques

- **Organisez vos scripts** en modules cohérents pour faciliter la gestion des dépendances.
- **Évitez les dépendances circulaires** qui peuvent causer des problèmes d'exécution.
- **Utilisez des chemins absolus** pour éviter les problèmes de résolution de chemins relatifs.
- **Documentez vos dépendances** pour faciliter la maintenance.
- **Analysez régulièrement** vos dépendances pour détecter les problèmes potentiels.
- **Utilisez la mise en cache** pour améliorer les performances sur les grands projets.
- **Exportez des visualisations** pour mieux comprendre les relations entre vos composants.

## FAQ

### Comment le module détecte-t-il les dépendances entre scripts ?

Le module analyse le contenu des scripts PowerShell pour détecter les appels à d'autres scripts, les importations de modules, etc. Il construit ensuite un graphe de dépendances pour représenter ces relations.

### Puis-je exclure certains fichiers ou dossiers de l'analyse ?

Oui, vous pouvez utiliser le paramètre `ExcludePattern` avec une expression régulière pour exclure certains fichiers ou dossiers de l'analyse.

### Comment gérer les dépendances externes ?

Vous pouvez utiliser le paramètre `IncludeExternal` avec la fonction `Get-ScriptDependencies` pour inclure les dépendances externes dans l'analyse. Vous pouvez ensuite utiliser la fonction `Install-Dependencies` pour installer automatiquement ces dépendances.

### Comment résoudre les cycles de dépendances ?

Vous pouvez utiliser la fonction `Optimize-Dependencies` pour obtenir des suggestions d'optimisation qui peuvent résoudre les cycles de dépendances. Vous pouvez également utiliser le module `CycleDetector` pour détecter et résoudre manuellement les cycles.

## Ressources supplémentaires

- [Documentation API du module DependencyManager](../api/DependencyManager.html)
- [Exemples d'utilisation du module DependencyManager](../api/examples/DependencyManager_Examples.html)
- [Guide de détection de cycles](cycle_detection.md)
- [Documentation technique sur la gestion des dépendances](../technical/DependencyManager.md)
