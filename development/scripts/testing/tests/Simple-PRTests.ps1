#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour les scripts de test de pull requests.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour vÃ©rifier le bon fonctionnement
    des scripts de test de pull requests, sans utiliser Pester pour Ã©viter les problÃ¨mes
    de rÃ©cursion.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

# DÃ©finir les chemins des scripts Ã  tester
$scriptPaths = @{
    "New-TestRepository" = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "New-TestRepository.ps1"
    "New-TestPullRequest" = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "New-TestPullRequest-Fixed.ps1"
    "Measure-PRAnalysisPerformance" = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Measure-PRAnalysisPerformance.ps1"
    "Start-PRTestSuite" = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Start-PRTestSuite.ps1"
}

# VÃ©rifier que les scripts existent
foreach ($scriptName in $scriptPaths.Keys) {
    $scriptPath = $scriptPaths[$scriptName]
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Warning "Script $scriptName non trouvÃ©: $scriptPath"
    } else {
        Write-Host "Script $scriptName trouvÃ©: $scriptPath" -ForegroundColor Green
    }
}

# Chemins temporaires pour les tests
$testRepoPath = Join-Path -Path $env:TEMP -ChildPath "PR-Analysis-TestRepo-$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "PR-Analysis-Reports-$(Get-Random)"

# CrÃ©er le dossier de sortie pour les tests
New-Item -ItemType Directory -Path $testOutputPath -Force | Out-Null

# Variables pour les statistiques
$totalTests = 0
$passedTests = 0
$failedTests = 0

# Fonction pour exÃ©cuter un test
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
            Write-Host "  RÃ©sultat: RÃ©ussi" -ForegroundColor Green
            $global:passedTests++
            return $true
        } else {
            Write-Host "  RÃ©sultat: Ã‰chouÃ©" -ForegroundColor Red
            Write-Host "  $FailureMessage" -ForegroundColor Yellow
            $global:failedTests++
            return $false
        }
    } catch {
        Write-Host "  RÃ©sultat: Erreur" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Yellow
        $global:failedTests++
        return $false
    }
}

