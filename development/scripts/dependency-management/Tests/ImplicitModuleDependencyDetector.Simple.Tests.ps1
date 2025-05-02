#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiés pour le module ImplicitModuleDependencyDetector.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiés pour le module ImplicitModuleDependencyDetector
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

# Créer un fichier temporaire pour les tests
$tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
Set-Content -Path $tempFile -Value $sampleCode

Write-Host "=== Tests unitaires simplifiés pour ImplicitModuleDependencyDetector ===" -ForegroundColor Cyan

# Test 1: Détecter les cmdlets sans import explicite
Write-Host "`nTest 1: Détecter les cmdlets sans import explicite" -ForegroundColor Cyan
$results = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode
$adCmdlets = $results | Where-Object { $_.ModuleName -eq "ActiveDirectory" }
$pesterCmdlets = $results | Where-Object { $_.ModuleName -eq "Pester" }
$azCmdlets = $results | Where-Object { $_.ModuleName -eq "Az.Compute" }
$psaCmdlets = $results | Where-Object { $_.ModuleName -eq "PSScriptAnalyzer" }
$sqlCmdlets = $results | Where-Object { $_.ModuleName -eq "SqlServer" }
$dbaCmdlets = $results | Where-Object { $_.ModuleName -eq "dbatools" }

$testsPassed = $true

# Vérifier les cmdlets Active Directory
if ($adCmdlets -and $adCmdlets.Count -ge 2 -and 
    $adCmdlets.CmdletName -contains "Get-ADUser" -and 
    $adCmdlets.CmdletName -contains "Set-ADUser") {
    Write-Host "  ✓ Détection des cmdlets Active Directory sans import" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la détection des cmdlets Active Directory sans import" -ForegroundColor Red
    $testsPassed = $false
}

# Vérifier les cmdlets Pester
if ($pesterCmdlets -and $pesterCmdlets.Count -ge 4 -and 
    $pesterCmdlets.CmdletName -contains "Describe" -and 
    $pesterCmdlets.CmdletName -contains "Context" -and
    $pesterCmdlets.CmdletName -contains "It" -and
    $pesterCmdlets.CmdletName -contains "Should") {
    Write-Host "  ✓ Détection des cmdlets Pester sans import" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la détection des cmdlets Pester sans import" -ForegroundColor Red
    $testsPassed = $false
}

# Vérifier les cmdlets Azure
if ($azCmdlets -and $azCmdlets.Count -ge 2 -and 
    $azCmdlets.CmdletName -contains "Get-AzVM" -and 
    $azCmdlets.CmdletName -contains "Start-AzVM") {
    Write-Host "  ✓ Détection des cmdlets Azure sans import" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la détection des cmdlets Azure sans import" -ForegroundColor Red
    $testsPassed = $false
}

# Vérifier les cmdlets PSScriptAnalyzer
if ($psaCmdlets -and $psaCmdlets.Count -ge 1 -and 
    $psaCmdlets.CmdletName -contains "Invoke-ScriptAnalyzer") {
    Write-Host "  ✓ Détection des cmdlets PSScriptAnalyzer sans import" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la détection des cmdlets PSScriptAnalyzer sans import" -ForegroundColor Red
    $testsPassed = $false
}

# Vérifier que les cmdlets SqlServer ne sont pas détectées comme non importées
if (-not $sqlCmdlets) {
    Write-Host "  ✓ Les cmdlets SqlServer ne sont pas détectées comme non importées" -ForegroundColor Green
} else {
    Write-Host "  ✗ Les cmdlets SqlServer sont incorrectement détectées comme non importées" -ForegroundColor Red
    $testsPassed = $false
}

# Vérifier que les cmdlets dbatools ne sont pas détectées comme non importées
if (-not $dbaCmdlets) {
    Write-Host "  ✓ Les cmdlets dbatools ne sont pas détectées comme non importées" -ForegroundColor Green
} else {
    Write-Host "  ✗ Les cmdlets dbatools sont incorrectement détectées comme non importées" -ForegroundColor Red
    $testsPassed = $false
}

# Test 2: Détecter toutes les cmdlets, y compris celles des modules importés
Write-Host "`nTest 2: Détecter toutes les cmdlets, y compris celles des modules importés" -ForegroundColor Cyan
$allResults = Find-CmdletWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules
$sqlCmdletsWithImport = $allResults | Where-Object { $_.ModuleName -eq "SqlServer" }
$dbaCmdletsWithImport = $allResults | Where-Object { $_.ModuleName -eq "dbatools" }

# Vérifier que les cmdlets SqlServer sont détectées avec le paramètre IncludeImportedModules
if ($sqlCmdletsWithImport -and $sqlCmdletsWithImport.Count -ge 1 -and 
    $sqlCmdletsWithImport.CmdletName -contains "Invoke-Sqlcmd" -and
    $sqlCmdletsWithImport.IsImported -eq $true) {
    Write-Host "  ✓ Détection des cmdlets SqlServer avec IncludeImportedModules" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la détection des cmdlets SqlServer avec IncludeImportedModules" -ForegroundColor Red
    $testsPassed = $false
}

# Vérifier que les cmdlets dbatools sont détectées avec le paramètre IncludeImportedModules
if ($dbaCmdletsWithImport -and $dbaCmdletsWithImport.Count -ge 1 -and 
    $dbaCmdletsWithImport.CmdletName -contains "Get-DbaDatabase" -and
    $dbaCmdletsWithImport.IsImported -eq $true) {
    Write-Host "  ✓ Détection des cmdlets dbatools avec IncludeImportedModules" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la détection des cmdlets dbatools avec IncludeImportedModules" -ForegroundColor Red
    $testsPassed = $false
}

# Test 3: Tester avec un fichier comme entrée
Write-Host "`nTest 3: Tester avec un fichier comme entrée" -ForegroundColor Cyan
$fileResults = Find-CmdletWithoutExplicitImport -FilePath $tempFile

if ($fileResults -and $fileResults.Count -gt 0) {
    Write-Host "  ✓ Détection des cmdlets à partir d'un fichier" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la détection des cmdlets à partir d'un fichier" -ForegroundColor Red
    $testsPassed = $false
}

# Test 4: Tester avec un fichier inexistant
Write-Host "`nTest 4: Tester avec un fichier inexistant" -ForegroundColor Cyan
$nonExistentResults = Find-CmdletWithoutExplicitImport -FilePath "C:\NonExistentFile.ps1" -ErrorAction SilentlyContinue

if (-not $nonExistentResults -or $nonExistentResults.Count -eq 0) {
    Write-Host "  ✓ Gestion correcte d'un fichier inexistant" -ForegroundColor Green
} else {
    Write-Host "  ✗ Échec de la gestion d'un fichier inexistant" -ForegroundColor Red
    $testsPassed = $false
}

# Nettoyer
if (Test-Path -Path $tempFile) {
    Remove-Item -Path $tempFile -Force
}

# Résultat final
if ($testsPassed) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
} else {
    Write-Host "`nCertains tests ont échoué!" -ForegroundColor Red
}

# Retourner le résultat pour l'intégration continue
return $testsPassed
