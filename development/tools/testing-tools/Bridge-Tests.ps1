#Requires -Version 5.1
<#
.SYNOPSIS
    Pont entre les tests simplifiÃƒÂ©s et les tests rÃƒÂ©els.

.DESCRIPTION
    Ce script permet d'exÃƒÂ©cuter et de comparer les tests simplifiÃƒÂ©s et les tests rÃƒÂ©els.
    Il offre plusieurs modes d'exÃƒÂ©cution pour faciliter la transition entre les deux types de tests.

.PARAMETER Mode
    Le mode d'exÃƒÂ©cution du script.
    - Simplified : ExÃƒÂ©cute uniquement les tests simplifiÃƒÂ©s.
    - Real : ExÃƒÂ©cute uniquement les tests rÃƒÂ©els.
    - Compare : ExÃƒÂ©cute les deux types de tests et compare les rÃƒÂ©sultats.
    - Fix : Tente de corriger les problÃƒÂ¨mes dans les tests rÃƒÂ©els.
    - All : ExÃƒÂ©cute tous les tests sans comparaison.

.EXAMPLE
    .\Bridge-Tests.ps1 -Mode Simplified
    ExÃƒÂ©cute uniquement les tests simplifiÃƒÂ©s.

.EXAMPLE
    .\Bridge-Tests.ps1 -Mode Compare
    ExÃƒÂ©cute les deux types de tests et compare les rÃƒÂ©sultats.
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

# Mappings entre les tests simplifiÃƒÂ©s et les tests rÃƒÂ©els
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

# Fonction pour exÃƒÂ©cuter les tests et afficher les rÃƒÂ©sultats
function Invoke-TestsWithSummary {
    param (
        [string[]]$TestFiles,
        [string]$TestType
    )

    if ($TestFiles.Count -eq 0) {
        Write-Warning "Aucun fichier de test $TestType trouvÃƒÂ©."
        return $null
    }

    Write-Host "`n===== ExÃƒÂ©cution des tests $TestType =====" -ForegroundColor Cyan
    Write-Host "Fichiers de test trouvÃƒÂ©s : $($TestFiles.Count)" -ForegroundColor Gray

    $results = Invoke-Pester -Path $TestFiles -PassThru -Output Normal

    Write-Host "`nRÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats de test $TestType :" -ForegroundColor Cyan
    Write-Host "Tests exÃƒÂ©cutÃƒÂ©s : $($results.TotalCount)"
    Write-Host "Tests rÃƒÂ©ussis : $($results.PassedCount)" -ForegroundColor Green
    Write-Host "Tests ÃƒÂ©chouÃƒÂ©s : $($results.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorÃƒÂ©s : $($results.SkippedCount)" -ForegroundColor Yellow
    Write-Host "DurÃƒÂ©e totale : $($results.Duration.TotalSeconds) secondes"

    return $results
}

# Fonction pour comparer les rÃƒÂ©sultats des tests
function Compare-TestResults {
    param (
        [PSObject]$SimplifiedResults,
        [PSObject]$RealResults,
        [hashtable]$Mappings
    )

    Write-Host "`n===== Comparaison des rÃƒÂ©sultats =====" -ForegroundColor Cyan

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
            "Test simplifiÃƒÂ©" = $simplifiedTestName
            "Test rÃƒÂ©el" = $realTestName
            "Tests simplifiÃƒÂ©s" = "$simplifiedPassedCount / $simplifiedTestCount"
            "Tests rÃƒÂ©els" = "$realPassedCount / $realTestCount"
            "Couverture simplifiÃƒÂ©e" = "$simplifiedCoverage%"
            "Couverture rÃƒÂ©elle" = "$realCoverage%"
        }
    }

    $comparisonTable | Format-Table -AutoSize
}

# Initialiser le module avec des stubs fonctionnels
function Initialize-ModuleStub {
    $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"

    if (-not (Test-Path -Path $modulePath)) {
        Write-Error "Le module Format-Converters n'existe pas ÃƒÂ  l'emplacement '$modulePath'."
        return $false
    }

    # ExÃƒÂ©cuter le script d'initialisation du module
    $initScript = Join-Path -Path $PSScriptRoot -ChildPath "Initialize-ModuleStub.ps1"
    if (Test-Path -Path $initScript) {
        & $initScript
        return $true
    }
    else {
        Write-Error "Le script d'initialisation du module n'existe pas ÃƒÂ  l'emplacement '$initScript'."
        return $false
    }
}

# Tenter de corriger les problÃƒÂ¨mes dans les tests rÃƒÂ©els
function Repair-RealTests {
    Write-Host "`n=== Tentative de correction des tests rÃƒÂ©els ===" -ForegroundColor Cyan

    # ExÃƒÂ©cuter le script de rÃƒÂ©paration des tests
    $repairScript = Join-Path -Path $PSScriptRoot -ChildPath "Fix-TestFiles.ps1"
    if (Test-Path -Path $repairScript) {
        & $repairScript
        return $true
    }
    else {
        Write-Error "Le script de rÃƒÂ©paration des tests n'existe pas ÃƒÂ  l'emplacement '$repairScript'."
        return $false
    }
}

