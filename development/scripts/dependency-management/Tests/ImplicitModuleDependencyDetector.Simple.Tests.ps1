#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour le module ImplicitModuleDependencyDetector.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour le module ImplicitModuleDependencyDetector
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

# CrÃ©er un fichier temporaire pour les tests
$tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
Set-Content -Path $tempFile -Value $sampleCode

Write-Host "=== Tests unitaires simplifiÃ©s pour ImplicitModuleDependencyDetector ===" -ForegroundColor Cyan

# Test 1: DÃ©tecter les cmdlets sans import explicite
Write-Host "`nTest 1: DÃ©tecter les cmdlets sans import explicite" -ForegroundColor Cyan
$results = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode
$adCmdlets = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
$pesterCmdlets = $results | Where-Object { $_.ModuleName -eq "Pester" }
$azCmdlets = $results | Where-Object { $_.ModuleName -eq "Az.Compute" }
$psaCmdlets = $results | Where-Object { $_.ModuleName -eq "PSScriptAnalyzer" }
$sqlCmdlets = $results | Where-Object { $_.ModuleName -eq "SqlServer" }
$dbaCmdlets = $results | Where-Object { $_.ModuleName -eq "dbatools" }

$testsPassed = $true

# VÃ©rifier les cmdlets Active Directory
if ($adCmdlets -and $adCmdlets.Count -ge 2 -and 
    $adCmdlets.CmdletName -contains "Get-ADUser" -and 
    $adCmdlets.CmdletName -contains "Set-ADUser") {
    Write-Host "  âœ“ DÃ©tection des cmdlets Active Directory sans import" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la dÃ©tection des cmdlets Active Directory sans import" -ForegroundColor Red
    $testsPassed = $false
}

# VÃ©rifier les cmdlets Pester
if ($pesterCmdlets -and $pesterCmdlets.Count -ge 4 -and 
    $pesterCmdlets.CmdletName -contains "Describe" -and 
    $pesterCmdlets.CmdletName -contains "Context" -and
    $pesterCmdlets.CmdletName -contains "It" -and
    $pesterCmdlets.CmdletName -contains "Should") {
    Write-Host "  âœ“ DÃ©tection des cmdlets Pester sans import" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la dÃ©tection des cmdlets Pester sans import" -ForegroundColor Red
    $testsPassed = $false
}

# VÃ©rifier les cmdlets Azure
if ($azCmdlets -and $azCmdlets.Count -ge 2 -and 
    $azCmdlets.CmdletName -contains "Get-AzVM" -and 
    $azCmdlets.CmdletName -contains "Start-AzVM") {
    Write-Host "  âœ“ DÃ©tection des cmdlets Azure sans import" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la dÃ©tection des cmdlets Azure sans import" -ForegroundColor Red
    $testsPassed = $false
}

# VÃ©rifier les cmdlets PSScriptAnalyzer
if ($psaCmdlets -and $psaCmdlets.Count -ge 1 -and 
    $psaCmdlets.CmdletName -contains "Invoke-ScriptAnalyzer") {
    Write-Host "  âœ“ DÃ©tection des cmdlets PSScriptAnalyzer sans import" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la dÃ©tection des cmdlets PSScriptAnalyzer sans import" -ForegroundColor Red
    $testsPassed = $false
}

# VÃ©rifier que les cmdlets SqlServer ne sont pas dÃ©tectÃ©es comme non importÃ©es
if (-not $sqlCmdlets) {
    Write-Host "  âœ“ Les cmdlets SqlServer ne sont pas dÃ©tectÃ©es comme non importÃ©es" -ForegroundColor Green
} else {
    Write-Host "  âœ— Les cmdlets SqlServer sont incorrectement dÃ©tectÃ©es comme non importÃ©es" -ForegroundColor Red
    $testsPassed = $false
}

# VÃ©rifier que les cmdlets dbatools ne sont pas dÃ©tectÃ©es comme non importÃ©es
if (-not $dbaCmdlets) {
    Write-Host "  âœ“ Les cmdlets dbatools ne sont pas dÃ©tectÃ©es comme non importÃ©es" -ForegroundColor Green
} else {
    Write-Host "  âœ— Les cmdlets dbatools sont incorrectement dÃ©tectÃ©es comme non importÃ©es" -ForegroundColor Red
    $testsPassed = $false
}

# Test 2: DÃ©tecter toutes les cmdlets, y compris celles des modules importÃ©s
Write-Host "`nTest 2: DÃ©tecter toutes les cmdlets, y compris celles des modules importÃ©s" -ForegroundColor Cyan
$allResults = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules
$sqlCmdletsWithImport = $allResults | Where-Object { $_.ModuleName -eq "SqlServer" }
$dbaCmdletsWithImport = $allResults | Where-Object { $_.ModuleName -eq "dbatools" }

# VÃ©rifier que les cmdlets SqlServer sont dÃ©tectÃ©es avec le paramÃ¨tre IncludeImportedModules
if ($sqlCmdletsWithImport -and $sqlCmdletsWithImport.Count -ge 1 -and 
    $sqlCmdletsWithImport.CmdletName -contains "Invoke-Sqlcmd" -and
    $sqlCmdletsWithImport.IsImported -eq $true) {
    Write-Host "  âœ“ DÃ©tection des cmdlets SqlServer avec IncludeImportedModules" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la dÃ©tection des cmdlets SqlServer avec IncludeImportedModules" -ForegroundColor Red
    $testsPassed = $false
}

# VÃ©rifier que les cmdlets dbatools sont dÃ©tectÃ©es avec le paramÃ¨tre IncludeImportedModules
if ($dbaCmdletsWithImport -and $dbaCmdletsWithImport.Count -ge 1 -and 
    $dbaCmdletsWithImport.CmdletName -contains "Get-DbaDatabase" -and
    $dbaCmdletsWithImport.IsImported -eq $true) {
    Write-Host "  âœ“ DÃ©tection des cmdlets dbatools avec IncludeImportedModules" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la dÃ©tection des cmdlets dbatools avec IncludeImportedModules" -ForegroundColor Red
    $testsPassed = $false
}

# Test 3: Tester avec un fichier comme entrÃ©e
Write-Host "`nTest 3: Tester avec un fichier comme entrÃ©e" -ForegroundColor Cyan
$fileResults = Find-CmdletWithoutExplicitImport -FilePath $tempFile

if ($fileResults -and $fileResults.Count -gt 0) {
    Write-Host "  âœ“ DÃ©tection des cmdlets Ã  partir d'un fichier" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la dÃ©tection des cmdlets Ã  partir d'un fichier" -ForegroundColor Red
    $testsPassed = $false
}

# Test 4: Tester avec un fichier inexistant
Write-Host "`nTest 4: Tester avec un fichier inexistant" -ForegroundColor Cyan
$nonExistentResults = Find-CmdletWithoutExplicitImport -FilePath "C:\NonExistentFile.ps1" -ErrorAction SilentlyContinue

if (-not $nonExistentResults -or $nonExistentResults.Count -eq 0) {
    Write-Host "  âœ“ Gestion correcte d'un fichier inexistant" -ForegroundColor Green
} else {
    Write-Host "  âœ— Ã‰chec de la gestion d'un fichier inexistant" -ForegroundColor Red
    $testsPassed = $false
}

# Nettoyer
if (Test-Path -Path $tempFile) {
    Remove-Item -Path $tempFile -Force
}

# RÃ©sultat final
if ($testsPassed) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©!" -ForegroundColor Red
}

# Retourner le rÃ©sultat pour l'intÃ©gration continue
return $testsPassed
