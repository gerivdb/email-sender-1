#Requires -Version 5.1

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module à tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyTraversal.psm1"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyTraversal.psm1 n'existe pas dans le chemin spécifié: $modulePath"
}

Import-Module -Name $modulePath -Force

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

# Exécuter les tests
Describe "ModuleDependencyTraversal" {
    BeforeAll {
        # Réinitialiser le graphe de dépendances avant chaque test
        Reset-ModuleDependencyGraph
    }

    Context "Get-ModuleDirectDependencies" {
        It "Détecte les dépendances directes d'un module" {
            $dependencies = Get-ModuleDirectDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -Be 2
            $dependencies.Name | Should -Contain "ModuleB"
            $dependencies.Name | Should -Contain "ModuleC"
        }

        It "Détecte les dépendances directes d'un module sans dépendances" {
            $dependencies = Get-ModuleDirectDependencies -ModulePath (Join-Path -Path $moduleD.Path -ChildPath "$($moduleD.Name).psd1")
            $dependencies | Should -BeNullOrEmpty
        }
    }
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force
