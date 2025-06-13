# Guide Pratique : Tests Progressifs en 4 Phases

## Introduction

Ce guide explique comment implémenter la méthodologie de tests progressive en 4 phases (P1-P4) dans le cadre du workflow COMBO (DEVR+TEST+DEBUG) du projet EMAIL_SENDER_1. Cette approche structurée permet de développer des tests exhaustifs qui garantissent la qualité, la robustesse et la performance du code.

## Intégration dans le Workflow COMBO

Le workflow COMBO (DEVR+TEST+DEBUG) est un cycle de développement itératif qui combine trois phases séquentielles :

1. **DEVR** : Développement initial de la fonctionnalité avec tests P1 basiques
2. **TEST** : Expansion progressive des tests à travers les phases P2, P3 et P4
3. **DEBUG** : Correction des problèmes identifiés et amélioration de la couverture de code

La méthodologie de tests progressive en 4 phases s'intègre parfaitement dans ce workflow, permettant de s'assurer que chaque fonctionnalité est développée, testée et déboguée de manière méthodique avant d'être considérée comme complète.

### Cycle de Développement Typique

```plaintext
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    DEVR     │────>│    TEST     │────>│    DEBUG    │
│ Implémenter │     │  Tester P1  │     │  Corriger   │
│ + Tests P1  │     │  Tester P2  │     │  Améliorer  │
└─────────────┘     │  Tester P3  │     │  Couverture │
      │             │  Tester P4  │     └─────────────┘
      │             └─────────────┘           │
      └───────────────────────────────────────┘
                    Itération
```plaintext
### Règles d'Avancement

1. Ne pas passer à la phase suivante tant que tous les tests de la phase actuelle ne sont pas réussis.
2. Ne pas marquer une tâche comme complète tant que tous les tests P1-P4 ne sont pas réussis.
3. Viser une couverture de code d'au moins 95% (objectif 100%).
4. Documenter les résultats des tests dans le fichier de plan (ex: plan-dev-v26.md) selon le format standard.

### Intégration avec les Autres Modes Opérationnels

Le workflow COMBO s'intègre avec d'autres modes opérationnels pour former un écosystème de développement complet :

- **Mode GRAN** : Utilisé en amont pour décomposer les fonctionnalités en tâches testables
- **Mode REVIEW** : Appliqué après chaque phase pour vérifier la qualité des tests
- **Mode OPTI** : Utilisé principalement avec les tests P4 pour optimiser les performances
- **Mode DEBUG** : Intégré dans le workflow COMBO pour résoudre les problèmes identifiés par les tests

## Exemples Concrets d'Implémentation

### Exemple 1 : Tests P1 (Basiques)

```powershell
# Wait-ForCompletedRunspace.P1.Tests.ps1

Describe "Wait-ForCompletedRunspace - Tests basiques" -Tag "P1" {
    BeforeAll {
        # Importer le module

        Import-Module -Name "UnifiedParallel" -Force
    }

    Context "Validation des paramètres" {
        It "Devrait accepter le paramètre Runspaces" {
            # Vérifier que le paramètre existe

            (Get-Command Wait-ForCompletedRunspace).Parameters.ContainsKey('Runspaces') | Should -BeTrue

            # Vérifier que le paramètre est obligatoire

            (Get-Command Wait-ForCompletedRunspace).Parameters['Runspaces'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -First 1 |
                ForEach-Object { $_.Mandatory } | Should -BeTrue
        }

        It "Devrait avoir une valeur par défaut de 0 pour TimeoutSeconds" {
            (Get-Command Wait-ForCompletedRunspace).Parameters['TimeoutSeconds'].DefaultValue | Should -Be 0
        }
    }

    Context "Comportement nominal" {
        BeforeEach {
            # Créer un runspace simple pour les tests

            $pool = [runspacefactory]::CreateRunspacePool(1, 1)
            $pool.Open()

            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool

            [void]$ps.AddScript({
                Start-Sleep -Milliseconds 100
                return "Test réussi"
            })

            $handle = $ps.BeginInvoke()

            $script:runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $script:runspaces.Add([PSCustomObject]@{
                PowerShell = $ps
                Handle = $handle
            })
        }

        AfterEach {
            # Nettoyer les ressources

            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Devrait attendre qu'un runspace soit complété" {
            # Créer une copie de la liste des runspaces

            $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($script:runspaces)

            # Attendre que le runspace soit complété

            $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -NoProgress

            # Vérifier que le résultat n'est pas null

            $result | Should -Not -BeNullOrEmpty

            # Vérifier que le runspace a été complété

            $result.Results.Count | Should -Be 1

            # Vérifier que la liste originale a été modifiée

            $runspacesCopy.Count | Should -Be 0
        }
    }
}
```plaintext
### Exemple 2 : Tests P2 (Robustesse)

