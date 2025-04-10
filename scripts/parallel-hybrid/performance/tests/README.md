# Tests de performance pour l'architecture hybride PowerShell-Python

Ce répertoire contient les tests unitaires et de performance pour l'architecture hybride PowerShell-Python. Ces tests permettent de vérifier le bon fonctionnement des scripts et de mesurer leurs performances.

## Structure des tests

Les tests sont organisés en plusieurs fichiers :

- **Functions.Tests.ps1** : Tests unitaires pour les fonctions communes utilisées dans les scripts de performance.
- **HtmlReporting.Tests.ps1** : Tests pour les fonctions de génération de rapports HTML.
- **TestDataManagement.Tests.ps1** : Tests pour la gestion des données de test.
- **Integration.Tests.ps1** : Tests d'intégration pour vérifier l'interaction entre les différentes fonctions.
- **Performance.Tests.ps1** : Tests de performance pour mesurer les améliorations apportées.
- **ParallelScenarios.Tests.ps1** : Tests pour les scénarios de test parallèles.
- **PerformanceBenchmark.Tests.ps1** : Tests de benchmark pour comparer les performances de différentes implémentations.
- **Optimize-ParallelBatchSize.Tests.ps1** : Tests pour l'optimisation de la taille des lots en traitement parallèle.

## Exécution des tests

### Exécution de tous les tests

Pour exécuter tous les tests, utilisez le script `Run-AllTests.ps1` :

```powershell
.\Run-AllTests.ps1
```

Par défaut, ce script exécute tous les tests et génère un rapport HTML des résultats.

### Options d'exécution

Le script `Run-AllTests.ps1` accepte les paramètres suivants :

- **GenerateReport** : Indique si un rapport HTML des résultats doit être généré (par défaut : $true).
- **OutputPath** : Chemin où les résultats des tests seront enregistrés (par défaut : "$PSScriptRoot\TestResults").

Exemple :

```powershell
.\Run-AllTests.ps1 -GenerateReport $true -OutputPath "C:\TestResults"
```

### Exécution dans un environnement CI/CD

Pour exécuter les tests dans un environnement CI/CD, utilisez le script `Run-CITests.ps1` :

```powershell
.\Run-CITests.ps1 -ThresholdPercent 70
```

Ce script exécute tous les tests, génère des rapports de couverture et de résultats au format compatible avec les systèmes CI/CD, et vérifie que la couverture de code est supérieure au seuil spécifié.

## Types de tests

### Tests unitaires

Les tests unitaires vérifient le bon fonctionnement des fonctions individuelles. Ils sont organisés en contextes (Context) et en tests (It).

Exemple de test unitaire :

```powershell
Describe "Fonctions communes des scripts de performance" {
    Context "New-DirectoryIfNotExists" {
        It "Crée un répertoire s'il n'existe pas" {
            # Test code here
        }
    }
}
```

### Tests d'intégration

Les tests d'intégration vérifient l'interaction entre les différentes fonctions et le flux de travail complet.

Exemple de test d'intégration :

```powershell
Describe "Tests d'intégration des scripts de performance" {
    Context "Flux de travail complet" {
        It "Exécute correctement le flux de travail complet" {
            # Test code here
        }
    }
}
```

### Tests de performance

Les tests de performance mesurent les performances des fonctions et comparent les différentes implémentations.

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

Les tests de benchmark comparent les performances de différentes implémentations et mesurent la scalabilité des fonctions avec différentes tailles de données.

Exemple de test de benchmark :

```powershell
Describe "Tests de benchmark de performance" {
    Context "Comparaison des performances entre différentes implémentations" {
        It "Compare les performances du tri avec différentes approches" {
            # Test code here
        }
    }
}
```

## Couverture de code

Les tests sont configurés pour mesurer la couverture de code. Le rapport de couverture est généré au format JaCoCo et enregistré dans le répertoire des résultats des tests.

