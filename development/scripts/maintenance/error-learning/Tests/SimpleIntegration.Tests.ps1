﻿<#
.SYNOPSIS
    Tests d'intÃ©gration simples pour le systÃ¨me d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce script contient des tests d'intÃ©gration simples pour le systÃ¨me d'apprentissage des erreurs PowerShell.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# DÃ©finir les tests Pester
Describe "Tests d'intÃ©gration simples" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "SimpleIntegrationTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

        # CrÃ©er un fichier de test
        $testFilePath = Join-Path -Path $script:testRoot -ChildPath "test.txt"
        Set-Content -Path $testFilePath -Value "Test content"
    }

    Context "OpÃ©rations de fichier" {
        It "Devrait crÃ©er un fichier" {
            $filePath = Join-Path -Path $script:testRoot -ChildPath "created.txt"
            Set-Content -Path $filePath -Value "Created content"
            Test-Path -Path $filePath | Should -BeTrue
        }

        It "Devrait lire un fichier" {
            $filePath = Join-Path -Path $script:testRoot -ChildPath "test.txt"
            $content = Get-Content -Path $filePath -Raw
            $content.TrimEnd() | Should -Be "Test content"
        }

        It "Devrait modifier un fichier" {
            $filePath = Join-Path -Path $script:testRoot -ChildPath "test.txt"
            Set-Content -Path $filePath -Value "Modified content"
            $content = Get-Content -Path $filePath -Raw
            $content.TrimEnd() | Should -Be "Modified content"
        }

        It "Devrait supprimer un fichier" {
            $filePath = Join-Path -Path $script:testRoot -ChildPath "test.txt"
            Remove-Item -Path $filePath -Force
            Test-Path -Path $filePath | Should -BeFalse
        }
    }

    AfterAll {
        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}