```powershell
# Wait-ForCompletedRunspace.P2.Tests.ps1

Describe "Wait-ForCompletedRunspace - Tests de robustesse" -Tag "P2" {
    BeforeAll {
        # Importer le module

        Import-Module -Name "UnifiedParallel" -Force
    }

    Context "Cas limites" {
        It "Devrait gérer une liste vide de runspaces" {
            # Créer une liste vide

            $emptyList = [System.Collections.Generic.List[PSObject]]::new()

            # Attendre les runspaces (qui n'existent pas)

            $result = Wait-ForCompletedRunspace -Runspaces $emptyList -NoProgress

            # Vérifier que le résultat n'est pas null

            $result | Should -Not -BeNullOrEmpty

            # Vérifier que la liste de résultats est vide

            $result.Results.Count | Should -Be 0
        }

        It "Devrait gérer un grand nombre de runspaces (50)" {
            # Créer un pool de runspaces

            $pool = [runspacefactory]::CreateRunspacePool(1, 10)
            $pool.Open()

            # Créer 50 runspaces

            $runspaces = [System.Collections.Generic.List[PSObject]]::new()

            for ($i = 0; $i -lt 50; $i++) {
                $ps = [powershell]::Create()
                $ps.RunspacePool = $pool

                [void]$ps.AddScript({
                    param($index)
                    Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 50)
                    return "Test $index réussi"
                }).AddParameter("index", $i)

                $handle = $ps.BeginInvoke()

                $runspaces.Add([PSCustomObject]@{
                    PowerShell = $ps
                    Handle = $handle
                    Index = $i
                })
            }

            # Attendre que tous les runspaces soient complétés

            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

            # Vérifier que tous les runspaces ont été complétés

            $result.Results.Count | Should -Be 50

            # Nettoyer les ressources

            $pool.Close()
            $pool.Dispose()
        }
    }

    Context "Timeouts" {
        It "Devrait respecter le timeout global" {
            # Créer un runspace qui se bloque

            $pool = [runspacefactory]::CreateRunspacePool(1, 1)
            $pool.Open()

            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool

            [void]$ps.AddScript({
                # Simuler un blocage

                while ($true) {
                    Start-Sleep -Milliseconds 100
                }
            })

            $handle = $ps.BeginInvoke()

            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add([PSCustomObject]@{
                PowerShell = $ps
                Handle = $handle
            })

            # Attendre avec un timeout court

            $startTime = [datetime]::Now
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 2 -NoProgress
            $endTime = [datetime]::Now

            # Vérifier que le timeout a été respecté

            ($endTime - $startTime).TotalSeconds | Should -BeLessThan 3

            # Vérifier que TimeoutOccurred est true

            $result.TimeoutOccurred | Should -BeTrue

            # Nettoyer les ressources

            $pool.Close()
            $pool.Dispose()
        }
    }
}
```plaintext
### Exemple 3 : Tests P3 (Exceptions)

```powershell
# Wait-ForCompletedRunspace.P3.Tests.ps1

Describe "Wait-ForCompletedRunspace - Tests d'exceptions" -Tag "P3" {
    BeforeAll {
        # Importer le module

        Import-Module -Name "UnifiedParallel" -Force
    }

    Context "Gestion des erreurs" {
        It "Devrait gérer les runspaces qui génèrent des erreurs" {
            # Créer un runspace qui génère une erreur

            $pool = [runspacefactory]::CreateRunspacePool(1, 1)
            $pool.Open()

            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool

            [void]$ps.AddScript({
                throw "Erreur simulée"
            })

            $handle = $ps.BeginInvoke()

            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add([PSCustomObject]@{
                PowerShell = $ps
                Handle = $handle
            })

            # Attendre que le runspace soit complété

            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -NoProgress

            # Vérifier que le runspace a été complété malgré l'erreur

            $result.Results.Count | Should -Be 1

            # Vérifier que le runspace a généré une erreur

            $result.Results[0].PowerShell.HadErrors | Should -BeTrue

            # Nettoyer les ressources

            $pool.Close()
            $pool.Dispose()
        }
    }

    Context "Entrées invalides" {
        It "Devrait gérer les runspaces null" {
            # Créer une liste avec un runspace null

            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add($null)

            # Attendre les runspaces

            { Wait-ForCompletedRunspace -Runspaces $runspaces -NoProgress } | Should -Not -Throw
        }

        It "Devrait gérer les runspaces avec PowerShell null" {
            # Créer une liste avec un runspace dont PowerShell est null

            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add([PSCustomObject]@{
                PowerShell = $null
                Handle = $null
            })

            # Attendre les runspaces

            { Wait-ForCompletedRunspace -Runspaces $runspaces -NoProgress } | Should -Not -Throw
        }
    }
}
```plaintext
### Exemple 4 : Tests P4 (Avancés)

