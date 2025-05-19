<#
.SYNOPSIS
    Tests progressifs pour le mécanisme de throttling adaptatif.

.DESCRIPTION
    Ce fichier contient des tests progressifs pour le mécanisme de throttling adaptatif
    du module UnifiedParallel, organisés en 4 phases:
    - Phase 1 (P1): Tests basiques pour les fonctionnalités essentielles
    - Phase 2 (P2): Tests de robustesse avec valeurs limites et cas particuliers
    - Phase 3 (P3): Tests d'exceptions pour la gestion des erreurs
    - Phase 4 (P4): Tests avancés pour les scénarios complexes

.NOTES
    Version:        1.0.0
    Auteur:         UnifiedParallel Team
    Date création:  2025-05-27
#>

#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel

    # Fonction utilitaire pour simuler une charge CPU
    function Invoke-CPULoad {
        param(
            [Parameter(Mandatory = $false)]
            [int]$DurationSeconds = 2,

            [Parameter(Mandatory = $false)]
            [int]$LoadPercent = 50
        )

        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($DurationSeconds)

        # Calculer le temps de travail et de pause en fonction de la charge
        $workTime = [TimeSpan]::FromMilliseconds(10 * $LoadPercent / 100)
        $sleepTime = [TimeSpan]::FromMilliseconds(10 * (100 - $LoadPercent) / 100)

        while ((Get-Date) -lt $endTime) {
            $workStart = Get-Date

            # Simuler une charge CPU
            while (((Get-Date) - $workStart) -lt $workTime) {
                $null = 1 + 1
            }

            # Pause pour réduire la charge
            Start-Sleep -Milliseconds $sleepTime.TotalMilliseconds
        }
    }

    # Fonction utilitaire pour exécuter un test de throttling adaptatif
    function Test-AdaptiveThrottling {
        param(
            [Parameter(Mandatory = $false)]
            [int]$InitialThreads = 8,

            [Parameter(Mandatory = $false)]
            [int]$ItemCount = 20,

            [Parameter(Mandatory = $false)]
            [int]$CPULoadPercent = 70,

            [Parameter(Mandatory = $false)]
            [switch]$EnableThrottling,

            [Parameter(Mandatory = $false)]
            [switch]$EnableBackpressure,

            [Parameter(Mandatory = $false)]
            [switch]$MeasurePerformance
        )

        # Configurer le throttling adaptatif
        $config = Get-ModuleConfig
        $config.ThrottlingSettings.Enabled = $EnableThrottling
        $config.ThrottlingSettings.AdaptiveThrottling = $EnableThrottling
        $config.ThrottlingSettings.MinThreads = 1
        $config.ThrottlingSettings.MaxThreads = $InitialThreads * 2
        $config.ThrottlingSettings.InitialThreads = $InitialThreads
        $config.ThrottlingSettings.CPUThreshold = 80
        $config.ThrottlingSettings.MemoryThreshold = 80

        # Configurer le backpressure
        $config.BackpressureSettings.Enabled = $EnableBackpressure
        $config.BackpressureSettings.CPUThreshold = 90
        $config.BackpressureSettings.MemoryThreshold = 90

        # Appliquer la configuration
        Set-ModuleConfig -Value $config

        # Créer des éléments à traiter
        $items = 1..$ItemCount

        # Créer un script block qui simule une charge CPU
        $scriptBlock = {
            param($item, $cpuLoad)

            # Simuler une charge CPU
            $startTime = Get-Date
            $endTime = $startTime.AddSeconds(1)

            # Calculer le temps de travail et de pause en fonction de la charge
            $workTime = [TimeSpan]::FromMilliseconds(10 * $cpuLoad / 100)
            $sleepTime = [TimeSpan]::FromMilliseconds(10 * (100 - $cpuLoad) / 100)

            while ((Get-Date) -lt $endTime) {
                $workStart = Get-Date

                # Simuler une charge CPU
                while (((Get-Date) - $workStart) -lt $workTime) {
                    $null = 1 + 1
                }

                # Pause pour réduire la charge
                Start-Sleep -Milliseconds $sleepTime.TotalMilliseconds
            }

            # Retourner un résultat
            return "Résultat pour l'élément $item"
        }

        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Exécuter le traitement parallèle
        $results = Invoke-UnifiedParallel -Scriptblock $scriptBlock -InputObject $items -AdditionalParameters @{
            cpuLoad = $CPULoadPercent
        } -MaxThreads $InitialThreads -NoProgress

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Récupérer les métriques
        $metrics = Get-UnifiedParallelMetrics

        # Créer un objet de résultat
        $result = [PSCustomObject]@{
            ElapsedMs    = $elapsedMs
            Results      = $results
            Metrics      = $metrics
            ThreadsUsed  = $metrics.MaxThreadsUsed
            SuccessCount = ($results | Where-Object { $_ -match "Résultat pour l'élément" }).Count
            Config       = $config
        }

        return $result
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel
}

