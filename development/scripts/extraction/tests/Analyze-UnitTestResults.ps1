# Analyze-UnitTestResults.ps1
# Script pour analyser les résultats des tests unitaires

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Définir le chemin du répertoire des résultats
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "Results"
$analysisDir = Join-Path -Path $resultsDir -ChildPath "Analysis"

# Créer le répertoire d'analyse s'il n'existe pas
if (-not (Test-Path -Path $analysisDir)) {
    New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null
}

# Définir le fichier d'analyse
$analysisFile = Join-Path -Path $analysisDir -ChildPath "UnitTestResults_Analysis.md"

# Initialiser le fichier d'analyse
Set-Content -Path $analysisFile -Value "# Analyse des résultats des tests unitaires`r`n"
Add-Content -Path $analysisFile -Value "Date d'analyse : $(Get-Date)`r`n"

# Fonction pour analyser un fichier de résultats
function Test-ResultsFile {
    param (
        [string]$ResultsFile,
        [string]$AnalysisFile
    )
    
    if (-not (Test-Path -Path $ResultsFile)) {
        Write-Host "Le fichier de résultats n'existe pas : $ResultsFile" -ForegroundColor $errorColor
        Add-Content -Path $AnalysisFile -Value "## Fichier non trouvé : $([System.IO.Path]::GetFileName($ResultsFile))`r`n"
        Add-Content -Path $AnalysisFile -Value "Le fichier de résultats n'existe pas.`r`n"
        return @{
            TotalTests = 0
            PassedTests = 0
            FailedTests = 0
            NotFoundTests = 0
            ErrorTests = 0
            Success = $false
        }
    }
    
    $content = Get-Content -Path $ResultsFile -Raw
    if ([string]::IsNullOrEmpty($content)) {
        Write-Host "Le fichier de résultats est vide : $ResultsFile" -ForegroundColor $warningColor
        Add-Content -Path $AnalysisFile -Value "## Fichier vide : $([System.IO.Path]::GetFileName($ResultsFile))`r`n"
        Add-Content -Path $AnalysisFile -Value "Le fichier de résultats est vide.`r`n"
        return @{
            TotalTests = 0
            PassedTests = 0
            FailedTests = 0
            NotFoundTests = 0
            ErrorTests = 0
            Success = $false
        }
    }
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($ResultsFile)
    Add-Content -Path $AnalysisFile -Value "## $fileName`r`n"
    
    # Extraire les informations du résumé
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    $notFoundTests = 0
    $errorTests = 0
    
    if ($content -match "Total des tests : (\d+)") {
        $totalTests = [int]$Matches[1]
    }
    
    if ($content -match "Tests réussis : (\d+)") {
        $passedTests = [int]$Matches[1]
    }
    
    if ($content -match "Tests échoués : (\d+)") {
        $failedTests = [int]$Matches[1]
    }
    
    # Compter les tests non trouvés
    $notFoundMatches = [regex]::Matches($content, "\[.+?\] NON TROUVÉ")
    $notFoundTests = $notFoundMatches.Count
    
    # Compter les tests en erreur
    $errorMatches = [regex]::Matches($content, "\[.+?\] ERREUR")
    $errorTests = $errorMatches.Count
    
    # Extraire les tests en échec
    $failedMatches = [regex]::Matches($content, "\[(.+?)\] ÉCHEC")
    $failedTestNames = $failedMatches | ForEach-Object { $_.Groups[1].Value }
    
    # Extraire les tests non trouvés
    $notFoundMatches = [regex]::Matches($content, "\[(.+?)\] NON TROUVÉ")
    $notFoundTestNames = $notFoundMatches | ForEach-Object { $_.Groups[1].Value }
    
    # Extraire les tests en erreur
    $errorMatches = [regex]::Matches($content, "\[(.+?)\] ERREUR")
    $errorTestNames = $errorMatches | ForEach-Object { $_.Groups[1].Value }
    
    # Ajouter les informations au fichier d'analyse
    Add-Content -Path $AnalysisFile -Value "### Résumé"
    Add-Content -Path $AnalysisFile -Value "- Total des tests : $totalTests"
    Add-Content -Path $AnalysisFile -Value "- Tests réussis : $passedTests"
    Add-Content -Path $AnalysisFile -Value "- Tests échoués : $failedTests"
    Add-Content -Path $AnalysisFile -Value "- Tests non trouvés : $notFoundTests"
    Add-Content -Path $AnalysisFile -Value "- Tests en erreur : $errorTests"
    
    if ($failedTests -gt 0 -or $notFoundTests -gt 0 -or $errorTests -gt 0) {
        Add-Content -Path $AnalysisFile -Value "`r`n### Problèmes identifiés"
        
        if ($failedTests -gt 0) {
            Add-Content -Path $AnalysisFile -Value "`r`n#### Tests en échec"
            foreach ($testName in $failedTestNames) {
                Add-Content -Path $AnalysisFile -Value "- $testName"
            }
        }
        
        if ($notFoundTests -gt 0) {
            Add-Content -Path $AnalysisFile -Value "`r`n#### Tests non trouvés"
            foreach ($testName in $notFoundTestNames) {
                Add-Content -Path $AnalysisFile -Value "- $testName"
            }
        }
        
        if ($errorTests -gt 0) {
            Add-Content -Path $AnalysisFile -Value "`r`n#### Tests en erreur"
            foreach ($testName in $errorTestNames) {
                Add-Content -Path $AnalysisFile -Value "- $testName"
            }
        }
    }
    
    Add-Content -Path $AnalysisFile -Value "`r`n"
    
    return @{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        NotFoundTests = $notFoundTests
        ErrorTests = $errorTests
        Success = ($failedTests -eq 0 -and $errorTests -eq 0)
    }
}

