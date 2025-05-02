# Test pour le module ModuleDependencyAnalyzer-Fixed
# Ce test vérifie les fonctionnalités de base du module

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importe avec succes" -ForegroundColor Green

    # Vérifier que les fonctions sont disponibles
    $functions = Get-Command -Module ModuleDependencyAnalyzer-Fixed
    Write-Host "Fonctions disponibles : $($functions.Count)" -ForegroundColor Green
    $functions | ForEach-Object { Write-Host "  - $($_.Name)" }

    # Créer un répertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyAnalyzerTests"
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # Créer des fichiers de test
    $manifestContent = @"
@{
    ModuleVersion = '1.0.0'
    GUID = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
    Author = 'Test Author'
    Description = 'Test Module'
    RootModule = 'TestModule.psm1'
    RequiredModules = @(
        'Module1',
        @{
            ModuleName = 'Module2'
            ModuleVersion = '2.0.0'
        }
    )
}
"@

    $scriptContent = @"
# Import modules
Import-Module Module1
Import-Module -Name Module2
"@

    $manifestPath = Join-Path -Path $testDir -ChildPath "TestModule.psd1"
    $scriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"

    Set-Content -Path $manifestPath -Value $manifestContent
    Set-Content -Path $scriptPath -Value $scriptContent

    # Test 1: Test-SystemModule
    Write-Host "`nTest 1: Test-SystemModule" -ForegroundColor Cyan
    $result1 = Test-SystemModule -ModuleName "Microsoft.PowerShell.Core"
    $result2 = Test-SystemModule -ModuleName "CustomModule"
    Write-Host "Microsoft.PowerShell.Core is system module: $result1"
    Write-Host "CustomModule is system module: $result2"

    # Test 2: Get-PowerShellManifestStructure
    Write-Host "`nTest 2: Get-PowerShellManifestStructure" -ForegroundColor Cyan
    $result = Get-PowerShellManifestStructure -ManifestPath $manifestPath
    Write-Host "Module Name: $($result.ModuleName)"
    Write-Host "Required Modules Count: $($result.RequiredModules.Count)"

    # Test 3: Get-ModuleDependenciesFromManifest
    Write-Host "`nTest 3: Get-ModuleDependenciesFromManifest" -ForegroundColor Cyan
    $result = Get-ModuleDependenciesFromManifest -ManifestPath $manifestPath
    Write-Host "Dependencies Count: $($result.Count)"
    $result | ForEach-Object {
        Write-Host "  - $($_.Name) (Type: $($_.Type))"
    }

    # Test 4: Get-ModuleDependenciesFromCode
    Write-Host "`nTest 4: Get-ModuleDependenciesFromCode" -ForegroundColor Cyan
    $result = Get-ModuleDependenciesFromCode -ModulePath $scriptPath
    Write-Host "Dependencies Count: $($result.Count)"
    $result | ForEach-Object {
        Write-Host "  - $($_.Name) (Type: $($_.Type))"
    }

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Module -Name "ModuleDependencyAnalyzer-Fixed" -Force -ErrorAction SilentlyContinue

    # Tout est OK
    Write-Host "`nTous les tests ont reussi !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
