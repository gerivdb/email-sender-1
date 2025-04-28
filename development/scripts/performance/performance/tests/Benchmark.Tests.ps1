Describe "Tests des fonctions de benchmark" {
    Context "Measure-Operation" {
        BeforeAll {
            # DÃ©finir la fonction Ã  tester
            function Measure-Operation {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Name,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ScriptBlock,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$Iterations = 3,
                    
                    [Parameter(Mandatory = $false)]
                    [hashtable]$Parameters = @{}
                )
                
                $results = @()
                
                for ($i = 1; $i -le $Iterations; $i++) {
                    # Nettoyer la mÃ©moire avant chaque test
                    [System.GC]::Collect()
                    
                    # Mesurer l'utilisation de la mÃ©moire avant
                    $memoryBefore = [System.GC]::GetTotalMemory($true)
                    
                    # Mesurer le temps d'exÃ©cution
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    try {
                        # ExÃ©cuter l'opÃ©ration
                        $result = & $ScriptBlock @Parameters
                        $success = $true
                    }
                    catch {
                        $success = $false
                        $result = $null
                    }
                    
                    $stopwatch.Stop()
                    $executionTime = $stopwatch.Elapsed.TotalSeconds
                    
                    # Mesurer l'utilisation de la mÃ©moire aprÃ¨s
                    $memoryAfter = [System.GC]::GetTotalMemory($true)
                    $memoryUsage = ($memoryAfter - $memoryBefore) / 1MB
                    
                    # Enregistrer les rÃ©sultats
                    $results += [PSCustomObject]@{
                        Iteration = $i
                        ExecutionTime = $executionTime
                        MemoryUsageMB = $memoryUsage
                        Success = $success
                        Result = $result
                    }
                }
                
                # Calculer les statistiques
                $avgTime = ($results | Measure-Object -Property ExecutionTime -Average).Average
                $minTime = ($results | Measure-Object -Property ExecutionTime -Minimum).Minimum
                $maxTime = ($results | Measure-Object -Property ExecutionTime -Maximum).Maximum
                $avgMemory = ($results | Measure-Object -Property MemoryUsageMB -Average).Average
                $successRate = ($results | Where-Object { $_.Success } | Measure-Object).Count / $Iterations * 100
                
                return [PSCustomObject]@{
                    Name = $Name
                    AverageTime = $avgTime
                    MinTime = $minTime
                    MaxTime = $maxTime
                    AverageMemoryMB = $avgMemory
                    SuccessRate = $successRate
                    DetailedResults = $results
                }
            }
            
            # CrÃ©er des scriptblocks de test
            $fastScriptBlock = { Start-Sleep -Milliseconds 10; return "Fast" }
            $slowScriptBlock = { Start-Sleep -Milliseconds 50; return "Slow" }
            $errorScriptBlock = { throw "Test error" }
            $memoryScriptBlock = { 
                $array = @()
                for ($i = 0; $i -lt 10000; $i++) {
                    $array += "Item $i"
                }
                return $array.Count
            }
        }
        
        It "Mesure correctement le temps d'exÃ©cution" {
            # ExÃ©cuter la fonction avec un scriptblock rapide
            $fastResult = Measure-Operation -Name "Test rapide" -ScriptBlock $fastScriptBlock -Iterations 2
            
            # ExÃ©cuter la fonction avec un scriptblock lent
            $slowResult = Measure-Operation -Name "Test lent" -ScriptBlock $slowScriptBlock -Iterations 2
            
            # VÃ©rifier que le temps d'exÃ©cution est mesurÃ© correctement
            $fastResult.AverageTime | Should -BeLessThan $slowResult.AverageTime
            $fastResult.MinTime | Should -BeLessThan $slowResult.MinTime
            $fastResult.MaxTime | Should -BeLessThan $slowResult.MaxTime
        }
        
        It "Mesure correctement l'utilisation de la mÃ©moire" {
            # ExÃ©cuter la fonction avec un scriptblock qui utilise beaucoup de mÃ©moire
            $memoryResult = Measure-Operation -Name "Test mÃ©moire" -ScriptBlock $memoryScriptBlock -Iterations 2
            
            # VÃ©rifier que l'utilisation de la mÃ©moire est mesurÃ©e
            $memoryResult.AverageMemoryMB | Should -BeGreaterThan 0
        }
        
        It "GÃ¨re correctement les erreurs" {
            # ExÃ©cuter la fonction avec un scriptblock qui gÃ©nÃ¨re une erreur
            $errorResult = Measure-Operation -Name "Test erreur" -ScriptBlock $errorScriptBlock -Iterations 2
            
            # VÃ©rifier que les erreurs sont gÃ©rÃ©es correctement
            $errorResult.SuccessRate | Should -Be 0
            $errorResult.DetailedResults[0].Success | Should -Be $false
            $errorResult.DetailedResults[0].Result | Should -BeNullOrEmpty
        }
        
        It "Accepte des paramÃ¨tres pour le scriptblock" {
            # CrÃ©er un scriptblock qui utilise des paramÃ¨tres
            $paramScriptBlock = { 
                param($value)
                return $value * 2
            }
            
            # ExÃ©cuter la fonction avec des paramÃ¨tres
            $paramResult = Measure-Operation -Name "Test paramÃ¨tres" -ScriptBlock $paramScriptBlock -Parameters @{ value = 5 } -Iterations 1
            
            # VÃ©rifier que les paramÃ¨tres sont passÃ©s correctement
            $paramResult.DetailedResults[0].Result | Should -Be 10
        }
        
        It "Retourne les statistiques correctes" {
            # ExÃ©cuter la fonction avec un scriptblock simple
            $result = Measure-Operation -Name "Test statistiques" -ScriptBlock { return 42 } -Iterations 3
            
            # VÃ©rifier que les statistiques sont calculÃ©es correctement
            $result.Name | Should -Be "Test statistiques"
            $result.SuccessRate | Should -Be 100
            $result.DetailedResults.Count | Should -Be 3
            $result.AverageTime | Should -BeGreaterThan 0
            
            # VÃ©rifier que les statistiques correspondent aux rÃ©sultats dÃ©taillÃ©s
            $avgTime = ($result.DetailedResults | Measure-Object -Property ExecutionTime -Average).Average
            $result.AverageTime | Should -Be $avgTime
        }
    }
    
    Context "New-TestFiles" {
        BeforeAll {
            # DÃ©finir la fonction Ã  tester (version simplifiÃ©e pour les tests)
            function New-TestFiles {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$OutputPath,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$SmallFiles = 2,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$MediumFiles = 1,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$LargeFiles = 0
                )
                
                $testFilesPath = Join-Path -Path $OutputPath -ChildPath "test_files"
                
                if (-not (Test-Path -Path $testFilesPath)) {
                    New-Item -Path $testFilesPath -ItemType Directory -Force | Out-Null
                }
                
                # CrÃ©er des fichiers de test simplifiÃ©s
                for ($i = 1; $i -le $SmallFiles; $i++) {
                    $filePath = Join-Path -Path $testFilesPath -ChildPath "small_$i.ps1"
                    "# Small test file $i" | Out-File -FilePath $filePath -Encoding utf8
                }
                
                for ($i = 1; $i -le $MediumFiles; $i++) {
                    $filePath = Join-Path -Path $testFilesPath -ChildPath "medium_$i.ps1"
                    "# Medium test file $i`n`nfunction Test-Function { param($i) }" | Out-File -FilePath $filePath -Encoding utf8
                }
                
                for ($i = 1; $i -le $LargeFiles; $i++) {
                    $filePath = Join-Path -Path $testFilesPath -ChildPath "large_$i.ps1"
                    "# Large test file $i`n`nfunction Test-Function { param($i) }`n`nclass TestClass {}" | Out-File -FilePath $filePath -Encoding utf8
                }
                
                return $testFilesPath
            }
            
            # CrÃ©er un rÃ©pertoire temporaire pour les tests
            $testOutputDir = Join-Path -Path $TestDrive -ChildPath "TestOutput"
        }
        
        It "CrÃ©e le rÃ©pertoire de sortie s'il n'existe pas" {
            # Appeler la fonction
            $result = New-TestFiles -OutputPath $testOutputDir
            
            # VÃ©rifier que le rÃ©pertoire a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $result -PathType Container | Should -Be $true
        }
        
        It "CrÃ©e le nombre correct de fichiers" {
            # Appeler la fonction avec des paramÃ¨tres spÃ©cifiques
            $smallFiles = 3
            $mediumFiles = 2
            $largeFiles = 1
            
            $result = New-TestFiles -OutputPath $testOutputDir -SmallFiles $smallFiles -MediumFiles $mediumFiles -LargeFiles $largeFiles
            
            # VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
            $createdFiles = Get-ChildItem -Path $result -File
            $createdFiles.Count | Should -Be ($smallFiles + $mediumFiles + $largeFiles)
            
            # VÃ©rifier le nombre de chaque type de fichier
            (Get-ChildItem -Path $result -Filter "small_*.ps1").Count | Should -Be $smallFiles
            (Get-ChildItem -Path $result -Filter "medium_*.ps1").Count | Should -Be $mediumFiles
            (Get-ChildItem -Path $result -Filter "large_*.ps1").Count | Should -Be $largeFiles
        }
        
        It "Retourne le chemin correct" {
            # Appeler la fonction
            $result = New-TestFiles -OutputPath $testOutputDir
            
            # VÃ©rifier que le chemin retournÃ© est correct
            $expectedPath = Join-Path -Path $testOutputDir -ChildPath "test_files"
            $result | Should -Be $expectedPath
        }
    }
    
    Context "GÃ©nÃ©ration de rapports HTML" {
        BeforeAll {
            # Fonction simplifiÃ©e pour gÃ©nÃ©rer un rapport HTML
            function New-BenchmarkReport {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$OutputPath,
                    
                    [Parameter(Mandatory = $true)]
                    [array]$Results
                )
                
                $reportPath = Join-Path -Path $OutputPath -ChildPath "benchmark_report.html"
                
                $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de benchmark</title>
</head>
<body>
    <h1>Rapport de benchmark</h1>
    <table>
        <tr>
            <th>ScÃ©nario</th>
            <th>Temps moyen (s)</th>
            <th>MÃ©moire moyenne (MB)</th>
            <th>Taux de succÃ¨s (%)</th>
        </tr>
"@
                
                foreach ($result in $Results) {
                    $htmlContent += @"
        <tr>
            <td>$($result.Name)</td>
            <td>$([Math]::Round($result.AverageTime, 2))</td>
            <td>$([Math]::Round($result.AverageMemoryMB, 2))</td>
            <td>$([Math]::Round($result.SuccessRate, 2))</td>
        </tr>
"@
                }
                
                $htmlContent += @"
    </table>
</body>
</html>
"@
                
                $htmlContent | Out-File -FilePath $reportPath -Encoding utf8
                
                return $reportPath
            }
            
            # CrÃ©er des donnÃ©es de test
            $testResults = @(
                [PSCustomObject]@{
                    Name = "Test 1"
                    AverageTime = 1.23
                    MinTime = 1.0
                    MaxTime = 1.5
                    AverageMemoryMB = 10.5
                    SuccessRate = 100
                    DetailedResults = @()
                },
                [PSCustomObject]@{
                    Name = "Test 2"
                    AverageTime = 2.34
                    MinTime = 2.0
                    MaxTime = 2.5
                    AverageMemoryMB = 20.5
                    SuccessRate = 66.7
                    DetailedResults = @()
                }
            )
            
            # CrÃ©er un rÃ©pertoire temporaire pour les tests
            $testOutputDir = Join-Path -Path $TestDrive -ChildPath "ReportOutput"
            New-Item -Path $testOutputDir -ItemType Directory -Force | Out-Null
        }
        
        It "GÃ©nÃ¨re un fichier HTML valide" {
            # GÃ©nÃ©rer un rapport
            $reportPath = New-BenchmarkReport -OutputPath $testOutputDir -Results $testResults
            
            # VÃ©rifier que le fichier a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $reportPath | Should -Be $true
            
            # VÃ©rifier que le contenu est du HTML valide
            $content = Get-Content -Path $reportPath -Raw
            $content | Should -Match "<!DOCTYPE html>"
            $content | Should -Match "<html>"
            $content | Should -Match "</html>"
        }
        
        It "Inclut toutes les donnÃ©es de performance" {
            # GÃ©nÃ©rer un rapport
            $reportPath = New-BenchmarkReport -OutputPath $testOutputDir -Results $testResults
            
            # VÃ©rifier que le contenu inclut toutes les donnÃ©es
            $content = Get-Content -Path $reportPath -Raw
            
            foreach ($result in $testResults) {
                $content | Should -Match $result.Name
                $content | Should -Match ([Math]::Round($result.AverageTime, 2))
                $content | Should -Match ([Math]::Round($result.AverageMemoryMB, 2))
                $content | Should -Match ([Math]::Round($result.SuccessRate, 2))
            }
        }
    }
}
