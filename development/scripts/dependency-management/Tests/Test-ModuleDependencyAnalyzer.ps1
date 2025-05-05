#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module ModuleDependencyAnalyzer.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    du module ModuleDependencyAnalyzer.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module Ã  tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyAnalyzer.psm1"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyAnalyzer.psm1 n'existe pas dans le chemin spÃ©cifiÃ©: $modulePath"
}

Import-Module -Name $modulePath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyAnalyzerTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er des fichiers de test
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

$testModuleC = @"
<#
.SYNOPSIS
    Module de test C.
#>

# Importer les modules requis
Import-Module -Name ModuleA

function Get-TestC {
    [CmdletBinding()]
    param()

    Write-Output "Test C"
}

Export-ModuleMember -Function Get-TestC
"@

$testModuleD = @"
<#
.SYNOPSIS
    Module de test D.
#>

function Get-TestD {
    [CmdletBinding()]
    param()

    Write-Output "Test D"
}

Export-ModuleMember -Function Get-TestD
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

# Ã‰crire les fichiers de test
$testModuleAPath = Join-Path -Path $testDir -ChildPath "ModuleA.psm1"
$testModuleBPath = Join-Path -Path $testDir -ChildPath "ModuleB.psm1"
$testModuleCPath = Join-Path -Path $testDir -ChildPath "ModuleC.psm1"
$testModuleDPath = Join-Path -Path $testDir -ChildPath "ModuleD.psm1"
$testManifestAPath = Join-Path -Path $testDir -ChildPath "ModuleA.psd1"

$testModuleA | Out-File -FilePath $testModuleAPath -Encoding UTF8
$testModuleB | Out-File -FilePath $testModuleBPath -Encoding UTF8
$testModuleC | Out-File -FilePath $testModuleCPath -Encoding UTF8
$testModuleD | Out-File -FilePath $testModuleDPath -Encoding UTF8
$testManifestA | Out-File -FilePath $testManifestAPath -Encoding UTF8

# ExÃ©cuter les tests
Describe "ModuleDependencyAnalyzer" {
    Context "Get-PowerShellManifestStructure" {
        It "Analyse la structure d'un manifeste PowerShell" {
            $manifestInfo = Get-PowerShellManifestStructure -ManifestPath $testManifestAPath
            $manifestInfo | Should -Not -BeNullOrEmpty
            $manifestInfo.ModuleName | Should -Be "ModuleA"
            $manifestInfo.ModuleVersion | Should -Be "1.0.0"
            $manifestInfo.Author | Should -Be "Test Author"
            $manifestInfo.Description | Should -Be "Module de test A"
            $manifestInfo.RootModule | Should -Be "ModuleA.psm1"
            $manifestInfo.RequiredModules | Should -Not -BeNullOrEmpty
            $manifestInfo.RequiredModules.Count | Should -Be 2
            $manifestInfo.RequiredModules[0].Name | Should -Be "ModuleB"
            $manifestInfo.RequiredModules[1].Name | Should -Be "ModuleC"
            $manifestInfo.RequiredModules[1].Version | Should -Be "1.0.0"
        }
    }

    Context "Get-ModuleDependenciesFromManifest" {
        It "DÃ©tecte les dÃ©pendances Ã  partir d'un manifeste" {
            $dependencies = Get-ModuleDependenciesFromManifest -ManifestPath $testManifestAPath
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -BeGreaterThan 0
            $dependencies[0].Name | Should -Be "ModuleB"
            $dependencies[1].Name | Should -Be "ModuleC"
            $dependencies[1].Version | Should -Be "1.0.0"
        }
    }

    Context "Get-ModuleDependenciesFromCode" {
        It "DÃ©tecte les dÃ©pendances Ã  partir du code" {
            $dependencies = Get-ModuleDependenciesFromCode -ModulePath $testModuleAPath
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -BeGreaterThan 0
            $dependencies.Name | Should -Contain "ModuleB"
            $dependencies.Name | Should -Contain "ModuleC"
        }

        It "DÃ©tecte les dÃ©pendances using module" {
            $dependencies = Get-ModuleDependenciesFromCode -ModulePath $testModuleBPath
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -BeGreaterThan 0
            $dependencies.Name | Should -Contain "ModuleD"
        }
    }

    Context "Find-ModuleDependencyCycles" {
        It "DÃ©tecte les cycles de dÃ©pendances" {
            $graph = @{
                'ModuleA' = @('ModuleB', 'ModuleC')
                'ModuleB' = @('ModuleD')
                'ModuleC' = @('ModuleA')
                'ModuleD' = @()
            }

            $cycles = Find-ModuleDependencyCycles -DependencyGraph $graph
            $cycles.HasCycles | Should -Be $true
            $cycles.CycleCount | Should -BeGreaterThan 0
            $cycles.Cycles[0].Nodes | Should -Contain "ModuleA"
            $cycles.Cycles[0].Nodes | Should -Contain "ModuleC"
        }
    }

    Context "Get-ModuleDependenciesRecursive" {
        It "Analyse rÃ©cursivement les dÃ©pendances" {
            $dependencies = Get-ModuleDependenciesRecursive -ModulePath $testManifestAPath -MaxDepth 2
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.ModuleName | Should -Be "ModuleA"
            $dependencies.DependencyGraph.Keys | Should -Contain "ModuleA"
        }
    }

    Context "Resolve-ModuleDependencies" {
        It "RÃ©sout les dÃ©pendances et dÃ©tecte les cycles" {
            $result = Resolve-ModuleDependencies -ModulePath $testManifestAPath -MaxDepth 2
            $result | Should -Not -BeNullOrEmpty
            $result.ModuleName | Should -Be "ModuleA"
            $result.HasCycles | Should -Be $true
        }
    }

    Context "Export-ModuleDependencyGraph" {
        It "Exporte le graphe de dÃ©pendances en HTML" {
            $graph = @{
                'ModuleA' = @('ModuleB', 'ModuleC')
                'ModuleB' = @('ModuleD')
                'ModuleC' = @('ModuleA')
                'ModuleD' = @()
            }

            $outputPath = Join-Path -Path $testDir -ChildPath "dependencies.html"
            $result = Export-ModuleDependencyGraph -DependencyGraph $graph -OutputPath $outputPath -Format "HTML" -HighlightCycles
            $result | Should -Be $outputPath
            Test-Path -Path $outputPath | Should -Be $true
        }

        It "Exporte le graphe de dÃ©pendances en Mermaid" {
            $graph = @{
                'ModuleA' = @('ModuleB', 'ModuleC')
                'ModuleB' = @('ModuleD')
                'ModuleC' = @('ModuleA')
                'ModuleD' = @()
            }

            $outputPath = Join-Path -Path $testDir -ChildPath "dependencies.md"
            $result = Export-ModuleDependencyGraph -DependencyGraph $graph -OutputPath $outputPath -Format "Mermaid" -HighlightCycles
            $result | Should -Be $outputPath
            Test-Path -Path $outputPath | Should -Be $true
        }
    }
}

