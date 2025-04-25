Describe "Tests de parallélisme avec Runspaces pour PowerShell 5.1" {
    Context "Traitement parallèle avec Runspaces" {
        BeforeAll {
            # Fonction pour exécuter un traitement en mode séquentiel
            function Invoke-SequentialProcessing {
                param (
                    [Parameter(Mandatory = $true)]
                    [array]$Items,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ProcessItem
                )
                
                $results = @()
                
                foreach ($item in $Items) {
                    $result = & $ProcessItem $item
                    $results += $result
                }
                
                return $results
            }
            
            # Fonction pour exécuter un traitement en mode parallèle avec Runspaces
            function Invoke-RunspaceParallelProcessing {
                param (
                    [Parameter(Mandatory = $true)]
                    [array]$Items,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ProcessItem,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$ThrottleLimit = 5
                )
                
                $results = @()
                
                # Créer un pool de runspaces
                $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
                $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit, $sessionState, $Host)
                $runspacePool.Open()
                
                $runspaces = @()
                
                # Créer et démarrer les runspaces
                foreach ($item in $Items) {
                    $powershell = [powershell]::Create().AddScript({
                        param($item, $scriptBlock)
                        & $scriptBlock $item
                    }).AddArgument($item).AddArgument($ProcessItem)
                    
                    $powershell.RunspacePool = $runspacePool
                    
                    $runspaces += [PSCustomObject]@{
                        Powershell = $powershell
                        AsyncResult = $powershell.BeginInvoke()
                        Item = $item
                    }
                }
                
                # Récupérer les résultats
                foreach ($runspace in $runspaces) {
                    $result = $runspace.Powershell.EndInvoke($runspace.AsyncResult)
                    $results += $result
                    $runspace.Powershell.Dispose()
                }
                
                # Fermer le pool de runspaces
                $runspacePool.Close()
                $runspacePool.Dispose()
                
                return $results
            }
            
            # Créer des données de test
            $testItems = 1..20
            
            # Créer un scriptblock de traitement
            $processItem = {
                param($item)
                Start-Sleep -Milliseconds ($item * 10)
                return $item * 2
            }
        }
        
        It "Le traitement parallèle avec Runspaces est plus rapide que le traitement séquentiel" {
            # Mesurer le temps d'exécution du traitement séquentiel
            $sequentialStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $sequentialResults = Invoke-SequentialProcessing -Items $testItems -ProcessItem $processItem
            $sequentialStopwatch.Stop()
            $sequentialTime = $sequentialStopwatch.Elapsed.TotalMilliseconds
            
            # Mesurer le temps d'exécution du traitement parallèle
            $parallelStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $parallelResults = Invoke-RunspaceParallelProcessing -Items $testItems -ProcessItem $processItem
            $parallelStopwatch.Stop()
            $parallelTime = $parallelStopwatch.Elapsed.TotalMilliseconds
            
            # Afficher les résultats
            Write-Host "Temps séquentiel : $sequentialTime ms"
            Write-Host "Temps parallèle : $parallelTime ms"
            Write-Host "Amélioration : $(($sequentialTime - $parallelTime) / $sequentialTime * 100)%"
            
            # Vérifier que le traitement parallèle est plus rapide
            $parallelTime | Should -BeLessThan $sequentialTime
            
            # Vérifier que les résultats sont identiques (après tri)
            $sortedSequentialResults = $sequentialResults | Sort-Object
            $sortedParallelResults = $parallelResults | Sort-Object
            $sortedSequentialResults | Should -Be $sortedParallelResults
        }
        
        It "Le traitement parallèle avec Runspaces gère correctement les erreurs" {
            # Créer un scriptblock qui génère des erreurs pour certains éléments
            $errorProcessItem = {
                param($item)
                if ($item % 3 -eq 0) {
                    throw "Erreur pour l'élément $item"
                }
                return $item * 2
            }
            
            # Fonction pour exécuter un traitement en mode parallèle avec gestion des erreurs
            function Invoke-RunspaceParallelProcessingWithErrorHandling {
                param (
                    [Parameter(Mandatory = $true)]
                    [array]$Items,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ProcessItem,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$ThrottleLimit = 5
                )
                
                $results = @()
                
                # Créer un pool de runspaces
                $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
                $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit, $sessionState, $Host)
                $runspacePool.Open()
                
                $runspaces = @()
                
                # Créer et démarrer les runspaces
                foreach ($item in $Items) {
                    $powershell = [powershell]::Create().AddScript({
                        param($item, $scriptBlock)
                        try {
                            $result = & $scriptBlock $item
                            return [PSCustomObject]@{
                                Item = $item
                                Result = $result
                                Success = $true
                                ErrorMessage = $null
                            }
                        }
                        catch {
                            return [PSCustomObject]@{
                                Item = $item
                                Result = $null
                                Success = $false
                                ErrorMessage = $_.Exception.Message
                            }
                        }
                    }).AddArgument($item).AddArgument($ProcessItem)
                    
                    $powershell.RunspacePool = $runspacePool
                    
                    $runspaces += [PSCustomObject]@{
                        Powershell = $powershell
                        AsyncResult = $powershell.BeginInvoke()
                        Item = $item
                    }
                }
                
                # Récupérer les résultats
                foreach ($runspace in $runspaces) {
                    $result = $runspace.Powershell.EndInvoke($runspace.AsyncResult)
                    $results += $result
                    $runspace.Powershell.Dispose()
                }
                
                # Fermer le pool de runspaces
                $runspacePool.Close()
                $runspacePool.Dispose()
                
                return $results
            }
            
            # Exécuter le traitement parallèle avec gestion des erreurs
            $results = Invoke-RunspaceParallelProcessingWithErrorHandling -Items $testItems -ProcessItem $errorProcessItem
            
            # Vérifier que les résultats sont corrects
            $results.Count | Should -Be $testItems.Count
            
            # Vérifier que les erreurs sont correctement gérées
            $successfulResults = $results | Where-Object { $_.Success }
            $failedResults = $results | Where-Object { -not $_.Success }
            
            $successfulResults.Count | Should -Be ($testItems.Count - [Math]::Floor($testItems.Count / 3))
            $failedResults.Count | Should -Be [Math]::Floor($testItems.Count / 3)
            
            # Vérifier que les éléments qui ont échoué sont bien ceux divisibles par 3
            foreach ($failedResult in $failedResults) {
                $failedResult.Item % 3 | Should -Be 0
                $failedResult.ErrorMessage | Should -Match "Erreur pour l'élément $($failedResult.Item)"
            }
        }
        
        It "Le traitement parallèle avec Runspaces peut être configuré avec différentes limites de parallélisme" {
            # Fonction pour mesurer les performances avec différentes limites de parallélisme
            function Measure-ParallelPerformance {
                param (
                    [Parameter(Mandatory = $true)]
                    [array]$Items,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ProcessItem,
                    
                    [Parameter(Mandatory = $true)]
                    [int[]]$ThrottleLimits
                )
                
                $results = @()
                
                foreach ($throttleLimit in $ThrottleLimits) {
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    $parallelResults = Invoke-RunspaceParallelProcessing -Items $Items -ProcessItem $ProcessItem -ThrottleLimit $throttleLimit
                    $stopwatch.Stop()
                    $executionTime = $stopwatch.Elapsed.TotalMilliseconds
                    
                    $results += [PSCustomObject]@{
                        ThrottleLimit = $throttleLimit
                        ExecutionTimeMs = $executionTime
                        ItemsPerMs = $Items.Count / $executionTime
                    }
                }
                
                return $results
            }
            
            # Mesurer les performances avec différentes limites de parallélisme
            $throttleLimits = @(1, 2, 5, 10)
            $performanceResults = Measure-ParallelPerformance -Items $testItems -ProcessItem $processItem -ThrottleLimits $throttleLimits
            
            # Afficher les résultats
            Write-Host "Performances avec différentes limites de parallélisme :"
            foreach ($result in $performanceResults) {
                Write-Host "  Limite: $($result.ThrottleLimit), Temps: $($result.ExecutionTimeMs) ms, Débit: $($result.ItemsPerMs) éléments/ms"
            }
            
            # Vérifier que les performances s'améliorent avec l'augmentation de la limite de parallélisme
            # (jusqu'à un certain point)
            $singleThreadPerformance = $performanceResults[0].ExecutionTimeMs
            $multiThreadPerformance = ($performanceResults | Where-Object { $_.ThrottleLimit -gt 1 } | Measure-Object -Property ExecutionTimeMs -Minimum).Minimum
            
            $multiThreadPerformance | Should -BeLessThan $singleThreadPerformance
        }
    }
    
    Context "Traitement de fichiers en parallèle avec Runspaces" {
        BeforeAll {
            # Fonction pour créer des fichiers de test
            function New-TestFiles {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$OutputPath,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$FileCount = 10,
                    
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
            
            # Fonction pour traiter des fichiers en mode séquentiel
            function Invoke-SequentialFileProcessing {
                param (
                    [Parameter(Mandatory = $true)]
                    [array]$FilePaths
                )
                
                $results = @()
                
                foreach ($filePath in $FilePaths) {
                    $content = Get-Content -Path $filePath -Raw
                    $size = (Get-Item -Path $filePath).Length
                    $results += [PSCustomObject]@{
                        FilePath = $filePath
                        Size = $size
                        Lines = ($content -split "`n").Count
                    }
                }
                
                return $results
            }
            
            # Fonction pour traiter des fichiers en mode parallèle avec Runspaces
            function Invoke-RunspaceParallelFileProcessing {
                param (
                    [Parameter(Mandatory = $true)]
                    [array]$FilePaths,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$ThrottleLimit = 5
                )
                
                $results = @()
                
                # Créer un pool de runspaces
                $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
                $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit, $sessionState, $Host)
                $runspacePool.Open()
                
                $runspaces = @()
                
                # Créer et démarrer les runspaces
                foreach ($filePath in $FilePaths) {
                    $powershell = [powershell]::Create().AddScript({
                        param($filePath)
                        $content = Get-Content -Path $filePath -Raw
                        $size = (Get-Item -Path $filePath).Length
                        return [PSCustomObject]@{
                            FilePath = $filePath
                            Size = $size
                            Lines = ($content -split "`n").Count
                        }
                    }).AddArgument($filePath)
                    
                    $powershell.RunspacePool = $runspacePool
                    
                    $runspaces += [PSCustomObject]@{
                        Powershell = $powershell
                        AsyncResult = $powershell.BeginInvoke()
                        FilePath = $filePath
                    }
                }
                
                # Récupérer les résultats
                foreach ($runspace in $runspaces) {
                    $result = $runspace.Powershell.EndInvoke($runspace.AsyncResult)
                    $results += $result
                    $runspace.Powershell.Dispose()
                }
                
                # Fermer le pool de runspaces
                $runspacePool.Close()
                $runspacePool.Dispose()
                
                return $results
            }
            
            # Créer un répertoire temporaire pour les tests
            $testDir = Join-Path -Path $TestDrive -ChildPath "FileProcessingTests"
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
            
            # Créer des fichiers de test
            $testFiles = New-TestFiles -OutputPath $testDir -FileCount 20
        }
        
        It "Le traitement de fichiers en parallèle avec Runspaces est plus rapide que le traitement séquentiel" {
            # Mesurer le temps d'exécution du traitement séquentiel
            $sequentialStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $sequentialResults = Invoke-SequentialFileProcessing -FilePaths $testFiles
            $sequentialStopwatch.Stop()
            $sequentialTime = $sequentialStopwatch.Elapsed.TotalMilliseconds
            
            # Mesurer le temps d'exécution du traitement parallèle
            $parallelStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $parallelResults = Invoke-RunspaceParallelFileProcessing -FilePaths $testFiles
            $parallelStopwatch.Stop()
            $parallelTime = $parallelStopwatch.Elapsed.TotalMilliseconds
            
            # Afficher les résultats
            Write-Host "Temps séquentiel : $sequentialTime ms"
            Write-Host "Temps parallèle : $parallelTime ms"
            Write-Host "Amélioration : $(($sequentialTime - $parallelTime) / $sequentialTime * 100)%"
            
            # Vérifier que le traitement parallèle est plus rapide
            $parallelTime | Should -BeLessThan $sequentialTime
            
            # Vérifier que les résultats sont identiques (après tri par chemin de fichier)
            $sortedSequentialResults = $sequentialResults | Sort-Object -Property FilePath
            $sortedParallelResults = $parallelResults | Sort-Object -Property FilePath
            
            $sortedSequentialResults.Count | Should -Be $sortedParallelResults.Count
            
            for ($i = 0; $i -lt $sortedSequentialResults.Count; $i++) {
                $sortedSequentialResults[$i].FilePath | Should -Be $sortedParallelResults[$i].FilePath
                $sortedSequentialResults[$i].Size | Should -Be $sortedParallelResults[$i].Size
                $sortedSequentialResults[$i].Lines | Should -Be $sortedParallelResults[$i].Lines
            }
        }
    }
}
