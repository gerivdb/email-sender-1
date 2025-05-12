# Test-RealisticRoadmapGeneration.ps1
# Script de test pour le module de génération de roadmaps réalistes
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste les fonctionnalités du module de génération de roadmaps réalistes.

.DESCRIPTION
    Ce script teste les fonctionnalités du module Generate-RealisticRoadmap.ps1,
    en vérifiant que les fonctions de génération de roadmaps réalistes fonctionnent correctement.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer le module à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$generationPath = Join-Path -Path $parentPath -ChildPath "generation"
$modulePath = Join-Path -Path $generationPath -ChildPath "Generate-RealisticRoadmap.ps1"

Write-Host "Chargement du module: $modulePath" -ForegroundColor Cyan
if (Test-Path $modulePath) {
    Write-Host "Le fichier existe." -ForegroundColor Green
    . $modulePath
    Write-Host "Module chargé avec succès." -ForegroundColor Green
} else {
    Write-Host "Le fichier n'existe pas!" -ForegroundColor Red
    exit
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour le module de génération de roadmaps réalistes..." -ForegroundColor Cyan
    
    Test-RoadmapStatisticalModel
    Test-RealisticRoadmapGeneration
    Test-RoadmapStructure
    Test-RoadmapTasks
    
    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Fonction pour créer des roadmaps de test
function New-TestRoadmaps {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestDir
    )
    
    # Créer le dossier de test s'il n'existe pas
    if (-not (Test-Path $TestDir)) {
        New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
    }
    
    # Créer la première roadmap de test
    $roadmap1Content = @"
# Plan de test 1 pour la génération de roadmaps réalistes

## 1. Première section
- [x] **1.1** Tâche complétée de niveau 1
  - [x] **1.1.1** Sous-tâche complétée
    - [x] **1.1.1.1** Sous-sous-tâche complétée
  - [ ] **1.1.2** Sous-tâche en cours
    - [ ] **1.1.2.1** Sous-sous-tâche en cours
    - [ ] **1.1.2.2** Autre sous-sous-tâche en cours
- [ ] **1.2** Tâche en cours de niveau 1
  - [ ] **1.2.1** Sous-tâche en cours
  - [ ] **1.2.2** Autre sous-tâche en cours

## 2. Deuxième section
- [ ] **2.1** Tâche de développement
  - [ ] **2.1.1** Implémenter la fonctionnalité A
  - [ ] **2.1.2** Implémenter la fonctionnalité B
  - [ ] **2.1.3** Implémenter la fonctionnalité C
- [ ] **2.2** Tâche de test
  - [ ] **2.2.1** Tester la fonctionnalité A
  - [ ] **2.2.2** Tester la fonctionnalité B
  - [ ] **2.2.3** Tester la fonctionnalité C
"@
    
    $roadmap1Path = Join-Path -Path $TestDir -ChildPath "test-roadmap-1.md"
    $roadmap1Content | Out-File -FilePath $roadmap1Path -Encoding utf8
    
    # Créer la deuxième roadmap de test
    $roadmap2Content = @"
# Plan de test 2 pour la génération de roadmaps réalistes

## 1. Analyse et conception
- [x] **1.1** Analyser les besoins
  - [x] **1.1.1** Recueillir les exigences
  - [x] **1.1.2** Analyser les cas d'utilisation
- [x] **1.2** Concevoir l'architecture
  - [x] **1.2.1** Définir l'architecture globale
  - [x] **1.2.2** Concevoir les composants principaux

## 2. Développement
- [ ] **2.1** Développer le backend
  - [ ] **2.1.1** Implémenter la base de données
  - [ ] **2.1.2** Développer l'API REST
  - [ ] **2.1.3** Implémenter la logique métier
- [ ] **2.2** Développer le frontend
  - [ ] **2.2.1** Créer les composants UI
  - [ ] **2.2.2** Implémenter les interactions utilisateur
  - [ ] **2.2.3** Intégrer avec le backend

## 3. Tests et déploiement
- [ ] **3.1** Tester l'application
  - [ ] **3.1.1** Exécuter les tests unitaires
  - [ ] **3.1.2** Réaliser les tests d'intégration
  - [ ] **3.1.3** Effectuer les tests de performance
- [ ] **3.2** Déployer l'application
  - [ ] **3.2.1** Préparer l'environnement de production
  - [ ] **3.2.2** Déployer la version initiale
  - [ ] **3.2.3** Configurer la surveillance
"@
    
    $roadmap2Path = Join-Path -Path $TestDir -ChildPath "test-roadmap-2.md"
    $roadmap2Content | Out-File -FilePath $roadmap2Path -Encoding utf8
    
    return @($roadmap1Path, $roadmap2Path)
}

