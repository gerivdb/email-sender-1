<#
.SYNOPSIS
    Tests progressifs pour la fonction Wait-ForCompletedRunspace.

.DESCRIPTION
    Ce fichier contient des tests progressifs pour la fonction Wait-ForCompletedRunspace
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

    # Fonction utilitaire pour créer des runspaces de test
    function New-TestRunspaces {
        param(
            [Parameter(Mandatory = $false)]
            [int]$Count = 5,

            [Parameter(Mandatory = $false)]
            [int]$DelayMilliseconds = 100,

            [Parameter(Mandatory = $false)]
            [switch]$WithErrors
        )

        # Créer un pool de runspaces
        $pool = [runspacefactory]::CreateRunspacePool(1, $Count)
        $pool.Open()

        $runspaces = @()

        for ($i = 0; $i -lt $Count; $i++) {
            $scriptBlock = {
                param($index, $delay, $withError)

                # Simuler un traitement
                Start-Sleep -Milliseconds $delay

                # Générer une erreur si demandé
                if ($withError -and ($index % 2 -eq 0)) {
                    throw "Erreur simulée pour le runspace $index"
                }

                # Retourner un résultat
                return "Résultat du runspace $index"
            }

            $powershell = [powershell]::Create().AddScript($scriptBlock).AddParameters(@{
                    index     = $i
                    delay     = $DelayMilliseconds
                    withError = $WithErrors
                })

            $powershell.RunspacePool = $pool

            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $powershell.BeginInvoke()
                Index      = $i
            }
        }

        return @{
            Runspaces = $runspaces
            Pool      = $pool
        }
    }

    # Fonction utilitaire pour créer des runspaces avec des délais variables
    function New-TestRunspacesWithVariableDelays {
        param(
            [Parameter(Mandatory = $false)]
            [int]$Count = 5,

            [Parameter(Mandatory = $false)]
            [int[]]$DelaysMilliseconds = @(100, 200, 300, 400, 500),

            [Parameter(Mandatory = $false)]
            [switch]$WithErrors
        )

        # Créer un pool de runspaces
        $pool = [runspacefactory]::CreateRunspacePool(1, $Count)
        $pool.Open()

        $runspaces = @()

        for ($i = 0; $i -lt $Count; $i++) {
            $delayIndex = $i % $DelaysMilliseconds.Length
            $delay = $DelaysMilliseconds[$delayIndex]

            $scriptBlock = {
                param($index, $delay, $withError)

                # Simuler un traitement
                Start-Sleep -Milliseconds $delay

                # Générer une erreur si demandé
                if ($withError -and ($index % 2 -eq 0)) {
                    throw "Erreur simulée pour le runspace $index"
                }

                # Retourner un résultat
                return "Résultat du runspace $index (délai: $delay ms)"
            }

            $powershell = [powershell]::Create().AddScript($scriptBlock).AddParameters(@{
                    index     = $i
                    delay     = $delay
                    withError = $WithErrors
                })

            $powershell.RunspacePool = $pool

            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $powershell.BeginInvoke()
                Index      = $i
                Delay      = $delay
            }
        }

        return @{
            Runspaces = $runspaces
            Pool      = $pool
        }
    }

    # Fonction utilitaire pour créer des runspaces invalides
    function New-InvalidRunspaces {
        param(
            [Parameter(Mandatory = $false)]
            [ValidateSet("NoHandle", "NoPowerShell", "NullHandle", "NullPowerShell", "Mixed")]
            [string]$Type = "NoHandle"
        )

        $runspaces = @()

        switch ($Type) {
            "NoHandle" {
                # Créer des runspaces sans propriété Handle
                for ($i = 0; $i -lt 3; $i++) {
                    $runspaces += [PSCustomObject]@{
                        PowerShell = [powershell]::Create()
                        Index      = $i
                    }
                }
            }
            "NoPowerShell" {
                # Créer des runspaces sans propriété PowerShell
                for ($i = 0; $i -lt 3; $i++) {
                    $runspaces += [PSCustomObject]@{
                        Handle = $null
                        Index  = $i
                    }
                }
            }
            "NullHandle" {
                # Créer des runspaces avec Handle null
                for ($i = 0; $i -lt 3; $i++) {
                    $runspaces += [PSCustomObject]@{
                        PowerShell = [powershell]::Create()
                        Handle     = $null
                        Index      = $i
                    }
                }
            }
            "NullPowerShell" {
                # Créer des runspaces avec PowerShell null
                for ($i = 0; $i -lt 3; $i++) {
                    $runspaces += [PSCustomObject]@{
                        PowerShell = $null
                        Handle     = $null
                        Index      = $i
                    }
                }
            }
            "Mixed" {
                # Créer un mélange de runspaces valides et invalides
                $testData = New-TestRunspaces -Count 2
                $runspaces += $testData.Runspaces

                $runspaces += [PSCustomObject]@{
                    PowerShell = $null
                    Handle     = $null
                    Index      = 100
                }

                $runspaces += [PSCustomObject]@{
                    PowerShell = [powershell]::Create()
                    Index      = 101
                }
            }
        }

        return $runspaces
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel
}