```powershell
# Wait-ForCompletedRunspace.P4.Tests.ps1

Describe "Wait-ForCompletedRunspace - Tests avancés" -Tag "P4" {
    BeforeAll {
        # Importer le module

        Import-Module -Name "UnifiedParallel" -Force
    }

    Context "Performance sous charge" {
        It "Devrait gérer 100 runspaces concurrents efficacement" {
            # Créer un pool de runspaces

            $pool = [runspacefactory]::CreateRunspacePool(1, 20)
            $pool.Open()

            # Créer 100 runspaces

            $runspaces = [System.Collections.Generic.List[PSObject]]::new()

            for ($i = 0; $i -lt 100; $i++) {
                $ps = [powershell]::Create()
                $ps.RunspacePool = $pool

                [void]$ps.AddScript({
                    param($index)
                    # Simuler un traitement

                    Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 100)
                    return "Test $index réussi"
                }).AddParameter("index", $i)

                $handle = $ps.BeginInvoke()

                $runspaces.Add([PSCustomObject]@{
                    PowerShell = $ps
                    Handle = $handle
                    Index = $i
                })
            }

            # Mesurer le temps d'exécution

            $startTime = [datetime]::Now
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
            $endTime = [datetime]::Now
            $duration = ($endTime - $startTime).TotalSeconds

            # Vérifier que tous les runspaces ont été complétés

            $result.Results.Count | Should -Be 100

            # Vérifier que le temps d'exécution est raisonnable (moins de 5 secondes)

            $duration | Should -BeLessThan 5

            # Nettoyer les ressources

            $pool.Close()
            $pool.Dispose()
        }
    }

    Context "Intégration avec d'autres modules" {
        It "Devrait s'intégrer correctement avec le module de journalisation" {
            # Créer un mock pour la fonction de journalisation

            Mock Write-Log { } -ModuleName "UnifiedParallel"

            # Créer un runspace simple

            $pool = [runspacefactory]::CreateRunspacePool(1, 1)
            $pool.Open()

            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool

            [void]$ps.AddScript({
                Start-Sleep -Milliseconds 100
                return "Test réussi"
            })

            $handle = $ps.BeginInvoke()

            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add([PSCustomObject]@{
                PowerShell = $ps
                Handle = $handle
            })

            # Attendre que le runspace soit complété

            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -NoProgress -Verbose

            # Vérifier que la fonction de journalisation a été appelée

            Should -Invoke Write-Log -ModuleName "UnifiedParallel"

            # Nettoyer les ressources

            $pool.Close()
            $pool.Dispose()
        }
    }
}
```plaintext
## Standards de Documentation des Résultats

### Format Standard de Documentation des Résultats

Pour assurer la cohérence dans la documentation des résultats de test, le format suivant doit être utilisé dans tous les fichiers de plan (ex: plan-dev-v26.md) :

#### Format pour les tâches complétées avec succès :

```markdown
- [x] Nom de la tâche (Tests: X/X réussis, couverture: Y%)
```plaintext
Exemple :
```markdown
- [x] Implémenter un mécanisme de timeout interne (Tests: 5/5 réussis, couverture: 97%)
```plaintext
#### Format pour les tâches avec tests skippés :

```markdown
- [x] Nom de la tâche (Tests: X/Z réussis, couverture: Y%, skippés: N [raison])
```plaintext
Exemple :
```markdown
- [x] Implémenter la détection de deadlock (Tests: 4/5 réussis, couverture: 95%, skippés: 1 [environnement spécifique requis])
```plaintext
#### Format pour les tâches en cours avec tests partiels :

```markdown
- [ ] Nom de la tâche (Tests: X/Z réussis, couverture: Y%, en cours)
```plaintext
Exemple :
```markdown
- [ ] Optimiser la gestion des collections (Tests: 3/8 réussis, couverture: 78%, en cours)
```plaintext
#### Format pour les tâches avec tests échoués :

```markdown
- [ ] Nom de la tâche (Tests: X/Z réussis, échecs: N, couverture: Y%)
```plaintext
Exemple :
```markdown
- [ ] Corriger la gestion des erreurs (Tests: 2/5 réussis, échecs: 3, couverture: 65%)
```plaintext
### Critères de Validation

