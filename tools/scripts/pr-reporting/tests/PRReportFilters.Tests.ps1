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
    Write-Warning "Le module Pester n'est pas installÃ©. Installation recommandÃ©e: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du module Ã  tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRReportFilters.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    throw "Module PRReportFilters non trouvÃ© Ã  l'emplacement: $moduleToTest"
}

# Importer le module Ã  tester
Import-Module $moduleToTest -Force

# Tests Pester
Describe "PRReportFilters Module Tests" {
    Context "Add-FilterControls" {
        It "GÃ©nÃ¨re des contrÃ´les de filtrage HTML" {
            # DonnÃ©es de test
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

            # GÃ©nÃ©rer les contrÃ´les de filtrage
            $filterControls = Add-FilterControls -Issues $issues

            # VÃ©rifier le rÃ©sultat
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

        It "Utilise les paramÃ¨tres personnalisÃ©s" {
            # DonnÃ©es de test
            $issues = @(
                [PSCustomObject]@{
                    Category = "A"
                    Priority = "High"
                    FilePath = "test.ps1"
                }
            )

            # GÃ©nÃ©rer les contrÃ´les de filtrage avec des paramÃ¨tres personnalisÃ©s
            $filterControls = Add-FilterControls -Issues $issues -ContainerId "custom-filters" -TargetTableId "custom-table" -FilterProperties @("Category", "Priority") -CustomLabels @{ "Category" = "CatÃ©gorie"; "Priority" = "PrioritÃ©" }

            # VÃ©rifier le rÃ©sultat
            $filterControls | Should -Not -BeNullOrEmpty
            $filterControls | Should -BeLike "*id=`"custom-filters`"*"
            $filterControls | Should -BeLike "*custom-table*"
            $filterControls | Should -BeLike "*CatÃ©gorie*"
            $filterControls | Should -BeLike "*PrioritÃ©*"
            $filterControls | Should -BeLike "*data-filter=`"Category`"*"
            $filterControls | Should -BeLike "*data-filter=`"Priority`"*"
        }

        It "GÃ¨re un ensemble de donnÃ©es vide" {
            # DonnÃ©es de test vides
            $issues = @()

            # GÃ©nÃ©rer les contrÃ´les de filtrage
            $filterControls = Add-FilterControls -Issues $issues

            # VÃ©rifier le rÃ©sultat
            $filterControls | Should -Not -BeNullOrEmpty
            $filterControls | Should -BeLike "*pr-filter-container*"
            $filterControls | Should -BeLike "*Filtres*"
        }
    }

    Context "Add-SortingCapabilities" {
        It "GÃ©nÃ¨re du JavaScript pour le tri de table" {
            # GÃ©nÃ©rer les capacitÃ©s de tri
            $sortingCapabilities = Add-SortingCapabilities

            # VÃ©rifier le rÃ©sultat
            $sortingCapabilities | Should -Not -BeNullOrEmpty
            $sortingCapabilities | Should -BeOfType [string]
            $sortingCapabilities | Should -BeLike "*<script>*"
            $sortingCapabilities | Should -BeLike "*sortTable*"
            $sortingCapabilities | Should -BeLike "*pr-sortable*"
            $sortingCapabilities | Should -BeLike "*pr-sort-indicator*"
        }

        It "Utilise les paramÃ¨tres personnalisÃ©s" {
            # GÃ©nÃ©rer les capacitÃ©s de tri avec des paramÃ¨tres personnalisÃ©s
            $sortingCapabilities = Add-SortingCapabilities -TableId "custom-table" -SortableColumns @("Name", "Date") -DefaultSortColumn "Date" -DefaultSortDirection "asc"

            # VÃ©rifier le rÃ©sultat
            $sortingCapabilities | Should -Not -BeNullOrEmpty
            $sortingCapabilities | Should -BeLike "*custom-table*"
            $sortingCapabilities | Should -BeLike "*Name*"
            $sortingCapabilities | Should -BeLike "*Date*"
            $sortingCapabilities | Should -BeLike "*asc*"
        }
    }

    Context "New-CustomReportView" {
        It "GÃ©nÃ¨re une vue personnalisÃ©e" {
            # GÃ©nÃ©rer une vue personnalisÃ©e
            $customView = New-CustomReportView -name "Erreurs critiques" -Filters @{ Severity = "Error" } -Description "Afficher uniquement les erreurs critiques"

            # VÃ©rifier le rÃ©sultat
            $customView | Should -Not -BeNullOrEmpty
            $customView | Should -BeOfType [string]
            $customView | Should -BeLike "*<div class=`"pr-custom-view`"*"
            $customView | Should -BeLike "*Erreurs critiques*"
            $customView | Should -BeLike "*Afficher uniquement les erreurs critiques*"
            $customView | Should -BeLike "*Severity*"
            $customView | Should -BeLike "*Error*"
        }

        It "Utilise les paramÃ¨tres personnalisÃ©s" {
            # GÃ©nÃ©rer une vue personnalisÃ©e avec des paramÃ¨tres personnalisÃ©s
            $customView = New-CustomReportView -name "Vue personnalisÃ©e" -Filters @{ Type = "Custom" } -Description "Description personnalisÃ©e" -Icon "star" -TargetTableId "custom-table"

            # VÃ©rifier le rÃ©sultat
            $customView | Should -Not -BeNullOrEmpty
            $customView | Should -BeLike "*Vue personnalisÃ©e*"
            $customView | Should -BeLike "*Description personnalisÃ©e*"
            $customView | Should -BeLike "*fa-star*"
            $customView | Should -BeLike "*custom-table*"
        }
    }

    Context "New-SearchableReport" {
        It "GÃ©nÃ¨re un rapport avec recherche avancÃ©e" {
            # DonnÃ©es de test
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

            # GÃ©nÃ©rer le rapport avec recherche
            $searchableReport = New-SearchableReport -Issues $issues -Title "Test Report" -Description "Test Description"

            # VÃ©rifier le rÃ©sultat
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

        It "Utilise les paramÃ¨tres personnalisÃ©s" {
            # DonnÃ©es de test
            $issues = @(
                [PSCustomObject]@{
                    Type  = "Custom"
                    Value = "Test"
                }
            )

            # GÃ©nÃ©rer le rapport avec recherche avec des paramÃ¨tres personnalisÃ©s
            $searchableReport = New-SearchableReport -Issues $issues -Title "Custom Report" -Description "Custom Description" -TableId "custom-table" -SearchableProperties @("Type", "Value")

            # VÃ©rifier le rÃ©sultat
            $searchableReport | Should -Not -BeNullOrEmpty
            $searchableReport | Should -BeLike "*Custom Report*"
            $searchableReport | Should -BeLike "*Custom Description*"
            $searchableReport | Should -BeLike "*id=`"custom-table`"*"
            $searchableReport | Should -BeLike "*Type*"
            $searchableReport | Should -BeLike "*Value*"
        }

        It "GÃ¨re un ensemble de donnÃ©es vide" {
            # DonnÃ©es de test vides
            $issues = @()

            # GÃ©nÃ©rer le rapport avec recherche
            $searchableReport = New-SearchableReport -Issues $issues -Title "Empty Report"

            # VÃ©rifier le rÃ©sultat
            $searchableReport | Should -Not -BeNullOrEmpty
            $searchableReport | Should -BeLike "*Empty Report*"
            $searchableReport | Should -BeLike "*pr-issues-table*"
            $searchableReport | Should -BeLike "*pr-issues-counter*"
        }
    }
}

# Note: Ne pas exÃ©cuter les tests directement ici pour Ã©viter une rÃ©cursion infinie
# Utilisez plutÃ´t: Invoke-Pester -Path $PSCommandPath
