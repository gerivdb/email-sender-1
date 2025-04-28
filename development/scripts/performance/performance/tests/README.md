# Tests de performance pour l'architecture hybride PowerShell-Python

## Test du script AutoHotkey - Test final

Ce rÃ©pertoire contient les tests unitaires et de performance pour l'architecture hybride PowerShell-Python. Ces tests permettent de vÃ©rifier le bon fonctionnement des scripts et de mesurer leurs performances.

## Structure des tests

Les tests sont organisÃ©s en plusieurs fichiers :

- **Functions.Tests.ps1** : Tests unitaires pour les fonctions communes utilisÃ©es dans les scripts de performance.
- **HtmlReporting.Tests.ps1** : Tests pour les fonctions de gÃ©nÃ©ration de rapports HTML.
- **TestDataManagement.Tests.ps1** : Tests pour la gestion des donnÃ©es de test.
- **Integration.Tests.ps1** : Tests d'intÃ©gration pour vÃ©rifier l'interaction entre les diffÃ©rentes fonctions.
- **Performance.Tests.ps1** : Tests de performance pour mesurer les amÃ©liorations apportÃ©es.
- **ParallelScenarios.Tests.ps1** : Tests pour les scÃ©narios de test parallÃ¨les.
- **PerformanceBenchmark.Tests.ps1** : Tests de benchmark pour comparer les performances de diffÃ©rentes implÃ©mentations.
- **Optimize-ParallelBatchSize.Tests.ps1** : Tests pour l'optimisation de la taille des lots en traitement parallÃ¨le.

## ExÃ©cution des tests

### ExÃ©cution de tous les tests

Pour exÃ©cuter tous les tests, utilisez le script `Run-AllTests.ps1` :

```powershell
.\Run-AllTests.ps1
```

Par dÃ©faut, ce script exÃ©cute tous les tests et gÃ©nÃ¨re un rapport HTML des rÃ©sultats.

### Options d'exÃ©cution

Le script `Run-AllTests.ps1` accepte les paramÃ¨tres suivants :

- **GenerateReport** : Indique si un rapport HTML des rÃ©sultats doit Ãªtre gÃ©nÃ©rÃ© (par dÃ©faut : $true).
- **OutputPath** : Chemin oÃ¹ les rÃ©sultats des tests seront enregistrÃ©s (par dÃ©faut : "$PSScriptRoot\TestResults").

Exemple :

```powershell
.\Run-AllTests.ps1 -GenerateReport $true -OutputPath "C:\TestResults"
```

### ExÃ©cution dans un environnement CI/CD

Pour exÃ©cuter les tests dans un environnement CI/CD, utilisez le script `Run-CITests.ps1` :

```powershell
.\Run-CITests.ps1 -ThresholdPercent 70
```

Ce script exÃ©cute tous les tests, gÃ©nÃ¨re des rapports de couverture et de rÃ©sultats au format compatible avec les systÃ¨mes CI/CD, et vÃ©rifie que la couverture de code est supÃ©rieure au seuil spÃ©cifiÃ©.

## Types de tests

### Tests unitaires

Les tests unitaires vÃ©rifient le bon fonctionnement des fonctions individuelles. Ils sont organisÃ©s en contextes (Context) et en tests (It).

Exemple de test unitaire :

```powershell
Describe "Fonctions communes des scripts de performance" {
    Context "New-DirectoryIfNotExists" {
        It "CrÃ©e un rÃ©pertoire s'il n'existe pas" {
            # Test code here
        }
    }
}
```

### Tests d'intÃ©gration

Les tests d'intÃ©gration vÃ©rifient l'interaction entre les diffÃ©rentes fonctions et le flux de travail complet.

Exemple de test d'intÃ©gration :

```powershell
Describe "Tests d'intÃ©gration des scripts de performance" {
    Context "Flux de travail complet" {
        It "ExÃ©cute correctement le flux de travail complet" {
            # Test code here
        }
    }
}
```

### Tests de performance

Les tests de performance mesurent les performances des fonctions et comparent les diffÃ©rentes implÃ©mentations.

Exemple de test de performance :

```powershell
Describe "Tests de performance" {
    Context "Mesure des performances des fonctions" {
        It "Compare les performances des fonctions de tri" {
            # Test code here
        }
    }
}
```

### Tests de benchmark

Les tests de benchmark comparent les performances de diffÃ©rentes implÃ©mentations et mesurent la scalabilitÃ© des fonctions avec diffÃ©rentes tailles de donnÃ©es.

Exemple de test de benchmark :

```powershell
Describe "Tests de benchmark de performance" {
    Context "Comparaison des performances entre diffÃ©rentes implÃ©mentations" {
        It "Compare les performances du tri avec diffÃ©rentes approches" {
            # Test code here
        }
    }
}
```

## Couverture de code

