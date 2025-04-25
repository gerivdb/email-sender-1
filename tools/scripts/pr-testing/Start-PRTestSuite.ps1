#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute une suite de tests pour le système d'analyse des pull requests.

.DESCRIPTION
    Ce script exécute une suite complète de tests pour le système d'analyse
    des pull requests en générant différents types de pull requests et en
    mesurant les performances de l'analyse.

.PARAMETER RepositoryPath
    Le chemin du dépôt de test.
    Par défaut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER CreateRepository
    Indique s'il faut créer un nouveau dépôt de test.
    Par défaut: $true

.PARAMETER RunAllTests
    Indique s'il faut exécuter tous les tests.
    Par défaut: $true

.PARAMETER GenerateReport
    Indique s'il faut générer un rapport global.
    Par défaut: $true

.EXAMPLE
    .\Start-PRTestSuite.ps1
    Exécute la suite complète de tests avec les paramètres par défaut.

.EXAMPLE
    .\Start-PRTestSuite.ps1 -CreateRepository $false -RunAllTests $false
    Exécute uniquement les tests spécifiés sans créer un nouveau dépôt.

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

# Définir le chemin des scripts
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Fonction pour créer le dépôt de test
function Initialize-TestRepository {
    Write-Host "Initialisation du dépôt de test..." -ForegroundColor Cyan

    $newRepoScript = Join-Path -Path $scriptPath -ChildPath "New-TestRepository.ps1"

    if (-not (Test-Path -Path $newRepoScript)) {
        Write-Error "Script New-TestRepository.ps1 non trouvé: $newRepoScript"
        return $false
    }

    & $newRepoScript -Path $RepositoryPath -Force:$Force

    if (-not (Test-Path -Path $RepositoryPath)) {
        Write-Error "Échec de la création du dépôt de test: $RepositoryPath"
        return $false
    }

    Write-Host "Dépôt de test initialisé avec succès: $RepositoryPath" -ForegroundColor Green
    return $true
}

# Fonction pour exécuter un test de pull request
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
        Write-Error "Script New-TestPullRequest-Fixed.ps1 non trouvé: $newPRScript"
        return $null
    }

    # Générer un nom de branche unique
    $branchName = "test/$ModificationType-$FileCount-$ErrorCount-$(Get-Date -Format 'yyyyMMddHHmmss')"

    # Exécuter le script pour créer la pull request
    & $newPRScript -RepositoryPath $RepositoryPath -BranchName $branchName -ModificationTypes $ModificationType -FileCount $FileCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes

    # Attendre un peu pour s'assurer que la PR est créée
    Start-Sleep -Seconds 2

    # Mesurer les performances
    $measureScript = Join-Path -Path $scriptPath -ChildPath "Measure-PRAnalysisPerformance.ps1"

    if (-not (Test-Path -Path $measureScript)) {
        Write-Error "Script Measure-PRAnalysisPerformance.ps1 non trouvé: $measureScript"
        return $null
    }

    $reportPath = & $measureScript -RepositoryPath $RepositoryPath

    # Créer un objet de résultat de test
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

# Fonction pour générer un rapport global
function New-GlobalTestReport {
    param (
        [array]$TestResults
    )

    Write-Host "`nGénération du rapport global..." -ForegroundColor Cyan

    # Créer le dossier de rapports s'il n'existe pas
    $reportsPath = Join-Path -Path $scriptPath -ChildPath "reports"
    if (-not (Test-Path -Path $reportsPath)) {
        New-Item -ItemType Directory -Path $reportsPath -Force | Out-Null
    }

    # Définir le chemin du rapport global
    $globalReportPath = Join-Path -Path $reportsPath -ChildPath "PR-TestSuite-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"

    # Générer le contenu du rapport
    $reportContent = @"
# Rapport de la suite de tests d'analyse des pull requests

## Résumé

- **Date d'exécution**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Nombre de tests exécutés**: $($TestResults.Count)
- **Dépôt de test**: $RepositoryPath

## Tests exécutés

| Test | Type de modification | Fichiers | Erreurs | Types d'erreurs | Branche |
|------|---------------------|----------|---------|-----------------|---------|
$(
    $TestResults | ForEach-Object {
        "| $($_.TestName) | $($_.ModificationType) | $($_.FileCount) | $($_.ErrorCount) | $($_.ErrorTypes) | $($_.BranchName) |"
    }
)

## Rapports détaillés

$(
    $TestResults | ForEach-Object {
        "- [$($_.TestName)]($($_.ReportPath))"
    }
)

## Recommandations

- Exécuter régulièrement cette suite de tests pour surveiller les performances du système d'analyse
- Ajouter de nouveaux tests pour couvrir des scénarios spécifiques
- Automatiser l'exécution de cette suite dans le pipeline CI/CD

## Prochaines étapes

1. Analyser les résultats pour identifier les opportunités d'optimisation
2. Implémenter les améliorations suggérées dans les rapports individuels
3. Mettre à jour la suite de tests avec de nouveaux scénarios

Ce rapport a été généré automatiquement par Start-PRTestSuite.ps1.
"@

    # Écrire le rapport dans le fichier
    Set-Content -Path $globalReportPath -Value $reportContent -Encoding UTF8

    Write-Host "Rapport global généré: $globalReportPath" -ForegroundColor Green

    return $globalReportPath
}

