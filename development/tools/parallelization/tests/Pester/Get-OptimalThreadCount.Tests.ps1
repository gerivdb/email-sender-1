# Tests unitaires pour la fonction Get-OptimalThreadCount
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"
    
    # Importer le module
    Import-Module $modulePath -Force
    
    # Initialiser le module
    Initialize-UnifiedParallel
}

Describe "Get-OptimalThreadCount" {
    It "Retourne un nombre de threads valide pour le type CPU" {
        $result = Get-OptimalThreadCount -TaskType 'CPU'
        $result | Should -BeGreaterThan 0
        $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 2)
    }
    
    It "Retourne un nombre de threads valide pour le type IO" {
        $result = Get-OptimalThreadCount -TaskType 'IO'
        $result | Should -BeGreaterThan 0
        $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 8)
    }
    
    It "Retourne un nombre de threads valide pour le type Mixed" {
        $result = Get-OptimalThreadCount -TaskType 'Mixed'
        $result | Should -BeGreaterThan 0
        $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 4)
    }
    
    It "Retourne un nombre de threads valide pour le type LowPriority" {
        $result = Get-OptimalThreadCount -TaskType 'LowPriority'
        $result | Should -BeGreaterThan 0
        $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount)
    }
    
    It "Retourne un nombre de threads valide pour le type HighPriority" {
        $result = Get-OptimalThreadCount -TaskType 'HighPriority'
        $result | Should -BeGreaterThan 0
        $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 16)
    }
    
    It "Retourne un nombre de threads valide pour le type Default" {
        $result = Get-OptimalThreadCount -TaskType 'Default'
        $result | Should -BeGreaterThan 0
        $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 4)
    }
    
    It "Ajuste le nombre de threads en fonction de la charge système" {
        $result1 = Get-OptimalThreadCount -TaskType 'CPU' -SystemLoadPercent 0
        $result2 = Get-OptimalThreadCount -TaskType 'CPU' -SystemLoadPercent 80 -Dynamic
        
        $result1 | Should -BeGreaterThanOrEqual $result2
    }
    
    It "Prend en compte la mémoire si demandé" {
        $result1 = Get-OptimalThreadCount -TaskType 'CPU' -SystemLoadPercent 50
        $result2 = Get-OptimalThreadCount -TaskType 'CPU' -SystemLoadPercent 50 -ConsiderMemory -Dynamic
        
        # Les résultats peuvent être identiques si le système n'est pas chargé
        $result1 | Should -BeGreaterThanOrEqual $result2
    }
    
    It "Prend en compte l'IO disque si demandé pour les tâches IO" {
        $result1 = Get-OptimalThreadCount -TaskType 'IO' -SystemLoadPercent 50
        $result2 = Get-OptimalThreadCount -TaskType 'IO' -SystemLoadPercent 50 -ConsiderDiskIO -Dynamic
        
        # Les résultats peuvent être identiques si le système n'est pas chargé
        $result1 | Should -BeGreaterThanOrEqual $result2
    }
    
    It "Prend en compte l'IO réseau si demandé pour les tâches IO" {
        $result1 = Get-OptimalThreadCount -TaskType 'IO' -SystemLoadPercent 50
        $result2 = Get-OptimalThreadCount -TaskType 'IO' -SystemLoadPercent 50 -ConsiderNetworkIO -Dynamic
        
        # Les résultats peuvent être identiques si le système n'est pas chargé
        $result1 | Should -BeGreaterThanOrEqual $result2
    }
    
    It "Respecte les limites minimales et maximales" {
        # Tester avec une charge système très élevée
        $result = Get-OptimalThreadCount -TaskType 'CPU' -SystemLoadPercent 100 -Dynamic
        $result | Should -BeGreaterThanOrEqual 1
        $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 2)
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel
}
