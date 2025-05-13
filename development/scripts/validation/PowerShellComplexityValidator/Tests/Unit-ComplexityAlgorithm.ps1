#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour l'algorithme de calcul de la complexité cyclomatique.
.DESCRIPTION
    Ce script contient des tests unitaires pour l'algorithme de calcul de la complexité
    cyclomatique du module PowerShellComplexityValidator.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module -Name Pester -Force

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\CyclomaticComplexityAnalyzer.psm1'
Import-Module -Name $modulePath -Force

# Créer des structures de contrôle fictives pour les tests
function New-MockControlStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [int]$Line,
        
        [Parameter(Mandatory = $false)]
        [int]$Column = 1,
        
        [Parameter(Mandatory = $false)]
        [string]$Text = "Test"
    )
    
    return [PSCustomObject]@{
        Type = $Type
        Line = $Line
        Column = $Column
        Text = $Text
    }
}

# Définir les tests Pester
Describe "Get-CyclomaticComplexityScore" {
    Context "Calcul de base" {
        It "Devrait retourner un score de 1 pour un tableau vide" {
            $result = Get-CyclomaticComplexityScore -ControlStructures @()
            $result.Score | Should -Be 1
        }
        
        It "Devrait retourner un score de 2 pour une structure If" {
            $structures = @(
                New-MockControlStructure -Type "If" -Line 1
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            $result.Score | Should -Be 2
        }
        
        It "Devrait retourner un score de 3 pour une structure If et une structure ElseIf" {
            $structures = @(
                New-MockControlStructure -Type "If" -Line 1
                New-MockControlStructure -Type "ElseIf" -Line 5
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            $result.Score | Should -Be 3
        }
        
        It "Devrait ignorer les structures Else dans le calcul" {
            $structures = @(
                New-MockControlStructure -Type "If" -Line 1
                New-MockControlStructure -Type "Else" -Line 5
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            $result.Score | Should -Be 2
        }
    }
    
    Context "Structures de contrôle" {
        It "Devrait compter correctement les boucles" {
            $structures = @(
                New-MockControlStructure -Type "For" -Line 1
                New-MockControlStructure -Type "ForEach" -Line 5
                New-MockControlStructure -Type "While" -Line 10
                New-MockControlStructure -Type "DoWhile" -Line 15
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            $result.Score | Should -Be 5
        }
        
        It "Devrait compter correctement les instructions switch" {
            $structures = @(
                New-MockControlStructure -Type "Switch" -Line 1
                New-MockControlStructure -Type "SwitchClause" -Line 2
                New-MockControlStructure -Type "SwitchClause" -Line 3
                New-MockControlStructure -Type "SwitchDefault" -Line 4
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            $result.Score | Should -Be 5
        }
        
        It "Devrait compter correctement les blocs try/catch" {
            $structures = @(
                New-MockControlStructure -Type "Catch" -Line 5
                New-MockControlStructure -Type "Catch" -Line 10
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            $result.Score | Should -Be 3
        }
        
        It "Devrait compter correctement les opérateurs logiques" {
            $structures = @(
                New-MockControlStructure -Type "LogicalOperator_And" -Line 1
                New-MockControlStructure -Type "LogicalOperator_Or" -Line 2
                New-MockControlStructure -Type "LogicalOperator_And" -Line 3
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            $result.Score | Should -Be 4
        }
    }
    
    Context "Imbrication" {
        It "Devrait ajouter une pénalité pour les structures imbriquées" {
            # Simuler des structures imbriquées en utilisant des lignes consécutives
            $structures = @(
                New-MockControlStructure -Type "If" -Line 1
                New-MockControlStructure -Type "If" -Line 2
                New-MockControlStructure -Type "If" -Line 3
                New-MockControlStructure -Type "If" -Line 4
                New-MockControlStructure -Type "If" -Line 5
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            # Score de base : 1 + 5 structures = 6
            # Pénalité d'imbrication : (5 - 3) * 0.2 = 0.4
            # Score total : 6 + 0.4 = 6.4 (arrondi à 6.4)
            $result.Score | Should -BeGreaterThan 6
        }
    }
    
    Context "Cas complexes" {
        It "Devrait calculer correctement la complexité d'un cas complexe" {
            $structures = @(
                # If/ElseIf/Else
                New-MockControlStructure -Type "If" -Line 1
                New-MockControlStructure -Type "ElseIf" -Line 5
                New-MockControlStructure -Type "ElseIf" -Line 10
                New-MockControlStructure -Type "Else" -Line 15
                
                # Boucles
                New-MockControlStructure -Type "For" -Line 20
                New-MockControlStructure -Type "ForEach" -Line 25
                
                # Switch
                New-MockControlStructure -Type "Switch" -Line 30
                New-MockControlStructure -Type "SwitchClause" -Line 31
                New-MockControlStructure -Type "SwitchClause" -Line 32
                New-MockControlStructure -Type "SwitchDefault" -Line 33
                
                # Try/Catch
                New-MockControlStructure -Type "Catch" -Line 40
                New-MockControlStructure -Type "Catch" -Line 45
                
                # Opérateurs logiques
                New-MockControlStructure -Type "LogicalOperator_And" -Line 50
                New-MockControlStructure -Type "LogicalOperator_Or" -Line 51
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            # Score de base : 1
            # Structures : 13 (sans compter Else)
            # Score total : 14 + pénalité d'imbrication
            $result.Score | Should -BeGreaterThan 14
        }
    }
    
    Context "Détails du calcul" {
        It "Devrait fournir des détails corrects sur le calcul" {
            $structures = @(
                New-MockControlStructure -Type "If" -Line 1
                New-MockControlStructure -Type "ElseIf" -Line 5
                New-MockControlStructure -Type "For" -Line 10
            )
            $result = Get-CyclomaticComplexityScore -ControlStructures $structures
            $result.Details.BaseScore | Should -Be 1
            $result.Details.StructureContributions.Count | Should -Be 3
            $result.Details.StructureContributions["If"] | Should -Be 1
            $result.Details.StructureContributions["ElseIf"] | Should -Be 1
            $result.Details.StructureContributions["For"] | Should -Be 1
            $result.Details.TotalScore | Should -Be 4
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed
