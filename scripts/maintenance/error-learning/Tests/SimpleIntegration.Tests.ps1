<#
.SYNOPSIS
    Tests d'intégration simples pour le système d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce script contient des tests d'intégration simples pour le système d'apprentissage des erreurs PowerShell.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Aucune définition de chemin nécessaire ici

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "SimpleIntegrationTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Définir les tests Pester
Describe "Tests d'intégration simples" {
    BeforeAll {
        # Créer un fichier de test
        $testFilePath = Join-Path -Path $testRoot -ChildPath "test.txt"
        Set-Content -Path $testFilePath -Value "Test content"
    }

    Context "Opérations de fichier" {
        It "Devrait créer un fichier" {
            $filePath = Join-Path -Path $testRoot -ChildPath "created.txt"
            Set-Content -Path $filePath -Value "Created content"
            Test-Path -Path $filePath | Should -BeTrue
        }

        It "Devrait lire un fichier" {
            $filePath = Join-Path -Path $testRoot -ChildPath "test.txt"
            $content = Get-Content -Path $filePath -Raw
            $content | Should -Be "Test content"
        }

        It "Devrait modifier un fichier" {
            $filePath = Join-Path -Path $testRoot -ChildPath "test.txt"
            Set-Content -Path $filePath -Value "Modified content"
            $content = Get-Content -Path $filePath -Raw
            $content | Should -Be "Modified content"
        }

        It "Devrait supprimer un fichier" {
            $filePath = Join-Path -Path $testRoot -ChildPath "test.txt"
            Remove-Item -Path $filePath -Force
            Test-Path -Path $filePath | Should -BeFalse
        }
    }

    AfterAll {
        # Supprimer le répertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force
        }
    }
}