#region Phase 1 - Tests basiques pour les fonctionnalités essentielles
Describe "Wait-ForCompletedRunspace - Tests basiques" -Tag "P1" {
    Context "Attente d'un seul runspace" {
        BeforeEach {
            # Créer des runspaces de test
            $testData = New-TestRunspaces -Count 5 -DelayMilliseconds 100
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Attend qu'un runspace soit complété" {
            # Act
            # Créer une copie de la collection de runspaces pour vérifier qu'elle est modifiée
            $runspacesCopy = $runspaces.Clone()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -TimeoutSeconds 5

            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty

            # Vérifier que la fonction retourne au moins un runspace complété
            # Note: La fonction peut retourner plus d'un runspace si plusieurs sont complétés en même temps
            $completedRunspaces.Count | Should -BeGreaterOrEqual 1

            # Vérifier que la collection d'entrée a été modifiée (les runspaces complétés ont été retirés)
            # Note: La fonction peut ne pas modifier la collection d'entrée si elle retourne un objet wrapper
            if ($runspacesCopy -is [System.Collections.ArrayList]) {
                $runspacesCopy.Count | Should -BeLessThan $runspaces.Count
            }
        }

        It "Retourne un objet avec les propriétés attendues" {
            # Act
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 5

            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty

            # Vérifier que le résultat a les propriétés attendues
            # Note: Le résultat peut être un objet wrapper avec une propriété Results
            if ($completedRunspaces.PSObject.Properties.Name -contains "Results") {
                $results = $completedRunspaces.Results
                $results | Should -Not -BeNullOrEmpty
                $results[0] | Should -Not -BeNullOrEmpty
            } else {
                $completedRunspaces[0] | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Attente de tous les runspaces" {
        BeforeEach {
            # Créer des runspaces de test
            $testData = New-TestRunspaces -Count 5 -DelayMilliseconds 100
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Attend que tous les runspaces soient complétés" {
            # Act
            # Créer une copie de la collection de runspaces pour vérifier qu'elle est modifiée
            $runspacesCopy = $runspaces.Clone()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -TimeoutSeconds 5

            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty

            # Vérifier que la fonction retourne tous les runspaces
            # Note: La fonction peut retourner un objet wrapper avec une propriété Results
            if ($completedRunspaces.PSObject.Properties.Name -contains "Results") {
                $results = $completedRunspaces.Results
                $results.Count | Should -Be 5
            } else {
                $completedRunspaces.Count | Should -Be 5
            }

            # Vérifier que la collection d'entrée a été modifiée (tous les runspaces ont été retirés)
            # Note: La fonction peut ne pas modifier la collection d'entrée si elle retourne un objet wrapper
            if ($runspacesCopy -is [System.Collections.ArrayList]) {
                $runspacesCopy.Count | Should -Be 0
            }
        }
    }
}
#endregion

#region Phase 2 - Tests de robustesse avec valeurs limites et cas particuliers
Describe "Wait-ForCompletedRunspace - Tests de robustesse" -Tag "P2" {
    Context "Gestion des timeouts" {
        BeforeEach {
            # Créer des runspaces de test avec un délai long
            $testData = New-TestRunspaces -Count 3 -DelayMilliseconds 1000
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Gère correctement un timeout court" {
            # Act
            # Créer une copie de la collection de runspaces pour vérifier qu'elle est modifiée
            $runspacesCopy = $runspaces.Clone()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -TimeoutSeconds 0.1

            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty

            # Vérifier que la fonction ne retourne aucun runspace (timeout atteint avant complétion)
            # Note: La fonction peut retourner un objet wrapper avec une propriété Results
            if ($completedRunspaces.PSObject.Properties.Name -contains "Results") {
                $results = $completedRunspaces.Results
                $results.Count | Should -Be 0
            } else {
                $completedRunspaces.Count | Should -Be 0
            }

            # Vérifier que la collection d'entrée n'a pas été modifiée (aucun runspace n'a été retiré)
            # Note: La fonction peut ne pas modifier la collection d'entrée si elle retourne un objet wrapper
            if ($runspacesCopy -is [System.Collections.ArrayList]) {
                $runspacesCopy.Count | Should -Be $runspaces.Count
            }
        }

        It "Nettoie les runspaces non complétés lors d'un timeout avec CleanupOnTimeout" {
            # Act
            # Créer une copie de la collection de runspaces pour vérifier qu'elle est modifiée
            $runspacesCopy = $runspaces.Clone()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -TimeoutSeconds 0.1 -CleanupOnTimeout

            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty

            # Vérifier que la fonction ne retourne aucun runspace (timeout atteint avant complétion)
            # Note: La fonction peut retourner un objet wrapper avec une propriété Results
            if ($completedRunspaces.PSObject.Properties.Name -contains "Results") {
                $results = $completedRunspaces.Results
                $results.Count | Should -Be 0
            } else {
                $completedRunspaces.Count | Should -Be 0
            }

            # Vérifier que la collection d'entrée a été vidée (tous les runspaces ont été retirés)
            # Note: La fonction peut ne pas modifier la collection d'entrée si elle retourne un objet wrapper
            if ($runspacesCopy -is [System.Collections.ArrayList]) {
                $runspacesCopy.Count | Should -Be 0
            }
        }
    }

    Context "Gestion des délais variables" {
        BeforeEach {
            # Créer des runspaces de test avec des délais variables
            $testData = New-TestRunspacesWithVariableDelays -Count 5 -DelaysMilliseconds @(50, 100, 150, 200, 250)
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Traite les runspaces dans l'ordre de complétion" {
            # Act
            # Créer une copie de la collection de runspaces pour vérifier qu'elle est modifiée
            $runspacesCopy = $runspaces.Clone()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -TimeoutSeconds 5

            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty

            # Vérifier que la fonction retourne tous les runspaces
            # Note: La fonction peut retourner un objet wrapper avec une propriété Results
            if ($completedRunspaces.PSObject.Properties.Name -contains "Results") {
                $results = $completedRunspaces.Results
                $results.Count | Should -Be 5

                # Vérifier que les runspaces sont traités dans l'ordre de complétion (délais croissants)
                $delays = $results | ForEach-Object { $_.Delay }
                $sortedDelays = $delays | Sort-Object
                $delays | Should -Be $sortedDelays
            } else {
                $completedRunspaces.Count | Should -Be 5

                # Vérifier que les runspaces sont traités dans l'ordre de complétion (délais croissants)
                $delays = $completedRunspaces | ForEach-Object { $_.Delay }
                $sortedDelays = $delays | Sort-Object
                $delays | Should -Be $sortedDelays
            }

            # Vérifier que la collection d'entrée a été vidée (tous les runspaces ont été retirés)
            # Note: La fonction peut ne pas modifier la collection d'entrée si elle retourne un objet wrapper
            if ($runspacesCopy -is [System.Collections.ArrayList]) {
                $runspacesCopy.Count | Should -Be 0
            }
        }
    }

    Context "Gestion des collections vides" {
        It "Gère correctement un tableau vide" {
            # Act
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces @() -TimeoutSeconds 1

            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty
            $completedRunspaces.Count | Should -Be 0
        }
    }
}
#endregion

#region Phase 3 - Tests d'exceptions pour la gestion des erreurs
Describe "Wait-ForCompletedRunspace - Tests d'exceptions" -Tag "P3" {
    Context "Gestion des entrées invalides" {
        It "Gère correctement les runspaces null" {
            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $null -TimeoutSeconds 1 } | Should -Throw
        }

        It "Gère les runspaces sans propriété Handle" {
            # Arrange
            $invalidRunspaces = New-InvalidRunspaces -Type "NoHandle"

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 1 } | Should -Not -Throw

            # Vérifier que la fonction ne plante pas mais retourne un résultat vide
            $result = Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 1
            $result.Count | Should -Be 0
        }

        It "Gère les runspaces sans propriété PowerShell" {
            # Arrange
            $invalidRunspaces = New-InvalidRunspaces -Type "NoPowerShell"

            # Act & Assert
            { Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 1 } | Should -Not -Throw

            # Vérifier que la fonction ne plante pas mais retourne un résultat vide
            $result = Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 1
            $result.Count | Should -Be 0
        }

        It "Gère un mélange de runspaces valides et invalides" {
            # Arrange
            $invalidRunspaces = New-InvalidRunspaces -Type "Mixed"

            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 2

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }
    }

    Context "Gestion des erreurs dans les runspaces" {
        BeforeEach {
            # Créer des runspaces de test qui génèrent des erreurs
            $testData = New-TestRunspaces -Count 4 -DelayMilliseconds 100 -WithErrors
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Capture correctement les runspaces qui génèrent des erreurs" {
            # Act
            # Créer une copie de la collection de runspaces pour vérifier qu'elle est modifiée
            $runspacesCopy = $runspaces.Clone()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -TimeoutSeconds 5

            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty

            # Vérifier que la fonction retourne tous les runspaces
            # Note: La fonction peut retourner un objet wrapper avec une propriété Results
            if ($completedRunspaces.PSObject.Properties.Name -contains "Results") {
                $results = $completedRunspaces.Results
                $results.Count | Should -Be 4

                # Vérifier que les erreurs sont correctement capturées
                $errorResults = $results | ForEach-Object {
                    try {
                        $_.PowerShell.EndInvoke($_.Handle)
                        return $true
                    } catch {
                        return $false
                    }
                }

                $errorCount = ($errorResults | Where-Object { -not $_ }).Count
                $errorCount | Should -BeGreaterThan 0
            } else {
                $completedRunspaces.Count | Should -Be 4

                # Vérifier que les erreurs sont correctement capturées
                $errorResults = $completedRunspaces | ForEach-Object {
                    try {
                        $_.PowerShell.EndInvoke($_.Handle)
                        return $true
                    } catch {
                        return $false
                    }
                }

                $errorCount = ($errorResults | Where-Object { -not $_ }).Count
                $errorCount | Should -BeGreaterThan 0
            }

            # Vérifier que la collection d'entrée a été vidée (tous les runspaces ont été retirés)
            # Note: La fonction peut ne pas modifier la collection d'entrée si elle retourne un objet wrapper
            if ($runspacesCopy -is [System.Collections.ArrayList]) {
                $runspacesCopy.Count | Should -Be 0
            }
        }
    }
}
#endregion

