BeforeAll {
    # Importer le module de cache
    $cachePath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelectionCache.ps1"
    . $cachePath
}

Describe "Tests basiques du cache" {
    It "Initialise le cache" {
        Initialize-BandwidthSelectionCache
        $stats = Get-CacheStatistics
        $stats | Should -Not -BeNullOrEmpty
    }
    
    It "Ajoute une entrée au cache" {
        Initialize-BandwidthSelectionCache
        Add-CacheEntry -Key "test" -Result @{ Value = "test" }
        $stats = Get-CacheStatistics
        $stats.EntryCount | Should -Be 1
    }
    
    It "Récupère une entrée du cache" {
        Initialize-BandwidthSelectionCache
        Add-CacheEntry -Key "test" -Result @{ Value = "test" }
        $result = Get-CacheEntry -Key "test"
        $result | Should -Not -BeNullOrEmpty
        $result.Value | Should -Be "test"
    }
}
