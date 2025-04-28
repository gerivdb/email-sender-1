# Guide d'utilisation de Invoke-CachedPSScriptAnalyzer

Ce guide explique comment utiliser le script `Invoke-CachedPSScriptAnalyzer.ps1` pour analyser des scripts PowerShell avec PSScriptAnalyzer et amÃ©liorer les performances grÃ¢ce Ã  la mise en cache des rÃ©sultats.

## PrÃ©requis

- PowerShell 5.1 ou supÃ©rieur
- PSScriptAnalyzer (installÃ© automatiquement si nÃ©cessaire)
- Module PRAnalysisCache.psm1 (fourni avec le script)

## Installation

Aucune installation n'est nÃ©cessaire. Le script peut Ãªtre exÃ©cutÃ© directement depuis le rÃ©pertoire oÃ¹ il se trouve.

## Utilisation de base

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\development\scripts" -OutputPath "results.json" -Recurse -UseCache
```

## ParamÃ¨tres

- **Path** (obligatoire) : Chemin du fichier ou du rÃ©pertoire Ã  analyser.
- **IncludeRule** : Liste des rÃ¨gles Ã  inclure dans l'analyse.
- **ExcludeRule** : Liste des rÃ¨gles Ã  exclure de l'analyse.
- **Severity** : Niveau de sÃ©vÃ©ritÃ© minimum des problÃ¨mes Ã  signaler (Error, Warning, Information).
- **OutputPath** : Chemin du fichier de sortie pour les rÃ©sultats de l'analyse.
- **Recurse** : Indique si les sous-rÃ©pertoires doivent Ãªtre analysÃ©s.
- **UseCache** : Indique si le cache doit Ãªtre utilisÃ© pour amÃ©liorer les performances. Par dÃ©faut, le cache n'est pas utilisÃ©.
- **CacheTTLHours** : DurÃ©e de vie des Ã©lÃ©ments du cache en heures. Par dÃ©faut : 24 heures.
- **ForceRefresh** : Force l'actualisation du cache mÃªme si les rÃ©sultats sont dÃ©jÃ  en cache.

## Exemples

### Analyser un seul fichier

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\script.ps1" -OutputPath "results.json" -UseCache
```

### Analyser un rÃ©pertoire et ses sous-rÃ©pertoires

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\development\scripts" -OutputPath "results.json" -Recurse -UseCache
```

### Analyser avec des rÃ¨gles spÃ©cifiques

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\development\scripts" -IncludeRule "PSAvoidUsingCmdletAliases", "PSAvoidUsingPositionalParameters" -OutputPath "results.json" -Recurse -UseCache
```

### Analyser sans utiliser le cache

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\development\scripts" -OutputPath "results.json" -Recurse -UseCache:$false
```

### Forcer l'actualisation du cache

```powershell
.\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\development\scripts" -OutputPath "results.json" -Recurse -UseCache -ForceRefresh
```

## Fonctionnement du cache

Le script utilise le module PRAnalysisCache pour mettre en cache les rÃ©sultats de l'analyse. Le cache est stockÃ© Ã  la fois en mÃ©moire et sur disque :

- **Cache en mÃ©moire** : Stocke jusqu'Ã  1000 rÃ©sultats d'analyse en mÃ©moire pour un accÃ¨s rapide.
- **Cache sur disque** : Stocke les rÃ©sultats d'analyse sur disque dans le rÃ©pertoire `%TEMP%\PSScriptAnalyzerCache`.

Le cache utilise une clÃ© unique basÃ©e sur :
- Le chemin du fichier
- La date de derniÃ¨re modification du fichier
- Les rÃ¨gles incluses et exclues
- Les niveaux de sÃ©vÃ©ritÃ©

Cela garantit que le cache est invalidÃ© automatiquement lorsque le fichier est modifiÃ© ou lorsque les paramÃ¨tres d'analyse changent.

## Test des performances

Pour tester les performances de l'analyse avec et sans cache, utilisez le script `Test-CachedPSScriptAnalyzer.ps1` :

```powershell
.\Test-CachedPSScriptAnalyzer.ps1 -Path ".\development\scripts"
```

Ce script exÃ©cute l'analyse trois fois :
1. Sans cache
2. Avec cache (premier accÃ¨s)
3. Avec cache (deuxiÃ¨me accÃ¨s)

Il affiche ensuite les statistiques de performance et l'accÃ©lÃ©ration obtenue grÃ¢ce au cache.

## DÃ©pannage

### Le cache ne fonctionne pas

- VÃ©rifiez que le module PRAnalysisCache.psm1 est correctement importÃ©
- VÃ©rifiez que le paramÃ¨tre `-UseCache` est activÃ©
- VÃ©rifiez que le rÃ©pertoire de cache est accessible en Ã©criture

### Les rÃ©sultats du cache sont obsolÃ¨tes

- Utilisez le paramÃ¨tre `-ForceRefresh` pour forcer l'actualisation du cache
- VÃ©rifiez que la date de modification du fichier est correcte

### Erreurs lors de l'analyse

- VÃ©rifiez que PSScriptAnalyzer est correctement installÃ©
- VÃ©rifiez que les fichiers Ã  analyser sont des scripts PowerShell valides
- VÃ©rifiez les rÃ¨gles incluses et exclues

## Conclusion

Le script `Invoke-CachedPSScriptAnalyzer.ps1` permet d'analyser des scripts PowerShell avec PSScriptAnalyzer tout en amÃ©liorant les performances grÃ¢ce Ã  la mise en cache des rÃ©sultats. Il est particuliÃ¨rement utile pour les analyses rÃ©pÃ©tÃ©es des mÃªmes fichiers, comme dans les pipelines CI/CD ou les environnements de dÃ©veloppement.
