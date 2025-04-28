#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les optimisations de traitement parallèle.
.DESCRIPTION
    Ce script contient les tests unitaires pour les fonctions de traitement parallèle,
    vérifiant les différentes méthodes de parallélisation.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-11
#>

BeforeAll {
    # Importer les scripts à tester
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\performance\Optimize-ParallelExecution.ps1"
    . $scriptPath
}

Describe "Invoke-SequentialProcessing" {
    Context "Lorsqu'on exécute un traitement séquentiel" {
        It "Devrait traiter tous les éléments" {
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
        
        It "Devrait mesurer le temps d'exécution" {
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
    Context "Lorsqu'on exécute un traitement parallèle avec Runspace Pools" {
        It "Devrait traiter tous les éléments" {
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
        
        It "Devrait être plus rapide que le traitement séquentiel pour les tâches longues" {
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
        
        It "Devrait utiliser le nombre de threads spécifié" {
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
    Context "Lorsqu'on exécute un traitement parallèle par lots" {
        It "Devrait traiter tous les éléments" {
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
            $result.BatchCount | Should -Be 4  # 10 éléments divisés en lots de 3 = 4 lots
        }
        
        It "Devrait être efficace pour les tâches avec surcharge de démarrage" {
            $data = 1..20
            $scriptBlock = {
                param($item)
                # Simuler une surcharge de démarrage
                Start-Sleep -Milliseconds 50
                return $item
            }
            
            $runspaceResult = Invoke-RunspacePoolProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
            $batchResult = Invoke-BatchParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -ChunkSize 5
            
            # Le traitement par lots devrait être plus efficace car il réduit la surcharge de démarrage
            $batchResult.ExecutionTime.TotalMilliseconds | Should -BeLessThan $runspaceResult.ExecutionTime.TotalMilliseconds
        }
        
        It "Devrait calculer automatiquement la taille des lots si non spécifiée" {
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
        Context "Lorsqu'on exécute un traitement parallèle avec ForEach-Object -Parallel" {
            It "Devrait traiter tous les éléments" {
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
    Context "Lorsqu'on optimise l'exécution parallèle" {
        BeforeAll {
            # Créer une fonction de test
            function Test-Function {
                param($item)
                Start-Sleep -Milliseconds 10
                return $item * 2
            }
        }
        
        It "Devrait comparer les différentes méthodes de parallélisation" {
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
        
        It "Devrait recommander la méthode la plus rapide" {
            $data = 1..20
            $result = Optimize-ParallelExecution -Data $data -ScriptBlock ${function:Test-Function} -MaxThreads 4 -ChunkSize 5 -Measure
            
            $result.Recommendations | Should -Not -BeNullOrEmpty
            $result.Recommendations.Method | Should -Be $result.FastestMethod
        }
        
        It "Devrait exécuter directement avec la méthode optimale si Measure n'est pas spécifié" {
            $data = 1..20
            $result = Optimize-ParallelExecution -Data $data -ScriptBlock ${function:Test-Function} -MaxThreads 4 -ChunkSize 5
            
            $result.Results.Count | Should -Be 20
            $result.ExecutionTime | Should -BeGreaterThan 0
        }
    }
}
