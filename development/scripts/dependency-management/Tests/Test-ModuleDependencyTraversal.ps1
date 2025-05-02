#Requires -Version 5.1

<#
.SYNOPSIS
    Tests unitaires pour le module ModuleDependencyTraversal.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du module ModuleDependencyTraversal.

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

    Context "Get-ModuleDependenciesFromManifest" {
        It "Extrait les dépendances du manifeste d'un module" {
            $dependencies = Get-ModuleDependenciesFromManifest -ManifestPath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -Be 2
            $dependencies.Name | Should -Contain "ModuleB"
            $dependencies.Name | Should -Contain "ModuleC"
            $dependencies.Type | Should -Contain "RequiredModule"
        }
    }

    Context "Get-ModuleDependenciesFromCode" {
        It "Extrait les dépendances du code d'un module" {
            $dependencies = Get-ModuleDependenciesFromCode -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psm1")
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.Count | Should -Be 2
            $dependencies.Name | Should -Contain "ModuleB"
            $dependencies.Name | Should -Contain "ModuleC"
            $dependencies.Type | Should -Contain "ImportModule"
        }
    }

    Context "Invoke-ModuleDependencyExploration" {
        It "Explore récursivement les dépendances d'un module" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Vérifier que tous les modules ont été visités
            $script:VisitedModules.Keys | Should -Contain "ModuleA"
            $script:VisitedModules.Keys | Should -Contain "ModuleB"
            $script:VisitedModules.Keys | Should -Contain "ModuleC"
            $script:VisitedModules.Keys | Should -Contain "ModuleD"
            $script:VisitedModules.Keys | Should -Contain "ModuleE"

            # Vérifier que le graphe de dépendances est correct
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

        It "Limite la profondeur de récursion" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Définir une profondeur maximale de 1
            $script:MaxRecursionDepth = 1

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Vérifier que seuls les modules A, B et C ont été visités
            $script:VisitedModules.Keys | Should -Contain "ModuleA"
            $script:VisitedModules.Keys | Should -Contain "ModuleB"
            $script:VisitedModules.Keys | Should -Contain "ModuleC"
            $script:VisitedModules.Keys | Should -Not -Contain "ModuleD"
            $script:VisitedModules.Keys | Should -Not -Contain "ModuleE"

            # Réinitialiser la profondeur maximale
            $script:MaxRecursionDepth = 10
        }
    }

    Context "Get-ModuleVisitStatistics" {
        It "Obtient les statistiques des modules visités" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Obtenir les statistiques
            $stats = Get-ModuleVisitStatistics

            # Vérifier les statistiques
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
        It "Obtient le graphe de dépendances des modules" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Obtenir le graphe de dépendances
            $graph = Get-ModuleDependencyGraph

            # Vérifier le graphe
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

        It "Obtient le graphe de dépendances d'un module spécifique" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Obtenir le graphe de dépendances du module A
            $graph = Get-ModuleDependencyGraph -ModuleName "ModuleA"

            # Vérifier le graphe
            $graph | Should -Not -BeNullOrEmpty
            $graph.Keys | Should -Contain "ModuleA"
            $graph.Keys | Should -Not -Contain "ModuleB"
            $graph.Keys | Should -Not -Contain "ModuleC"
            $graph.Keys | Should -Not -Contain "ModuleD"
            $graph.Keys | Should -Not -Contain "ModuleE"

            $graph["ModuleA"] | Should -Contain "ModuleB"
            $graph["ModuleA"] | Should -Contain "ModuleC"
        }

        It "Obtient le graphe de dépendances avec des statistiques" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Obtenir le graphe de dépendances avec des statistiques
            $result = Get-ModuleDependencyGraph -IncludeStats

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Graph | Should -Not -BeNullOrEmpty
            $result.Stats | Should -Not -BeNullOrEmpty
            $result.Stats.ModuleCount | Should -Be 5
            $result.Stats.DependencyCount | Should -BeGreaterThan 0
        }
    }

    Context "Find-ModuleDependencyCycles" {
        It "Détecte les cycles dans le graphe de dépendances" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Détecter les cycles
            $cycles = Find-ModuleDependencyCycles

            # Vérifier les cycles
            $cycles | Should -Not -BeNullOrEmpty
            $cycles.HasCycles | Should -Be $true
            $cycles.Cycles | Should -Not -BeNullOrEmpty
            $cycles.CycleCount | Should -BeGreaterThan 0
        }

        It "Détecte tous les cycles dans le graphe de dépendances" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Détecter tous les cycles
            $cycles = Find-ModuleDependencyCycles -IncludeAllCycles

            # Vérifier les cycles
            $cycles | Should -Not -BeNullOrEmpty
            $cycles.HasCycles | Should -Be $true
            $cycles.Cycles | Should -Not -BeNullOrEmpty
            $cycles.CycleCount | Should -BeGreaterThan 0
        }
    }

    Context "Resolve-ModuleDependencyCycles" {
        It "Résout les cycles dans le graphe de dépendances" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Résoudre les cycles
            $result = Resolve-ModuleDependencyCycles

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.HasCycles | Should -Be $true
            $result.ResolvedCycles | Should -Not -BeNullOrEmpty
            $result.ResolvedCycleCount | Should -BeGreaterThan 0
            $result.ModifiedGraph | Should -Not -BeNullOrEmpty

            # Vérifier que les cycles ont été résolus
            $cycles = Find-ModuleDependencyCycles -DependencyGraph $result.ModifiedGraph
            $cycles.HasCycles | Should -Be $false
        }

        It "Rapporte les cycles sans les résoudre" {
            # Réinitialiser le graphe de dépendances
            Reset-ModuleDependencyGraph

            # Explorer les dépendances du module A
            Invoke-ModuleDependencyExploration -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -CurrentDepth 0

            # Rapporter les cycles
            $result = Resolve-ModuleDependencyCycles -ReportOnly

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.HasCycles | Should -Be $true
            $result.ResolvedCycles | Should -Not -BeNullOrEmpty
            $result.ResolvedCycleCount | Should -BeGreaterThan 0
            $result.ModifiedGraph | Should -Not -BeNullOrEmpty

            # Vérifier que les cycles n'ont pas été résolus
            $cycles = Find-ModuleDependencyCycles -DependencyGraph $result.ModifiedGraph
            $cycles.HasCycles | Should -Be $true
        }
    }

    Context "Get-ModuleDependencies" {
        It "Obtient les dépendances récursives d'un module" {
            # Obtenir les dépendances du module A
            $dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1")

            # Vérifier les dépendances
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

        It "Obtient les dépendances récursives d'un module avec des statistiques" {
            # Obtenir les dépendances du module A avec des statistiques
            $dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -IncludeStats

            # Vérifier les dépendances
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.ModuleName | Should -Be "ModuleA"
            $dependencies.DependencyGraph | Should -Not -BeNullOrEmpty
            $dependencies.VisitedModules | Should -Not -BeNullOrEmpty
            $dependencies.MaxDepth | Should -Be 10
            $dependencies.Stats | Should -Not -BeNullOrEmpty
            $dependencies.Stats.VisitedModulesCount | Should -Be 5
        }

        It "Obtient les dépendances récursives d'un module avec détection des cycles" {
            # Obtenir les dépendances du module A avec détection des cycles
            $dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -DetectCycles

            # Vérifier les dépendances
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

        It "Limite la profondeur de récursion" {
            # Obtenir les dépendances du module A avec une profondeur maximale de 1
            $dependencies = Get-ModuleDependencies -ModulePath (Join-Path -Path $moduleA.Path -ChildPath "$($moduleA.Name).psd1") -MaxDepth 1

            # Vérifier les dépendances
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