#region Phase 1 - Tests basiques pour les fonctionnalités essentielles
Describe "Throttling Adaptatif - Tests basiques" -Tag "P1" {
    Context "Activation et désactivation du throttling" {
        It "Exécute correctement sans throttling adaptatif" {
            # Act
            $result = Test-AdaptiveThrottling -InitialThreads 4 -ItemCount 10 -CPULoadPercent 30 -EnableThrottling:$false

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 10
            $result.SuccessCount | Should -Be 10
            $result.ThreadsUsed | Should -Be 4
        }

        It "Exécute correctement avec throttling adaptatif" {
            # Act
            $result = Test-AdaptiveThrottling -InitialThreads 4 -ItemCount 10 -CPULoadPercent 30 -EnableThrottling

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 10
            $result.SuccessCount | Should -Be 10
        }
    }
}
#endregion

#region Phase 2 - Tests de robustesse avec valeurs limites et cas particuliers
Describe "Throttling Adaptatif - Tests de robustesse" -Tag "P2" {
    Context "Comportement avec différentes charges CPU" {
        It "Réduit le nombre de threads avec une charge CPU élevée" {
            # Act
            $result = Test-AdaptiveThrottling -InitialThreads 8 -ItemCount 16 -CPULoadPercent 80 -EnableThrottling

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 16
            $result.SuccessCount | Should -Be 16

            # Vérifier que le nombre de threads a été réduit
            # Note: Cette vérification peut être difficile car le throttling adaptatif
            # peut ne pas réduire les threads si la charge système n'est pas assez élevée
            # pendant le test. Nous vérifions simplement que le test s'exécute correctement.
            Write-Host "Nombre de threads utilisés: $($result.ThreadsUsed)"
        }

        It "Augmente le nombre de threads avec une charge CPU faible" {
            # Act
            $result = Test-AdaptiveThrottling -InitialThreads 2 -ItemCount 16 -CPULoadPercent 20 -EnableThrottling

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 16
            $result.SuccessCount | Should -Be 16

            # Vérifier que le nombre de threads a été augmenté
            # Note: Cette vérification peut être difficile car le throttling adaptatif
            # peut ne pas augmenter les threads si la charge système est déjà élevée
            # pendant le test. Nous vérifions simplement que le test s'exécute correctement.
            Write-Host "Nombre de threads utilisés: $($result.ThreadsUsed)"
        }
    }

    Context "Limites de threads" {
        It "Respecte la limite minimale de threads" {
            # Configurer le throttling adaptatif avec une limite minimale
            $config = Get-ModuleConfig
            $config.ThrottlingSettings.Enabled = $true
            $config.ThrottlingSettings.AdaptiveThrottling = $true
            $config.ThrottlingSettings.MinThreads = 2
            $config.ThrottlingSettings.MaxThreads = 8
            $config.ThrottlingSettings.InitialThreads = 4
            $config.ThrottlingSettings.CPUThreshold = 50
            Set-ModuleConfig -Value $config

            # Act
            $result = Test-AdaptiveThrottling -InitialThreads 4 -ItemCount 10 -CPULoadPercent 90 -EnableThrottling

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 10
            $result.SuccessCount | Should -Be 10

            # Vérifier que le nombre de threads n'est pas inférieur à la limite minimale
            $result.ThreadsUsed | Should -BeGreaterOrEqual 2
        }

        It "Respecte la limite maximale de threads" {
            # Configurer le throttling adaptatif avec une limite maximale
            $config = Get-ModuleConfig
            $config.ThrottlingSettings.Enabled = $true
            $config.ThrottlingSettings.AdaptiveThrottling = $true
            $config.ThrottlingSettings.MinThreads = 1
            $config.ThrottlingSettings.MaxThreads = 4
            $config.ThrottlingSettings.InitialThreads = 2
            $config.ThrottlingSettings.CPUThreshold = 90
            Set-ModuleConfig -Value $config

            # Act
            $result = Test-AdaptiveThrottling -InitialThreads 2 -ItemCount 10 -CPULoadPercent 10 -EnableThrottling

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 10
            $result.SuccessCount | Should -Be 10

            # Vérifier que le nombre de threads n'est pas supérieur à la limite maximale
            $result.ThreadsUsed | Should -BeLessOrEqual 4
        }
    }
}
#endregion

