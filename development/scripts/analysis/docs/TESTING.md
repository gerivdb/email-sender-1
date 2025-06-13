# Guide de test pour le systÃ¨me d'analyse de code

Ce document explique comment tester le systÃ¨me d'analyse de code et comment rÃ©soudre les problÃ¨mes courants.

## Vue d'ensemble

Le systÃ¨me d'analyse de code est testÃ© Ã  l'aide de deux approches complÃ©mentaires :

1. **Tests unitaires** : Tests qui vÃ©rifient le comportement de fonctions individuelles.
2. **Tests d'intÃ©gration** : Tests qui vÃ©rifient le comportement du systÃ¨me dans son ensemble.

## Tests unitaires

Les tests unitaires sont Ã©crits Ã  l'aide du framework Pester et se trouvent dans le rÃ©pertoire `development/scripts/analysis/tests`. Chaque script principal a un fichier de test correspondant avec le suffixe `.Tests.ps1`.

### ExÃ©cution des tests unitaires

Pour exÃ©cuter tous les tests unitaires, utilisez le script `Run-AllTests.ps1` :

```powershell
.\development\scripts\analysis\tests\Run-AllTests.ps1
```plaintext
Pour exÃ©cuter un test spÃ©cifique, utilisez Pester directement :

```powershell
Invoke-Pester -Path ".\development\scripts\analysis\tests\Start-CodeAnalysis.Tests.ps1"
```plaintext
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
    throw "Le module TestHelpers.psm1 n'existe pas Ã  l'emplacement: $testHelpersPath"
}

# Chemin du script Ã  tester

$scriptPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "<nom-du-script>.ps1"
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script <nom-du-script>.ps1 n'existe pas Ã  l'emplacement: $scriptPath"
}