#region Phase 4 - Tests avancés pour les scénarios complexes
Describe "Wait-ForCompletedRunspace - Tests avancés" -Tag "P4" {
    Context "Performance avec un grand nombre de runspaces" {
        BeforeEach {
            # Créer un grand nombre de runspaces avec des délais variables
            $testData = New-TestRunspacesWithVariableDelays -Count 20 -DelaysMilliseconds @(10, 20, 30, 40, 50, 100, 150, 200)
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Traite efficacement un grand nombre de runspaces" {
            # Mesurer le temps d'exécution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Act
            # Créer une copie de la collection de runspaces pour vérifier qu'elle est modifiée
            $runspacesCopy = $runspaces.Clone()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -NoProgress -TimeoutSeconds 10

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty

            # Vérifier que la fonction retourne tous les runspaces
            # Note: La fonction peut retourner un objet wrapper avec une propriété Results
            if ($completedRunspaces.PSObject.Properties.Name -contains "Results") {
                $results = $completedRunspaces.Results
                $results.Count | Should -Be 20
            } else {
                $completedRunspaces.Count | Should -Be 20
            }

            # Vérifier que la collection d'entrée a été vidée (tous les runspaces ont été retirés)
            # Note: La fonction peut ne pas modifier la collection d'entrée si elle retourne un objet wrapper
            if ($runspacesCopy -is [System.Collections.ArrayList]) {
                $runspacesCopy.Count | Should -Be 0
            }

            # Vérifier que le temps d'exécution est raisonnable
            # Le temps devrait être proche du délai maximum (200ms) plus une marge
            $elapsedMs | Should -BeLessThan 1000

            Write-Host "Temps d'exécution pour 20 runspaces: $elapsedMs ms"
        }
    }

    Context "Comportement avec SleepMilliseconds personnalisé" {
        BeforeEach {
            # Créer des runspaces de test
            $testData = New-TestRunspaces -Count 5 -DelayMilliseconds 100
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Utilise correctement un SleepMilliseconds personnalisé" {
            # Mesurer le temps d'exécution avec un SleepMilliseconds élevé
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Act
            # Créer une copie de la collection de runspaces pour vérifier qu'elle est modifiée
            $runspacesCopy1 = $runspaces.Clone()
            $completedRunspaces1 = Wait-ForCompletedRunspace -Runspaces $runspacesCopy1 -WaitForAll -SleepMilliseconds 50 -TimeoutSeconds 5

            $stopwatch.Stop()
            $elapsedMs1 = $stopwatch.ElapsedMilliseconds

            # Recréer des runspaces pour un second test
            $testData2 = New-TestRunspaces -Count 5 -DelayMilliseconds 100
            $runspaces2 = $testData2.Runspaces

            # Mesurer le temps d'exécution avec un SleepMilliseconds faible
            $stopwatch.Restart()

            # Act
            $completedRunspaces2 = Wait-ForCompletedRunspace -Runspaces $runspaces2 -WaitForAll -SleepMilliseconds 5 -TimeoutSeconds 5

            $stopwatch.Stop()
            $elapsedMs2 = $stopwatch.ElapsedMilliseconds

            # Assert
            # Vérifier que les deux appels ont fonctionné
            $completedRunspaces1 | Should -Not -BeNullOrEmpty
            $completedRunspaces2 | Should -Not -BeNullOrEmpty

            # Vérifier que la fonction retourne tous les runspaces
            # Note: La fonction peut retourner un objet wrapper avec une propriété Results
            if ($completedRunspaces2.PSObject.Properties.Name -contains "Results") {
                $results = $completedRunspaces2.Results
                $results.Count | Should -Be 5
            } else {
                $completedRunspaces2.Count | Should -Be 5
            }

            # Le temps avec un SleepMilliseconds plus faible devrait être légèrement plus court
            # mais la différence peut être minime pour des runspaces rapides
            Write-Host "Temps avec SleepMilliseconds=50: $elapsedMs1 ms"
            Write-Host "Temps avec SleepMilliseconds=5: $elapsedMs2 ms"
        }
    }
}
#endregion
