#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module ModuleDependencyAnalyzer.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du module ModuleDependencyAnalyzer.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de création: 2023-06-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module à tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyAnalyzer.psm1"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyAnalyzer.psm1 n'existe pas dans le chemin spécifié: $modulePath"
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

# Écrire les fichiers de test
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

# Exécuter les tests
Describe "ModuleDependencyAnalyzer" {
    Context "Get-ModuleDependenciesFromManifest" {
        It "Détecte les dépendances à partir d'un manifeste" {
            $dependencies = Get-ModuleDependenciesFromManifest -ManifestPath $testManifestAPath
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -BeGreaterThan 0
            $dependencies[0].Name | Should -Be "ModuleB"
            $dependencies[1].Name | Should -Be "ModuleC"
            $dependencies[1].Version | Should -Be "1.0.0"
        }
    }

    Context "Get-ModuleDependenciesFromCode" {
        It "Détecte les dépendances à partir du code" {
            $dependencies = Get-ModuleDependenciesFromCode -ModulePath $testModuleAPath
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -BeGreaterThan 0
            $dependencies.Name | Should -Contain "ModuleB"
            $dependencies.Name | Should -Contain "ModuleC"
        }

        It "Détecte les dépendances using module" {
            $dependencies = Get-ModuleDependenciesFromCode -ModulePath $testModuleBPath
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -BeGreaterThan 0
            $dependencies.Name | Should -Contain "ModuleD"
        }
    }

    Context "Find-ModuleDependencyCycles" {
        It "Détecte les cycles de dépendances" {
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
        It "Analyse récursivement les dépendances" {
            $dependencies = Get-ModuleDependenciesRecursive -ModulePath $testManifestAPath -MaxDepth 2
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.ModuleName | Should -Be "ModuleA"
            $dependencies.DependencyGraph.Keys | Should -Contain "ModuleA"
        }
    }

    Context "Resolve-ModuleDependencies" {
        It "Résout les dépendances et détecte les cycles" {
            $result = Resolve-ModuleDependencies -ModulePath $testManifestAPath -MaxDepth 2
            $result | Should -Not -BeNullOrEmpty
            $result.ModuleName | Should -Be "ModuleA"
            $result.HasCycles | Should -Be $true
        }
    }

    Context "Export-ModuleDependencyGraph" {
        It "Exporte le graphe de dépendances en HTML" {
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

        It "Exporte le graphe de dépendances en Mermaid" {
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

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force
