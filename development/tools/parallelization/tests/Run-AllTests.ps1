# Script pour exécuter tous les tests unitaires du module UnifiedParallel
# et générer un rapport de couverture de code

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$modulePath = Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1"

# Chemin des tests
$testsPath = $PSScriptRoot

# Créer le dossier de rapports s'il n'existe pas
$reportsPath = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsPath)) {
    New-Item -Path $reportsPath -ItemType Directory -Force | Out-Null
}

# Exécuter les tests individuellement
Write-Host "Exécution des tests unitaires pour le module UnifiedParallel..." -ForegroundColor Cyan

# Créer un objet pour stocker les résultats
$testResults = [PSCustomObject]@{
    TotalCount   = 0
    PassedCount  = 0
    FailedCount  = 0
    SkippedCount = 0
    Duration     = [timespan]::Zero
    CodeCoverage = [PSCustomObject]@{
        CommandsAnalyzedCount = 0
        CommandsExecutedCount = 0
    }
}

# Exécuter chaque fichier de test individuellement
$testFiles = Get-ChildItem -Path $testsPath -Filter "*.ps1" | Where-Object { $_.Name -ne "Run-AllTests.ps1" -and $_.Name -ne "PerformanceTests.ps1" }

foreach ($testFile in $testFiles) {
    Write-Host "`nExécution des tests dans $($testFile.Name)..." -ForegroundColor Yellow
    try {
        & $testFile.FullName
    } catch {
        Write-Host "Erreur lors de l'exécution des tests dans $($testFile.Name): $_" -ForegroundColor Red
    }
}

# Afficher le résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Total des tests: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale: $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher le résumé de la couverture de code
Write-Host "`nRésumé de la couverture de code:" -ForegroundColor Cyan
$coverageSummary = $testResults.CodeCoverage.CommandsAnalyzedCount
$coveredCommands = $testResults.CodeCoverage.CommandsExecutedCount
$coveragePercent = if ($coverageSummary -gt 0) { [math]::Round(($coveredCommands / $coverageSummary) * 100, 2) } else { 0 }

Write-Host "Commandes analysées: $coverageSummary" -ForegroundColor White
Write-Host "Commandes couvertes: $coveredCommands" -ForegroundColor White
Write-Host "Pourcentage de couverture: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { "Green" } elseif ($coveragePercent -ge 60) { "Yellow" } else { "Red" })

# Afficher le chemin du rapport de couverture
Write-Host "`nRapport de couverture généré: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor Cyan

# Retourner les résultats des tests
return $testResults
