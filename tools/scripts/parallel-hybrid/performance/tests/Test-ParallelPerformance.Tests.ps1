BeforeAll {
    # Aucune fonction Ã  dÃ©finir pour ce test
}

Describe "Test-ParallelPerformance" {
    Context "Mesure des performances" {
        BeforeAll {
            # CrÃ©er un script de test simple
            $testScriptPath = Join-Path -Path $TestDrive -ChildPath "TestScript.ps1"
            @"
param(
    [int]`$SleepTime = 1,
    [switch]`$ShouldFail
)

Start-Sleep -Seconds `$SleepTime

if (`$ShouldFail) {
    throw "Ã‰chec simulÃ© pour les tests"
}

return "SuccÃ¨s"
"@ | Set-Content -Path $testScriptPath
        }

        It "Mesure correctement le temps d'exÃ©cution d'un script" {
            # Simuler la mesure d'une exÃ©cution simple
            $startTime = Get-Date
            $result = & $testScriptPath -SleepTime 1
            $endTime = Get-Date
            $elapsedTime = ($endTime - $startTime).TotalSeconds

            # VÃ©rifier que le temps Ã©coulÃ© est d'environ 1 seconde (avec une marge d'erreur)
            $elapsedTime | Should -BeGreaterThan 0.9
            $elapsedTime | Should -BeLessThan 1.5

            # VÃ©rifier que le rÃ©sultat est correct
            $result | Should -Be "SuccÃ¨s"
        }

        It "Capture correctement les erreurs lors de l'exÃ©cution d'un script" {
            # Simuler une exÃ©cution qui Ã©choue
            $errorMessage = $null
            $errorRecord = $null
            $success = $false

            try {
                $result = & $testScriptPath -ShouldFail
                $success = $true
            }
            catch {
                $errorMessage = $_.Exception.Message
                $errorRecord = $_
                $success = $false
            }

            # VÃ©rifier que l'erreur est capturÃ©e correctement
            $success | Should -Be $false
            $errorMessage | Should -Be "Ã‰chec simulÃ© pour les tests"
            $errorRecord | Should -Not -BeNullOrEmpty
        }
    }

    Context "Formatage des donnÃ©es pour les graphiques" {
        BeforeAll {
            # CrÃ©er des donnÃ©es de test pour simuler les rÃ©sultats de performance
            $validDetailedResults = @(
                [PSCustomObject]@{
                    Iteration = 1
                    ExecutionTimeS = 5.2
                    ProcessorTimeS = 4.8
                    WorkingSetMB = 150
                    PrivateMemoryMB = 120
                },
                [PSCustomObject]@{
                    Iteration = 2
                    ExecutionTimeS = 4.5
                    ProcessorTimeS = 4.2
                    WorkingSetMB = 180
                    PrivateMemoryMB = 140
                },
                [PSCustomObject]@{
                    Iteration = 3
                    ExecutionTimeS = 4.8
                    ProcessorTimeS = 4.5
                    WorkingSetMB = 170
                    PrivateMemoryMB = 130
                }
            )
        }

        It "Formate correctement les donnÃ©es pour JavaScript" {
            # DÃ©finir la fonction de formatage
            $jsData = { param($data) ($data | ConvertTo-Json -Compress -Depth 1) }

            # Appeler la fonction avec les donnÃ©es de test
            $jsLabels = & $jsData -data ($validDetailedResults | ForEach-Object { "ItÃ©ration $($_.Iteration)" })
            $jsExecTimes = & $jsData -data ($validDetailedResults | ForEach-Object { [Math]::Round($_.ExecutionTimeS, 5) })

            # VÃ©rifier que les donnÃ©es sont formatÃ©es correctement
            $jsLabels | Should -Not -BeNullOrEmpty
            $jsExecTimes | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les donnÃ©es sont au format JSON
            { $jsLabels | ConvertFrom-Json } | Should -Not -Throw
            { $jsExecTimes | ConvertFrom-Json } | Should -Not -Throw

            # VÃ©rifier le contenu des donnÃ©es
            $labelsArray = $jsLabels | ConvertFrom-Json
            $labelsArray.Count | Should -Be 3
            $labelsArray[0] | Should -Be "ItÃ©ration 1"

            $execTimesArray = $jsExecTimes | ConvertFrom-Json
            $execTimesArray.Count | Should -Be 3
            $execTimesArray[0] | Should -Be 5.2
        }
    }

    Context "Calcul des statistiques" {
        BeforeAll {
            # CrÃ©er des donnÃ©es de test pour simuler les rÃ©sultats de performance
            $testResults = @(
                [PSCustomObject]@{
                    Iteration = 1
                    ExecutionTimeS = 5.2
                    ProcessorTimeS = 4.8
                    WorkingSetMB = 150
                    PrivateMemoryMB = 120
                    Success = $true
                },
                [PSCustomObject]@{
                    Iteration = 2
                    ExecutionTimeS = 4.5
                    ProcessorTimeS = 4.2
                    WorkingSetMB = 180
                    PrivateMemoryMB = 140
                    Success = $true
                },
                [PSCustomObject]@{
                    Iteration = 3
                    ExecutionTimeS = 4.8
                    ProcessorTimeS = 4.5
                    WorkingSetMB = 170
                    PrivateMemoryMB = 130
                    Success = $false
                }
            )
        }

        It "Calcule correctement les moyennes des mÃ©triques" {
            # Filtrer les rÃ©sultats rÃ©ussis
            $successfulResults = $testResults | Where-Object { $_.Success }

            # Calculer les moyennes
            $avgExecTime = ($successfulResults | Measure-Object -Property ExecutionTimeS -Average).Average
            $avgCpuTime = ($successfulResults | Measure-Object -Property ProcessorTimeS -Average).Average
            $avgWorkingSet = ($successfulResults | Measure-Object -Property WorkingSetMB -Average).Average
            $avgPrivateMemory = ($successfulResults | Measure-Object -Property PrivateMemoryMB -Average).Average

            # VÃ©rifier que les moyennes sont calculÃ©es correctement
            $avgExecTime | Should -Be 4.85
            $avgCpuTime | Should -Be 4.5
            $avgWorkingSet | Should -Be 165
            $avgPrivateMemory | Should -Be 130
        }

        It "Calcule correctement le taux de succÃ¨s" {
            # Calculer le taux de succÃ¨s
            $successCount = ($testResults | Where-Object { $_.Success }).Count
            $totalCount = $testResults.Count
            $successRate = [Math]::Round(($successCount / $totalCount) * 100, 1)

            # VÃ©rifier que le taux de succÃ¨s est calculÃ© correctement
            $successRate | Should -Be 66.7
        }
    }
}