# Test pour la fonction New-RoadmapStatisticalModel
function Test-RoadmapStatisticalModel {
    Write-Host "`nTest de la fonction New-RoadmapStatisticalModel:" -ForegroundColor Yellow
    
    # Créer des roadmaps de test
    $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapTests"
    $roadmapPaths = New-TestRoadmaps -TestDir $testDir
    
    # Test 1: Créer un modèle statistique
    Write-Host "  Test 1: Créer un modèle statistique" -ForegroundColor Gray
    $modelOutputDir = Join-Path -Path $testDir -ChildPath "Models"
    $result = New-RoadmapStatisticalModel -RoadmapPaths $roadmapPaths -ModelName "TestModel" -OutputPath $modelOutputDir
    
    # Vérifier que le modèle est créé correctement
    $success = $true
    if ($null -eq $result) {
        Write-Host "    Échec: Aucun modèle retourné." -ForegroundColor Red
        $success = $false
    }
    elseif ($result.ModelName -ne "TestModel") {
        Write-Host "    Échec: Nom du modèle incorrect: $($result.ModelName)" -ForegroundColor Red
        $success = $false
    }
    elseif ($null -eq $result.StructuralParameters -or $result.StructuralParameters.Count -eq 0) {
        Write-Host "    Échec: Paramètres structurels manquants ou vides." -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "    Succès: Modèle statistique créé correctement." -ForegroundColor Green
        Write-Host "      Nom du modèle: $($result.ModelName)" -ForegroundColor Gray
        Write-Host "      Nombre moyen de tâches: $($result.StructuralParameters.AverageTaskCount)" -ForegroundColor Gray
        Write-Host "      Profondeur moyenne: $($result.StructuralParameters.AverageMaxDepth)" -ForegroundColor Gray
        
        # Vérifier que le fichier de modèle a été créé
        $modelFiles = Get-ChildItem -Path $modelOutputDir -Filter "*.clixml"
        if ($modelFiles.Count -gt 0) {
            Write-Host "      Fichier de modèle créé: $($modelFiles[0].FullName)" -ForegroundColor Gray
        } else {
            Write-Host "      Avertissement: Aucun fichier de modèle trouvé." -ForegroundColor Yellow
        }
    }
    
    # Test 2: Vérifier le comportement avec des fichiers inexistants
    Write-Host "  Test 2: Vérifier le comportement avec des fichiers inexistants" -ForegroundColor Gray
    $result = New-RoadmapStatisticalModel -RoadmapPaths @("C:\NonExistentFile1.md", "C:\NonExistentFile2.md") -ModelName "InvalidModel" -ErrorAction SilentlyContinue
    
    if ($null -eq $result) {
        Write-Host "    Succès: La fonction retourne null pour des fichiers inexistants." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La fonction ne retourne pas null pour des fichiers inexistants." -ForegroundColor Red
    }
}

