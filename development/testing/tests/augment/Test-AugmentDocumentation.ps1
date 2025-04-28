#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la structure de documentation Augment.

.DESCRIPTION
    Ce script vérifie que la structure de documentation Augment est correctement
    implémentée et accessible.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param()

# Importer le module Pester s'il est disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -ErrorAction Stop

# Définir le chemin racine du projet
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Describe "Structure de documentation Augment" {
    Context "Structure des dossiers" {
        It "Le dossier .augment existe" {
            Test-Path -Path "$projectRoot\.augment" -PathType Container | Should -Be $true
        }

        It "Le dossier .augment/guidelines existe" {
            Test-Path -Path "$projectRoot\.augment\guidelines" -PathType Container | Should -Be $true
        }

        It "Le dossier .augment/context existe" {
            Test-Path -Path "$projectRoot\.augment\context" -PathType Container | Should -Be $true
        }
    }

    Context "Fichiers de configuration" {
        It "Le fichier config.json existe" {
            Test-Path -Path "$projectRoot\.augment\config.json" -PathType Leaf | Should -Be $true
        }

        It "Le fichier README.md existe" {
            Test-Path -Path "$projectRoot\.augment\README.md" -PathType Leaf | Should -Be $true
        }

        It "Le fichier config.json contient les fournisseurs de contexte guidelines et context" {
            $config = Get-Content -Path "$projectRoot\.augment\config.json" -Raw | ConvertFrom-Json
            $config.context_providers | Where-Object { $_.name -eq "guidelines" } | Should -Not -BeNullOrEmpty
            $config.context_providers | Where-Object { $_.name -eq "context" } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Fichiers de guidelines" {
        $guidelinesFiles = @(
            "frontend_rules.md",
            "backend_rules.md",
            "project_standards.md",
            "implementation_steps.md"
        )

        foreach ($file in $guidelinesFiles) {
            It "Le fichier guidelines/$file existe" {
                Test-Path -Path "$projectRoot\.augment\guidelines\$file" -PathType Leaf | Should -Be $true
            }
        }

        It "Les fichiers de guidelines contiennent du contenu" {
            $guidelinesFiles | ForEach-Object {
                $content = Get-Content -Path "$projectRoot\.augment\guidelines\$_" -Raw
                $content | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Fichiers de contexte" {
        $contextFiles = @(
            "app_flow.md",
            "tech_stack.md",
            "design_system.md"
        )

        foreach ($file in $contextFiles) {
            It "Le fichier context/$file existe" {
                Test-Path -Path "$projectRoot\.augment\context\$file" -PathType Leaf | Should -Be $true
            }
        }

        It "Les fichiers de contexte contiennent du contenu" {
            $contextFiles | ForEach-Object {
                $content = Get-Content -Path "$projectRoot\.augment\context\$_" -Raw
                $content | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Intégration à la roadmap" {
        It "Le fichier de tâche dans la roadmap existe" {
            Test-Path -Path "$projectRoot\Roadmap\tasks\augment_documentation_structure.md" -PathType Leaf | Should -Be $true
        }
    }
}

Describe "Validation du contenu" {
    Context "Validation du format Markdown" {
        $allFiles = @(
            Get-ChildItem -Path "$projectRoot\.augment\guidelines\*.md"
            Get-ChildItem -Path "$projectRoot\.augment\context\*.md"
            "$projectRoot\.augment\README.md"
        )

        foreach ($file in $allFiles) {
            It "Le fichier $($file.Name) a un format Markdown valide" {
                $content = Get-Content -Path $file.FullName -Raw
                # Vérifier la présence d'au moins un titre
                $content -match "^#\s+.+" | Should -Be $true
                # Vérifier qu'il n'y a pas de balises HTML non fermées
                $openTags = [regex]::Matches($content, "<[a-zA-Z]+[^>]*>").Count
                $closeTags = [regex]::Matches($content, "</[a-zA-Z]+>").Count
                $selfClosingTags = [regex]::Matches($content, "<[a-zA-Z]+[^>]*/\s*>").Count
                ($openTags - $closeTags - $selfClosingTags) | Should -Be 0
            }
        }
    }

    Context "Validation du contenu JSON" {
        It "Le fichier config.json est un JSON valide" {
            { Get-Content -Path "$projectRoot\.augment\config.json" -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed
