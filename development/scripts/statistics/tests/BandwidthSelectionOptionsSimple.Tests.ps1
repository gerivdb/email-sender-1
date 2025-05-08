BeforeAll {
    # Importer les modules à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $modulePath -Force
    
    $optionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\BandwidthSelectionOptions.ps1"
    . $optionsPath
}

Describe "Tests simples de la fonction Get-BandwidthSelectionOptions" {
    It "Crée un objet d'options avec les valeurs par défaut" {
        $options = Get-BandwidthSelectionOptions
        
        $options | Should -Not -BeNullOrEmpty
        $options.Methods | Should -Contain "Silverman"
        $options.Methods | Should -Contain "Scott"
        $options.Weights.Accuracy | Should -Be 1
        $options.Weights.Speed | Should -Be 1
        $options.AutoDetect | Should -Be $true
        $options.ObjectiveProfile | Should -Be "Balanced"
    }
}