# Test pour la fonction New-RealisticRoadmap
function Test-RealisticRoadmapGeneration {
    Write-Host "`nTest de la fonction New-RealisticRoadmap:" -ForegroundColor Yellow
    
    # Créer des roadmaps de test
    $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapTests"
    $roadmapPaths = New-TestRoadmaps -TestDir $testDir
    
    # Créer un modèle statistique
    $modelOutputDir = Join-Path -Path $testDir -ChildPath "Models"
    $model = New-RoadmapStatisticalModel -RoadmapPaths $roadmapPaths -ModelName "TestModel" -OutputPath $modelOutputDir
    
    # Test 1: Générer une roadmap réaliste à partir d'un modèle
    Write-Host "  Test 1: Générer une roadmap réaliste à partir d'un modèle" -ForegroundColor Gray
    $outputPath = Join-Path -Path $testDir -ChildPath "generated-roadmap.md"
    $result = New-RealisticRoadmap -Model $model -Title "Roadmap générée pour test" -OutputPath $outputPath -ThematicContext "Système de test"
    
    # Vérifier que la roadmap est générée correctement
    $success = $true
    if ($null -eq $result) {
        Write-Host "    Échec: Aucun résultat retourné." -ForegroundColor Red
        $success = $false
    }
    elseif (-not (Test-Path $result)) {
        Write-Host "    Échec: Le fichier de roadmap n'a pas été créé: $result" -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "    Succès: Roadmap réaliste générée correctement." -ForegroundColor Green
        Write-Host "      Fichier de roadmap: $result" -ForegroundColor Gray
        
        # Vérifier le contenu de la roadmap
        $content = Get-Content -Path $result -Raw
        $lines = ($content -split "`n").Count
        
        Write-Host "      Nombre de lignes: $lines" -ForegroundColor Gray
        
        if ($content -match "^# Roadmap générée pour test") {
            Write-Host "      Le titre est correct." -ForegroundColor Gray
        } else {
            Write-Host "      Avertissement: Le titre est incorrect." -ForegroundColor Yellow
        }
        
        if ($content -match "\- \[ \]|\- \[x\]") {
            Write-Host "      Les tâches sont présentes." -ForegroundColor Gray
        } else {
            Write-Host "      Avertissement: Aucune tâche trouvée." -ForegroundColor Yellow
        }
    }
    
    # Test 2: Générer une roadmap réaliste à partir d'un fichier de modèle
    Write-Host "  Test 2: Générer une roadmap réaliste à partir d'un fichier de modèle" -ForegroundColor Gray
    
    # Trouver le fichier de modèle
    $modelFiles = Get-ChildItem -Path $modelOutputDir -Filter "*.clixml"
    if ($modelFiles.Count -gt 0) {
        $modelPath = $modelFiles[0].FullName
        $outputPath = Join-Path -Path $testDir -ChildPath "generated-roadmap-from-file.md"
        
        $result = New-RealisticRoadmap -ModelPath $modelPath -Title "Roadmap générée depuis fichier" -OutputPath $outputPath -ThematicContext "Système de test depuis fichier"
        
        if ($null -eq $result) {
            Write-Host "    Échec: Aucun résultat retourné." -ForegroundColor Red
        }
        elseif (-not (Test-Path $result)) {
            Write-Host "    Échec: Le fichier de roadmap n'a pas été créé: $result" -ForegroundColor Red
        }
        else {
            Write-Host "    Succès: Roadmap réaliste générée correctement depuis un fichier de modèle." -ForegroundColor Green
            Write-Host "      Fichier de roadmap: $result" -ForegroundColor Gray
        }
    } else {
        Write-Host "    Ignoré: Aucun fichier de modèle trouvé pour le test." -ForegroundColor Yellow
    }
}

