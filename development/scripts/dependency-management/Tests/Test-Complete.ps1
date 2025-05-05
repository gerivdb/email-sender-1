#Requires -Version 5.1

# Importer le module Ã  tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyTraversal.psm1"

Write-Host "Module path: $modulePath"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyTraversal.psm1 n'existe pas dans le chemin spÃ©cifiÃ©: $modulePath"
}

Write-Host "Importing module..."
Import-Module -Name $modulePath -Force

Write-Host "Testing module functions..."

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyTraversalTests"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# CrÃ©er des modules de test
$moduleA = @{
    Name = "ModuleA"
    Version = "1.0.0"
    Path = Join-Path -Path $testDir -ChildPath "ModuleA"
    Dependencies = @("ModuleB", "ModuleC")
}

$moduleB = @{
    Name = "ModuleB"
    Version = "1.0.0"
    Path = Join-Path -Path $testDir -ChildPath "ModuleB"
    Dependencies = @("ModuleD")
}

$moduleC = @{
    Name = "ModuleC"
    Version = "1.0.0"
    Path = Join-Path -Path $testDir -ChildPath "ModuleC"
    Dependencies = @("ModuleE")
}

$moduleD = @{
    Name = "ModuleD"
    Version = "1.0.0"
    Path = Join-Path -Path $testDir -ChildPath "ModuleD"
    Dependencies = @("ModuleF")
}

$moduleE = @{
    Name = "ModuleE"
    Version = "1.0.0"
    Path = Join-Path -Path $testDir -ChildPath "ModuleE"
    Dependencies = @("ModuleB")  # CrÃ©e un cycle avec ModuleB
}

$moduleF = @{
    Name = "ModuleF"
    Version = "1.0.0"
    Path = Join-Path -Path $testDir -ChildPath "ModuleF"
    Dependencies = @("ModuleB")  # CrÃ©e un cycle avec ModuleB
}

$modules = @($moduleA, $moduleB, $moduleC, $moduleD, $moduleE, $moduleF)

# CrÃ©er les rÃ©pertoires des modules
foreach ($module in $modules) {
    New-Item -Path $module.Path -ItemType Directory -Force | Out-Null
}

