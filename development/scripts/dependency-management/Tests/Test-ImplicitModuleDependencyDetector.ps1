#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le module ImplicitModuleDependencyDetector.

.DESCRIPTION
    Ce script teste les fonctionnalités du module ImplicitModuleDependencyDetector
    qui détecte les modules requis implicitement dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# Créer un script PowerShell de test avec différentes cmdlets
$sampleCode = @'
# Script avec des cmdlets de différents modules

# Cmdlets Active Directory sans import
Get-ADUser -Filter {Name -eq "John Doe"}
Set-ADUser -Identity "John Doe" -Enabled $true

# Import explicite du module SqlServer
Import-Module SqlServer
Invoke-Sqlcmd -Query "SELECT * FROM Users"

# Cmdlets Pester sans import
Describe "Test Suite" {
    Context "Test Context" {
        It "Should pass" {
            $true | Should -Be $true
        }
    }
}

# Cmdlets Azure sans import
Get-AzVM -Name "MyVM"
Start-AzVM -Name "MyVM" -ResourceGroupName "MyRG"

# Import explicite du module dbatools
Import-Module dbatools
Get-DbaDatabase -SqlInstance "MyServer"

# Cmdlets PSScriptAnalyzer sans import
Invoke-ScriptAnalyzer -Path "C:\Scripts\MyScript.ps1"
'@

Write-Host "=== Test du module ImplicitModuleDependencyDetector ===" -ForegroundColor Cyan

# Test 1: Détecter les cmdlets sans import explicite
Write-Host "`nTest 1: Détecter les cmdlets sans import explicite" -ForegroundColor Cyan
$results = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode

Write-Host "  Cmdlets détectées sans import explicite:" -ForegroundColor Green
foreach ($result in $results) {
    Write-Host "    $($result.CmdletName) (Module: $($result.ModuleName)) - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 2: Détecter toutes les cmdlets, y compris celles des modules importés
Write-Host "`nTest 2: Détecter toutes les cmdlets, y compris celles des modules importés" -ForegroundColor Cyan
$allResults = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

Write-Host "  Toutes les cmdlets détectées:" -ForegroundColor Green
foreach ($result in $allResults) {
    $importStatus = if ($result.IsImported) { "Module importé" } else { "Module non importé" }
    Write-Host "    $($result.CmdletName) (Module: $($result.ModuleName)) - $importStatus - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 3: Vérifier la détection des imports explicites
Write-Host "`nTest 3: Vérifier la détection des imports explicites" -ForegroundColor Cyan
$importedModules = $allResults | Where-Object { $_.IsImported } | Select-Object -ExpandProperty ModuleName -Unique
$nonImportedModules = $allResults | Where-Object { -not $_.IsImported } | Select-Object -ExpandProperty ModuleName -Unique

Write-Host "  Modules importés explicitement:" -ForegroundColor Green
foreach ($module in $importedModules) {
    Write-Host "    $module" -ForegroundColor Gray
}

Write-Host "  Modules non importés:" -ForegroundColor Green
foreach ($module in $nonImportedModules) {
    Write-Host "    $module" -ForegroundColor Gray
}

Write-Host "`nTests terminés avec succès!" -ForegroundColor Green
