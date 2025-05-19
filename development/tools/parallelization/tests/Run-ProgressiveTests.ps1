<#
.SYNOPSIS
    Exécute les tests progressifs pour le module UnifiedParallel.

.DESCRIPTION
    Ce script exécute les tests progressifs (P1 à P4) pour le module UnifiedParallel,
    en utilisant l'approche progressive définie dans le module ProgressiveTestFramework.

    Les tests sont organisés en 4 phases:
    - Phase 1 (P1): Tests basiques pour les fonctionnalités essentielles
    - Phase 2 (P2): Tests de robustesse avec valeurs limites et cas particuliers
    - Phase 3 (P3): Tests d'exceptions pour la gestion des erreurs
    - Phase 4 (P4): Tests avancés pour les scénarios complexes

.PARAMETER Phase
    Phase de test à exécuter. Valeurs possibles: P1, P2, P3, P4, All.
    Par défaut: All (toutes les phases).

.PARAMETER TestName
    Nom spécifique du test à exécuter. Si non spécifié, tous les tests sont exécutés.

.PARAMETER CodeCoverage
    Indique si la couverture de code doit être mesurée.
    Par défaut: $false.

.PARAMETER GenerateReport
    Indique si un rapport de couverture de code doit être généré.
    Par défaut: $false.

.PARAMETER ReportPath
    Chemin vers le répertoire où les rapports de couverture seront générés.
    Par défaut: le répertoire "reports" dans le même répertoire que ce script.

.PARAMETER Parallel
    Indique si les tests doivent être exécutés en parallèle.
    Par défaut: $false.

.PARAMETER SkipPerformanceTests
    Indique si les tests de performance doivent être ignorés.
    Par défaut: $false.

.EXAMPLE
    .\Run-ProgressiveTests.ps1 -Phase P1

    Exécute les tests de phase 1 (tests basiques) pour le module UnifiedParallel.

.EXAMPLE
    .\Run-ProgressiveTests.ps1 -Phase All -CodeCoverage -GenerateReport

    Exécute tous les tests pour le module UnifiedParallel, mesure la couverture de code
    et génère un rapport de couverture.

.NOTES
    Version:        1.0.0
    Auteur:         UnifiedParallel Team
    Date création:  2023-05-20
    Mise à jour:    2025-05-26
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('P1', 'P2', 'P3', 'P4', 'All')]
    [string]$Phase = 'All',

    [Parameter(Mandatory = $false)]
    [string]$TestName = "",

    [Parameter(Mandatory = $false)]
    [switch]$CodeCoverage,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath,

    [Parameter(Mandatory = $false)]
    [switch]$Parallel,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPerformanceTests
)

# Déterminer les chemins par défaut
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testsPath = Join-Path -Path $scriptPath -ChildPath "Pester"
$modulePath = Split-Path -Parent $scriptPath
if (-not $ReportPath) {
    $ReportPath = Join-Path -Path $scriptPath -ChildPath "reports"
}

# Créer le répertoire de rapports s'il n'existe pas
if ($GenerateReport -and -not (Test-Path -Path $ReportPath)) {
    New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null
}

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Vérifier que le module UnifiedParallel existe
$modulePsm1Path = Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1"
if (-not (Test-Path -Path $modulePsm1Path)) {
    throw "Le module UnifiedParallel n'a pas été trouvé à l'emplacement $modulePsm1Path."
}

# Importer le module ProgressiveTestFramework
$frameworkPath = Join-Path -Path $scriptPath -ChildPath "ProgressiveTestFramework.psm1"
if (-not (Test-Path -Path $frameworkPath)) {
    throw "Le module ProgressiveTestFramework n'a pas été trouvé à l'emplacement $frameworkPath."
}
Import-Module $frameworkPath -Force

# Importer le module UnifiedParallel
Import-Module $modulePsm1Path -Force

# Définir le chemin des tests
$testFiles = Get-ChildItem -Path $testsPath -Filter "*.Progressive.Tests.ps1" -Recurse

