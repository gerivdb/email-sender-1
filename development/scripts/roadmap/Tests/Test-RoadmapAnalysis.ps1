# Test-RoadmapAnalysis.ps1
# Script de test pour le module d'analyse de roadmaps
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste les fonctionnalités du module d'analyse de roadmaps.

.DESCRIPTION
    Ce script teste les fonctionnalités du module Analyze-RoadmapStructure.ps1,
    en vérifiant que les fonctions d'analyse de roadmaps fonctionnent correctement.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer le module à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$analysisPath = Join-Path -Path $parentPath -ChildPath "analysis"
$modulePath = Join-Path -Path $analysisPath -ChildPath "Analyze-RoadmapStructure.ps1"

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
    Write-Host "Exécution des tests pour le module d'analyse de roadmaps..." -ForegroundColor Cyan
    
    Test-RoadmapStructuralStatistics
    Test-RoadmapMetadataDistributions
    Test-RoadmapRecurringPatterns
    Test-RoadmapAnalysis
    
    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Fonction pour créer une roadmap de test
function New-TestRoadmap {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $roadmapContent = @"
# Plan de test pour l'analyse de roadmaps

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
- [ ] **2.3** Tâche de documentation
  - [ ] **2.3.1** Documenter la fonctionnalité A
  - [ ] **2.3.2** Documenter la fonctionnalité B
  - [ ] **2.3.3** Documenter la fonctionnalité C

## 3. Troisième section
- [ ] **3.1** Première tâche similaire
  - [ ] **3.1.1** Sous-tâche similaire 1
  - [ ] **3.1.2** Sous-tâche similaire 2
- [ ] **3.2** Deuxième tâche similaire
  - [ ] **3.2.1** Sous-tâche similaire 1
  - [ ] **3.2.2** Sous-tâche similaire 2
- [ ] **3.3** Troisième tâche similaire
  - [ ] **3.3.1** Sous-tâche similaire 1
  - [ ] **3.3.2** Sous-tâche similaire 2
"@
    
    # Créer le dossier de test s'il n'existe pas
    $testDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $testDir)) {
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    }
    
    # Écrire le contenu dans le fichier
    $roadmapContent | Out-File -FilePath $OutputPath -Encoding utf8
    
    Write-Host "Roadmap de test créée: $OutputPath" -ForegroundColor Green
    return $OutputPath
}

# Test pour la fonction Get-RoadmapStructuralStatistics
function Test-RoadmapStructuralStatistics {
    Write-Host "`nTest de la fonction Get-RoadmapStructuralStatistics:" -ForegroundColor Yellow
    
    # Créer une roadmap de test
    $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapTests"
    $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
    New-TestRoadmap -OutputPath $testRoadmapPath
    
    # Test 1: Extraire les statistiques structurelles
    Write-Host "  Test 1: Extraire les statistiques structurelles" -ForegroundColor Gray
    $result = Get-RoadmapStructuralStatistics -RoadmapPath $testRoadmapPath
    
    # Vérifier que les statistiques de base sont correctes
    $success = $true
    if ($null -eq $result) {
        Write-Host "    Échec: Aucun résultat retourné." -ForegroundColor Red
        $success = $false
    }
    elseif ($result.TotalTasks -le 0) {
        Write-Host "    Échec: Nombre total de tâches incorrect: $($result.TotalTasks)" -ForegroundColor Red
        $success = $false
    }
    elseif ($result.MaxDepth -le 0) {
        Write-Host "    Échec: Profondeur maximale incorrecte: $($result.MaxDepth)" -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "    Succès: Statistiques structurelles extraites correctement." -ForegroundColor Green
        Write-Host "      Nombre total de tâches: $($result.TotalTasks)" -ForegroundColor Gray
        Write-Host "      Tâches complétées: $($result.CompletedTasks)" -ForegroundColor Gray
        Write-Host "      Tâches en cours: $($result.PendingTasks)" -ForegroundColor Gray
        Write-Host "      Profondeur maximale: $($result.MaxDepth)" -ForegroundColor Gray
        
        Write-Host "      Tâches par niveau:" -ForegroundColor Gray
        foreach ($level in $result.TasksPerLevel.Keys | Sort-Object) {
            Write-Host "        Niveau $level: $($result.TasksPerLevel[$level]) tâches" -ForegroundColor Gray
        }
    }
    
    # Test 2: Vérifier le comportement avec un fichier inexistant
    Write-Host "  Test 2: Vérifier le comportement avec un fichier inexistant" -ForegroundColor Gray
    $result = Get-RoadmapStructuralStatistics -RoadmapPath "C:\NonExistentFile.md" -ErrorAction SilentlyContinue
    
    if ($null -eq $result) {
        Write-Host "    Succès: La fonction retourne null pour un fichier inexistant." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La fonction ne retourne pas null pour un fichier inexistant." -ForegroundColor Red
    }
}