# Tests pour les nouvelles fonctionnalitÃ©s
Context "Test-SystemModule" {
    It "DÃ©tecte correctement les modules systÃ¨me" {
        Test-SystemModule -ModuleName "Microsoft.PowerShell.Core" | Should -Be $true
        Test-SystemModule -ModuleName "NonExistentModule" | Should -Be $false
    }

    It "Prend en compte les modules supplÃ©mentaires" {
        Test-SystemModule -ModuleName "CustomModule" | Should -Be $false
        Test-SystemModule -ModuleName "CustomModule" -AdditionalSystemModules @("CustomModule") | Should -Be $true
    }
}

Context "Find-ModulePath" {
    It "Trouve le chemin d'un module existant" {
        # CrÃ©er un module de test
        $testModuleDir = Join-Path -Path $testDir -ChildPath "TestModule"
        New-Item -Path $testModuleDir -ItemType Directory -Force | Out-Null

        $testModuleManifest = @"
@{
    ModuleName = 'TestModule'
    ModuleVersion = '1.0.0'
    GUID = '$(New-Guid)'
    Author = 'Test Author'
    Description = 'Module de test pour Find-ModulePath'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
"@

        $testModuleManifestPath = Join-Path -Path $testModuleDir -ChildPath "TestModule.psd1"
        $testModuleManifest | Out-File -FilePath $testModuleManifestPath -Encoding UTF8

        # Tester la fonction
        $modulePath = Find-ModulePath -ModuleName "TestModule" -AdditionalPaths @($testDir)
        $modulePath | Should -Not -BeNullOrEmpty
        $modulePath | Should -Be $testModuleManifestPath
    }

    It "GÃ¨re les contraintes de version" {
        # CrÃ©er des modules de test avec diffÃ©rentes versions
        $testModuleDir1 = Join-Path -Path $testDir -ChildPath "VersionedModule\1.0.0"
        $testModuleDir2 = Join-Path -Path $testDir -ChildPath "VersionedModule\2.0.0"
        New-Item -Path $testModuleDir1 -ItemType Directory -Force | Out-Null
        New-Item -Path $testModuleDir2 -ItemType Directory -Force | Out-Null

        $testModuleManifest1 = @"
@{
    ModuleName = 'VersionedModule'
    ModuleVersion = '1.0.0'
    GUID = '$(New-Guid)'
    Author = 'Test Author'
    Description = 'Module de test pour Find-ModulePath'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
"@

        $testModuleManifest2 = @"
@{
    ModuleName = 'VersionedModule'
    ModuleVersion = '2.0.0'
    GUID = '$(New-Guid)'
    Author = 'Test Author'
    Description = 'Module de test pour Find-ModulePath'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
"@

        $testModuleManifestPath1 = Join-Path -Path $testModuleDir1 -ChildPath "VersionedModule.psd1"
        $testModuleManifestPath2 = Join-Path -Path $testModuleDir2 -ChildPath "VersionedModule.psd1"
        $testModuleManifest1 | Out-File -FilePath $testModuleManifestPath1 -Encoding UTF8
        $testModuleManifest2 | Out-File -FilePath $testModuleManifestPath2 -Encoding UTF8

        # Tester la fonction avec une version spÃ©cifique
        $modulePath = Find-ModulePath -ModuleName "VersionedModule" -ModuleVersion "1.0.0" -AdditionalPaths @($testDir)
        $modulePath | Should -Be $testModuleManifestPath1

        # Tester la fonction avec une version minimale
        $modulePath = Find-ModulePath -ModuleName "VersionedModule" -MinimumVersion "1.5.0" -AdditionalPaths @($testDir)
        $modulePath | Should -Be $testModuleManifestPath2

        # Tester la fonction avec une version maximale
        $modulePath = Find-ModulePath -ModuleName "VersionedModule" -MaximumVersion "1.5.0" -AdditionalPaths @($testDir)
        $modulePath | Should -Be $testModuleManifestPath1

        # Tester la fonction avec AllVersions
        $modulePaths = Find-ModulePath -ModuleName "VersionedModule" -AdditionalPaths @($testDir) -AllVersions
        $modulePaths.Count | Should -Be 2
        $modulePaths | Should -Contain $testModuleManifestPath1
        $modulePaths | Should -Contain $testModuleManifestPath2
    }
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force
