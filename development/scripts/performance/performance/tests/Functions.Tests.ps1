Describe "Fonctions communes des scripts de performance" {
    Context "New-DirectoryIfNotExists" {
        BeforeAll {
            # DÃ©finir la fonction Ã  tester
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
    
    Context "Formatage des donnÃ©es pour JavaScript" {
        BeforeAll {
            # DÃ©finir la fonction Ã  tester
            $jsData = { param($data) ($data | ConvertTo-Json -Compress -Depth 1) }
            
            # CrÃ©er des donnÃ©es de test
            $testData = @(
                [PSCustomObject]@{ Name = "Test1"; Value = 10 },
                [PSCustomObject]@{ Name = "Test2"; Value = 20 },
                [PSCustomObject]@{ Name = "Test3"; Value = 30 }
            )
        }
        
        It "Formate correctement les donnÃ©es en JSON" {
            # Appeler la fonction avec les donnÃ©es de test
            $result = & $jsData -data $testData
            
            # VÃ©rifier que le rÃ©sultat est une chaÃ®ne JSON valide
            { $result | ConvertFrom-Json } | Should -Not -Throw
            
            # VÃ©rifier que les donnÃ©es sont correctement formatÃ©es
            $jsonData = $result | ConvertFrom-Json
            $jsonData.Count | Should -Be 3
            $jsonData[0].Name | Should -Be "Test1"
            $jsonData[0].Value | Should -Be 10
        }
    }
    
    Context "Tri des rÃ©sultats avec plusieurs critÃ¨res" {
        BeforeAll {
            # CrÃ©er des donnÃ©es de test
            $testResults = @(
                [PSCustomObject]@{
                    BatchSize = 10
                    SuccessRatePercent = 100
                    AverageExecutionTimeS = 5.2
                },
                [PSCustomObject]@{
                    BatchSize = 20
                    SuccessRatePercent = 100
                    AverageExecutionTimeS = 4.5
                },
                [PSCustomObject]@{
                    BatchSize = 50
                    SuccessRatePercent = 80
                    AverageExecutionTimeS = 3.8
                },
                [PSCustomObject]@{
                    BatchSize = 100
                    SuccessRatePercent = 60
                    AverageExecutionTimeS = 3.2
                }
            )
        }
        
        It "Trie correctement par taux de succÃ¨s dÃ©croissant puis par temps d'exÃ©cution" {
            # Trier les rÃ©sultats
            $sortedResults = $testResults | Sort-Object -Property @{Expression = 'SuccessRatePercent'; Descending = $true}, 'AverageExecutionTimeS'
            
            # VÃ©rifier que le premier Ã©lÃ©ment a le taux de succÃ¨s le plus Ã©levÃ©
            $sortedResults[0].SuccessRatePercent | Should -Be 100
            
            # VÃ©rifier que parmi les Ã©lÃ©ments avec le mÃªme taux de succÃ¨s, celui avec le temps d'exÃ©cution le plus court est en premier
            $sortedResults[0].AverageExecutionTimeS | Should -Be 4.5
            $sortedResults[1].AverageExecutionTimeS | Should -Be 5.2
        }
    }
    
    Context "Calcul des statistiques" {
        BeforeAll {
            # CrÃ©er des donnÃ©es de test
            $testResults = @(
                [PSCustomObject]@{
                    ExecutionTimeS = 5.2
                    ProcessorTimeS = 4.8
                    WorkingSetMB = 150
                    PrivateMemoryMB = 120
                    Success = $true
                },
                [PSCustomObject]@{
                    ExecutionTimeS = 4.5
                    ProcessorTimeS = 4.2
                    WorkingSetMB = 180
                    PrivateMemoryMB = 140
                    Success = $true
                },
                [PSCustomObject]@{
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
