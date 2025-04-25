<#
.SYNOPSIS
    Tests unitaires très simples pour vérifier que Pester fonctionne correctement.
.DESCRIPTION
    Ce script contient des tests unitaires très simples pour vérifier que Pester fonctionne correctement.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

Describe "Tests basiques" {
    It "Devrait additionner deux nombres" {
        1 + 1 | Should -Be 2
    }
    
    It "Devrait soustraire deux nombres" {
        3 - 1 | Should -Be 2
    }
}
