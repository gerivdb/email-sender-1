#Requires -Version 5.1

# Importer le module à tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyTraversal.psm1"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyTraversal.psm1 n'existe pas dans le chemin spécifié: $modulePath"
}

Import-Module -Name $modulePath -Force -Verbose

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyTraversalTests"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Créer des modules de test
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
    Dependencies = @()
}

$moduleE = @{
    Name = "ModuleE"
    Version = "1.0.0"
    Path = Join-Path -Path $testDir -ChildPath "ModuleE"
    Dependencies = @("ModuleB")  # Crée un cycle avec ModuleB
}

$modules = @($moduleA, $moduleB, $moduleC, $moduleD, $moduleE)

# Créer les répertoires des modules
foreach ($module in $modules) {
    New-Item -Path $module.Path -ItemType Directory -Force | Out-Null
}

# Créer les fichiers des modules
foreach ($module in $modules) {
    # Créer le manifeste du module
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

    # Créer le fichier du module
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
Write-Host "Test 1: Get-ModuleDirectDependencies" -ForegroundColor Cyan
$dependencies = Get-ModuleDirectDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")
Write-Host "Dépendances directes trouvées: $($dependencies.Count)" -ForegroundColor Yellow
foreach ($dependency in $dependencies) {
    Write-Host "  - $($dependency.Name) (Type: $($dependency.Type))" -ForegroundColor Green
}

# Test 2: Get-ModuleDependenciesFromManifest
Write-Host "`nTest 2: Get-ModuleDependenciesFromManifest" -ForegroundColor Cyan
$dependencies = Get-ModuleDependenciesFromManifest -ManifestPath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")
Write-Host "Dépendances du manifeste trouvées: $($dependencies.Count)" -ForegroundColor Yellow
foreach ($dependency in $dependencies) {
    Write-Host "  - $($dependency.Name) (Type: $($dependency.Type))" -ForegroundColor Green
}

# Test 3: Get-ModuleDependenciesFromCode
Write-Host "`nTest 3: Get-ModuleDependenciesFromCode" -ForegroundColor Cyan
$dependencies = Get-ModuleDependenciesFromCode -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psm1")
Write-Host "Dépendances du code trouvées: $($dependencies.Count)" -ForegroundColor Yellow
foreach ($dependency in $dependencies) {
    Write-Host "  - $($dependency.Name) (Type: $($dependency.Type))" -ForegroundColor Green
}

# Test 4: Invoke-ModuleDependencyExploration
Write-Host "`nTest 4: Invoke-ModuleDependencyExploration" -ForegroundColor Cyan
Reset-ModuleDependencyGraph
Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0
Write-Host "Modules visités: $($script:VisitedModules.Count)" -ForegroundColor Yellow
Write-Host "  - $($script:VisitedModules.Keys -join ', ')" -ForegroundColor Green
Write-Host "Graphe de dépendances: $($script:DependencyGraph.Count) modules" -ForegroundColor Yellow
foreach ($module in $script:DependencyGraph.Keys) {
    Write-Host "  - $module -> $($script:DependencyGraph[$module] -join ', ')" -ForegroundColor Green
}

# Test 5: Get-ModuleVisitStatistics
Write-Host "`nTest 5: Get-ModuleVisitStatistics" -ForegroundColor Cyan
$stats = Get-ModuleVisitStatistics
Write-Host "Statistiques des modules visités:" -ForegroundColor Yellow
Write-Host "  - Nombre de modules visités: $($stats.VisitedModulesCount)" -ForegroundColor Green
Write-Host "  - Profondeur maximale: $($stats.MaxDepth)" -ForegroundColor Green
Write-Host "  - Profondeur minimale: $($stats.MinDepth)" -ForegroundColor Green
Write-Host "  - Profondeur moyenne: $($stats.AverageDepth)" -ForegroundColor Green

# Test 6: Find-ModuleDependencyCycles
Write-Host "`nTest 6: Find-ModuleDependencyCycles" -ForegroundColor Cyan
$cycles = Find-ModuleDependencyCycles
Write-Host "Cycles trouvés: $($cycles.CycleCount)" -ForegroundColor Yellow
foreach ($cycle in $cycles.Cycles) {
    Write-Host "  - Cycle: $($cycle.Path)" -ForegroundColor Green
}

# Test 7: Resolve-ModuleDependencyCycles
Write-Host "`nTest 7: Resolve-ModuleDependencyCycles" -ForegroundColor Cyan
$result = Resolve-ModuleDependencyCycles
Write-Host "Cycles résolus: $($result.ResolvedCycleCount)" -ForegroundColor Yellow
foreach ($cycle in $result.ResolvedCycles) {
    Write-Host "  - Cycle: $($cycle.Path)" -ForegroundColor Green
    Write-Host "  - Dépendance supprimée: $($cycle.RemovedDependency)" -ForegroundColor Green
}

# Test 8: Get-ModuleDependencies
Write-Host "`nTest 8: Get-ModuleDependencies" -ForegroundColor Cyan
$dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -IncludeStats -DetectCycles
Write-Host "Dépendances récursives trouvées:" -ForegroundColor Yellow
Write-Host "  - Module: $($dependencies.ModuleName)" -ForegroundColor Green
Write-Host "  - Nombre de modules visités: $($dependencies.VisitedModules.Count)" -ForegroundColor Green
Write-Host "  - Modules visités: $($dependencies.VisitedModules -join ', ')" -ForegroundColor Green
Write-Host "  - Nombre de cycles: $($dependencies.Cycles.CycleCount)" -ForegroundColor Green
foreach ($cycle in $dependencies.Cycles.Cycles) {
    Write-Host "  - Cycle: $($cycle.Path)" -ForegroundColor Green
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force

Write-Host "`nTous les tests ont été exécutés avec succès !" -ForegroundColor Green
