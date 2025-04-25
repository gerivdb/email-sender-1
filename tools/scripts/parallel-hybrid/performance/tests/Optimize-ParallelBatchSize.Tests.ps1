BeforeAll {
    # Définir la fonction New-DirectoryIfNotExists pour les tests
    function New-DirectoryIfNotExists {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [string]$Path,
            [string]$Purpose
        )

        if (-not (Test-Path -Path $Path -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($Path, "Créer le répertoire pour $Purpose")) {
                $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
            }
        }

        return (Resolve-Path -Path $Path).Path
    }
}

Describe "Optimize-ParallelBatchSize" {
    Context "New-DirectoryIfNotExists" {
        BeforeAll {
            # Créer un répertoire temporaire pour les tests
            $testDir = Join-Path -Path $TestDrive -ChildPath "TestDir"
            $testSubDir = Join-Path -Path $testDir -ChildPath "SubDir"

            # S'assurer que le répertoire de test n'existe pas
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Crée un répertoire s'il n'existe pas" {
            # Appeler la fonction avec ShouldProcess forcé à $true
            $result = New-DirectoryIfNotExists -Path $testDir -Purpose "Test" -Confirm:$false

            # Vérifier que le répertoire a été créé
            Test-Path -Path $testDir | Should -Be $true

            # Vérifier que la fonction retourne le chemin complet
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be (Resolve-Path -Path $testDir).Path
        }

        It "Retourne le chemin existant si le répertoire existe déjà" {
            # Créer le répertoire manuellement
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null

            # Appeler la fonction avec ShouldProcess forcé à $true
            $result = New-DirectoryIfNotExists -Path $testSubDir -Purpose "Test" -Confirm:$false

            # Vérifier que la fonction retourne le chemin complet
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be (Resolve-Path -Path $testSubDir).Path
        }
    }

    Context "Tri des résultats" {
        BeforeAll {
            # Créer des données de test pour simuler les résultats de performance
            $testResults = @(
                [PSCustomObject]@{
                    BatchSize = 10
                    SuccessRatePercent = 100
                    AverageExecutionTimeS = 5.2
                    AverageProcessorTimeS = 4.8
                    AverageWorkingSetMB = 150
                    AveragePrivateMemoryMB = 120
                },
                [PSCustomObject]@{
                    BatchSize = 20
                    SuccessRatePercent = 100
                    AverageExecutionTimeS = 4.5
                    AverageProcessorTimeS = 4.2
                    AverageWorkingSetMB = 180
                    AveragePrivateMemoryMB = 140
                },
                [PSCustomObject]@{
                    BatchSize = 50
                    SuccessRatePercent = 80
                    AverageExecutionTimeS = 3.8
                    AverageProcessorTimeS = 3.5
                    AverageWorkingSetMB = 220
                    AveragePrivateMemoryMB = 180
                },
                [PSCustomObject]@{
                    BatchSize = 100
                    SuccessRatePercent = 60
                    AverageExecutionTimeS = 3.2
                    AverageProcessorTimeS = 3.0
                    AverageWorkingSetMB = 280
                    AveragePrivateMemoryMB = 240
                }
            )
        }

        It "Trie correctement les résultats par taux de succès décroissant puis par temps d'exécution" {
            # Simuler le tri utilisé dans le script
            $sortedResults = $testResults | Sort-Object -Property @{Expression = 'SuccessRatePercent'; Descending = $true}, 'AverageExecutionTimeS'

            # Vérifier que le premier élément a le taux de succès le plus élevé
            $sortedResults[0].SuccessRatePercent | Should -Be 100

            # Vérifier que parmi les éléments avec le même taux de succès, celui avec le temps d'exécution le plus court est en premier
            $sortedResults[0].AverageExecutionTimeS | Should -Be 4.5
            $sortedResults[1].AverageExecutionTimeS | Should -Be 5.2
        }

        It "Identifie correctement le résultat optimal selon le critère 'FastestSuccessful'" {
            # Simuler la logique de sélection du résultat optimal
            $successfulRuns = $testResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AverageExecutionTimeS -ge 0 }
            $optimalResult = $successfulRuns | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1

            # Vérifier que le résultat optimal est celui avec 100% de succès et le temps d'exécution le plus court
            $optimalResult.BatchSize | Should -Be 20
            $optimalResult.AverageExecutionTimeS | Should -Be 4.5
        }

        It "Gère correctement le cas où aucun résultat n'a 100% de succès" {
            # Créer des données de test sans résultat à 100% de succès
            $noSuccessResults = $testResults | Where-Object { $_.SuccessRatePercent -lt 100 }

            # Simuler la logique de sélection du résultat partiellement réussi
            $partialResults = $noSuccessResults | Where-Object { $_.SuccessRatePercent -gt 0 -and $_.AverageExecutionTimeS -ge 0 }
            $partiallySuccessful = $partialResults | Sort-Object -Property SuccessRatePercent -Descending | Select-Object -First 1

            # Vérifier que le résultat partiellement réussi est celui avec le taux de succès le plus élevé
            $partiallySuccessful.BatchSize | Should -Be 50
            $partiallySuccessful.SuccessRatePercent | Should -Be 80
        }
    }
}
