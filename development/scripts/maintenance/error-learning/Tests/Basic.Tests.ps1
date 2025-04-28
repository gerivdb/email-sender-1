<#
.SYNOPSIS
    Tests unitaires trÃ¨s simples pour vÃ©rifier que Pester fonctionne correctement.
.DESCRIPTION
    Ce script contient des tests unitaires trÃ¨s simples pour vÃ©rifier que Pester fonctionne correctement.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

Describe "Tests basiques" {
    It "Devrait additionner deux nombres" {
        1 + 1 | Should -Be 2
    }
    
    It "Devrait soustraire deux nombres" {
        3 - 1 | Should -Be 2
    }
}
