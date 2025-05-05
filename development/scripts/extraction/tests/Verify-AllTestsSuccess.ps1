# Verify-AllTestsSuccess.ps1
# Script pour vérifier que tous les tests passent avec succès

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Définir le chemin du répertoire des résultats
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "Results"
$fixedResultsDir = Join-Path -Path $resultsDir -ChildPath "Fixed"
$verificationDir = Join-Path -Path $resultsDir -ChildPath "Verification"

# Créer le répertoire de vérification s'il n'existe pas
if (-not (Test-Path -Path $verificationDir)) {
    New-Item -Path $verificationDir -ItemType Directory -Force | Out-Null
}

# Définir le fichier de vérification
$verificationFile = Join-Path -Path $verificationDir -ChildPath "AllTests_Verification.md"

# Initialiser le fichier de vérification
Set-Content -Path $verificationFile -Value "# Vérification des résultats de tous les tests`r`n"
Add-Content -Path $verificationFile -Value "Date de vérification : $(Get-Date)`r`n"

# Fonction pour analyser un fichier de résultats
function Analyze-ResultsFile {
    param (
        [string]$ResultsFile,
        [string]$Category
    )
    
    if (-not (Test-Path -Path $ResultsFile)) {
        Write-Host "Le fichier de résultats n'existe pas : $ResultsFile" -ForegroundColor $errorColor
        return @{
            Category = $Category
            TotalTests = 0
            PassedTests = 0
            FailedTests = 0
            Success = $false
            Error = "Fichier non trouvé"
        }
    }
    
    $content = Get-Content -Path $ResultsFile -Raw
    if ([string]::IsNullOrEmpty($content)) {
        Write-Host "Le fichier de résultats est vide : $ResultsFile" -ForegroundColor $warningColor
        return @{
            Category = $Category
            TotalTests = 0
            PassedTests = 0
            FailedTests = 0
            Success = $false
            Error = "Fichier vide"
        }
    }
    
    # Extraire les informations du résumé
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    
    if ($content -match "Total des tests : (\d+)") {
        $totalTests = [int]$Matches[1]
    }
    
    if ($content -match "Tests réussis : (\d+)") {
        $passedTests = [int]$Matches[1]
    }
    
    if ($content -match "Tests échoués : (\d+)") {
        $failedTests = [int]$Matches[1]
    }
    
    return @{
        Category = $Category
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        Success = ($failedTests -eq 0 -and $totalTests -gt 0)
        Error = $null
    }
}

# Fonction pour vérifier les résultats des tests
function Verify-TestResults {
    param (
        [string]$TestType,
        [string[]]$ResultsFiles
    )
    
    Add-Content -Path $verificationFile -Value "## Vérification des tests $TestType`r`n"
    
    $allResults = @()
    $totalTests = 0
    $totalPassedTests = 0
    $totalFailedTests = 0
    $allSuccess = $true
    
    foreach ($resultsFile in $ResultsFiles) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($resultsFile)
        $category = $fileName -replace "_Fixed_Results", ""
        
        $resultsFilePath = Join-Path -Path $fixedResultsDir -ChildPath $resultsFile
        $result = Analyze-ResultsFile -ResultsFile $resultsFilePath -Category $category
        
        $allResults += $result
        
        $totalTests += $result.TotalTests
        $totalPassedTests += $result.PassedTests
        $totalFailedTests += $result.FailedTests
        $allSuccess = $allSuccess -and $result.Success
        
        if ($result.Error) {
            Add-Content -Path $verificationFile -Value "### $category`r`n"
            Add-Content -Path $verificationFile -Value "**ERREUR** : $($result.Error)`r`n"
            continue
        }
        
        Add-Content -Path $verificationFile -Value "### $category`r`n"
        Add-Content -Path $verificationFile -Value "- Total des tests : $($result.TotalTests)"
        Add-Content -Path $verificationFile -Value "- Tests réussis : $($result.PassedTests)"
        Add-Content -Path $verificationFile -Value "- Tests échoués : $($result.FailedTests)"
        Add-Content -Path $verificationFile -Value "- Statut : $($result.Success ? 'SUCCÈS' : 'ÉCHEC')`r`n"
    }
    
    Add-Content -Path $verificationFile -Value "### Résumé des tests $TestType`r`n"
    Add-Content -Path $verificationFile -Value "- Total des tests : $totalTests"
    Add-Content -Path $verificationFile -Value "- Tests réussis : $totalPassedTests"
    Add-Content -Path $verificationFile -Value "- Tests échoués : $totalFailedTests"
    Add-Content -Path $verificationFile -Value "- Statut global : $($allSuccess ? 'SUCCÈS' : 'ÉCHEC')`r`n"
    
    return @{
        TestType = $TestType
        TotalTests = $totalTests
        PassedTests = $totalPassedTests
        FailedTests = $totalFailedTests
        Success = $allSuccess
    }
}

# Définir les fichiers de résultats à vérifier
$unitTestResultsFiles = @(
    "BaseFunctionTests_Fixed_Results.txt",
    "MetadataFunctionTests_Fixed_Results.txt",
    "CollectionFunctionTests_Fixed_Results.txt",
    "SerializationFunctionTests_Fixed_Results.txt",
    "ValidationFunctionTests_Fixed_Results.txt"
)

