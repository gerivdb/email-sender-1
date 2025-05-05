#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃƒÂ©cute TestOmnibus pour l'analyse rapide des tests Python.
.DESCRIPTION
    Ce script est un wrapper PowerShell pour l'outil TestOmnibus Python.
    Il permet d'exÃƒÂ©cuter les tests Python, d'analyser les erreurs et de gÃƒÂ©nÃƒÂ©rer des rapports.
.PARAMETER TestDirectory
    Le rÃƒÂ©pertoire contenant les tests Python.
.PARAMETER Pattern
    Le pattern des fichiers de test ÃƒÂ  exÃƒÂ©cuter.
.PARAMETER Jobs
    Le nombre de processus parallÃƒÂ¨les ÃƒÂ  utiliser.
.PARAMETER Verbose
    Active le mode verbeux.
.PARAMETER Pdb
    Lance le dÃƒÂ©bogueur Python en cas d'ÃƒÂ©chec.
.PARAMETER GenerateReport
    GÃƒÂ©nÃƒÂ¨re un rapport HTML des rÃƒÂ©sultats.
.PARAMETER ReportDirectory
    Le rÃƒÂ©pertoire oÃƒÂ¹ stocker les rapports.
.PARAMETER Analyze
    Analyse les erreurs pour dÃƒÂ©tecter des patterns.
.PARAMETER SaveErrors
    Sauvegarde les erreurs dans la base de donnÃƒÂ©es.
.PARAMETER ErrorDatabase
    Chemin de la base de donnÃƒÂ©es d'erreurs.
.PARAMETER UseTestmon
    Utilise pytest-testmon pour exÃƒÂ©cuter uniquement les tests affectÃƒÂ©s.
.PARAMETER GenerateCoverage
    GÃƒÂ©nÃƒÂ¨re un rapport de couverture.
.PARAMETER CoverageFormat
    Format du rapport de couverture (html, xml, term).
.PARAMETER TracebackFormat
    Format des tracebacks (auto, short, long, native).
.PARAMETER InstallDependencies
    Installe automatiquement les dÃƒÂ©pendances nÃƒÂ©cessaires.
.EXAMPLE
    .\Invoke-TestOmnibus.ps1 -TestDirectory "development/testing/tests/python" -GenerateReport
.EXAMPLE
    .\Invoke-TestOmnibus.ps1 -TestDirectory "development/testing/tests/python" -GenerateReport -Analyze -SaveErrors
.EXAMPLE
    .\Invoke-TestOmnibus.ps1 -TestDirectory "development/testing/tests/python" -UseTestmon -GenerateCoverage
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestDirectory = "development/testing/tests/python",

    [Parameter()]
    [string]$Pattern = "test_*.py",

    [Parameter()]
    [int]$Jobs = 0,

    [Parameter()]
    [switch]$VerboseOutput,

    [Parameter()]
    [switch]$Pdb,

    [Parameter()]
    [switch]$GenerateReport,

    [Parameter()]
    [string]$ReportDirectory = "test_reports",

    [Parameter()]
    [switch]$Analyze,

    [Parameter()]
    [switch]$SaveErrors,

    [Parameter()]
    [string]$ErrorDatabase = "error_database.json",

    [Parameter()]
    [switch]$UseTestmon,

    [Parameter()]
    [switch]$GenerateCoverage,

    [Parameter()]
    [ValidateSet("html", "xml", "term")]
    [string]$CoverageFormat = "html",

    [Parameter()]
    [ValidateSet("auto", "short", "long", "native")]
    [string]$TracebackFormat = "auto",

    [Parameter()]
    [switch]$InstallDependencies,

    [Parameter()]
    [switch]$OpenReport,

    [Parameter()]
    [switch]$GenerateAllureReport,

    [Parameter()]
    [string]$AllureDirectory = "allure-results",

    [Parameter()]
    [switch]$GenerateJenkinsReport,

    [Parameter()]
    [string]$JenkinsDirectory = "jenkins-results",

    [Parameter()]
    [switch]$OpenAllureReport
)

