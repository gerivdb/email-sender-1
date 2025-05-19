Describe "Super Simple Test" {
    It "Should pass" {
        $true | Should -Be $true
    }
    
    It "Should add numbers correctly" {
        1 + 1 | Should -Be 2
    }
}
