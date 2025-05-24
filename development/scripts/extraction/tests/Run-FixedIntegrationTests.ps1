# Run-FixedIntegrationTests.ps1
# Script pour réexécuter les tests d'intégration corrigés

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Définir le chemin du répertoire des tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "Integration"
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "Results"
$fixedResultsDir = Join-Path -Path $resultsDir -ChildPath "Fixed"

# Créer le répertoire des résultats s'il n'existe pas
if (-not (Test-Path -Path $resultsDir)) {
    New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
}

# Créer le répertoire des résultats corrigés s'il n'existe pas
if (-not (Test-Path -Path $fixedResultsDir)) {
    New-Item -Path $fixedResultsDir -ItemType Directory -Force | Out-Null
}

# Fonction pour exécuter un test et enregistrer les résultats
function Invoke-TestScript {
    param (
        [string]$TestScript,
        [string]$ResultsFile
    )
    
    $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestScript)
    Write-Host "Exécution du test : $testName" -ForegroundColor $infoColor
    
    try {
        $output = & $TestScript 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "  [SUCCÈS] $testName" -ForegroundColor $successColor
            Add-Content -Path $ResultsFile -Value "[$testName] SUCCÈS"
            return $true
        } else {
            Write-Host "  [ÉCHEC] $testName (Code de sortie: $exitCode)" -ForegroundColor $errorColor
            Add-Content -Path $ResultsFile -Value "[$testName] ÉCHEC (Code de sortie: $exitCode)"
            Add-Content -Path $ResultsFile -Value "Output:"
            Add-Content -Path $ResultsFile -Value $output
            return $false
        }
    } catch {
        Write-Host "  [ERREUR] $testName : $_" -ForegroundColor $errorColor
        Add-Content -Path $ResultsFile -Value "[$testName] ERREUR : $_"
        return $false
    }
}

# Fonction pour réexécuter les tests d'intégration d'une catégorie
function Restart-IntegrationTests {
    param (
        [string]$Category,
        [string[]]$TestScripts
    )
    
    # Définir le fichier de résultats
    $resultsFile = Join-Path -Path $fixedResultsDir -ChildPath "${Category}Tests_Fixed_Results.txt"
    
    # Initialiser le fichier de résultats
    Set-Content -Path $resultsFile -Value "# Résultats des tests d'intégration corrigés : $Category`r`n"
    Add-Content -Path $resultsFile -Value "Date d'exécution : $(Get-Date)`r`n"
    
    # Exécuter les tests
    $totalTests = $TestScripts.Count
    $passedTests = 0
    $failedTests = 0
    
    Add-Content -Path $resultsFile -Value "## Tests exécutés`r`n"
    
    foreach ($test in $TestScripts) {
        $testPath = Join-Path -Path $testDir -ChildPath $test
        if (Test-Path -Path $testPath) {
            $success = Invoke-TestScript -TestScript $testPath -ResultsFile $resultsFile
            if ($success) {
                $passedTests++
            } else {
                $failedTests++
            }
        } else {
            Write-Host "  [AVERTISSEMENT] Test non trouvé : $test" -ForegroundColor $warningColor
            Add-Content -Path $resultsFile -Value "[$test] NON TROUVÉ"
        }
    }
    
    # Afficher le résumé
    Write-Host "`nRésumé des tests d'intégration corrigés ($Category) :" -ForegroundColor $infoColor
    Write-Host "  Total des tests : $totalTests" -ForegroundColor $infoColor
    Write-Host "  Tests réussis : $passedTests" -ForegroundColor $successColor
    Write-Host "  Tests échoués : $failedTests" -ForegroundColor $errorColor
    
    # Enregistrer le résumé dans le fichier de résultats
    Add-Content -Path $resultsFile -Value "`r`n## Résumé"
    Add-Content -Path $resultsFile -Value "- Total des tests : $totalTests"
    Add-Content -Path $resultsFile -Value "- Tests réussis : $passedTests"
    Add-Content -Path $resultsFile -Value "- Tests échoués : $failedTests"
    
    return @{
        Category = $Category
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        Success = ($failedTests -eq 0)
    }
}

