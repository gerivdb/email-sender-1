#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la détection des types .NET spécifiques à des modules.

.DESCRIPTION
    Ce script teste la fonction Find-DotNetTypeWithoutExplicitImport du module ImplicitModuleDependencyDetector
    qui détecte les types .NET spécifiques à des modules dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# Créer un script PowerShell de test avec différentes références de types .NET
$sampleCode = @'
# Script avec des références à des types .NET de différents modules

# Import explicite du module ActiveDirectory
Import-Module ActiveDirectory

# Références à des types Active Directory
$user = [Microsoft.ActiveDirectory.Management.ADUser]::new()
$group = [Microsoft.ActiveDirectory.Management.ADGroup]::FindByIdentity($null, "Domain Admins")

# Références à des types Azure sans import
$vm = [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]::new()
$network = [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]::new()

# Import explicite du module SqlServer
Import-Module SqlServer

# Références à des types SQL Server
$server = New-Object Microsoft.SqlServer.Management.Smo.Server("localhost")
$database = [Microsoft.SqlServer.Management.Smo.Database]::new()

# Références à des types Pester sans import
$config = [Pester.Runtime.PesterConfiguration]::new()
$result = [Pester.Runtime.TestResult]::new()

# Références à des types dbatools sans import
$backupHistory = [Sqlcollaborative.Dbatools.Database.BackupHistory]::new()
$instanceParam = [Sqlcollaborative.Dbatools.Parameter.DbaInstanceParameter]::new("localhost")

# Références à des types ImportExcel sans import
$excel = [OfficeOpenXml.ExcelPackage]::new()
$worksheet = [OfficeOpenXml.ExcelWorksheet]::new()
'@

Write-Host "=== Test de la détection des types .NET spécifiques à des modules ===" -ForegroundColor Cyan

# Test 1: Détecter les types .NET sans import explicite
Write-Host "`nTest 1: Détecter les types .NET sans import explicite" -ForegroundColor Cyan
$results = Find-DotNetTypeWithoutExplicitImport -ScriptContent $sampleCode

Write-Host "  Types .NET détectés sans import explicite:" -ForegroundColor Green
foreach ($result in $results) {
    Write-Host "    $($result.TypeName) (Module: $($result.ModuleName)) - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 2: Détecter tous les types .NET, y compris ceux des modules importés
Write-Host "`nTest 2: Détecter tous les types .NET, y compris ceux des modules importés" -ForegroundColor Cyan
$allResults = Find-DotNetTypeWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

Write-Host "  Tous les types .NET détectés:" -ForegroundColor Green
foreach ($result in $allResults) {
    $importStatus = if ($result.IsImported) { "Module importé" } else { "Module non importé" }
    Write-Host "    $($result.TypeName) (Module: $($result.ModuleName)) - $importStatus - Ligne $($result.LineNumber)" -ForegroundColor Gray
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

# Test 4: Vérifier les différentes façons de référencer des types
Write-Host "`nTest 4: Vérifier les différentes façons de référencer des types" -ForegroundColor Cyan
$newObjectTypes = $allResults | Where-Object { $_.PSObject.Properties.Name -contains "Source" -and $_.Source -eq "New-Object" }
$staticMemberTypes = $allResults | Where-Object { $_.PSObject.Properties.Name -contains "Member" }
$otherTypes = $allResults | Where-Object { 
    -not ($_.PSObject.Properties.Name -contains "Source" -and $_.Source -eq "New-Object") -and
    -not ($_.PSObject.Properties.Name -contains "Member")
}

Write-Host "  Types référencés via New-Object:" -ForegroundColor Green
foreach ($type in $newObjectTypes) {
    Write-Host "    $($type.TypeName) - Ligne $($type.LineNumber)" -ForegroundColor Gray
}

Write-Host "  Types référencés via membres statiques:" -ForegroundColor Green
foreach ($type in $staticMemberTypes) {
    Write-Host "    $($type.TypeName)::$($type.Member) - Ligne $($type.LineNumber)" -ForegroundColor Gray
}

Write-Host "  Types référencés d'autres façons:" -ForegroundColor Green
foreach ($type in $otherTypes) {
    Write-Host "    $($type.TypeName) - Ligne $($type.LineNumber)" -ForegroundColor Gray
}

Write-Host "`nTests terminés avec succès!" -ForegroundColor Green
