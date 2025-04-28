<#
.SYNOPSIS
    Tests unitaires simples pour vÃ©rifier que Pester fonctionne correctement.
.DESCRIPTION
    Ce script contient des tests unitaires simples pour vÃ©rifier que Pester fonctionne correctement.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

Describe "Tests simples" {
    It "Devrait additionner deux nombres" {
        1 + 1 | Should -Be 2
    }

    It "Devrait soustraire deux nombres" {
        3 - 1 | Should -Be 2
    }

    It "Devrait multiplier deux nombres" {
        2 * 2 | Should -Be 4
    }

    It "Devrait diviser deux nombres" {
        4 / 2 | Should -Be 2
    }
}

# Ne pas exÃ©cuter les tests automatiquement pour Ã©viter la rÃ©cursion infinie
# # # # # Invoke-Pester -Path $PSCommandPath -Output Detailed # CommentÃ© pour Ã©viter la rÃ©cursion infinie # CommentÃ© pour Ã©viter la rÃ©cursion infinie # CommentÃ© pour Ã©viter la rÃ©cursion infinie # CommentÃ© pour Ã©viter la rÃ©cursion infinie