# Filtrer les tests par nom si spécifié
if ($TestName) {
    $testFiles = $testFiles | Where-Object { $_.BaseName -like "*$TestName*" }
}

# Vérifier qu'il y a des tests à exécuter
if (-not $testFiles -or $testFiles.Count -eq 0) {
    Write-Host "Aucun test progressif trouvé." -ForegroundColor Red
    return
}

# Afficher les informations sur l'exécution des tests
Write-Host "Exécution des tests progressifs pour le module UnifiedParallel" -ForegroundColor Cyan
Write-Host "  Phase: $Phase" -ForegroundColor White
Write-Host "  Nom du test: $(if ($TestName -eq '') { 'Tous' } else { $TestName })" -ForegroundColor White
Write-Host "  Chemin des tests: $testsPath" -ForegroundColor White
Write-Host "  Chemin du module: $modulePath" -ForegroundColor White
Write-Host "  Couverture de code: $CodeCoverage" -ForegroundColor White
Write-Host "  Génération de rapport: $GenerateReport" -ForegroundColor White
if ($GenerateReport) {
    Write-Host "  Chemin des rapports: $ReportPath" -ForegroundColor White
}
Write-Host "  Exécution en parallèle: $Parallel" -ForegroundColor White
Write-Host "  Ignorer les tests de performance: $SkipPerformanceTests" -ForegroundColor White

# Filtrer les tests de performance si demandé
if ($SkipPerformanceTests) {
    $testFiles = $testFiles | Where-Object { $_.Name -notmatch "Performance|Benchmark" }
    Write-Host "Tests de performance ignorés. Nombre de fichiers de test restants: $($testFiles.Count)" -ForegroundColor Yellow
}

# Créer un répertoire temporaire pour les fichiers de couverture
$coveragePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "UnifiedParallelCoverage_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if ($CodeCoverage) {
    New-Item -Path $coveragePath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire temporaire pour les fichiers de couverture: $coveragePath" -ForegroundColor White
}

# Exécuter les tests
$outputFile = if ($GenerateReport) { Join-Path -Path $ReportPath -ChildPath "TestResults_$Phase.xml" } else { $null }

