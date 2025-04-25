# Guide d'utilisation de Invoke-CachedPSScriptAnalyzer

Ce guide explique comment utiliser le script `Invoke-CachedPSScriptAnalyzer.ps1` pour analyser des scripts PowerShell avec PSScriptAnalyzer et améliorer les performances grâce à la mise en cache des résultats.

## Prérequis

- PowerShell 5.1 ou supérieur
- PSScriptAnalyzer (installé automatiquement si nécessaire)
- Module PRAnalysisCache.psm1 (fourni avec le script)

## Installation

Aucune installation n'est nécessaire. Le script peut être exécuté directement depuis le répertoire où il se trouve.

## Utilisation de base

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\scripts" -OutputPath "results.json" -Recurse -UseCache
```

## Paramètres

- **Path** (obligatoire) : Chemin du fichier ou du répertoire à analyser.
- **IncludeRule** : Liste des règles à inclure dans l'analyse.
- **ExcludeRule** : Liste des règles à exclure de l'analyse.
- **Severity** : Niveau de sévérité minimum des problèmes à signaler (Error, Warning, Information).
- **OutputPath** : Chemin du fichier de sortie pour les résultats de l'analyse.
- **Recurse** : Indique si les sous-répertoires doivent être analysés.
- **UseCache** : Indique si le cache doit être utilisé pour améliorer les performances. Par défaut, le cache n'est pas utilisé.
- **CacheTTLHours** : Durée de vie des éléments du cache en heures. Par défaut : 24 heures.
- **ForceRefresh** : Force l'actualisation du cache même si les résultats sont déjà en cache.

## Exemples

### Analyser un seul fichier

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\script.ps1" -OutputPath "results.json" -UseCache
```

### Analyser un répertoire et ses sous-répertoires

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\scripts" -OutputPath "results.json" -Recurse -UseCache
```

### Analyser avec des règles spécifiques

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\scripts" -IncludeRule "PSAvoidUsingCmdletAliases", "PSAvoidUsingPositionalParameters" -OutputPath "results.json" -Recurse -UseCache
```

### Analyser sans utiliser le cache

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\scripts" -OutputPath "results.json" -Recurse -UseCache:$false
```

### Forcer l'actualisation du cache

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\scripts" -OutputPath "results.json" -Recurse -UseCache -ForceRefresh
```

## Fonctionnement du cache

Le script utilise le module PRAnalysisCache pour mettre en cache les résultats de l'analyse. Le cache est stocké à la fois en mémoire et sur disque :

- **Cache en mémoire** : Stocke jusqu'à 1000 résultats d'analyse en mémoire pour un accès rapide.
- **Cache sur disque** : Stocke les résultats d'analyse sur disque dans le répertoire `%TEMP%\PSScriptAnalyzerCache`.

Le cache utilise une clé unique basée sur :
- Le chemin du fichier
- La date de dernière modification du fichier
- Les règles incluses et exclues
- Les niveaux de sévérité

Cela garantit que le cache est invalidé automatiquement lorsque le fichier est modifié ou lorsque les paramètres d'analyse changent.

## Test des performances

Pour tester les performances de l'analyse avec et sans cache, utilisez le script `Test-CachedPSScriptAnalyzer.ps1` :

```powershell
.\Test-CachedPSScriptAnalyzer.ps1 -Path ".\scripts"
```

Ce script exécute l'analyse trois fois :
1. Sans cache
2. Avec cache (premier accès)
3. Avec cache (deuxième accès)

Il affiche ensuite les statistiques de performance et l'accélération obtenue grâce au cache.

## Dépannage

### Le cache ne fonctionne pas

- Vérifiez que le module PRAnalysisCache.psm1 est correctement importé
- Vérifiez que le paramètre `-UseCache` est activé
- Vérifiez que le répertoire de cache est accessible en écriture

### Les résultats du cache sont obsolètes

- Utilisez le paramètre `-ForceRefresh` pour forcer l'actualisation du cache
- Vérifiez que la date de modification du fichier est correcte

### Erreurs lors de l'analyse

- Vérifiez que PSScriptAnalyzer est correctement installé
- Vérifiez que les fichiers à analyser sont des scripts PowerShell valides
- Vérifiez les règles incluses et exclues

## Conclusion

Le script `Invoke-CachedPSScriptAnalyzer.ps1` permet d'analyser des scripts PowerShell avec PSScriptAnalyzer tout en améliorant les performances grâce à la mise en cache des résultats. Il est particulièrement utile pour les analyses répétées des mêmes fichiers, comme dans les pipelines CI/CD ou les environnements de développement.
