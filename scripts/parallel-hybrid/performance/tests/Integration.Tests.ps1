Describe "Tests d'intégration des scripts de performance" {
    Context "Interaction entre les fonctions" {
        BeforeAll {
            # Fonction pour créer un répertoire
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

            # Fonction pour générer des fichiers de test
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

                    # Générer une taille aléatoire entre MinSize et MaxSize
                    $fileSize = Get-Random -Minimum $MinSize -Maximum $MaxSize

                    # Générer le contenu du fichier
                    $content = "A" * $fileSize

                    # Créer le fichier
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

                        # Calculer les métriques
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

            # Aucune initialisation nécessaire pour ce contexte
        }

        It "Intègre correctement la création de répertoires et la génération de fichiers" {
            # Créer le répertoire de données
            $dataDir = New-DirectoryIfNotExists -Path $testDataDir -Purpose "Données de test" -Confirm:$false

            # Générer des fichiers de test
            $fileCount = 5
            $generatedFiles = New-TestFiles -OutputPath $dataDir -FileCount $fileCount

            # Vérifier que le répertoire a été créé
            Test-Path -Path $dataDir -PathType Container | Should -Be $true

            # Vérifier que les fichiers ont été générés
            $generatedFiles.Count | Should -Be $fileCount
            foreach ($file in $generatedFiles) {
                Test-Path -Path $file | Should -Be $true
            }
        }

        It "Intègre correctement la mesure de performances et le calcul de statistiques" {
            # Créer un script de test simple
            $testScript = {
                param($SleepTime)
                Start-Sleep -Seconds $SleepTime
            }

            # Mesurer les performances du script
            $results = Measure-ScriptPerformance -ScriptBlock $testScript -Parameters @{SleepTime = 1} -Iterations 3

            # Calculer les statistiques
            $stats = Get-PerformanceStatistics -Results $results

            # Vérifier que les résultats sont corrects
            $results.Count | Should -Be 3
            $results[0].Success | Should -Be $true
            $results[0].ExecutionTimeS | Should -BeGreaterThan 0.9
            $results[0].ExecutionTimeS | Should -BeLessThan 1.5

            # Vérifier que les statistiques sont correctes
            $stats.TotalIterations | Should -Be 3
            $stats.SuccessfulIterations | Should -Be 3
            $stats.SuccessRatePercent | Should -Be 100
            $stats.AverageExecutionTimeS | Should -BeGreaterThan 0.9
            $stats.AverageExecutionTimeS | Should -BeLessThan 1.5
        }

        It "Gère correctement les erreurs dans les scripts" {
            # Créer un script qui génère une erreur
            $errorScript = {
                throw "Erreur simulée pour les tests"
            }

            # Mesurer les performances du script
            $results = Measure-ScriptPerformance -ScriptBlock $errorScript -Iterations 2

            # Calculer les statistiques
            $stats = Get-PerformanceStatistics -Results $results

            # Vérifier que les résultats sont corrects
            $results.Count | Should -Be 2
            $results[0].Success | Should -Be $false
            $results[0].ErrorMessage | Should -Be "Erreur simulée pour les tests"

            # Vérifier que les statistiques sont correctes
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

                # 1. Créer le répertoire de sortie
                $outputDir = New-DirectoryIfNotExists -Path $OutputPath -Purpose "Résultats de performance" -Confirm:$false

                # 2. Mesurer les performances du script
                $results = Measure-ScriptPerformance -ScriptBlock $TestScript -Parameters $Parameters -Iterations $Iterations

                # 3. Calculer les statistiques
                $stats = Get-PerformanceStatistics -Results $results

                # 4. Enregistrer les résultats
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

            # Créer un répertoire de test pour les résultats du workflow
            $testOutputDir = Join-Path -Path $TestDrive -ChildPath "WorkflowOutput"
            # Cette variable est utilisée plus loin dans le test

            # Créer un script de test simple
            $testScript = {
                param($SleepTime)
                Start-Sleep -Seconds $SleepTime
            }
        }

        It "Exécute correctement le flux de travail complet" {
            # Définir les fonctions nécessaires dans ce contexte
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

                        # Calculer les métriques
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

            # Exécuter le flux de travail
            $workflow = Invoke-PerformanceWorkflow -OutputPath $testOutputDir -TestScript $testScript -Parameters @{SleepTime = 1} -Iterations 2

            # Vérifier que le répertoire de sortie a été créé
            Test-Path -Path $workflow.OutputDirectory -PathType Container | Should -Be $true

            # Vérifier que les fichiers de résultats ont été créés
            Test-Path -Path $workflow.ResultsPath | Should -Be $true
            Test-Path -Path $workflow.StatsPath | Should -Be $true

            # Vérifier que les résultats sont corrects
            $workflow.Results.Count | Should -Be 2
            $workflow.Results[0].Success | Should -Be $true
            $workflow.Results[0].ExecutionTimeS | Should -BeGreaterThan 0.9
            $workflow.Results[0].ExecutionTimeS | Should -BeLessThan 1.5

            # Vérifier que les statistiques sont correctes
            $workflow.Statistics.TotalIterations | Should -Be 2
            $workflow.Statistics.SuccessfulIterations | Should -Be 2
            $workflow.Statistics.SuccessRatePercent | Should -Be 100
            $workflow.Statistics.AverageExecutionTimeS | Should -BeGreaterThan 0.9
            $workflow.Statistics.AverageExecutionTimeS | Should -BeLessThan 1.5
        }
    }
}
