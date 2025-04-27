Describe "Tests des scÃ©narios parallÃ¨les" {
    Context "Comparaison sÃ©quentiel vs parallÃ¨le" {
        BeforeAll {
            # Fonction pour exÃ©cuter un traitement en mode sÃ©quentiel
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
            
            # Fonction pour exÃ©cuter un traitement en mode parallÃ¨le
            function Invoke-ParallelProcessing {
                param (
                    [Parameter(Mandatory = $true)]
                    [array]$Items,
                    
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ProcessItem,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$ThrottleLimit = 5
                )
                
                # VÃ©rifier si ForEach-Object -Parallel est disponible (PowerShell 7+)
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
                    
                    # CrÃ©er un pool de runspaces
                    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit)
                    $runspacePool.Open()
                    
                    $runspaces = @()
                    
                    # CrÃ©er et dÃ©marrer les runspaces
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
                    
                    # RÃ©cupÃ©rer les rÃ©sultats
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
            
            # CrÃ©er des donnÃ©es de test
            $testItems = 1..10
            
            # CrÃ©er un scriptblock de traitement
            $processItem = {
                param($item)
                Start-Sleep -Milliseconds ($item * 10)
                return $item * 2
            }
        }
        
        It "Le traitement parallÃ¨le est plus rapide que le traitement sÃ©quentiel" -Skip:($PSVersionTable.PSVersion.Major -lt 7 -and -not (Get-Command -Name ForEach-Object).Parameters.ContainsKey('Parallel')) {
            # Mesurer le temps d'exÃ©cution du traitement sÃ©quentiel
            $sequentialStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $sequentialResults = Invoke-SequentialProcessing -Items $testItems -ProcessItem $processItem
            $sequentialStopwatch.Stop()
            $sequentialTime = $sequentialStopwatch.Elapsed.TotalMilliseconds
            
            # Mesurer le temps d'exÃ©cution du traitement parallÃ¨le
            $parallelStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $parallelResults = Invoke-ParallelProcessing -Items $testItems -ProcessItem $processItem
            $parallelStopwatch.Stop()
            $parallelTime = $parallelStopwatch.Elapsed.TotalMilliseconds
            
            # VÃ©rifier que le traitement parallÃ¨le est plus rapide
            $parallelTime | Should -BeLessThan $sequentialTime
            
            # VÃ©rifier que les rÃ©sultats sont identiques (aprÃ¨s tri)
            $sortedSequentialResults = $sequentialResults | Sort-Object
            $sortedParallelResults = $parallelResults | Sort-Object
            $sortedSequentialResults | Should -Be $sortedParallelResults
        }
        
        It "Le traitement parallÃ¨le produit les mÃªmes rÃ©sultats que le traitement sÃ©quentiel" -Skip:($PSVersionTable.PSVersion.Major -lt 7 -and -not (Get-Command -Name ForEach-Object).Parameters.ContainsKey('Parallel')) {
            # ExÃ©cuter le traitement sÃ©quentiel
            $sequentialResults = Invoke-SequentialProcessing -Items $testItems -ProcessItem $processItem
            
            # ExÃ©cuter le traitement parallÃ¨le
            $parallelResults = Invoke-ParallelProcessing -Items $testItems -ProcessItem $processItem
            
            # VÃ©rifier que les rÃ©sultats sont identiques (aprÃ¨s tri)
            $sortedSequentialResults = $sequentialResults | Sort-Object
            $sortedParallelResults = $parallelResults | Sort-Object
            
            # VÃ©rifier que les deux ensembles de rÃ©sultats ont la mÃªme taille
            $sortedSequentialResults.Count | Should -Be $sortedParallelResults.Count
            
            # VÃ©rifier que chaque Ã©lÃ©ment est identique
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
                    # Retourner le rÃ©sultat du cache
                    return $Cache[$Key]
                }
                else {
                    # GÃ©nÃ©rer le rÃ©sultat
                    $result = & $Generator
                    
                    # Stocker le rÃ©sultat dans le cache
                    if ($UseCache) {
                        $Cache[$Key] = $result
                    }
                    
                    return $result
                }
            }
            
            # CrÃ©er un gÃ©nÃ©rateur qui prend du temps
            $slowGenerator = {
                Start-Sleep -Milliseconds 50
                return Get-Random
            }
            
            # CrÃ©er un cache partagÃ©
            $sharedCache = @{}
        }
        
        It "L'utilisation du cache amÃ©liore les performances" {
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
            
            # VÃ©rifier que l'utilisation du cache est plus rapide
            $withCacheTime | Should -BeLessThan $noCacheTime
            
            # VÃ©rifier que les rÃ©sultats du cache sont cohÃ©rents
            $withCacheResult1 | Should -Be $withCacheResult2
            
            # VÃ©rifier que les rÃ©sultats sans cache sont diffÃ©rents (car gÃ©nÃ©rÃ©s alÃ©atoirement)
            # Note: Il y a une trÃ¨s faible probabilitÃ© que les deux rÃ©sultats soient identiques par hasard
            if ($noCacheResult1 -eq $noCacheResult2) {
                Write-Warning "Les rÃ©sultats sans cache sont identiques par hasard. Cela peut arriver, mais c'est peu probable."
            }
        }
        
        It "Le cache stocke correctement les rÃ©sultats" {
            # Vider le cache
            $sharedCache.Clear()
            
            # GÃ©nÃ©rer un rÃ©sultat et le mettre en cache
            $key = "testKey"
            $result1 = Get-CachedResult -Key $key -Generator $slowGenerator -UseCache -Cache $sharedCache
            
            # VÃ©rifier que le rÃ©sultat est dans le cache
            $sharedCache.ContainsKey($key) | Should -Be $true
            $sharedCache[$key] | Should -Be $result1
            
            # RÃ©cupÃ©rer le rÃ©sultat du cache
            $result2 = Get-CachedResult -Key $key -Generator $slowGenerator -UseCache -Cache $sharedCache
            
            # VÃ©rifier que le rÃ©sultat est identique
            $result2 | Should -Be $result1
        }
    }
    
    Context "Gestion des ressources systÃ¨me" {
        BeforeAll {
            # Fonction pour surveiller l'utilisation des ressources
            function Measure-ResourceUsage {
                param (
                    [Parameter(Mandatory = $true)]
                    [scriptblock]$ScriptBlock,
                    
                    [Parameter(Mandatory = $false)]
                    [hashtable]$Parameters = @{}
                )
                
                # Mesurer l'utilisation de la mÃ©moire avant
                $process = Get-Process -Id $PID
                $startCpu = $process.TotalProcessorTime
                $startWS = $process.WorkingSet64
                $startPM = $process.PrivateMemorySize64
                
                # ExÃ©cuter le script
                $result = & $ScriptBlock @Parameters
                
                # Mesurer l'utilisation de la mÃ©moire aprÃ¨s
                $process = Get-Process -Id $PID
                $endCpu = $process.TotalProcessorTime
                $endWS = $process.WorkingSet64
                $endPM = $process.PrivateMemorySize64
                
                # Calculer les diffÃ©rences
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
            
            # CrÃ©er des scriptblocks de test
            $lowMemoryScript = { 
                # Script qui utilise peu de mÃ©moire
                $sum = 0
                for ($i = 0; $i -lt 1000; $i++) {
                    $sum += $i
                }
                return $sum
            }
            
            $highMemoryScript = { 
                # Script qui utilise beaucoup de mÃ©moire
                $array = @()
                for ($i = 0; $i -lt 100000; $i++) {
                    $array += "Item $i"
                }
                return $array.Count
            }
        }
        
        It "DÃ©tecte correctement l'utilisation de la mÃ©moire" {
            # Mesurer l'utilisation des ressources pour un script qui utilise peu de mÃ©moire
            $lowMemoryUsage = Measure-ResourceUsage -ScriptBlock $lowMemoryScript
            
            # Mesurer l'utilisation des ressources pour un script qui utilise beaucoup de mÃ©moire
            $highMemoryUsage = Measure-ResourceUsage -ScriptBlock $highMemoryScript
            
            # VÃ©rifier que l'utilisation de la mÃ©moire est dÃ©tectÃ©e correctement
            $highMemoryUsage.WorkingSetDiffMB | Should -BeGreaterThan $lowMemoryUsage.WorkingSetDiffMB
            $highMemoryUsage.PrivateMemoryDiffMB | Should -BeGreaterThan $lowMemoryUsage.PrivateMemoryDiffMB
        }
        
        It "Retourne le rÃ©sultat correct" {
            # Mesurer l'utilisation des ressources pour un script avec un rÃ©sultat connu
            $knownResultScript = { return 42 }
            $usage = Measure-ResourceUsage -ScriptBlock $knownResultScript
            
            # VÃ©rifier que le rÃ©sultat est correct
            $usage.Result | Should -Be 42
        }
        
        It "Accepte des paramÃ¨tres pour le scriptblock" {
            # CrÃ©er un scriptblock qui utilise des paramÃ¨tres
            $paramScript = { 
                param($value)
                return $value * 2
            }
            
            # Mesurer l'utilisation des ressources avec des paramÃ¨tres
            $usage = Measure-ResourceUsage -ScriptBlock $paramScript -Parameters @{ value = 5 }
            
            # VÃ©rifier que les paramÃ¨tres sont passÃ©s correctement
            $usage.Result | Should -Be 10
        }
    }
}
