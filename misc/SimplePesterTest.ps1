# Test simple pour vérifier que Pester fonctionne
Describe "Test simple" {
    It "Vérifie que true est true" {
        $true | Should -Be $true
    }
}
