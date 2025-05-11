﻿# Test-RoadmapRAGSystem.ps1
# Script pour tester l'ensemble du système RAG pour les roadmaps
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
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_test",

    [Parameter(Mandatory = $false)]
    [switch]$CleanupAfterTests
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"

# Importer les fonctions utilitaires
. (Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1")

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

    # Créer un fichier de roadmap similaire pour tester la détection des doublons
    $duplicateContent = @"
# Roadmap de test - Version similaire

## 1. Section 1
- [x] **1.1** Tâche complétée
- [ ] **1.2** Tâche à faire
  - [ ] **1.2.1** Sous-tâche 1 légèrement modifiée
  - [ ] **1.2.2** Sous-tâche 2

## 2. Section 2
- [ ] **2.1** Autre tâche
- [ ] **2.2** Encore une tâche
  - [ ] **2.2.1** Sous-tâche A
  - [ ] **2.2.2** Sous-tâche B

## 3. Section 3
- [ ] **3.1** Dernière tâche
"@

    $duplicatePath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_duplicate.md"
    Set-Content -Path $duplicatePath -Value $duplicateContent -Encoding UTF8
    Write-Log "Fichier de roadmap similaire créé: $duplicatePath" -Level Success

    return @{
        OriginalPath          = $originalPath
        ModifiedPath          = $modifiedPath
        StructuralChangesPath = $structuralChangesPath
        DuplicatePath         = $duplicatePath
    }
}

# Fonction pour vérifier si Qdrant est en cours d'exécution
function Test-QdrantRunning {
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get -ErrorAction Stop
        Write-Log "Connexion à Qdrant établie" -Level Success
        return $true
    } catch {
        Write-Log "Impossible de se connecter à Qdrant: $_" -Level Error
        return $false
    }
}

# Fonction pour tester la détection des changements
function Test-ChangeDetection {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestFiles
    )

    Write-Log "Test de la détection des changements..." -Level Info

    $detectChangesScript = Join-Path -Path $parentPath -ChildPath "Detect-RoadmapChanges.ps1"
    $outputPath = Join-Path -Path $TestDataDirectory -ChildPath "changes.json"

    if (Test-Path -Path $detectChangesScript) {
        & $detectChangesScript -RoadmapPath $TestFiles.ModifiedPath -PreviousVersionPath $TestFiles.OriginalPath -OutputPath $outputPath -OutputFormat "JSON" -Detailed

        if ($LASTEXITCODE -eq 0 -and (Test-Path -Path $outputPath)) {
            $changes = Get-Content -Path $outputPath -Raw | ConvertFrom-Json

            if ($changes.HasChanges) {
                Write-Log "Test de détection des changements réussi" -Level Success
                return $true
            } else {
                Write-Log "Échec du test de détection des changements: aucun changement détecté" -Level Error
                return $false
            }
        } else {
            Write-Log "Échec du test de détection des changements: erreur lors de l'exécution du script" -Level Error
            return $false
        }
    } else {
        Write-Log "Script de détection des changements non trouvé: $detectChangesScript" -Level Error
        return $false
    }
}

# Fonction pour tester la vectorisation
function Test-Vectorization {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestFiles,

        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    Write-Log "Test de la vectorisation..." -Level Info

    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -QdrantUrl $QdrantUrl)) {
        Write-Log "Impossible de tester la vectorisation: Qdrant n'est pas accessible" -Level Error
        return $false
    }

    $vectorSyncScript = Join-Path -Path $parentPath -ChildPath "Invoke-RoadmapVectorSync.ps1"

    if (Test-Path -Path $vectorSyncScript) {
        & $vectorSyncScript -RoadmapPath $TestFiles.OriginalPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -SyncMode "Full" -Force

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Test de vectorisation réussi" -Level Success
            return $true
        } else {
            Write-Log "Échec du test de vectorisation: erreur lors de l'exécution du script" -Level Error
            return $false
        }
    } else {
        Write-Log "Script de vectorisation non trouvé: $vectorSyncScript" -Level Error
        return $false
    }
}