Pour visualiser la couverture de code, ouvrez le fichier `coverage.xml` dans un outil compatible avec le format JaCoCo, comme ReportGenerator ou un plugin d'IDE.

## Ajout de nouveaux tests

### Structure d'un test

Un test Pester est structuré comme suit :

1. **Describe** : Décrit un ensemble de tests liés à une fonctionnalité ou un composant.
2. **Context** : Décrit un contexte ou un scénario spécifique dans lequel les tests sont exécutés.
3. **BeforeAll** : Code exécuté une fois avant tous les tests dans le contexte.
4. **It** : Un test individuel qui vérifie un comportement spécifique.
5. **Should** : Une assertion qui vérifie que le résultat est conforme aux attentes.

### Exemple de test

```powershell
Describe "Ma fonctionnalité" {
    Context "Dans un contexte spécifique" {
        BeforeAll {
            # Code d'initialisation
            $testData = @(1, 2, 3)
        }
        
        It "Fait quelque chose de spécifique" {
            # Appeler la fonction à tester
            $result = Do-Something -Data $testData
            
            # Vérifier le résultat
            $result | Should -Be 6
        }
    }
}
```

### Bonnes pratiques pour les tests

1. **Nommage explicite** : Donnez des noms clairs et descriptifs à vos tests pour faciliter la compréhension de ce qu'ils testent.
2. **Tests isolés** : Chaque test doit être indépendant des autres tests.
3. **Initialisation et nettoyage** : Utilisez BeforeAll, AfterAll, BeforeEach et AfterEach pour initialiser et nettoyer l'environnement de test.
4. **Assertions précises** : Utilisez des assertions précises pour vérifier les résultats.
5. **Tests de cas limites** : Testez les cas limites et les cas d'erreur.
6. **Tests de performance** : Pour les tests de performance, utilisez des mesures précises et répétez les tests plusieurs fois pour obtenir des résultats fiables.

### Ajout d'un nouveau fichier de test

Pour ajouter un nouveau fichier de test :

1. Créez un nouveau fichier avec le suffixe `.Tests.ps1` dans le répertoire des tests.
2. Structurez vos tests avec Describe, Context et It.
3. Exécutez les tests avec `Run-AllTests.ps1` pour vérifier qu'ils fonctionnent correctement.

## Dépannage

### Problèmes courants

1. **Tests qui échouent de manière intermittente** : Les tests de performance peuvent échouer de manière intermittente en raison de variations dans l'environnement d'exécution. Utilisez des tolérances appropriées et répétez les tests plusieurs fois pour obtenir des résultats fiables.

2. **Tests qui prennent trop de temps** : Les tests de performance peuvent prendre beaucoup de temps à s'exécuter. Utilisez le paramètre Skip pour ignorer les tests longs pendant le développement.

3. **Erreurs de couverture de code** : Si la couverture de code est inférieure au seuil, vérifiez les parties du code qui ne sont pas couvertes et ajoutez des tests pour ces parties.

### Résolution des problèmes

1. **Exécuter un test spécifique** : Pour exécuter un test spécifique, utilisez le paramètre `-Name` de Invoke-Pester :

```powershell
Invoke-Pester -Path ".\MyTest.Tests.ps1" -Name "Ma fonctionnalité"
```

2. **Déboguer un test** : Pour déboguer un test, utilisez Write-Host pour afficher des informations de débogage ou utilisez le débogueur de PowerShell :

```powershell
It "Mon test" {
    Write-Host "Valeur de la variable : $myVariable"
    # Test code here
}
```

3. **Ignorer un test** : Pour ignorer temporairement un test, utilisez le paramètre Skip :

```powershell
It "Mon test" -Skip {
    # Test code here
}
```

## Ressources

- [Documentation Pester](https://pester.dev/docs/quick-start)
- [Guide de la couverture de code avec Pester](https://pester.dev/docs/usage/code-coverage)
- [Bonnes pratiques pour les tests unitaires](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations?view=powershell-7.1)
