#Requires -Version 5.1

# Importer le module à tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyAnalyzer_Simple.psm1"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyAnalyzer_Simple.psm1 n'existe pas dans le chemin spécifié: $modulePath"
}

Import-Module -Name $modulePath -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyAnalyzerTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer des fichiers de test
$testModuleA = @"
#Requires -Modules ModuleB, ModuleC
<#
.SYNOPSIS
    Module de test A.
#>

# Importer les modules requis
Import-Module -Name ModuleB
Import-Module -Name ModuleC

function Get-TestA {
    [CmdletBinding()]
    param()
    
    Write-Output "Test A"
}

Export-ModuleMember -Function Get-TestA
"@

$testModuleB = @"
<#
.SYNOPSIS
    Module de test B.
#>

using module ModuleD

function Get-TestB {
    [CmdletBinding()]
    param()
    
    Write-Output "Test B"
}

Export-ModuleMember -Function Get-TestB
"@

$testManifestA = @"
@{
    RootModule = 'ModuleA.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'Test Author'
    Description = 'Module de test A'
    RequiredModules = @(
        'ModuleB',
        @{
            ModuleName = 'ModuleC'
            ModuleVersion = '1.0.0'
        }
    )
    FunctionsToExport = @('Get-TestA')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
"@

# Écrire les fichiers de test
$testModuleAPath = Join-Path -Path $testDir -ChildPath "ModuleA.psm1"
$testModuleBPath = Join-Path -Path $testDir -ChildPath "ModuleB.psm1"
$testManifestAPath = Join-Path -Path $testDir -ChildPath "ModuleA.psd1"

$testModuleA | Out-File -FilePath $testModuleAPath -Encoding UTF8
$testModuleB | Out-File -FilePath $testModuleBPath -Encoding UTF8
$testManifestA | Out-File -FilePath $testManifestAPath -Encoding UTF8

# Test 1: Get-ModuleDependenciesFromManifest
Write-Host "Test 1: Get-ModuleDependenciesFromManifest" -ForegroundColor Cyan
$dependencies = Get-ModuleDependenciesFromManifest -ManifestPath $testManifestAPath
Write-Host "Dépendances trouvées: $($dependencies.Count)" -ForegroundColor Yellow
foreach ($dependency in $dependencies) {
    Write-Host "  - $($dependency.Name) (Type: $($dependency.Type))" -ForegroundColor Green
}

# Test 2: Get-ModuleDependenciesFromCode
Write-Host "`nTest 2: Get-ModuleDependenciesFromCode" -ForegroundColor Cyan
$dependencies = Get-ModuleDependenciesFromCode -ModulePath $testModuleAPath
Write-Host "Dépendances trouvées: $($dependencies.Count)" -ForegroundColor Yellow
foreach ($dependency in $dependencies) {
    Write-Host "  - $($dependency.Name) (Type: $($dependency.Type))" -ForegroundColor Green
}

# Test 3: Get-ModuleDependenciesFromCode (using module)
Write-Host "`nTest 3: Get-ModuleDependenciesFromCode (using module)" -ForegroundColor Cyan
$dependencies = Get-ModuleDependenciesFromCode -ModulePath $testModuleBPath
Write-Host "Dépendances trouvées: $($dependencies.Count)" -ForegroundColor Yellow
foreach ($dependency in $dependencies) {
    Write-Host "  - $($dependency.Name) (Type: $($dependency.Type))" -ForegroundColor Green
}

# Test 4: Find-ModuleDependencyCycles
Write-Host "`nTest 4: Find-ModuleDependencyCycles" -ForegroundColor Cyan
$graph = @{
    'ModuleA' = @('ModuleB', 'ModuleC')
    'ModuleB' = @('ModuleD')
    'ModuleC' = @('ModuleA')
    'ModuleD' = @()
}
$cycles = Find-ModuleDependencyCycles -DependencyGraph $graph
Write-Host "Cycles trouvés: $($cycles.CycleCount)" -ForegroundColor Yellow
foreach ($cycle in $cycles.Cycles) {
    Write-Host "  - Cycle: $($cycle.Nodes -join ' -> ')" -ForegroundColor Green
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force

Write-Host "`nTous les tests ont été exécutés avec succès !" -ForegroundColor Green
