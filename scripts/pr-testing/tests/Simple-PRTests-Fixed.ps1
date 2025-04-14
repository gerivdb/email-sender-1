#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiés pour les scripts de test de pull requests.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiés pour vérifier le bon fonctionnement
    des scripts de test de pull requests, sans utiliser Pester pour éviter les problèmes
    de récursion.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

# Définir les chemins des scripts à tester
$scriptPaths = @{
    "New-TestRepository"            = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "New-TestRepository.ps1"
    "New-TestPullRequest"           = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "New-TestPullRequest-Fixed.ps1"
    "Measure-PRAnalysisPerformance" = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Measure-PRAnalysisPerformance.ps1"
    "Start-PRTestSuite"             = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Start-PRTestSuite.ps1"
}

# Vérifier que les scripts existent
foreach ($scriptName in $scriptPaths.Keys) {
    $scriptPath = $scriptPaths[$scriptName]
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Warning "Script $scriptName non trouvé: $scriptPath"
    } else {
        Write-Host "Script $scriptName trouvé: $scriptPath" -ForegroundColor Green
    }
}

# Chemins temporaires pour les tests
$testRepoPath = Join-Path -Path $env:TEMP -ChildPath "PR-Analysis-TestRepo-$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "PR-Analysis-Reports-$(Get-Random)"

# Créer le dossier de sortie pour les tests
New-Item -ItemType Directory -Path $testOutputPath -Force | Out-Null

# Variables pour les statistiques
$totalTests = 0
$passedTests = 0
$failedTests = 0

# Fonction pour exécuter un test
function Test-Condition {
    param (
        [string]$Name,
        [scriptblock]$Condition,
        [string]$FailureMessage
    )

    $global:totalTests++
    Write-Host "`nTest: $Name" -ForegroundColor Yellow

    try {
        $result = & $Condition
        if ($result) {
            Write-Host "  Résultat: Réussi" -ForegroundColor Green
            $global:passedTests++
            return $true
        } else {
            Write-Host "  Résultat: Échoué" -ForegroundColor Red
            Write-Host "  $FailureMessage" -ForegroundColor Yellow
            $global:failedTests++
            return $false
        }
    } catch {
        Write-Host "  Résultat: Erreur" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Yellow
        $global:failedTests++
        return $false
    }
}

