#Requires -Version 5.1
<#
.SYNOPSIS
    Test de débogage pour l'algorithme de calcul de la complexité cyclomatique.
.DESCRIPTION
    Ce script teste l'algorithme de calcul de la complexité cyclomatique
    du module PowerShellComplexityValidator et affiche les résultats détaillés.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

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
        Type   = $Type
        Line   = $Line
        Column = $Column
        Text   = $Text
    }
}

# Fonction pour exécuter un test
function Test-ComplexityScenario {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [object[]]$ControlStructures,

        [Parameter(Mandatory = $false)]
        [double]$ExpectedScore = 1.0
    )

    Write-Host "Test du scénario : $Name" -ForegroundColor Cyan

    # Calculer la complexité cyclomatique
    $result = Get-CyclomaticComplexityScore -ControlStructures $ControlStructures

    # Vérifier le résultat
    if ($result.Score -eq $ExpectedScore) {
        Write-Host "  Score correct : $($result.Score)" -ForegroundColor Green
    } else {
        Write-Host "  Score incorrect. Attendu : $ExpectedScore, Obtenu : $($result.Score)" -ForegroundColor Red
    }

    # Afficher les détails
    Write-Host "  Détails du calcul :" -ForegroundColor Yellow
    Write-Host "    Score de base : $($result.Details.BaseScore)" -ForegroundColor Gray

    if ($result.Details.StructureContributions.Count -gt 0) {
        Write-Host "    Structures détectées :" -ForegroundColor Gray
        foreach ($type in $result.Details.StructureContributions.Keys) {
            $count = $result.Details.StructureContributions[$type]
            $weight = if ($result.Details.WeightedStructures[$type]) {
                $result.Details.WeightedStructures[$type] / $count
            } else {
                0
            }
            Write-Host "      $type : $count (poids : $weight)" -ForegroundColor Gray
        }
    }

    if ($result.Details.NestingPenalty -gt 0) {
        Write-Host "    Pénalité d'imbrication : $($result.Details.NestingPenalty)" -ForegroundColor Gray
    }

    Write-Host "    Score total : $($result.Details.TotalScore)" -ForegroundColor Gray

    return $result
}

# Test 1: Tableau vide
Write-Host "Test 1: Tableau vide" -ForegroundColor Cyan
$emptyResult = Get-CyclomaticComplexityScore -ControlStructures @()
Write-Host "  Score : $($emptyResult.Score)" -ForegroundColor Gray
if ($emptyResult.Score -eq 1) {
    Write-Host "  Réussi: Le score est de 1 pour un tableau vide" -ForegroundColor Green
} else {
    Write-Host "  Échoué: Le score devrait être de 1 pour un tableau vide" -ForegroundColor Red
}

# Test 2: Structures de contrôle simples
$simpleStructures = @(
    New-MockControlStructure -Type "If" -Line 1
    New-MockControlStructure -Type "ElseIf" -Line 5
    New-MockControlStructure -Type "Else" -Line 10
)

Test-ComplexityScenario -Name "Structures simples" -ControlStructures $simpleStructures -ExpectedScore 3

# Test 3: Boucles
$loopStructures = @(
    New-MockControlStructure -Type "For" -Line 1
    New-MockControlStructure -Type "ForEach" -Line 5
    New-MockControlStructure -Type "While" -Line 10
    New-MockControlStructure -Type "DoWhile" -Line 15
)

Test-ComplexityScenario -Name "Boucles" -ControlStructures $loopStructures -ExpectedScore 5.2

# Test 4: Switch
$switchStructures = @(
    New-MockControlStructure -Type "Switch" -Line 1
    New-MockControlStructure -Type "SwitchClause" -Line 2
    New-MockControlStructure -Type "SwitchClause" -Line 3
    New-MockControlStructure -Type "SwitchDefault" -Line 4
)

Test-ComplexityScenario -Name "Switch" -ControlStructures $switchStructures -ExpectedScore 5.2

# Test 5: Try/Catch
$tryCatchStructures = @(
    New-MockControlStructure -Type "Catch" -Line 5
    New-MockControlStructure -Type "Catch" -Line 10
)

Test-ComplexityScenario -Name "Try/Catch" -ControlStructures $tryCatchStructures -ExpectedScore 3

# Test 6: Opérateurs logiques
$logicalOperatorStructures = @(
    New-MockControlStructure -Type "LogicalOperator_And" -Line 1
    New-MockControlStructure -Type "LogicalOperator_Or" -Line 2
    New-MockControlStructure -Type "LogicalOperator_And" -Line 3
)

Test-ComplexityScenario -Name "Opérateurs logiques" -ControlStructures $logicalOperatorStructures -ExpectedScore 4

# Test 7: Structures imbriquées
$nestedStructures = @(
    New-MockControlStructure -Type "If" -Line 1
    New-MockControlStructure -Type "If" -Line 2
    New-MockControlStructure -Type "If" -Line 3
    New-MockControlStructure -Type "If" -Line 4
    New-MockControlStructure -Type "If" -Line 5
)

Test-ComplexityScenario -Name "Structures imbriquées" -ControlStructures $nestedStructures -ExpectedScore 6.6

# Test 8: Cas complexe
$complexStructures = @(
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

Test-ComplexityScenario -Name "Cas complexe" -ControlStructures $complexStructures -ExpectedScore 23

Write-Host "`nTests terminés." -ForegroundColor Yellow
