# Test-HierarchicalDiagramGenerator.ps1
# Script de test pour le générateur de diagrammes hiérarchiques
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Tests unitaires pour le générateur de diagrammes hiérarchiques.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du générateur de diagrammes hiérarchiques, notamment la conversion des données
    de roadmap en structure hiérarchique et la génération de code D3.js et Mermaid.

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$generatorPath = Join-Path -Path $scriptPath -ChildPath "..\HierarchicalDiagramGenerator.ps1"
$visualizationTypesPath = Join-Path -Path $scriptPath -ChildPath "..\..\VisualizationTypes.ps1"

if (Test-Path -Path $generatorPath) {
    . $generatorPath
}
else {
    Write-Error "Le fichier HierarchicalDiagramGenerator.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $visualizationTypesPath) {
    . $visualizationTypesPath
}
else {
    Write-Error "Le fichier VisualizationTypes.ps1 est introuvable."
    exit 1
}

# Créer un répertoire temporaire pour les fichiers de test
$testOutputDir = Join-Path -Path $env:TEMP -ChildPath "HierarchicalDiagramTests"
if (-not (Test-Path -Path $testOutputDir)) {
    New-Item -Path $testOutputDir -ItemType Directory | Out-Null
}

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testOutputDir -ChildPath "test-roadmap.md"
@"
# Test Roadmap

## 1. Section 1
- [x] **1.1** Tâche terminée
  - [x] **1.1.1** Sous-tâche terminée
  - [ ] **1.1.2** Sous-tâche en cours
- [ ] **1.2** Tâche en cours
  - [ ] **1.2.1** Sous-tâche à faire
  - [ ] **1.2.2** Sous-tâche bloquée

## 2. Section 2
- [ ] **2.1** Tâche à priorité haute
  - [ ] **2.1.1** Sous-tâche
- [ ] **2.2** Tâche à priorité basse
"@ | Out-File -FilePath $testRoadmapPath -Encoding utf8

