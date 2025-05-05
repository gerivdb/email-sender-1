# Run-BaseFunctionTests.ps1
# Script pour exécuter les tests des fonctions de base

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"

# Définir le chemin du répertoire des tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "."
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "Results"

# Créer le répertoire des résultats s'il n'existe pas
if (-not (Test-Path -Path $resultsDir)) {
    New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
}

# Définir le fichier de résultats
$resultsFile = Join-Path -Path $resultsDir -ChildPath "BaseFunctionTests_Results.txt"

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

# Initialiser le fichier de résultats
Set-Content -Path $resultsFile -Value "# Résultats des tests des fonctions de base`r`n"
Add-Content -Path $resultsFile -Value "Date d'exécution : $(Get-Date)`r`n"

# Trouver tous les tests des fonctions de base
$baseTests = @(
    "Test-NewExtractedInfo.ps1",
    "Test-NewTextExtractedInfo.ps1",
    "Test-NewStructuredDataExtractedInfo.ps1",
    "Test-NewMediaExtractedInfo.ps1",
    "Test-CopyExtractedInfo.ps1"
)

# Exécuter les tests
$totalTests = $baseTests.Count
$passedTests = 0
$failedTests = 0

Add-Content -Path $resultsFile -Value "## Tests exécutés`r`n"

foreach ($test in $baseTests) {
    $testPath = Join-Path -Path $testDir -ChildPath $test
    if (Test-Path -Path $testPath) {
        $success = Invoke-TestScript -TestScript $testPath -ResultsFile $resultsFile
        if ($success) {
            $passedTests++
        } else {
            $failedTests++
        }
    } else {
        Write-Host "  [AVERTISSEMENT] Test non trouvé : $test" -ForegroundColor "Yellow"
        Add-Content -Path $resultsFile -Value "[$test] NON TROUVÉ"
    }
}

# Afficher le résumé
Write-Host "`nRésumé des tests des fonctions de base :" -ForegroundColor $infoColor
Write-Host "  Total des tests : $totalTests" -ForegroundColor $infoColor
Write-Host "  Tests réussis : $passedTests" -ForegroundColor $successColor
Write-Host "  Tests échoués : $failedTests" -ForegroundColor $errorColor

# Enregistrer le résumé dans le fichier de résultats
Add-Content -Path $resultsFile -Value "`r`n## Résumé"
Add-Content -Path $resultsFile -Value "- Total des tests : $totalTests"
Add-Content -Path $resultsFile -Value "- Tests réussis : $passedTests"
Add-Content -Path $resultsFile -Value "- Tests échoués : $failedTests"

# Retourner le code de sortie
if ($failedTests -eq 0) {
    Write-Host "Tous les tests des fonctions de base ont réussi!" -ForegroundColor $successColor
    exit 0
} else {
    Write-Host "Certains tests des fonctions de base ont échoué. Consultez le fichier de résultats pour plus de détails : $resultsFile" -ForegroundColor $errorColor
    exit 1
}