# Fonction pour tester la recherche
function Test-Search {
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    Write-Log "Test de la recherche..." -Level Info

    $searchScript = Join-Path -Path $parentPath -ChildPath "Search-RoadmapVectors.ps1"
    $outputPath = Join-Path -Path $TestDataDirectory -ChildPath "search_results.json"

    if (Test-Path -Path $searchScript) {
        & $searchScript -Query "Tâche complétée" -QdrantUrl $QdrantUrl -CollectionName $CollectionName -OutputPath $outputPath -OutputFormat "JSON"

        if ($LASTEXITCODE -eq 0 -and (Test-Path -Path $outputPath)) {
            $results = Get-Content -Path $outputPath -Raw | ConvertFrom-Json

            if ($results.results.Count -gt 0) {
                Write-Log "Test de recherche réussi: $($results.results.Count) résultats trouvés" -Level Success
                return $true
            } else {
                Write-Log "Échec du test de recherche: aucun résultat trouvé" -Level Error
                return $false
            }
        } else {
            Write-Log "Échec du test de recherche: erreur lors de l'exécution du script" -Level Error
            return $false
        }
    } else {
        Write-Log "Script de recherche non trouvé: $searchScript" -Level Error
        return $false
    }
}

# Fonction pour tester la détection des doublons
function Test-DuplicateDetection {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestFiles
    )

    Write-Log "Test de la détection des doublons..." -Level Info

    $duplicateScript = Join-Path -Path $parentPath -ChildPath "Find-DuplicateRoadmaps.ps1"
    $outputPath = Join-Path -Path $TestDataDirectory -ChildPath "duplicates.json"

    if (Test-Path -Path $duplicateScript) {
        # Créer un répertoire temporaire pour les tests
        $tempDir = Join-Path -Path $TestDataDirectory -ChildPath "temp_duplicates"
        if (-not (Test-Path -Path $tempDir)) {
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        }

        # Copier les fichiers de test dans le répertoire temporaire
        Copy-Item -Path $TestFiles.OriginalPath -Destination $tempDir
        Copy-Item -Path $TestFiles.DuplicatePath -Destination $tempDir

        # Exécuter le script de détection des doublons
        & $duplicateScript -RoadmapsDirectory $tempDir -OutputPath $outputPath -OutputFormat "JSON" -SimilarityThreshold 0.8

        if ($LASTEXITCODE -eq 0 -and (Test-Path -Path $outputPath)) {
            $duplicates = Get-Content -Path $outputPath -Raw | ConvertFrom-Json

            if ($duplicates.duplicates.Count -gt 0) {
                Write-Log "Test de détection des doublons réussi: $($duplicates.duplicates.Count) doublons trouvés" -Level Success
                return $true
            } else {
                Write-Log "Échec du test de détection des doublons: aucun doublon trouvé" -Level Error
                return $false
            }
        } else {
            Write-Log "Échec du test de détection des doublons: erreur lors de l'exécution du script" -Level Error
            return $false
        }
    } else {
        Write-Log "Script de détection des doublons non trouvé: $duplicateScript" -Level Error
        return $false
    }
}

# Fonction pour tester la visualisation
function Test-Visualization {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestFiles
    )

    Write-Log "Test de la visualisation..." -Level Info

    $visualizationScript = Join-Path -Path $parentPath -ChildPath "Invoke-RoadmapVisualization.ps1"

    if (Test-Path -Path $visualizationScript) {
        $outputDir = Join-Path -Path $TestDataDirectory -ChildPath "visualizations"

        & $visualizationScript -RoadmapPath $TestFiles.OriginalPath -OutputDirectory $outputDir

        if ($LASTEXITCODE -eq 0) {
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($TestFiles.OriginalPath)
            $indexPath = Join-Path -Path $outputDir -ChildPath "$fileName/index.html"

            if (Test-Path -Path $indexPath) {
                Write-Log "Test de visualisation réussi" -Level Success
                return $true
            } else {
                Write-Log "Échec du test de visualisation: fichier index.html non trouvé" -Level Error
                return $false
            }
        } else {
            Write-Log "Échec du test de visualisation: erreur lors de l'exécution du script" -Level Error
            return $false
        }
    } else {
        Write-Log "Script de visualisation non trouvé: $visualizationScript" -Level Error
        return $false
    }
}

