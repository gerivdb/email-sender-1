Describe "Tests des scénarios parallèles" {
    Context "Comparaison séquentiel vs parallèle" {
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
            
            # Fonction pour exécuter un traitement en mode parallèle
            function Invoke-ParallelProcessing {
                param (
                    [Parameter(Mandatory = $true)]
                    [array]$Items,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ProcessItem,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$ThrottleLimit = 5
                )
                
                # Vérifier si ForEach-Object -Parallel est disponible (PowerShell 7+)
                $psVersion = $PSVersionTable.PSVersion
                $supportsParallel = $psVersion.Major -ge 7
                
                if ($supportsParallel) {
                    # Utiliser ForEach-Object -Parallel pour PowerShell 7+
                    $results = $Items | ForEach-Object -Parallel {
                        $item = $_
                        $ProcessItem = $using:ProcessItem
                        & $ProcessItem $item
                    } -ThrottleLimit $ThrottleLimit
                }
                else {
                    # Utiliser les runspaces pour PowerShell 5.1
                    $results = @()
                    
                    # Créer un pool de runspaces
                    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit)
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
                }
                
                return $results
            }
            
            # Créer des données de test
            $testItems = 1..10
            
            # Créer un scriptblock de traitement
            $processItem = {
                param($item)
                Start-Sleep -Milliseconds ($item * 10)
                return $item * 2
            }
        }
        
        It "Le traitement parallèle est plus rapide que le traitement séquentiel" -Skip:($PSVersionTable.PSVersion.Major -lt 7 -and -not (Get-Command -Name ForEach-Object).Parameters.ContainsKey('Parallel')) {
            # Mesurer le temps d'exécution du traitement séquentiel
            $sequentialStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $sequentialResults = Invoke-SequentialProcessing -Items $testItems -ProcessItem $processItem
            $sequentialStopwatch.Stop()
            $sequentialTime = $sequentialStopwatch.Elapsed.TotalMilliseconds
            
            # Mesurer le temps d'exécution du traitement parallèle
            $parallelStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $parallelResults = Invoke-ParallelProcessing -Items $testItems -ProcessItem $processItem
            $parallelStopwatch.Stop()
            $parallelTime = $parallelStopwatch.Elapsed.TotalMilliseconds
            
            # Vérifier que le traitement parallèle est plus rapide
            $parallelTime | Should -BeLessThan $sequentialTime
            
            # Vérifier que les résultats sont identiques (après tri)
            $sortedSequentialResults = $sequentialResults | Sort-Object
            $sortedParallelResults = $parallelResults | Sort-Object
            $sortedSequentialResults | Should -Be $sortedParallelResults
        }
        
        It "Le traitement parallèle produit les mêmes résultats que le traitement séquentiel" -Skip:($PSVersionTable.PSVersion.Major -lt 7 -and -not (Get-Command -Name ForEach-Object).Parameters.ContainsKey('Parallel')) {
            # Exécuter le traitement séquentiel
            $sequentialResults = Invoke-SequentialProcessing -Items $testItems -ProcessItem $processItem
            
            # Exécuter le traitement parallèle
            $parallelResults = Invoke-ParallelProcessing -Items $testItems -ProcessItem $processItem
            
            # Vérifier que les résultats sont identiques (après tri)
            $sortedSequentialResults = $sequentialResults | Sort-Object
            $sortedParallelResults = $parallelResults | Sort-Object
            
            # Vérifier que les deux ensembles de résultats ont la même taille
            $sortedSequentialResults.Count | Should -Be $sortedParallelResults.Count
            
            # Vérifier que chaque élément est identique
            for ($i = 0; $i -lt $sortedSequentialResults.Count; $i++) {
                $sortedSequentialResults[$i] | Should -Be $sortedParallelResults[$i]
            }
        }
    }
    
    Context "Utilisation du cache" {
        BeforeAll {
            # Fonction pour simuler un cache
            function Get-CachedResult {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$Key,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$Generator,
                    
                    [Parameter(Mandatory = $false)]
                    [switch]$UseCache = $true,
                    
                    [Parameter(Mandatory = $false)]
                    [hashtable]$Cache = @{}
                )
                
                if ($UseCache -and $Cache.ContainsKey($Key)) {
                    # Retourner le résultat du cache
                    return $Cache[$Key]
                }
                else {
                    # Générer le résultat
                    $result = & $Generator
                    
                    # Stocker le résultat dans le cache
                    if ($UseCache) {
                        $Cache[$Key] = $result
                    }
                    
                    return $result
                }
            }
            
            # Créer un générateur qui prend du temps
            $slowGenerator = {
                Start-Sleep -Milliseconds 50
                return Get-Random
            }
            
            # Créer un cache partagé
            $sharedCache = @{}
        }
        
        It "L'utilisation du cache améliore les performances" {
            # Mesurer le temps sans cache
            $noCacheStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $noCacheResult1 = Get-CachedResult -Key "test" -Generator $slowGenerator -UseCache:$false -Cache $sharedCache
            $noCacheResult2 = Get-CachedResult -Key "test" -Generator $slowGenerator -UseCache:$false -Cache $sharedCache
            $noCacheStopwatch.Stop()
            $noCacheTime = $noCacheStopwatch.Elapsed.TotalMilliseconds
            
            # Mesurer le temps avec cache
            $withCacheStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $withCacheResult1 = Get-CachedResult -Key "test2" -Generator $slowGenerator -UseCache -Cache $sharedCache
            $withCacheResult2 = Get-CachedResult -Key "test2" -Generator $slowGenerator -UseCache -Cache $sharedCache
            $withCacheStopwatch.Stop()
            $withCacheTime = $withCacheStopwatch.Elapsed.TotalMilliseconds
            
            # Vérifier que l'utilisation du cache est plus rapide
            $withCacheTime | Should -BeLessThan $noCacheTime
            
            # Vérifier que les résultats du cache sont cohérents
            $withCacheResult1 | Should -Be $withCacheResult2
            
            # Vérifier que les résultats sans cache sont différents (car générés aléatoirement)
            # Note: Il y a une très faible probabilité que les deux résultats soient identiques par hasard
            if ($noCacheResult1 -eq $noCacheResult2) {
                Write-Warning "Les résultats sans cache sont identiques par hasard. Cela peut arriver, mais c'est peu probable."
            }
        }
        
        It "Le cache stocke correctement les résultats" {
            # Vider le cache
            $sharedCache.Clear()
            
            # Générer un résultat et le mettre en cache
            $key = "testKey"
            $result1 = Get-CachedResult -Key $key -Generator $slowGenerator -UseCache -Cache $sharedCache
            
            # Vérifier que le résultat est dans le cache
            $sharedCache.ContainsKey($key) | Should -Be $true
            $sharedCache[$key] | Should -Be $result1
            
            # Récupérer le résultat du cache
            $result2 = Get-CachedResult -Key $key -Generator $slowGenerator -UseCache -Cache $sharedCache
            
            # Vérifier que le résultat est identique
            $result2 | Should -Be $result1
        }
    }
    
    Context "Gestion des ressources système" {
        BeforeAll {
            # Fonction pour surveiller l'utilisation des ressources
            function Measure-ResourceUsage {
                param (
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ScriptBlock,
                    
                    [Parameter(Mandatory = $false)]
                    [hashtable]$Parameters = @{}
                )
                
                # Mesurer l'utilisation de la mémoire avant
                $process = Get-Process -Id $PID
                $startCpu = $process.TotalProcessorTime
                $startWS = $process.WorkingSet64
                $startPM = $process.PrivateMemorySize64
                
                # Exécuter le script
                $result = & $ScriptBlock @Parameters
                
                # Mesurer l'utilisation de la mémoire après
                $process = Get-Process -Id $PID
                $endCpu = $process.TotalProcessorTime
                $endWS = $process.WorkingSet64
                $endPM = $process.PrivateMemorySize64
                
                # Calculer les différences
                $cpuTime = ($endCpu - $startCpu).TotalSeconds
                $workingSetDiff = ($endWS - $startWS) / 1MB
                $privateMemoryDiff = ($endPM - $startPM) / 1MB
                
                return [PSCustomObject]@{
                    Result = $result
                    CpuTimeS = $cpuTime
                    WorkingSetDiffMB = $workingSetDiff
                    PrivateMemoryDiffMB = $privateMemoryDiff
                }
            }
            
            # Créer des scriptblocks de test
            $lowMemoryScript = { 
                # Script qui utilise peu de mémoire
                $sum = 0
                for ($i = 0; $i -lt 1000; $i++) {
                    $sum += $i
                }
                return $sum
            }
            
            $highMemoryScript = { 
                # Script qui utilise beaucoup de mémoire
                $array = @()
                for ($i = 0; $i -lt 100000; $i++) {
                    $array += "Item $i"
                }
                return $array.Count
            }
        }
        
        It "Détecte correctement l'utilisation de la mémoire" {
            # Mesurer l'utilisation des ressources pour un script qui utilise peu de mémoire
            $lowMemoryUsage = Measure-ResourceUsage -ScriptBlock $lowMemoryScript
            
            # Mesurer l'utilisation des ressources pour un script qui utilise beaucoup de mémoire
            $highMemoryUsage = Measure-ResourceUsage -ScriptBlock $highMemoryScript
            
            # Vérifier que l'utilisation de la mémoire est détectée correctement
            $highMemoryUsage.WorkingSetDiffMB | Should -BeGreaterThan $lowMemoryUsage.WorkingSetDiffMB
            $highMemoryUsage.PrivateMemoryDiffMB | Should -BeGreaterThan $lowMemoryUsage.PrivateMemoryDiffMB
        }
        
        It "Retourne le résultat correct" {
            # Mesurer l'utilisation des ressources pour un script avec un résultat connu
            $knownResultScript = { return 42 }
            $usage = Measure-ResourceUsage -ScriptBlock $knownResultScript
            
            # Vérifier que le résultat est correct
            $usage.Result | Should -Be 42
        }
        
        It "Accepte des paramètres pour le scriptblock" {
            # Créer un scriptblock qui utilise des paramètres
            $paramScript = { 
                param($value)
                return $value * 2
            }
            
            # Mesurer l'utilisation des ressources avec des paramètres
            $usage = Measure-ResourceUsage -ScriptBlock $paramScript -Parameters @{ value = 5 }
            
            # Vérifier que les paramètres sont passés correctement
            $usage.Result | Should -Be 10
        }
    }
}
