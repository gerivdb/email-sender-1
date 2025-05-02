#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiés pour le mécanisme de scoring des dépendances de modules.

.DESCRIPTION
    Ce script teste les fonctions Get-ModuleDependencyScore et Find-ImplicitModuleDependency
    du module ImplicitModuleDependencyDetector de manière simplifiée.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Write-Host "Module path: $modulePath"

if (-not (Test-Path -Path $modulePath)) {
    throw "Module not found at path: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force -ErrorAction Stop

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

Write-Host "=== Test du mécanisme de scoring des dépendances de modules (version simplifiée) ===" -ForegroundColor Cyan

# Test 1: Détecter les cmdlets sans import explicite
Write-Host "`nTest 1: Détecter les cmdlets sans import explicite" -ForegroundColor Cyan
$cmdletReferences = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules
Write-Host "  Cmdlets détectées: $($cmdletReferences.Count)" -ForegroundColor Green
foreach ($ref in $cmdletReferences | Select-Object -First 5) {
    Write-Host "    $($ref.CmdletName) - Module: $($ref.ModuleName) - Importé: $($ref.IsImported)" -ForegroundColor Gray
}
if ($cmdletReferences.Count -gt 5) {
    Write-Host "    ... et $($cmdletReferences.Count - 5) autres" -ForegroundColor Gray
}

# Test 2: Détecter les types .NET sans import explicite
Write-Host "`nTest 2: Détecter les types .NET sans import explicite" -ForegroundColor Cyan
$typeReferences = Find-DotNetTypeWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules
Write-Host "  Types détectés: $($typeReferences.Count)" -ForegroundColor Green
foreach ($ref in $typeReferences | Select-Object -First 5) {
    Write-Host "    $($ref.TypeName) - Module: $($ref.ModuleName) - Importé: $($ref.IsImported)" -ForegroundColor Gray
}
if ($typeReferences.Count -gt 5) {
    Write-Host "    ... et $($typeReferences.Count - 5) autres" -ForegroundColor Gray
}

# Test 3: Détecter les variables globales sans import explicite
Write-Host "`nTest 3: Détecter les variables globales sans import explicite" -ForegroundColor Cyan
$variableReferences = Find-GlobalVariableWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules
Write-Host "  Variables détectées: $($variableReferences.Count)" -ForegroundColor Green
foreach ($ref in $variableReferences | Select-Object -First 5) {
    Write-Host "    $($ref.VariableName) - Module: $($ref.ModuleName) - Importé: $($ref.IsImported)" -ForegroundColor Gray
}
if ($variableReferences.Count -gt 5) {
    Write-Host "    ... et $($variableReferences.Count - 5) autres" -ForegroundColor Gray
}

# Test 4: Calculer les scores de dépendance
Write-Host "`nTest 4: Calculer les scores de dépendance" -ForegroundColor Cyan
$scores = Get-ModuleDependencyScore -CmdletReferences $cmdletReferences -TypeReferences $typeReferences -VariableReferences $variableReferences -IncludeDetails
Write-Host "  Scores de dépendance calculés: $($scores.Count)" -ForegroundColor Green
foreach ($score in $scores) {
    $requiredStatus = if ($score.IsProbablyRequired) { "Probablement requis" } else { "Probablement pas requis" }
    Write-Host "    $($score.ModuleName) - Score: $($score.Score) - $requiredStatus" -ForegroundColor Gray
    Write-Host "      Références: $($score.TotalReferences) (Cmdlets: $($score.CmdletReferences), Types: $($score.TypeReferences), Variables: $($score.VariableReferences))" -ForegroundColor Gray
    
    if ($score.PSObject.Properties.Name -contains "BaseScore") {
        Write-Host "      Détails: BaseScore=$($score.BaseScore), WeightedScore=$($score.WeightedScore), DiversityScore=$($score.DiversityScore)" -ForegroundColor Gray
    }
}

# Test 5: Utiliser la fonction combinée Find-ImplicitModuleDependency
Write-Host "`nTest 5: Utiliser la fonction combinée Find-ImplicitModuleDependency" -ForegroundColor Cyan
$implicitDependencies = Find-ImplicitModuleDependency -ScriptContent $sampleCode -IncludeImportedModules -IncludeDetails
Write-Host "  Dépendances implicites détectées: $($implicitDependencies.Count)" -ForegroundColor Green
foreach ($dep in $implicitDependencies) {
    $requiredStatus = if ($dep.IsProbablyRequired) { "Probablement requis" } else { "Probablement pas requis" }
    Write-Host "    $($dep.ModuleName) - Score: $($dep.Score) - $requiredStatus" -ForegroundColor Gray
    Write-Host "      Références: $($dep.TotalReferences) (Cmdlets: $($dep.CmdletReferences), Types: $($dep.TypeReferences), Variables: $($dep.VariableReferences))" -ForegroundColor Gray
}

# Test 6: Tester différents seuils de score
Write-Host "`nTest 6: Tester différents seuils de score" -ForegroundColor Cyan
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

# Test 7: Créer une base de données de correspondance
Write-Host "`nTest 7: Créer une base de données de correspondance" -ForegroundColor Cyan
$tempDir = Join-Path -Path $env:TEMP -ChildPath "ModuleMappingTests_$(Get-Random)"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
$databasePath = Join-Path -Path $tempDir -ChildPath "ModuleMapping.psd1"

try {
    $moduleNames = @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility")
    $database = New-ModuleMappingDatabase -ModuleNames $moduleNames -OutputPath $databasePath -IncludeCmdlets -IncludeTypes:$false -IncludeVariables:$false
    
    if (Test-Path -Path $databasePath) {
        Write-Host "  Base de données créée avec succès: $databasePath" -ForegroundColor Green
        $content = Get-Content -Path $databasePath -Raw
        if ($content -match "CmdletToModuleMapping") {
            Write-Host "  La base de données contient les sections attendues" -ForegroundColor Green
        } else {
            Write-Host "  La base de données ne contient pas les sections attendues" -ForegroundColor Red
        }
    } else {
        Write-Host "  Échec de la création de la base de données" -ForegroundColor Red
    }
} finally {
    # Nettoyer
    if (Test-Path -Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

Write-Host "`nTests terminés avec succès!" -ForegroundColor Green
