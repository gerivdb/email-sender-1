﻿# Test-RoadmapChangeDetection.ps1
# Script de test pour vérifier le bon fonctionnement du système de détection des changements dans les roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Verbose,

    [Parameter(Mandatory = $false)]
    [switch]$CreateTestFiles,

    [Parameter(Mandatory = $false)]
    [string]$TestDataDirectory = "development/scripts/roadmap/rag/tests/data",

    [Parameter(Mandatory = $false)]
    [switch]$CleanupAfterTests
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"

# Importer les fonctions utilitaires
. (Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1")
. (Join-Path -Path $utilsPath -ChildPath "Parse-Markdown.ps1")
. (Join-Path -Path $utilsPath -ChildPath "Format-Output.ps1")

# Importer le script principal à tester
$scriptToTest = Join-Path -Path $parentPath -ChildPath "Detect-RoadmapChanges.ps1"
. $scriptToTest

# Fonction pour créer des fichiers de test
function New-TestFiles {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestDataDirectory
    )

    # Créer le répertoire de test s'il n'existe pas
    if (-not (Test-Path -Path $TestDataDirectory)) {
        New-Item -Path $TestDataDirectory -ItemType Directory -Force | Out-Null
        Write-Log "Répertoire de test créé: $TestDataDirectory" -Level Info
    }

    # Créer un fichier de roadmap original
    $originalContent = @"
# Roadmap de test - Version originale

## 1. Section 1
- [x] **1.1** Tâche complétée
- [ ] **1.2** Tâche à faire
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2

## 2. Section 2
- [ ] **2.1** Autre tâche
- [ ] **2.2** Encore une tâche
  - [ ] **2.2.1** Sous-tâche A
  - [ ] **2.2.2** Sous-tâche B

## 3. Section 3
- [ ] **3.1** Dernière tâche
"@

    $originalPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_original.md"
    Set-Content -Path $originalPath -Value $originalContent -Encoding UTF8
    Write-Log "Fichier de roadmap original créé: $originalPath" -Level Success

    # Créer un fichier de roadmap modifié avec des changements
    $modifiedContent = @"
# Roadmap de test - Version modifiée

## 1. Section 1 (mise à jour)
- [x] **1.1** Tâche complétée
- [x] **1.2** Tâche maintenant complétée
  - [ ] **1.2.1** Sous-tâche 1
  - [x] **1.2.2** Sous-tâche 2 terminée

## 2. Section 2
- [ ] **2.1** Autre tâche modifiée
- [ ] **2.3** Nouvelle tâche ajoutée
  - [ ] **2.3.1** Nouvelle sous-tâche

## 3. Section 3
- [ ] **3.1** Dernière tâche
- [ ] **3.2** Tâche supplémentaire
"@

    $modifiedPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_modified.md"
    Set-Content -Path $modifiedPath -Value $modifiedContent -Encoding UTF8
    Write-Log "Fichier de roadmap modifié créé: $modifiedPath" -Level Success

    # Créer un fichier de roadmap avec des changements structurels
    $structuralChangesContent = @"
# Roadmap de test - Version avec changements structurels

## 1. Section renommée
- [x] **1.1** Tâche complétée
- [ ] **1.2** Tâche à faire
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2

## 4. Nouvelle section
- [ ] **4.1** Tâche dans nouvelle section
  - [ ] **4.1.1** Sous-tâche X
  - [ ] **4.1.2** Sous-tâche Y

## 3. Section 3
- [ ] **3.1** Dernière tâche
"@

    $structuralChangesPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_structural_changes.md"
    Set-Content -Path $structuralChangesPath -Value $structuralChangesContent -Encoding UTF8
    Write-Log "Fichier de roadmap avec changements structurels créé: $structuralChangesPath" -Level Success

    # Créer un fichier de roadmap identique pour tester la détection de non-changement
    $identicalPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_identical.md"
    Set-Content -Path $identicalPath -Value $originalContent -Encoding UTF8
    Write-Log "Fichier de roadmap identique créé: $identicalPath" -Level Success

    return @{
        OriginalPath          = $originalPath
        ModifiedPath          = $modifiedPath
        StructuralChangesPath = $structuralChangesPath
        IdenticalPath         = $identicalPath
    }
}

