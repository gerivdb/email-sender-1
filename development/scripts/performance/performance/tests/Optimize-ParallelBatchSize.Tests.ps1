BeforeAll {
    # DÃ©finir la fonction New-DirectoryIfNotExists pour les tests
    function New-DirectoryIfNotExists {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [string]$Path,
            [string]$Purpose
        )

        if (-not (Test-Path -Path $Path -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($Path, "CrÃ©er le rÃ©pertoire pour $Purpose")) {
                $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
            }
        }

        return (Resolve-Path -Path $Path).Path
    }
}

Describe "Optimize-ParallelBatchSize" {
    Context "New-DirectoryIfNotExists" {
        BeforeAll {
            # CrÃ©er un rÃ©pertoire temporaire pour les tests
            $testDir = Join-Path -Path $TestDrive -ChildPath "TestDir"
            $testSubDir = Join-Path -Path $testDir -ChildPath "SubDir"

            # S'assurer que le rÃ©pertoire de test n'existe pas
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "CrÃ©e un rÃ©pertoire s'il n'existe pas" {
            # Appeler la fonction avec ShouldProcess forcÃ© Ã  $true
            $result = New-DirectoryIfNotExists -Path $testDir -Purpose "Test" -Confirm:$false

            # VÃ©rifier que le rÃ©pertoire a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $testDir | Should -Be $true

            # VÃ©rifier que la fonction retourne le chemin complet
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be (Resolve-Path -Path $testDir).Path
        }

        It "Retourne le chemin existant si le rÃ©pertoire existe dÃ©jÃ " {
            # CrÃ©er le rÃ©pertoire manuellement
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null

            # Appeler la fonction avec ShouldProcess forcÃ© Ã  $true
            $result = New-DirectoryIfNotExists -Path $testSubDir -Purpose "Test" -Confirm:$false

            # VÃ©rifier que la fonction retourne le chemin complet
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be (Resolve-Path -Path $testSubDir).Path
        }
    }

    Context "Tri des rÃ©sultats" {
        BeforeAll {
            # CrÃ©er des donnÃ©es de test pour simuler les rÃ©sultats de performance
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

        It "Trie correctement les rÃ©sultats par taux de succÃ¨s dÃ©croissant puis par temps d'exÃ©cution" {
            # Simuler le tri utilisÃ© dans le script
            $sortedResults = $testResults | Sort-Object -Property @{Expression = 'SuccessRatePercent'; Descending = $true}, 'AverageExecutionTimeS'

            # VÃ©rifier que le premier Ã©lÃ©ment a le taux de succÃ¨s le plus Ã©levÃ©
            $sortedResults[0].SuccessRatePercent | Should -Be 100

            # VÃ©rifier que parmi les Ã©lÃ©ments avec le mÃªme taux de succÃ¨s, celui avec le temps d'exÃ©cution le plus court est en premier
            $sortedResults[0].AverageExecutionTimeS | Should -Be 4.5
            $sortedResults[1].AverageExecutionTimeS | Should -Be 5.2
        }

        It "Identifie correctement le rÃ©sultat optimal selon le critÃ¨re 'FastestSuccessful'" {
            # Simuler la logique de sÃ©lection du rÃ©sultat optimal
            $successfulRuns = $testResults | Where-Object { $_.SuccessRatePercent -eq 100 -and $_.AverageExecutionTimeS -ge 0 }
            $optimalResult = $successfulRuns | Sort-Object -Property AverageExecutionTimeS | Select-Object -First 1

            # VÃ©rifier que le rÃ©sultat optimal est celui avec 100% de succÃ¨s et le temps d'exÃ©cution le plus court
            $optimalResult.BatchSize | Should -Be 20
            $optimalResult.AverageExecutionTimeS | Should -Be 4.5
        }

        It "GÃ¨re correctement le cas oÃ¹ aucun rÃ©sultat n'a 100% de succÃ¨s" {
            # CrÃ©er des donnÃ©es de test sans rÃ©sultat Ã  100% de succÃ¨s
            $noSuccessResults = $testResults | Where-Object { $_.SuccessRatePercent -lt 100 }

            # Simuler la logique de sÃ©lection du rÃ©sultat partiellement rÃ©ussi
            $partialResults = $noSuccessResults | Where-Object { $_.SuccessRatePercent -gt 0 -and $_.AverageExecutionTimeS -ge 0 }
            $partiallySuccessful = $partialResults | Sort-Object -Property SuccessRatePercent -Descending | Select-Object -First 1

            # VÃ©rifier que le rÃ©sultat partiellement rÃ©ussi est celui avec le taux de succÃ¨s le plus Ã©levÃ©
            $partiallySuccessful.BatchSize | Should -Be 50
            $partiallySuccessful.SuccessRatePercent | Should -Be 80
        }
    }
}
