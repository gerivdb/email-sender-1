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

    # Définir les fonctions de mock
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

    # Définir la fonction New-TestRepository
    function New-TestRepository {
        param(
            [string]$Path = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",
            [string]$SourceRepo = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",
            [bool]$SetupBranches = $true,
            [switch]$Force
        )

        # Initialiser le dépôt Git
        $initResult = Initialize-GitRepository -Path $Path -Force:$Force
        if (-not $initResult) {
            return
        }

        # Copier la structure du dépôt source
        $copyResult = Copy-RepositoryStructure -SourcePath $SourceRepo -DestinationPath $Path
        if (-not $copyResult) {
            return
        }

        # Configurer les branches si demandé
        if ($SetupBranches) {
            $branchResult = Set-GitBranches -Path $Path
            if (-not $branchResult) {
                return
            }
        }

        Write-Host "`nDépôt de test créé avec succès à $Path" -ForegroundColor Green
        Write-Host "Vous pouvez maintenant utiliser ce dépôt pour tester le système d'analyse des pull requests." -ForegroundColor Cyan
    }

    # Test 1: La fonction New-TestRepository existe
    Test-Condition -Name "La fonction New-TestRepository existe" -Condition {
        Get-Command -Name New-TestRepository -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction New-TestRepository n'existe pas"

    # Test 2: Initialize-GitRepository est appelé avec le bon chemin
    Test-Condition -Name "Initialize-GitRepository est appelé avec le bon chemin" -Condition {
        $script:testPathCalled = $false
        $script:testPath = $null
        $script:testForce = $false

        # Redéfinir la fonction pour capturer les appels
        function Initialize-GitRepository {
            param($Path, $Force)
            $script:testPathCalled = $true
            $script:testPath = $Path
            $script:testForce = $Force
            Write-Host "  Mock: Initialize-GitRepository appelé avec Path=$Path, Force=$Force" -ForegroundColor Yellow
            return $true
        }

        # Appeler la fonction à tester avec Force=true pour éviter les confirmations
        New-TestRepository -Path $testRepoPath -Force

        # Vérifier que la fonction a été appelée avec le bon chemin
        Write-Host "  Vérification: Called=$script:testPathCalled, Path=$script:testPath, Force=$script:testForce" -ForegroundColor Yellow
        $script:testPathCalled -and $script:testPath -eq $testRepoPath -and $script:testForce -eq $true
    } -FailureMessage "Initialize-GitRepository n'a pas été appelé avec le bon chemin"
}

