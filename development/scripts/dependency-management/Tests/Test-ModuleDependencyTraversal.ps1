#Requires -Version 5.1

<#
.SYNOPSIS
    Tests unitaires pour le module ModuleDependencyTraversal.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    du module ModuleDependencyTraversal.

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
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyTraversal.psm1"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyTraversal.psm1 n'existe pas dans le chemin spÃ©cifiÃ©: $modulePath"
}

Import-Module -Name $modulePath -Force

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
    Dependencies = @()
}

$moduleE = @{
    Name = "ModuleE"
    Version = "1.0.0"
    Path = Join-Path -Path $testDir -ChildPath "ModuleE"
    Dependencies = @("ModuleB")  # CrÃ©e un cycle avec ModuleB
}

$modules = @($moduleA, $moduleB, $moduleC, $moduleD, $moduleE)

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

# ExÃ©cuter les tests
Describe "ModuleDependencyTraversal" {
    BeforeAll {
        # RÃ©initialiser le graphe de dÃ©pendances avant chaque test
        Reset-ModuleDependencyGraph
    }

    Context "Get-ModuleDirectDependencies" {
        It "DÃ©tecte les dÃ©pendances directes d'un module" {
            $dependencies = Get-ModuleDirectDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -Be 2
            $dependencies.Name | Should -Contain "ModuleB"
            $dependencies.Name | Should -Contain "ModuleC"
        }

        It "DÃ©tecte les dÃ©pendances directes d'un module sans dÃ©pendances" {
            $dependencies = Get-ModuleDirectDependencies -ModulePath (Join-Path -Path $moduleD.Path -ChildPath "$($moduleD.Name).psd1")
            $dependencies | Should -BeNullOrEmpty
        }
    }

    Context "Get-ModuleDependenciesFromManifest" {
        It "Extrait les dÃ©pendances du manifeste d'un module" {
            $dependencies = Get-ModuleDependenciesFromManifest -ManifestPath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -Be 2
            $dependencies.Name | Should -Contain "ModuleB"
            $dependencies.Name | Should -Contain "ModuleC"
            $dependencies.Type | Should -Contain "RequiredModule"
        }
    }

    Context "Get-ModuleDependenciesFromCode" {
        It "Extrait les dÃ©pendances du code d'un module" {
            $dependencies = Get-ModuleDependenciesFromCode -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psm1")
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -Be 2
            $dependencies.Name | Should -Contain "ModuleB"
            $dependencies.Name | Should -Contain "ModuleC"
            $dependencies.Type | Should -Contain "ImportModule"
        }
    }

    Context "Invoke-ModuleDependencyExploration" {
        It "Explore rÃ©cursivement les dÃ©pendances d'un module" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # VÃ©rifier que tous les modules ont Ã©tÃ© visitÃ©s
            $script:VisitedModules.Keys | Should -Contain "ModuleA"
            $script:VisitedModules.Keys | Should -Contain "ModuleB"
            $script:VisitedModules.Keys | Should -Contain "ModuleC"
            $script:VisitedModules.Keys | Should -Contain "ModuleD"
            $script:VisitedModules.Keys | Should -Contain "ModuleE"

            # VÃ©rifier que le graphe de dÃ©pendances est correct
            $script:DependencyGraph.Keys | Should -Contain "ModuleA"
            $script:DependencyGraph.Keys | Should -Contain "ModuleB"
            $script:DependencyGraph.Keys | Should -Contain "ModuleC"
            $script:DependencyGraph.Keys | Should -Contain "ModuleD"
            $script:DependencyGraph.Keys | Should -Contain "ModuleE"

            $script:DependencyGraph["ModuleA"] | Should -Contain "ModuleB"
            $script:DependencyGraph["ModuleA"] | Should -Contain "ModuleC"
            $script:DependencyGraph["ModuleB"] | Should -Contain "ModuleD"
            $script:DependencyGraph["ModuleC"] | Should -Contain "ModuleE"
            $script:DependencyGraph["ModuleE"] | Should -Contain "ModuleB"
        }

        It "Limite la profondeur de rÃ©cursion" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # DÃ©finir une profondeur maximale de 1
            $script:MaxRecursionDepth = 1

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # VÃ©rifier que seuls les modules A, B et C ont Ã©tÃ© visitÃ©s
            $script:VisitedModules.Keys | Should -Contain "ModuleA"
            $script:VisitedModules.Keys | Should -Contain "ModuleB"
            $script:VisitedModules.Keys | Should -Contain "ModuleC"
            $script:VisitedModules.Keys | Should -Not -Contain "ModuleD"
            $script:VisitedModules.Keys | Should -Not -Contain "ModuleE"

            # RÃ©initialiser la profondeur maximale
            $script:MaxRecursionDepth = 10
        }
    }

    Context "Get-ModuleVisitStatistics" {
        It "Obtient les statistiques des modules visitÃ©s" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Obtenir les statistiques
            $stats = Get-ModuleVisitStatistics

            # VÃ©rifier les statistiques
            $stats | Should -Not -BeNullOrEmpty
            $stats.VisitedModulesCount | Should -Be 5
            $stats.MaxDepth | Should -BeGreaterThan 0
            $stats.VisitedModules | Should -Contain "ModuleA"
            $stats.VisitedModules | Should -Contain "ModuleB"
            $stats.VisitedModules | Should -Contain "ModuleC"
            $stats.VisitedModules | Should -Contain "ModuleD"
            $stats.VisitedModules | Should -Contain "ModuleE"
        }
    }

    Context "Get-ModuleDependencyGraph" {
        It "Obtient le graphe de dÃ©pendances des modules" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Obtenir le graphe de dÃ©pendances
            $graph = Get-ModuleDependencyGraph

            # VÃ©rifier le graphe
            $graph | Should -Not -BeNullOrEmpty
            $graph.Keys | Should -Contain "ModuleA"
            $graph.Keys | Should -Contain "ModuleB"
            $graph.Keys | Should -Contain "ModuleC"
            $graph.Keys | Should -Contain "ModuleD"
            $graph.Keys | Should -Contain "ModuleE"

            $graph["ModuleA"] | Should -Contain "ModuleB"
            $graph["ModuleA"] | Should -Contain "ModuleC"
            $graph["ModuleB"] | Should -Contain "ModuleD"
            $graph["ModuleC"] | Should -Contain "ModuleE"
            $graph["ModuleE"] | Should -Contain "ModuleB"
        }

        It "Obtient le graphe de dÃ©pendances d'un module spÃ©cifique" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Obtenir le graphe de dÃ©pendances du module A
            $graph = Get-ModuleDependencyGraph -ModuleName "ModuleA"

            # VÃ©rifier le graphe
            $graph | Should -Not -BeNullOrEmpty
            $graph.Keys | Should -Contain "ModuleA"
            $graph.Keys | Should -Not -Contain "ModuleB"
            $graph.Keys | Should -Not -Contain "ModuleC"
            $graph.Keys | Should -Not -Contain "ModuleD"
            $graph.Keys | Should -Not -Contain "ModuleE"

            $graph["ModuleA"] | Should -Contain "ModuleB"
            $graph["ModuleA"] | Should -Contain "ModuleC"
        }

        It "Obtient le graphe de dÃ©pendances avec des statistiques" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Obtenir le graphe de dÃ©pendances avec des statistiques
            $result = Get-ModuleDependencyGraph -IncludeStats

            # VÃ©rifier le rÃ©sultat
            $result | Should -Not -BeNullOrEmpty
            $result.Graph | Should -Not -BeNullOrEmpty
            $result.Stats | Should -Not -BeNullOrEmpty
            $result.Stats.ModuleCount | Should -Be 5
            $result.Stats.DependencyCount | Should -BeGreaterThan 0
        }
    }

    Context "Find-ModuleDependencyCycles" {
        It "DÃ©tecte les cycles dans le graphe de dÃ©pendances" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # DÃ©tecter les cycles
            $cycles = Find-ModuleDependencyCycles

            # VÃ©rifier les cycles
            $cycles | Should -Not -BeNullOrEmpty
            $cycles.HasCycles | Should -Be $true
            $cycles.Cycles | Should -Not -BeNullOrEmpty
            $cycles.CycleCount | Should -BeGreaterThan 0
        }

        It "DÃ©tecte tous les cycles dans le graphe de dÃ©pendances" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # DÃ©tecter tous les cycles
            $cycles = Find-ModuleDependencyCycles -IncludeAllCycles

            # VÃ©rifier les cycles
            $cycles | Should -Not -BeNullOrEmpty
            $cycles.HasCycles | Should -Be $true
            $cycles.Cycles | Should -Not -BeNullOrEmpty
            $cycles.CycleCount | Should -BeGreaterThan 0
        }
    }

    Context "Resolve-ModuleDependencyCycles" {
        It "RÃ©sout les cycles dans le graphe de dÃ©pendances" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # RÃ©soudre les cycles
            $result = Resolve-ModuleDependencyCycles

            # VÃ©rifier le rÃ©sultat
            $result | Should -Not -BeNullOrEmpty
            $result.HasCycles | Should -Be $true
            $result.ResolvedCycles | Should -Not -BeNullOrEmpty
            $result.ResolvedCycleCount | Should -BeGreaterThan 0
            $result.ModifiedGraph | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les cycles ont Ã©tÃ© rÃ©solus
            $cycles = Find-ModuleDependencyCycles -DependencyGraph $result.ModifiedGraph
            $cycles.HasCycles | Should -Be $false
        }

        It "Rapporte les cycles sans les rÃ©soudre" {
            # RÃ©initialiser le graphe de dÃ©pendances
            Reset-ModuleDependencyGraph

            # Explorer les dÃ©pendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Rapporter les cycles
            $result = Resolve-ModuleDependencyCycles -ReportOnly

            # VÃ©rifier le rÃ©sultat
            $result | Should -Not -BeNullOrEmpty
            $result.HasCycles | Should -Be $true
            $result.ResolvedCycles | Should -Not -BeNullOrEmpty
            $result.ResolvedCycleCount | Should -BeGreaterThan 0
            $result.ModifiedGraph | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les cycles n'ont pas Ã©tÃ© rÃ©solus
            $cycles = Find-ModuleDependencyCycles -DependencyGraph $result.ModifiedGraph
            $cycles.HasCycles | Should -Be $true
        }
    }

    Context "Get-ModuleDependencies" {
        It "Obtient les dÃ©pendances rÃ©cursives d'un module" {
            # Obtenir les dÃ©pendances du module A
            $dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")

            # VÃ©rifier les dÃ©pendances
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.ModuleName | Should -Be "ModuleA"
            $dependencies.DependencyGraph | Should -Not -BeNullOrEmpty
            $dependencies.VisitedModules | Should -Not -BeNullOrEmpty
            $dependencies.MaxDepth | Should -Be 10

            $dependencies.DependencyGraph.Keys | Should -Contain "ModuleA"
            $dependencies.DependencyGraph.Keys | Should -Contain "ModuleB"
            $dependencies.DependencyGraph.Keys | Should -Contain "ModuleC"
            $dependencies.DependencyGraph.Keys | Should -Contain "ModuleD"
            $dependencies.DependencyGraph.Keys | Should -Contain "ModuleE"

            $dependencies.VisitedModules | Should -Contain "ModuleA"
            $dependencies.VisitedModules | Should -Contain "ModuleB"
            $dependencies.VisitedModules | Should -Contain "ModuleC"
            $dependencies.VisitedModules | Should -Contain "ModuleD"
            $dependencies.VisitedModules | Should -Contain "ModuleE"
        }

        It "Obtient les dÃ©pendances rÃ©cursives d'un module avec des statistiques" {
            # Obtenir les dÃ©pendances du module A avec des statistiques
            $dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -IncludeStats

            # VÃ©rifier les dÃ©pendances
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.ModuleName | Should -Be "ModuleA"
            $dependencies.DependencyGraph | Should -Not -BeNullOrEmpty
            $dependencies.VisitedModules | Should -Not -BeNullOrEmpty
            $dependencies.MaxDepth | Should -Be 10
            $dependencies.Stats | Should -Not -BeNullOrEmpty
            $dependencies.Stats.VisitedModulesCount | Should -Be 5
        }

        It "Obtient les dÃ©pendances rÃ©cursives d'un module avec dÃ©tection des cycles" {
            # Obtenir les dÃ©pendances du module A avec dÃ©tection des cycles
            $dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -DetectCycles

            # VÃ©rifier les dÃ©pendances
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.ModuleName | Should -Be "ModuleA"
            $dependencies.DependencyGraph | Should -Not -BeNullOrEmpty
            $dependencies.VisitedModules | Should -Not -BeNullOrEmpty
            $dependencies.MaxDepth | Should -Be 10
            $dependencies.Cycles | Should -Not -BeNullOrEmpty
            $dependencies.Cycles.HasCycles | Should -Be $true
            $dependencies.Cycles.Cycles | Should -Not -BeNullOrEmpty
            $dependencies.Cycles.CycleCount | Should -BeGreaterThan 0
        }

        It "Limite la profondeur de rÃ©cursion" {
            # Obtenir les dÃ©pendances du module A avec une profondeur maximale de 1
            $dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -MaxDepth 1

            # VÃ©rifier les dÃ©pendances
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.ModuleName | Should -Be "ModuleA"
            $dependencies.DependencyGraph | Should -Not -BeNullOrEmpty
            $dependencies.VisitedModules | Should -Not -BeNullOrEmpty
            $dependencies.MaxDepth | Should -Be 1

            $dependencies.VisitedModules | Should -Contain "ModuleA"
            $dependencies.VisitedModules | Should -Contain "ModuleB"
            $dependencies.VisitedModules | Should -Contain "ModuleC"
            $dependencies.VisitedModules | Should -Not -Contain "ModuleD"
            $dependencies.VisitedModules | Should -Not -Contain "ModuleE"
        }
    }
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force