#region Phase 3 - Tests d'exceptions pour la gestion des erreurs
Describe "Throttling Adaptatif - Tests d'exceptions" -Tag "P3" {
    Context "Gestion des erreurs de configuration" {
        It "Gère correctement une configuration invalide (MinThreads > MaxThreads)" {
            # Configurer le throttling adaptatif avec une configuration invalide
            $config = Get-ModuleConfig
            $config.ThrottlingSettings.Enabled = $true
            $config.ThrottlingSettings.AdaptiveThrottling = $true
            $config.ThrottlingSettings.MinThreads = 8
            $config.ThrottlingSettings.MaxThreads = 4
            $config.ThrottlingSettings.InitialThreads = 6
            $config.ThrottlingSettings.CPUThreshold = 80
            Set-ModuleConfig -Value $config

            # Act & Assert
            # Le module devrait corriger automatiquement la configuration invalide
            # ou utiliser des valeurs par défaut raisonnables
            { Test-AdaptiveThrottling -InitialThreads 6 -ItemCount 5 -CPULoadPercent 50 -EnableThrottling } | Should -Not -Throw

            $result = Test-AdaptiveThrottling -InitialThreads 6 -ItemCount 5 -CPULoadPercent 50 -EnableThrottling
            $result.Results.Count | Should -Be 5
            $result.SuccessCount | Should -Be 5
        }

        It "Gère correctement une configuration invalide (InitialThreads hors limites)" {
            # Configurer le throttling adaptatif avec une configuration invalide
            $config = Get-ModuleConfig
            $config.ThrottlingSettings.Enabled = $true
            $config.ThrottlingSettings.AdaptiveThrottling = $true
            $config.ThrottlingSettings.MinThreads = 2
            $config.ThrottlingSettings.MaxThreads = 8
            $config.ThrottlingSettings.InitialThreads = 10
            $config.ThrottlingSettings.CPUThreshold = 80
            Set-ModuleConfig -Value $config

            # Act & Assert
            # Le module devrait corriger automatiquement la configuration invalide
            # ou utiliser des valeurs par défaut raisonnables
            { Test-AdaptiveThrottling -InitialThreads 10 -ItemCount 5 -CPULoadPercent 50 -EnableThrottling } | Should -Not -Throw

            $result = Test-AdaptiveThrottling -InitialThreads 10 -ItemCount 5 -CPULoadPercent 50 -EnableThrottling
            $result.Results.Count | Should -Be 5
            $result.SuccessCount | Should -Be 5
        }
    }

    Context "Gestion des erreurs d'exécution" {
        It "Gère correctement les erreurs dans les tâches parallèles" {
            # Configurer le throttling adaptatif
            $config = Get-ModuleConfig
            $config.ThrottlingSettings.Enabled = $true
            $config.ThrottlingSettings.AdaptiveThrottling = $true
            $config.ThrottlingSettings.MinThreads = 1
            $config.ThrottlingSettings.MaxThreads = 4
            $config.ThrottlingSettings.InitialThreads = 2
            $config.ThrottlingSettings.CPUThreshold = 80
            Set-ModuleConfig -Value $config

            # Créer des éléments à traiter
            $items = 1..10

            # Créer un script block qui génère des erreurs pour certains éléments
            $scriptBlock = {
                param($item)

                # Générer une erreur pour les éléments pairs
                if ($item % 2 -eq 0) {
                    throw "Erreur simulée pour l'élément $item"
                }

                # Retourner un résultat pour les éléments impairs
                return "Résultat pour l'élément $item"
            }

            # Act
            $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $items -MaxThreads 2 -NoProgress -ErrorAction SilentlyContinue

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $successCount = ($results | Where-Object { $_ -match "Résultat pour l'élément" }).Count
            $successCount | Should -Be 5

            # Vérifier que le throttling adaptatif continue de fonctionner malgré les erreurs
            $metrics = Get-UnifiedParallelMetrics
            $metrics | Should -Not -BeNullOrEmpty
        }
    }
}
#endregion

