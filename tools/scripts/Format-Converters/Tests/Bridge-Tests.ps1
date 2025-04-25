#Requires -Version 5.1
<#
.SYNOPSIS
    Pont entre les tests simplifiés et les tests réels.

.DESCRIPTION
    Ce script permet d'exécuter et de comparer les tests simplifiés et les tests réels.
    Il offre plusieurs modes d'exécution pour faciliter la transition entre les deux types de tests.

.PARAMETER Mode
    Le mode d'exécution du script.
    - Simplified : Exécute uniquement les tests simplifiés.
    - Real : Exécute uniquement les tests réels.
    - Compare : Exécute les deux types de tests et compare les résultats.
    - Fix : Tente de corriger les problèmes dans les tests réels.
    - All : Exécute tous les tests sans comparaison.

.EXAMPLE
    .\Bridge-Tests.ps1 -Mode Simplified
    Exécute uniquement les tests simplifiés.

.EXAMPLE
    .\Bridge-Tests.ps1 -Mode Compare
    Exécute les deux types de tests et compare les résultats.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Simplified", "Real", "Compare", "Fix", "Coverage")]
    [string]$Mode = "All",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "$PSScriptRoot\Reports"
)

# Mappings entre les tests simplifiés et les tests réels
$testMappings = @{
    "Handle-AmbiguousFormats.Tests.Simplified.ps1" = "Handle-AmbiguousFormats.Tests.ps1"
    "Show-FormatDetectionResults.Tests.Simplified.ps1" = "Show-FormatDetectionResults.Tests.ps1"
    "Test-FileFormat.Tests.Simplified.ps1" = "Detect-FileFormat.Tests.ps1"
    "Test-DetectedFileFormat.Tests.Simplified.ps1" = "Detect-FileFormat.Tests.ps1"
    "Test-FileFormatWithConfirmation.Tests.Simplified.ps1" = "Detect-FileFormatWithConfirmation.Tests.ps1"
    "Convert-FileFormat.Tests.Simplified.ps1" = "Format-Converters.Tests.ps1"
    "Confirm-FormatDetection.Tests.Simplified.ps1" = "Detect-FileFormatWithConfirmation.Tests.ps1"
    "Integration.Tests.Simplified.ps1" = "Format-Converters.Tests.ps1"
}

# Fonction pour exécuter les tests et afficher les résultats
function Invoke-TestsWithSummary {
    param (
        [string[]]$TestFiles,
        [string]$TestType
    )

    if ($TestFiles.Count -eq 0) {
        Write-Warning "Aucun fichier de test $TestType trouvé."
        return $null
    }

    Write-Host "`n===== Exécution des tests $TestType =====" -ForegroundColor Cyan
    Write-Host "Fichiers de test trouvés : $($TestFiles.Count)" -ForegroundColor Gray

    $results = Invoke-Pester -Path $TestFiles -PassThru -Output Normal

    Write-Host "`nRésumé des résultats de test $TestType :" -ForegroundColor Cyan
    Write-Host "Tests exécutés : $($results.TotalCount)"
    Write-Host "Tests réussis : $($results.PassedCount)" -ForegroundColor Green
    Write-Host "Tests échoués : $($results.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorés : $($results.SkippedCount)" -ForegroundColor Yellow
    Write-Host "Durée totale : $($results.Duration.TotalSeconds) secondes"

    return $results
}

# Fonction pour comparer les résultats des tests
function Compare-TestResults {
    param (
        [PSObject]$SimplifiedResults,
        [PSObject]$RealResults,
        [hashtable]$Mappings
    )

    Write-Host "`n===== Comparaison des résultats =====" -ForegroundColor Cyan

    $comparisonTable = @()

    foreach ($simplifiedTest in $Mappings.Keys) {
        $realTest = $Mappings[$simplifiedTest]

        $simplifiedTestName = [System.IO.Path]::GetFileNameWithoutExtension($simplifiedTest)
        $realTestName = [System.IO.Path]::GetFileNameWithoutExtension($realTest)

        $simplifiedTestCount = ($SimplifiedResults.Tests | Where-Object { $_.Path -like "*$simplifiedTestName*" }).Count
        $realTestCount = ($RealResults.Tests | Where-Object { $_.Path -like "*$realTestName*" }).Count

        $simplifiedPassedCount = ($SimplifiedResults.Tests | Where-Object { $_.Path -like "*$simplifiedTestName*" -and $_.Result -eq "Passed" }).Count
        $realPassedCount = ($RealResults.Tests | Where-Object { $_.Path -like "*$realTestName*" -and $_.Result -eq "Passed" }).Count

        $simplifiedCoverage = if ($simplifiedTestCount -gt 0) { [math]::Round(($simplifiedPassedCount / $simplifiedTestCount) * 100, 2) } else { 0 }
        $realCoverage = if ($realTestCount -gt 0) { [math]::Round(($realPassedCount / $realTestCount) * 100, 2) } else { 0 }

        $comparisonTable += [PSCustomObject]@{
            "Test simplifié" = $simplifiedTestName
            "Test réel" = $realTestName
            "Tests simplifiés" = "$simplifiedPassedCount / $simplifiedTestCount"
            "Tests réels" = "$realPassedCount / $realTestCount"
            "Couverture simplifiée" = "$simplifiedCoverage%"
            "Couverture réelle" = "$realCoverage%"
        }
    }

    $comparisonTable | Format-Table -AutoSize
}