Une tâche est considérée comme complète uniquement lorsque :
- 100% des tests sont réussis
- La couverture de code atteint au moins 95% (objectif 100%)
- Tous les tests sont traçables à une exigence fonctionnelle
- Les tests skippés sont documentés avec une justification

### Documentation des Tests Skippés

Dans le code de test, les tests skippés doivent être clairement documentés avec la raison du skip :

```powershell
It "Devrait faire quelque chose" -Skip:$isNotSupportedEnvironment -Tag "EnvironmentSpecific" {
    # Test skippé dans certains environnements

}
```plaintext
Ou avec une explication explicite :

```powershell
It "Devrait faire quelque chose (nécessite un environnement spécifique)" -Skip {
    # Test skippé

}
```plaintext
## Exécution des Tests

### Exécution d'une Phase Spécifique

```powershell
# Exécuter uniquement les tests P1

$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = ".\Wait-ForCompletedRunspace.P1.Tests.ps1"
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = ".\Results\Wait-ForCompletedRunspace.P1.Results.xml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = ".\UnifiedParallel.psm1"
$pesterConfig.CodeCoverage.OutputPath = ".\Results\Wait-ForCompletedRunspace.P1.Coverage.xml"

Invoke-Pester -Configuration $pesterConfig
```plaintext
### Exécution de Toutes les Phases

```powershell
# Exécuter tous les tests (P1-P4)

$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = @(
    ".\Wait-ForCompletedRunspace.P1.Tests.ps1",
    ".\Wait-ForCompletedRunspace.P2.Tests.ps1",
    ".\Wait-ForCompletedRunspace.P3.Tests.ps1",
    ".\Wait-ForCompletedRunspace.P4.Tests.ps1"
)
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = ".\Results\Wait-ForCompletedRunspace.All.Results.xml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = ".\UnifiedParallel.psm1"
$pesterConfig.CodeCoverage.OutputPath = ".\Results\Wait-ForCompletedRunspace.All.Coverage.xml"

Invoke-Pester -Configuration $pesterConfig
```plaintext
## Intégration avec CI/CD

La méthodologie de tests progressive en 4 phases s'intègre parfaitement avec les pipelines CI/CD via GitHub Actions pour automatiser l'exécution des tests et garantir la qualité du code.

### Configuration GitHub Actions

Voici un exemple de configuration GitHub Actions pour exécuter les tests automatiquement :

```yaml
# .github/workflows/test-pipeline.yml

name: Test Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup PowerShell
        uses: actions/setup-powershell@v1
        with:
          powershell-version: '7.1'

      - name: Install Pester
        shell: pwsh
        run: |
          Install-Module -Name Pester -Force -SkipPublisherCheck

      - name: Run P1 Tests
        shell: pwsh
        run: |
          $pesterConfig = [PesterConfiguration]::Default
          $pesterConfig.Run.Path = "./development/tools/*/tests/Pester/*.P1.Tests.ps1"
          $pesterConfig.Output.Verbosity = 'Detailed'
          $pesterConfig.TestResult.Enabled = $true
          $pesterConfig.TestResult.OutputPath = "./TestResults/P1.Results.xml"
          $pesterConfig.CodeCoverage.Enabled = $true
          $pesterConfig.CodeCoverage.OutputPath = "./TestResults/P1.Coverage.xml"
          Invoke-Pester -Configuration $pesterConfig
```plaintext
### Stratégie d'Exécution des Tests

Pour optimiser le temps d'exécution des pipelines CI/CD, utilisez la stratégie suivante :

- **Pull Requests** : Exécution des tests P1 et P2 pour validation rapide
- **Merge dans develop** : Exécution des tests P1, P2 et P3
- **Merge dans main** : Exécution de tous les tests (P1-P4)
- **Nightly Build** : Exécution complète avec tests de performance et stress (P4)

## Gestion des Dépendances Externes

La gestion efficace des dépendances externes est essentielle pour créer des tests fiables et reproductibles.

### Techniques de Mocking

#### Mocking avec Pester

```powershell
Describe "Test avec mock Pester" {
    BeforeAll {
        # Mock d'une fonction qui appelle un service externe

        Mock Invoke-RestMethod {
            return @{
                StatusCode = 200
                Content = '{"data": "mocked response"}'
            }
        }
    }

    It "Devrait utiliser le mock au lieu du service réel" {
        $result = Get-ExternalData -Url "https://api.example.com"
        $result.data | Should -Be "mocked response"
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
    }
}
```plaintext
#### Injection de Dépendances