# Tests pour New-TestRepository.ps1
function Test-NewTestRepository {
    Write-Host "`n=== Tests pour New-TestRepository.ps1 ===" -ForegroundColor Cyan

    # Mock des fonctions
    function Initialize-GitRepository {
        param($Path, $Force)
        Write-Host "Mock: Initialize-GitRepository appelé avec Path=$Path, Force=$Force"
        return $true
    }

    function Copy-RepositoryStructure {
        param($SourcePath, $DestinationPath)
        Write-Host "Mock: Copy-RepositoryStructure appelé"
        return $true
    }

    function Set-GitBranches {
        param($Path)
        Write-Host "Mock: Set-GitBranches appelé"
        return $true
    }

    # Charger le script avec les fonctions mockées
    if (Test-Path -Path $scriptPaths["New-TestRepository"]) {
        # Créer un bloc de script temporaire pour éviter l'exécution automatique
        $scriptContent = Get-Content -Path $scriptPaths["New-TestRepository"] -Raw
        $scriptContent = $scriptContent -replace 'if \(\$MyInvocation\.InvocationName.*', ''
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        . $scriptBlock
    } else {
        Write-Warning "Script New-TestRepository.ps1 non trouvé"
        return
    }

    # Test 1: La fonction New-TestRepository existe
    Test-Condition -Name "La fonction New-TestRepository existe" -Condition {
        Get-Command -Name New-TestRepository -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction New-TestRepository n'existe pas"

    # Test 2: Initialize-GitRepository est appelé avec le bon chemin
    Test-Condition -Name "Initialize-GitRepository est appelé avec le bon chemin" -Condition {
        $called = $false
        $calledPath = $null
        $calledForce = $false

        # Redéfinir la fonction pour capturer les appels
        function Initialize-GitRepository {
            param($Path, $Force)
            $script:called = $true
            $script:calledPath = $Path
            $script:calledForce = $Force
            return $true
        }

        # Appeler la fonction à tester avec Force=true pour éviter les confirmations
        New-TestRepository -Path $testRepoPath -Force

        # Vérifier que la fonction a été appelée avec le bon chemin
        $called -and $calledPath -eq $testRepoPath -and $calledForce -eq $true
    } -FailureMessage "Initialize-GitRepository n'a pas été appelé avec le bon chemin"
}

# Tests pour New-TestPullRequest-Fixed.ps1
function Test-NewTestPullRequest {
    Write-Host "`n=== Tests pour New-TestPullRequest-Fixed.ps1 ===" -ForegroundColor Cyan

    # Mock des fonctions
    function New-GitBranch {
        param($RepositoryPath, $BranchName, $BaseBranch)
        Write-Host "Mock: New-GitBranch appelé"
        return $true
    }

    function New-PowerShellScriptWithErrors {
        param($Path, $ErrorCount, $ErrorTypes)
        Write-Host "Mock: New-PowerShellScriptWithErrors appelé"
    }

    function Add-NewFiles {
        param($RepositoryPath, $Count, $ErrorCount, $ErrorTypes)
        Write-Host "Mock: Add-NewFiles appelé"
    }

    function Update-ExistingFiles {
        param($RepositoryPath, $Count, $ErrorCount, $ErrorTypes)
        Write-Host "Mock: Update-ExistingFiles appelé"
    }

    function Remove-ExistingFiles {
        param($RepositoryPath, $Count)
        Write-Host "Mock: Remove-ExistingFiles appelé"
    }

    function Submit-Changes {
        param($RepositoryPath, $Message)
        Write-Host "Mock: Submit-Changes appelé"
        return $true
    }

    function Push-Changes {
        param($RepositoryPath, $BranchName)
        Write-Host "Mock: Push-Changes appelé"
        return $true
    }

    function New-GithubPullRequest {
        param($RepositoryPath, $BranchName, $BaseBranch, $Title, $Body)
        Write-Host "Mock: New-GithubPullRequest appelé"
        return $true
    }

    # Charger le script avec les fonctions mockées
    if (Test-Path -Path $scriptPaths["New-TestPullRequest"]) {
        # Créer un bloc de script temporaire pour éviter l'exécution automatique
        $scriptContent = Get-Content -Path $scriptPaths["New-TestPullRequest"] -Raw
        $scriptContent = $scriptContent -replace 'if \(\$MyInvocation\.InvocationName.*', ''
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        . $scriptBlock
    } else {
        Write-Warning "Script New-TestPullRequest-Fixed.ps1 non trouvé"
        return
    }

    # Test 1: La fonction New-TestPullRequest existe
    Test-Condition -Name "La fonction New-TestPullRequest existe" -Condition {
        Get-Command -Name New-TestPullRequest -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction New-TestPullRequest n'existe pas"

    # Test 2: New-GitBranch est appelé avec les bons paramètres
    Test-Condition -Name "New-GitBranch est appelé avec les bons paramètres" -Condition {
        $called = $false
        $calledRepo = $null
        $calledBranch = $null

        # Redéfinir la fonction pour capturer les appels
        function New-GitBranch {
            param($RepositoryPath, $BranchName, $BaseBranch)
            $script:called = $true
            $script:calledRepo = $RepositoryPath
            $script:calledBranch = $BranchName
            return $true
        }

        # Appeler la fonction à tester
        $testBranch = "feature/test-branch"
        New-TestPullRequest -RepositoryPath $testRepoPath -BranchName $testBranch

        # Vérifier que la fonction a été appelée avec les bons paramètres
        $called -and $calledRepo -eq $testRepoPath -and $calledBranch -eq $testBranch
    } -FailureMessage "New-GitBranch n'a pas été appelé avec les bons paramètres"
}

# Tests pour Measure-PRAnalysisPerformance.ps1
function Test-MeasurePRAnalysisPerformance {
    Write-Host "`n=== Tests pour Measure-PRAnalysisPerformance.ps1 ===" -ForegroundColor Cyan

    # Mock des fonctions
    function Get-PullRequestInfo {
        param($RepositoryPath, $PullRequestNumber)
        Write-Host "Mock: Get-PullRequestInfo appelé"
        return [PSCustomObject]@{
            Number     = 42
            Title      = "Test PR"
            HeadBranch = "feature/test"
            BaseBranch = "main"
            CreatedAt  = (Get-Date).ToString("yyyy-MM-dd")
            Files      = @(
                [PSCustomObject]@{
                    path      = "test1.ps1"
                    additions = 10
                    deletions = 5
                },
                [PSCustomObject]@{
                    path      = "test2.ps1"
                    additions = 20
                    deletions = 10
                }
            )
            FileCount  = 2
            Additions  = 30
            Deletions  = 15
            Changes    = 45
        }
    }

    function Invoke-PRAnalysis {
        param($PullRequestInfo)
        Write-Host "Mock: Invoke-PRAnalysis appelé"
        return [PSCustomObject]@{
            PullRequestNumber       = $PullRequestInfo.Number
            StartTime               = (Get-Date).AddMinutes(-5)
            EndTime                 = Get-Date
            TotalDuration           = 300000
            FileAnalysisDurations   = @(
                [PSCustomObject]@{
                    FilePath  = "test1.ps1"
                    Duration  = 150000
                    Additions = 10
                    Deletions = 5
                    Changes   = 15
                },
                [PSCustomObject]@{
                    FilePath  = "test2.ps1"
                    Duration  = 150000
                    Additions = 20
                    Deletions = 10
                    Changes   = 30
                }
            )
            ErrorsDetected          = @(
                [PSCustomObject]@{
                    FilePath   = "test1.ps1"
                    LineNumber = 10
                    ErrorType  = "Syntax"
                    Message    = "Test error"
                    Severity   = "Error"
                },
                [PSCustomObject]@{
                    FilePath   = "test2.ps1"
                    LineNumber = 20
                    ErrorType  = "Style"
                    Message    = "Test warning"
                    Severity   = "Warning"
                }
            )
            ErrorCount              = 2
            MemoryUsageBefore       = 100000000
            MemoryUsageAfter        = 150000000
            MemoryUsageDelta        = 50000000
            CPUUsage                = @(10, 20, 30)
            AverageFileAnalysisTime = 150000
            MaxFileAnalysisTime     = 150000
            MinFileAnalysisTime     = 150000
        }
    }

    function New-PerformanceReport {
        param($Metrics, $PullRequestInfo, $OutputPath, $DetailedReport)
        Write-Host "Mock: New-PerformanceReport appelé"
        $reportPath = Join-Path -Path $OutputPath -ChildPath "PR-$($PullRequestInfo.Number)-Analysis-Test.md"
        Set-Content -Path $reportPath -Value "# Test Report"
        return $reportPath
    }

    # Charger le script avec les fonctions mockées
    if (Test-Path -Path $scriptPaths["Measure-PRAnalysisPerformance"]) {
        # Créer un bloc de script temporaire pour éviter l'exécution automatique
        $scriptContent = Get-Content -Path $scriptPaths["Measure-PRAnalysisPerformance"] -Raw
        $scriptContent = $scriptContent -replace 'if \(\$MyInvocation\.InvocationName.*', ''
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        . $scriptBlock
    } else {
        Write-Warning "Script Measure-PRAnalysisPerformance.ps1 non trouvé"
        return
    }

    # Test 1: La fonction Measure-PRAnalysisPerformance existe
    Test-Condition -Name "La fonction Measure-PRAnalysisPerformance existe" -Condition {
        Get-Command -Name Measure-PRAnalysisPerformance -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction Measure-PRAnalysisPerformance n'existe pas"

    # Test 2: Get-PullRequestInfo retourne un objet valide
    Test-Condition -Name "Get-PullRequestInfo retourne un objet valide" -Condition {
        $result = Get-PullRequestInfo -RepositoryPath $testRepoPath -PullRequestNumber 42
        $result -and $result.Number -eq 42 -and $result.Files.Count -eq 2
    } -FailureMessage "Get-PullRequestInfo ne retourne pas un objet valide"

    # Test 3: New-PerformanceReport génère un rapport et retourne le chemin
    Test-Condition -Name "New-PerformanceReport génère un rapport et retourne le chemin" -Condition {
        $prInfo = Get-PullRequestInfo -RepositoryPath $testRepoPath -PullRequestNumber 42
        $metrics = Invoke-PRAnalysis -PullRequestInfo $prInfo
        $result = New-PerformanceReport -Metrics $metrics -PullRequestInfo $prInfo -OutputPath $testOutputPath -DetailedReport $true
        $result -and (Test-Path -Path $result)
    } -FailureMessage "New-PerformanceReport ne génère pas un rapport valide"
}

# Tests pour Start-PRTestSuite.ps1
function Test-StartPRTestSuite {
    Write-Host "`n=== Tests pour Start-PRTestSuite.ps1 ===" -ForegroundColor Cyan

    # Mock des fonctions
    function Initialize-TestRepository {
        param($RepositoryPath, $Force)
        Write-Host "Mock: Initialize-TestRepository appelé avec RepositoryPath=$RepositoryPath, Force=$Force"
        return $true
    }

    function Invoke-PRTest {
        param($TestName, $ModificationType, $FileCount, $ErrorCount, $ErrorTypes)
        Write-Host "Mock: Invoke-PRTest appelé avec TestName=$TestName"
        return [PSCustomObject]@{
            TestName         = $TestName
            ModificationType = $ModificationType
            FileCount        = $FileCount
            ErrorCount       = $ErrorCount
            ErrorTypes       = $ErrorTypes
            BranchName       = "test-branch"
            ReportPath       = "test-report.md"
            Timestamp        = Get-Date
        }
    }

    function New-GlobalTestReport {
        param($TestResults)
        Write-Host "Mock: New-GlobalTestReport appelé"
        return "global-report.md"
    }

    # Charger le script avec les fonctions mockées
    if (Test-Path -Path $scriptPaths["Start-PRTestSuite"]) {
        # Créer un bloc de script temporaire pour éviter l'exécution automatique
        $scriptContent = Get-Content -Path $scriptPaths["Start-PRTestSuite"] -Raw
        $scriptContent = $scriptContent -replace 'if \(\$MyInvocation\.InvocationName.*', ''
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        . $scriptBlock
    } else {
        Write-Warning "Script Start-PRTestSuite.ps1 non trouvé"
        return
    }

    # Test 1: La fonction Start-PRTestSuite existe
    Test-Condition -Name "La fonction Start-PRTestSuite existe" -Condition {
        Get-Command -Name Start-PRTestSuite -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction Start-PRTestSuite n'existe pas"

    # Test 2: Initialize-TestRepository est appelé lorsque CreateRepository est true
    Test-Condition -Name "Initialize-TestRepository est appelé lorsque CreateRepository est true" -Condition {
        $called = $false

        # Redéfinir la fonction pour capturer les appels
        function Initialize-TestRepository {
            param($RepositoryPath, $Force)
            $script:called = $true
            Write-Host "Mock: Initialize-TestRepository appelé avec Force=$Force"
            return $true
        }

        # Appeler la fonction à tester avec Force=true pour éviter les confirmations
        Start-PRTestSuite -RepositoryPath $testRepoPath -CreateRepository $true -RunAllTests $false -GenerateReport $false -Force

        # Vérifier que la fonction a été appelée
        $called
    } -FailureMessage "Initialize-TestRepository n'a pas été appelé"
}

# Exécuter tous les tests
function Invoke-AllTests {
    Write-Host "`n=== Exécution de tous les tests ===" -ForegroundColor Cyan

    # Exécuter les tests pour chaque script
    Test-NewTestRepository
    Test-NewTestPullRequest
    Test-MeasurePRAnalysisPerformance
    Test-StartPRTestSuite

    # Afficher le résumé
    Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
    Write-Host "Tests exécutés: $totalTests" -ForegroundColor White
    Write-Host "Tests réussis: $passedTests" -ForegroundColor Green
    Write-Host "Tests échoués: $failedTests" -ForegroundColor Red

    # Générer un rapport
    $reportPath = Join-Path -Path $testOutputPath -ChildPath "TestResults.txt"
    Set-Content -Path $reportPath -Value "Rapport des tests - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    Add-Content -Path $reportPath -Value "Tests exécutés: $totalTests"
    Add-Content -Path $reportPath -Value "Tests réussis: $passedTests"
    Add-Content -Path $reportPath -Value "Tests échoués: $failedTests"

    Write-Host "`nRapport généré: $reportPath" -ForegroundColor Green

    # Nettoyer les dossiers de test
    if (Test-Path -Path $testOutputPath) {
        Remove-Item -Path $testOutputPath -Recurse -Force
    }
}

# Exécuter tous les tests
Invoke-AllTests
