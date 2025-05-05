#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les optimisations de traitement parallÃ¨le.
.DESCRIPTION
    Ce script contient les tests unitaires pour les fonctions de traitement parallÃ¨le,
    vÃ©rifiant les diffÃ©rentes mÃ©thodes de parallÃ©lisation.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-11
#>

BeforeAll {
    # Importer les scripts Ã  tester
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\performance\Optimize-ParallelExecution.ps1"
    . $scriptPath
}

Describe "Invoke-SequentialProcessing" {
    Context "Lorsqu'on exÃ©cute un traitement sÃ©quentiel" {
        It "Devrait traiter tous les Ã©lÃ©ments" {
            $data = 1..10
            $scriptBlock = {
                param($item)
                return $item * 2
            }
            
            $result = Invoke-SequentialProcessing -Data $data -ScriptBlock $scriptBlock
            
            $result.Results.Count | Should -Be 10
            $result.Results | Should -Contain 2
            $result.Results | Should -Contain 20
            $result.ItemsProcessed | Should -Be 10
        }
        
        It "Devrait mesurer le temps d'exÃ©cution" {
            $data = 1..5
            $scriptBlock = {
                param($item)
                Start-Sleep -Milliseconds 100
                return $item
            }
            
            $result = Invoke-SequentialProcessing -Data $data -ScriptBlock $scriptBlock
            
            $result.ExecutionTime.TotalMilliseconds | Should -BeGreaterThan 400  # Au moins 5 * 100ms
        }
    }
}

Describe "Invoke-RunspacePoolProcessing" {
    Context "Lorsqu'on exÃ©cute un traitement parallÃ¨le avec Runspace Pools" {
        It "Devrait traiter tous les Ã©lÃ©ments" {
            $data = 1..10
            $scriptBlock = {
                param($item)
                return $item * 2
            }
            
            $result = Invoke-RunspacePoolProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
            
            $result.Results.Count | Should -Be 10
            $result.Results | Should -Contain 2
            $result.Results | Should -Contain 20
            $result.ItemsProcessed | Should -Be 10
            $result.MaxThreads | Should -Be 4
        }
        
        It "Devrait Ãªtre plus rapide que le traitement sÃ©quentiel pour les tÃ¢ches longues" {
            $data = 1..8
            $scriptBlock = {
                param($item)
                Start-Sleep -Milliseconds 100
                return $item
            }
            
            $sequentialResult = Invoke-SequentialProcessing -Data $data -ScriptBlock $scriptBlock
            $parallelResult = Invoke-RunspacePoolProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
            
            $parallelResult.ExecutionTime.TotalMilliseconds | Should -BeLessThan $sequentialResult.ExecutionTime.TotalMilliseconds
        }
        
        It "Devrait utiliser le nombre de threads spÃ©cifiÃ©" {
            $data = 1..10
            $scriptBlock = {
                param($item)
                return $item
            }
            
            $result = Invoke-RunspacePoolProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 2
            $result.MaxThreads | Should -Be 2
        }
    }
}

Describe "Invoke-BatchParallelProcessing" {
    Context "Lorsqu'on exÃ©cute un traitement parallÃ¨le par lots" {
        It "Devrait traiter tous les Ã©lÃ©ments" {
            $data = 1..10
            $scriptBlock = {
                param($item)
                return $item * 2
            }
            
            $result = Invoke-BatchParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -ChunkSize 3
            
            $result.Results.Count | Should -Be 10
            $result.Results | Should -Contain 2
            $result.Results | Should -Contain 20
            $result.ItemsProcessed | Should -Be 10
            $result.MaxThreads | Should -Be 4
            $result.ChunkSize | Should -Be 3
            $result.BatchCount | Should -Be 4  # 10 Ã©lÃ©ments divisÃ©s en lots de 3 = 4 lots
        }
        
        It "Devrait Ãªtre efficace pour les tÃ¢ches avec surcharge de dÃ©marrage" {
            $data = 1..20
            $scriptBlock = {
                param($item)
                # Simuler une surcharge de dÃ©marrage
                Start-Sleep -Milliseconds 50
                return $item
            }
            
            $runspaceResult = Invoke-RunspacePoolProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
            $batchResult = Invoke-BatchParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -ChunkSize 5
            
            # Le traitement par lots devrait Ãªtre plus efficace car il rÃ©duit la surcharge de dÃ©marrage
            $batchResult.ExecutionTime.TotalMilliseconds | Should -BeLessThan $runspaceResult.ExecutionTime.TotalMilliseconds
        }
        
        It "Devrait calculer automatiquement la taille des lots si non spÃ©cifiÃ©e" {
            $data = 1..10
            $scriptBlock = {
                param($item)
                return $item
            }
            
            $result = Invoke-BatchParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -ChunkSize 0
            
            $result.ChunkSize | Should -BeGreaterThan 0
        }
    }
}

# Tester ForEach-Object -Parallel uniquement si PowerShell 7+ est disponible
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Describe "Invoke-ForEachParallelProcessing" {
        Context "Lorsqu'on exÃ©cute un traitement parallÃ¨le avec ForEach-Object -Parallel" {
            It "Devrait traiter tous les Ã©lÃ©ments" {
                $data = 1..10
                $scriptBlock = {
                    param($item)
                    return $item * 2
                }
                
                $result = Invoke-ForEachParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
                
                $result.Results.Count | Should -Be 10
                $result.Results | Should -Contain 2
                $result.Results | Should -Contain 20
                $result.ItemsProcessed | Should -Be 10
                $result.MaxThreads | Should -Be 4
            }
        }
    }
}

Describe "Optimize-ParallelExecution" {
    Context "Lorsqu'on optimise l'exÃ©cution parallÃ¨le" {
        BeforeAll {
            # CrÃ©er une fonction de test
            function Test-Function {
                param($item)
                Start-Sleep -Milliseconds 10
                return $item * 2
            }
        }
        
        It "Devrait comparer les diffÃ©rentes mÃ©thodes de parallÃ©lisation" {
            $data = 1..20
            $result = Optimize-ParallelExecution -Data $data -ScriptBlock ${function:Test-Function} -MaxThreads 4 -ChunkSize 5 -Measure
            
            $result.FastestMethod | Should -Not -BeNullOrEmpty
            $result.FastestTime | Should -BeGreaterThan 0
            
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $result.ForEachParallel | Should -Not -BeNullOrEmpty
            }
            
            $result.RunspacePool | Should -Not -BeNullOrEmpty
            $result.BatchParallel | Should -Not -BeNullOrEmpty
            $result.Sequential | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait recommander la mÃ©thode la plus rapide" {
            $data = 1..20
            $result = Optimize-ParallelExecution -Data $data -ScriptBlock ${function:Test-Function} -MaxThreads 4 -ChunkSize 5 -Measure
            
            $result.Recommendations | Should -Not -BeNullOrEmpty
            $result.Recommendations.Method | Should -Be $result.FastestMethod
        }
        
        It "Devrait exÃ©cuter directement avec la mÃ©thode optimale si Measure n'est pas spÃ©cifiÃ©" {
            $data = 1..20
            $result = Optimize-ParallelExecution -Data $data -ScriptBlock ${function:Test-Function} -MaxThreads 4 -ChunkSize 5
            
            $result.Results.Count | Should -Be 20
            $result.ExecutionTime | Should -BeGreaterThan 0
        }
    }
}