# Fonction principale pour exécuter tous les tests
function Invoke-RoadmapRAGSystemTests {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestFiles,

        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    $testResults = @{
        TotalTests  = 0
        PassedTests = 0
        FailedTests = 0
        Results     = @()
    }

    # Test 1: Détection des changements
    $testResults.TotalTests++
    $result = Test-ChangeDetection -TestFiles $TestFiles

    if ($result) {
        $testResults.PassedTests++
        $testResults.Results += @{
            TestName = "Détection des changements"
            Result   = "Réussi"
        }
    } else {
        $testResults.FailedTests++
        $testResults.Results += @{
            TestName = "Détection des changements"
            Result   = "Échec"
        }
    }

    # Test 2: Vectorisation
    $testResults.TotalTests++
    $result = Test-Vectorization -TestFiles $TestFiles -QdrantUrl $QdrantUrl -CollectionName $CollectionName

    if ($result) {
        $testResults.PassedTests++
        $testResults.Results += @{
            TestName = "Vectorisation"
            Result   = "Réussi"
        }
    } else {
        $testResults.FailedTests++
        $testResults.Results += @{
            TestName = "Vectorisation"
            Result   = "Échec"
        }
    }

    # Test 3: Recherche
    $testResults.TotalTests++
    $result = Test-Search -QdrantUrl $QdrantUrl -CollectionName $CollectionName

    if ($result) {
        $testResults.PassedTests++
        $testResults.Results += @{
            TestName = "Recherche"
            Result   = "Réussi"
        }
    } else {
        $testResults.FailedTests++
        $testResults.Results += @{
            TestName = "Recherche"
            Result   = "Échec"
        }
    }

    # Test 4: Détection des doublons
    $testResults.TotalTests++
    $result = Test-DuplicateDetection -TestFiles $TestFiles

    if ($result) {
        $testResults.PassedTests++
        $testResults.Results += @{
            TestName = "Détection des doublons"
            Result   = "Réussi"
        }
    } else {
        $testResults.FailedTests++
        $testResults.Results += @{
            TestName = "Détection des doublons"
            Result   = "Échec"
        }
    }

    # Test 5: Visualisation
    $testResults.TotalTests++
    $result = Test-Visualization -TestFiles $TestFiles

    if ($result) {
        $testResults.PassedTests++
        $testResults.Results += @{
            TestName = "Visualisation"
            Result   = "Réussi"
        }
    } else {
        $testResults.FailedTests++
        $testResults.Results += @{
            TestName = "Visualisation"
            Result   = "Échec"
        }
    }

    # Afficher le résumé des tests
    Write-Log "Résumé des tests:" -Level Info
    Write-Log "  - Tests totaux: $($testResults.TotalTests)" -Level Info
    Write-Log "  - Tests réussis: $($testResults.PassedTests)" -Level Success
    Write-Log "  - Tests échoués: $($testResults.FailedTests)" -Level ($testResults.FailedTests -gt 0 ? "Error" : "Info")

    foreach ($result in $testResults.Results) {
        $level = $result.Result -eq "Réussi" ? "Success" : "Error"
        Write-Log "  - $($result.TestName): $($result.Result)" -Level $level
    }

    return $testResults
}

# Fonction principale
function Main {
    Write-Log "Démarrage des tests du système RAG pour les roadmaps" -Level Info

    # Créer les fichiers de test si demandé
    if ($CreateTestFiles -or -not (Test-Path -Path $TestDataDirectory)) {
        $testFiles = New-TestFiles -TestDataDirectory $TestDataDirectory
    } else {
        # Utiliser les fichiers existants
        $testFiles = @{
            OriginalPath          = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_original.md"
            ModifiedPath          = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_modified.md"
            StructuralChangesPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_structural_changes.md"
            DuplicatePath         = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_duplicate.md"
        }
    }

    # Exécuter les tests
    $testResults = Invoke-RoadmapRAGSystemTests -TestFiles $testFiles -QdrantUrl $QdrantUrl -CollectionName $CollectionName

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