# Test pour la fonction Get-RoadmapMetadataDistributions
function Test-RoadmapMetadataDistributions {
    Write-Host "`nTest de la fonction Get-RoadmapMetadataDistributions:" -ForegroundColor Yellow
    
    # Utiliser la roadmap de test créée précédemment
    $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapTests"
    $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
    
    # Test 1: Extraire les distributions de métadonnées
    Write-Host "  Test 1: Extraire les distributions de métadonnées" -ForegroundColor Gray
    $result = Get-RoadmapMetadataDistributions -RoadmapPath $testRoadmapPath
    
    # Vérifier que les distributions sont correctes
    $success = $true
    if ($null -eq $result) {
        Write-Host "    Échec: Aucun résultat retourné." -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "    Succès: Distributions de métadonnées extraites correctement." -ForegroundColor Green
        
        # Afficher les distributions disponibles
        Write-Host "      Distributions disponibles:" -ForegroundColor Gray
        foreach ($field in $result.Keys | Where-Object { $_ -ne "ByLevel" }) {
            Write-Host "        $field" -ForegroundColor Gray
        }
        
        # Afficher les distributions par niveau
        if ($result.ContainsKey("ByLevel")) {
            Write-Host "      Distributions par niveau:" -ForegroundColor Gray
            foreach ($level in $result.ByLevel.Keys | Sort-Object) {
                Write-Host "        $level" -ForegroundColor Gray
            }
        }
    }
    
    # Test 2: Vérifier le comportement avec un fichier inexistant
    Write-Host "  Test 2: Vérifier le comportement avec un fichier inexistant" -ForegroundColor Gray
    $result = Get-RoadmapMetadataDistributions -RoadmapPath "C:\NonExistentFile.md" -ErrorAction SilentlyContinue
    
    if ($null -eq $result) {
        Write-Host "    Succès: La fonction retourne null pour un fichier inexistant." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La fonction ne retourne pas null pour un fichier inexistant." -ForegroundColor Red
    }
}