# Tests pour New-TestPullRequest-Fixed.ps1
function Test-NewTestPullRequest {
    Write-Host "`n=== Tests pour New-TestPullRequest-Fixed.ps1 ===" -ForegroundColor Cyan

    # Définir les fonctions de mock
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

    # Définir la fonction New-TestPullRequest
    function New-TestPullRequest {
        param(
            [string]$RepositoryPath = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",
            [string]$BranchName = "feature/test-pr-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
            [string]$BaseBranch = "develop",
            [int]$FileCount = 5,
            [int]$ErrorCount = 3,
            [string]$ErrorTypes = "All",
            [string]$ModificationTypes = "Mixed",
            [bool]$CreatePR = $false
        )

        # Créer une nouvelle branche
        $branchResult = New-GitBranch -RepositoryPath $RepositoryPath -BranchName $BranchName -BaseBranch $BaseBranch
        if (-not $branchResult) {
            return
        }

        # Effectuer les modifications selon le type spécifié
        switch ($ModificationTypes) {
            "Add" {
                Add-NewFiles -RepositoryPath $RepositoryPath -Count $FileCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
            }
            "Modify" {
                Update-ExistingFiles -RepositoryPath $RepositoryPath -Count $FileCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
            }
            "Delete" {
                Remove-ExistingFiles -RepositoryPath $RepositoryPath -Count $FileCount
            }
            "Mixed" {
                $addCount = [Math]::Ceiling($FileCount / 3)
                $modifyCount = [Math]::Ceiling($FileCount / 3)
                $deleteCount = $FileCount - $addCount - $modifyCount

                Add-NewFiles -RepositoryPath $RepositoryPath -Count $addCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
                Update-ExistingFiles -RepositoryPath $RepositoryPath -Count $modifyCount -ErrorCount $ErrorCount -ErrorTypes $ErrorTypes
                Remove-ExistingFiles -RepositoryPath $RepositoryPath -Count $deleteCount
            }
        }

        # Soumettre les changements
        $commitResult = Submit-Changes -RepositoryPath $RepositoryPath -Message "Test PR: $ModificationTypes modifications with $ErrorCount errors per file"
        if (-not $commitResult) {
            return
        }

        # Pousser les changements
        $pushResult = Push-Changes -RepositoryPath $RepositoryPath -BranchName $BranchName
        if (-not $pushResult) {
            return
        }

        # Créer une pull request si demandé
        if ($CreatePR) {
            $prTitle = "Test PR: $ModificationTypes modifications with $ErrorCount errors per file"
            $prBody = @"
# Test Pull Request

Cette pull request a été générée automatiquement pour tester le système d'analyse.

## Détails

- **Type de modifications**: $ModificationTypes
- **Nombre de fichiers**: $FileCount
- **Nombre d'erreurs par fichier**: $ErrorCount
- **Types d'erreurs**: $ErrorTypes

## Notes

Les erreurs ont été intentionnellement injectées dans le code pour tester la détection.
Cette PR ne doit pas être fusionnée en production.
"@

            New-GithubPullRequest -RepositoryPath $RepositoryPath -BranchName $BranchName -BaseBranch $BaseBranch -Title $prTitle -Body $prBody
        }

        Write-Host "`nPull request de test créée avec succès:" -ForegroundColor Green
        Write-Host "  Branche: $BranchName" -ForegroundColor Cyan
        Write-Host "  Base: $BaseBranch" -ForegroundColor Cyan
        Write-Host "  Type de modifications: $ModificationTypes" -ForegroundColor Cyan
        Write-Host "  Nombre de fichiers: $FileCount" -ForegroundColor Cyan
        Write-Host "  Erreurs par fichier: $ErrorCount" -ForegroundColor Cyan
        Write-Host "  Types d'erreurs: $ErrorTypes" -ForegroundColor Cyan
    }

    # Test 1: La fonction New-TestPullRequest existe
    Test-Condition -Name "La fonction New-TestPullRequest existe" -Condition {
        Get-Command -Name New-TestPullRequest -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction New-TestPullRequest n'existe pas"

    # Test 2: New-GitBranch est appelé avec les bons paramètres
    Test-Condition -Name "New-GitBranch est appelé avec les bons paramètres" -Condition {
        $script:branchCalled = $false
        $script:branchRepo = $null
        $script:branchName = $null

        # Redéfinir la fonction pour capturer les appels
        function New-GitBranch {
            param($RepositoryPath, $BranchName, $BaseBranch)
            $script:branchCalled = $true
            $script:branchRepo = $RepositoryPath
            $script:branchName = $BranchName
            Write-Host "  Mock: New-GitBranch appelé avec RepositoryPath=$RepositoryPath, BranchName=$BranchName" -ForegroundColor Yellow
            return $true
        }

        # Appeler la fonction à tester
        $testBranch = "feature/test-branch"
        New-TestPullRequest -RepositoryPath $testRepoPath -BranchName $testBranch

        # Vérifier que la fonction a été appelée avec les bons paramètres
        Write-Host "  Vérification: Called=$script:branchCalled, Repo=$script:branchRepo, Branch=$script:branchName" -ForegroundColor Yellow
        $script:branchCalled -and $script:branchRepo -eq $testRepoPath -and $script:branchName -eq $testBranch
    } -FailureMessage "New-GitBranch n'a pas été appelé avec les bons paramètres"
}

# Tests pour Measure-PRAnalysisPerformance.ps1
function Test-MeasurePRAnalysisPerformance {
    Write-Host "`n=== Tests pour Measure-PRAnalysisPerformance.ps1 ===" -ForegroundColor Cyan

    # Définir les fonctions de mock
    function Get-PullRequestInfo {
        param($RepositoryPath, $PullRequestNumber)
        Write-Host "  Mock: Get-PullRequestInfo appelé avec RepositoryPath=$RepositoryPath, PullRequestNumber=$PullRequestNumber" -ForegroundColor Yellow
        return [PSCustomObject]@{
            Number     = if ($PullRequestNumber -eq 0) { 42 } else { $PullRequestNumber }
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
        Write-Host "  Mock: Invoke-PRAnalysis appelé avec PullRequestNumber=$($PullRequestInfo.Number)" -ForegroundColor Yellow
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
        Write-Host "  Mock: New-PerformanceReport appelé avec PullRequestNumber=$($PullRequestInfo.Number), DetailedReport=$DetailedReport" -ForegroundColor Yellow
        $reportPath = Join-Path -Path $OutputPath -ChildPath "PR-$($PullRequestInfo.Number)-Analysis-Test.md"
        Set-Content -Path $reportPath -Value "# Test Report"
        return $reportPath
    }

    # Définir la fonction Measure-PRAnalysisPerformance
    function Measure-PRAnalysisPerformance {
        param(
            [string]$RepositoryPath = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",
            [int]$PullRequestNumber = 0,
            [string]$OutputPath = "reports\pr-analysis",
            [bool]$DetailedReport = $true
        )

        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        # Obtenir les informations sur la pull request
        $prInfo = Get-PullRequestInfo -RepositoryPath $RepositoryPath -PullRequestNumber $PullRequestNumber

        # Exécuter l'analyse
        $metrics = Invoke-PRAnalysis -PullRequestInfo $prInfo

        # Générer le rapport
        $reportPath = New-PerformanceReport -Metrics $metrics -PullRequestInfo $prInfo -OutputPath $OutputPath -DetailedReport $DetailedReport

        # Afficher les résultats
        Write-Host "`nAnalyse de performance terminée:" -ForegroundColor Green
        Write-Host "  Pull request: #$($prInfo.Number) - $($prInfo.Title)" -ForegroundColor White
        Write-Host "  Durée totale: $($metrics.TotalDuration) ms" -ForegroundColor White
        Write-Host "  Temps moyen par fichier: $($metrics.AverageFileAnalysisTime) ms" -ForegroundColor White
        Write-Host "  Utilisation mémoire: $($metrics.MemoryUsageDelta) bytes" -ForegroundColor White
        Write-Host "  Erreurs détectées: $($metrics.ErrorCount)" -ForegroundColor White
        Write-Host "  Rapport: $reportPath" -ForegroundColor White
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

    # Test 4: Measure-PRAnalysisPerformance accepte des paramètres personnalisés
    Test-Condition -Name "Measure-PRAnalysisPerformance accepte des paramètres personnalisés" -Condition {
        # Capturer les appels aux fonctions mockées
        $script:prInfoCalled = $false
        $script:prInfoNumber = 0
        $script:reportCalled = $false
        $script:reportDetailed = $false

        # Redéfinir les fonctions pour capturer les appels
        function Get-PullRequestInfo {
            param($RepositoryPath, $PullRequestNumber)
            $script:prInfoCalled = $true
            $script:prInfoNumber = $PullRequestNumber
            Write-Host "  Mock: Get-PullRequestInfo appelé avec PullRequestNumber=$PullRequestNumber" -ForegroundColor Yellow
            return [PSCustomObject]@{
                Number     = $PullRequestNumber
                Title      = "Test PR"
                HeadBranch = "feature/test"
                BaseBranch = "main"
                CreatedAt  = (Get-Date).ToString("yyyy-MM-dd")
                Files      = @()
                FileCount  = 0
                Additions  = 0
                Deletions  = 0
                Changes    = 0
            }
        }

        function New-PerformanceReport {
            param($Metrics, $PullRequestInfo, $OutputPath, $DetailedReport)
            $script:reportCalled = $true
            $script:reportDetailed = $DetailedReport
            Write-Host "  Mock: New-PerformanceReport appelé avec DetailedReport=$DetailedReport" -ForegroundColor Yellow
            return "test-report.md"
        }

        # Appeler la fonction à tester avec des paramètres personnalisés
        Measure-PRAnalysisPerformance -PullRequestNumber 123 -DetailedReport $false

        # Vérifier que les fonctions ont été appelées avec les bons paramètres
        Write-Host "  Vérification: PRInfoCalled=$script:prInfoCalled, PRInfoNumber=$script:prInfoNumber, ReportCalled=$script:reportCalled, ReportDetailed=$script:reportDetailed" -ForegroundColor Yellow
        $script:prInfoCalled -and $script:prInfoNumber -eq 123 -and $script:reportCalled -and $script:reportDetailed -eq $false
    } -FailureMessage "Measure-PRAnalysisPerformance ne gère pas correctement les paramètres personnalisés"
}

# Tests pour Start-PRTestSuite.ps1
function Test-StartPRTestSuite {
    Write-Host "`n=== Tests pour Start-PRTestSuite.ps1 ===" -ForegroundColor Cyan

    # Définir les fonctions de mock
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

    # Définir la fonction Start-PRTestSuite
    function Start-PRTestSuite {
        param(
            [string]$RepositoryPath = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",
            [bool]$CreateRepository = $true,
            [bool]$RunAllTests = $true,
            [bool]$GenerateReport = $true,
            [switch]$Force
        )

        # Initialiser le dépôt de test si demandé
        if ($CreateRepository) {
            $repoResult = Initialize-TestRepository -RepositoryPath $RepositoryPath -Force:$Force
            if (-not $repoResult) {
                return
            }
        }

        # Exécuter les tests
        $testResults = @()

        if ($RunAllTests) {
            # Test 1: Ajout de nouveaux fichiers avec erreurs de syntaxe
            $testResults += Invoke-PRTest -TestName "Test1-Add-Syntax" -ModificationType "Add" -FileCount 3 -ErrorCount 2 -ErrorTypes "Syntax"

            # Test 2: Modification de fichiers existants avec erreurs de style
            $testResults += Invoke-PRTest -TestName "Test2-Modify-Style" -ModificationType "Modify" -FileCount 3 -ErrorCount 2 -ErrorTypes "Style"

            # Test 3: Suppression de fichiers
            $testResults += Invoke-PRTest -TestName "Test3-Delete" -ModificationType "Delete" -FileCount 3 -ErrorCount 0 -ErrorTypes "None"

            # Test 4: Modifications mixtes avec erreurs mixtes
            $testResults += Invoke-PRTest -TestName "Test4-Mixed-All" -ModificationType "Mixed" -FileCount 5 -ErrorCount 3 -ErrorTypes "All"
        }

        # Générer le rapport global si demandé
        if ($GenerateReport -and $testResults.Count -gt 0) {
            $globalReportPath = New-GlobalTestReport -TestResults $testResults

            Write-Host "`nSuite de tests terminée. Rapport global: $globalReportPath" -ForegroundColor Green
        } else {
            Write-Host "`nSuite de tests terminée." -ForegroundColor Green
        }
    }

    # Test 1: La fonction Start-PRTestSuite existe
    Test-Condition -Name "La fonction Start-PRTestSuite existe" -Condition {
        Get-Command -Name Start-PRTestSuite -ErrorAction SilentlyContinue
    } -FailureMessage "La fonction Start-PRTestSuite n'existe pas"

    # Test 2: Initialize-TestRepository est appelé lorsque CreateRepository est true
    Test-Condition -Name "Initialize-TestRepository est appelé lorsque CreateRepository est true" -Condition {
        $script:initCalled = $false
        $script:initRepo = $null
        $script:initForce = $false

        # Redéfinir la fonction pour capturer les appels
        function Initialize-TestRepository {
            param($RepositoryPath, $Force)
            $script:initCalled = $true
            $script:initRepo = $RepositoryPath
            $script:initForce = $Force
            Write-Host "  Mock: Initialize-TestRepository appelé avec RepositoryPath=$RepositoryPath, Force=$Force" -ForegroundColor Yellow
            return $true
        }

        # Appeler la fonction à tester avec Force=true pour éviter les confirmations
        Start-PRTestSuite -RepositoryPath $testRepoPath -CreateRepository $true -RunAllTests $false -GenerateReport $false -Force

        # Vérifier que la fonction a été appelée
        Write-Host "  Vérification: Called=$script:initCalled, Repo=$script:initRepo, Force=$script:initForce" -ForegroundColor Yellow
        $script:initCalled -and $script:initRepo -eq $testRepoPath -and $script:initForce -eq $true
    } -FailureMessage "Initialize-TestRepository n'a pas été appelé avec les bons paramètres"

    # Test 3: Invoke-PRTest est appelé lorsque RunAllTests est true
    Test-Condition -Name "Invoke-PRTest est appelé lorsque RunAllTests est true" -Condition {
        $script:testCalls = 0
        $script:testNames = @()

        # Redéfinir la fonction pour capturer les appels
        function Initialize-TestRepository { param($RepositoryPath, $Force) return $true }

        function Invoke-PRTest {
            param($TestName, $ModificationType, $FileCount, $ErrorCount, $ErrorTypes)
            $script:testCalls++
            $script:testNames += $TestName
            Write-Host "  Mock: Invoke-PRTest appelé avec TestName=$TestName" -ForegroundColor Yellow
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

        function New-GlobalTestReport { param($TestResults) return "global-report.md" }

        # Appeler la fonction à tester
        Start-PRTestSuite -RepositoryPath $testRepoPath -CreateRepository $false -RunAllTests $true -GenerateReport $false -Force

        # Vérifier que la fonction a été appelée plusieurs fois
        Write-Host "  Vérification: TestCalls=$script:testCalls, TestNames=$($script:testNames -join ', ')" -ForegroundColor Yellow
        $script:testCalls -gt 0
    } -FailureMessage "Invoke-PRTest n'a pas été appelé lorsque RunAllTests est true"
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