Les tests sont configurÃ©s pour mesurer la couverture de code. Le rapport de couverture est gÃ©nÃ©rÃ© au format JaCoCo et enregistrÃ© dans le rÃ©pertoire des rÃ©sultats des tests.

Pour visualiser la couverture de code, ouvrez le fichier `coverage.xml` dans un outil compatible avec le format JaCoCo, comme ReportGenerator ou un plugin d'IDE.

## Ajout de nouveaux tests

### Structure d'un test

Un test Pester est structurÃ© comme suit :

1. **Describe** : DÃ©crit un ensemble de tests liÃ©s Ã  une fonctionnalitÃ© ou un composant.
2. **Context** : DÃ©crit un contexte ou un scÃ©nario spÃ©cifique dans lequel les tests sont exÃ©cutÃ©s.
3. **BeforeAll** : Code exÃ©cutÃ© une fois avant tous les tests dans le contexte.
4. **It** : Un test individuel qui vÃ©rifie un comportement spÃ©cifique.
5. **Should** : Une assertion qui vÃ©rifie que le rÃ©sultat est conforme aux attentes.

### Exemple de test

```powershell
Describe "Ma fonctionnalitÃ©" {
    Context "Dans un contexte spÃ©cifique" {
        BeforeAll {
            # Code d'initialisation
            $testData = @(1, 2, 3)
        }

        It "Fait quelque chose de spÃ©cifique" {
            # Appeler la fonction Ã  tester
            $result = Do-Something -Data $testData

            # VÃ©rifier le rÃ©sultat
            $result | Should -Be 6
        }
    }
}
```

### Bonnes pratiques pour les tests

1. **Nommage explicite** : Donnez des noms clairs et descriptifs Ã  vos tests pour faciliter la comprÃ©hension de ce qu'ils testent.
2. **Tests isolÃ©s** : Chaque test doit Ãªtre indÃ©pendant des autres tests.
3. **Initialisation et nettoyage** : Utilisez BeforeAll, AfterAll, BeforeEach et AfterEach pour initialiser et nettoyer l'environnement de test.
4. **Assertions prÃ©cises** : Utilisez des assertions prÃ©cises pour vÃ©rifier les rÃ©sultats.
5. **Tests de cas limites** : Testez les cas limites et les cas d'erreur.
6. **Tests de performance** : Pour les tests de performance, utilisez des mesures prÃ©cises et rÃ©pÃ©tez les tests plusieurs fois pour obtenir des rÃ©sultats fiables.

### Ajout d'un nouveau fichier de test

Pour ajouter un nouveau fichier de test :

1. CrÃ©ez un nouveau fichier avec le suffixe `.Tests.ps1` dans le rÃ©pertoire des tests.
2. Structurez vos tests avec Describe, Context et It.
3. ExÃ©cutez les tests avec `Run-AllTests.ps1` pour vÃ©rifier qu'ils fonctionnent correctement.

## DÃ©pannage

### ProblÃ¨mes courants

1. **Tests qui Ã©chouent de maniÃ¨re intermittente** : Les tests de performance peuvent Ã©chouer de maniÃ¨re intermittente en raison de variations dans l'environnement d'exÃ©cution. Utilisez des tolÃ©rances appropriÃ©es et rÃ©pÃ©tez les tests plusieurs fois pour obtenir des rÃ©sultats fiables.

2. **Tests qui prennent trop de temps** : Les tests de performance peuvent prendre beaucoup de temps Ã  s'exÃ©cuter. Utilisez le paramÃ¨tre Skip pour ignorer les tests longs pendant le dÃ©veloppement.

3. **Erreurs de couverture de code** : Si la couverture de code est infÃ©rieure au seuil, vÃ©rifiez les parties du code qui ne sont pas couvertes et ajoutez des tests pour ces parties.

### RÃ©solution des problÃ¨mes

1. **ExÃ©cuter un test spÃ©cifique** : Pour exÃ©cuter un test spÃ©cifique, utilisez le paramÃ¨tre `-Name` de Invoke-Pester :

```powershell
Invoke-Pester -Path ".\MyTest.Tests.ps1" -Name "Ma fonctionnalitÃ©"
```

2. **DÃ©boguer un test** : Pour dÃ©boguer un test, utilisez Write-Host pour afficher des informations de dÃ©bogage ou utilisez le dÃ©bogueur de PowerShell :

```powershell
It "Mon test" {
    Write-Host "Valeur de la variable : $myVariable"
    # Test code here
}
```

3. **Ignorer un test** : Pour ignorer temporairement un test, utilisez le paramÃ¨tre Skip :

```powershell
It "Mon test" -Skip {
    # Test code here
}
```

## Ressources

- [Documentation Pester](https://pester.dev/docs/quick-start)
- [Guide de la couverture de code avec Pester](https://pester.dev/docs/usage/code-coverage)
- [Bonnes pratiques pour les tests unitaires](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations?view=powershell-7.1)
