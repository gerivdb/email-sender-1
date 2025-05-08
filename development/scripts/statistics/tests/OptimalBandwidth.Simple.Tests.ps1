BeforeAll {
    # Charger les modules nécessaires
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AdaptiveSampling.ps1"
    . $modulePath
    
    $kdePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $kdePath -Force
}

Describe "Tests simples pour Get-OptimalBandwidthMethod avec échantillonnage" {
    Context "Tests de base pour l'échantillonnage dans Get-OptimalBandwidthMethod" {
        It "Devrait utiliser l'échantillonnage adaptatif pour les grands ensembles de données" {
            # Générer un ensemble de données de taille moyenne
            $data = 1..500 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            
            # Appeler Get-OptimalBandwidthMethod avec l'échantillonnage adaptatif
            $result = Get-OptimalBandwidthMethod -Data $data -UseSampling $true -MaxSampleSize 100
            
            # Vérifier que l'échantillonnage a été utilisé
            $result.UsedSampling | Should -Be $true
            $result.SampledDataCount | Should -BeLessOrEqual 100
            $result.OriginalDataCount | Should -Be 500
            
            # Vérifier que la largeur de bande est valide
            $result.Bandwidth | Should -BeGreaterThan 0
        }
        
        It "Ne devrait pas utiliser l'échantillonnage pour les petits ensembles de données" {
            # Générer un petit ensemble de données
            $data = 1..50 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
            
            # Appeler Get-OptimalBandwidthMethod avec l'échantillonnage adaptatif
            $result = Get-OptimalBandwidthMethod -Data $data -UseSampling $true -MaxSampleSize 100
            
            # Vérifier que l'échantillonnage n'a pas été utilisé
            $result.UsedSampling | Should -Be $false
            $result.SampledDataCount | Should -Be 50
            $result.OriginalDataCount | Should -Be 50
        }
    }
}