# Test pour la fonction New-RoadmapStructure
function Test-RoadmapStructure {
    Write-Host "`nTest de la fonction New-RoadmapStructure:" -ForegroundColor Yellow
    
    # Test 1: Générer une structure de roadmap
    Write-Host "  Test 1: Générer une structure de roadmap" -ForegroundColor Gray
    $branchingFactorDistribution = @{
        2 = 40
        3 = 40
        4 = 20
    }
    
    $result = New-RoadmapStructure -TaskCount 50 -MaxDepth 4 -BranchingFactorDistribution $branchingFactorDistribution
    
    # Vérifier que la structure est générée correctement
    $success = $true
    if ($null -eq $result) {
        Write-Host "    Échec: Aucun résultat retourné." -ForegroundColor Red
        $success = $false
    }
    elseif ($result.Count -eq 0) {
        Write-Host "    Échec: Aucune tâche générée." -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "    Succès: Structure de roadmap générée correctement." -ForegroundColor Green
        Write-Host "      Nombre de tâches générées: $($result.Count)" -ForegroundColor Gray
        
        # Vérifier la profondeur maximale
        $maxDepth = ($result | ForEach-Object { $_.Level } | Measure-Object -Maximum).Maximum
        Write-Host "      Profondeur maximale: $maxDepth" -ForegroundColor Gray
        
        # Vérifier les relations parent-enfant
        $rootTasks = $result | Where-Object { $null -eq $_.ParentId }
        $childTasks = $result | Where-Object { $null -ne $_.ParentId }
        
        Write-Host "      Tâches racines: $($rootTasks.Count)" -ForegroundColor Gray
        Write-Host "      Tâches enfants: $($childTasks.Count)" -ForegroundColor Gray
        
        # Vérifier que toutes les tâches enfants ont un parent valide
        $validParents = $true
        foreach ($task in $childTasks) {
            $parentId = $task.ParentId
            $parent = $result | Where-Object { $_.Id -eq $parentId } | Select-Object -First 1
            
            if ($null -eq $parent) {
                $validParents = $false
                break
            }
        }
        
        if ($validParents) {
            Write-Host "      Toutes les tâches enfants ont un parent valide." -ForegroundColor Gray
        } else {
            Write-Host "      Avertissement: Certaines tâches enfants n'ont pas de parent valide." -ForegroundColor Yellow
        }
    }
}

# Test pour la fonction New-RoadmapTasks
function Test-RoadmapTasks {
    Write-Host "`nTest de la fonction New-RoadmapTasks:" -ForegroundColor Yellow
    
    # Générer une structure de roadmap
    $branchingFactorDistribution = @{
        2 = 40
        3 = 40
        4 = 20
    }
    
    $structure = New-RoadmapStructure -TaskCount 20 -MaxDepth 3 -BranchingFactorDistribution $branchingFactorDistribution
    
    # Définir des distributions de longueur
    $nameLengthDistribution = @{
        20 = 10
        30 = 30
        40 = 40
        50 = 20
    }
    
    $descriptionLengthDistribution = @{
        0 = 10
        50 = 20
        100 = 40
        150 = 30
    }
    
    # Test 1: Générer des noms et descriptions de tâches
    Write-Host "  Test 1: Générer des noms et descriptions de tâches" -ForegroundColor Gray
    $result = New-RoadmapTasks -Structure $structure -ThematicContext "Système de gestion des roadmaps" -NameLengthDistribution $nameLengthDistribution -DescriptionLengthDistribution $descriptionLengthDistribution
    
    # Vérifier que les tâches sont générées correctement
    $success = $true
    if ($null -eq $result) {
        Write-Host "    Échec: Aucun résultat retourné." -ForegroundColor Red
        $success = $false
    }
    elseif ($result.Count -eq 0) {
        Write-Host "    Échec: Aucune tâche générée." -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "    Succès: Tâches générées correctement." -ForegroundColor Green
        Write-Host "      Nombre de tâches générées: $($result.Count)" -ForegroundColor Gray
        
        # Vérifier que toutes les tâches ont un titre
        $allHaveTitles = $true
        foreach ($task in $result) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $allHaveTitles = $false
                break
            }
        }
        
        if ($allHaveTitles) {
            Write-Host "      Toutes les tâches ont un titre." -ForegroundColor Gray
        } else {
            Write-Host "      Avertissement: Certaines tâches n'ont pas de titre." -ForegroundColor Yellow
        }
        
        # Afficher quelques exemples de tâches
        Write-Host "      Exemples de tâches:" -ForegroundColor Gray
        for ($i = 0; $i -lt [Math]::Min(3, $result.Count); $i++) {
            $task = $result[$i]
            Write-Host "        $($task.Id): $($task.Title)" -ForegroundColor Gray
            if (-not [string]::IsNullOrEmpty($task.Description)) {
                Write-Host "          $($task.Description)" -ForegroundColor Gray
            }
        }
    }
}

# Exécuter tous les tests
Write-Host "Démarrage des tests..." -ForegroundColor Cyan
Invoke-AllTests
Write-Host "Fin des tests." -ForegroundColor Cyan

# Nettoyer les fichiers de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapTests"
if (Test-Path $testDir) {
    Write-Host "Nettoyage des fichiers de test..." -ForegroundColor Cyan
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Cyan
}