# Fonction pour vÃƒÂ©rifier si un module Python est installÃƒÂ©
function Test-PythonModule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    $result = python -c "import sys, pkgutil; print(1 if pkgutil.find_loader('$ModuleName') else 0)" 2>$null
    return $result -eq "1"
}

# VÃƒÂ©rifier que Python est installÃƒÂ©
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python n'est pas installÃƒÂ© ou n'est pas dans le PATH."
    return 1
}

# Installer les dÃƒÂ©pendances si nÃƒÂ©cessaire
if ($InstallDependencies) {
    Write-Host "VÃƒÂ©rification des dÃƒÂ©pendances..." -ForegroundColor Cyan

    $modules = @(
        @{Name = "pytest"; Description = "Framework de test Python"},
        @{Name = "pytest-cov"; Description = "Plugin de couverture de code pour pytest"},
        @{Name = "pytest-xdist"; Description = "Plugin pour exÃƒÂ©cuter les tests en parallÃƒÂ¨le"}
    )

    if ($UseTestmon) {
        $modules += @{Name = "pytest-testmon"; Description = "Plugin pour exÃƒÂ©cuter uniquement les tests affectÃƒÂ©s"}
    }

    foreach ($module in $modules) {
        if (-not (Test-PythonModule -ModuleName $module.Name)) {
            Write-Host "Installation de $($module.Name) ($($module.Description))..." -ForegroundColor Yellow
            python -m pip install $module.Name

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Impossible d'installer $($module.Name). Certaines fonctionnalitÃƒÂ©s pourraient ne pas fonctionner."
            }
        } else {
            Write-Host "$($module.Name) est dÃƒÂ©jÃƒÂ  installÃƒÂ©." -ForegroundColor Green
        }
    }
}

# VÃƒÂ©rifier que pytest est installÃƒÂ©
if (-not (Test-PythonModule -ModuleName "pytest")) {
    Write-Warning "pytest n'est pas installÃƒÂ©. Installation recommandÃƒÂ©e: python -m pip install pytest pytest-cov pytest-xdist"

    if (-not $InstallDependencies) {
        $installNow = Read-Host "Voulez-vous installer les dÃƒÂ©pendances maintenant? (O/N)"
        if ($installNow -eq "O" -or $installNow -eq "o") {
            python -m pip install pytest pytest-cov pytest-xdist

            if ($UseTestmon) {
                python -m pip install pytest-testmon
            }
        }
    }
}

# Construire la commande
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "run_testomnibus.py"

if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script run_testomnibus.py n'a pas ÃƒÂ©tÃƒÂ© trouvÃƒÂ© dans $PSScriptRoot."
    return 1
}

$cmd = "python `"$scriptPath`" -d `"$TestDirectory`" -p `"$Pattern`""

if ($Jobs -gt 0) {
    $cmd += " -j $Jobs"
}

if ($VerboseOutput) {
    $cmd += " -v"
}

if ($Pdb) {
    $cmd += " --pdb"
}

if ($GenerateReport) {
    $cmd += " --report --report-dir `"$ReportDirectory`""
}

if ($Analyze) {
    $cmd += " --analyze"
}

if ($SaveErrors) {
    $cmd += " --save-errors --error-db `"$ErrorDatabase`""
}

if ($UseTestmon) {
    $cmd += " --testmon"
}

if ($GenerateCoverage) {
    $cmd += " --cov --cov-report $CoverageFormat"
}

$cmd += " --tb $TracebackFormat"

# Ajouter les options pour Allure
if ($GenerateAllureReport) {
    $cmd += " --allure --allure-dir `"$AllureDirectory`""
}

# Ajouter les options pour Jenkins
if ($GenerateJenkinsReport) {
    $cmd += " --jenkins --jenkins-dir `"$JenkinsDirectory`""
}

