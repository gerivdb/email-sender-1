# Guide de test pour le système d'analyse de code

Ce document explique comment tester le système d'analyse de code et comment résoudre les problèmes courants.

## Vue d'ensemble

Le système d'analyse de code est testé à l'aide de deux approches complémentaires :

1. **Tests unitaires** : Tests qui vérifient le comportement de fonctions individuelles.
2. **Tests d'intégration** : Tests qui vérifient le comportement du système dans son ensemble.

## Tests unitaires

Les tests unitaires sont écrits à l'aide du framework Pester et se trouvent dans le répertoire `scripts/analysis/tests`. Chaque script principal a un fichier de test correspondant avec le suffixe `.Tests.ps1`.

### Exécution des tests unitaires

Pour exécuter tous les tests unitaires, utilisez le script `Run-AllTests.ps1` :

```powershell
.\scripts\analysis\tests\Run-AllTests.ps1
```

Pour exécuter un test spécifique, utilisez Pester directement :

```powershell
Invoke-Pester -Path ".\scripts\analysis\tests\Start-CodeAnalysis.Tests.ps1"
```

### Structure des tests unitaires

Chaque fichier de test unitaire suit la structure suivante :

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script <nom-du-script>.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script <nom-du-script>.ps1.
#>

# Importer le module Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installez-le avec 'Install-Module -Name Pester -Force'."
    return
}

# Importer le module d'aide pour les tests
$testHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath "TestHelpers.psm1"
if (Test-Path -Path $testHelpersPath) {
    Import-Module -Name $testHelpersPath -Force
} else {
    throw "Le module TestHelpers.psm1 n'existe pas à l'emplacement: $testHelpersPath"
}

# Chemin du script à tester
$scriptPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "<nom-du-script>.ps1"
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script <nom-du-script>.ps1 n'existe pas à l'emplacement: $scriptPath"
}

