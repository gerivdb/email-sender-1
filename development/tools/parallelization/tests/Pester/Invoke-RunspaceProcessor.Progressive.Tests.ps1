<#
.SYNOPSIS
    Tests progressifs pour la fonction Invoke-RunspaceProcessor.

.DESCRIPTION
    Ce fichier contient des tests progressifs pour la fonction Invoke-RunspaceProcessor
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

        # Attendre que tous les runspaces soient complétés
        $completed = $false
        while (-not $completed) {
            $completed = $true
            foreach ($runspace in $runspaces) {
                if (-not $runspace.Handle.IsCompleted) {
                    $completed = $false
                    Start-Sleep -Milliseconds 10
                    break
                }
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
Describe "Invoke-RunspaceProcessor - Tests basiques" -Tag "P1" {
    Context "Traitement de runspaces valides" {
        BeforeEach {
            # Créer des runspaces de test
            $testData = New-TestRunspaces -Count 3
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

        It "Traite correctement les runspaces complétés" {
            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $runspaces

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 3
            $result.TotalProcessed | Should -Be 3
            $result.SuccessCount | Should -Be 3
            $result.ErrorCount | Should -Be 0
        }

        It "Retourne les résultats dans le format attendu" {
            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $runspaces

            # Assert
            $result.Results[0].Value | Should -Match "Résultat du runspace"
            $result.Results[0].Success | Should -BeTrue
            $result.Results[0].Error | Should -BeNullOrEmpty
        }
    }
}
#endregion

#region Phase 2 - Tests de robustesse avec valeurs limites et cas particuliers
Describe "Invoke-RunspaceProcessor - Tests de robustesse" -Tag "P2" {
    Context "Traitement de collections vides" {
        It "Gère correctement un tableau vide" {
            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces @()

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 0
            $result.TotalProcessed | Should -Be 0
            $result.SuccessCount | Should -Be 0
            $result.ErrorCount | Should -Be 0
        }

        It "Gère correctement un tableau null" {
            # Act & Assert
            { Invoke-RunspaceProcessor -CompletedRunspaces $null } | Should -Not -Throw
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $null
            $result.TotalProcessed | Should -Be 0
        }
    }

    Context "Traitement de différents types de collections" {
        BeforeEach {
            # Créer des runspaces de test
            $testData = New-TestRunspaces -Count 3
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

        It "Traite correctement un ArrayList" {
            # Arrange
            $arrayList = [System.Collections.ArrayList]::new()
            foreach ($runspace in $runspaces) {
                $arrayList.Add($runspace) | Out-Null
            }

            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $arrayList

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 3
            $result.TotalProcessed | Should -Be 3
        }

        It "Traite correctement un tableau standard" {
            # Arrange
            $array = @()
            foreach ($runspace in $runspaces) {
                $array += $runspace
            }

            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $array

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 3
            $result.TotalProcessed | Should -Be 3
        }

        It "Traite correctement un objet unique" {
            # Arrange
            $singleRunspace = $runspaces[0]

            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $singleRunspace

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 1
            $result.TotalProcessed | Should -Be 1
        }
    }
}
#endregion

#region Phase 3 - Tests d'exceptions pour la gestion des erreurs
Describe "Invoke-RunspaceProcessor - Tests d'exceptions" -Tag "P3" {
    Context "Traitement de runspaces avec erreurs" {
        BeforeEach {
            # Créer des runspaces de test qui génèrent des erreurs
            $testData = New-TestRunspaces -Count 4 -WithErrors
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

        It "Capture correctement les erreurs des runspaces" {
            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $runspaces

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 4
            $result.SuccessCount | Should -BeLessThan 4
            $result.ErrorCount | Should -BeGreaterThan 0

            # Vérifier que les erreurs sont correctement capturées
            $errorResults = $result.Results | Where-Object { -not $_.Success }
            $errorResults.Count | Should -BeGreaterThan 0
            $errorResults[0].Error | Should -Not -BeNullOrEmpty
        }

        It "Gère correctement le paramètre IgnoreErrors" {
            # Act - Aucune erreur ne devrait être écrite dans le flux d'erreur
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $runspaces -IgnoreErrors

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 4
            $result.ErrorCount | Should -BeGreaterThan 0
        }
    }

    Context "Traitement de runspaces invalides" {
        It "Gère les runspaces sans propriété Handle" {
            # Arrange
            $invalidRunspaces = New-InvalidRunspaces -Type "NoHandle"

            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $invalidRunspaces

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalProcessed | Should -Be 3
            $result.Results.Count | Should -Be 3

            # Vérifier que les résultats sont vides ou null
            $result.Results | ForEach-Object {
                $_.Value | Should -BeNullOrEmpty
            }
        }

        It "Gère les runspaces sans propriété PowerShell" {
            # Arrange
            $invalidRunspaces = New-InvalidRunspaces -Type "NoPowerShell"

            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $invalidRunspaces

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.TotalProcessed | Should -Be 3
            $result.Results.Count | Should -Be 3
        }

        It "Gère un mélange de runspaces valides et invalides" {
            # Arrange
            $invalidRunspaces = New-InvalidRunspaces -Type "Mixed"

            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $invalidRunspaces

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -BeGreaterThan 0

            # Vérifier que les runspaces valides ont été traités correctement
            $validResults = $result.Results | Where-Object { $_.Success -and $_.Value -match "Résultat du runspace" }
            $validResults.Count | Should -BeGreaterThan 0
        }
    }
}
#endregion

#region Phase 4 - Tests avancés pour les scénarios complexes
Describe "Invoke-RunspaceProcessor - Tests avancés" -Tag "P4" {
    Context "Performance avec un grand nombre de runspaces" {
        BeforeEach {
            # Créer un grand nombre de runspaces
            $testData = New-TestRunspaces -Count 20 -DelayMilliseconds 10
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
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $runspaces -NoProgress

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Results.Count | Should -Be 20
            $result.TotalProcessed | Should -Be 20

            # Vérifier que le temps d'exécution est raisonnable
            $elapsedMs | Should -BeLessThan 1000

            Write-Host "Temps d'exécution pour 20 runspaces: $elapsedMs ms"
        }
    }

    Context "Options de formatage des résultats" {
        BeforeEach {
            # Créer des runspaces de test
            $testData = New-TestRunspaces -Count 3
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

        It "Retourne uniquement les résultats avec SimpleResults" {
            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $runspaces -SimpleResults

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].Value | Should -Match "Résultat du runspace"

            # Vérifier que le résultat est une liste simple et non un objet complexe
            $result.PSObject.Properties.Name -contains "TotalProcessed" | Should -BeFalse
        }

        It "Affiche correctement la progression" {
            # Act & Assert - Vérifier que l'appel ne génère pas d'erreur
            { Invoke-RunspaceProcessor -CompletedRunspaces $runspaces -ActivityName "Test de progression" } | Should -Not -Throw
        }
    }
}
#endregion
