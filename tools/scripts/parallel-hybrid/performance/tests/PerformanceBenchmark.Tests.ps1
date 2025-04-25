Describe "Tests de benchmark de performance" {
    Context "Comparaison des performances entre différentes implémentations" {
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
                
                # Exécuter des itérations de préchauffage pour éviter les biais de démarrage à froid
                for ($i = 1; $i -le $WarmupIterations; $i++) {
                    & $ScriptBlock @Parameters | Out-Null
                }
                
                $results = @()
                
                # Exécuter les itérations de mesure
                for ($i = 1; $i -le $Iterations; $i++) {
                    # Nettoyer la mémoire avant chaque test
                    [System.GC]::Collect()
                    
                    # Mesurer l'utilisation de la mémoire avant
                    $process = Get-Process -Id $PID
                    $startCpu = $process.TotalProcessorTime
                    $startWS = $process.WorkingSet64
                    $startPM = $process.PrivateMemorySize64
                    
                    # Mesurer le temps d'exécution
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    try {
                        # Exécuter la fonction
                        $result = & $ScriptBlock @Parameters
                        $success = $true
                    }
                    catch {
                        Write-Error "Erreur lors de l'exécution de '$Name' : $_"
                        $success = $false
                        $result = $null
                    }
                    
                    $stopwatch.Stop()
                    $executionTime = $stopwatch.Elapsed.TotalMilliseconds
                    
                    # Mesurer l'utilisation de la mémoire après
                    $process = Get-Process -Id $PID
                    $endCpu = $process.TotalProcessorTime
                    $endWS = $process.WorkingSet64
                    $endPM = $process.PrivateMemorySize64
                    
                    # Calculer les différences
                    $cpuTime = ($endCpu - $startCpu).TotalMilliseconds
                    $workingSetDiff = ($endWS - $startWS) / 1MB
                    $privateMemoryDiff = ($endPM - $startPM) / 1MB
                    
                    # Enregistrer les résultats
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
            
            # Fonction pour comparer les performances de deux implémentations
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
                
                # Mesurer les performances de la première implémentation
                $result1 = Measure-FunctionPerformance -Name "$Name (Implémentation 1)" -ScriptBlock $Implementation1 -Parameters $Parameters -Iterations $Iterations
                
                # Mesurer les performances de la seconde implémentation
                $result2 = Measure-FunctionPerformance -Name "$Name (Implémentation 2)" -ScriptBlock $Implementation2 -Parameters $Parameters -Iterations $Iterations
                
                # Calculer l'amélioration en pourcentage
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
            
            # Fonction pour générer un grand tableau de données
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
            
            # Fonction pour générer des fichiers de test
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
                    
                    # Générer une taille aléatoire entre MinSize et MaxSize
                    $fileSize = Get-Random -Minimum $MinSize -Maximum $MaxSize
                    
                    # Générer le contenu du fichier
                    $content = "A" * $fileSize
                    
                    # Créer le fichier
                    Set-Content -Path $filePath -Value $content | Out-Null
                    
                    $filePaths += $filePath
                }
                
                return $filePaths
            }
            
            # Créer un répertoire temporaire pour les tests
            $testRootDir = Join-Path -Path $TestDrive -ChildPath "PerformanceTests"
            New-Item -Path $testRootDir -ItemType Directory -Force | Out-Null
            
            # Générer des données de test
            $testData = New-LargeDataArray -Size 1000
            
            # Générer des fichiers de test
            $testFiles = New-TestFiles -OutputPath $testRootDir -FileCount 20 -MinSize 1KB -MaxSize 10KB
        }
        
        It "Compare les performances du tri avec différentes approches" {
            # Définir les implémentations à comparer
            $implementation1 = {
                param($data)
                # Tri simple
                return $data | Sort-Object -Property Value
            }
            
            $implementation2 = {
                param($data)
                # Tri optimisé avec sélection des propriétés
                return $data | Select-Object Id, Name, Value | Sort-Object -Property Value
            }
            
            # Comparer les implémentations
            $comparison = Compare-Implementations -Name "Tri de données" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 3
            
            # Vérifier que les deux implémentations produisent des résultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les résultats pour information
            Write-Host "Temps moyen (Implémentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (Implémentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "Amélioration du temps: $($comparison.TimeImprovementPercent) %"
            
            # Note: Nous ne faisons pas d'assertion sur l'amélioration car cela dépend de l'environnement d'exécution
            # et pourrait rendre les tests instables. Nous vérifions simplement que les deux implémentations fonctionnent.
        }
        
        It "Compare les performances du traitement de fichiers avec différentes approches" -Skip:($PSVersionTable.PSVersion.Major -lt 7 -and -not (Get-Command -Name ForEach-Object).Parameters.ContainsKey('Parallel')) {
            # Définir les implémentations à comparer
            $implementation1 = {
                param($files)
                # Traitement séquentiel
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
                # Traitement parallèle
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
            
            # Comparer les implémentations
            $comparison = Compare-Implementations -Name "Traitement de fichiers" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ files = $testFiles } -Iterations 3
            
            # Vérifier que les deux implémentations produisent des résultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les résultats pour information
            Write-Host "Temps moyen (Implémentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (Implémentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "Amélioration du temps: $($comparison.TimeImprovementPercent) %"
            
            # Vérifier que le traitement parallèle est plus rapide (au moins 10% d'amélioration)
            # Note: Cette assertion peut être instable selon l'environnement d'exécution
            # $comparison.TimeImprovementPercent | Should -BeGreaterThan 10
        }
        
        It "Compare les performances de la recherche avec différentes approches" {
            # Définir les implémentations à comparer
            $implementation1 = {
                param($data, $searchValue)
                # Recherche simple avec Where-Object
                return $data | Where-Object { $_.Value -gt $searchValue }
            }
            
            $implementation2 = {
                param($data, $searchValue)
                # Recherche optimisée avec .Where()
                return $data.Where({ $_.Value -gt $searchValue })
            }
            
            # Comparer les implémentations
            $comparison = Compare-Implementations -Name "Recherche de données" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData; searchValue = 500 } -Iterations 3
            
            # Vérifier que les deux implémentations produisent des résultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les résultats pour information
            Write-Host "Temps moyen (Implémentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (Implémentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "Amélioration du temps: $($comparison.TimeImprovementPercent) %"
        }
        
        It "Compare les performances de la conversion JSON avec différentes approches" {
            # Définir les implémentations à comparer
            $implementation1 = {
                param($data)
                # Conversion JSON simple
                return $data | ConvertTo-Json -Depth 3
            }
            
            $implementation2 = {
                param($data)
                # Conversion JSON avec sélection des propriétés essentielles
                return $data | Select-Object Id, Name, Value | ConvertTo-Json -Depth 3 -Compress
            }
            
            # Comparer les implémentations
            $comparison = Compare-Implementations -Name "Conversion JSON" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 3
            
            # Vérifier que les deux implémentations produisent des résultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les résultats pour information
            Write-Host "Temps moyen (Implémentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (Implémentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "Amélioration du temps: $($comparison.TimeImprovementPercent) %"
        }
        
        It "Compare les performances de l'agrégation de données avec différentes approches" {
            # Définir les implémentations à comparer
            $implementation1 = {
                param($data)
                # Agrégation avec Group-Object
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
                # Agrégation optimisée avec dictionnaire
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
            
            # Comparer les implémentations
            $comparison = Compare-Implementations -Name "Agrégation de données" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 3
            
            # Vérifier que les deux implémentations produisent des résultats valides
            $comparison.Result1.SuccessRate | Should -Be 100
            $comparison.Result2.SuccessRate | Should -Be 100
            
            # Afficher les résultats pour information
            Write-Host "Temps moyen (Implémentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (Implémentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "Amélioration du temps: $($comparison.TimeImprovementPercent) %"
        }
    }
    
    Context "Tests de charge avec différentes tailles de données" {
        BeforeAll {
            # Fonction pour mesurer les performances en fonction de la taille des données
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
                    # Générer les données de test
                    $data = New-LargeDataArray -Size $size
                    
                    # Mesurer les performances
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    for ($i = 1; $i -le $Iterations; $i++) {
                        & $ScriptBlock -data $data | Out-Null
                    }
                    
                    $stopwatch.Stop()
                    $executionTime = $stopwatch.Elapsed.TotalMilliseconds / $Iterations
                    
                    # Enregistrer les résultats
                    $results += [PSCustomObject]@{
                        Size = $size
                        ExecutionTimeMs = $executionTime
                        ItemsPerMs = $size / $executionTime
                    }
                }
                
                return $results
            }
            
            # Fonction pour générer un tableau de données de taille variable
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
            
            # Définir les tailles de données à tester
            $dataSizes = @(100, 1000, 10000)
            
            # Définir les fonctions à tester
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
        
        It "Mesure la scalabilité du tri" {
            # Mesurer les performances du tri avec différentes tailles de données
            $results = Measure-ScalabilityPerformance -Name "Tri" -ScriptBlock $sortFunction -DataSizes $dataSizes -Iterations 2
            
            # Afficher les résultats pour information
            Write-Host "Performances du tri :"
            foreach ($result in $results) {
                Write-Host "  Taille: $($result.Size) éléments, Temps: $($result.ExecutionTimeMs) ms, Débit: $($result.ItemsPerMs) éléments/ms"
            }
            
            # Vérifier que les performances se dégradent de manière prévisible
            # Le tri a une complexité O(n log n), donc le temps par élément devrait augmenter légèrement avec la taille des données
            $smallSizeItemsPerMs = $results[0].ItemsPerMs
            $largeSizeItemsPerMs = $results[-1].ItemsPerMs
            
            # Le débit (éléments/ms) devrait diminuer avec l'augmentation de la taille des données
            $largeSizeItemsPerMs | Should -BeLessThan $smallSizeItemsPerMs
        }
        
        It "Mesure la scalabilité du filtrage" {
            # Mesurer les performances du filtrage avec différentes tailles de données
            $results = Measure-ScalabilityPerformance -Name "Filtrage" -ScriptBlock $filterFunction -DataSizes $dataSizes -Iterations 2
            
            # Afficher les résultats pour information
            Write-Host "Performances du filtrage :"
            foreach ($result in $results) {
                Write-Host "  Taille: $($result.Size) éléments, Temps: $($result.ExecutionTimeMs) ms, Débit: $($result.ItemsPerMs) éléments/ms"
            }
            
            # Vérifier que les performances se dégradent de manière prévisible
            # Le filtrage a une complexité O(n), donc le temps par élément devrait rester relativement constant
            $smallSizeItemsPerMs = $results[0].ItemsPerMs
            $largeSizeItemsPerMs = $results[-1].ItemsPerMs
            
            # Le débit (éléments/ms) devrait rester relativement stable
            # Nous permettons une certaine dégradation due aux effets de cache et autres facteurs
            $largeSizeItemsPerMs | Should -BeGreaterThan ($smallSizeItemsPerMs * 0.5)
        }
        
        It "Mesure la scalabilité de l'agrégation" {
            # Mesurer les performances de l'agrégation avec différentes tailles de données
            $results = Measure-ScalabilityPerformance -Name "Agrégation" -ScriptBlock $aggregateFunction -DataSizes $dataSizes -Iterations 2
            
            # Afficher les résultats pour information
            Write-Host "Performances de l'agrégation :"
            foreach ($result in $results) {
                Write-Host "  Taille: $($result.Size) éléments, Temps: $($result.ExecutionTimeMs) ms, Débit: $($result.ItemsPerMs) éléments/ms"
            }
            
            # Vérifier que les performances se dégradent de manière prévisible
            # L'agrégation avec Group-Object a une complexité qui dépend de l'implémentation,
            # mais devrait être au moins O(n)
            $smallSizeItemsPerMs = $results[0].ItemsPerMs
            $largeSizeItemsPerMs = $results[-1].ItemsPerMs
            
            # Le débit (éléments/ms) devrait diminuer avec l'augmentation de la taille des données
            $largeSizeItemsPerMs | Should -BeLessThan $smallSizeItemsPerMs
        }
    }
}
