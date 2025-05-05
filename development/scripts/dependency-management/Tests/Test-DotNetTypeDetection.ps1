#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la dÃ©tection des types .NET spÃ©cifiques Ã  des modules.

.DESCRIPTION
    Ce script teste la fonction Find-DotNetTypeWithoutExplicitImport du module ImplicitModuleDependencyDetector
    qui dÃ©tecte les types .NET spÃ©cifiques Ã  des modules dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell de test avec diffÃ©rentes rÃ©fÃ©rences de types .NET
$sampleCode = @'
# Script avec des rÃ©fÃ©rences Ã  des types .NET de diffÃ©rents modules

# Import explicite du module ActiveDirectory
Import-Module ActiveDirectory

# RÃ©fÃ©rences Ã  des types Active Directory
$user = [Microsoft.ActiveDirectory.Management.ADUser]::new()
$group = [Microsoft.ActiveDirectory.Management.ADGroup]::FindByIdentity($null, "Domain Admins")

# RÃ©fÃ©rences Ã  des types Azure sans import
$vm = [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]::new()
$network = [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]::new()

# Import explicite du module SqlServer
Import-Module SqlServer

# RÃ©fÃ©rences Ã  des types SQL Server
$server = New-Object Microsoft.SqlServer.Management.Smo.Server("localhost")
$database = [Microsoft.SqlServer.Management.Smo.Database]::new()

# RÃ©fÃ©rences Ã  des types Pester sans import
$config = [Pester.Runtime.PesterConfiguration]::new()
$result = [Pester.Runtime.TestResult]::new()

# RÃ©fÃ©rences Ã  des types dbatools sans import
$backupHistory = [Sqlcollaborative.Dbatools.Database.BackupHistory]::new()
$instanceParam = [Sqlcollaborative.Dbatools.Parameter.DbaInstanceParameter]::new("localhost")

# RÃ©fÃ©rences Ã  des types ImportExcel sans import
$excel = [OfficeOpenXml.ExcelPackage]::new()
$worksheet = [OfficeOpenXml.ExcelWorksheet]::new()
'@

Write-Host "=== Test de la dÃ©tection des types .NET spÃ©cifiques Ã  des modules ===" -ForegroundColor Cyan

# Test 1: DÃ©tecter les types .NET sans import explicite
Write-Host "`nTest 1: DÃ©tecter les types .NET sans import explicite" -ForegroundColor Cyan
$results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $sampleCode

Write-Host "  Types .NET dÃ©tectÃ©s sans import explicite:" -ForegroundColor Green
foreach ($result in $results) {
    Write-Host "    $($result.TypeName) (Module: $($result.ModuleName)) - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 2: DÃ©tecter tous les types .NET, y compris ceux des modules importÃ©s
Write-Host "`nTest 2: DÃ©tecter tous les types .NET, y compris ceux des modules importÃ©s" -ForegroundColor Cyan
$allResults = Find-DotNetTypeWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

Write-Host "  Tous les types .NET dÃ©tectÃ©s:" -ForegroundColor Green
foreach ($result in $allResults) {
    $importStatus = if ($result.IsImported) { "Module importÃ©" } else { "Module non importÃ©" }
    Write-Host "    $($result.TypeName) (Module: $($result.ModuleName)) - $importStatus - Ligne $($result.LineNumber)" -ForegroundColor Gray
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

# Test 4: VÃ©rifier les diffÃ©rentes faÃ§ons de rÃ©fÃ©rencer des types
Write-Host "`nTest 4: VÃ©rifier les diffÃ©rentes faÃ§ons de rÃ©fÃ©rencer des types" -ForegroundColor Cyan
$newObjectTypes = $allResults | Where-Object { $_.PSObject.Properties.Name -contains "Source" -and $_.Source -eq "New-Object" }
$staticMemberTypes = $allResults | Where-Object { $_.PSObject.Properties.Name -contains "Member" }
$otherTypes = $allResults | Where-Object { 
    -not ($_.PSObject.Properties.Name -contains "Source" -and $_.Source -eq "New-Object") -and
    -not ($_.PSObject.Properties.Name -contains "Member")
}

Write-Host "  Types rÃ©fÃ©rencÃ©s via New-Object:" -ForegroundColor Green
foreach ($type in $newObjectTypes) {
    Write-Host "    $($type.TypeName) - Ligne $($type.LineNumber)" -ForegroundColor Gray
}

Write-Host "  Types rÃ©fÃ©rencÃ©s via membres statiques:" -ForegroundColor Green
foreach ($type in $staticMemberTypes) {
    Write-Host "    $($type.TypeName)::$($type.Member) - Ligne $($type.LineNumber)" -ForegroundColor Gray
}

Write-Host "  Types rÃ©fÃ©rencÃ©s d'autres faÃ§ons:" -ForegroundColor Green
foreach ($type in $otherTypes) {
    Write-Host "    $($type.TypeName) - Ligne $($type.LineNumber)" -ForegroundColor Gray
}

Write-Host "`nTests terminÃ©s avec succÃ¨s!" -ForegroundColor Green
