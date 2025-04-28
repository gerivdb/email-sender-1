#Requires -Version 5.1
<#
.SYNOPSIS
    Pont entre les tests simplifiÃ©s et les tests rÃ©els.

.DESCRIPTION
    Ce script permet d'exÃ©cuter et de comparer les tests simplifiÃ©s et les tests rÃ©els.
    Il offre plusieurs modes d'exÃ©cution pour faciliter la transition entre les deux types de tests.

.PARAMETER Mode
    Le mode d'exÃ©cution du script.
    - Simplified : ExÃ©cute uniquement les tests simplifiÃ©s.
    - Real : ExÃ©cute uniquement les tests rÃ©els.
    - Compare : ExÃ©cute les deux types de tests et compare les rÃ©sultats.
    - Fix : Tente de corriger les problÃ¨mes dans les tests rÃ©els.
    - All : ExÃ©cute tous les tests sans comparaison.

.EXAMPLE
    .\Bridge-Tests.ps1 -Mode Simplified
    ExÃ©cute uniquement les tests simplifiÃ©s.

.EXAMPLE
    .\Bridge-Tests.ps1 -Mode Compare
    ExÃ©cute les deux types de tests et compare les rÃ©sultats.
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

# Mappings entre les tests simplifiÃ©s et les tests rÃ©els
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

# Fonction pour exÃ©cuter les tests et afficher les rÃ©sultats
function Invoke-TestsWithSummary {
    param (
        [string[]]$TestFiles,
        [string]$TestType
    )

    if ($TestFiles.Count -eq 0) {
        Write-Warning "Aucun fichier de test $TestType trouvÃ©."
        return $null
    }

    Write-Host "`n===== ExÃ©cution des tests $TestType =====" -ForegroundColor Cyan
    Write-Host "Fichiers de test trouvÃ©s : $($TestFiles.Count)" -ForegroundColor Gray

    $results = Invoke-Pester -Path $TestFiles -PassThru -Output Normal

    Write-Host "`nRÃ©sumÃ© des rÃ©sultats de test $TestType :" -ForegroundColor Cyan
    Write-Host "Tests exÃ©cutÃ©s : $($results.TotalCount)"
    Write-Host "Tests rÃ©ussis : $($results.PassedCount)" -ForegroundColor Green
    Write-Host "Tests Ã©chouÃ©s : $($results.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorÃ©s : $($results.SkippedCount)" -ForegroundColor Yellow
    Write-Host "DurÃ©e totale : $($results.Duration.TotalSeconds) secondes"

    return $results
}

# Fonction pour comparer les rÃ©sultats des tests
function Compare-TestResults {
    param (
        [PSObject]$SimplifiedResults,
        [PSObject]$RealResults,
        [hashtable]$Mappings
    )

    Write-Host "`n===== Comparaison des rÃ©sultats =====" -ForegroundColor Cyan

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
            "Test simplifiÃ©" = $simplifiedTestName
            "Test rÃ©el" = $realTestName
            "Tests simplifiÃ©s" = "$simplifiedPassedCount / $simplifiedTestCount"
            "Tests rÃ©els" = "$realPassedCount / $realTestCount"
            "Couverture simplifiÃ©e" = "$simplifiedCoverage%"
            "Couverture rÃ©elle" = "$realCoverage%"
        }
    }

    $comparisonTable | Format-Table -AutoSize
}

# Initialiser le module avec des stubs fonctionnels
function Initialize-ModuleStub {
    $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"

    if (-not (Test-Path -Path $modulePath)) {
        Write-Error "Le module Format-Converters n'existe pas Ã  l'emplacement '$modulePath'."
        return $false
    }

    # ExÃ©cuter le script d'initialisation du module
    $initScript = Join-Path -Path $PSScriptRoot -ChildPath "Initialize-ModuleStub.ps1"
    if (Test-Path -Path $initScript) {
        & $initScript
        return $true
    }
    else {
        Write-Error "Le script d'initialisation du module n'existe pas Ã  l'emplacement '$initScript'."
        return $false
    }
}

# Tenter de corriger les problÃ¨mes dans les tests rÃ©els
function Repair-RealTests {
    Write-Host "`n=== Tentative de correction des tests rÃ©els ===" -ForegroundColor Cyan

    # ExÃ©cuter le script de rÃ©paration des tests
    $repairScript = Join-Path -Path $PSScriptRoot -ChildPath "Fix-TestFiles.ps1"
    if (Test-Path -Path $repairScript) {
        & $repairScript
        return $true
    }
    else {
        Write-Error "Le script de rÃ©paration des tests n'existe pas Ã  l'emplacement '$repairScript'."
        return $false
    }
}

