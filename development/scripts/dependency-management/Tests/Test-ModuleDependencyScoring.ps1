#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le mécanisme de scoring des dépendances de modules.

.DESCRIPTION
    Ce script teste les fonctions Get-ModuleDependencyScore et Find-ImplicitModuleDependency
    du module ImplicitModuleDependencyDetector.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# Créer un script PowerShell de test avec différentes références
$sampleCode = @'
# Script avec des références à différents modules

# Import explicite du module ActiveDirectory
Import-Module ActiveDirectory

# Références à Active Directory
$user = [Microsoft.ActiveDirectory.Management.ADUser]::new()
$group = Get-ADGroup -Identity "Domain Admins"
$settings = $ADServerSettings

# Références à Azure sans import
$vm = [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]::new()
$network = [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]::new()
Get-AzVM -Name "MyVM"
Start-AzVM -Name "MyVM" -ResourceGroupName "MyRG"
$context = $AzContext

# Références à Pester sans import
Describe "Test Suite" {
    Context "Test Context" {
        It "Should pass" {
            $true | Should -Be $true
        }
    }
}
$config = $PesterPreference

# Références à dbatools sans import (une seule référence)
$backupHistory = [Sqlcollaborative.Dbatools.Database.BackupHistory]::new()

# Références à PSScriptAnalyzer sans import (une seule référence)
Invoke-ScriptAnalyzer -Path "C:\Scripts\MyScript.ps1"
'@

Write-Host "=== Test du mécanisme de scoring des dépendances de modules ===" -ForegroundColor Cyan

# Test 1: Calculer les scores de dépendance à partir des résultats des fonctions de détection
Write-Host "`nTest 1: Calculer les scores de dépendance à partir des résultats des fonctions de détection" -ForegroundColor Cyan

# Détecter les références de cmdlets
$cmdletReferences = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

# Détecter les références de types .NET
$typeReferences = Find-DotNetTypeWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

# Détecter les références de variables globales
$variableReferences = Find-GlobalVariableWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

# Calculer les scores de dépendance
$scores = Get-ModuleDependencyScore -CmdletReferences $cmdletReferences -TypeReferences $typeReferences -VariableReferences $variableReferences -IncludeDetails

Write-Host "  Scores de dépendance calculés:" -ForegroundColor Green
foreach ($score in $scores) {
    $requiredStatus = if ($score.IsProbablyRequired) { "Probablement requis" } else { "Probablement pas requis" }
    Write-Host "    $($score.ModuleName) - Score: $($score.Score) - $requiredStatus" -ForegroundColor Gray
    Write-Host "      Références: $($score.TotalReferences) (Cmdlets: $($score.CmdletReferences), Types: $($score.TypeReferences), Variables: $($score.VariableReferences))" -ForegroundColor Gray
    
    if ($score.PSObject.Properties.Name -contains "BaseScore") {
        Write-Host "      Détails: BaseScore=$($score.BaseScore), WeightedScore=$($score.WeightedScore), DiversityScore=$($score.DiversityScore)" -ForegroundColor Gray
    }
}

# Test 2: Utiliser la fonction combinée Find-ImplicitModuleDependency
Write-Host "`nTest 2: Utiliser la fonction combinée Find-ImplicitModuleDependency" -ForegroundColor Cyan
$implicitDependencies = Find-ImplicitModuleDependency -ScriptContent $sampleCode -IncludeImportedModules -IncludeDetails

Write-Host "  Dépendances implicites détectées:" -ForegroundColor Green
foreach ($dep in $implicitDependencies) {
    $requiredStatus = if ($dep.IsProbablyRequired) { "Probablement requis" } else { "Probablement pas requis" }
    Write-Host "    $($dep.ModuleName) - Score: $($dep.Score) - $requiredStatus" -ForegroundColor Gray
    Write-Host "      Références: $($dep.TotalReferences) (Cmdlets: $($dep.CmdletReferences), Types: $($dep.TypeReferences), Variables: $($dep.VariableReferences))" -ForegroundColor Gray
    
    if ($dep.PSObject.Properties.Name -contains "BaseScore") {
        Write-Host "      Détails: BaseScore=$($dep.BaseScore), WeightedScore=$($dep.WeightedScore), DiversityScore=$($dep.DiversityScore)" -ForegroundColor Gray
    }
}

# Test 3: Tester différents seuils de score
Write-Host "`nTest 3: Tester différents seuils de score" -ForegroundColor Cyan
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

# Test 4: Exclure les modules déjà importés
Write-Host "`nTest 4: Exclure les modules déjà importés" -ForegroundColor Cyan
$nonImportedDependencies = Find-ImplicitModuleDependency -ScriptContent $sampleCode

Write-Host "  Dépendances implicites sans modules importés:" -ForegroundColor Green
foreach ($dep in $nonImportedDependencies) {
    Write-Host "    $($dep.ModuleName) - Score: $($dep.Score) - Références: $($dep.TotalReferences)" -ForegroundColor Gray
}

Write-Host "`nTests terminés avec succès!" -ForegroundColor Green
