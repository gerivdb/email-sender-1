#Requires -Version 5.1

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyDetectorTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de test
$testScriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"
$testScriptContent = @'
# Test d'importation de modules
Import-Module PSScriptAnalyzer
Import-Module -Name Pester
using module PSScriptAnalyzer
'@
Set-Content -Path $testScriptPath -Value $testScriptContent

# Tester la dÃ©tection des instructions Import-Module
Write-Host "Test de detection des instructions Import-Module"
$result = Find-ImportModuleInstruction -FilePath $testScriptPath
Write-Host "Nombre d'instructions trouvees : $($result.Count)"

# Afficher les dÃ©tails
foreach ($module in $result) {
    Write-Host "Module : $($module.Name), Type : $($module.ImportType), Ligne : $($module.LineNumber)"
}

# Nettoyer
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

Write-Host "Tests termines."