# Définir les tests Pester
Describe "HierarchicalDiagramGenerator" {
    Context "Convert-RoadmapToHierarchy" {
        BeforeAll {
            # Créer des données de roadmap simulées pour les tests
            $mockRoadmapData = @{
                Title = "Test Roadmap"
                Items = @(
                    @{
                        Id = "1"
                        Title = "Section 1"
                        IsCompleted = $false
                        IsBlocked = $false
                        Progress = 50
                        Description = "Section de test 1"
                        Metadata = @{}
                        Children = @(
                            @{
                                Id = "1.1"
                                Title = "Tâche terminée"
                                IsCompleted = $true
                                IsBlocked = $false
                                Progress = 100
                                Description = "Tâche de test terminée"
                                Metadata = @{}
                                Children = @(
                                    @{
                                        Id = "1.1.1"
                                        Title = "Sous-tâche terminée"
                                        IsCompleted = $true
                                        IsBlocked = $false
                                        Progress = 100
                                        Description = "Sous-tâche de test terminée"
                                        Metadata = @{}
                                        Children = @()
                                    },
                                    @{
                                        Id = "1.1.2"
                                        Title = "Sous-tâche en cours"
                                        IsCompleted = $false
                                        IsBlocked = $false
                                        Progress = 50
                                        Description = "Sous-tâche de test en cours"
                                        Metadata = @{}
                                        Children = @()
                                    }
                                )
                            }
                        )
                    }
                )
            }

            # Convertir les données en structure hiérarchique
            $script:hierarchyData = Convert-RoadmapToHierarchy -RoadmapData $mockRoadmapData
        }

        It "Devrait créer un nœud racine" {
            $script:hierarchyData | Should -Not -BeNullOrEmpty
            $script:hierarchyData.Id | Should -Be "root"
            $script:hierarchyData.Title | Should -Be "Roadmap"
        }

        It "Devrait convertir correctement la structure hiérarchique" {
            $script:hierarchyData.Children.Count | Should -Be 1
            $script:hierarchyData.Children[0].Id | Should -Be "1"
            $script:hierarchyData.Children[0].Children.Count | Should -Be 1
            $script:hierarchyData.Children[0].Children[0].Id | Should -Be "1.1"
            $script:hierarchyData.Children[0].Children[0].Children.Count | Should -Be 2
        }

        It "Devrait calculer correctement la progression" {
            $script:hierarchyData.Progress | Should -BeGreaterThan 0
            $script:hierarchyData.Children[0].Children[0].Progress | Should -Be 75  # Moyenne de 100% et 50%
        }

        It "Devrait définir correctement les statuts" {
            $script:hierarchyData.Children[0].Children[0].Children[0].Status | Should -Be "Terminé"
            $script:hierarchyData.Children[0].Children[0].Children[1].Status | Should -Be "En cours"
        }
    }

    Context "Convert-HierarchyToD3" {
        BeforeAll {
            # Créer un nœud hiérarchique simple pour les tests
            $rootNode = [HierarchicalNode]::new("root", "Test Roadmap", "En cours", "Haute", 0)
            $rootNode.Description = "Roadmap de test"
            
            $node1 = [HierarchicalNode]::new("1", "Section 1", "En cours", "Haute", 1)
            $node1.Progress = 50
            
            $node11 = [HierarchicalNode]::new("1.1", "Tâche 1.1", "Terminé", "Moyenne", 2)
            $node11.Progress = 100
            
            $node12 = [HierarchicalNode]::new("1.2", "Tâche 1.2", "Bloqué", "Critique", 2)
            $node12.Progress = 30
            
            $node1.AddChild($node11)
            $node1.AddChild($node12)
            $rootNode.AddChild($node1)
            
            # Générer le code D3.js
            $script:d3Code = Convert-HierarchyToD3 -HierarchyData $rootNode
        }

        It "Devrait générer du code D3.js valide" {
            $script:d3Code | Should -Not -BeNullOrEmpty
            $script:d3Code | Should -Match "const hierarchyData ="
            $script:d3Code | Should -Match "d3.hierarchy"
            $script:d3Code | Should -Match "d3.tree"
        }

        It "Devrait inclure les données hiérarchiques" {
            $script:d3Code | Should -Match "Test Roadmap"
            $script:d3Code | Should -Match "Section 1"
            $script:d3Code | Should -Match "Tâche 1.1"
            $script:d3Code | Should -Match "Tâche 1.2"
        }

        It "Devrait inclure les couleurs de statut" {
            $script:d3Code | Should -Match "#2ECC71"  # Couleur pour "Terminé"
            $script:d3Code | Should -Match "#E74C3C"  # Couleur pour "Bloqué"
            $script:d3Code | Should -Match "#4A86E8"  # Couleur pour "En cours"
        }
    }

    Context "Convert-HierarchyToMermaid" {
        BeforeAll {
            # Créer un nœud hiérarchique simple pour les tests
            $rootNode = [HierarchicalNode]::new("root", "Test Roadmap", "En cours", "Haute", 0)
            $rootNode.Description = "Roadmap de test"
            
            $node1 = [HierarchicalNode]::new("1", "Section 1", "En cours", "Haute", 1)
            $node1.Progress = 50
            
            $node11 = [HierarchicalNode]::new("1.1", "Tâche 1.1", "Terminé", "Moyenne", 2)
            $node11.Progress = 100
            
            $node12 = [HierarchicalNode]::new("1.2", "Tâche 1.2", "Bloqué", "Critique", 2)
            $node12.Progress = 30
            
            $node1.AddChild($node11)
            $node1.AddChild($node12)
            $rootNode.AddChild($node1)
            
            # Générer le code Mermaid
            $script:mermaidCode = Convert-HierarchyToMermaid -HierarchyData $rootNode
        }

        It "Devrait générer du code Mermaid valide" {
            $script:mermaidCode | Should -Not -BeNullOrEmpty
            $script:mermaidCode | Should -Match "graph TD"
            $script:mermaidCode | Should -Match "-->"
        }

        It "Devrait inclure les nœuds avec leurs identifiants" {
            $script:mermaidCode | Should -Match "root\["
            $script:mermaidCode | Should -Match "1\["
            $script:mermaidCode | Should -Match "1_1\["
            $script:mermaidCode | Should -Match "1_2\["
        }

        It "Devrait inclure les styles basés sur le statut" {
            $script:mermaidCode | Should -Match "fill:#2ECC71"  # Couleur pour "Terminé"
            $script:mermaidCode | Should -Match "fill:#E74C3C"  # Couleur pour "Bloqué"
            $script:mermaidCode | Should -Match "fill:#4A86E8"  # Couleur pour "En cours"
        }

        It "Devrait inclure les classes de style" {
            $script:mermaidCode | Should -Match "classDef terminé"
            $script:mermaidCode | Should -Match "classDef encours"
            $script:mermaidCode | Should -Match "classDef bloqué"
        }
    }

    Context "New-HierarchicalDiagram" {
        It "Devrait générer un diagramme D3.js à partir d'un fichier de roadmap" {
            $outputPath = Join-Path -Path $testOutputDir -ChildPath "test-d3.js"
            $result = New-HierarchicalDiagram -RoadmapFilePath $testRoadmapPath -Technology ([VisualizationTechnology]::D3js) -OutputPath $outputPath
            
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -Be $true
            Get-Content -Path $outputPath | Should -Match "const hierarchyData ="
        }

        It "Devrait générer un diagramme Mermaid à partir d'un fichier de roadmap" {
            $outputPath = Join-Path -Path $testOutputDir -ChildPath "test-mermaid.mmd"
            $result = New-HierarchicalDiagram -RoadmapFilePath $testRoadmapPath -Technology ([VisualizationTechnology]::Mermaid) -OutputPath $outputPath
            
            $result | Should -Not -BeNullOrEmpty
            Test-Path -Path $outputPath | Should -Be $true
            Get-Content -Path $outputPath | Should -Match "graph TD"
        }

        It "Devrait respecter l'option IncludeCompleted" {
            $outputPath = Join-Path -Path $testOutputDir -ChildPath "test-no-completed.js"
            $result = New-HierarchicalDiagram -RoadmapFilePath $testRoadmapPath -Technology ([VisualizationTechnology]::D3js) -OutputPath $outputPath -IncludeCompleted:$false
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Not -Match "Tâche terminée"
        }

        It "Devrait appliquer les options personnalisées" {
            $options = @{
                width = 800
                height = 600
                orientation = "horizontal"
            }
            
            $outputPath = Join-Path -Path $testOutputDir -ChildPath "test-options.js"
            $result = New-HierarchicalDiagram -RoadmapFilePath $testRoadmapPath -Technology ([VisualizationTechnology]::D3js) -OutputPath $outputPath -Options $options
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "const width = 800"
            $result | Should -Match "const height = 600"
            $result | Should -Match "const orientation = `"horizontal`""
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $MyInvocation.MyCommand.Path -Output Detailed

# Nettoyer les fichiers de test
# Remove-Item -Path $testOutputDir -Recurse -Force
