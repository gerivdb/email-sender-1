# Test-ChangeDetection.ps1
# Script de test pour la détection des changements dans les roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
  [Parameter(Mandatory = $false)]
  [string]$TestDataDirectory = "projet/roadmaps/analysis/test/files",

  [Parameter(Mandatory = $false)]
  [string]$OutputDirectory = "projet/roadmaps/analysis/test/output",

  [Parameter(Mandatory = $false)]
  [switch]$VerboseOutput
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
  . $logModulePath
} else {
  function Write-Log {
    param (
      [string]$Message,
      [string]$Level = "Info"
    )

    $color = switch ($Level) {
      "Info" { "White" }
      "Warning" { "Yellow" }
      "Error" { "Red" }
      "Success" { "Green" }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
  }
}

# Fonction pour créer des fichiers de test
function New-TestFiles {
  param (
    [string]$TestDataDirectory
  )

  # Créer le répertoire de test s'il n'existe pas
  if (-not (Test-Path -Path $TestDataDirectory)) {
    New-Item -Path $TestDataDirectory -ItemType Directory -Force | Out-Null
  }

  # Fichier original
  $originalContent = @"
# Roadmap Test

## Section 1

- [ ] **1.1** Tâche 1
  - [ ] **1.1.1** Sous-tâche 1
  - [ ] **1.1.2** Sous-tâche 2
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2

## Section 2

- [ ] **2.1** Tâche 1
  - [ ] **2.1.1** Sous-tâche 1
  - [ ] **2.1.2** Sous-tâche 2
- [ ] **2.2** Tâche 2
  - [ ] **2.2.1** Sous-tâche 1
  - [ ] **2.2.2** Sous-tâche 2
"@

  $originalPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_original.md"
  Set-Content -Path $originalPath -Value $originalContent -Encoding UTF8

  # Fichier avec ajouts
  $addedContent = @"
# Roadmap Test

## Section 1

- [ ] **1.1** Tâche 1
  - [ ] **1.1.1** Sous-tâche 1
  - [ ] **1.1.2** Sous-tâche 2
  - [ ] **1.1.3** Nouvelle sous-tâche
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2

## Section 2

- [ ] **2.1** Tâche 1
  - [ ] **2.1.1** Sous-tâche 1
  - [ ] **2.1.2** Sous-tâche 2
- [ ] **2.2** Tâche 2
  - [ ] **2.2.1** Sous-tâche 1
  - [ ] **2.2.2** Sous-tâche 2
- [ ] **2.3** Nouvelle tâche
  - [ ] **2.3.1** Nouvelle sous-tâche
"@

  $addedPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_added.md"
  Set-Content -Path $addedPath -Value $addedContent -Encoding UTF8

  # Fichier avec suppressions
  $removedContent = @"
# Roadmap Test

## Section 1

- [ ] **1.1** Tâche 1
  - [ ] **1.1.1** Sous-tâche 1
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2

## Section 2

- [ ] **2.1** Tâche 1
  - [ ] **2.1.1** Sous-tâche 1
  - [ ] **2.1.2** Sous-tâche 2
"@

  $removedPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_removed.md"
  Set-Content -Path $removedPath -Value $removedContent -Encoding UTF8

  # Fichier avec modifications
  $modifiedContent = @"
# Roadmap Test

## Section 1

- [ ] **1.1** Tâche 1 modifiée
  - [ ] **1.1.1** Sous-tâche 1
  - [ ] **1.1.2** Sous-tâche 2 modifiée
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2

## Section 2

- [ ] **2.1** Tâche 1
  - [ ] **2.1.1** Sous-tâche 1
  - [ ] **2.1.2** Sous-tâche 2
- [ ] **2.2** Tâche 2 modifiée
  - [ ] **2.2.1** Sous-tâche 1
  - [ ] **2.2.2** Sous-tâche 2
"@

  $modifiedPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_modified.md"
  Set-Content -Path $modifiedPath -Value $modifiedContent -Encoding UTF8

  # Fichier avec changements de statut
  $statusContent = @"
# Roadmap Test

## Section 1

- [x] **1.1** Tâche 1
  - [x] **1.1.1** Sous-tâche 1
  - [ ] **1.1.2** Sous-tâche 2
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [x] **1.2.2** Sous-tâche 2

## Section 2

- [ ] **2.1** Tâche 1
  - [ ] **2.1.1** Sous-tâche 1
  - [ ] **2.1.2** Sous-tâche 2
- [ ] **2.2** Tâche 2
  - [ ] **2.2.1** Sous-tâche 1
  - [ ] **2.2.2** Sous-tâche 2
"@

  $statusPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_status.md"
  Set-Content -Path $statusPath -Value $statusContent -Encoding UTF8

  # Fichier avec déplacements
  $movedContent = @"
# Roadmap Test

## Section 1

- [ ] **1.1** Tâche 1
  - [ ] **1.1.1** Sous-tâche 1
  - [ ] **1.1.2** Sous-tâche 2
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2
  - [ ] **2.1.1** Sous-tâche 1 déplacée

## Section 2

- [ ] **2.1** Tâche 1
  - [ ] **2.1.2** Sous-tâche 2
- [ ] **2.2** Tâche 2
  - [ ] **2.2.1** Sous-tâche 1
  - [ ] **2.2.2** Sous-tâche 2
"@

  $movedPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_moved.md"
  Set-Content -Path $movedPath -Value $movedContent -Encoding UTF8

  # Fichier avec changements structurels
  $structuralContent = @"
# Roadmap Test

## Section 1 Renommée

- [ ] **1.1** Tâche 1
  - [ ] **1.1.1** Sous-tâche 1
  - [ ] **1.1.2** Sous-tâche 2
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2

## Section 2

- [ ] **2.1** Tâche 1
  - [ ] **2.1.1** Sous-tâche 1
  - [ ] **2.1.2** Sous-tâche 2
- [ ] **2.2** Tâche 2
  - [ ] **2.2.1** Sous-tâche 1
  - [ ] **2.2.2** Sous-tâche 2

## Nouvelle Section

- [ ] **3.1** Nouvelle tâche
  - [ ] **3.1.1** Nouvelle sous-tâche
"@

  $structuralPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_structural.md"
  Set-Content -Path $structuralPath -Value $structuralContent -Encoding UTF8

  return @{
    OriginalPath   = $originalPath
    AddedPath      = $addedPath
    RemovedPath    = $removedPath
    ModifiedPath   = $modifiedPath
    StatusPath     = $statusPath
    MovedPath      = $movedPath
    StructuralPath = $structuralPath
  }
}

# Fonction pour tester la détection des changements
function Test-DetectChanges {
  param (
    [string]$OriginalPath,
    [string]$NewPath,
    [string]$OutputPath,
    [string]$TestName
  )

  Write-Log "Test: $TestName" -Level "Info"

  $detectScriptPath = Join-Path -Path $parentPath -ChildPath "Detect-RoadmapChanges.ps1"

  if (-not (Test-Path -Path $detectScriptPath)) {
    Write-Log "Script de détection des changements introuvable: $detectScriptPath" -Level "Error"
    return $false
  }

  & $detectScriptPath -OriginalPath $OriginalPath -NewPath $NewPath -OutputPath $OutputPath -OutputFormat "Json" -Force

  if ($LASTEXITCODE -eq 0) {
    # Vérifier si le fichier de sortie existe
    if (Test-Path -Path $OutputPath) {
      $changes = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json

      if ($changes.HasChanges) {
        Write-Log "Changements détectés:" -Level "Success"

        if ($VerboseOutput) {
          if ($changes.ContentChanges.HasChanges) {
            Write-Log "  - Changements de contenu:" -Level "Info"
            Write-Log "    - Tâches ajoutées: $($changes.ContentChanges.Changes.Added.Count)" -Level "Info"
            Write-Log "    - Tâches supprimées: $($changes.ContentChanges.Changes.Removed.Count)" -Level "Info"
            Write-Log "    - Tâches modifiées: $($changes.ContentChanges.Changes.Modified.Count)" -Level "Info"
            Write-Log "    - Statuts changés: $($changes.ContentChanges.Changes.StatusChanged.Count)" -Level "Info"
            Write-Log "    - Tâches déplacées: $($changes.ContentChanges.Changes.Moved.Count)" -Level "Info"
          }

          if ($changes.StructuralChanges.HasStructuralChanges) {
            Write-Log "  - Changements structurels:" -Level "Info"
            Write-Log "    - En-têtes ajoutés: $($changes.StructuralChanges.Changes.AddedHeaders.Count)" -Level "Info"
            Write-Log "    - En-têtes supprimés: $($changes.StructuralChanges.Changes.RemovedHeaders.Count)" -Level "Info"
            Write-Log "    - En-têtes modifiés: $($changes.StructuralChanges.Changes.ModifiedHeaders.Count)" -Level "Info"
          }

          if ($changes.TaskMovements.HasMovements) {
            Write-Log "  - Mouvements de tâches:" -Level "Info"
            Write-Log "    - Changements de contexte: $($changes.TaskMovements.Movements.ContextChanges.Count)" -Level "Info"
            Write-Log "    - Changements de parent: $($changes.TaskMovements.Movements.ParentChanges.Count)" -Level "Info"
            Write-Log "    - Changements d'indentation: $($changes.TaskMovements.Movements.IndentChanges.Count)" -Level "Info"
            Write-Log "    - Changements d'ordre: $($changes.TaskMovements.Movements.OrderChanges.Count)" -Level "Info"
          }
        }

        return $true
      } else {
        Write-Log "Aucun changement détecté." -Level "Warning"
        return $false
      }
    } else {
      Write-Log "Fichier de sortie introuvable: $OutputPath" -Level "Error"
      return $false
    }
  } else {
    Write-Log "Erreur lors de la détection des changements." -Level "Error"
    return $false
  }
}

# Fonction principale
function Invoke-ChangeDetectionTests {
  param (
    [string]$TestDataDirectory,
    [string]$OutputDirectory
  )

  # Créer le répertoire de sortie s'il n'existe pas
  if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
  }

  # Créer les fichiers de test
  Write-Log "Création des fichiers de test..." -Level "Info"
  $testFiles = New-TestFiles -TestDataDirectory $TestDataDirectory

  # Exécuter les tests
  $testResults = @{
    Total  = 0
    Passed = 0
    Failed = 0
  }

  # Test 1: Ajouts
  $testResults.Total++
  $outputPath = Join-Path -Path $OutputDirectory -ChildPath "changes_added.json"
  $result = Test-DetectChanges -OriginalPath $testFiles.OriginalPath -NewPath $testFiles.AddedPath -OutputPath $outputPath -TestName "Détection des ajouts"
  if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

  # Test 2: Suppressions
  $testResults.Total++
  $outputPath = Join-Path -Path $OutputDirectory -ChildPath "changes_removed.json"
  $result = Test-DetectChanges -OriginalPath $testFiles.OriginalPath -NewPath $testFiles.RemovedPath -OutputPath $outputPath -TestName "Détection des suppressions"
  if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

  # Test 3: Modifications
  $testResults.Total++
  $outputPath = Join-Path -Path $OutputDirectory -ChildPath "changes_modified.json"
  $result = Test-DetectChanges -OriginalPath $testFiles.OriginalPath -NewPath $testFiles.ModifiedPath -OutputPath $outputPath -TestName "Détection des modifications"
  if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

  # Test 4: Changements de statut
  $testResults.Total++
  $outputPath = Join-Path -Path $OutputDirectory -ChildPath "changes_status.json"
  $result = Test-DetectChanges -OriginalPath $testFiles.OriginalPath -NewPath $testFiles.StatusPath -OutputPath $outputPath -TestName "Détection des changements de statut"
  if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

  # Test 5: Déplacements
  $testResults.Total++
  $outputPath = Join-Path -Path $OutputDirectory -ChildPath "changes_moved.json"
  $result = Test-DetectChanges -OriginalPath $testFiles.OriginalPath -NewPath $testFiles.MovedPath -OutputPath $outputPath -TestName "Détection des déplacements"
  if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

  # Test 6: Changements structurels
  $testResults.Total++
  $outputPath = Join-Path -Path $OutputDirectory -ChildPath "changes_structural.json"
  $result = Test-DetectChanges -OriginalPath $testFiles.OriginalPath -NewPath $testFiles.StructuralPath -OutputPath $outputPath -TestName "Détection des changements structurels"
  if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

  # Afficher les résultats
  Write-Log "Résultats des tests:" -Level "Info"
  Write-Log "  - Total: $($testResults.Total)" -Level "Info"
  Write-Log "  - Réussis: $($testResults.Passed)" -Level "Success"
  Write-Log "  - Échoués: $($testResults.Failed)" -Level "Error"

  return $testResults
}

# Exécuter les tests
Invoke-ChangeDetectionTests -TestDataDirectory $TestDataDirectory -OutputDirectory $OutputDirectory
