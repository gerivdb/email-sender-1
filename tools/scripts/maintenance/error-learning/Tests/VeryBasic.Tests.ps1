<#
.SYNOPSIS
    Tests très basiques pour vérifier que Pester fonctionne correctement.
.DESCRIPTION
    Ce script contient des tests très basiques pour vérifier que Pester fonctionne correctement.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

Describe "Tests très basiques" {
    It "Devrait additionner deux nombres" {
        1 + 1 | Should -Be 2
    }
    
    It "Devrait soustraire deux nombres" {
        3 - 1 | Should -Be 2
    }
    
    It "Devrait multiplier deux nombres" {
        2 * 3 | Should -Be 6
    }
    
    It "Devrait diviser deux nombres" {
        6 / 2 | Should -Be 3
    }
}