# Exécuter les tests en parallèle ou en séquence
if ($Parallel -and $testFiles.Count -gt 1) {
    Write-Host "Exécution des tests en parallèle..." -ForegroundColor Cyan

    # Créer un runspace pool
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, [Environment]::ProcessorCount, $sessionState, $Host)
    $runspacePool.Open()

    # Créer les runspaces pour chaque fichier de test
    $runspaces = @()
    foreach ($testFile in $testFiles) {
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool

        # Ajouter le script à exécuter
        [void]$powershell.AddScript({
                param($TestFile, $Phase, $FrameworkPath, $ModulePsm1Path, $CodeCoverage, $CoveragePath)

                # Importer les modules nécessaires
                Import-Module $FrameworkPath -Force
                Import-Module $ModulePsm1Path -Force

                # Exécuter les tests
                $testPath = $TestFile.FullName
                $testName = $TestFile.Name
                Write-Host "Exécution des tests dans $testName..." -ForegroundColor Cyan

                $params = @{
                    Path     = $testPath
                    Phase    = $Phase
                    PassThru = $true
                }

                if ($CodeCoverage) {
                    $params.CodeCoverage = $true
                    $params.CodeCoveragePath = $ModulePsm1Path
                }

                $results = Invoke-ProgressiveTest @params

                return [PSCustomObject]@{
                    TestFile = $testName
                    Results  = $results
                }
            })

        # Ajouter les paramètres
        [void]$powershell.AddParameter('TestFile', $testFile)
        [void]$powershell.AddParameter('Phase', $Phase)
        [void]$powershell.AddParameter('FrameworkPath', $frameworkPath)
        [void]$powershell.AddParameter('ModulePsm1Path', $modulePsm1Path)
        [void]$powershell.AddParameter('CodeCoverage', $CodeCoverage)
        [void]$powershell.AddParameter('CoveragePath', $coveragePath)

        # Démarrer le runspace
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
        $runspaces += [PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            TestFile   = $testFile.Name
        }
    }

    # Attendre que tous les runspaces soient terminés
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    $skippedTests = 0

    foreach ($runspace in $runspaces) {
        Write-Host "Attente des résultats pour $($runspace.TestFile)..." -ForegroundColor White
        $results = $runspace.PowerShell.EndInvoke($runspace.Handle)

        # Afficher les résultats
        $testResults = $results.Results
        Write-Host "Résultats pour $($results.TestFile):" -ForegroundColor Cyan
        Write-Host "  Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
        Write-Host "  Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
        Write-Host "  Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
        Write-Host "  Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow

        # Mettre à jour les compteurs
        $totalTests += $testResults.TotalCount
        $passedTests += $testResults.PassedCount
        $failedTests += $testResults.FailedCount
        $skippedTests += $testResults.SkippedCount

        # Nettoyer le runspace
        $runspace.PowerShell.Dispose()
    }

    # Fermer le runspace pool
    $runspacePool.Close()
    $runspacePool.Dispose()

    # Afficher le résumé
    Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
    Write-Host "  Tests exécutés: $totalTests" -ForegroundColor White
    Write-Host "  Tests réussis: $passedTests" -ForegroundColor Green
    Write-Host "  Tests échoués: $failedTests" -ForegroundColor Red
    Write-Host "  Tests ignorés: $skippedTests" -ForegroundColor Yellow
} else {
    # Exécution séquentielle
    Write-Host "Exécution des tests en séquence..." -ForegroundColor Cyan

    $params = @{
        Path     = $testFiles.FullName
        Phase    = $Phase
        PassThru = $true
    }

    if ($CodeCoverage) {
        $params.CodeCoverage = $true
        $params.CodeCoveragePath = $modulePath
    }

    if ($outputFile) {
        $params.OutputFile = $outputFile
    }

    $results = Invoke-ProgressiveTest @params

    # Afficher le résumé
    Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
    Write-Host "  Tests exécutés: $($results.TotalCount)" -ForegroundColor White
    Write-Host "  Tests réussis: $($results.PassedCount)" -ForegroundColor Green
    Write-Host "  Tests échoués: $($results.FailedCount)" -ForegroundColor Red
    Write-Host "  Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Durée totale: $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

    # Mettre à jour les compteurs pour la génération du rapport
    $totalTests = $results.TotalCount
    $passedTests = $results.PassedCount
    $failedTests = $results.FailedCount
    $skippedTests = $results.SkippedCount
}

# Générer le rapport de couverture si demandé
if ($CodeCoverage -and $GenerateReport) {
    Write-Host "`nGénération du rapport de couverture de code..." -ForegroundColor Cyan

    # Exécuter le script de génération de rapport
    $coverageReportScript = Join-Path -Path $scriptPath -ChildPath "Get-ProgressiveTestCoverage.ps1"
    if (Test-Path -Path $coverageReportScript) {
        & $coverageReportScript -CoveragePath $coveragePath -OutputPath $ReportPath -ModulePath $modulePath
    } else {
        Write-Host "Le script de génération de rapport de couverture n'a pas été trouvé à l'emplacement $coverageReportScript." -ForegroundColor Yellow
    }
}

# Afficher le chemin du rapport si généré
if ($GenerateReport -and $outputFile) {
    Write-Host "`nRapport de test généré: $outputFile" -ForegroundColor Green
}

# Nettoyer le répertoire temporaire de couverture
if ($CodeCoverage -and (Test-Path -Path $coveragePath)) {
    Remove-Item -Path $coveragePath -Recurse -Force
}

# Retourner le statut global
if ($failedTests -gt 0) {
    exit 1
} else {
    exit 0
}
