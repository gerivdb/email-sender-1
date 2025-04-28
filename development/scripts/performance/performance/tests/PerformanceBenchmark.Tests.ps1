Describe "Tests de benchmark de performance" {
    Context "Comparaison des performances entre diffÃ©rentes implÃ©mentations" {
        BeforeAll {
            # Fonction pour mesurer les performances d'une fonction
            function Measure-FunctionPerformance {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Name,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ScriptBlock,
                    
                    [Parameter(Mandatory = $false)]
                    [hashtable]$Parameters = @{},
                    
                    [Parameter(Mandatory = $false)]
                    [int]$Iterations = 5,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$WarmupIterations = 1
                )
                
                # ExÃ©cuter des itÃ©rations de prÃ©chauffage pour Ã©viter les biais de dÃ©marrage Ã  froid
                for ($i = 1; $i -le $WarmupIterations; $i++) {
                    & $ScriptBlock @Parameters | Out-Null
                }
                
                $results = @()
                
                # ExÃ©cuter les itÃ©rations de mesure
                for ($i = 1; $i -le $Iterations; $i++) {
                    # Nettoyer la mÃ©moire avant chaque test
                    [System.GC]::Collect()
                    
                    # Mesurer l'utilisation de la mÃ©moire avant
                    $process = Get-Process -Id $PID
                    $startCpu = $process.TotalProcessorTime
                    $startWS = $process.WorkingSet64
                    $startPM = $process.PrivateMemorySize64
                    
                    # Mesurer le temps d'exÃ©cution
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    try {
                        # ExÃ©cuter la fonction
                        $result = & $ScriptBlock @Parameters
                        $success = $true
                    }
                    catch {
                        Write-Error "Erreur lors de l'exÃ©cution de '$Name' : $_"
                        $success = $false
                        $result = $null
                    }
                    
                    $stopwatch.Stop()
                    $executionTime = $stopwatch.Elapsed.TotalMilliseconds
                    
                    # Mesurer l'utilisation de la mÃ©moire aprÃ¨s
                    $process = Get-Process -Id $PID
                    $endCpu = $process.TotalProcessorTime
                    $endWS = $process.WorkingSet64
                    $endPM = $process.PrivateMemorySize64
                    
                    # Calculer les diffÃ©rences
                    $cpuTime = ($endCpu - $startCpu).TotalMilliseconds
                    $workingSetDiff = ($endWS - $startWS) / 1MB
                    $privateMemoryDiff = ($endPM - $startPM) / 1MB
                    
                    # Enregistrer les rÃ©sultats
                    $results += [PSCustomObject]@{
                        Iteration = $i
                        ExecutionTimeMs = $executionTime
                        CpuTimeMs = $cpuTime
                        WorkingSetDiffMB = $workingSetDiff
                        PrivateMemoryDiffMB = $privateMemoryDiff
                        Success = $success
                    }
                }
                
                # Calculer les statistiques
                $avgExecutionTime = ($results | Measure-Object -Property ExecutionTimeMs -Average).Average
                $minExecutionTime = ($results | Measure-Object -Property ExecutionTimeMs -Minimum).Minimum
                $maxExecutionTime = ($results | Measure-Object -Property ExecutionTimeMs -Maximum).Maximum
                $stdDevExecutionTime = [Math]::Sqrt(($results | ForEach-Object { [Math]::Pow($_.ExecutionTimeMs - $avgExecutionTime, 2) } | Measure-Object -Average).Average)
                
                $avgCpuTime = ($results | Measure-Object -Property CpuTimeMs -Average).Average
                $avgWorkingSetDiff = ($results | Measure-Object -Property WorkingSetDiffMB -Average).Average
                $avgPrivateMemoryDiff = ($results | Measure-Object -Property PrivateMemoryDiffMB -Average).Average
                $successRate = ($results | Where-Object { $_.Success } | Measure-Object).Count / $Iterations * 100
                
                return [PSCustomObject]@{
                    Name = $Name
                    AverageExecutionTimeMs = $avgExecutionTime
                    MinExecutionTimeMs = $minExecutionTime
                    MaxExecutionTimeMs = $maxExecutionTime
                    StdDevExecutionTimeMs = $stdDevExecutionTime
                    AverageCpuTimeMs = $avgCpuTime
                    AverageWorkingSetDiffMB = $avgWorkingSetDiff
                    AveragePrivateMemoryDiffMB = $avgPrivateMemoryDiff
                    SuccessRate = $successRate
                    DetailedResults = $results
                }
            }
            
            # Fonction pour comparer les performances de deux implÃ©mentations
            function Compare-Implementations {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Name,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$Implementation1,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$Implementation2,
                    
                    [Parameter(Mandatory = $false)]
                    [hashtable]$Parameters = @{},
                    
                    [Parameter(Mandatory = $false)]
                    [int]$Iterations = 5
                )
                
                # Mesurer les performances de la premiÃ¨re implÃ©mentation
                $result1 = Measure-FunctionPerformance -Name "$Name (ImplÃ©mentation 1)" -ScriptBlock $Implementation1 -Parameters $Parameters -Iterations $Iterations
                
                # Mesurer les performances de la seconde implÃ©mentation
                $result2 = Measure-FunctionPerformance -Name "$Name (ImplÃ©mentation 2)" -ScriptBlock $Implementation2 -Parameters $Parameters -Iterations $Iterations
                
                # Calculer l'amÃ©lioration en pourcentage
                $timeImprovement = ($result1.AverageExecutionTimeMs - $result2.AverageExecutionTimeMs) / $result1.AverageExecutionTimeMs * 100
                $memoryImprovement = ($result1.AverageWorkingSetDiffMB - $result2.AverageWorkingSetDiffMB) / $result1.AverageWorkingSetDiffMB * 100
                
                return [PSCustomObject]@{
                    Name = $Name
                    Result1 = $result1
                    Result2 = $result2
                    TimeImprovementPercent = $timeImprovement
                    MemoryImprovementPercent = $memoryImprovement
                }
            }
            
            # Fonction pour gÃ©nÃ©rer un grand tableau de donnÃ©es
            function New-LargeDataArray {
                param (
                    [Parameter(Mandatory = $false)]
                    [int]$Size = 10000
                )
                
                $data = @()
                
                for ($i = 1; $i -le $Size; $i++) {
                    $data += [PSCustomObject]@{
                        Id = $i
                        Name = "Item $i"
                        Value = Get-Random -Minimum 1 -Maximum 1000
                        Date = (Get-Date).AddDays(-$i)
                        Category = "Category " + ($i % 5 + 1)
                        IsActive = ($i % 2 -eq 0)
                    }
                }
                
                return $data
            }
            
            # Fonction pour gÃ©nÃ©rer des fichiers de test
            function New-TestFiles {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$OutputPath,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$FileCount = 100,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$MinSize = 1KB,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$MaxSize = 10KB
                )
                
                if (-not (Test-Path -Path $OutputPath -PathType Container)) {
                    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                }
                
                $filePaths = @()
                
                for ($i = 1; $i -le $FileCount; $i++) {
                    $fileName = "test_file_$i.txt"
                    $filePath = Join-Path -Path $OutputPath -ChildPath $fileName
                    
                    # GÃ©nÃ©rer une taille alÃ©atoire entre MinSize et MaxSize
                    $fileSize = Get-Random -Minimum $MinSize -Maximum $MaxSize
                    
                    # GÃ©nÃ©rer le contenu du fichier
                    $content = "A" * $fileSize
                    
                    # CrÃ©er le fichier
                    Set-Content -Path $filePath -Value $content | Out-Null
                    
                    $filePaths += $filePath
                }
                
                return $filePaths
            }
            
            # CrÃ©er un rÃ©pertoire temporaire pour les tests
            $testRootDir = Join-Path -Path $TestDrive -ChildPath "PerformanceTests"
            New-Item -Path $testRootDir -ItemType Directory -Force | Out-Null
            
            # GÃ©nÃ©rer des donnÃ©es de test
            $testData = New-LargeDataArray -Size 1000
            
            # GÃ©nÃ©rer des fichiers de test
            $testFiles = New-TestFiles -OutputPath $testRootDir -FileCount 20 -MinSize 1KB -MaxSize 10KB
        }
        
        It "Compare les performances du tri avec diffÃ©rentes approches" {
            # DÃ©finir les implÃ©mentations Ã  comparer
            $implementation1 = {
                param($data)
                # Tri simple
                return $data | Sort-Object -Property Value
            }
            
            $implementation2 = {
                param($data)
                # Tri optimisÃ© avec sÃ©lection des propriÃ©tÃ©s
                return $data | Select-Object Id, Name, Value | Sort-Object -Property Value
            }
            
            # Comparer les implÃ©mentations
            $comparison = Compare-Implementations -Name "Tri de donnÃ©es" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 3
            
            # VÃ©rifier que les deux implÃ©mentations produisent des rÃ©sultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les rÃ©sultats pour information
            Write-Host "Temps moyen (ImplÃ©mentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (ImplÃ©mentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "AmÃ©lioration du temps: $($comparison.TimeImprovementPercent) %"
            
            # Note: Nous ne faisons pas d'assertion sur l'amÃ©lioration car cela dÃ©pend de l'environnement d'exÃ©cution
            # et pourrait rendre les tests instables. Nous vÃ©rifions simplement que les deux implÃ©mentations fonctionnent.
        }
        
        It "Compare les performances du traitement de fichiers avec diffÃ©rentes approches" -Skip:($PSVersionTable.PSVersion.Major -lt 7 -and -not (Get-Command -Name ForEach-Object).Parameters.ContainsKey('Parallel')) {
            # DÃ©finir les implÃ©mentations Ã  comparer
            $implementation1 = {
                param($files)
                # Traitement sÃ©quentiel
                $results = @()
                foreach ($file in $files) {
                    $content = Get-Content -Path $file -Raw
                    $size = (Get-Item -Path $file).Length
                    $results += [PSCustomObject]@{
                        File = $file
                        Size = $size
                        Lines = ($content -split "`n").Count
                    }
                }
                return $results
            }
            
            $implementation2 = {
                param($files)
                # Traitement parallÃ¨le
                $results = $files | ForEach-Object -Parallel {
                    $file = $_
                    $content = Get-Content -Path $file -Raw
                    $size = (Get-Item -Path $file).Length
                    [PSCustomObject]@{
                        File = $file
                        Size = $size
                        Lines = ($content -split "`n").Count
                    }
                } -ThrottleLimit 5
                return $results
            }
            
            # Comparer les implÃ©mentations
            $comparison = Compare-Implementations -Name "Traitement de fichiers" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ files = $testFiles } -Iterations 3
            
            # VÃ©rifier que les deux implÃ©mentations produisent des rÃ©sultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les rÃ©sultats pour information
            Write-Host "Temps moyen (ImplÃ©mentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (ImplÃ©mentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "AmÃ©lioration du temps: $($comparison.TimeImprovementPercent) %"
            
            # VÃ©rifier que le traitement parallÃ¨le est plus rapide (au moins 10% d'amÃ©lioration)
            # Note: Cette assertion peut Ãªtre instable selon l'environnement d'exÃ©cution
            # $comparison.TimeImprovementPercent | Should -BeGreaterThan 10
        }
        
        It "Compare les performances de la recherche avec diffÃ©rentes approches" {
            # DÃ©finir les implÃ©mentations Ã  comparer
            $implementation1 = {
                param($data, $searchValue)
                # Recherche simple avec Where-Object
                return $data | Where-Object { $_.Value -gt $searchValue }
            }
            
            $implementation2 = {
                param($data, $searchValue)
                # Recherche optimisÃ©e avec .Where()
                return $data.Where({ $_.Value -gt $searchValue })
            }
            
            # Comparer les implÃ©mentations
            $comparison = Compare-Implementations -Name "Recherche de donnÃ©es" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData; searchValue = 500 } -Iterations 3
            
            # VÃ©rifier que les deux implÃ©mentations produisent des rÃ©sultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les rÃ©sultats pour information
            Write-Host "Temps moyen (ImplÃ©mentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (ImplÃ©mentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "AmÃ©lioration du temps: $($comparison.TimeImprovementPercent) %"
        }
        
        It "Compare les performances de la conversion JSON avec diffÃ©rentes approches" {
            # DÃ©finir les implÃ©mentations Ã  comparer
            $implementation1 = {
                param($data)
                # Conversion JSON simple
                return $data | ConvertTo-Json -Depth 3
            }
            
            $implementation2 = {
                param($data)
                # Conversion JSON avec sÃ©lection des propriÃ©tÃ©s essentielles
                return $data | Select-Object Id, Name, Value | ConvertTo-Json -Depth 3 -Compress
            }
            
            # Comparer les implÃ©mentations
            $comparison = Compare-Implementations -Name "Conversion JSON" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 3
            
            # VÃ©rifier que les deux implÃ©mentations produisent des rÃ©sultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les rÃ©sultats pour information
            Write-Host "Temps moyen (ImplÃ©mentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (ImplÃ©mentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "AmÃ©lioration du temps: $($comparison.TimeImprovementPercent) %"
        }
        
        It "Compare les performances de l'agrÃ©gation de donnÃ©es avec diffÃ©rentes approches" {
            # DÃ©finir les implÃ©mentations Ã  comparer
            $implementation1 = {
                param($data)
                # AgrÃ©gation avec Group-Object
                return $data | Group-Object -Property Category | ForEach-Object {
                    [PSCustomObject]@{
                        Category = $_.Name
                        Count = $_.Count
                        AverageValue = ($_.Group | Measure-Object -Property Value -Average).Average
                    }
                }
            }
            
            $implementation2 = {
                param($data)
                # AgrÃ©gation optimisÃ©e avec dictionnaire
                $categories = @{}
                
                foreach ($item in $data) {
                    $category = $item.Category
                    
                    if (-not $categories.ContainsKey($category)) {
                        $categories[$category] = @{
                            Count = 0
                            TotalValue = 0
                        }
                    }
                    
                    $categories[$category].Count++
                    $categories[$category].TotalValue += $item.Value
                }
                
                $results = @()
                
                foreach ($category in $categories.Keys) {
                    $results += [PSCustomObject]@{
                        Category = $category
                        Count = $categories[$category].Count
                        AverageValue = $categories[$category].TotalValue / $categories[$category].Count
                    }
                }
                
                return $results
            }
            
            # Comparer les implÃ©mentations
            $comparison = Compare-Implementations -Name "AgrÃ©gation de donnÃ©es" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 3
            
            # VÃ©rifier que les deux implÃ©mentations produisent des rÃ©sultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les rÃ©sultats pour information
            Write-Host "Temps moyen (ImplÃ©mentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (ImplÃ©mentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "AmÃ©lioration du temps: $($comparison.TimeImprovementPercent) %"
        }
    }
    
    Context "Tests de charge avec diffÃ©rentes tailles de donnÃ©es" {
        BeforeAll {
            # Fonction pour mesurer les performances en fonction de la taille des donnÃ©es
            function Measure-ScalabilityPerformance {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Name,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ScriptBlock,
                    
                    [Parameter(Mandatory = $true)]
                    [int[]]$DataSizes,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$Iterations = 3
                )
                
                $results = @()
                
                foreach ($size in $DataSizes) {
                    # GÃ©nÃ©rer les donnÃ©es de test
                    $data = New-LargeDataArray -Size $size
                    
                    # Mesurer les performances
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    for ($i = 1; $i -le $Iterations; $i++) {
                        & $ScriptBlock -data $data | Out-Null
                    }
                    
                    $stopwatch.Stop()
                    $executionTime = $stopwatch.Elapsed.TotalMilliseconds / $Iterations
                    
                    # Enregistrer les rÃ©sultats
                    $results += [PSCustomObject]@{
                        Size = $size
                        ExecutionTimeMs = $executionTime
                        ItemsPerMs = $size / $executionTime
                    }
                }
                
                return $results
            }
            
            # Fonction pour gÃ©nÃ©rer un tableau de donnÃ©es de taille variable
            function New-LargeDataArray {
                param (
                    [Parameter(Mandatory = $false)]
                    [int]$Size = 10000
                )
                
                $data = @()
                
                for ($i = 1; $i -le $Size; $i++) {
                    $data += [PSCustomObject]@{
                        Id = $i
                        Name = "Item $i"
                        Value = Get-Random -Minimum 1 -Maximum 1000
                        Date = (Get-Date).AddDays(-$i)
                        Category = "Category " + ($i % 5 + 1)
                        IsActive = ($i % 2 -eq 0)
                    }
                }
                
                return $data
            }
            
            # DÃ©finir les tailles de donnÃ©es Ã  tester
            $dataSizes = @(100, 1000, 10000)
            
            # DÃ©finir les fonctions Ã  tester
            $sortFunction = {
                param($data)
                return $data | Sort-Object -Property Value
            }
            
            $filterFunction = {
                param($data)
                return $data | Where-Object { $_.Value -gt 500 }
            }
            
            $aggregateFunction = {
                param($data)
                return $data | Group-Object -Property Category | ForEach-Object {
                    [PSCustomObject]@{
                        Category = $_.Name
                        Count = $_.Count
                        AverageValue = ($_.Group | Measure-Object -Property Value -Average).Average
                    }
                }
            }
        }
        
        It "Mesure la scalabilitÃ© du tri" {
            # Mesurer les performances du tri avec diffÃ©rentes tailles de donnÃ©es
            $results = Measure-ScalabilityPerformance -Name "Tri" -ScriptBlock $sortFunction -DataSizes $dataSizes -Iterations 2
            
            # Afficher les rÃ©sultats pour information
            Write-Host "Performances du tri :"
            foreach ($result in $results) {
                Write-Host "  Taille: $($result.Size) Ã©lÃ©ments, Temps: $($result.ExecutionTimeMs) ms, DÃ©bit: $($result.ItemsPerMs) Ã©lÃ©ments/ms"
            }
            
            # VÃ©rifier que les performances se dÃ©gradent de maniÃ¨re prÃ©visible
            # Le tri a une complexitÃ© O(n log n), donc le temps par Ã©lÃ©ment devrait augmenter lÃ©gÃ¨rement avec la taille des donnÃ©es
            $smallSizeItemsPerMs = $results[0].ItemsPerMs
            $largeSizeItemsPerMs = $results[-1].ItemsPerMs
            
            # Le dÃ©bit (Ã©lÃ©ments/ms) devrait diminuer avec l'augmentation de la taille des donnÃ©es
            $largeSizeItemsPerMs | Should -BeLessThan $smallSizeItemsPerMs
        }
        
        It "Mesure la scalabilitÃ© du filtrage" {
            # Mesurer les performances du filtrage avec diffÃ©rentes tailles de donnÃ©es
            $results = Measure-ScalabilityPerformance -Name "Filtrage" -ScriptBlock $filterFunction -DataSizes $dataSizes -Iterations 2
            
            # Afficher les rÃ©sultats pour information
            Write-Host "Performances du filtrage :"
            foreach ($result in $results) {
                Write-Host "  Taille: $($result.Size) Ã©lÃ©ments, Temps: $($result.ExecutionTimeMs) ms, DÃ©bit: $($result.ItemsPerMs) Ã©lÃ©ments/ms"
            }
            
            # VÃ©rifier que les performances se dÃ©gradent de maniÃ¨re prÃ©visible
            # Le filtrage a une complexitÃ© O(n), donc le temps par Ã©lÃ©ment devrait rester relativement constant
            $smallSizeItemsPerMs = $results[0].ItemsPerMs
            $largeSizeItemsPerMs = $results[-1].ItemsPerMs
            
            # Le dÃ©bit (Ã©lÃ©ments/ms) devrait rester relativement stable
            # Nous permettons une certaine dÃ©gradation due aux effets de cache et autres facteurs
            $largeSizeItemsPerMs | Should -BeGreaterThan ($smallSizeItemsPerMs * 0.5)
        }
        
        It "Mesure la scalabilitÃ© de l'agrÃ©gation" {
            # Mesurer les performances de l'agrÃ©gation avec diffÃ©rentes tailles de donnÃ©es
            $results = Measure-ScalabilityPerformance -Name "AgrÃ©gation" -ScriptBlock $aggregateFunction -DataSizes $dataSizes -Iterations 2
            
            # Afficher les rÃ©sultats pour information
            Write-Host "Performances de l'agrÃ©gation :"
            foreach ($result in $results) {
                Write-Host "  Taille: $($result.Size) Ã©lÃ©ments, Temps: $($result.ExecutionTimeMs) ms, DÃ©bit: $($result.ItemsPerMs) Ã©lÃ©ments/ms"
            }
            
            # VÃ©rifier que les performances se dÃ©gradent de maniÃ¨re prÃ©visible
            # L'agrÃ©gation avec Group-Object a une complexitÃ© qui dÃ©pend de l'implÃ©mentation,
            # mais devrait Ãªtre au moins O(n)
            $smallSizeItemsPerMs = $results[0].ItemsPerMs
            $largeSizeItemsPerMs = $results[-1].ItemsPerMs
            
            # Le dÃ©bit (Ã©lÃ©ments/ms) devrait diminuer avec l'augmentation de la taille des donnÃ©es
            $largeSizeItemsPerMs | Should -BeLessThan $smallSizeItemsPerMs
        }
    }
}