# GÃƒÂ©nÃƒÂ©rer un rapport de couverture de test
function Invoke-CoverageReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$PSScriptRoot\Reports"
    )

    Write-Host "`n=== GÃƒÂ©nÃƒÂ©ration du rapport de couverture de test ===" -ForegroundColor Cyan

    # CrÃƒÂ©er le rÃƒÂ©pertoire de rapport s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "RÃƒÂ©pertoire de rapport crÃƒÂ©ÃƒÂ© : $OutputPath" -ForegroundColor Yellow
    }

    # Obtenir le chemin du module
    $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
    if (-not (Test-Path -Path $modulePath)) {
        Write-Error "Le module Format-Converters n'existe pas ÃƒÂ  l'emplacement : $modulePath"
        return $false
    }

    # Obtenir tous les fichiers de test rÃƒÂ©els
    $testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" |
        Where-Object { $_.Name -notlike "*.Simplified.ps1" } |
        ForEach-Object { $_.FullName }

    if ($testFiles.Count -eq 0) {
        Write-Warning "Aucun fichier de test rÃƒÂ©el trouvÃƒÂ© dans le rÃƒÂ©pertoire : $PSScriptRoot"
        return $false
    }

    # GÃƒÂ©nÃƒÂ©rer le rapport de couverture
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportFile = Join-Path -Path $OutputPath -ChildPath "CoverageReport_$timestamp.xml"

    Write-Host "GÃƒÂ©nÃƒÂ©ration du rapport de couverture pour le module : $modulePath" -ForegroundColor Yellow
    Write-Host "Fichiers de test : $($testFiles.Count) fichiers" -ForegroundColor Yellow
    Write-Host "Rapport de couverture : $reportFile" -ForegroundColor Yellow

    try {
        $results = Invoke-Pester -Path $testFiles -CodeCoverage $modulePath -PassThru

        # Afficher un rÃƒÂ©sumÃƒÂ© de la couverture
        Write-Host "`nRÃƒÂ©sumÃƒÂ© de la couverture de test :" -ForegroundColor Cyan
        Write-Host "Commandes exÃƒÂ©cutÃƒÂ©es : $($results.CodeCoverage.NumberOfCommandsExecuted)" -ForegroundColor Yellow
        Write-Host "Commandes analysÃƒÂ©es : $($results.CodeCoverage.NumberOfCommandsAnalyzed)" -ForegroundColor Yellow
        Write-Host "Pourcentage de couverture : $($results.CodeCoverage.CoveragePercent)%" -ForegroundColor Yellow

        # Enregistrer le rapport au format XML
        $results | Export-Clixml -Path $reportFile -Force

        # GÃƒÂ©nÃƒÂ©rer un rapport HTML si possible
        $htmlReportFile = Join-Path -Path $OutputPath -ChildPath "CoverageReport_$timestamp.html"

        try {
            # VÃƒÂ©rifier si le module ReportUnit est disponible
            if (Get-Module -ListAvailable -Name ReportUnit) {
                Import-Module -Name ReportUnit -Force
                ConvertTo-PesterReport -InputFile $reportFile -OutputFile $htmlReportFile
                Write-Host "Rapport HTML gÃƒÂ©nÃƒÂ©rÃƒÂ© : $htmlReportFile" -ForegroundColor Green
            }
            else {
                Write-Warning "Le module ReportUnit n'est pas installÃƒÂ©. Le rapport HTML n'a pas ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©."
                Write-Warning "Pour installer le module, exÃƒÂ©cutez : Install-Module -Name ReportUnit -Scope CurrentUser"
            }
        }
        catch {
            Write-Warning "Erreur lors de la gÃƒÂ©nÃƒÂ©ration du rapport HTML : $_"
        }

        return $true
    }
    catch {
        Write-Error "Erreur lors de la gÃƒÂ©nÃƒÂ©ration du rapport de couverture : $_"
        return $false
    }
}

# Initialiser le module si nÃƒÂ©cessaire
if ($Mode -eq "Fix") {
    $moduleInitialized = Initialize-ModuleStub
    if (-not $moduleInitialized) {
        Write-Error "Impossible d'initialiser le module. ArrÃƒÂªt du script."
        exit 1
    }

    $repaired = Repair-RealTests
    if ($repaired) {
        Write-Host "`nExÃƒÂ©cution des tests rÃƒÂ©els aprÃƒÂ¨s rÃƒÂ©paration :" -ForegroundColor Cyan
        $Mode = "Real"
    }
    else {
        Write-Error "Impossible de rÃƒÂ©parer les tests rÃƒÂ©els. ArrÃƒÂªt du script."
        exit 1
    }
}