# GÃ©nÃ©rer un rapport de couverture de test
function Invoke-CoverageReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$PSScriptRoot\Reports"
    )

    Write-Host "`n=== GÃ©nÃ©ration du rapport de couverture de test ===" -ForegroundColor Cyan

    # CrÃ©er le rÃ©pertoire de rapport s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "RÃ©pertoire de rapport crÃ©Ã© : $OutputPath" -ForegroundColor Yellow
    }

    # Obtenir le chemin du module
    $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
    if (-not (Test-Path -Path $modulePath)) {
        Write-Error "Le module Format-Converters n'existe pas Ã  l'emplacement : $modulePath"
        return $false
    }

    # Obtenir tous les fichiers de test rÃ©els
    $testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" |
        Where-Object { $_.Name -notlike "*.Simplified.ps1" } |
        ForEach-Object { $_.FullName }

    if ($testFiles.Count -eq 0) {
        Write-Warning "Aucun fichier de test rÃ©el trouvÃ© dans le rÃ©pertoire : $PSScriptRoot"
        return $false
    }

    # GÃ©nÃ©rer le rapport de couverture
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportFile = Join-Path -Path $OutputPath -ChildPath "CoverageReport_$timestamp.xml"

    Write-Host "GÃ©nÃ©ration du rapport de couverture pour le module : $modulePath" -ForegroundColor Yellow
    Write-Host "Fichiers de test : $($testFiles.Count) fichiers" -ForegroundColor Yellow
    Write-Host "Rapport de couverture : $reportFile" -ForegroundColor Yellow

    try {
        $results = Invoke-Pester -Path $testFiles -CodeCoverage $modulePath -PassThru

        # Afficher un rÃ©sumÃ© de la couverture
        Write-Host "`nRÃ©sumÃ© de la couverture de test :" -ForegroundColor Cyan
        Write-Host "Commandes exÃ©cutÃ©es : $($results.CodeCoverage.NumberOfCommandsExecuted)" -ForegroundColor Yellow
        Write-Host "Commandes analysÃ©es : $($results.CodeCoverage.NumberOfCommandsAnalyzed)" -ForegroundColor Yellow
        Write-Host "Pourcentage de couverture : $($results.CodeCoverage.CoveragePercent)%" -ForegroundColor Yellow

        # Enregistrer le rapport au format XML
        $results | Export-Clixml -Path $reportFile -Force

        # GÃ©nÃ©rer un rapport HTML si possible
        $htmlReportFile = Join-Path -Path $OutputPath -ChildPath "CoverageReport_$timestamp.html"

        try {
            # VÃ©rifier si le module ReportUnit est disponible
            if (Get-Module -ListAvailable -Name ReportUnit) {
                Import-Module -Name ReportUnit -Force
                ConvertTo-PesterReport -InputFile $reportFile -OutputFile $htmlReportFile
                Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $htmlReportFile" -ForegroundColor Green
            }
            else {
                Write-Warning "Le module ReportUnit n'est pas installÃ©. Le rapport HTML n'a pas Ã©tÃ© gÃ©nÃ©rÃ©."
                Write-Warning "Pour installer le module, exÃ©cutez : Install-Module -Name ReportUnit -Scope CurrentUser"
            }
        }
        catch {
            Write-Warning "Erreur lors de la gÃ©nÃ©ration du rapport HTML : $_"
        }

        return $true
    }
    catch {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport de couverture : $_"
        return $false
    }
}

# Initialiser le module si nÃ©cessaire
if ($Mode -eq "Fix") {
    $moduleInitialized = Initialize-ModuleStub
    if (-not $moduleInitialized) {
        Write-Error "Impossible d'initialiser le module. ArrÃªt du script."
        exit 1
    }

    $repaired = Repair-RealTests
    if ($repaired) {
        Write-Host "`nExÃ©cution des tests rÃ©els aprÃ¨s rÃ©paration :" -ForegroundColor Cyan
        $Mode = "Real"
    }
    else {
        Write-Error "Impossible de rÃ©parer les tests rÃ©els. ArrÃªt du script."
        exit 1
    }
}