# Trouver tous les fichiers de résultats des tests unitaires
$unitTestResultsFiles = @(
    "BaseFunctionTests_Results.txt",
    "MetadataFunctionTests_Results.txt",
    "CollectionFunctionTests_Results.txt",
    "SerializationFunctionTests_Results.txt",
    "ValidationFunctionTests_Results.txt"
)

# Analyser les fichiers de résultats
$totalTests = 0
$totalPassedTests = 0
$totalFailedTests = 0
$totalNotFoundTests = 0
$totalErrorTests = 0
$allSuccess = $true

foreach ($resultsFile in $unitTestResultsFiles) {
    $resultsFilePath = Join-Path -Path $resultsDir -ChildPath $resultsFile
    $analysisResult = Test-ResultsFile -ResultsFile $resultsFilePath -AnalysisFile $analysisFile
    
    $totalTests += $analysisResult.TotalTests
    $totalPassedTests += $analysisResult.PassedTests
    $totalFailedTests += $analysisResult.FailedTests
    $totalNotFoundTests += $analysisResult.NotFoundTests
    $totalErrorTests += $analysisResult.ErrorTests
    $allSuccess = $allSuccess -and $analysisResult.Success
}

# Ajouter le résumé global au fichier d'analyse
Add-Content -Path $analysisFile -Value "## Résumé global`r`n"
Add-Content -Path $analysisFile -Value "- Total des tests : $totalTests"
Add-Content -Path $analysisFile -Value "- Tests réussis : $totalPassedTests"
Add-Content -Path $analysisFile -Value "- Tests échoués : $totalFailedTests"
Add-Content -Path $analysisFile -Value "- Tests non trouvés : $totalNotFoundTests"
Add-Content -Path $analysisFile -Value "- Tests en erreur : $totalErrorTests"

if ($allSuccess) {
    Add-Content -Path $analysisFile -Value "`r`n**Tous les tests unitaires ont réussi!**"
    Write-Host "Tous les tests unitaires ont réussi!" -ForegroundColor $successColor
} else {
    Add-Content -Path $analysisFile -Value "`r`n**Certains tests unitaires ont échoué ou sont en erreur.**"
    Write-Host "Certains tests unitaires ont échoué ou sont en erreur. Consultez le fichier d'analyse pour plus de détails : $analysisFile" -ForegroundColor $errorColor
}

# Afficher le résumé
Write-Host "`nRésumé global des tests unitaires :" -ForegroundColor $infoColor
Write-Host "  Total des tests : $totalTests" -ForegroundColor $infoColor
Write-Host "  Tests réussis : $totalPassedTests" -ForegroundColor $successColor
Write-Host "  Tests échoués : $totalFailedTests" -ForegroundColor $errorColor
Write-Host "  Tests non trouvés : $totalNotFoundTests" -ForegroundColor $warningColor
Write-Host "  Tests en erreur : $totalErrorTests" -ForegroundColor $errorColor

# Retourner le code de sortie
if ($allSuccess) {
    exit 0
} else {
    exit 1
}

