#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires pour le projet MCP.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour le projet MCP, y compris les tests pour MCPManager et MCPClient.
.EXAMPLE
    .\Run-AllTests.ps1
    Exécute tous les tests unitaires.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipPythonTests,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPowerShellTests,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

# Fonction principale
function Start-AllTests {
    [CmdletBinding()]
    param (
        [switch]$SkipPythonTests,
        [switch]$SkipPowerShellTests,
        [switch]$GenerateReport
    )

    try {
        # Vérifier si Pester est installé
        Write-Log "Vérification de l'installation de Pester..." -Level "INFO"
        $pesterInstalled = Get-Module -Name Pester -ListAvailable
        if (-not $pesterInstalled) {
            Write-Log "Pester n'est pas installé. Installation en cours..." -Level "WARNING"
            Install-Module -Name Pester -Force -SkipPublisherCheck
        }

        # Vérifier si pytest est installé (si les tests Python ne sont pas ignorés)
        if (-not $SkipPythonTests) {
            Write-Log "Vérification de l'installation de pytest..." -Level "INFO"
            $null = python -c "import pytest" 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Log "pytest n'est pas installé. Installation en cours..." -Level "WARNING"
                python -m pip install pytest pytest-cov pytest-html
            }
        }

        # Créer un dossier pour les rapports
        $reportsDir = Join-Path -Path $PSScriptRoot -ChildPath "..\reports"
        if (-not (Test-Path $reportsDir)) {
            New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
        }

        # Exécuter les tests PowerShell
        if (-not $SkipPowerShellTests) {
            Write-Log "Exécution des tests PowerShell..." -Level "INFO"

            # Trouver tous les fichiers de test PowerShell
            $testFiles = Get-ChildItem -Path $PSScriptRoot -Recurse -Filter "*.Tests*.ps1" | Where-Object {
                $_.Name -ne "Run-Tests.ps1" -and
                $_.Name -ne "Run-AllTests.ps1" -and
                $_.FullName -notlike "*\Run-Tests.ps1" -and
                $_.FullName -notlike "*\Run-AllTests.ps1"
            }

            Write-Log "Fichiers de test PowerShell trouvés: $($testFiles.Count)" -Level "INFO"
            foreach ($testFile in $testFiles) {
                Write-Log "Exécution du test: $($testFile.Name)" -Level "INFO"

                if ($GenerateReport) {
                    $reportPath = Join-Path -Path $reportsDir -ChildPath "$($testFile.BaseName).xml"
                    Invoke-Pester -Path $testFile.FullName -OutputFormat NUnitXml -OutputFile $reportPath
                } else {
                    Invoke-Pester -Path $testFile.FullName -Output Detailed
                }
            }
        }

        # Exécuter les tests Python
        if (-not $SkipPythonTests) {
            Write-Log "Exécution des tests Python..." -Level "INFO"

            # Trouver tous les fichiers de test Python
            $pythonTestFiles = Get-ChildItem -Path $PSScriptRoot -Recurse -Filter "test_*.py"

            Write-Log "Fichiers de test Python trouvés: $($pythonTestFiles.Count)" -Level "INFO"
            foreach ($testFile in $pythonTestFiles) {
                Write-Log "Exécution du test: $($testFile.Name)" -Level "INFO"

                if ($GenerateReport) {
                    $reportPath = Join-Path -Path $reportsDir -ChildPath "$($testFile.BaseName).html"
                    python -m pytest $testFile.FullName -v --html=$reportPath
                } else {
                    python -m pytest $testFile.FullName -v
                }
            }
        }

        Write-Log "Tous les tests ont été exécutés" -Level "SUCCESS"

        # Générer un rapport de couverture si demandé
        if ($GenerateReport) {
            Write-Log "Génération du rapport de couverture..." -Level "INFO"

            # Générer un rapport de couverture pour les tests PowerShell
            if (-not $SkipPowerShellTests) {
                $coverageReportPath = Join-Path -Path $reportsDir -ChildPath "coverage-powershell.xml"
                Invoke-Pester -Path $PSScriptRoot -CodeCoverage "$PSScriptRoot\..\modules\*.psm1" -OutputFormat NUnitXml -OutputFile $coverageReportPath
            }

            # Générer un rapport de couverture pour les tests Python
            if (-not $SkipPythonTests) {
                $coverageReportPath = Join-Path -Path $reportsDir -ChildPath "coverage-python.html"
                python -m pytest $PSScriptRoot --cov=mcp --cov-report=html:$coverageReportPath
            }

            Write-Log "Rapports de couverture générés dans le dossier: $reportsDir" -Level "SUCCESS"
        }
    } catch {
        Write-Log "Erreur lors de l'exécution des tests: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Start-AllTests -SkipPythonTests:$SkipPythonTests -SkipPowerShellTests:$SkipPowerShellTests -GenerateReport:$GenerateReport -Verbose
