<#
.SYNOPSIS
    Version amÃ©liorÃ©e de TestOmnibus avec analyse de tendances, dÃ©tection de tests flaky et optimisation avancÃ©e.
.DESCRIPTION
    Ce script exÃ©cute TestOmnibus avec des fonctionnalitÃ©s amÃ©liorÃ©es, comme l'analyse
    des tendances, la dÃ©tection des tests flaky, l'intÃ©gration avec SonarQube et
    l'optimisation avancÃ©e des tests.
.PARAMETER TestPath
    Chemin vers les tests Ã  exÃ©cuter.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats des tests.
.PARAMETER HistoryPath
    Chemin vers l'historique des exÃ©cutions prÃ©cÃ©dentes.
.PARAMETER DetectFlakyTests
    Active la dÃ©tection des tests flaky.
.PARAMETER AnalyzeTrends
    Active l'analyse des tendances.
.PARAMETER UseSonarQube
    Active l'intÃ©gration avec SonarQube.
.PARAMETER SonarQubeUrl
    L'URL du serveur SonarQube.
.PARAMETER SonarQubeToken
    Le token d'authentification SonarQube.
.PARAMETER SonarQubeProjectKey
    La clÃ© du projet SonarQube.
.PARAMETER UseAdvancedOptimization
    Active l'optimisation avancÃ©e des tests.
.EXAMPLE
    .\Invoke-EnhancedTestOmnibus.ps1 -TestPath "D:\Tests" -DetectFlakyTests -AnalyzeTrends
.EXAMPLE
    .\Invoke-EnhancedTestOmnibus.ps1 -TestPath "D:\Tests" -UseSonarQube -SonarQubeUrl "http://sonarqube.example.com" -SonarQubeToken "token" -SonarQubeProjectKey "testomnibus"
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results"),

    [Parameter(Mandatory = $false)]
    [string]$HistoryPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\History"),

    [Parameter(Mandatory = $false)]
    [switch]$DetectFlakyTests,

    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeTrends,

    [Parameter(Mandatory = $false)]
    [switch]$UseSonarQube,

    [Parameter(Mandatory = $false)]
    [string]$SonarQubeUrl,

    [Parameter(Mandatory = $false)]
    [string]$SonarQubeToken,

    [Parameter(Mandatory = $false)]
    [string]$SonarQubeProjectKey,

    [Parameter(Mandatory = $false)]
    [switch]$UseAdvancedOptimization
)

# VÃ©rifier les chemins
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# CrÃ©er les rÃ©pertoires s'ils n'existent pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $HistoryPath)) {
    New-Item -Path $HistoryPath -ItemType Directory -Force | Out-Null
}

# VÃ©rifier les paramÃ¨tres SonarQube
if ($UseSonarQube) {
    if (-not $SonarQubeUrl -or -not $SonarQubeToken -or -not $SonarQubeProjectKey) {
        Write-Error "Pour utiliser SonarQube, vous devez spÃ©cifier SonarQubeUrl, SonarQubeToken et SonarQubeProjectKey."
        return 1
    }
}

# Fonction pour exÃ©cuter TestOmnibus
function Invoke-TestOmnibusWithConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )

    try {
        # Chemin vers TestOmnibus
        $testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

        if (-not (Test-Path -Path $testOmnibusPath)) {
            Write-Error "TestOmnibus n'existe pas: $testOmnibusPath"
            return $null
        }

        # ExÃ©cuter TestOmnibus
        Write-Host "ExÃ©cution de TestOmnibus..." -ForegroundColor Cyan

        $testOmnibusParams = @{
            Path = $TestPath
        }

        if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
            $testOmnibusParams.Add("ConfigPath", $ConfigPath)
        }

        # ExÃ©cuter TestOmnibus et capturer le code de sortie
        & $testOmnibusPath @testOmnibusParams
        $exitCode = $LASTEXITCODE

        # VÃ©rifier si l'exÃ©cution a rÃ©ussi
        if ($exitCode -ne 0) {
            throw "TestOmnibus a retournÃ© un code d'erreur: $exitCode"
        }

        # VÃ©rifier si des rÃ©sultats ont Ã©tÃ© gÃ©nÃ©rÃ©s
        $resultsPath = Join-Path -Path $OutputPath -ChildPath "results.xml"
        if (-not (Test-Path -Path $resultsPath)) {
            Write-Error "Aucun rÃ©sultat n'a Ã©tÃ© gÃ©nÃ©rÃ© par TestOmnibus."
            return $null
        }

        return $resultsPath
    } catch {
        Write-Error "Erreur lors de l'exÃ©cution de TestOmnibus: $_"
        return $null
    }
}

