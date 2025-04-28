#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute une suite de tests pour le systÃ¨me d'analyse des pull requests.

.DESCRIPTION
    Ce script exÃ©cute une suite complÃ¨te de tests pour le systÃ¨me d'analyse
    des pull requests en gÃ©nÃ©rant diffÃ©rents types de pull requests et en
    mesurant les performances de l'analyse.

.PARAMETER RepositoryPath
    Le chemin du dÃ©pÃ´t de test.
    Par dÃ©faut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER CreateRepository
    Indique s'il faut crÃ©er un nouveau dÃ©pÃ´t de test.
    Par dÃ©faut: $true

.PARAMETER RunAllTests
    Indique s'il faut exÃ©cuter tous les tests.
    Par dÃ©faut: $true

.PARAMETER GenerateReport
    Indique s'il faut gÃ©nÃ©rer un rapport global.
    Par dÃ©faut: $true

.EXAMPLE
    .\Start-PRTestSuite.ps1
    ExÃ©cute la suite complÃ¨te de tests avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\Start-PRTestSuite.ps1 -CreateRepository $false -RunAllTests $false
    ExÃ©cute uniquement les tests spÃ©cifiÃ©s sans crÃ©er un nouveau dÃ©pÃ´t.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryPath = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",

    [Parameter()]
    [bool]$CreateRepository = $true,

    [Parameter()]
    [bool]$RunAllTests = $true,

    [Parameter()]
    [bool]$GenerateReport = $true,

    [Parameter()]
    [switch]$Force
)

# DÃ©finir le chemin des scripts
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Fonction pour crÃ©er le dÃ©pÃ´t de test
function Initialize-TestRepository {
    Write-Host "Initialisation du dÃ©pÃ´t de test..." -ForegroundColor Cyan

    $newRepoScript = Join-Path -Path $scriptPath -ChildPath "New-TestRepository.ps1"

    if (-not (Test-Path -Path $newRepoScript)) {
        Write-Error "Script New-TestRepository.ps1 non trouvÃ©: $newRepoScript"
        return $false
    }

    & $newRepoScript -Path $RepositoryPath -Force:$Force

    if (-not (Test-Path -Path $RepositoryPath)) {
        Write-Error "Ã‰chec de la crÃ©ation du dÃ©pÃ´t de test: $RepositoryPath"
        return $false
    }

    Write-Host "DÃ©pÃ´t de test initialisÃ© avec succÃ¨s: $RepositoryPath" -ForegroundColor Green
    return $true
}

# Fonction pour exÃ©cuter un test de pull request
function Invoke-PRTest {
    param (
        [string]$TestName,
        [string]$ModificationType,
        [int]$FileCount,
        [int]$ErrorCount,
        [string]$ErrorTypes
    )

    Write-Host "`n========== Test: $TestName ==========" -ForegroundColor Cyan

    $newPRScript = Join-Path -Path $scriptPath -ChildPath "New-TestPullRequest-Fixed.ps1"

    if (-not (Test-Path -Path $newPRScript)) {
        Write-Error "Script New-TestPullRequest-Fixed.ps1 non trouvÃ©: $newPRScript"
        return $null
    }

    # GÃ©nÃ©rer un nom de branche unique
    $branchName = "test/$ModificationType-$FileCount-$ErrorCount-$(Get-Date -Format 'yyyyMMddHHmmss')"

    # ExÃ©cuter le script pour crÃ©er la pull request
    & $newPRScript -RepositoryPath $RepositoryPath -BranchName $branchName -ModificationTypes $ModificationType -FileCount $FileCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes

    # Attendre un peu pour s'assurer que la PR est crÃ©Ã©e
    Start-Sleep -Seconds 2

    # Mesurer les performances
    $measureScript = Join-Path -Path $scriptPath -ChildPath "Measure-PRAnalysisPerformance.ps1"

    if (-not (Test-Path -Path $measureScript)) {
        Write-Error "Script Measure-PRAnalysisPerformance.ps1 non trouvÃ©: $measureScript"
        return $null
    }

    $reportPath = & $measureScript -RepositoryPath $RepositoryPath

    # CrÃ©er un objet de rÃ©sultat de test
    $testResult = [PSCustomObject]@{
        TestName         = $TestName
        ModificationType = $ModificationType
        FileCount        = $FileCount
        ErrorCount       = $ErrorCount
        ErrorTypes       = $ErrorTypes
        BranchName       = $branchName
        ReportPath       = $reportPath
        Timestamp        = Get-Date
    }

    return $testResult
}