# Définir les catégories de tests d'intégration et leurs scripts associés
$integrationTestCategories = @(
    @{
        Category = "ExtractionWorkflow"
        Tests = @(
            "Test-TextExtractionWorkflow.ps1",
            "Test-StructuredDataExtractionWorkflow.ps1",
            "Test-MediaExtractionWorkflow.ps1",
            "Test-MixedExtractionWorkflow.ps1"
        )
    },
    @{
        Category = "CollectionWorkflow"
        Tests = @(
            "Test-CollectionCreation.ps1",
            "Test-FilteringBySource.ps1",
            "Test-FilteringByType.ps1",
            "Test-FilteringByProcessingState.ps1",
            "Test-FilteringByConfidenceScore.ps1"
        )
    },
    @{
        Category = "SerializationWorkflow"
        Tests = @(
            "Test-SimpleInfoSerialization.ps1",
            "Test-CollectionSerialization.ps1",
            "Test-SaveInfoToFile.ps1",
            "Test-LoadInfoFromFile.ps1",
            "Test-CollectionSaveLoad.ps1"
        )
    },
    @{
        Category = "ValidationWorkflow"
        Tests = @(
            "Test-ValidInfoValidation.ps1",
            "Test-InvalidInfoValidation.ps1",
            "Test-FixInvalidInfo.ps1",
            "Test-CustomValidationRules.ps1",
            "Test-CollectionValidation.ps1"
        )
    }
)

# Réexécuter les tests d'intégration
$allResults = @()
$totalTests = 0
$totalPassedTests = 0
$totalFailedTests = 0
$allSuccess = $true

foreach ($category in $integrationTestCategories) {
    $result = Restart-IntegrationTests -Category $category.Category -TestScripts $category.Tests
    $allResults += $result
    
    $totalTests += $result.TotalTests
    $totalPassedTests += $result.PassedTests
    $totalFailedTests += $result.FailedTests
    $allSuccess = $allSuccess -and $result.Success
}

# Afficher le résumé global
Write-Host "`nRésumé global des tests d'intégration corrigés :" -ForegroundColor $infoColor
Write-Host "  Total des tests : $totalTests" -ForegroundColor $infoColor
Write-Host "  Tests réussis : $totalPassedTests" -ForegroundColor $successColor
Write-Host "  Tests échoués : $totalFailedTests" -ForegroundColor $errorColor

# Créer un fichier de résumé global
$globalResultsFile = Join-Path -Path $fixedResultsDir -ChildPath "IntegrationTests_Fixed_Summary.md"
Set-Content -Path $globalResultsFile -Value "# Résumé global des tests d'intégration corrigés`r`n"
Add-Content -Path $globalResultsFile -Value "Date d'exécution : $(Get-Date)`r`n"

Add-Content -Path $globalResultsFile -Value "## Résultats par catégorie`r`n"
foreach ($result in $allResults) {
    Add-Content -Path $globalResultsFile -Value "### $($result.Category)`r`n"
    Add-Content -Path $globalResultsFile -Value "- Total des tests : $($result.TotalTests)"
    Add-Content -Path $globalResultsFile -Value "- Tests réussis : $($result.PassedTests)"
    Add-Content -Path $globalResultsFile -Value "- Tests échoués : $($result.FailedTests)"
    Add-Content -Path $globalResultsFile -Value "- Statut : $($result.Success ? 'SUCCÈS' : 'ÉCHEC')`r`n"
}

Add-Content -Path $globalResultsFile -Value "## Résumé global`r`n"
Add-Content -Path $globalResultsFile -Value "- Total des tests : $totalTests"
Add-Content -Path $globalResultsFile -Value "- Tests réussis : $totalPassedTests"
Add-Content -Path $globalResultsFile -Value "- Tests échoués : $totalFailedTests"
Add-Content -Path $globalResultsFile -Value "- Statut global : $($allSuccess ? 'SUCCÈS' : 'ÉCHEC')"

# Retourner le code de sortie
if ($allSuccess) {
    Write-Host "Tous les tests d'intégration corrigés ont réussi!" -ForegroundColor $successColor
    exit 0
} else {
    Write-Host "Certains tests d'intégration corrigés ont échoué. Consultez les fichiers de résultats pour plus de détails." -ForegroundColor $errorColor
    exit 1
}

