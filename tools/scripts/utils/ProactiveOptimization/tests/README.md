# Tests Unitaires pour le Module ProactiveOptimization

Ce dossier contient des tests unitaires pour le module ProactiveOptimization, utilisant le framework Pester.

## Structure des Tests

- **MonitorScriptUsage.Tests.ps1** : Tests pour le script Monitor-ScriptUsage.ps1
- **DetectBottlenecks.Tests.ps1** : Tests pour le script Detect-Bottlenecks.ps1
- **AnalyzeUsageTrends.Tests.ps1** : Tests pour le script Analyze-UsageTrends.ps1
- **Run-AllTests.ps1** : Script pour exécuter tous les tests et générer un rapport de couverture

## État actuel des tests

Les tests actuels sont des exemples qui montrent comment les fonctionnalités du module ProactiveOptimization devraient être testées. Cependant, ils nécessitent des modifications pour fonctionner correctement, car ils dépendent de modules externes qui ne sont pas encore implémentés.

## Problèmes connus

1. **Dépendance au module UsageMonitor**: Les tests dépendent du module UsageMonitor qui n'est pas encore implémenté. Pour exécuter les tests, vous devez d'abord implémenter ce module ou modifier les tests pour utiliser des mocks.

2. **Fonctions non disponibles**: Certaines fonctions comme `Test-ScriptUsesParallelization`, `Analyze-ParallelBottleneck` et `Generate-BottleneckReport` ne sont pas correctement chargées ou ne sont pas disponibles.

3. **Problèmes de mock**: Les mocks ne fonctionnent pas correctement, car ils essaient d'appeler des fonctions qui n'existent pas.

## Comment corriger les tests

Pour faire fonctionner les tests, vous devez:

1. Implémenter le module UsageMonitor avec les fonctions requises:
   - `Initialize-UsageMonitor`
   - `Get-ScriptUsageStatistics`
   - `Find-ScriptBottlenecks`

2. Modifier les tests pour utiliser des mocks simples qui ne dépendent pas de fonctions externes:

```powershell
# Exemple de mock simple
Mock Get-ScriptUsageStatistics {
    return [PSCustomObject]@{
        TopUsedScripts = @{
            "C:\Scripts\Test1.ps1" = 10
            "C:\Scripts\Test2.ps1" = 5
        }
        # Autres propriétés...
    }
}
```

3. S'assurer que toutes les fonctions testées sont correctement définies et chargées avant d'exécuter les tests.

## Exécution des Tests

Une fois les problèmes ci-dessus résolus, vous pouvez exécuter les tests avec:

```powershell
# Exécuter tous les tests
.\Run-AllTests.ps1

# Exécuter les tests avec génération de rapport de couverture
.\Run-AllTests.ps1 -GenerateCodeCoverage

# Exécuter les tests avec affichage détaillé des résultats
.\Run-AllTests.ps1 -ShowDetailedResults

# Exécuter un test spécifique
Invoke-Pester -Path .\MonitorScriptUsage.Tests.ps1
```

## Approche de Test

Les tests unitaires suivent une approche AAA (Arrange-Act-Assert) :

1. **Arrange** : Préparation des données et des mocks nécessaires
2. **Act** : Exécution de la fonction à tester
3. **Assert** : Vérification des résultats

## Mocks

Les tests utilisent des mocks pour simuler le comportement des dépendances externes, notamment :

- Le module UsageMonitor
- Les fonctions d'accès aux fichiers (Get-Content, Test-Path)
- Les fonctions d'écriture de fichiers (Out-File, New-Item)

## Prochaines étapes

1. Implémenter le module UsageMonitor
2. Corriger les tests pour qu'ils fonctionnent avec le module implémenté
3. Ajouter plus de tests pour couvrir toutes les fonctionnalités du module ProactiveOptimization

## Intégration Continue (Future)

Une fois les tests corrigés, ils pourront être intégrés dans un pipeline CI/CD pour assurer la qualité du code :

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
```