# CrÃ©er les fichiers des modules
foreach ($module in $modules) {
    # CrÃ©er le manifeste du module
    $manifestContent = @"
@{
    RootModule = '$($module.Name).psm1'
    ModuleVersion = '$($module.Version)'
    GUID = '$(New-Guid)'
    Author = 'Test Author'
    Description = 'Module de test $($module.Name)'
    RequiredModules = @(
$(
    $module.Dependencies | ForEach-Object {
        "        '$_'"
    } | Join-String -Separator ",`n"
)
    )
    FunctionsToExport = @('Get-$($module.Name)Data')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
"@
    $manifestPath = Join-Path -Path $module.Path -ChildPath "$($module.Name).psd1"
    $manifestContent | Out-File -FilePath $manifestPath -Encoding UTF8

    # CrÃ©er le fichier du module
    $moduleContent = @"
<#
.SYNOPSIS
    Module de test $($module.Name).
#>

# Importer les modules requis
$(
    $module.Dependencies | ForEach-Object {
        "Import-Module -Name '$_'"
    } | Join-String -Separator "`n"
)

function Get-$($module.Name)Data {
    [CmdletBinding()]
    param()
    
    Write-Output "$($module.Name) Data"
}

Export-ModuleMember -Function Get-$($module.Name)Data
"@
    $modulePath = Join-Path -Path $module.Path -ChildPath "$($module.Name).psm1"
    $moduleContent | Out-File -FilePath $modulePath -Encoding UTF8
}

# Test 1: Get-ModuleDirectDependencies
Write-Host "`nTest 1: Get-ModuleDirectDependencies"
$dependencies = Get-ModuleDirectDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")
Write-Host "DÃ©pendances directes de ModuleA: $($dependencies.Count)"
foreach ($dependency in $dependencies) {
    Write-Host "  - $($dependency.Name) (Type: $($dependency.Type))"
}

# Test 2: Get-ModuleDependenciesFromManifest
Write-Host "`nTest 2: Get-ModuleDependenciesFromManifest"
$manifestDependencies = Get-ModuleDependenciesFromManifest -ManifestPath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")
Write-Host "DÃ©pendances du manifeste de ModuleA: $($manifestDependencies.Count)"
foreach ($dependency in $manifestDependencies) {
    Write-Host "  - $($dependency.Name) (Type: $($dependency.Type))"
}

# Test 3: Get-ModuleDependenciesFromCode
Write-Host "`nTest 3: Get-ModuleDependenciesFromCode"
$codeDependencies = Get-ModuleDependenciesFromCode -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psm1")
Write-Host "DÃ©pendances du code de ModuleA: $($codeDependencies.Count)"
foreach ($dependency in $codeDependencies) {
    Write-Host "  - $($dependency.Name) (Type: $($dependency.Type))"
}

# Test 4: Invoke-ModuleDependencyExploration
Write-Host "`nTest 4: Invoke-ModuleDependencyExploration"
Reset-ModuleDependencyGraph
Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0
Write-Host "Modules visitÃ©s: $($Global:MDT_VisitedModules.Count)"
Write-Host "  - $($Global:MDT_VisitedModules.Keys -join ', ')"
Write-Host "Graphe de dÃ©pendances: $($Global:MDT_DependencyGraph.Count) modules"
foreach ($module in $Global:MDT_DependencyGraph.Keys) {
    Write-Host "  - $module -> $($Global:MDT_DependencyGraph[$module] -join ', ')"
}

# Test 5: Get-ModuleVisitStatistics
Write-Host "`nTest 5: Get-ModuleVisitStatistics"
$stats = Get-ModuleVisitStatistics
Write-Host "Statistiques des modules visitÃ©s:"
Write-Host "  - Nombre de modules visitÃ©s: $($stats.VisitedModulesCount)"
Write-Host "  - Profondeur maximale: $($stats.MaxDepth)"
Write-Host "  - Profondeur minimale: $($stats.MinDepth)"
Write-Host "  - Profondeur moyenne: $($stats.AverageDepth)"

# Test 6: Find-ModuleDependencyCycles
Write-Host "`nTest 6: Find-ModuleDependencyCycles"
$cycles = Find-ModuleDependencyCycles
Write-Host "Cycles trouvÃ©s: $($cycles.CycleCount)"
foreach ($cycle in $cycles.Cycles) {
    Write-Host "  - Cycle: $($cycle.Path)"
}

# Test 7: Resolve-ModuleDependencyCycles
Write-Host "`nTest 7: Resolve-ModuleDependencyCycles"
$result = Resolve-ModuleDependencyCycles
Write-Host "Cycles rÃ©solus: $($result.ResolvedCycleCount)"
foreach ($cycle in $result.ResolvedCycles) {
    Write-Host "  - Cycle: $($cycle.Path)"
    Write-Host "  - DÃ©pendance supprimÃ©e: $($cycle.RemovedDependency)"
}

# Test 8: Get-ModuleDependencies
Write-Host "`nTest 8: Get-ModuleDependencies"
$dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -IncludeStats -DetectCycles
Write-Host "DÃ©pendances rÃ©cursives trouvÃ©es:"
Write-Host "  - Module: $($dependencies.ModuleName)"
Write-Host "  - Nombre de modules visitÃ©s: $($dependencies.VisitedModules.Count)"
Write-Host "  - Modules visitÃ©s: $($dependencies.VisitedModules -join ', ')"
if ($dependencies.Cycles) {
    Write-Host "  - Nombre de cycles: $($dependencies.Cycles.CycleCount)"
    foreach ($cycle in $dependencies.Cycles.Cycles) {
        Write-Host "  - Cycle: $($cycle.Path)"
    }
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force

Write-Host "`nTous les tests ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s !"
