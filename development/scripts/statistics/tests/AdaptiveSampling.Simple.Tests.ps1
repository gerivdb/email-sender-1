BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AdaptiveSampling.ps1"
    . $modulePath
}

Describe "Tests simples pour l'échantillonnage adaptatif" {
    Context "Tests de base pour Get-AdaptiveSampling" {
        It "Devrait retourner les données d'origine si elles sont plus petites que la taille maximale de l'échantillon" {
            $data = 1..10
            $result = Get-AdaptiveSampling -Data $data -MaxSampleSize 20
            $result.Count | Should -Be 10
            $result | Should -Be $data
        }
        
        It "Devrait échantillonner les données si elles sont plus grandes que la taille maximale de l'échantillon" {
            $data = 1..2000
            $result = Get-AdaptiveSampling -Data $data -MaxSampleSize 500
            $result.Count | Should -BeLessOrEqual 500
        }
        
        It "Devrait préserver les valeurs extrêmes si demandé" {
            $data = 1..1000
            $result = Get-AdaptiveSampling -Data $data -MaxSampleSize 100 -PreserveExtremes $true
            $result | Should -Contain 1
            $result | Should -Contain 1000
        }
    }
}
