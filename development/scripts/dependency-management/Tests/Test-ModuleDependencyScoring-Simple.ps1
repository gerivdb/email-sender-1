#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiÃ©s pour le mÃ©canisme de scoring des dÃ©pendances de modules.

.DESCRIPTION
    Ce script teste les fonctions Get-ModuleDependencyScore et Find-ImplicitModuleDependency
    du module ImplicitModuleDependencyDetector de maniÃ¨re simplifiÃ©e.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Write-Host "Module path: $modulePath"

if (-not (Test-Path -Path $modulePath)) {
    throw "Module not found at path: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force -ErrorAction Stop

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

Write-Host "=== Test du mÃ©canisme de scoring des dÃ©pendances de modules (version simplifiÃ©e) ===" -ForegroundColor Cyan

# Test 1: DÃ©tecter les cmdlets sans import explicite
Write-Host "`nTest 1: DÃ©tecter les cmdlets sans import explicite" -ForegroundColor Cyan
$cmdletReferences = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules
Write-Host "  Cmdlets dÃ©tectÃ©es: $($cmdletReferences.Count)" -ForegroundColor Green
foreach ($ref in $cmdletReferences | Select-Object -First 5) {
    Write-Host "    $($ref.CmdletName) - Module: $($ref.ModuleName) - ImportÃ©: $($ref.IsImported)" -ForegroundColor Gray
}
if ($cmdletReferences.Count -gt 5) {
    Write-Host "    ... et $($cmdletReferences.Count - 5) autres" -ForegroundColor Gray
}

# Test 2: DÃ©tecter les types .NET sans import explicite
Write-Host "`nTest 2: DÃ©tecter les types .NET sans import explicite" -ForegroundColor Cyan
$typeReferences = Find-DotNetTypeWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules
Write-Host "  Types dÃ©tectÃ©s: $($typeReferences.Count)" -ForegroundColor Green
foreach ($ref in $typeReferences | Select-Object -First 5) {
    Write-Host "    $($ref.TypeName) - Module: $($ref.ModuleName) - ImportÃ©: $($ref.IsImported)" -ForegroundColor Gray
}
if ($typeReferences.Count -gt 5) {
    Write-Host "    ... et $($typeReferences.Count - 5) autres" -ForegroundColor Gray
}

# Test 3: DÃ©tecter les variables globales sans import explicite
Write-Host "`nTest 3: DÃ©tecter les variables globales sans import explicite" -ForegroundColor Cyan
$variableReferences = Find-GlobalVariableWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules
Write-Host "  Variables dÃ©tectÃ©es: $($variableReferences.Count)" -ForegroundColor Green
foreach ($ref in $variableReferences | Select-Object -First 5) {
    Write-Host "    $($ref.VariableName) - Module: $($ref.ModuleName) - ImportÃ©: $($ref.IsImported)" -ForegroundColor Gray
}
if ($variableReferences.Count -gt 5) {
    Write-Host "    ... et $($variableReferences.Count - 5) autres" -ForegroundColor Gray
}

# Test 4: Calculer les scores de dÃ©pendance
Write-Host "`nTest 4: Calculer les scores de dÃ©pendance" -ForegroundColor Cyan
$scores = Get-ModuleDependencyScore -CmdletReferences $cmdletReferences -TypeReferences $typeReferences -VariableReferences $variableReferences -IncludeDetails
Write-Host "  Scores de dÃ©pendance calculÃ©s: $($scores.Count)" -ForegroundColor Green
foreach ($score in $scores) {
    $requiredStatus = if ($score.IsProbablyRequired) { "Probablement requis" } else { "Probablement pas requis" }
    Write-Host "    $($score.ModuleName) - Score: $($score.Score) - $requiredStatus" -ForegroundColor Gray
    Write-Host "      RÃ©fÃ©rences: $($score.TotalReferences) (Cmdlets: $($score.CmdletReferences), Types: $($score.TypeReferences), Variables: $($score.VariableReferences))" -ForegroundColor Gray
    
    if ($score.PSObject.Properties.Name -contains "BaseScore") {
        Write-Host "      DÃ©tails: BaseScore=$($score.BaseScore), WeightedScore=$($score.WeightedScore), DiversityScore=$($score.DiversityScore)" -ForegroundColor Gray
    }
}

# Test 5: Utiliser la fonction combinÃ©e Find-ImplicitModuleDependency
Write-Host "`nTest 5: Utiliser la fonction combinÃ©e Find-ImplicitModuleDependency" -ForegroundColor Cyan
$implicitDependencies = Find-ImplicitModuleDependency -ScriptContent $sampleCode -IncludeImportedModules -IncludeDetails
Write-Host "  DÃ©pendances implicites dÃ©tectÃ©es: $($implicitDependencies.Count)" -ForegroundColor Green
foreach ($dep in $implicitDependencies) {
    $requiredStatus = if ($dep.IsProbablyRequired) { "Probablement requis" } else { "Probablement pas requis" }
    Write-Host "    $($dep.ModuleName) - Score: $($dep.Score) - $requiredStatus" -ForegroundColor Gray
    Write-Host "      RÃ©fÃ©rences: $($dep.TotalReferences) (Cmdlets: $($dep.CmdletReferences), Types: $($dep.TypeReferences), Variables: $($dep.VariableReferences))" -ForegroundColor Gray
}

# Test 6: Tester diffÃ©rents seuils de score
Write-Host "`nTest 6: Tester diffÃ©rents seuils de score" -ForegroundColor Cyan
$thresholds = @(0.3, 0.5, 0.7)

foreach ($threshold in $thresholds) {
    Write-Host "  Seuil de score: $threshold" -ForegroundColor Green
    $thresholdDependencies = Find-ImplicitModuleDependency -ScriptContent $sampleCode -ScoreThreshold $threshold
    
    $requiredModules = $thresholdDependencies | Where-Object { $_.IsProbablyRequired }
    Write-Host "    Modules probablement requis: $($requiredModules.Count)" -ForegroundColor Gray
    foreach ($module in $requiredModules) {
        Write-Host "      $($module.ModuleName) - Score: $($module.Score)" -ForegroundColor Gray
    }
}

# Test 7: CrÃ©er une base de donnÃ©es de correspondance
Write-Host "`nTest 7: CrÃ©er une base de donnÃ©es de correspondance" -ForegroundColor Cyan
$tempDir = Join-Path -Path $env:TEMP -ChildPath "ModuleMappingTests_$(Get-Random)"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
$databasePath = Join-Path -Path $tempDir -ChildPath "ModuleMapping.psd1"

try {
    $moduleNames = @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility")
    $database = New-ModuleMappingDatabase -ModuleNames $moduleNames -OutputPath $databasePath -IncludeCmdlets -IncludeTypes:$false -IncludeVariables:$false
    
    if (Test-Path -Path $databasePath) {
        Write-Host "  Base de donnÃ©es crÃ©Ã©e avec succÃ¨s: $databasePath" -ForegroundColor Green
        $content = Get-Content -Path $databasePath -Raw
        if ($content -match "CmdletToModuleMapping") {
            Write-Host "  La base de donnÃ©es contient les sections attendues" -ForegroundColor Green
        } else {
            Write-Host "  La base de donnÃ©es ne contient pas les sections attendues" -ForegroundColor Red
        }
    } else {
        Write-Host "  Ã‰chec de la crÃ©ation de la base de donnÃ©es" -ForegroundColor Red
    }
} finally {
    # Nettoyer
    if (Test-Path -Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

Write-Host "`nTests terminÃ©s avec succÃ¨s!" -ForegroundColor Green
