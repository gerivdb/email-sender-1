#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le mÃ©canisme de scoring des dÃ©pendances de modules.

.DESCRIPTION
    Ce script teste les fonctions Get-ModuleDependencyScore et Find-ImplicitModuleDependency
    du module ImplicitModuleDependencyDetector.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell de test avec diffÃ©rentes rÃ©fÃ©rences
$sampleCode = @'
# Script avec des rÃ©fÃ©rences Ã  diffÃ©rents modules

# Import explicite du module ActiveDirectory
Import-Module ActiveDirectory

# RÃ©fÃ©rences Ã  Active Directory
$user = [Microsoft.ActiveDirectory.Management.ADUser]::new()
$group = Get-ADGroup -Identity "Domain Admins"
$settings = $ADServerSettings

# RÃ©fÃ©rences Ã  Azure sans import
$vm = [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]::new()
$network = [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]::new()
Get-AzVM -Name "MyVM"
Start-AzVM -Name "MyVM" -ResourceGroupName "MyRG"
$context = $AzContext

# RÃ©fÃ©rences Ã  Pester sans import
Describe "Test Suite" {
    Context "Test Context" {
        It "Should pass" {
            $true | Should -Be $true
        }
    }
}
$config = $PesterPreference

# RÃ©fÃ©rences Ã  dbatools sans import (une seule rÃ©fÃ©rence)
$backupHistory = [Sqlcollaborative.Dbatools.Database.BackupHistory]::new()

# RÃ©fÃ©rences Ã  PSScriptAnalyzer sans import (une seule rÃ©fÃ©rence)
Invoke-ScriptAnalyzer -Path "C:\Scripts\MyScript.ps1"
'@

Write-Host "=== Test du mÃ©canisme de scoring des dÃ©pendances de modules ===" -ForegroundColor Cyan

# Test 1: Calculer les scores de dÃ©pendance Ã  partir des rÃ©sultats des fonctions de dÃ©tection
Write-Host "`nTest 1: Calculer les scores de dÃ©pendance Ã  partir des rÃ©sultats des fonctions de dÃ©tection" -ForegroundColor Cyan

# DÃ©tecter les rÃ©fÃ©rences de cmdlets
$cmdletReferences = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

# DÃ©tecter les rÃ©fÃ©rences de types .NET
$typeReferences = Find-DotNetTypeWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

# DÃ©tecter les rÃ©fÃ©rences de variables globales
$variableReferences = Find-GlobalVariableWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

# Calculer les scores de dÃ©pendance
$scores = Get-ModuleDependencyScore -CmdletReferences $cmdletReferences -TypeReferences $typeReferences -VariableReferences $variableReferences -IncludeDetails

Write-Host "  Scores de dÃ©pendance calculÃ©s:" -ForegroundColor Green
foreach ($score in $scores) {
    $requiredStatus = if ($score.IsProbablyRequired) { "Probablement requis" } else { "Probablement pas requis" }
    Write-Host "    $($score.ModuleName) - Score: $($score.Score) - $requiredStatus" -ForegroundColor Gray
    Write-Host "      RÃ©fÃ©rences: $($score.TotalReferences) (Cmdlets: $($score.CmdletReferences), Types: $($score.TypeReferences), Variables: $($score.VariableReferences))" -ForegroundColor Gray
    
    if ($score.PSObject.Properties.Name -contains "BaseScore") {
        Write-Host "      DÃ©tails: BaseScore=$($score.BaseScore), WeightedScore=$($score.WeightedScore), DiversityScore=$($score.DiversityScore)" -ForegroundColor Gray
    }
}

# Test 2: Utiliser la fonction combinÃ©e Find-ImplicitModuleDependency
Write-Host "`nTest 2: Utiliser la fonction combinÃ©e Find-ImplicitModuleDependency" -ForegroundColor Cyan
$implicitDependencies = Find-ImplicitModuleDependency -ScriptContent $sampleCode -IncludeImportedModules -IncludeDetails

Write-Host "  DÃ©pendances implicites dÃ©tectÃ©es:" -ForegroundColor Green
foreach ($dep in $implicitDependencies) {
    $requiredStatus = if ($dep.IsProbablyRequired) { "Probablement requis" } else { "Probablement pas requis" }
    Write-Host "    $($dep.ModuleName) - Score: $($dep.Score) - $requiredStatus" -ForegroundColor Gray
    Write-Host "      RÃ©fÃ©rences: $($dep.TotalReferences) (Cmdlets: $($dep.CmdletReferences), Types: $($dep.TypeReferences), Variables: $($dep.VariableReferences))" -ForegroundColor Gray
    
    if ($dep.PSObject.Properties.Name -contains "BaseScore") {
        Write-Host "      DÃ©tails: BaseScore=$($dep.BaseScore), WeightedScore=$($dep.WeightedScore), DiversityScore=$($dep.DiversityScore)" -ForegroundColor Gray
    }
}

# Test 3: Tester diffÃ©rents seuils de score
Write-Host "`nTest 3: Tester diffÃ©rents seuils de score" -ForegroundColor Cyan
$thresholds = @(0.3, 0.5, 0.7)

foreach ($threshold in $thresholds) {
    Write-Host "  Seuil de score: $threshold" -ForegroundColor Green
    $thresholdDependencies = Find-ImplicitModuleDependency -ScriptContent $sampleCode -ScoreThreshold $threshold
    
    $requiredModules = $thresholdDependencies | Where-Object { $_.IsProbablyRequired }
    Write-Host "    Modules probablement requis:" -ForegroundColor Gray
    foreach ($module in $requiredModules) {
        Write-Host "      $($module.ModuleName) - Score: $($module.Score)" -ForegroundColor Gray
    }
}

# Test 4: Exclure les modules dÃ©jÃ  importÃ©s
Write-Host "`nTest 4: Exclure les modules dÃ©jÃ  importÃ©s" -ForegroundColor Cyan
$nonImportedDependencies = Find-ImplicitModuleDependency -ScriptContent $sampleCode

Write-Host "  DÃ©pendances implicites sans modules importÃ©s:" -ForegroundColor Green
foreach ($dep in $nonImportedDependencies) {
    Write-Host "    $($dep.ModuleName) - Score: $($dep.Score) - RÃ©fÃ©rences: $($dep.TotalReferences)" -ForegroundColor Gray
}

Write-Host "`nTests terminÃ©s avec succÃ¨s!" -ForegroundColor Green
