#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le module ImplicitModuleDependencyDetector.

.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s du module ImplicitModuleDependencyDetector
    qui dÃ©tecte les modules requis implicitement dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell de test avec diffÃ©rentes cmdlets
$sampleCode = @'
# Script avec des cmdlets de diffÃ©rents modules

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

# Test 1: DÃ©tecter les cmdlets sans import explicite
Write-Host "`nTest 1: DÃ©tecter les cmdlets sans import explicite" -ForegroundColor Cyan
$results = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode

Write-Host "  Cmdlets dÃ©tectÃ©es sans import explicite:" -ForegroundColor Green
foreach ($result in $results) {
    Write-Host "    $($result.CmdletName) (Module: $($result.ModuleName)) - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 2: DÃ©tecter toutes les cmdlets, y compris celles des modules importÃ©s
Write-Host "`nTest 2: DÃ©tecter toutes les cmdlets, y compris celles des modules importÃ©s" -ForegroundColor Cyan
$allResults = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

Write-Host "  Toutes les cmdlets dÃ©tectÃ©es:" -ForegroundColor Green
foreach ($result in $allResults) {
    $importStatus = if ($result.IsImported) { "Module importÃ©" } else { "Module non importÃ©" }
    Write-Host "    $($result.CmdletName) (Module: $($result.ModuleName)) - $importStatus - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 3: VÃ©rifier la dÃ©tection des imports explicites
Write-Host "`nTest 3: VÃ©rifier la dÃ©tection des imports explicites" -ForegroundColor Cyan
$importedModules = $allResults | Where-Object { $_.IsImported } | Select-Object -ExpandProperty ModuleName -Unique
$nonImportedModules = $allResults | Where-Object { -not $_.IsImported } | Select-Object -ExpandProperty ModuleName -Unique

Write-Host "  Modules importÃ©s explicitement:" -ForegroundColor Green
foreach ($module in $importedModules) {
    Write-Host "    $module" -ForegroundColor Gray
}

Write-Host "  Modules non importÃ©s:" -ForegroundColor Green
foreach ($module in $nonImportedModules) {
    Write-Host "    $module" -ForegroundColor Gray
}

Write-Host "`nTests terminÃ©s avec succÃ¨s!" -ForegroundColor Green