$integrationTestResultsFiles = @(
    "ExtractionWorkflowTests_Fixed_Results.txt",
    "CollectionWorkflowTests_Fixed_Results.txt",
    "SerializationWorkflowTests_Fixed_Results.txt",
    "ValidationWorkflowTests_Fixed_Results.txt"
)

# Vérifier les résultats des tests
$unitTestsResult = Verify-TestResults -TestType "unitaires" -ResultsFiles $unitTestResultsFiles
$integrationTestsResult = Verify-TestResults -TestType "d'intégration" -ResultsFiles $integrationTestResultsFiles

# Ajouter le résumé global au fichier de vérification
Add-Content -Path $verificationFile -Value "## Résumé global`r`n"
Add-Content -Path $verificationFile -Value "### Tests unitaires`r`n"
Add-Content -Path $verificationFile -Value "- Total des tests : $($unitTestsResult.TotalTests)"
Add-Content -Path $verificationFile -Value "- Tests réussis : $($unitTestsResult.PassedTests)"
Add-Content -Path $verificationFile -Value "- Tests échoués : $($unitTestsResult.FailedTests)"
Add-Content -Path $verificationFile -Value "- Statut global : $($unitTestsResult.Success ? 'SUCCÈS' : 'ÉCHEC')`r`n"

Add-Content -Path $verificationFile -Value "### Tests d'intégration`r`n"
Add-Content -Path $verificationFile -Value "- Total des tests : $($integrationTestsResult.TotalTests)"
Add-Content -Path $verificationFile -Value "- Tests réussis : $($integrationTestsResult.PassedTests)"
Add-Content -Path $verificationFile -Value "- Tests échoués : $($integrationTestsResult.FailedTests)"
Add-Content -Path $verificationFile -Value "- Statut global : $($integrationTestsResult.Success ? 'SUCCÈS' : 'ÉCHEC')`r`n"

$allTestsSuccess = $unitTestsResult.Success -and $integrationTestsResult.Success
$totalAllTests = $unitTestsResult.TotalTests + $integrationTestsResult.TotalTests
$totalAllPassedTests = $unitTestsResult.PassedTests + $integrationTestsResult.PassedTests
$totalAllFailedTests = $unitTestsResult.FailedTests + $integrationTestsResult.FailedTests

Add-Content -Path $verificationFile -Value "### Tous les tests`r`n"
Add-Content -Path $verificationFile -Value "- Total des tests : $totalAllTests"
Add-Content -Path $verificationFile -Value "- Tests réussis : $totalAllPassedTests"
Add-Content -Path $verificationFile -Value "- Tests échoués : $totalAllFailedTests"
Add-Content -Path $verificationFile -Value "- Statut global : $($allTestsSuccess ? 'SUCCÈS' : 'ÉCHEC')`r`n"

if ($allTestsSuccess) {
    Add-Content -Path $verificationFile -Value "## Conclusion`r`n"
    Add-Content -Path $verificationFile -Value "**Tous les tests ont réussi!** Le module ExtractedInfoModuleV2 fonctionne correctement."
} else {
    Add-Content -Path $verificationFile -Value "## Conclusion`r`n"
    Add-Content -Path $verificationFile -Value "**Certains tests ont échoué.** Des problèmes subsistent dans le module ExtractedInfoModuleV2."
}

# Afficher le résumé
Write-Host "`nRésumé de la vérification des tests :" -ForegroundColor $infoColor
Write-Host "  Tests unitaires :" -ForegroundColor $infoColor
Write-Host "    Total des tests : $($unitTestsResult.TotalTests)" -ForegroundColor $infoColor
Write-Host "    Tests réussis : $($unitTestsResult.PassedTests)" -ForegroundColor $successColor
Write-Host "    Tests échoués : $($unitTestsResult.FailedTests)" -ForegroundColor $errorColor
Write-Host "    Statut global : $($unitTestsResult.Success ? 'SUCCÈS' : 'ÉCHEC')" -ForegroundColor ($unitTestsResult.Success ? $successColor : $errorColor)

Write-Host "`n  Tests d'intégration :" -ForegroundColor $infoColor
Write-Host "    Total des tests : $($integrationTestsResult.TotalTests)" -ForegroundColor $infoColor
Write-Host "    Tests réussis : $($integrationTestsResult.PassedTests)" -ForegroundColor $successColor
Write-Host "    Tests échoués : $($integrationTestsResult.FailedTests)" -ForegroundColor $errorColor
Write-Host "    Statut global : $($integrationTestsResult.Success ? 'SUCCÈS' : 'ÉCHEC')" -ForegroundColor ($integrationTestsResult.Success ? $successColor : $errorColor)

Write-Host "`n  Tous les tests :" -ForegroundColor $infoColor
Write-Host "    Total des tests : $totalAllTests" -ForegroundColor $infoColor
Write-Host "    Tests réussis : $totalAllPassedTests" -ForegroundColor $successColor
Write-Host "    Tests échoués : $totalAllFailedTests" -ForegroundColor $errorColor
Write-Host "    Statut global : $($allTestsSuccess ? 'SUCCÈS' : 'ÉCHEC')" -ForegroundColor ($allTestsSuccess ? $successColor : $errorColor)

# Retourner le code de sortie
if ($allTestsSuccess) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor $successColor
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué. Consultez le fichier de vérification pour plus de détails : $verificationFile" -ForegroundColor $errorColor
    exit 1
}
