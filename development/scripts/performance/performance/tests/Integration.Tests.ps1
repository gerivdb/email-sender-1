Describe "Tests d'intÃ©gration des scripts de performance" {
    Context "Interaction entre les fonctions" {
        BeforeAll {
            # Fonction pour crÃ©er un rÃ©pertoire
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

            # Fonction pour gÃ©nÃ©rer des fichiers de test
            function New-TestFiles {
                param (
                    [string]$OutputPath,
                    [int]$FileCount = 10,
                    [int]$MinSize = 1KB,
                    [int]$MaxSize = 10KB
                )

                if (-not (Test-Path -Path $OutputPath -PathType Container)) {
                    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                }

                $generatedFiles = @()

                for ($i = 1; $i -le $FileCount; $i++) {
                    $fileName = "test_file_$i.txt"
                    $filePath = Join-Path -Path $OutputPath -ChildPath $fileName

                    # GÃ©nÃ©rer une taille alÃ©atoire entre MinSize et MaxSize
                    $fileSize = Get-Random -Minimum $MinSize -Maximum $MaxSize

                    # GÃ©nÃ©rer le contenu du fichier
                    $content = "A" * $fileSize

                    # CrÃ©er le fichier
                    Set-Content -Path $filePath -Value $content | Out-Null

                    $generatedFiles += $filePath
                }

                return $generatedFiles
            }

            # Fonction pour mesurer les performances d'un script
            function Measure-ScriptPerformance {
                param (
                    [scriptblock]$ScriptBlock,
                    [hashtable]$Parameters = @{},
                    [int]$Iterations = 3
                )

                $results = @()

                for ($i = 1; $i -le $Iterations; $i++) {
                    $result = [PSCustomObject]@{
                        Iteration = $i
                        ExecutionTimeS = $null
                        ProcessorTimeS = $null
                        WorkingSetMB = $null
                        PrivateMemoryMB = $null
                        Success = $false
                        ErrorMessage = $null
                    }

                    try {
                        # Mesurer les performances
                        $process = Get-Process -Id $PID
                        $startCpu = $process.TotalProcessorTime
                        $startWS = $process.WorkingSet64
                        $startPM = $process.PrivateMemorySize64

                        $startTime = Get-Date
                        & $ScriptBlock @Parameters
                        $endTime = Get-Date

                        $process = Get-Process -Id $PID
                        $endCpu = $process.TotalProcessorTime
                        $endWS = $process.WorkingSet64
                        $endPM = $process.PrivateMemorySize64

                        # Calculer les mÃ©triques
                        $result.ExecutionTimeS = ($endTime - $startTime).TotalSeconds
                        $result.ProcessorTimeS = ($endCpu - $startCpu).TotalSeconds
                        $result.WorkingSetMB = [Math]::Round(($endWS - $startWS) / 1MB, 2)
                        $result.PrivateMemoryMB = [Math]::Round(($endPM - $startPM) / 1MB, 2)
                        $result.Success = $true
                    }
                    catch {
                        $result.ErrorMessage = $_.Exception.Message
                    }

                    $results += $result
                }

                return $results
            }

            # Fonction pour calculer des statistiques
            function Get-PerformanceStatistics {
                param (
                    [array]$Results
                )

                $successfulResults = $Results | Where-Object { $_.Success }
                $totalCount = $Results.Count
                $successCount = $successfulResults.Count

                if ($totalCount -eq 0) {
                    return $null
                }

                $stats = [PSCustomObject]@{
                    TotalIterations = $totalCount
                    SuccessfulIterations = $successCount
                    SuccessRatePercent = [Math]::Round(($successCount / $totalCount) * 100, 1)
                    AverageExecutionTimeS = 0
                    AverageProcessorTimeS = 0
                    AverageWorkingSetMB = 0
                    AveragePrivateMemoryMB = 0
                }

                if ($successCount -gt 0) {
                    $stats.AverageExecutionTimeS = [Math]::Round(($successfulResults | Measure-Object -Property ExecutionTimeS -Average).Average, 3)
                    $stats.AverageProcessorTimeS = [Math]::Round(($successfulResults | Measure-Object -Property ProcessorTimeS -Average).Average, 3)
                    $stats.AverageWorkingSetMB = [Math]::Round(($successfulResults | Measure-Object -Property WorkingSetMB -Average).Average, 2)
                    $stats.AveragePrivateMemoryMB = [Math]::Round(($successfulResults | Measure-Object -Property PrivateMemoryMB -Average).Average, 2)
                }

                return $stats
            }

            # Initialisation du rÃ©pertoire de test
            $testDataDir = Join-Path -Path $TestDrive -ChildPath "TestData"
        }

        It "IntÃ¨gre correctement la crÃ©ation de rÃ©pertoires et la gÃ©nÃ©ration de fichiers" {
            # CrÃ©er le rÃ©pertoire de donnÃ©es
            $dataDir = New-DirectoryIfNotExists -Path $testDataDir -Purpose "DonnÃ©es de test" -Confirm:$false

            # GÃ©nÃ©rer des fichiers de test
            $fileCount = 5
            $generatedFiles = New-TestFiles -OutputPath $dataDir -FileCount $fileCount

            # VÃ©rifier que le rÃ©pertoire a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $dataDir -PathType Container | Should -Be $true

            # VÃ©rifier que les fichiers ont Ã©tÃ© gÃ©nÃ©rÃ©s
            $generatedFiles.Count | Should -Be $fileCount
            foreach ($file in $generatedFiles) {
                Test-Path -Path $file | Should -Be $true
            }
        }

        It "IntÃ¨gre correctement la mesure de performances et le calcul de statistiques" {
            # CrÃ©er un script de test simple
            $testScript = {
                param($SleepTime)
                Start-Sleep -Seconds $SleepTime
            }

            # Mesurer les performances du script
            $results = Measure-ScriptPerformance -ScriptBlock $testScript -Parameters @{SleepTime = 1} -Iterations 3

            # Calculer les statistiques
            $stats = Get-PerformanceStatistics -Results $results

            # VÃ©rifier que les rÃ©sultats sont corrects
            $results.Count | Should -Be 3
            $results[0].Success | Should -Be $true
            $results[0].ExecutionTimeS | Should -BeGreaterThan 0.9
            $results[0].ExecutionTimeS | Should -BeLessThan 1.5

            # VÃ©rifier que les statistiques sont correctes
            $stats.TotalIterations | Should -Be 3
            $stats.SuccessfulIterations | Should -Be 3
            $stats.SuccessRatePercent | Should -Be 100
            $stats.AverageExecutionTimeS | Should -BeGreaterThan 0.9
            $stats.AverageExecutionTimeS | Should -BeLessThan 1.5
        }

        It "GÃ¨re correctement les erreurs dans les scripts" {
            # CrÃ©er un script qui gÃ©nÃ¨re une erreur
            $errorScript = {
                throw "Erreur simulÃ©e pour les tests"
            }

            # Mesurer les performances du script
            $results = Measure-ScriptPerformance -ScriptBlock $errorScript -Iterations 2

            # Calculer les statistiques
            $stats = Get-PerformanceStatistics -Results $results

            # VÃ©rifier que les rÃ©sultats sont corrects
            $results.Count | Should -Be 2
            $results[0].Success | Should -Be $false
            $results[0].ErrorMessage | Should -Be "Erreur simulÃ©e pour les tests"

            # VÃ©rifier que les statistiques sont correctes
            $stats.TotalIterations | Should -Be 2
            $stats.SuccessfulIterations | Should -Be 0
            $stats.SuccessRatePercent | Should -Be 0
        }
    }

    Context "Flux de travail complet" {
        BeforeAll {
            # Fonction pour simuler un flux de travail complet
            function Invoke-PerformanceWorkflow {
                param (
                    [string]$OutputPath,
                    [scriptblock]$TestScript,
                    [hashtable]$Parameters = @{},
                    [int]$Iterations = 3
                )

                # 1. CrÃ©er le rÃ©pertoire de sortie
                $outputDir = New-DirectoryIfNotExists -Path $OutputPath -Purpose "RÃ©sultats de performance" -Confirm:$false

                # 2. Mesurer les performances du script
                $results = Measure-ScriptPerformance -ScriptBlock $TestScript -Parameters $Parameters -Iterations $Iterations

                # 3. Calculer les statistiques
                $stats = Get-PerformanceStatistics -Results $results

                # 4. Enregistrer les rÃ©sultats
                $resultsPath = Join-Path -Path $outputDir -ChildPath "results.json"
                $statsPath = Join-Path -Path $outputDir -ChildPath "stats.json"

                $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Encoding UTF8 -Force
                $stats | ConvertTo-Json -Depth 5 | Out-File -FilePath $statsPath -Encoding UTF8 -Force

                return [PSCustomObject]@{
                    OutputDirectory = $outputDir
                    Results = $results
                    Statistics = $stats
                    ResultsPath = $resultsPath
                    StatsPath = $statsPath
                }
            }

            # CrÃ©er un rÃ©pertoire de test pour les rÃ©sultats du workflow
            $testOutputDir = Join-Path -Path $TestDrive -ChildPath "WorkflowOutput"
            # Cette variable est utilisÃ©e plus loin dans le test

            # CrÃ©er un script de test simple
            $testScript = {
                param($SleepTime)
                Start-Sleep -Seconds $SleepTime
            }
        }

        It "ExÃ©cute correctement le flux de travail complet" {
            # DÃ©finir les fonctions nÃ©cessaires dans ce contexte
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

            function Measure-ScriptPerformance {
                param (
                    [scriptblock]$ScriptBlock,
                    [hashtable]$Parameters = @{},
                    [int]$Iterations = 3
                )

                $results = @()

                for ($i = 1; $i -le $Iterations; $i++) {
                    $result = [PSCustomObject]@{
                        Iteration = $i
                        ExecutionTimeS = $null
                        ProcessorTimeS = $null
                        WorkingSetMB = $null
                        PrivateMemoryMB = $null
                        Success = $false
                        ErrorMessage = $null
                    }

                    try {
                        # Mesurer les performances
                        $process = Get-Process -Id $PID
                        $startCpu = $process.TotalProcessorTime
                        $startWS = $process.WorkingSet64
                        $startPM = $process.PrivateMemorySize64

                        $startTime = Get-Date
                        & $ScriptBlock @Parameters
                        $endTime = Get-Date

                        $process = Get-Process -Id $PID
                        $endCpu = $process.TotalProcessorTime
                        $endWS = $process.WorkingSet64
                        $endPM = $process.PrivateMemorySize64

                        # Calculer les mÃ©triques
                        $result.ExecutionTimeS = ($endTime - $startTime).TotalSeconds
                        $result.ProcessorTimeS = ($endCpu - $startCpu).TotalSeconds
                        $result.WorkingSetMB = [Math]::Round(($endWS - $startWS) / 1MB, 2)
                        $result.PrivateMemoryMB = [Math]::Round(($endPM - $startPM) / 1MB, 2)
                        $result.Success = $true
                    }
                    catch {
                        $result.ErrorMessage = $_.Exception.Message
                    }

                    $results += $result
                }

                return $results
            }

            function Get-PerformanceStatistics {
                param (
                    [array]$Results
                )

                $successfulResults = $Results | Where-Object { $_.Success }
                $totalCount = $Results.Count
                $successCount = $successfulResults.Count

                if ($totalCount -eq 0) {
                    return $null
                }

                $stats = [PSCustomObject]@{
                    TotalIterations = $totalCount
                    SuccessfulIterations = $successCount
                    SuccessRatePercent = [Math]::Round(($successCount / $totalCount) * 100, 1)
                    AverageExecutionTimeS = 0
                    AverageProcessorTimeS = 0
                    AverageWorkingSetMB = 0
                    AveragePrivateMemoryMB = 0
                }

                if ($successCount -gt 0) {
                    $stats.AverageExecutionTimeS = [Math]::Round(($successfulResults | Measure-Object -Property ExecutionTimeS -Average).Average, 3)
                    $stats.AverageProcessorTimeS = [Math]::Round(($successfulResults | Measure-Object -Property ProcessorTimeS -Average).Average, 3)
                    $stats.AverageWorkingSetMB = [Math]::Round(($successfulResults | Measure-Object -Property WorkingSetMB -Average).Average, 2)
                    $stats.AveragePrivateMemoryMB = [Math]::Round(($successfulResults | Measure-Object -Property PrivateMemoryMB -Average).Average, 2)
                }

                return $stats
            }

            # ExÃ©cuter le flux de travail
            $workflow = Invoke-PerformanceWorkflow -OutputPath $testOutputDir -TestScript $testScript -Parameters @{SleepTime = 1} -Iterations 2

            # VÃ©rifier que le rÃ©pertoire de sortie a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $workflow.OutputDirectory -PathType Container | Should -Be $true

            # VÃ©rifier que les fichiers de rÃ©sultats ont Ã©tÃ© crÃ©Ã©s
            Test-Path -Path $workflow.ResultsPath | Should -Be $true
            Test-Path -Path $workflow.StatsPath | Should -Be $true

            # VÃ©rifier que les rÃ©sultats sont corrects
            $workflow.Results.Count | Should -Be 2
            $workflow.Results[0].Success | Should -Be $true
            $workflow.Results[0].ExecutionTimeS | Should -BeGreaterThan 0.9
            $workflow.Results[0].ExecutionTimeS | Should -BeLessThan 1.5

            # VÃ©rifier que les statistiques sont correctes
            $workflow.Statistics.TotalIterations | Should -Be 2
            $workflow.Statistics.SuccessfulIterations | Should -Be 2
            $workflow.Statistics.SuccessRatePercent | Should -Be 100
            $workflow.Statistics.AverageExecutionTimeS | Should -BeGreaterThan 0.9
            $workflow.Statistics.AverageExecutionTimeS | Should -BeLessThan 1.5
        }
    }
}
