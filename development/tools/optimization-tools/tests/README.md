# Tests Unitaires pour le Module ProactiveOptimization

Ce dossier contient des tests unitaires pour le module ProactiveOptimization, utilisant le framework Pester.

## Structure des Tests

- **MonitorScriptUsage.Tests.ps1** : Tests pour le script Monitor-ScriptUsage.ps1
- **DetectBottlenecks.Tests.ps1** : Tests pour le script Detect-Bottlenecks.ps1
- **AnalyzeUsageTrends.Tests.ps1** : Tests pour le script Analyze-UsageTrends.ps1
- **Run-AllTests.ps1** : Script pour exÃ©cuter tous les tests et gÃ©nÃ©rer un rapport de couverture

## Ã‰tat actuel des tests

Les tests actuels sont des exemples qui montrent comment les fonctionnalitÃ©s du module ProactiveOptimization devraient Ãªtre testÃ©es. Cependant, ils nÃ©cessitent des modifications pour fonctionner correctement, car ils dÃ©pendent de modules externes qui ne sont pas encore implÃ©mentÃ©s.

## ProblÃ¨mes connus

1. **DÃ©pendance au module UsageMonitor**: Les tests dÃ©pendent du module UsageMonitor qui n'est pas encore implÃ©mentÃ©. Pour exÃ©cuter les tests, vous devez d'abord implÃ©menter ce module ou modifier les tests pour utiliser des mocks.

2. **Fonctions non disponibles**: Certaines fonctions comme `Test-ScriptUsesParallelization`, `Analyze-ParallelBottleneck` et `Generate-BottleneckReport` ne sont pas correctement chargÃ©es ou ne sont pas disponibles.

3. **ProblÃ¨mes de mock**: Les mocks ne fonctionnent pas correctement, car ils essaient d'appeler des fonctions qui n'existent pas.

## Comment corriger les tests

Pour faire fonctionner les tests, vous devez:

1. ImplÃ©menter le module UsageMonitor avec les fonctions requises:
   - `Initialize-UsageMonitor`
   - `Get-ScriptUsageStatistics`
   - `Find-ScriptBottlenecks`

2. Modifier les tests pour utiliser des mocks simples qui ne dÃ©pendent pas de fonctions externes:

```powershell
# Exemple de mock simple

Mock Get-ScriptUsageStatistics {
    return [PSCustomObject]@{
        TopUsedScripts = @{
            "C:\Scripts\Test1.ps1" = 10
            "C:\Scripts\Test2.ps1" = 5
        }
        # Autres propriÃ©tÃ©s...

    }
}
```plaintext
3. S'assurer que toutes les fonctions testÃ©es sont correctement dÃ©finies et chargÃ©es avant d'exÃ©cuter les tests.

## ExÃ©cution des Tests

Une fois les problÃ¨mes ci-dessus rÃ©solus, vous pouvez exÃ©cuter les tests avec:

```powershell
# ExÃ©cuter tous les tests

.\Run-AllTests.ps1

# ExÃ©cuter les tests avec gÃ©nÃ©ration de rapport de couverture

.\Run-AllTests.ps1 -GenerateCodeCoverage

# ExÃ©cuter les tests avec affichage dÃ©taillÃ© des rÃ©sultats

.\Run-AllTests.ps1 -ShowDetailedResults

# ExÃ©cuter un test spÃ©cifique

Invoke-Pester -Path .\MonitorScriptUsage.Tests.ps1
```plaintext
## Approche de Test

Les tests unitaires suivent une approche AAA (Arrange-Act-Assert) :

1. **Arrange** : PrÃ©paration des donnÃ©es et des mocks nÃ©cessaires
2. **Act** : ExÃ©cution de la fonction Ã  tester
3. **Assert** : VÃ©rification des rÃ©sultats

## Mocks

Les tests utilisent des mocks pour simuler le comportement des dÃ©pendances externes, notamment :

- Le module UsageMonitor
- Les fonctions d'accÃ¨s aux fichiers (Get-Content, Test-Path)
- Les fonctions d'Ã©criture de fichiers (Out-File, New-Item)

## Prochaines Ã©tapes

1. ImplÃ©menter le module UsageMonitor
2. Corriger les tests pour qu'ils fonctionnent avec le module implÃ©mentÃ©
3. Ajouter plus de tests pour couvrir toutes les fonctionnalitÃ©s du module ProactiveOptimization

## IntÃ©gration Continue (Future)

Une fois les tests corrigÃ©s, ils pourront Ãªtre intÃ©grÃ©s dans un pipeline CI/CD pour assurer la qualitÃ© du code :

```yaml
# Exemple pour Azure DevOps

steps:
- task: PowerShell@2
  displayName: 'Run Pester Tests'
  inputs:
    filePath: 'scripts\utils\ProactiveOptimization\tests\Run-AllTests.ps1'
    arguments: '-GenerateCodeCoverage'
    pwsh: true

- task: PublishTestResults@2
  displayName: 'Publish Test Results'
  inputs:
    testResultsFormat: 'NUnit'
    testResultsFiles: '**/TestResults.xml'
    failTaskOnFailedTests: true

- task: PublishCodeCoverageResults@1
  displayName: 'Publish Code Coverage'
  inputs:
    codeCoverageTool: 'JaCoCo'
    summaryFileLocation: 'scripts\utils\ProactiveOptimization\tests\coverage.xml'
    failIfCoverageEmpty: true
```plaintext