# Test pour la fonction Get-RoadmapRecurringPatterns
function Test-RoadmapRecurringPatterns {
    Write-Host "`nTest de la fonction Get-RoadmapRecurringPatterns:" -ForegroundColor Yellow
    
    # Utiliser la roadmap de test créée précédemment
    $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapTests"
    $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
    
    # Test 1: Détecter les patterns récurrents
    Write-Host "  Test 1: Détecter les patterns récurrents" -ForegroundColor Gray
    $result = Get-RoadmapRecurringPatterns -RoadmapPath $testRoadmapPath
    
    # Vérifier que des patterns sont détectés
    $success = $true
    if ($null -eq $result) {
        Write-Host "    Échec: Aucun résultat retourné." -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "    Succès: Patterns récurrents détectés correctement." -ForegroundColor Green
        Write-Host "      Nombre de patterns détectés: $($result.Count)" -ForegroundColor Gray
        
        # Afficher les types de patterns détectés
        $patternTypes = $result | ForEach-Object { $_.Type } | Sort-Object -Unique
        Write-Host "      Types de patterns détectés: $($patternTypes -join ', ')" -ForegroundColor Gray
        
        # Afficher quelques exemples de patterns
        if ($result.Count -gt 0) {
            Write-Host "      Exemples de patterns:" -ForegroundColor Gray
            for ($i = 0; $i -lt [Math]::Min(3, $result.Count); $i++) {
                Write-Host "        $($result[$i].Pattern)" -ForegroundColor Gray
            }
        }
    }
    
    # Test 2: Vérifier le comportement avec un fichier inexistant
    Write-Host "  Test 2: Vérifier le comportement avec un fichier inexistant" -ForegroundColor Gray
    $result = Get-RoadmapRecurringPatterns -RoadmapPath "C:\NonExistentFile.md" -ErrorAction SilentlyContinue
    
    if ($null -eq $result) {
        Write-Host "    Succès: La fonction retourne null pour un fichier inexistant." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La fonction ne retourne pas null pour un fichier inexistant." -ForegroundColor Red
    }
}

# Test pour la fonction Invoke-RoadmapAnalysis
function Test-RoadmapAnalysis {
    Write-Host "`nTest de la fonction Invoke-RoadmapAnalysis:" -ForegroundColor Yellow
    
    # Utiliser la roadmap de test créée précédemment
    $testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapTests"
    $testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
    $outputDir = Join-Path -Path $testDir -ChildPath "Analysis"
    
    # Test 1: Effectuer une analyse complète
    Write-Host "  Test 1: Effectuer une analyse complète" -ForegroundColor Gray
    $result = Invoke-RoadmapAnalysis -RoadmapPath $testRoadmapPath -OutputPath $outputDir -Format "JSON"
    
    # Vérifier que l'analyse est correcte
    $success = $true
    if ($null -eq $result) {
        Write-Host "    Échec: Aucun résultat retourné." -ForegroundColor Red
        $success = $false
    }
    elseif ($null -eq $result.StructuralStatistics) {
        Write-Host "    Échec: Statistiques structurelles manquantes." -ForegroundColor Red
        $success = $false
    }
    elseif ($null -eq $result.MetadataDistributions) {
        Write-Host "    Échec: Distributions de métadonnées manquantes." -ForegroundColor Red
        $success = $false
    }
    elseif ($null -eq $result.RecurringPatterns) {
        Write-Host "    Échec: Patterns récurrents manquants." -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "    Succès: Analyse complète effectuée correctement." -ForegroundColor Green
        Write-Host "      Nom de la roadmap: $($result.RoadmapName)" -ForegroundColor Gray
        Write-Host "      Date d'analyse: $($result.AnalysisDate)" -ForegroundColor Gray
        Write-Host "      Nombre total de tâches: $($result.StructuralStatistics.TotalTasks)" -ForegroundColor Gray
        
        # Vérifier que le fichier de sortie a été créé
        $outputFiles = Get-ChildItem -Path $outputDir -Filter "*.json"
        if ($outputFiles.Count -gt 0) {
            Write-Host "      Fichier de sortie créé: $($outputFiles[0].FullName)" -ForegroundColor Gray
        } else {
            Write-Host "      Avertissement: Aucun fichier de sortie trouvé." -ForegroundColor Yellow
        }
    }
    
    # Test 2: Vérifier le comportement avec un fichier inexistant
    Write-Host "  Test 2: Vérifier le comportement avec un fichier inexistant" -ForegroundColor Gray
    $result = Invoke-RoadmapAnalysis -RoadmapPath "C:\NonExistentFile.md" -ErrorAction SilentlyContinue
    
    if ($null -eq $result) {
        Write-Host "    Succès: La fonction retourne null pour un fichier inexistant." -ForegroundColor Green
    } else {
        Write-Host "    Échec: La fonction ne retourne pas null pour un fichier inexistant." -ForegroundColor Red
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
