<#
.SYNOPSIS
    Tests unitaires simples pour vérifier que Pester fonctionne correctement.
.DESCRIPTION
    Ce script contient des tests unitaires simples pour vérifier que Pester fonctionne correctement.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
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

# Ne pas exécuter les tests automatiquement pour éviter la récursion infinie
# Invoke-Pester -Path $PSCommandPath -Output Detailed
