Describe "Fonctions communes des scripts de performance" {
    Context "New-DirectoryIfNotExists" {
        BeforeAll {
            # Définir la fonction à tester
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
    
    Context "Formatage des données pour JavaScript" {
        BeforeAll {
            # Définir la fonction à tester
            $jsData = { param($data) ($data | ConvertTo-Json -Compress -Depth 1) }
            
            # Créer des données de test
            $testData = @(
                [PSCustomObject]@{ Name = "Test1"; Value = 10 },
                [PSCustomObject]@{ Name = "Test2"; Value = 20 },
                [PSCustomObject]@{ Name = "Test3"; Value = 30 }
            )
        }
        
        It "Formate correctement les données en JSON" {
            # Appeler la fonction avec les données de test
            $result = & $jsData -data $testData
            
            # Vérifier que le résultat est une chaîne JSON valide
            { $result | ConvertFrom-Json } | Should -Not -Throw
            
            # Vérifier que les données sont correctement formatées
            $jsonData = $result | ConvertFrom-Json
            $jsonData.Count | Should -Be 3
            $jsonData[0].Name | Should -Be "Test1"
            $jsonData[0].Value | Should -Be 10
        }
    }
    
    Context "Tri des résultats avec plusieurs critères" {
        BeforeAll {
            # Créer des données de test
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
        
        It "Trie correctement par taux de succès décroissant puis par temps d'exécution" {
            # Trier les résultats
            $sortedResults = $testResults | Sort-Object -Property @{Expression = 'SuccessRatePercent'; Descending = $true}, 'AverageExecutionTimeS'
            
            # Vérifier que le premier élément a le taux de succès le plus élevé
            $sortedResults[0].SuccessRatePercent | Should -Be 100
            
            # Vérifier que parmi les éléments avec le même taux de succès, celui avec le temps d'exécution le plus court est en premier
            $sortedResults[0].AverageExecutionTimeS | Should -Be 4.5
            $sortedResults[1].AverageExecutionTimeS | Should -Be 5.2
        }
    }
    
    Context "Calcul des statistiques" {
        BeforeAll {
            # Créer des données de test
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
