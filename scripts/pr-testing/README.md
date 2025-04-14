# Tests avec des pull requests réelles

Ce dossier contient les scripts nécessaires pour tester le système d'analyse des pull requests avec des pull requests réelles.

## Scripts inclus

- **New-TestRepository.ps1** : Crée un dépôt Git de test isolé pour les tests de pull requests
- **New-TestPullRequest.ps1** : Génère des pull requests de test avec différents types de modifications
- **Measure-PRAnalysisPerformance.ps1** : Mesure les performances du système d'analyse des pull requests
- **Start-PRTestSuite.ps1** : Exécute une suite complète de tests pour le système d'analyse

## Utilisation

### Création d'un dépôt de test

```powershell
.\New-TestRepository.ps1 -Path "D:\TestRepos\PR-Test" -SourceRepo "D:\MyProject"
```

Ce script crée un dépôt Git isolé pour les tests de pull requests. Il configure le dépôt avec la même structure que le dépôt principal et met en place les branches nécessaires.

### Génération d'une pull request de test

```powershell
.\New-TestPullRequest.ps1 -FileCount 10 -ErrorCount 5 -ErrorTypes "Syntax,Style" -ModificationTypes "Mixed"
```

Ce script crée une pull request de test avec différents types de modifications (ajouts, modifications, suppressions) et injecte des erreurs connues pour tester le système d'analyse.

### Mesure des performances

```powershell
.\Measure-PRAnalysisPerformance.ps1 -PullRequestNumber 42 -DetailedReport $true
```

Ce script mesure les performances du système d'analyse des pull requests en collectant des métriques sur les temps d'exécution, la précision des détections d'erreurs et l'utilisation des ressources.

### Exécution de la suite de tests complète

```powershell
.\Start-PRTestSuite.ps1 -CreateRepository $true -RunAllTests $true -GenerateReport $true
```

Ce script exécute une suite complète de tests pour le système d'analyse des pull requests en générant différents types de pull requests et en mesurant les performances de l'analyse.

## Types de modifications

- **Add** : Ajout de nouveaux fichiers
- **Modify** : Modification de fichiers existants
- **Delete** : Suppression de fichiers existants
- **Mixed** : Combinaison d'ajouts, de modifications et de suppressions

## Types d'erreurs

- **Syntax** : Erreurs de syntaxe PowerShell (parenthèses manquantes, accolades non fermées, etc.)
- **Style** : Problèmes de style (verbes non approuvés, variables non utilisées, etc.)
- **Performance** : Problèmes de performance (appels inutiles, utilisation inefficace des ressources, etc.)
- **Security** : Problèmes de sécurité (mots de passe en clair, exécution de code non sécurisée, etc.)
- **All** : Tous les types d'erreurs

## Rapports

Les rapports de performance sont générés dans le dossier `reports` et contiennent des informations détaillées sur les performances du système d'analyse, les erreurs détectées et des recommandations pour l'amélioration.

## Bonnes pratiques

1. Toujours utiliser un dépôt de test isolé pour éviter d'interférer avec le dépôt principal
2. Commencer par des tests simples avant de passer à des scénarios plus complexes
3. Analyser les rapports de performance pour identifier les opportunités d'optimisation
4. Exécuter régulièrement la suite de tests pour surveiller les performances du système

## Exemples de scénarios de test

### Test de base avec différents types de modifications

```powershell
.\New-TestPullRequest.ps1 -ModificationTypes "Add" -FileCount 5 -ErrorCount 3
.\New-TestPullRequest.ps1 -ModificationTypes "Modify" -FileCount 5 -ErrorCount 3
.\New-TestPullRequest.ps1 -ModificationTypes "Delete" -FileCount 3
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 8 -ErrorCount 3
```

### Test avec différents volumes

```powershell
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 3 -ErrorCount 2
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 10 -ErrorCount 2
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 20 -ErrorCount 2
```

### Test avec différents types d'erreurs

```powershell
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 5 -ErrorCount 3 -ErrorTypes "Syntax"
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 5 -ErrorCount 3 -ErrorTypes "Style"
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 5 -ErrorCount 3 -ErrorTypes "Performance"
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 5 -ErrorCount 3 -ErrorTypes "Security"
```