Describe "Script <nom-du-script>" {
    BeforeAll {
        # CrÃ©er un environnement de test

        $testEnv = New-TestEnvironment -TestName "<nom-du-test>"
    }
    
    Context "ParamÃ¨tres et validation" {
        It "LÃ¨ve une exception si le chemin n'existe pas" {
            # Act & Assert

            { Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{ Path = "C:\chemin\inexistant" } } | Should -Throw
        }
    }
    
    # Autres contextes et tests...

}
```plaintext
### Module d'aide pour les tests

Le module `TestHelpers.psm1` contient des fonctions d'aide pour les tests unitaires :

- `New-TestEnvironment` : CrÃ©e un environnement de test avec des fichiers et des rÃ©pertoires de test.
- `Invoke-ScriptWithParams` : ExÃ©cute un script avec des paramÃ¨tres.
- `New-PSScriptAnalyzerMock` : CrÃ©e un mock pour PSScriptAnalyzer.
- `New-UnifiedAnalysisResultMock` : CrÃ©e un mock pour New-UnifiedAnalysisResult.

### Bonnes pratiques pour les tests unitaires

1. **Utilisez des mocks** : Utilisez des mocks pour simuler le comportement des fonctions externes.
2. **Isolez les tests** : Chaque test doit Ãªtre indÃ©pendant des autres tests.
3. **Testez les cas limites** : Testez les cas limites et les cas d'erreur.
4. **Utilisez des assertions claires** : Utilisez des assertions claires et prÃ©cises.
5. **Documentez les tests** : Documentez les tests pour expliquer ce qu'ils testent.

### ProblÃ¨mes courants avec les tests unitaires

#### ProblÃ¨me : Impossible de mocker des fonctions systÃ¨me

PowerShell 5.1 a des limitations pour mocker des fonctions systÃ¨me comme `[System.IO.File]::ReadAllBytes`. Pour contourner ce problÃ¨me, vous pouvez :

1. CrÃ©er une fonction wrapper qui appelle la fonction systÃ¨me, puis mocker cette fonction wrapper.
2. Utiliser des fichiers temporaires rÃ©els pour les tests.

#### ProblÃ¨me : Impossible de mocker des fonctions dans des modules

PowerShell 5.1 a des limitations pour mocker des fonctions dans des modules. Pour contourner ce problÃ¨me, vous pouvez :

1. Importer le module dans le contexte de test avec `Import-Module -Force`.
2. Utiliser `Mock -ModuleName` pour mocker des fonctions dans des modules.

#### ProblÃ¨me : Les tests Ã©chouent avec des erreurs d'encodage

Les problÃ¨mes d'encodage sont courants avec PowerShell 5.1. Pour Ã©viter ces problÃ¨mes, assurez-vous que :

1. Tous les fichiers PowerShell sont encodÃ©s en UTF-8 avec BOM.
2. Les chaÃ®nes de caractÃ¨res contenant des caractÃ¨res spÃ©ciaux sont correctement Ã©chappÃ©es.

## Tests d'intÃ©gration

Les tests d'intÃ©gration vÃ©rifient le comportement du systÃ¨me dans son ensemble. Ils sont Ã©crits Ã  l'aide du script `Test-AnalysisIntegration.ps1`.

### ExÃ©cution des tests d'intÃ©gration

Pour exÃ©cuter les tests d'intÃ©gration, utilisez le script `Test-AnalysisIntegration.ps1` :

```powershell
.\development\scripts\analysis\tests\Test-AnalysisIntegration.ps1 -TestDirectory ".\development\scripts" -OutputPath ".\results"
```plaintext
### Structure des tests d'intÃ©gration

Le script `Test-AnalysisIntegration.ps1` exÃ©cute une sÃ©rie de tests qui vÃ©rifient le comportement du systÃ¨me d'analyse de code dans son ensemble :

1. Analyse d'un fichier avec PSScriptAnalyzer
2. Analyse d'un fichier avec TodoAnalyzer
3. GÃ©nÃ©ration d'un rapport HTML
4. Correction de l'encodage du rapport HTML
5. IntÃ©gration avec GitHub
6. IntÃ©gration avec SonarQube
7. IntÃ©gration avec Azure DevOps
8. Analyse parallÃ¨le

### Bonnes pratiques pour les tests d'intÃ©gration

1. **Utilisez des donnÃ©es de test rÃ©alistes** : Utilisez des donnÃ©es de test qui ressemblent aux donnÃ©es rÃ©elles.
2. **Testez le flux complet** : Testez le flux complet du systÃ¨me, de l'analyse Ã  la gÃ©nÃ©ration de rapports.
3. **VÃ©rifiez les rÃ©sultats** : VÃ©rifiez que les rÃ©sultats sont corrects et complets.
4. **Nettoyez aprÃ¨s les tests** : Nettoyez les fichiers temporaires aprÃ¨s les tests.

### ProblÃ¨mes courants avec les tests d'intÃ©gration

#### ProblÃ¨me : Les tests Ã©chouent avec des erreurs d'accÃ¨s aux fichiers

Les erreurs d'accÃ¨s aux fichiers sont courantes avec les tests d'intÃ©gration. Pour Ã©viter ces problÃ¨mes, assurez-vous que :

1. Les fichiers temporaires sont crÃ©Ã©s dans un rÃ©pertoire accessible.
2. Les fichiers temporaires sont supprimÃ©s aprÃ¨s les tests.
3. Les fichiers ne sont pas verrouillÃ©s par d'autres processus.

#### ProblÃ¨me : Les tests Ã©chouent avec des erreurs d'API

Les erreurs d'API sont courantes avec les tests d'intÃ©gration qui utilisent des API externes. Pour Ã©viter ces problÃ¨mes, vous pouvez :

1. Utiliser des mocks pour simuler les API externes.
2. Utiliser des API de test ou des environnements de test.
3. VÃ©rifier que les API sont accessibles avant d'exÃ©cuter les tests.

## Tests de performance

Les tests de performance vÃ©rifient les performances du systÃ¨me d'analyse de code. Ils sont Ã©crits Ã  l'aide du script `Test-PerformanceOptimization.ps1`.

### ExÃ©cution des tests de performance

Pour exÃ©cuter les tests de performance, utilisez le script `Test-PerformanceOptimization.ps1` :

```powershell
.\development\scripts\analysis\tests\Test-PerformanceOptimization.ps1 -TestDirectory ".\development\scripts" -OutputPath ".\results" -NumberOfFiles 100 -MaxThreads 8
```plaintext
### Structure des tests de performance

Le script `Test-PerformanceOptimization.ps1` exÃ©cute une sÃ©rie de tests qui mesurent les performances du systÃ¨me d'analyse de code :

1. Analyse sÃ©quentielle
2. Analyse parallÃ¨le avec 2 threads
3. Analyse parallÃ¨le avec 4 threads
4. Analyse parallÃ¨le avec 8 threads

### Bonnes pratiques pour les tests de performance

1. **Utilisez des donnÃ©es de test rÃ©alistes** : Utilisez des donnÃ©es de test qui ressemblent aux donnÃ©es rÃ©elles.
2. **ExÃ©cutez les tests plusieurs fois** : ExÃ©cutez les tests plusieurs fois pour obtenir des rÃ©sultats fiables.
3. **Mesurez le temps d'exÃ©cution** : Mesurez le temps d'exÃ©cution pour chaque test.
4. **Comparez les rÃ©sultats** : Comparez les rÃ©sultats pour identifier les goulots d'Ã©tranglement.

### ProblÃ¨mes courants avec les tests de performance

#### ProblÃ¨me : Les rÃ©sultats varient considÃ©rablement

Les rÃ©sultats des tests de performance peuvent varier considÃ©rablement en fonction de la charge du systÃ¨me. Pour obtenir des rÃ©sultats plus fiables, vous pouvez :

1. ExÃ©cuter les tests plusieurs fois et calculer la moyenne.
2. ExÃ©cuter les tests sur un systÃ¨me dÃ©diÃ©.
3. Fermer les applications inutiles pendant les tests.

#### ProblÃ¨me : Les tests prennent trop de temps

Les tests de performance peuvent prendre beaucoup de temps, surtout avec un grand nombre de fichiers. Pour rÃ©duire le temps d'exÃ©cution, vous pouvez :

1. RÃ©duire le nombre de fichiers Ã  analyser.
2. Utiliser un sous-ensemble reprÃ©sentatif des fichiers.
3. ExÃ©cuter les tests en parallÃ¨le.

## Conclusion

Les tests sont essentiels pour garantir la qualitÃ© et la fiabilitÃ© du systÃ¨me d'analyse de code. En suivant les bonnes pratiques et en Ã©vitant les problÃ¨mes courants, vous pouvez crÃ©er des tests efficaces qui vous aideront Ã  amÃ©liorer le systÃ¨me.