# Initialiser le module avec des stubs fonctionnels
function Initialize-ModuleStub {
    $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"

    if (-not (Test-Path -Path $modulePath)) {
        Write-Error "Le module Format-Converters n'existe pas à l'emplacement '$modulePath'."
        return $false
    }

    # Exécuter le script d'initialisation du module
    $initScript = Join-Path -Path $PSScriptRoot -ChildPath "Initialize-ModuleStub.ps1"
    if (Test-Path -Path $initScript) {
        & $initScript
        return $true
    }
    else {
        Write-Error "Le script d'initialisation du module n'existe pas à l'emplacement '$initScript'."
        return $false
    }
}

# Tenter de corriger les problèmes dans les tests réels
function Repair-RealTests {
    Write-Host "`n=== Tentative de correction des tests réels ===" -ForegroundColor Cyan

    # Exécuter le script de réparation des tests
    $repairScript = Join-Path -Path $PSScriptRoot -ChildPath "Fix-TestFiles.ps1"
    if (Test-Path -Path $repairScript) {
        & $repairScript
        return $true
    }
    else {
        Write-Error "Le script de réparation des tests n'existe pas à l'emplacement '$repairScript'."
        return $false
    }
}

# Générer un rapport de couverture de test
function Invoke-CoverageReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$PSScriptRoot\Reports"
    )

    Write-Host "`n=== Génération du rapport de couverture de test ===" -ForegroundColor Cyan

    # Créer le répertoire de rapport s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de rapport créé : $OutputPath" -ForegroundColor Yellow
    }

    # Obtenir le chemin du module
    $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
    if (-not (Test-Path -Path $modulePath)) {
        Write-Error "Le module Format-Converters n'existe pas à l'emplacement : $modulePath"
        return $false
    }

    # Obtenir tous les fichiers de test réels
    $testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" |
        Where-Object { $_.Name -notlike "*.Simplified.ps1" } |
        ForEach-Object { $_.FullName }

    if ($testFiles.Count -eq 0) {
        Write-Warning "Aucun fichier de test réel trouvé dans le répertoire : $PSScriptRoot"
        return $false
    }

    # Générer le rapport de couverture
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportFile = Join-Path -Path $OutputPath -ChildPath "CoverageReport_$timestamp.xml"

    Write-Host "Génération du rapport de couverture pour le module : $modulePath" -ForegroundColor Yellow
    Write-Host "Fichiers de test : $($testFiles.Count) fichiers" -ForegroundColor Yellow
    Write-Host "Rapport de couverture : $reportFile" -ForegroundColor Yellow

    try {
        $results = Invoke-Pester -Path $testFiles -CodeCoverage $modulePath -PassThru

        # Afficher un résumé de la couverture
        Write-Host "`nRésumé de la couverture de test :" -ForegroundColor Cyan
        Write-Host "Commandes exécutées : $($results.CodeCoverage.NumberOfCommandsExecuted)" -ForegroundColor Yellow
        Write-Host "Commandes analysées : $($results.CodeCoverage.NumberOfCommandsAnalyzed)" -ForegroundColor Yellow
        Write-Host "Pourcentage de couverture : $($results.CodeCoverage.CoveragePercent)%" -ForegroundColor Yellow

        # Enregistrer le rapport au format XML
        $results | Export-Clixml -Path $reportFile -Force

        # Générer un rapport HTML si possible
        $htmlReportFile = Join-Path -Path $OutputPath -ChildPath "CoverageReport_$timestamp.html"

        try {
            # Vérifier si le module ReportUnit est disponible
            if (Get-Module -ListAvailable -Name ReportUnit) {
                Import-Module -Name ReportUnit -Force
                ConvertTo-PesterReport -InputFile $reportFile -OutputFile $htmlReportFile
                Write-Host "Rapport HTML généré : $htmlReportFile" -ForegroundColor Green
            }
            else {
                Write-Warning "Le module ReportUnit n'est pas installé. Le rapport HTML n'a pas été généré."
                Write-Warning "Pour installer le module, exécutez : Install-Module -Name ReportUnit -Scope CurrentUser"
            }
        }
        catch {
            Write-Warning "Erreur lors de la génération du rapport HTML : $_"
        }

        return $true
    }
    catch {
        Write-Error "Erreur lors de la génération du rapport de couverture : $_"
        return $false
    }
}