# Fonction pour exécuter les tests
function Invoke-RoadmapChangeDetectionTests {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestFiles,

        [Parameter(Mandatory = $false)]
        [switch]$Verbose
    )

    $testResults = @{
        TotalTests  = 0
        PassedTests = 0
        FailedTests = 0
        Results     = @()
    }

    # Test 1: Détecter des changements entre original et modifié
    $testResults.TotalTests++
    Write-Log "Test 1: Détecter des changements entre original et modifié" -Level Info

    $outputPath = Join-Path -Path $TestDataDirectory -ChildPath "test1_results.txt"
    $result = Invoke-RoadmapChangeDetection -RoadmapPath $TestFiles.ModifiedPath -PreviousVersionPath $TestFiles.OriginalPath -OutputPath $outputPath -OutputFormat "Text" -Detailed

    if ($result) {
        $testResults.PassedTests++
        Write-Log "Test 1: Réussi - Des changements ont été détectés" -Level Success
        $testResults.Results += @{
            TestName = "Détecter des changements entre original et modifié"
            Result   = "Réussi"
            Details  = "Des changements ont été détectés"
        }
    } else {
        $testResults.FailedTests++
        Write-Log "Test 1: Échec - Aucun changement détecté alors qu'il devrait y en avoir" -Level Error
        $testResults.Results += @{
            TestName = "Détecter des changements entre original et modifié"
            Result   = "Échec"
            Details  = "Aucun changement détecté alors qu'il devrait y en avoir"
        }
    }

    # Test 2: Détecter des changements structurels
    $testResults.TotalTests++
    Write-Log "Test 2: Détecter des changements structurels" -Level Info

    $outputPath = Join-Path -Path $TestDataDirectory -ChildPath "test2_results.txt"
    $result = Invoke-RoadmapChangeDetection -RoadmapPath $TestFiles.StructuralChangesPath -PreviousVersionPath $TestFiles.OriginalPath -OutputPath $outputPath -OutputFormat "Text" -Detailed

    if ($result) {
        $testResults.PassedTests++
        Write-Log "Test 2: Réussi - Des changements structurels ont été détectés" -Level Success
        $testResults.Results += @{
            TestName = "Détecter des changements structurels"
            Result   = "Réussi"
            Details  = "Des changements structurels ont été détectés"
        }
    } else {
        $testResults.FailedTests++
        Write-Log "Test 2: Échec - Aucun changement structurel détecté alors qu'il devrait y en avoir" -Level Error
        $testResults.Results += @{
            TestName = "Détecter des changements structurels"
            Result   = "Échec"
            Details  = "Aucun changement structurel détecté alors qu'il devrait y en avoir"
        }
    }

    # Test 3: Ne pas détecter de changements entre fichiers identiques
    $testResults.TotalTests++
    Write-Log "Test 3: Ne pas détecter de changements entre fichiers identiques" -Level Info

    $outputPath = Join-Path -Path $TestDataDirectory -ChildPath "test3_results.txt"
    $result = Invoke-RoadmapChangeDetection -RoadmapPath $TestFiles.IdenticalPath -PreviousVersionPath $TestFiles.OriginalPath -OutputPath $outputPath -OutputFormat "Text" -Detailed

    if (-not $result) {
        $testResults.PassedTests++
        Write-Log "Test 3: Réussi - Aucun changement détecté entre fichiers identiques" -Level Success
        $testResults.Results += @{
            TestName = "Ne pas détecter de changements entre fichiers identiques"
            Result   = "Réussi"
            Details  = "Aucun changement détecté entre fichiers identiques"
        }
    } else {
        $testResults.FailedTests++
        Write-Log "Test 3: Échec - Des changements ont été détectés alors qu'il ne devrait pas y en avoir" -Level Error
        $testResults.Results += @{
            TestName = "Ne pas détecter de changements entre fichiers identiques"
            Result   = "Échec"
            Details  = "Des changements ont été détectés alors qu'il ne devrait pas y en avoir"
        }
    }

    # Test 4: Tester différents formats de sortie
    $testResults.TotalTests++
    Write-Log "Test 4: Tester différents formats de sortie" -Level Info

    $formats = @("Text", "JSON", "Markdown", "HTML")
    $formatResults = @()

    foreach ($format in $formats) {
        $outputPath = Join-Path -Path $TestDataDirectory -ChildPath "test4_results_$format.$($format.ToLower())"
        $result = Invoke-RoadmapChangeDetection -RoadmapPath $TestFiles.ModifiedPath -PreviousVersionPath $TestFiles.OriginalPath -OutputPath $outputPath -OutputFormat $format -Detailed

        if (Test-Path -Path $outputPath) {
            $formatResults += "$format: OK"
        } else {
            $formatResults += "$format: Échec"
        }
    }

    if ($formatResults -notcontains "*: Échec") {
        $testResults.PassedTests++
        Write-Log "Test 4: Réussi - Tous les formats de sortie fonctionnent" -Level Success
        $testResults.Results += @{
            TestName = "Tester différents formats de sortie"
            Result   = "Réussi"
            Details  = $formatResults -join ", "
        }
    } else {
        $testResults.FailedTests++
        Write-Log "Test 4: Échec - Certains formats de sortie ne fonctionnent pas" -Level Error
        $testResults.Results += @{
            TestName = "Tester différents formats de sortie"
            Result   = "Échec"
            Details  = $formatResults -join ", "
        }
    }

    # Afficher le résumé des tests
    Write-Log "Résumé des tests:" -Level Info
    Write-Log "  - Tests totaux: $($testResults.TotalTests)" -Level Info
    Write-Log "  - Tests réussis: $($testResults.PassedTests)" -Level Success
    Write-Log "  - Tests échoués: $($testResults.FailedTests)" -Level ($testResults.FailedTests -gt 0 ? "Error" : "Info")

    return $testResults
}

# Fonction principale
function Main {
    Write-Log "Démarrage des tests de détection des changements dans les roadmaps" -Level Info

    # Créer les fichiers de test si demandé
    if ($CreateTestFiles -or -not (Test-Path -Path $TestDataDirectory)) {
        $testFiles = New-TestFiles -TestDataDirectory $TestDataDirectory
    } else {
        # Utiliser les fichiers existants
        $testFiles = @{
            OriginalPath          = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_original.md"
            ModifiedPath          = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_modified.md"
            StructuralChangesPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_structural_changes.md"
            IdenticalPath         = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_identical.md"
        }
    }

    # Exécuter les tests
    $testResults = Invoke-RoadmapChangeDetectionTests -TestFiles $testFiles -Verbose:$Verbose

    # Nettoyer les fichiers de test si demandé
    if ($CleanupAfterTests) {
        Remove-Item -Path $TestDataDirectory -Recurse -Force
        Write-Log "Nettoyage des fichiers de test terminé" -Level Info
    }

    # Retourner les résultats des tests
    return $testResults
}

# Exécuter la fonction principale
Main