# ExÃƒÂ©cuter la commande
Write-Host "ExÃƒÂ©cution de TestOmnibus..." -ForegroundColor Cyan
Write-Host "Commande: $cmd" -ForegroundColor DarkGray
Invoke-Expression $cmd

# VÃƒÂ©rifier le code de retour
if ($LASTEXITCODE -eq 0) {
    Write-Host "Tous les tests ont rÃƒÂ©ussi!" -ForegroundColor Green
} else {
    Write-Host "Des tests ont ÃƒÂ©chouÃƒÂ©. Consultez le rapport pour plus de dÃƒÂ©tails." -ForegroundColor Red
}

# Ouvrir le rapport HTML si gÃƒÂ©nÃƒÂ©rÃƒÂ© et demandÃƒÂ©
if ($GenerateReport -and $OpenReport) {
    $reportFiles = Get-ChildItem -Path $ReportDirectory -Filter "testomnibus_report_*.html" | Sort-Object LastWriteTime -Descending

    if ($reportFiles.Count -gt 0) {
        $latestReport = $reportFiles[0].FullName
        Write-Host "Ouverture du rapport HTML le plus rÃƒÂ©cent: $latestReport" -ForegroundColor Yellow
        Start-Process $latestReport
    } else {
        Write-Warning "Aucun rapport HTML n'a ÃƒÂ©tÃƒÂ© trouvÃƒÂ© dans $ReportDirectory."
    }
}

# Ouvrir le rapport Allure si gÃƒÂ©nÃƒÂ©rÃƒÂ© et demandÃƒÂ©
if ($GenerateAllureReport -and $OpenAllureReport) {
    $allureReportDir = Join-Path -Path (Split-Path -Parent $AllureDirectory) -ChildPath "allure-report"

    if (Test-Path -Path $allureReportDir) {
        Write-Host "Ouverture du rapport Allure: $allureReportDir" -ForegroundColor Yellow

        # VÃƒÂ©rifier si allure est installÃƒÂ©
        $allureCheck = $null
        try {
            $allureCheck = Get-Command allure -ErrorAction SilentlyContinue
        } catch {
            # Ignorer l'erreur
        }

        if ($allureCheck) {
            # Ouvrir le rapport avec allure
            Start-Process -FilePath "allure" -ArgumentList "open", "`"$allureReportDir`""
        } else {
            # Ouvrir le rÃƒÂ©pertoire du rapport
            Start-Process $allureReportDir
            Write-Warning "Allure n'est pas installÃƒÂ© ou n'est pas dans le PATH. Le rÃƒÂ©pertoire du rapport a ÃƒÂ©tÃƒÂ© ouvert ÃƒÂ  la place."
            Write-Warning "Pour installer Allure, consultez https://docs.qameta.io/allure/"
        }
    } else {
        Write-Warning "Aucun rapport Allure n'a ÃƒÂ©tÃƒÂ© trouvÃƒÂ© dans $allureReportDir."
    }
}

# Afficher des informations sur les rapports Jenkins si gÃƒÂ©nÃƒÂ©rÃƒÂ©s
if ($GenerateJenkinsReport) {
    $jenkinsFiles = Get-ChildItem -Path $JenkinsDirectory -Filter "*.xml" -ErrorAction SilentlyContinue

    if ($jenkinsFiles.Count -gt 0) {
        Write-Host "Rapports JUnit pour Jenkins gÃƒÂ©nÃƒÂ©rÃƒÂ©s dans ${JenkinsDirectory}:" -ForegroundColor Yellow
        foreach ($file in $jenkinsFiles) {
            Write-Host "  - $($file.Name)" -ForegroundColor Gray
        }
        Write-Host "Ces rapports peuvent ÃƒÂªtre utilisÃƒÂ©s par Jenkins pour afficher les rÃƒÂ©sultats des tests." -ForegroundColor Gray
    } else {
        Write-Warning "Aucun rapport JUnit n'a ÃƒÂ©tÃƒÂ© trouvÃƒÂ© dans $JenkinsDirectory."
    }
}

return $LASTEXITCODE