Describe "Script <nom-du-script>" {
    BeforeAll {
        # Créer un environnement de test
        $testEnv = New-TestEnvironment -TestName "<nom-du-test>"
    }
    
    Context "Paramètres et validation" {
        It "Lève une exception si le chemin n'existe pas" {
            # Act & Assert
            { Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{ Path = "C:\chemin\inexistant" } } | Should -Throw
        }
    }
    
    # Autres contextes et tests...
}
```

### Module d'aide pour les tests

Le module `TestHelpers.psm1` contient des fonctions d'aide pour les tests unitaires :

- `New-TestEnvironment` : Crée un environnement de test avec des fichiers et des répertoires de test.
- `Invoke-ScriptWithParams` : Exécute un script avec des paramètres.
- `New-PSScriptAnalyzerMock` : Crée un mock pour PSScriptAnalyzer.
- `New-UnifiedAnalysisResultMock` : Crée un mock pour New-UnifiedAnalysisResult.

### Bonnes pratiques pour les tests unitaires

1. **Utilisez des mocks** : Utilisez des mocks pour simuler le comportement des fonctions externes.
2. **Isolez les tests** : Chaque test doit être indépendant des autres tests.
3. **Testez les cas limites** : Testez les cas limites et les cas d'erreur.
4. **Utilisez des assertions claires** : Utilisez des assertions claires et précises.
5. **Documentez les tests** : Documentez les tests pour expliquer ce qu'ils testent.

### Problèmes courants avec les tests unitaires

#### Problème : Impossible de mocker des fonctions système

PowerShell 5.1 a des limitations pour mocker des fonctions système comme `[System.IO.File]::ReadAllBytes`. Pour contourner ce problème, vous pouvez :

1. Créer une fonction wrapper qui appelle la fonction système, puis mocker cette fonction wrapper.
2. Utiliser des fichiers temporaires réels pour les tests.

#### Problème : Impossible de mocker des fonctions dans des modules

PowerShell 5.1 a des limitations pour mocker des fonctions dans des modules. Pour contourner ce problème, vous pouvez :

1. Importer le module dans le contexte de test avec `Import-Module -Force`.
2. Utiliser `Mock -ModuleName` pour mocker des fonctions dans des modules.

#### Problème : Les tests échouent avec des erreurs d'encodage

Les problèmes d'encodage sont courants avec PowerShell 5.1. Pour éviter ces problèmes, assurez-vous que :

1. Tous les fichiers PowerShell sont encodés en UTF-8 avec BOM.
2. Les chaînes de caractères contenant des caractères spéciaux sont correctement échappées.

## Tests d'intégration

Les tests d'intégration vérifient le comportement du système dans son ensemble. Ils sont écrits à l'aide du script `Test-AnalysisIntegration.ps1`.

### Exécution des tests d'intégration

Pour exécuter les tests d'intégration, utilisez le script `Test-AnalysisIntegration.ps1` :

```powershell
.\scripts\analysis\tests\Test-AnalysisIntegration.ps1 -TestDirectory ".\scripts" -OutputPath ".\results"
```

### Structure des tests d'intégration

Le script `Test-AnalysisIntegration.ps1` exécute une série de tests qui vérifient le comportement du système d'analyse de code dans son ensemble :

1. Analyse d'un fichier avec PSScriptAnalyzer
2. Analyse d'un fichier avec TodoAnalyzer
3. Génération d'un rapport HTML
4. Correction de l'encodage du rapport HTML
5. Intégration avec GitHub
6. Intégration avec SonarQube
7. Intégration avec Azure DevOps
8. Analyse parallèle

### Bonnes pratiques pour les tests d'intégration

1. **Utilisez des données de test réalistes** : Utilisez des données de test qui ressemblent aux données réelles.
2. **Testez le flux complet** : Testez le flux complet du système, de l'analyse à la génération de rapports.
3. **Vérifiez les résultats** : Vérifiez que les résultats sont corrects et complets.
4. **Nettoyez après les tests** : Nettoyez les fichiers temporaires après les tests.

### Problèmes courants avec les tests d'intégration

#### Problème : Les tests échouent avec des erreurs d'accès aux fichiers

Les erreurs d'accès aux fichiers sont courantes avec les tests d'intégration. Pour éviter ces problèmes, assurez-vous que :

1. Les fichiers temporaires sont créés dans un répertoire accessible.
2. Les fichiers temporaires sont supprimés après les tests.
3. Les fichiers ne sont pas verrouillés par d'autres processus.

#### Problème : Les tests échouent avec des erreurs d'API

Les erreurs d'API sont courantes avec les tests d'intégration qui utilisent des API externes. Pour éviter ces problèmes, vous pouvez :

1. Utiliser des mocks pour simuler les API externes.
2. Utiliser des API de test ou des environnements de test.
3. Vérifier que les API sont accessibles avant d'exécuter les tests.

## Tests de performance

Les tests de performance vérifient les performances du système d'analyse de code. Ils sont écrits à l'aide du script `Test-PerformanceOptimization.ps1`.

### Exécution des tests de performance

Pour exécuter les tests de performance, utilisez le script `Test-PerformanceOptimization.ps1` :

```powershell
.\scripts\analysis\tests\Test-PerformanceOptimization.ps1 -TestDirectory ".\scripts" -OutputPath ".\results" -NumberOfFiles 100 -MaxThreads 8
```

### Structure des tests de performance

Le script `Test-PerformanceOptimization.ps1` exécute une série de tests qui mesurent les performances du système d'analyse de code :

1. Analyse séquentielle
2. Analyse parallèle avec 2 threads
3. Analyse parallèle avec 4 threads
4. Analyse parallèle avec 8 threads

### Bonnes pratiques pour les tests de performance

1. **Utilisez des données de test réalistes** : Utilisez des données de test qui ressemblent aux données réelles.
2. **Exécutez les tests plusieurs fois** : Exécutez les tests plusieurs fois pour obtenir des résultats fiables.
3. **Mesurez le temps d'exécution** : Mesurez le temps d'exécution pour chaque test.
4. **Comparez les résultats** : Comparez les résultats pour identifier les goulots d'étranglement.

### Problèmes courants avec les tests de performance

#### Problème : Les résultats varient considérablement

Les résultats des tests de performance peuvent varier considérablement en fonction de la charge du système. Pour obtenir des résultats plus fiables, vous pouvez :

1. Exécuter les tests plusieurs fois et calculer la moyenne.
2. Exécuter les tests sur un système dédié.
3. Fermer les applications inutiles pendant les tests.

#### Problème : Les tests prennent trop de temps

Les tests de performance peuvent prendre beaucoup de temps, surtout avec un grand nombre de fichiers. Pour réduire le temps d'exécution, vous pouvez :

1. Réduire le nombre de fichiers à analyser.
2. Utiliser un sous-ensemble représentatif des fichiers.
3. Exécuter les tests en parallèle.

## Conclusion

Les tests sont essentiels pour garantir la qualité et la fiabilité du système d'analyse de code. En suivant les bonnes pratiques et en évitant les problèmes courants, vous pouvez créer des tests efficaces qui vous aideront à améliorer le système.
