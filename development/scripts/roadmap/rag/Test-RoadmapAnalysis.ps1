# Test-RoadmapAnalysis.ps1
# Script de test pour vérifier le fonctionnement des scripts d'analyse de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/analysis/test",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer le module de journalisation
if (Test-Path -Path "$PSScriptRoot\..\utils\Write-Log.ps1") {
    . "$PSScriptRoot\..\utils\Write-Log.ps1"
} else {
    function Write-Log {
        param (
            [string]$Message,
            [ValidateSet("Info", "Warning", "Error", "Success")]
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
function New-TestRoadmapFiles {
    param (
        [string]$TestDirectory
    )

    # Créer le dossier de test s'il n'existe pas
    if (-not (Test-Path -Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
    }

    # Créer des fichiers de test
    $testFiles = @(
        @{
            Name    = "roadmap-v1.md"
            Content = @"
# Roadmap Test v1

## Section 1
- [ ] Tâche 1
- [ ] Tâche 2
  - [ ] Sous-tâche 2.1
  - [ ] Sous-tâche 2.2

## Section 2
- [ ] Tâche 3
- [x] Tâche 4
"@
        },
        @{
            Name    = "roadmap-v2.md"
            Content = @"
# Roadmap Test v2

## Section 1
- [ ] Tâche 1
- [ ] Tâche 2
  - [ ] Sous-tâche 2.1
  - [x] Sous-tâche 2.2

## Section 2
- [ ] Tâche 3
- [x] Tâche 4
- [ ] Tâche 5
"@
        },
        @{
            Name    = "roadmap_duplicate.md"
            Content = @"
# Roadmap Test v1

## Section 1
- [ ] Tâche 1
- [ ] Tâche 2
  - [ ] Sous-tâche 2.1
  - [ ] Sous-tâche 2.2

## Section 2
- [ ] Tâche 3
- [x] Tâche 4
"@
        },
        @{
            Name    = "plan-implementation.md"
            Content = @"
# Plan d'implémentation

## Fonctionnalité A
- [ ] **1.1** Conception
  - [ ] **1.1.1** Analyse des besoins
  - [ ] **1.1.2** Conception de l'architecture
- [ ] **1.2** Développement
  - [ ] **1.2.1** Implémentation du backend
  - [ ] **1.2.2** Implémentation du frontend

## Fonctionnalité B
- [ ] **2.1** Conception
- [ ] **2.2** Développement
"@
        }
    )

    foreach ($file in $testFiles) {
        $filePath = Join-Path -Path $TestDirectory -ChildPath $file.Name
        Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
        Write-Log "Fichier de test créé : $filePath" -Level Info
    }

    return $testFiles.Count
}

# Fonction pour tester l'inventaire des fichiers
function Test-Inventory {
    param (
        [string]$TestDirectory,
        [string]$OutputDirectory
    )

    Write-Log "Test de l'inventaire des fichiers..." -Level Info

    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "test_inventory.json"

    # Exécuter le script d'inventaire
    $scriptPath = "$PSScriptRoot\Get-RoadmapFiles.ps1"
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Log "Le script $scriptPath n'existe pas." -Level Error
        return $false
    }

    $params = @{
        Directories     = @($TestDirectory)
        FileExtensions  = @(".md")
        IncludeContent  = $true
        IncludeMetadata = $true
        OutputPath      = $outputPath
        OutputFormat    = "JSON"
    }

    & $scriptPath @params

    # Vérifier que le fichier de sortie a été créé
    if (-not (Test-Path -Path $outputPath)) {
        Write-Log "Le fichier de sortie $outputPath n'a pas été créé." -Level Error
        return $false
    }

    # Charger les résultats
    $results = Get-Content -Path $outputPath -Raw | ConvertFrom-Json

    # Vérifier que tous les fichiers ont été trouvés
    if ($results.Count -lt 4) {
        Write-Log "Tous les fichiers n'ont pas été trouvés. Attendu : 4, Trouvé : $($results.Count)" -Level Error
        return $false
    }

    Write-Log "Test d'inventaire réussi. $($results.Count) fichiers trouvés." -Level Success
    return $true
}

# Fonction pour tester l'analyse de structure
function Test-StructureAnalysis {
    param (
        [string]$InventoryPath,
        [string]$OutputDirectory
    )

    Write-Log "Test de l'analyse de structure..." -Level Info

    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "test_structure.json"

    # Exécuter le script d'analyse
    $scriptPath = "$PSScriptRoot\Analyze-RoadmapStructure.ps1"
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Log "Le script $scriptPath n'existe pas." -Level Error
        return $false
    }

    $params = @{
        InputPath    = $InventoryPath
        OutputPath   = $outputPath
        OutputFormat = "JSON"
    }

    & $scriptPath @params

    # Vérifier que le fichier de sortie a été créé
    if (-not (Test-Path -Path $outputPath)) {
        Write-Log "Le fichier de sortie $outputPath n'a pas été créé." -Level Error
        return $false
    }

    # Charger les résultats
    $results = Get-Content -Path $outputPath -Raw | ConvertFrom-Json

    # Vérifier que tous les fichiers ont été analysés
    if ($results.Count -lt 4) {
        Write-Log "Tous les fichiers n'ont pas été analysés. Attendu : 4, Trouvé : $($results.Count)" -Level Error
        return $false
    }

    Write-Log "Test d'analyse de structure réussi. $($results.Count) fichiers analysés." -Level Success
    return $true
}

# Fonction pour tester la recherche de doublons
function Test-DuplicateSearch {
    param (
        [string]$InventoryPath,
        [string]$OutputDirectory
    )

    Write-Log "Test de la recherche de doublons..." -Level Info

    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "test_duplicates.json"

    # Exécuter le script de recherche de doublons
    $scriptPath = "$PSScriptRoot\Find-DuplicateRoadmaps.ps1"
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Log "Le script $scriptPath n'existe pas." -Level Error
        return $false
    }

    $params = @{
        InputPath           = $InventoryPath
        OutputPath          = $outputPath
        OutputFormat        = "JSON"
        SimilarityThreshold = 0.8
        IncludeContent      = $true
    }

    & $scriptPath @params

    # Vérifier que le fichier de sortie a été créé
    if (-not (Test-Path -Path $outputPath)) {
        Write-Log "Le fichier de sortie $outputPath n'a pas été créé." -Level Error
        return $false
    }

    # Charger les résultats
    $results = Get-Content -Path $outputPath -Raw | ConvertFrom-Json

    # Vérifier que des doublons ont été trouvés
    if ($results.Duplicates.Count -lt 1) {
        Write-Log "Aucun doublon n'a été trouvé. Attendu : au moins 1" -Level Error
        return $false
    }

    # Vérifier que des versions ont été trouvées
    if ($results.VersionedFiles.Count -lt 1) {
        Write-Log "Aucun groupe de fichiers versionnés n'a été trouvé. Attendu : au moins 1" -Level Error
        return $false
    }

    Write-Log "Test de recherche de doublons réussi." -Level Success
    Write-Log "  - Doublons trouvés: $($results.Duplicates.Count)" -Level Info
    Write-Log "  - Versions obsolètes trouvées: $($results.Obsolete.Count)" -Level Info
    Write-Log "  - Groupes de fichiers versionnés: $($results.VersionedFiles.Count)" -Level Info

    return $true
}

# Fonction principale de test
function Invoke-RoadmapAnalysisTests {
    param (
        [string]$OutputDirectory,
        [switch]$Force
    )

    Write-Log "Démarrage des tests d'analyse de roadmap..." -Level Info

    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    } elseif ($Force) {
        Write-Log "Le dossier de sortie $OutputDirectory existe déjà. Les fichiers existants seront écrasés." -Level Warning
    } else {
        Write-Log "Le dossier de sortie $OutputDirectory existe déjà." -Level Info
    }

    # Créer un dossier pour les fichiers de test
    $testDirectory = Join-Path -Path $OutputDirectory -ChildPath "files"

    # Créer des fichiers de test
    $fileCount = New-TestRoadmapFiles -TestDirectory $testDirectory
    Write-Log "$fileCount fichiers de test créés dans $testDirectory" -Level Success

    # Tester l'inventaire des fichiers
    $inventorySuccess = Test-Inventory -TestDirectory $testDirectory -OutputDirectory $OutputDirectory

    if (-not $inventorySuccess) {
        Write-Log "Le test d'inventaire a échoué. Impossible de continuer." -Level Error
        return $false
    }

    # Chemin vers le fichier d'inventaire
    $inventoryPath = Join-Path -Path $OutputDirectory -ChildPath "test_inventory.json"

    # Tester l'analyse de structure
    $structureSuccess = Test-StructureAnalysis -InventoryPath $inventoryPath -OutputDirectory $OutputDirectory

    if (-not $structureSuccess) {
        Write-Log "Le test d'analyse de structure a échoué. Impossible de continuer." -Level Error
        return $false
    }

    # Tester la recherche de doublons
    $duplicateSuccess = Test-DuplicateSearch -InventoryPath $inventoryPath -OutputDirectory $OutputDirectory

    if (-not $duplicateSuccess) {
        Write-Log "Le test de recherche de doublons a échoué." -Level Error
        return $false
    }

    Write-Log "Tous les tests ont réussi !" -Level Success
    return $true
}

# Exécution principale
try {
    $success = Invoke-RoadmapAnalysisTests -OutputDirectory $OutputDirectory -Force:$Force

    if ($success) {
        Write-Log "Tests terminés avec succès." -Level Success
        return 0
    } else {
        Write-Log "Tests terminés avec des erreurs." -Level Error
        return 1
    }
} catch {
    Write-Log "Erreur lors de l'exécution des tests : $_" -Level Error
    throw $_
}
