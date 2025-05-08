BeforeAll {
    # Importer les modules à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $modulePath -Force
    
    $cachePath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelectionCache.ps1"
    . $cachePath
}

Describe "Tests simples du module BandwidthSelectionCache" {
    It "Initialise correctement le cache" {
        Initialize-BandwidthSelectionCache -MaxCacheSize 10 -ExpirationMinutes 5
        
        $stats = Get-CacheStatistics
        
        $stats | Should -Not -BeNullOrEmpty
        $stats.MaxSize | Should -Be 10
        $stats.ExpirationMinutes | Should -Be 5
    }
    
    It "Ajoute et récupère correctement une entrée du cache" {
        Initialize-BandwidthSelectionCache -MaxCacheSize 10 -ExpirationMinutes 5
        
        $key = "TestKey"
        $result = @{
            SelectedMethod = "Silverman"
            Bandwidth = 0.5
            ExecutionTime = 0.1
        }
        
        Add-CacheEntry -Key $key -Result $result
        
        $cachedResult = Get-CacheEntry -Key $key
        
        $cachedResult | Should -Not -BeNullOrEmpty
        $cachedResult.SelectedMethod | Should -Be "Silverman"
        $cachedResult.Bandwidth | Should -Be 0.5
    }
}
