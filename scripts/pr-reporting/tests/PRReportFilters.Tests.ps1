#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module PRReportFilters.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module PRReportFilters
    en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du module à tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRReportFilters.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    throw "Module PRReportFilters non trouvé à l'emplacement: $moduleToTest"
}

# Importer le module à tester
Import-Module $moduleToTest -Force

# Tests Pester
Describe "PRReportFilters Module Tests" {
    Context "Add-FilterControls" {
        It "Génère des contrôles de filtrage HTML" {
            # Données de test
            $issues = @(
                [PSCustomObject]@{
                    Type     = "Syntax"
                    Severity = "Error"
                    Rule     = "PSAvoidUsingCmdletAliases"
                    FilePath = "test.ps1"
                    Line     = 10
                    Message  = "Avoid using cmdlet aliases"
                },
                [PSCustomObject]@{
                    Type     = "Style"
                    Severity = "Warning"
                    Rule     = "PSUseConsistentIndentation"
                    FilePath = "test.ps1"
                    Line     = 20
                    Message  = "Use consistent indentation"
                },
                [PSCustomObject]@{
                    Type     = "Performance"
                    Severity = "Information"
                    Rule     = "PSUseProcessBlockForPipelineCommand"
                    FilePath = "test2.ps1"
                    Line     = 30
                    Message  = "Use process block for pipeline command"
                }
            )

            # Générer les contrôles de filtrage
            $filterControls = Add-FilterControls -Issues $issues

            # Vérifier le résultat
            $filterControls | Should -Not -BeNullOrEmpty
            $filterControls | Should -BeOfType [string]
            $filterControls | Should -BeLike "*pr-filter-container*"
            $filterControls | Should -BeLike "*Filtres*"
            $filterControls | Should -BeLike "*Type*"
            $filterControls | Should -BeLike "*Severity*"
            $filterControls | Should -BeLike "*Rule*"
            $filterControls | Should -BeLike "*Syntax*"
            $filterControls | Should -BeLike "*Style*"
            $filterControls | Should -BeLike "*Performance*"
            $filterControls | Should -BeLike "*Error*"
            $filterControls | Should -BeLike "*Warning*"
            $filterControls | Should -BeLike "*Information*"
        }

        It "Utilise les paramètres personnalisés" {
            # Données de test
            $issues = @(
                [PSCustomObject]@{
                    Category = "A"
                    Priority = "High"
                    FilePath = "test.ps1"
                }
            )

            # Générer les contrôles de filtrage avec des paramètres personnalisés
            $filterControls = Add-FilterControls -Issues $issues -ContainerId "custom-filters" -TargetTableId "custom-table" -FilterProperties @("Category", "Priority") -CustomLabels @{ "Category" = "Catégorie"; "Priority" = "Priorité" }

            # Vérifier le résultat
            $filterControls | Should -Not -BeNullOrEmpty
            $filterControls | Should -BeLike "*id=`"custom-filters`"*"
            $filterControls | Should -BeLike "*custom-table*"
            $filterControls | Should -BeLike "*Catégorie*"
            $filterControls | Should -BeLike "*Priorité*"
            $filterControls | Should -BeLike "*data-filter=`"Category`"*"
            $filterControls | Should -BeLike "*data-filter=`"Priority`"*"
        }

        It "Gère un ensemble de données vide" {
            # Données de test vides
            $issues = @()

            # Générer les contrôles de filtrage
            $filterControls = Add-FilterControls -Issues $issues

            # Vérifier le résultat
            $filterControls | Should -Not -BeNullOrEmpty
            $filterControls | Should -BeLike "*pr-filter-container*"
            $filterControls | Should -BeLike "*Filtres*"
        }
    }

    Context "Add-SortingCapabilities" {
        It "Génère du JavaScript pour le tri de table" {
            # Générer les capacités de tri
            $sortingCapabilities = Add-SortingCapabilities

            # Vérifier le résultat
            $sortingCapabilities | Should -Not -BeNullOrEmpty
            $sortingCapabilities | Should -BeOfType [string]
            $sortingCapabilities | Should -BeLike "*<script>*"
            $sortingCapabilities | Should -BeLike "*sortTable*"
            $sortingCapabilities | Should -BeLike "*pr-sortable*"
            $sortingCapabilities | Should -BeLike "*pr-sort-indicator*"
        }

        It "Utilise les paramètres personnalisés" {
            # Générer les capacités de tri avec des paramètres personnalisés
            $sortingCapabilities = Add-SortingCapabilities -TableId "custom-table" -SortableColumns @("Name", "Date") -DefaultSortColumn "Date" -DefaultSortDirection "asc"

            # Vérifier le résultat
            $sortingCapabilities | Should -Not -BeNullOrEmpty
            $sortingCapabilities | Should -BeLike "*custom-table*"
            $sortingCapabilities | Should -BeLike "*Name*"
            $sortingCapabilities | Should -BeLike "*Date*"
            $sortingCapabilities | Should -BeLike "*asc*"
        }
    }

    Context "New-CustomReportView" {
        It "Génère une vue personnalisée" {
            # Générer une vue personnalisée
            $customView = New-CustomReportView -name "Erreurs critiques" -Filters @{ Severity = "Error" } -Description "Afficher uniquement les erreurs critiques"

            # Vérifier le résultat
            $customView | Should -Not -BeNullOrEmpty
            $customView | Should -BeOfType [string]
            $customView | Should -BeLike "*<div class=`"pr-custom-view`"*"
            $customView | Should -BeLike "*Erreurs critiques*"
            $customView | Should -BeLike "*Afficher uniquement les erreurs critiques*"
            $customView | Should -BeLike "*Severity*"
            $customView | Should -BeLike "*Error*"
        }

        It "Utilise les paramètres personnalisés" {
            # Générer une vue personnalisée avec des paramètres personnalisés
            $customView = New-CustomReportView -name "Vue personnalisée" -Filters @{ Type = "Custom" } -Description "Description personnalisée" -Icon "star" -TargetTableId "custom-table"

            # Vérifier le résultat
            $customView | Should -Not -BeNullOrEmpty
            $customView | Should -BeLike "*Vue personnalisée*"
            $customView | Should -BeLike "*Description personnalisée*"
            $customView | Should -BeLike "*fa-star*"
            $customView | Should -BeLike "*custom-table*"
        }
    }

    Context "New-SearchableReport" {
        It "Génère un rapport avec recherche avancée" {
            # Données de test
            $issues = @(
                [PSCustomObject]@{
                    Type     = "Syntax"
                    Severity = "Error"
                    Rule     = "PSAvoidUsingCmdletAliases"
                    FilePath = "test.ps1"
                    Line     = 10
                    Message  = "Avoid using cmdlet aliases"
                },
                [PSCustomObject]@{
                    Type     = "Style"
                    Severity = "Warning"
                    Rule     = "PSUseConsistentIndentation"
                    FilePath = "test.ps1"
                    Line     = 20
                    Message  = "Use consistent indentation"
                }
            )

            # Générer le rapport avec recherche
            $searchableReport = New-SearchableReport -Issues $issues -Title "Test Report" -Description "Test Description"

            # Vérifier le résultat
            $searchableReport | Should -Not -BeNullOrEmpty
            $searchableReport | Should -BeOfType [string]
            $searchableReport | Should -BeLike "*<div class=`"pr-searchable-report`"*"
            $searchableReport | Should -BeLike "*Test Report*"
            $searchableReport | Should -BeLike "*Test Description*"
            $searchableReport | Should -BeLike "*pr-advanced-search*"
            $searchableReport | Should -BeLike "*pr-issues-table*"
            $searchableReport | Should -BeLike "*Type*"
            $searchableReport | Should -BeLike "*Severity*"
            $searchableReport | Should -BeLike "*FilePath*"
            $searchableReport | Should -BeLike "*Line*"
            $searchableReport | Should -BeLike "*Message*"
            $searchableReport | Should -BeLike "*Rule*"
            $searchableReport | Should -BeLike "*Syntax*"
            $searchableReport | Should -BeLike "*Error*"
            $searchableReport | Should -BeLike "*test.ps1*"
        }

        It "Utilise les paramètres personnalisés" {
            # Données de test
            $issues = @(
                [PSCustomObject]@{
                    Type  = "Custom"
                    Value = "Test"
                }
            )

            # Générer le rapport avec recherche avec des paramètres personnalisés
            $searchableReport = New-SearchableReport -Issues $issues -Title "Custom Report" -Description "Custom Description" -TableId "custom-table" -SearchableProperties @("Type", "Value")

            # Vérifier le résultat
            $searchableReport | Should -Not -BeNullOrEmpty
            $searchableReport | Should -BeLike "*Custom Report*"
            $searchableReport | Should -BeLike "*Custom Description*"
            $searchableReport | Should -BeLike "*id=`"custom-table`"*"
            $searchableReport | Should -BeLike "*Type*"
            $searchableReport | Should -BeLike "*Value*"
        }

        It "Gère un ensemble de données vide" {
            # Données de test vides
            $issues = @()

            # Générer le rapport avec recherche
            $searchableReport = New-SearchableReport -Issues $issues -Title "Empty Report"

            # Vérifier le résultat
            $searchableReport | Should -Not -BeNullOrEmpty
            $searchableReport | Should -BeLike "*Empty Report*"
            $searchableReport | Should -BeLike "*pr-issues-table*"
            $searchableReport | Should -BeLike "*pr-issues-counter*"
        }
    }
}

# Note: Ne pas exécuter les tests directement ici pour éviter une récursion infinie
# Utilisez plutôt: Invoke-Pester -Path $PSCommandPath