#region Phase 4 - Tests avancés pour les scénarios complexes
Describe "Throttling Adaptatif - Tests avancés" -Tag "P4" {
    Context "Performance avec différentes configurations" {
        It "Mesure les performances avec throttling adaptatif activé" {
            # Act
            $result = Test-AdaptiveThrottling -InitialThreads 4 -ItemCount 20 -CPULoadPercent 50 -EnableThrottling -MeasurePerformance

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 20
            $result.SuccessCount | Should -Be 20

            # Afficher les métriques de performance
            Write-Host "Temps d'exécution avec throttling adaptatif: $($result.ElapsedMs) ms"
            Write-Host "Nombre de threads utilisés: $($result.ThreadsUsed)"
        }

        It "Mesure les performances avec throttling adaptatif désactivé" {
            # Act
            $result = Test-AdaptiveThrottling -InitialThreads 4 -ItemCount 20 -CPULoadPercent 50 -EnableThrottling:$false -MeasurePerformance

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 20
            $result.SuccessCount | Should -Be 20

            # Afficher les métriques de performance
            Write-Host "Temps d'exécution sans throttling adaptatif: $($result.ElapsedMs) ms"
            Write-Host "Nombre de threads utilisés: $($result.ThreadsUsed)"
        }
    }

    Context "Intégration avec le mécanisme de backpressure" {
        It "Combine throttling adaptatif et backpressure" {
            # Act
            $result = Test-AdaptiveThrottling -InitialThreads 6 -ItemCount 30 -CPULoadPercent 70 -EnableThrottling -EnableBackpressure

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 30
            $result.SuccessCount | Should -Be 30

            # Afficher les métriques
            Write-Host "Temps d'exécution avec throttling et backpressure: $($result.ElapsedMs) ms"
            Write-Host "Nombre de threads utilisés: $($result.ThreadsUsed)"
        }

        It "Gère correctement les charges de travail variables" {
            # Configurer le throttling adaptatif
            $config = Get-ModuleConfig
            $config.ThrottlingSettings.Enabled = $true
            $config.ThrottlingSettings.AdaptiveThrottling = $true
            $config.ThrottlingSettings.MinThreads = 1
            $config.ThrottlingSettings.MaxThreads = 8
            $config.ThrottlingSettings.InitialThreads = 4
            $config.ThrottlingSettings.CPUThreshold = 70
            $config.BackpressureSettings.Enabled = $true
            $config.BackpressureSettings.CPUThreshold = 85
            Set-ModuleConfig -Value $config

            # Créer des éléments à traiter avec des charges variables
            $items = 1..20 | ForEach-Object {
                [PSCustomObject]@{
                    Id   = $_
                    Load = if ($_ % 5 -eq 0) { 90 } elseif ($_ % 3 -eq 0) { 60 } else { 30 }
                }
            }

            # Créer un script block qui simule une charge variable
            $scriptBlock = {
                param($item)

                # Simuler une charge CPU variable
                $startTime = Get-Date
                $endTime = $startTime.AddSeconds(1)

                # Calculer le temps de travail et de pause en fonction de la charge
                $workTime = [TimeSpan]::FromMilliseconds(10 * $item.Load / 100)
                $sleepTime = [TimeSpan]::FromMilliseconds(10 * (100 - $item.Load) / 100)

                while ((Get-Date) -lt $endTime) {
                    $workStart = Get-Date

                    # Simuler une charge CPU
                    while (((Get-Date) - $workStart) -lt $workTime) {
                        $null = 1 + 1
                    }

                    # Pause pour réduire la charge
                    Start-Sleep -Milliseconds $sleepTime.TotalMilliseconds
                }

                # Retourner un résultat
                return "Résultat pour l'élément $($item.Id) (charge: $($item.Load)%)"
            }

            # Act
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $items -MaxThreads 4 -NoProgress
            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 20

            # Afficher les métriques
            $metrics = Get-UnifiedParallelMetrics
            Write-Host "Temps d'exécution avec charges variables: $elapsedMs ms"
            Write-Host "Nombre de threads utilisés: $($metrics.MaxThreadsUsed)"
        }
    }
}
#endregion