# GÃ©nÃ©rer un rapport de couverture si demandÃ©
if ($Mode -eq "Coverage") {
    $coverageGenerated = Invoke-CoverageReport -OutputPath $ReportPath
    if (-not $coverageGenerated) {
        Write-Error "Impossible de gÃ©nÃ©rer le rapport de couverture. ArrÃªt du script."
        exit 1
    }

    exit 0
}

# Obtenir les fichiers de test
$simplifiedTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.Simplified.ps1" | ForEach-Object { $_.FullName }
$realTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" | Where-Object { $_.Name -notlike "*.Simplified.ps1" } | ForEach-Object { $_.FullName }

# ExÃ©cuter les tests selon le mode spÃ©cifiÃ©
$simplifiedResults = $null
$realResults = $null

if ($Mode -eq "All" -or $Mode -eq "Simplified") {
    $simplifiedResults = Invoke-TestsWithSummary -TestFiles $simplifiedTestFiles -TestType "simplifiÃ©s"
}

if ($Mode -eq "All" -or $Mode -eq "Real") {
    $realResults = Invoke-TestsWithSummary -TestFiles $realTestFiles -TestType "rÃ©els"
}

if ($Mode -eq "All" -or $Mode -eq "Compare") {
    if ($null -eq $simplifiedResults -and $Mode -eq "Compare") {
        $simplifiedResults = Invoke-TestsWithSummary -TestFiles $simplifiedTestFiles -TestType "simplifiÃ©s"
    }

    if ($null -eq $realResults -and $Mode -eq "Compare") {
        $realResults = Invoke-TestsWithSummary -TestFiles $realTestFiles -TestType "rÃ©els"
    }

    if ($null -ne $simplifiedResults -and $null -ne $realResults) {
        Compare-TestResults -SimplifiedResults $simplifiedResults -RealResults $realResults -Mappings $testMappings
    }
    else {
        Write-Warning "Impossible de comparer les rÃ©sultats. Assurez-vous que les deux types de tests ont Ã©tÃ© exÃ©cutÃ©s."
    }
}

# Afficher un rÃ©sumÃ© global
if (($Mode -eq "All" -or $Mode -eq "Compare") -and $null -ne $simplifiedResults -and $null -ne $realResults) {
    Write-Host "`n===== RÃ©sumÃ© global =====" -ForegroundColor Cyan
    Write-Host "Tests simplifiÃ©s : $($simplifiedResults.TotalCount) tests, $($simplifiedResults.PassedCount) rÃ©ussis, $($simplifiedResults.FailedCount) Ã©chouÃ©s"
    Write-Host "Tests rÃ©els : $($realResults.TotalCount) tests, $($realResults.PassedCount) rÃ©ussis, $($realResults.FailedCount) Ã©chouÃ©s"

    $totalTests = $simplifiedResults.TotalCount + $realResults.TotalCount
    $passedTests = $simplifiedResults.PassedCount + $realResults.PassedCount
    $coveragePercentage = [math]::Round(($passedTests / $totalTests) * 100, 2)

    Write-Host "Couverture totale : $coveragePercentage% ($passeddevelopment/testing/tests/$totalTests tests rÃ©ussis)" -ForegroundColor Cyan
}

# GÃ©nÃ©rer un rapport si demandÃ©
if ($GenerateReport) {
    Write-Host "`n===== GÃ©nÃ©ration du rapport =====" -ForegroundColor Cyan

    # CrÃ©er le rÃ©pertoire de rapport s'il n'existe pas
    if (-not (Test-Path -Path $ReportPath)) {
        New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null
        Write-Host "RÃ©pertoire de rapport crÃ©Ã© : $ReportPath" -ForegroundColor Yellow
    }

    # GÃ©nÃ©rer le rapport
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportFile = Join-Path -Path $ReportPath -ChildPath "TestReport_$timestamp.xml"

    Write-Host "GÃ©nÃ©ration du rapport de test : $reportFile" -ForegroundColor Yellow

    # CrÃ©er un objet de rapport
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

    Write-Host "Rapport de test gÃ©nÃ©rÃ© : $reportFile" -ForegroundColor Green

    # GÃ©nÃ©rer un rapport de couverture si les tests rÃ©els ont Ã©tÃ© exÃ©cutÃ©s
    if ($Mode -eq "All" -or $Mode -eq "Real") {
        Invoke-CoverageReport -OutputPath $ReportPath
    }
}