# Tests pour New-TestRepository.ps1
function Test-NewTestRepository {
    Write-Host "`n=== Tests pour New-TestRepository.ps1 ===" -ForegroundColor Cyan
    
    # Mock des fonctions
    function Initialize-GitRepository { param($Path) return $true }
    function Copy-RepositoryStructure { param($SourcePath, $DestinationPath) return $true }
    function Set-GitBranches { param($Path) return $true }
    
    # Charger le script avec les fonctions mockÃ©es
    . $scriptPaths["New-TestRepository"]
    
    # Test 1: La fonction New-TestRepository existe
    Test-Condition -Name "La fonction New-TestRepository existe" -Condition {
        Get-Command -Name New-TestRepository -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction New-TestRepository n'existe pas"
    
    # Test 2: Initialize-GitRepository est appelÃ© avec le bon chemin
    Test-Condition -Name "Initialize-GitRepository est appelÃ© avec le bon chemin" -Condition {
        $called = $false
        $calledPath = $null
        
        # RedÃ©finir la fonction pour capturer les appels
        function Initialize-GitRepository {
            param($Path)
            $script:called = $true
            $script:calledPath = $Path
            return $true
        }
        
        # Appeler la fonction Ã  tester
        New-TestRepository -Path $testRepoPath
        
        # VÃ©rifier que la fonction a Ã©tÃ© appelÃ©e avec le bon chemin
        $called -and $calledPath -eq $testRepoPath
    } -FailureMessage "Initialize-GitRepository n'a pas Ã©tÃ© appelÃ© avec le bon chemin"
}

# Tests pour New-TestPullRequest-Fixed.ps1
function Test-NewTestPullRequest {
    Write-Host "`n=== Tests pour New-TestPullRequest-Fixed.ps1 ===" -ForegroundColor Cyan
    
    # Mock des fonctions
    function New-GitBranch { param($RepositoryPath, $BranchName, $BaseBranch) return $true }
    function New-PowerShellScriptWithErrors { param($Path, $ErrorCount, $ErrorTypes) }
    function Add-NewFiles { param($RepositoryPath, $Count, $ErrorCount, $ErrorTypes) }
    function Update-ExistingFiles { param($RepositoryPath, $Count, $ErrorCount, $ErrorTypes) }
    function Remove-ExistingFiles { param($RepositoryPath, $Count) }
    function Submit-Changes { param($RepositoryPath, $Message) return $true }
    function Push-Changes { param($RepositoryPath, $BranchName) return $true }
    function New-GithubPullRequest { param($RepositoryPath, $BranchName, $BaseBranch, $Title, $Body) return $true }
    
    # Charger le script avec les fonctions mockÃ©es
    . $scriptPaths["New-TestPullRequest"]
    
    # Test 1: La fonction New-TestPullRequest existe
    Test-Condition -Name "La fonction New-TestPullRequest existe" -Condition {
        Get-Command -Name New-TestPullRequest -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction New-TestPullRequest n'existe pas"
    
    # Test 2: New-GitBranch est appelÃ© avec les bons paramÃ¨tres
    Test-Condition -Name "New-GitBranch est appelÃ© avec les bons paramÃ¨tres" -Condition {
        $called = $false
        $calledRepo = $null
        $calledBranch = $null
        
        # RedÃ©finir la fonction pour capturer les appels
        function New-GitBranch {
            param($RepositoryPath, $BranchName, $BaseBranch)
            $script:called = $true
            $script:calledRepo = $RepositoryPath
            $script:calledBranch = $BranchName
            return $true
        }
        
        # Appeler la fonction Ã  tester
        $testBranch = "feature/test-branch"
        New-TestPullRequest -RepositoryPath $testRepoPath -BranchName $testBranch
        
        # VÃ©rifier que la fonction a Ã©tÃ© appelÃ©e avec les bons paramÃ¨tres
        $called -and $calledRepo -eq $testRepoPath -and $calledBranch -eq $testBranch
    } -FailureMessage "New-GitBranch n'a pas Ã©tÃ© appelÃ© avec les bons paramÃ¨tres"
}

# Tests pour Measure-PRAnalysisPerformance.ps1
function Test-MeasurePRAnalysisPerformance {
    Write-Host "`n=== Tests pour Measure-PRAnalysisPerformance.ps1 ===" -ForegroundColor Cyan
    
    # Mock des fonctions
    function Get-PullRequestInfo { 
        param($RepositoryPath, $PullRequestNumber) 
        return [PSCustomObject]@{
            Number = 42
            Title = "Test PR"
            HeadBranch = "feature/test"
            BaseBranch = "main"
            CreatedAt = (Get-Date).ToString("yyyy-MM-dd")
            Files = @(
                [PSCustomObject]@{
                    path = "test1.ps1"
                    additions = 10
                    deletions = 5
                },
                [PSCustomObject]@{
                    path = "test2.ps1"
                    additions = 20
                    deletions = 10
                }
            )
            FileCount = 2
            Additions = 30
            Deletions = 15
            Changes = 45
        }
    }
    
    function Invoke-PRAnalysis { 
        param($PullRequestInfo) 
        return [PSCustomObject]@{
            PullRequestNumber = $PullRequestInfo.Number
            StartTime = (Get-Date).AddMinutes(-5)
            EndTime = Get-Date
            TotalDuration = 300000
            FileAnalysisDurations = @(
                [PSCustomObject]@{
                    FilePath = "test1.ps1"
                    Duration = 150000
                    Additions = 10
                    Deletions = 5
                    Changes = 15
                },
                [PSCustomObject]@{
                    FilePath = "test2.ps1"
                    Duration = 150000
                    Additions = 20
                    Deletions = 10
                    Changes = 30
                }
            )
            ErrorsDetected = @(
                [PSCustomObject]@{
                    FilePath = "test1.ps1"
                    LineNumber = 10
                    ErrorType = "Syntax"
                    Message = "Test error"
                    Severity = "Error"
                },
                [PSCustomObject]@{
                    FilePath = "test2.ps1"
                    LineNumber = 20
                    ErrorType = "Style"
                    Message = "Test warning"
                    Severity = "Warning"
                }
            )
            ErrorCount = 2
            MemoryUsageBefore = 100000000
            MemoryUsageAfter = 150000000
            MemoryUsageDelta = 50000000
            CPUUsage = @(10, 20, 30)
            AverageFileAnalysisTime = 150000
            MaxFileAnalysisTime = 150000
            MinFileAnalysisTime = 150000
        }
    }
    
    function New-PerformanceReport { 
        param($Metrics, $PullRequestInfo, $OutputPath, $DetailedReport) 
        $reportPath = Join-Path -Path $OutputPath -ChildPath "PR-$($PullRequestInfo.Number)-Analysis-Test.md"
        Set-Content -Path $reportPath -Value "# Test Report"
        return $reportPath
    }
    
    # Charger le script avec les fonctions mockÃ©es
    . $scriptPaths["Measure-PRAnalysisPerformance"]
    
    # Test 1: La fonction Measure-PRAnalysisPerformance existe
    Test-Condition -Name "La fonction Measure-PRAnalysisPerformance existe" -Condition {
        Get-Command -Name Measure-PRAnalysisPerformance -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction Measure-PRAnalysisPerformance n'existe pas"
    
    # Test 2: Get-PullRequestInfo retourne un objet valide
    Test-Condition -Name "Get-PullRequestInfo retourne un objet valide" -Condition {
        $result = Get-PullRequestInfo -RepositoryPath $testRepoPath -PullRequestNumber 42
        $result -and $result.Number -eq 42 -and $result.Files.Count -eq 2
    } -FailureMessage "Get-PullRequestInfo ne retourne pas un objet valide"
    
    # Test 3: New-PerformanceReport gÃ©nÃ¨re un rapport et retourne le chemin
    Test-Condition -Name "New-PerformanceReport gÃ©nÃ¨re un rapport et retourne le chemin" -Condition {
        $prInfo = Get-PullRequestInfo -RepositoryPath $testRepoPath -PullRequestNumber 42
        $metrics = Invoke-PRAnalysis -PullRequestInfo $prInfo
        $result = New-PerformanceReport -Metrics $metrics -PullRequestInfo $prInfo -OutputPath $testOutputPath -DetailedReport $true
        $result -and (Test-Path -Path $result)
    } -FailureMessage "New-PerformanceReport ne gÃ©nÃ¨re pas un rapport valide"
}

# Tests pour Start-PRTestSuite.ps1
function Test-StartPRTestSuite {
    Write-Host "`n=== Tests pour Start-PRTestSuite.ps1 ===" -ForegroundColor Cyan
    
    # Mock des fonctions
    function Initialize-TestRepository { return $true }
    function Invoke-PRTest { 
        param($TestName, $ModificationType, $FileCount, $ErrorCount, $ErrorTypes)
        return [PSCustomObject]@{
            TestName = $TestName
            ModificationType = $ModificationType
            FileCount = $FileCount
            ErrorCount = $ErrorCount
            ErrorTypes = $ErrorTypes
            BranchName = "test-branch"
            ReportPath = "test-report.md"
            Timestamp = Get-Date
        }
    }
    function New-GlobalTestReport { 
        param($TestResults)
        return "global-report.md"
    }
    
    # Charger le script avec les fonctions mockÃ©es
    . $scriptPaths["Start-PRTestSuite"]
    
    # Test 1: La fonction Start-PRTestSuite existe
    Test-Condition -Name "La fonction Start-PRTestSuite existe" -Condition {
        Get-Command -Name Start-PRTestSuite -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction Start-PRTestSuite n'existe pas"
    
    # Test 2: Initialize-TestRepository est appelÃ© lorsque CreateRepository est true
    Test-Condition -Name "Initialize-TestRepository est appelÃ© lorsque CreateRepository est true" -Condition {
        $called = $false
        
        # RedÃ©finir la fonction pour capturer les appels
        function Initialize-TestRepository {
            $script:called = $true
            return $true
        }
        
        # Appeler la fonction Ã  tester
        Start-PRTestSuite -RepositoryPath $testRepoPath -CreateRepository $true -RunAllTests $false -GenerateReport $false
        
        # VÃ©rifier que la fonction a Ã©tÃ© appelÃ©e
        $called
    } -FailureMessage "Initialize-TestRepository n'a pas Ã©tÃ© appelÃ©"
}

# ExÃ©cuter tous les tests
function Start-AllTests {
    Write-Host "`n=== ExÃ©cution de tous les tests ===" -ForegroundColor Cyan
    
    # ExÃ©cuter les tests pour chaque script
    Test-NewTestRepository
    Test-NewTestPullRequest
    Test-MeasurePRAnalysisPerformance
    Test-StartPRTestSuite
    
    # Afficher le rÃ©sumÃ©
    Write-Host "`n=== RÃ©sumÃ© des tests ===" -ForegroundColor Cyan
    Write-Host "Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor White
    Write-Host "Tests rÃ©ussis: $passedTests" -ForegroundColor Green
    Write-Host "Tests Ã©chouÃ©s: $failedTests" -ForegroundColor Red
    
    # GÃ©nÃ©rer un rapport
    $reportPath = Join-Path -Path $testOutputPath -ChildPath "TestResults.txt"
    Set-Content -Path $reportPath -Value "Rapport des tests - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    Add-Content -Path $reportPath -Value "Tests exÃ©cutÃ©s: $totalTests"
    Add-Content -Path $reportPath -Value "Tests rÃ©ussis: $passedTests"
    Add-Content -Path $reportPath -Value "Tests Ã©chouÃ©s: $failedTests"
    
    Write-Host "`nRapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green
    
    # Nettoyer les dossiers de test
    if (Test-Path -Path $testOutputPath) {
        Remove-Item -Path $testOutputPath -Recurse -Force
    }
}

# ExÃ©cuter tous les tests
Start-AllTests

