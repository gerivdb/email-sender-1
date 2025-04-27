# Tests avec des pull requests rÃ©elles

Ce dossier contient les scripts nÃ©cessaires pour tester le systÃ¨me d'analyse des pull requests avec des pull requests rÃ©elles.

## Scripts inclus

- **New-TestRepository.ps1** : CrÃ©e un dÃ©pÃ´t Git de test isolÃ© pour les tests de pull requests
- **New-TestPullRequest.ps1** : GÃ©nÃ¨re des pull requests de test avec diffÃ©rents types de modifications
- **Measure-PRAnalysisPerformance.ps1** : Mesure les performances du systÃ¨me d'analyse des pull requests
- **Start-PRTestSuite.ps1** : ExÃ©cute une suite complÃ¨te de tests pour le systÃ¨me d'analyse

## Utilisation

### CrÃ©ation d'un dÃ©pÃ´t de test

```powershell
.\New-TestRepository.ps1 -Path "D:\TestRepos\PR-Test" -SourceRepo "D:\MyProject"
```

Ce script crÃ©e un dÃ©pÃ´t Git isolÃ© pour les tests de pull requests. Il configure le dÃ©pÃ´t avec la mÃªme structure que le dÃ©pÃ´t principal et met en place les branches nÃ©cessaires.

### GÃ©nÃ©ration d'une pull request de test

```powershell
.\New-TestPullRequest.ps1 -FileCount 10 -ErrorCount 5 -ErrorTypes "Syntax,Style" -ModificationTypes "Mixed"
```

Ce script crÃ©e une pull request de test avec diffÃ©rents types de modifications (ajouts, modifications, suppressions) et injecte des erreurs connues pour tester le systÃ¨me d'analyse.

### Mesure des performances

```powershell
.\Measure-PRAnalysisPerformance.ps1 -PullRequestNumber 42 -DetailedReport $true
```

Ce script mesure les performances du systÃ¨me d'analyse des pull requests en collectant des mÃ©triques sur les temps d'exÃ©cution, la prÃ©cision des dÃ©tections d'erreurs et l'utilisation des ressources.

### ExÃ©cution de la suite de tests complÃ¨te

```powershell
.\Start-PRTestSuite.ps1 -CreateRepository $true -RunAllTests $true -GenerateReport $true
```

Ce script exÃ©cute une suite complÃ¨te de tests pour le systÃ¨me d'analyse des pull requests en gÃ©nÃ©rant diffÃ©rents types de pull requests et en mesurant les performances de l'analyse.

## Types de modifications

- **Add** : Ajout de nouveaux fichiers
- **Modify** : Modification de fichiers existants
- **Delete** : Suppression de fichiers existants
- **Mixed** : Combinaison d'ajouts, de modifications et de suppressions

## Types d'erreurs

- **Syntax** : Erreurs de syntaxe PowerShell (parenthÃ¨ses manquantes, accolades non fermÃ©es, etc.)
- **Style** : ProblÃ¨mes de style (verbes non approuvÃ©s, variables non utilisÃ©es, etc.)
- **Performance** : ProblÃ¨mes de performance (appels inutiles, utilisation inefficace des ressources, etc.)
- **Security** : ProblÃ¨mes de sÃ©curitÃ© (mots de passe en clair, exÃ©cution de code non sÃ©curisÃ©e, etc.)
- **All** : Tous les types d'erreurs

## Rapports

Les rapports de performance sont gÃ©nÃ©rÃ©s dans le dossier `reports` et contiennent des informations dÃ©taillÃ©es sur les performances du systÃ¨me d'analyse, les erreurs dÃ©tectÃ©es et des recommandations pour l'amÃ©lioration.

## Bonnes pratiques

1. Toujours utiliser un dÃ©pÃ´t de test isolÃ© pour Ã©viter d'interfÃ©rer avec le dÃ©pÃ´t principal
2. Commencer par des tests simples avant de passer Ã  des scÃ©narios plus complexes
3. Analyser les rapports de performance pour identifier les opportunitÃ©s d'optimisation
4. ExÃ©cuter rÃ©guliÃ¨rement la suite de tests pour surveiller les performances du systÃ¨me

## Exemples de scÃ©narios de test

### Test de base avec diffÃ©rents types de modifications

```powershell
.\New-TestPullRequest.ps1 -ModificationTypes "Add" -FileCount 5 -ErrorCount 3
.\New-TestPullRequest.ps1 -ModificationTypes "Modify" -FileCount 5 -ErrorCount 3
.\New-TestPullRequest.ps1 -ModificationTypes "Delete" -FileCount 3
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 8 -ErrorCount 3
```

### Test avec diffÃ©rents volumes

```powershell
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 3 -ErrorCount 2
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 10 -ErrorCount 2
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 20 -ErrorCount 2
```

### Test avec diffÃ©rents types d'erreurs

```powershell
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 5 -ErrorCount 3 -ErrorTypes "Syntax"
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 5 -ErrorCount 3 -ErrorTypes "Style"
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 5 -ErrorCount 3 -ErrorTypes "Performance"
.\New-TestPullRequest.ps1 -ModificationTypes "Mixed" -FileCount 5 -ErrorCount 3 -ErrorTypes "Security"
```