# Fonction principale
function Start-PRTestSuite {
    $testResults = @()

    # Créer le dépôt de test si demandé
    if ($CreateRepository) {
        $repoResult = Initialize-TestRepository
        if (-not $repoResult) {
            return
        }
    }

    # Définir les tests à exécuter
    $tests = @()

    if ($RunAllTests) {
        # Tests avec différents types de modifications
        $tests += [PSCustomObject]@{ Name = "Ajout de fichiers"; ModificationType = "Add"; FileCount = 5; ErrorCount = 3; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Modification de fichiers"; ModificationType = "Modify"; FileCount = 5; ErrorCount = 3; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Suppression de fichiers"; ModificationType = "Delete"; FileCount = 3; ErrorCount = 0; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Modifications mixtes"; ModificationType = "Mixed"; FileCount = 8; ErrorCount = 3; ErrorTypes = "All" }

        # Tests avec différents nombres de fichiers
        $tests += [PSCustomObject]@{ Name = "Petit volume"; ModificationType = "Mixed"; FileCount = 3; ErrorCount = 2; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Volume moyen"; ModificationType = "Mixed"; FileCount = 10; ErrorCount = 2; ErrorTypes = "All" }
        $tests += [PSCustomObject]@{ Name = "Grand volume"; ModificationType = "Mixed"; FileCount = 20; ErrorCount = 2; ErrorTypes = "All" }

        # Tests avec différents types d'erreurs
        $tests += [PSCustomObject]@{ Name = "Erreurs de syntaxe"; ModificationType = "Mixed"; FileCount = 5; ErrorCount = 3; ErrorTypes = "Syntax" }
        $tests += [PSCustomObject]@{ Name = "Erreurs de style"; ModificationType = "Mixed"; FileCount = 5; ErrorCount = 3; ErrorTypes = "Style" }
        $tests += [PSCustomObject]@{ Name = "Erreurs de performance"; ModificationType = "Mixed"; FileCount = 5; ErrorCount = 3; ErrorTypes = "Performance" }
        $tests += [PSCustomObject]@{ Name = "Erreurs de sécurité"; ModificationType = "Mixed"; FileCount = 5; ErrorCount = 3; ErrorTypes = "Security" }
    } else {
        # Tests minimaux
        $tests += [PSCustomObject]@{ Name = "Test minimal"; ModificationType = "Mixed"; FileCount = 3; ErrorCount = 2; ErrorTypes = "All" }
    }

    # Exécuter les tests
    foreach ($test in $tests) {
        $result = Invoke-PRTest -TestName $test.Name -ModificationType $test.ModificationType -FileCount $test.FileCount -ErrorCount $test.ErrorCount -ErrorTypes $test.ErrorTypes

        if ($null -ne $result) {
            $testResults += $result
        }
    }

    # Générer le rapport global si demandé
    if ($GenerateReport -and $testResults.Count -gt 0) {
        $globalReportPath = New-GlobalTestReport -TestResults $testResults

        Write-Host "`nSuite de tests terminée. Rapport global: $globalReportPath" -ForegroundColor Green
    } else {
        Write-Host "`nSuite de tests terminée." -ForegroundColor Green
    }
}

# Exporter la fonction principale
Export-ModuleMember -Function Start-PRTestSuite

# Si le script est exécuté directement (pas importé comme module)
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # Exécuter la fonction principale
    Start-PRTestSuite
}
