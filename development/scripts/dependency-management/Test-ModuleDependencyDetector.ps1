#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module ModuleDependencyDetector.

.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s du module ModuleDependencyDetector
    en analysant diffÃ©rents types d'instructions Import-Module.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyDetectorTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory | Out-Null
}

# CrÃ©er un script de test avec diffÃ©rentes formes d'Import-Module et using module
$testScriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"
$testScriptContent = @'
# Instructions using module
using module PSScriptAnalyzer
using module ..\Modules\MyModule.psm1
using module C:\Modules\AnotherModule.psm1

# Import-Module simple
Import-Module PSScriptAnalyzer

# Import-Module avec paramÃ¨tre nommÃ©
Import-Module -Name Pester

# Import-Module avec chemin relatif
Import-Module ..\Modules\MyModule.psm1

# Import-Module avec chemin absolu
Import-Module C:\Modules\AnotherModule.psm1

# Import-Module avec version
Import-Module PSScriptAnalyzer -RequiredVersion 1.18.0

# Import-Module avec plage de versions
Import-Module PSScriptAnalyzer -MinimumVersion 1.18.0 -MaximumVersion 2.0.0

# Import-Module avec paramÃ¨tres supplÃ©mentaires
Import-Module PSScriptAnalyzer -Global -Force -Prefix "PSA"

# Import-Module avec variable
$moduleName = "PSScriptAnalyzer"
Import-Module $moduleName

# Import-Module conditionnel
if ($true) {
    Import-Module PSScriptAnalyzer
}

# Import-Module dans une fonction
function Test-Function {
    Import-Module PSScriptAnalyzer
}
'@

Set-Content -Path $testScriptPath -Value $testScriptContent

# Fonction pour afficher les rÃ©sultats
function Format-ModuleInfo {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$ModuleInfo
    )

    process {
        $output = "Module: $($ModuleInfo.Name)"

        if ($ModuleInfo.Path) {
            $output += ", Path: $($ModuleInfo.Path)"
        }

        if ($ModuleInfo.Version) {
            $output += ", Version: $($ModuleInfo.Version)"
        }

        if ($ModuleInfo.Global) {
            $output += ", Global: $($ModuleInfo.Global)"
        }

        if ($ModuleInfo.Force) {
            $output += ", Force: $($ModuleInfo.Force)"
        }

        if ($ModuleInfo.Prefix) {
            $output += ", Prefix: $($ModuleInfo.Prefix)"
        }

        $output += ", Type: $($ModuleInfo.ArgumentType)"
        $output += ", Line: $($ModuleInfo.LineNumber)"

        return $output
    }
}

# Test 1: Analyser un fichier
Write-Host "Test 1: Analyser un fichier" -ForegroundColor Cyan
$result1 = Find-ImportModuleInstruction -FilePath $testScriptPath
Write-Host "Nombre d'instructions Import-Module trouvÃ©es: $($result1.Count)" -ForegroundColor Yellow
$result1 | ForEach-Object { Format-ModuleInfo -ModuleInfo $_ } | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }

# Test 2: Analyser un contenu de script
Write-Host "`nTest 2: Analyser un contenu de script" -ForegroundColor Cyan
$scriptContent = Get-Content -Path $testScriptPath -Raw
$result2 = Find-ImportModuleInstruction -ScriptContent $scriptContent
Write-Host "Nombre d'instructions Import-Module trouvÃ©es: $($result2.Count)" -ForegroundColor Yellow
$result2 | ForEach-Object { Format-ModuleInfo -ModuleInfo $_ } | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }

# Test 3: RÃ©soudre les chemins des modules
Write-Host "`nTest 3: RÃ©soudre les chemins des modules" -ForegroundColor Cyan
$result3 = Find-ImportModuleInstruction -FilePath $testScriptPath -ResolveModulePaths
Write-Host "Nombre d'instructions Import-Module trouvÃ©es: $($result3.Count)" -ForegroundColor Yellow
$result3 | ForEach-Object { Format-ModuleInfo -ModuleInfo $_ } | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }

# Nettoyer
Remove-Item -Path $testScriptPath -Force
if ((Get-ChildItem -Path $testDir).Count -eq 0) {
    Remove-Item -Path $testDir -Force
}

Write-Host "`nTests terminÃ©s." -ForegroundColor Cyan
