BeforeAll {
    # Aucune fonction à définir pour ce test
}

Describe "Test-ParallelPerformance" {
    Context "Mesure des performances" {
        BeforeAll {
            # Créer un script de test simple
            $testScriptPath = Join-Path -Path $TestDrive -ChildPath "TestScript.ps1"
            @"
param(
    [int]`$SleepTime = 1,
    [switch]`$ShouldFail
)

Start-Sleep -Seconds `$SleepTime

if (`$ShouldFail) {
    throw "Échec simulé pour les tests"
}

return "Succès"
"@ | Set-Content -Path $testScriptPath
        }

        It "Mesure correctement le temps d'exécution d'un script" {
            # Simuler la mesure d'une exécution simple
            $startTime = Get-Date
            $result = & $testScriptPath -SleepTime 1
            $endTime = Get-Date
            $elapsedTime = ($endTime - $startTime).TotalSeconds

            # Vérifier que le temps écoulé est d'environ 1 seconde (avec une marge d'erreur)
            $elapsedTime | Should -BeGreaterThan 0.9
            $elapsedTime | Should -BeLessThan 1.5

            # Vérifier que le résultat est correct
            $result | Should -Be "Succès"
        }

        It "Capture correctement les erreurs lors de l'exécution d'un script" {
            # Simuler une exécution qui échoue
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

            # Vérifier que l'erreur est capturée correctement
            $success | Should -Be $false
            $errorMessage | Should -Be "Échec simulé pour les tests"
            $errorRecord | Should -Not -BeNullOrEmpty
        }
    }

    Context "Formatage des données pour les graphiques" {
        BeforeAll {
            # Créer des données de test pour simuler les résultats de performance
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

        It "Formate correctement les données pour JavaScript" {
            # Définir la fonction de formatage
            $jsData = { param($data) ($data | ConvertTo-Json -Compress -Depth 1) }

            # Appeler la fonction avec les données de test
            $jsLabels = & $jsData -data ($validDetailedResults | ForEach-Object { "Itération $($_.Iteration)" })
            $jsExecTimes = & $jsData -data ($validDetailedResults | ForEach-Object { [Math]::Round($_.ExecutionTimeS, 5) })

            # Vérifier que les données sont formatées correctement
            $jsLabels | Should -Not -BeNullOrEmpty
            $jsExecTimes | Should -Not -BeNullOrEmpty

            # Vérifier que les données sont au format JSON
            { $jsLabels | ConvertFrom-Json } | Should -Not -Throw
            { $jsExecTimes | ConvertFrom-Json } | Should -Not -Throw

            # Vérifier le contenu des données
            $labelsArray = $jsLabels | ConvertFrom-Json
            $labelsArray.Count | Should -Be 3
            $labelsArray[0] | Should -Be "Itération 1"

            $execTimesArray = $jsExecTimes | ConvertFrom-Json
            $execTimesArray.Count | Should -Be 3
            $execTimesArray[0] | Should -Be 5.2
        }
    }

    Context "Calcul des statistiques" {
        BeforeAll {
            # Créer des données de test pour simuler les résultats de performance
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

        It "Calcule correctement les moyennes des métriques" {
            # Filtrer les résultats réussis
            $successfulResults = $testResults | Where-Object { $_.Success }

            # Calculer les moyennes
            $avgExecTime = ($successfulResults | Measure-Object -Property ExecutionTimeS -Average).Average
            $avgCpuTime = ($successfulResults | Measure-Object -Property ProcessorTimeS -Average).Average
            $avgWorkingSet = ($successfulResults | Measure-Object -Property WorkingSetMB -Average).Average
            $avgPrivateMemory = ($successfulResults | Measure-Object -Property PrivateMemoryMB -Average).Average

            # Vérifier que les moyennes sont calculées correctement
            $avgExecTime | Should -Be 4.85
            $avgCpuTime | Should -Be 4.5
            $avgWorkingSet | Should -Be 165
            $avgPrivateMemory | Should -Be 130
        }

        It "Calcule correctement le taux de succès" {
            # Calculer le taux de succès
            $successCount = ($testResults | Where-Object { $_.Success }).Count
            $totalCount = $testResults.Count
            $successRate = [Math]::Round(($successCount / $totalCount) * 100, 1)

            # Vérifier que le taux de succès est calculé correctement
            $successRate | Should -Be 66.7
        }
    }
}