# Fonction pour sauvegarder les rÃ©sultats dans l'historique
function Save-ResultsToHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResultsPath,

        [Parameter(Mandatory = $true)]
        [string]$HistoryPath
    )

    try {
        # CrÃ©er un nom de fichier unique
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $historyFile = Join-Path -Path $HistoryPath -ChildPath "results_$timestamp.xml"

        # Copier les rÃ©sultats
        Copy-Item -Path $ResultsPath -Destination $historyFile -Force

        return $historyFile
    } catch {
        Write-Error "Erreur lors de la sauvegarde des rÃ©sultats dans l'historique: $_"
        return $null
    }
}

# Initialiser la gestion des erreurs
$errorHandlingPath = Join-Path -Path $PSScriptRoot -ChildPath "Initialize-ErrorHandling.ps1"
if (Test-Path -Path $errorHandlingPath) {
    . $errorHandlingPath
} else {
    Write-Warning "Le script de gestion des erreurs n'a pas Ã©tÃ© trouvÃ©: $errorHandlingPath"
}

# Point d'entrÃ©e principal
try {
    # Utiliser l'optimisation avancÃ©e si demandÃ©
    $configPath = $null

    if ($UseAdvancedOptimization) {
        Write-Host "Utilisation de l'optimisation avancÃ©e..." -ForegroundColor Cyan
        $optimizerPath = Join-Path -Path $PSScriptRoot -ChildPath "Optimizers\Advanced-Optimizer.ps1"

        if (Test-Path -Path $optimizerPath) {
            $optimizationResult = & $optimizerPath -TestPath $TestPath -HistoryPath $HistoryPath -OutputPath $OutputPath

            if ($optimizationResult -and $optimizationResult.ConfigPath) {
                $configPath = $optimizationResult.ConfigPath
                Write-Host "Configuration optimisÃ©e gÃ©nÃ©rÃ©e: $configPath" -ForegroundColor Green
                Write-Host "Nombre de threads: $($optimizationResult.ThreadCount)" -ForegroundColor Green
                Write-Host "Nombre de tests: $($optimizationResult.TestCount)" -ForegroundColor Green
            } else {
                Write-Warning "L'optimisation avancÃ©e a Ã©chouÃ©. Utilisation de la configuration par dÃ©faut."
            }
        } else {
            Write-Warning "Le script d'optimisation avancÃ©e n'existe pas: $optimizerPath"
        }
    }

    # DÃ©tecter les tests flaky si demandÃ©
    if ($DetectFlakyTests) {
        Write-Host "DÃ©tection des tests flaky..." -ForegroundColor Cyan
        $flakyTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "Manage-FlakyTests.ps1"

        if (Test-Path -Path $flakyTestsPath) {
            $flakyTestsResult = & $flakyTestsPath -TestPath $TestPath -OutputPath $OutputPath -Iterations 3 -GenerateReport -FixMode Retry -MaxRetries 3

            if ($flakyTestsResult -and $flakyTestsResult.FlakyTests) {
                Write-Host "Tests flaky dÃ©tectÃ©s: $($flakyTestsResult.FlakyTests.Count)" -ForegroundColor Yellow

                if ($flakyTestsResult.ReportPath) {
                    Write-Host "Rapport des tests flaky gÃ©nÃ©rÃ©: $($flakyTestsResult.ReportPath)" -ForegroundColor Green
                }

                if ($flakyTestsResult.ConfigPath) {
                    Write-Host "Configuration des tests flaky gÃ©nÃ©rÃ©e: $($flakyTestsResult.ConfigPath)" -ForegroundColor Green
                }
            } else {
                Write-Host "Aucun test flaky dÃ©tectÃ©." -ForegroundColor Green
            }
        } else {
            Write-Warning "Le script de dÃ©tection des tests flaky n'existe pas: $flakyTestsPath"
        }
    } else {
        # ExÃ©cuter TestOmnibus normalement
        $resultsPath = Invoke-TestOmnibusWithConfig -TestPath $TestPath -ConfigPath $configPath

        if ($resultsPath) {
            Write-Host "Tests exÃ©cutÃ©s avec succÃ¨s. RÃ©sultats enregistrÃ©s: $resultsPath" -ForegroundColor Green

            # Sauvegarder les rÃ©sultats dans l'historique
            $historyFile = Save-ResultsToHistory -ResultsPath $resultsPath -HistoryPath $HistoryPath

            if ($historyFile) {
                Write-Host "RÃ©sultats sauvegardÃ©s dans l'historique: $historyFile" -ForegroundColor Green
            }
        }
    }

    # Analyser les tendances si demandÃ©
    if ($AnalyzeTrends) {
        Write-Host "Analyse des tendances..." -ForegroundColor Cyan
        $trendsPath = Join-Path -Path $PSScriptRoot -ChildPath "Analyzers\Analyze-TestTrends.ps1"

        if (Test-Path -Path $trendsPath) {
            $trendsResult = & $trendsPath -HistoryPath $HistoryPath -OutputPath $OutputPath -DaysToAnalyze 30 -GenerateReport

            if ($trendsResult -and $trendsResult.ReportPath) {
                Write-Host "Rapport des tendances gÃ©nÃ©rÃ©: $($trendsResult.ReportPath)" -ForegroundColor Green

                if ($trendsResult.FlakyTests) {
                    Write-Host "Tests instables dÃ©tectÃ©s par l'analyse des tendances: $($trendsResult.FlakyTests.Count)" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Warning "Le script d'analyse des tendances n'existe pas: $trendsPath"
        }
    }

    # IntÃ©grer avec SonarQube si demandÃ©
    if ($UseSonarQube) {
        Write-Host "IntÃ©gration avec SonarQube..." -ForegroundColor Cyan
        $sonarQubePath = Join-Path -Path $PSScriptRoot -ChildPath "Integrate-SonarQube.ps1"

        if (Test-Path -Path $sonarQubePath) {
            $sonarQubeResult = & $sonarQubePath -TestPath $TestPath -SourcePath (Split-Path -Path $TestPath -Parent) -SonarQubeUrl $SonarQubeUrl -SonarQubeToken $SonarQubeToken -ProjectKey $SonarQubeProjectKey -ProjectName $SonarQubeProjectKey -SimulationMode

            if ($sonarQubeResult -eq 0) {
                Write-Host "IntÃ©gration avec SonarQube rÃ©ussie." -ForegroundColor Green
            } else {
                Write-Warning "L'intÃ©gration avec SonarQube a Ã©chouÃ©."
            }
        } else {
            Write-Warning "Le script d'intÃ©gration avec SonarQube n'existe pas: $sonarQubePath"
        }
    }

    return 0
} catch {
    # Utiliser le gestionnaire d'erreurs si disponible
    if (Get-Command -Name "Handle-TestOmnibusError" -ErrorAction SilentlyContinue) {
        Handle-TestOmnibusError -ErrorRecord $_ -TestName "EnhancedTestOmnibus" -AddToReport
    } else {
        Write-Error "Erreur lors de l'exÃ©cution de TestOmnibus amÃ©liorÃ©: $_"
    }
    return 1
}
