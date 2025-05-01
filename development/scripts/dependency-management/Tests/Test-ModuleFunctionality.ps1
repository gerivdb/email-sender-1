#Requires -Version 5.1
<#
.SYNOPSIS
    Tests manuels pour le module ModuleDependencyDetector.

.DESCRIPTION
    Ce script exécute des tests manuels pour vérifier le bon fonctionnement
    du module ModuleDependencyDetector sans dépendre de Pester.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-16
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyDetectorTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Fonction pour afficher les résultats des tests
function Write-TestResult {
    param (
        [string]$TestName,
        [bool]$Success,
        [string]$Message = ""
    )

    if ($Success) {
        Write-Host "✓ $TestName" -ForegroundColor Green
    } else {
        Write-Host "✗ $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "  $Message" -ForegroundColor Red
        }
    }
}

# Fonction pour vérifier une condition
function Test-Condition {
    param (
        [string]$TestName,
        [scriptblock]$Condition,
        [string]$FailureMessage = ""
    )

    try {
        $result = & $Condition
        Write-TestResult -TestName $TestName -Success $result -Message $FailureMessage
        return $result
    } catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Exception: $_"
        return $false
    }
}

# Créer des fichiers de test
$testScriptPath1 = Join-Path -Path $testDir -ChildPath "TestImportModule.ps1"
$testScriptContent1 = @'
# Test d'importation de modules avec Import-Module
Import-Module PSScriptAnalyzer
Import-Module -Name Pester
Import-Module ..\Modules\MyModule.psm1
Import-Module C:\Modules\AnotherModule.psm1
Import-Module PSScriptAnalyzer -RequiredVersion 1.18.0
Import-Module PSScriptAnalyzer -MinimumVersion 1.18.0 -MaximumVersion 2.0.0
Import-Module PSScriptAnalyzer -Global -Force -Prefix "PSA"
$moduleName = "PSScriptAnalyzer"
Import-Module $moduleName
if ($true) {
    Import-Module PSScriptAnalyzer
}
function Test-Function {
    Import-Module PSScriptAnalyzer
}
'@
Set-Content -Path $testScriptPath1 -Value $testScriptContent1

$testScriptPath2 = Join-Path -Path $testDir -ChildPath "TestUsingModule.ps1"
$testScriptContent2 = @'
# Test d'importation de modules avec using module
using module PSScriptAnalyzer
using module ..\Modules\MyModule.psm1
using module C:\Modules\AnotherModule.psm1

# Mélange avec Import-Module
Import-Module Pester
'@
Set-Content -Path $testScriptPath2 -Value $testScriptContent2

$testScriptPath3 = Join-Path -Path $testDir -ChildPath "TestMixed.ps1"
$testScriptContent3 = @'
# Test d'importation de modules avec using module et Import-Module
using module PSScriptAnalyzer
using module ..\Modules\MyModule.psm1

# Import-Module
Import-Module Pester
Import-Module ..\Modules\AnotherModule.psm1
'@
Set-Content -Path $testScriptPath3 -Value $testScriptContent3

# Créer un module de test
$testModulePath = Join-Path -Path $testDir -ChildPath "Modules"
if (-not (Test-Path -Path $testModulePath)) {
    New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
}
$testModuleFile = Join-Path -Path $testModulePath -ChildPath "TestModule.psm1"
$testModuleContent = @'
function Test-Function {
    [CmdletBinding()]
    param()

    Write-Output "Test function"
}

Export-ModuleMember -Function Test-Function
'@
Set-Content -Path $testModuleFile -Value $testModuleContent

# Exécuter les tests
Write-Host "Tests du module ModuleDependencyDetector" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Test 1: Détection des instructions Import-Module
Write-Host "`nTest 1: Détection des instructions Import-Module" -ForegroundColor Yellow
$result1 = Find-ImportModuleInstruction -FilePath $testScriptPath1
Test-Condition -TestName "Détecte les instructions Import-Module" -Condition { $result1.Count -gt 0 }
Test-Condition -TestName "Détecte le nom du module" -Condition { $result1[0].Name -eq "PSScriptAnalyzer" }
Test-Condition -TestName "Détecte le type d'importation" -Condition { $result1[0].ImportType -eq "Import-Module" }

# Test 2: Détection des instructions using module
Write-Host "`nTest 2: Détection des instructions using module" -ForegroundColor Yellow
$result2 = Find-ImportModuleInstruction -FilePath $testScriptPath2
$usingModules = @($result2 | Where-Object { $_.ImportType -eq "using module" })
Test-Condition -TestName "Détecte les instructions using module" -Condition { $usingModules.Count -gt 0 }
if ($usingModules.Count -gt 0) {
    Test-Condition -TestName "Détecte le nom du module" -Condition { $usingModules[0].Name -eq "PSScriptAnalyzer" }
    Test-Condition -TestName "Détecte le type d'importation" -Condition { $usingModules[0].ImportType -eq "using module" }
}

