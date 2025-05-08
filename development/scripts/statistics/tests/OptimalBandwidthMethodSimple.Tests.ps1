BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\KernelDensityEstimation.psm1"
    Import-Module $modulePath -Force
}

Describe "Tests simples de l'intégration de Get-OptimalBandwidthMethod" {
    It "Vérifie que Get-OptimalBandwidthMethod fonctionne correctement" {
        # Utiliser des données très simples
        $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

        # Appeler directement Get-OptimalBandwidthMethod
        $result = Get-OptimalBandwidthMethod -Data $data -KernelType "Gaussian" -Objective "Balanced" -AutoDetect $true

        # Vérifier que le résultat contient les informations attendues
        $result | Should -Not -BeNullOrEmpty
        $result.SelectedMethod | Should -Not -BeNullOrEmpty
        $result.Bandwidth | Should -BeGreaterThan 0
    }

    It "Vérifie que l'intégration dans Get-KernelDensityEstimation fonctionne" {
        # Utiliser des données très simples
        $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

        # Effectuer l'estimation de densité avec la méthode Silverman (plus rapide pour les tests)
        $result = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Silverman" -KernelType "Gaussian"

        # Vérifier que le résultat contient les informations attendues
        $result | Should -Not -BeNullOrEmpty
        $result.BandwidthMethod | Should -Be "Silverman"
        $result.Bandwidth | Should -BeGreaterThan 0
    }

    It "Vérifie que l'option Auto fonctionne correctement" {
        # Utiliser des données très simples
        $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

        # Effectuer l'estimation de densité avec la méthode Auto
        $result = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -KernelType "Gaussian" -Objective "Balance"

        # Vérifier que le résultat contient les informations attendues
        $result | Should -Not -BeNullOrEmpty
        $result.BandwidthMethod | Should -Be "Auto"
        $result.Bandwidth | Should -BeGreaterThan 0
        $result.OptimalBandwidthInfo | Should -Not -BeNullOrEmpty
        $result.SelectedBandwidthMethod | Should -Not -BeNullOrEmpty
    }
}
