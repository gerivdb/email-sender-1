BeforeAll {
    # Importer les modules à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $modulePath -Force

    $cachePath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelectionCache.ps1"
    . $cachePath
}

Describe "Tests de l'intégration du cache avec Get-OptimalBandwidthMethod" {
    It "Utilise le cache pour des appels répétés avec les mêmes données" {
        # Réinitialiser le cache
        Initialize-BandwidthSelectionCache -MaxCacheSize 10 -ExpirationMinutes 5

        # Créer des données de test simples
        $data = @(1, 2, 3, 4, 5)

        # Vérifier les statistiques initiales du cache
        $initialStats = Get-CacheStatistics
        $initialHits = $initialStats.Hits
        $initialAdditions = $initialStats.Additions

        # Premier appel (sans cache)
        $result1 = Get-OptimalBandwidthMethod -Data $data -UseCache $true

        # Vérifier que l'entrée a été ajoutée au cache
        $statsAfterFirstCall = Get-CacheStatistics
        $statsAfterFirstCall.Additions | Should -BeGreaterThan $initialAdditions

        # Deuxième appel (avec cache)
        $result2 = Get-OptimalBandwidthMethod -Data $data -UseCache $true

        # Vérifier que les résultats sont identiques
        $result1.SelectedMethod | Should -Be $result2.SelectedMethod
        $result1.Bandwidth | Should -Be $result2.Bandwidth

        # Vérifier que le cache a été utilisé
        $statsAfterSecondCall = Get-CacheStatistics
        $statsAfterSecondCall.Hits | Should -BeGreaterThan $initialHits
    }
}