# Fonction pour gÃ©nÃ©rer un rapport global
function New-GlobalTestReport {
    param (
        [array]$TestResults
    )

    Write-Host "`nGÃ©nÃ©ration du rapport global..." -ForegroundColor Cyan

    # CrÃ©er le dossier de rapports s'il n'existe pas
    $reportsPath = Join-Path -Path $scriptPath -ChildPath "reports"
    if (-not (Test-Path -Path $reportsPath)) {
        New-Item -ItemType Directory -Path $reportsPath -Force | Out-Null
    }

    # DÃ©finir le chemin du rapport global
    $globalReportPath = Join-Path -Path $reportsPath -ChildPath "PR-TestSuite-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

    # GÃ©nÃ©rer le contenu du rapport
    $reportContent = @"
# Rapport de la suite de tests d'analyse des pull requests

## RÃ©sumÃ©

- **Date d'exÃ©cution**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Nombre de tests exÃ©cutÃ©s**: $($TestResults.Count)
- **DÃ©pÃ´t de test**: $RepositoryPath

## Tests exÃ©cutÃ©s

| Test | Type de modification | Fichiers | Erreurs | Types d'erreurs | Branche |
|------|---------------------|----------|---------|-----------------|---------|
$(
    $TestResults | ForEach-Object {
        "| $($_.TestName) | $($_.ModificationType) | $($_.FileCount) | $($_.ErrorCount) | $($_.ErrorTypes) | $($_.BranchName) |"
    }
)

## Rapports dÃ©taillÃ©s

$(
    $TestResults | ForEach-Object {
        "- [$($_.TestName)]($($_.ReportPath))"
    }
)

## Recommandations

- ExÃ©cuter rÃ©guliÃ¨rement cette suite de tests pour surveiller les performances du systÃ¨me d'analyse
- Ajouter de nouveaux tests pour couvrir des scÃ©narios spÃ©cifiques
- Automatiser l'exÃ©cution de cette suite dans le pipeline CI/CD

## Prochaines Ã©tapes

1. Analyser les rÃ©sultats pour identifier les opportunitÃ©s d'optimisation
2. ImplÃ©menter les amÃ©liorations suggÃ©rÃ©es dans les rapports individuels
3. Mettre Ã  jour la suite de tests avec de nouveaux scÃ©narios

Ce rapport a Ã©tÃ© gÃ©nÃ©rÃ© automatiquement par Start-PRTestSuite.ps1.
"@

    # Ã‰crire le rapport dans le fichier
    Set-Content -Path $globalReportPath -Value $reportContent -Encoding UTF8

    Write-Host "Rapport global gÃ©nÃ©rÃ©: $globalReportPath" -ForegroundColor Green

    return $globalReportPath
}

# Fonction principale
function Start-PRTestSuite {
    $testResults = @()

    # CrÃ©er le dÃ©pÃ´t de test si demandÃ©
    if ($CreateRepository) {
        $repoResult = Initialize-TestRepository
        if (-not $repoResult) {
            return
        }
    }

    # DÃ©finir les tests Ã  exÃ©cuter
    $tests = @()

    if ($RunAllTests) {
        # Tests avec diffÃ©rents types de modifications
        $tests += [PSCustomObject]@{ Name = "Ajout de fichiers"; ModificationType = "Add"; FileCount = 5; ErrorCount = 3; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Modification de fichiers"; ModificationType = "Modify"; FileCount = 5; ErrorCount = 3; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Suppression de fichiers"; ModificationType = "Delete"; FileCount = 3; ErrorCount = 0; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Modifications mixtes"; ModificationType = "Mixed"; FileCount = 8; ErrorCount = 3; ErrorTypes = "All" }

        # Tests avec diffÃ©rents nombres de fichiers
        $tests += [PSCustomObject]@{ Name = "Petit volume"; ModificationType = "Mixed"; FileCount = 3; ErrorCount = 2; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Volume moyen"; ModificationType = "Mixed"; FileCount = 10; ErrorCount = 2; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Grand volume"; ModificationType = "Mixed"; FileCount = 20; ErrorCount = 2; ErrorTypes = "All" }

        # Tests avec diffÃ©rents types d'erreurs
        $tests += [PSCustomObject]@{ Name = "Erreurs de syntaxe"; ModificationType = "Mixed"; FileCount = 5; ErrorCount = 3; ErrorTypes = "Syntax" }
        $tests += [PSCustomObject]@{ Name = "Erreurs de style"; ModificationType = "Mixed"; FileCount = 5; ErrorCount = 3; ErrorTypes = "Style" }
        $tests += [PSCustomObject]@{ Name = "Erreurs de performance"; ModificationType = "Mixed"; FileCount = 5; ErrorCount = 3; ErrorTypes = "Performance" }
        $tests += [PSCustomObject]@{ Name = "Erreurs de sÃ©curitÃ©"; ModificationType = "Mixed"; FileCount = 5; ErrorCount = 3; ErrorTypes = "Security" }
    } else {
        # Tests minimaux
        $tests += [PSCustomObject]@{ Name = "Test minimal"; ModificationType = "Mixed"; FileCount = 3; ErrorCount = 2; ErrorTypes = "All" }
    }

    # ExÃ©cuter les tests
    foreach ($test in $tests) {
        $result = Invoke-PRTest -TestName $test.Name -ModificationType $test.ModificationType -FileCount $test.FileCount -ErrorCount $test.ErrorCount -ErrorTypes $test.ErrorTypes

        if ($null -ne $result) {
            $testResults += $result
        }
    }

    # GÃ©nÃ©rer le rapport global si demandÃ©
    if ($GenerateReport -and $testResults.Count -gt 0) {
        $globalReportPath = New-GlobalTestReport -TestResults $testResults

        Write-Host "`nSuite de tests terminÃ©e. Rapport global: $globalReportPath" -ForegroundColor Green
    } else {
        Write-Host "`nSuite de tests terminÃ©e." -ForegroundColor Green
    }
}

# Exporter la fonction principale
Export-ModuleMember -Function Start-PRTestSuite

# Si le script est exÃ©cutÃ© directement (pas importÃ© comme module)
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # ExÃ©cuter la fonction principale
    Start-PRTestSuite
}
