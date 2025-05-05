# Identify-FailedTests.ps1
# Script pour identifier les tests en échec

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

# Définir le fichier d'identification des tests en échec
$failedTestsFile = Join-Path -Path $analysisDir -ChildPath "FailedTests.md"

# Initialiser le fichier d'identification des tests en échec
Set-Content -Path $failedTestsFile -Value "# Tests en échec`r`n"
Add-Content -Path $failedTestsFile -Value "Date d'analyse : $(Get-Date)`r`n"

# Fonction pour extraire les tests en échec d'un fichier de résultats
function Extract-FailedTests {
    param (
        [string]$ResultsFile,
        [string]$FailedTestsFile,
        [string]$Category
    )
    
    if (-not (Test-Path -Path $ResultsFile)) {
        Write-Host "Le fichier de résultats n'existe pas : $ResultsFile" -ForegroundColor $errorColor
        return @()
    }
    
    $content = Get-Content -Path $ResultsFile -Raw
    if ([string]::IsNullOrEmpty($content)) {
        Write-Host "Le fichier de résultats est vide : $ResultsFile" -ForegroundColor $warningColor
        return @()
    }
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($ResultsFile)
    
    # Extraire les tests en échec
    $failedMatches = [regex]::Matches($content, "\[(.+?)\] ÉCHEC")
    $failedTestNames = $failedMatches | ForEach-Object { $_.Groups[1].Value }
    
    # Extraire les tests en erreur
    $errorMatches = [regex]::Matches($content, "\[(.+?)\] ERREUR")
    $errorTestNames = $errorMatches | ForEach-Object { $_.Groups[1].Value }
    
    # Extraire les tests non trouvés
    $notFoundMatches = [regex]::Matches($content, "\[(.+?)\] NON TROUVÉ")
    $notFoundTestNames = $notFoundMatches | ForEach-Object { $_.Groups[1].Value }
    
    # Combiner tous les tests problématiques
    $allProblematicTests = @()
    
    foreach ($testName in $failedTestNames) {
        $allProblematicTests += @{
            Name = $testName
            Type = "Échec"
            Category = $Category
            File = $fileName
        }
    }
    
    foreach ($testName in $errorTestNames) {
        $allProblematicTests += @{
            Name = $testName
            Type = "Erreur"
            Category = $Category
            File = $fileName
        }
    }
    
    foreach ($testName in $notFoundTestNames) {
        $allProblematicTests += @{
            Name = $testName
            Type = "Non trouvé"
            Category = $Category
            File = $fileName
        }
    }
    
    return $allProblematicTests
}

# Trouver tous les fichiers de résultats
$unitTestResultsFiles = @(
    "BaseFunctionTests_Results.txt",
    "MetadataFunctionTests_Results.txt",
    "CollectionFunctionTests_Results.txt",
    "SerializationFunctionTests_Results.txt",
    "ValidationFunctionTests_Results.txt"
)

$integrationTestResultsFiles = @(
    "ExtractionWorkflowTests_Results.txt",
    "CollectionWorkflowTests_Results.txt",
    "SerializationWorkflowTests_Results.txt",
    "ValidationWorkflowTests_Results.txt"
)

# Extraire les tests en échec
$allProblematicTests = @()

foreach ($resultsFile in $unitTestResultsFiles) {
    $resultsFilePath = Join-Path -Path $resultsDir -ChildPath $resultsFile
    $problematicTests = Extract-FailedTests -ResultsFile $resultsFilePath -FailedTestsFile $failedTestsFile -Category "Tests unitaires"
    $allProblematicTests += $problematicTests
}

foreach ($resultsFile in $integrationTestResultsFiles) {
    $resultsFilePath = Join-Path -Path $resultsDir -ChildPath $resultsFile
    $problematicTests = Extract-FailedTests -ResultsFile $resultsFilePath -FailedTestsFile $failedTestsFile -Category "Tests d'intégration"
    $allProblematicTests += $problematicTests
}

# Ajouter les tests en échec au fichier d'identification
if ($allProblematicTests.Count -eq 0) {
    Add-Content -Path $failedTestsFile -Value "## Aucun test en échec`r`n"
    Add-Content -Path $failedTestsFile -Value "Tous les tests ont réussi!`r`n"
} else {
    # Regrouper par catégorie
    $testsByCategory = $allProblematicTests | Group-Object -Property Category
    
    foreach ($category in $testsByCategory) {
        Add-Content -Path $failedTestsFile -Value "## $($category.Name)`r`n"
        
        # Regrouper par type
        $testsByType = $category.Group | Group-Object -Property Type
        
        foreach ($type in $testsByType) {
            Add-Content -Path $failedTestsFile -Value "### $($type.Name)`r`n"
            
            # Regrouper par fichier
            $testsByFile = $type.Group | Group-Object -Property File
            
            foreach ($file in $testsByFile) {
                Add-Content -Path $failedTestsFile -Value "#### $($file.Name)`r`n"
                
                foreach ($test in $file.Group) {
                    Add-Content -Path $failedTestsFile -Value "- $($test.Name)"
                }
                
                Add-Content -Path $failedTestsFile -Value ""
            }
        }
    }
}

# Ajouter le résumé
Add-Content -Path $failedTestsFile -Value "## Résumé`r`n"
Add-Content -Path $failedTestsFile -Value "- Total des tests en échec : $($allProblematicTests.Count)"

$testsByType = $allProblematicTests | Group-Object -Property Type
foreach ($type in $testsByType) {
    Add-Content -Path $failedTestsFile -Value "- Tests en $($type.Name) : $($type.Count)"
}

# Afficher le résumé
Write-Host "`nRésumé des tests en échec :" -ForegroundColor $infoColor
Write-Host "  Total des tests en échec : $($allProblematicTests.Count)" -ForegroundColor $infoColor

$testsByType = $allProblematicTests | Group-Object -Property Type
foreach ($type in $testsByType) {
    $color = switch ($type.Name) {
        "Échec" { $errorColor }
        "Erreur" { $errorColor }
        "Non trouvé" { $warningColor }
        default { $infoColor }
    }
    
    Write-Host "  Tests en $($type.Name) : $($type.Count)" -ForegroundColor $color
}

if ($allProblematicTests.Count -eq 0) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor $successColor
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué ou sont en erreur. Consultez le fichier d'identification pour plus de détails : $failedTestsFile" -ForegroundColor $errorColor
    exit 1
}