# Initialiser le module si nécessaire
if ($Mode -eq "Fix") {
    $moduleInitialized = Initialize-ModuleStub
    if (-not $moduleInitialized) {
        Write-Error "Impossible d'initialiser le module. Arrêt du script."
        exit 1
    }

    $repaired = Repair-RealTests
    if ($repaired) {
        Write-Host "`nExécution des tests réels après réparation :" -ForegroundColor Cyan
        $Mode = "Real"
    }
    else {
        Write-Error "Impossible de réparer les tests réels. Arrêt du script."
        exit 1
    }
}

# Générer un rapport de couverture si demandé
if ($Mode -eq "Coverage") {
    $coverageGenerated = Invoke-CoverageReport -OutputPath $ReportPath
    if (-not $coverageGenerated) {
        Write-Error "Impossible de générer le rapport de couverture. Arrêt du script."
        exit 1
    }

    exit 0
}

# Obtenir les fichiers de test
$simplifiedTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.Simplified.ps1" | ForEach-Object { $_.FullName }
$realTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" | Where-Object { $_.Name -notlike "*.Simplified.ps1" } | ForEach-Object { $_.FullName }

# Exécuter les tests selon le mode spécifié
$simplifiedResults = $null
$realResults = $null

if ($Mode -eq "All" -or $Mode -eq "Simplified") {
    $simplifiedResults = Invoke-TestsWithSummary -TestFiles $simplifiedTestFiles -TestType "simplifiés"
}

if ($Mode -eq "All" -or $Mode -eq "Real") {
    $realResults = Invoke-TestsWithSummary -TestFiles $realTestFiles -TestType "réels"
}

if ($Mode -eq "All" -or $Mode -eq "Compare") {
    if ($null -eq $simplifiedResults -and $Mode -eq "Compare") {
        $simplifiedResults = Invoke-TestsWithSummary -TestFiles $simplifiedTestFiles -TestType "simplifiés"
    }

    if ($null -eq $realResults -and $Mode -eq "Compare") {
        $realResults = Invoke-TestsWithSummary -TestFiles $realTestFiles -TestType "réels"
    }

    if ($null -ne $simplifiedResults -and $null -ne $realResults) {
        Compare-TestResults -SimplifiedResults $simplifiedResults -RealResults $realResults -Mappings $testMappings
    }
    else {
        Write-Warning "Impossible de comparer les résultats. Assurez-vous que les deux types de tests ont été exécutés."
    }
}

# Afficher un résumé global
if (($Mode -eq "All" -or $Mode -eq "Compare") -and $null -ne $simplifiedResults -and $null -ne $realResults) {
    Write-Host "`n===== Résumé global =====" -ForegroundColor Cyan
    Write-Host "Tests simplifiés : $($simplifiedResults.TotalCount) tests, $($simplifiedResults.PassedCount) réussis, $($simplifiedResults.FailedCount) échoués"
    Write-Host "Tests réels : $($realResults.TotalCount) tests, $($realResults.PassedCount) réussis, $($realResults.FailedCount) échoués"

    $totalTests = $simplifiedResults.TotalCount + $realResults.TotalCount
    $passedTests = $simplifiedResults.PassedCount + $realResults.PassedCount
    $coveragePercentage = [math]::Round(($passedTests / $totalTests) * 100, 2)

    Write-Host "Couverture totale : $coveragePercentage% ($passedTests/$totalTests tests réussis)" -ForegroundColor Cyan
}

# Générer un rapport si demandé
if ($GenerateReport) {
    Write-Host "`n===== Génération du rapport =====" -ForegroundColor Cyan

    # Créer le répertoire de rapport s'il n'existe pas
    if (-not (Test-Path -Path $ReportPath)) {
        New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de rapport créé : $ReportPath" -ForegroundColor Yellow
    }

    # Générer le rapport
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportFile = Join-Path -Path $ReportPath -ChildPath "TestReport_$timestamp.xml"

    Write-Host "Génération du rapport de test : $reportFile" -ForegroundColor Yellow

    # Créer un objet de rapport
    $report = [PSCustomObject]@{
        Timestamp = Get-Date
        SimplifiedTests = $simplifiedResults
        RealTests = $realResults
        Comparison = @{
            SimplifiedTotal = $simplifiedResults.TotalCount
            SimplifiedPassed = $simplifiedResults.PassedCount
            SimplifiedFailed = $simplifiedResults.FailedCount
            RealTotal = $realResults.TotalCount
            RealPassed = $realResults.PassedCount
            RealFailed = $realResults.FailedCount
            Difference = $realResults.TotalCount - $simplifiedResults.TotalCount
        }
    }

    # Enregistrer le rapport
    $report | Export-Clixml -Path $reportFile -Force

    Write-Host "Rapport de test généré : $reportFile" -ForegroundColor Green

    # Générer un rapport de couverture si les tests réels ont été exécutés
    if ($Mode -eq "All" -or $Mode -eq "Real") {
        Invoke-CoverageReport -OutputPath $ReportPath
    }
}