```powershell
# Fonction avec injection de dépendance

function Get-ProcessedData {
    param(
        [Parameter(Mandatory)]
        [string]$InputData,

        [Parameter()]
        [scriptblock]$DataProvider = { param($url) Invoke-RestMethod -Uri $url }
    )

    $externalData = & $DataProvider -url "https://api.example.com"
    return "$InputData - $($externalData.data)"
}

# Test avec mock injecté

Describe "Test avec injection de dépendance" {
    It "Devrait utiliser le provider injecté" {
        $mockProvider = { param($url) return @{ data = "mocked data" } }
        $result = Get-ProcessedData -InputData "Test" -DataProvider $mockProvider
        $result | Should -Be "Test - mocked data"
    }
}
```plaintext
### Mocking de Systèmes Spécifiques

#### Bases de Données

```powershell
# Mock pour SQL Server

Mock Invoke-Sqlcmd {
    return @(
        [PSCustomObject]@{
            Id = 1
            Name = "Test User"
            Email = "test@example.com"
        }
    )
}
```plaintext
#### Services Web

```powershell
# Mock pour API REST

Mock Invoke-RestMethod {
    $response = switch -Regex ($Uri) {
        '/users/\d+' { @{ name = "Test User"; email = "test@example.com" } }
        '/products' { @( @{ id = 1; name = "Product 1" }, @{ id = 2; name = "Product 2" } ) }
        default { throw "Not Found" }
    }
    return $response
} -ParameterFilter { $Method -eq 'GET' }
```plaintext
## Métriques de Qualité Supplémentaires

Au-delà de la couverture de code, d'autres métriques sont essentielles pour évaluer la qualité des tests et du code testé.

### Complexité Cyclomatique

La complexité cyclomatique mesure le nombre de chemins d'exécution indépendants dans le code, ce qui affecte directement la testabilité.

**Objectifs :**
- Complexité cyclomatique < 10 pour les fonctions individuelles
- Complexité moyenne < 5 pour l'ensemble du module

**Mesure :**
```powershell
# Utilisation de PSScriptAnalyzer pour mesurer la complexité

Install-Module -Name PSScriptAnalyzer -Force
$results = Invoke-ScriptAnalyzer -Path $modulePath -Recurse -Settings PSGallery
$complexity = $results | Where-Object { $_.RuleName -eq 'PSAvoidUsingCmdletAliases' }
$complexity | Format-Table -Property ScriptName, Line, Column, Message
```plaintext
### Temps d'Exécution des Tests

Le temps d'exécution des tests est crucial pour l'intégration continue et le feedback rapide.

**Objectifs :**
- Tests P1 : < 30 secondes
- Tests P2 : < 2 minutes
- Tests P3 : < 5 minutes
- Tests P4 : < 15 minutes (hors tests de stress)

**Mesure :**
```powershell
# Mesure du temps d'exécution des tests

$startTime = Get-Date
Invoke-Pester -Configuration $pesterConfig
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds
Write-Host "Durée d'exécution des tests : $duration secondes"
```plaintext
### Stabilité des Tests

La stabilité des tests mesure leur fiabilité et leur déterminisme.

**Objectifs :**
- Taux d'échec aléatoire < 1%
- Pas de tests "flaky" (instables)

**Amélioration :**
- Identifier et corriger les tests instables
- Isoler les tests qui dépendent de l'état
- Éviter les dépendances sur le timing ou l'ordre d'exécution
- Utiliser des timeouts appropriés

## Conclusion

La méthodologie de tests progressive en 4 phases est un outil puissant pour garantir la qualité, la robustesse et la performance du code. En suivant cette approche structurée et en l'intégrant dans le workflow COMBO (DEVR+TEST+DEBUG), vous pouvez développer des tests exhaustifs qui couvrent tous les aspects de votre code.

Les points clés à retenir sont :
- Progression méthodique à travers les 4 phases de test (P1-P4)
- Intégration avec le workflow COMBO et les autres modes opérationnels
- Utilisation de formats standardisés pour documenter les résultats
- Gestion efficace des dépendances externes
- Suivi de métriques de qualité supplémentaires
- Intégration avec les pipelines CI/CD

N'oubliez pas que l'objectif est d'atteindre une couverture de code d'au moins 95% (idéalement 100%) et de s'assurer que tous les tests sont réussis avant de considérer une tâche comme complète.

Pour plus de détails techniques sur la méthodologie, consultez le document de référence technique à l'emplacement `.augment/testing-methodology.md`.