# Test 3: Détection des instructions mixtes
Write-Host "`nTest 3: Détection des instructions mixtes" -ForegroundColor Yellow
$result3 = Find-ImportModuleInstruction -FilePath $testScriptPath3
$importModules = @($result3 | Where-Object { $_.ImportType -eq "Import-Module" })
$usingModules = @($result3 | Where-Object { $_.ImportType -eq "using module" })
Test-Condition -TestName "Détecte les instructions Import-Module" -Condition { $importModules.Count -gt 0 }
Test-Condition -TestName "Détecte les instructions using module" -Condition { $usingModules.Count -gt 0 }

# Test 4: Détection des paramètres nommés
Write-Host "`nTest 4: Détection des paramètres nommés" -ForegroundColor Yellow
$namedModule = $result1 | Where-Object { $_.ArgumentType -eq "Named" }
Test-Condition -TestName "Détecte les paramètres nommés" -Condition { $namedModule.Count -gt 0 }
if ($namedModule.Count -gt 0) {
    Test-Condition -TestName "Détecte le nom du module" -Condition { $namedModule[0].Name -eq "Pester" }
}

# Test 5: Détection des chemins relatifs
Write-Host "`nTest 5: Détection des chemins relatifs" -ForegroundColor Yellow
$pathModule = $result1 | Where-Object { $_.Path -like "*MyModule.psm1" }
Test-Condition -TestName "Détecte les chemins relatifs" -Condition { $pathModule.Count -gt 0 }
if ($pathModule.Count -gt 0) {
    Test-Condition -TestName "Détecte le nom du module" -Condition { $pathModule[0].Name -eq "MyModule" }
}

# Test 6: Détection des versions
Write-Host "`nTest 6: Détection des versions" -ForegroundColor Yellow
$versionModule = $result1 | Where-Object { $null -ne $_.Version }
Test-Condition -TestName "Détecte les versions" -Condition { $versionModule.Count -gt 0 }
if ($versionModule.Count -gt 0) {
    Test-Condition -TestName "Détecte le nom du module" -Condition { $versionModule[0].Name -eq "PSScriptAnalyzer" }
    Test-Condition -TestName "Détecte la version" -Condition { $null -ne $versionModule[0].Version }
}

# Test 7: Détection des paramètres supplémentaires
Write-Host "`nTest 7: Détection des paramètres supplémentaires" -ForegroundColor Yellow
$globalModule = $result1 | Where-Object { $_.Global -eq $true -and $_.ImportType -eq "Import-Module" }
Test-Condition -TestName "Détecte les paramètres supplémentaires" -Condition { $globalModule.Count -gt 0 }
if ($globalModule.Count -gt 0) {
    Test-Condition -TestName "Détecte le paramètre Global" -Condition { $globalModule[0].Global -eq $true }
    Test-Condition -TestName "Détecte le paramètre Force" -Condition { $globalModule[0].Force -eq $true }
    Test-Condition -TestName "Détecte le paramètre Prefix" -Condition { $globalModule[0].Prefix -eq "PSA" }
}

# Test 8: Résolution des chemins
Write-Host "`nTest 8: Résolution des chemins" -ForegroundColor Yellow
$testModulePath = Join-Path -Path $testDir -ChildPath "TestResolveModule.psm1"
$testModuleContent = @'
function Test-Function {
    [CmdletBinding()]
    param()

    Write-Output "Test function"
}

Export-ModuleMember -Function Test-Function
'@
Set-Content -Path $testModulePath -Value $testModuleContent

$result = Resolve-ModulePath -Name "TestResolveModule" -BaseDirectory $testDir
Test-Condition -TestName "Résout le chemin par nom" -Condition { $null -ne $result }

# Test 9: Contenu de script
Write-Host "`nTest 9: Contenu de script" -ForegroundColor Yellow
$scriptContent = @'
# Test d'importation de modules
Import-Module PSScriptAnalyzer
using module Pester
'@
$result = Find-ImportModuleInstruction -ScriptContent $scriptContent
$importModules = @($result | Where-Object { $_.ImportType -eq "Import-Module" })
$usingModules = @($result | Where-Object { $_.ImportType -eq "using module" })
Test-Condition -TestName "Détecte les instructions Import-Module" -Condition { $importModules.Count -gt 0 }
Test-Condition -TestName "Détecte les instructions using module" -Condition { $usingModules.Count -gt 0 }
if ($importModules.Count -gt 0 -and $usingModules.Count -gt 0) {
    Test-Condition -TestName "Détecte le nom du module Import-Module" -Condition { $importModules[0].Name -eq "PSScriptAnalyzer" }
    Test-Condition -TestName "Détecte le nom du module using module" -Condition { $usingModules[0].Name -eq "Pester" }
}

# Nettoyer
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

Write-Host "`nTests termines." -ForegroundColor Cyan