# GÃƒÂ©nÃƒÂ©rer un rapport de couverture si demandÃƒÂ©
if ($Mode -eq "Coverage") {
    $coverageGenerated = Invoke-CoverageReport -OutputPath $ReportPath
    if (-not $coverageGenerated) {
        Write-Error "Impossible de gÃƒÂ©nÃƒÂ©rer le rapport de couverture. ArrÃƒÂªt du script."
        exit 1
    }

    exit 0
}

# Obtenir les fichiers de test
$simplifiedTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.Simplified.ps1" | ForEach-Object { $_.FullName }
$realTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" | Where-Object { $_.Name -notlike "*.Simplified.ps1" } | ForEach-Object { $_.FullName }

# ExÃƒÂ©cuter les tests selon le mode spÃƒÂ©cifiÃƒÂ©
$simplifiedResults = $null
$realResults = $null

if ($Mode -eq "All" -or $Mode -eq "Simplified") {
    $simplifiedResults = Invoke-TestsWithSummary -TestFiles $simplifiedTestFiles -TestType "simplifiÃƒÂ©s"
}

if ($Mode -eq "All" -or $Mode -eq "Real") {
    $realResults = Invoke-TestsWithSummary -TestFiles $realTestFiles -TestType "rÃƒÂ©els"
}

if ($Mode -eq "All" -or $Mode -eq "Compare") {
    if ($null -eq $simplifiedResults -and $Mode -eq "Compare") {
        $simplifiedResults = Invoke-TestsWithSummary -TestFiles $simplifiedTestFiles -TestType "simplifiÃƒÂ©s"
    }

    if ($null -eq $realResults -and $Mode -eq "Compare") {
        $realResults = Invoke-TestsWithSummary -TestFiles $realTestFiles -TestType "rÃƒÂ©els"
    }

    if ($null -ne $simplifiedResults -and $null -ne $realResults) {
        Compare-TestResults -SimplifiedResults $simplifiedResults -RealResults $realResults -Mappings $testMappings
    }
    else {
        Write-Warning "Impossible de comparer les rÃƒÂ©sultats. Assurez-vous que les deux types de tests ont ÃƒÂ©tÃƒÂ© exÃƒÂ©cutÃƒÂ©s."
    }
}

# Afficher un rÃƒÂ©sumÃƒÂ© global
if (($Mode -eq "All" -or $Mode -eq "Compare") -and $null -ne $simplifiedResults -and $null -ne $realResults) {
    Write-Host "`n===== RÃƒÂ©sumÃƒÂ© global =====" -ForegroundColor Cyan
    Write-Host "Tests simplifiÃƒÂ©s : $($simplifiedResults.TotalCount) tests, $($simplifiedResults.PassedCount) rÃƒÂ©ussis, $($simplifiedResults.FailedCount) ÃƒÂ©chouÃƒÂ©s"
    Write-Host "Tests rÃƒÂ©els : $($realResults.TotalCount) tests, $($realResults.PassedCount) rÃƒÂ©ussis, $($realResults.FailedCount) ÃƒÂ©chouÃƒÂ©s"

    $totalTests = $simplifiedResults.TotalCount + $realResults.TotalCount
    $passedTests = $simplifiedResults.PassedCount + $realResults.PassedCount
    $coveragePercentage = [math]::Round(($passedTests / $totalTests) * 100, 2)

    Write-Host "Couverture totale : $coveragePercentage% ($passeddevelopment/testing/tests/$totalTests tests rÃƒÂ©ussis)" -ForegroundColor Cyan
}

# GÃƒÂ©nÃƒÂ©rer un rapport si demandÃƒÂ©
if ($GenerateReport) {
    Write-Host "`n===== GÃƒÂ©nÃƒÂ©ration du rapport =====" -ForegroundColor Cyan

    # CrÃƒÂ©er le rÃƒÂ©pertoire de rapport s'il n'existe pas
    if (-not (Test-Path -Path $ReportPath)) {
        New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null
        Write-Host "RÃƒÂ©pertoire de rapport crÃƒÂ©ÃƒÂ© : $ReportPath" -ForegroundColor Yellow
    }

    # GÃƒÂ©nÃƒÂ©rer le rapport
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportFile = Join-Path -Path $ReportPath -ChildPath "TestReport_$timestamp.xml"

    Write-Host "GÃƒÂ©nÃƒÂ©ration du rapport de test : $reportFile" -ForegroundColor Yellow

    # CrÃƒÂ©er un objet de rapport
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

    Write-Host "Rapport de test gÃƒÂ©nÃƒÂ©rÃƒÂ© : $reportFile" -ForegroundColor Green

    # GÃƒÂ©nÃƒÂ©rer un rapport de couverture si les tests rÃƒÂ©els ont ÃƒÂ©tÃƒÂ© exÃƒÂ©cutÃƒÂ©s
    if ($Mode -eq "All" -or $Mode -eq "Real") {
        Invoke-CoverageReport -OutputPath $ReportPath
    }
}
