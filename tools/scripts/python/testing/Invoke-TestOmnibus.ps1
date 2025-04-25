#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute TestOmnibus pour l'analyse rapide des tests Python.
.DESCRIPTION
    Ce script est un wrapper PowerShell pour l'outil TestOmnibus Python.
    Il permet d'exécuter les tests Python, d'analyser les erreurs et de générer des rapports.
.PARAMETER TestDirectory
    Le répertoire contenant les tests Python.
.PARAMETER Pattern
    Le pattern des fichiers de test à exécuter.
.PARAMETER Jobs
    Le nombre de processus parallèles à utiliser.
.PARAMETER Verbose
    Active le mode verbeux.
.PARAMETER Pdb
    Lance le débogueur Python en cas d'échec.
.PARAMETER GenerateReport
    Génère un rapport HTML des résultats.
.PARAMETER ReportDirectory
    Le répertoire où stocker les rapports.
.PARAMETER Analyze
    Analyse les erreurs pour détecter des patterns.
.PARAMETER SaveErrors
    Sauvegarde les erreurs dans la base de données.
.PARAMETER ErrorDatabase
    Chemin de la base de données d'erreurs.
.PARAMETER UseTestmon
    Utilise pytest-testmon pour exécuter uniquement les tests affectés.
.PARAMETER GenerateCoverage
    Génère un rapport de couverture.
.PARAMETER CoverageFormat
    Format du rapport de couverture (html, xml, term).
.PARAMETER TracebackFormat
    Format des tracebacks (auto, short, long, native).
.PARAMETER InstallDependencies
    Installe automatiquement les dépendances nécessaires.
.EXAMPLE
    .\Invoke-TestOmnibus.ps1 -TestDirectory "tests/python" -GenerateReport
.EXAMPLE
    .\Invoke-TestOmnibus.ps1 -TestDirectory "tests/python" -GenerateReport -Analyze -SaveErrors
.EXAMPLE
    .\Invoke-TestOmnibus.ps1 -TestDirectory "tests/python" -UseTestmon -GenerateCoverage
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestDirectory = "tests/python",

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

# Fonction pour vérifier si un module Python est installé
function Test-PythonModule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    $result = python -c "import sys, pkgutil; print(1 if pkgutil.find_loader('$ModuleName') else 0)" 2>$null
    return $result -eq "1"
}

# Vérifier que Python est installé
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python n'est pas installé ou n'est pas dans le PATH."
    return 1
}

# Installer les dépendances si nécessaire
if ($InstallDependencies) {
    Write-Host "Vérification des dépendances..." -ForegroundColor Cyan

    $modules = @(
        @{Name = "pytest"; Description = "Framework de test Python"},
        @{Name = "pytest-cov"; Description = "Plugin de couverture de code pour pytest"},
        @{Name = "pytest-xdist"; Description = "Plugin pour exécuter les tests en parallèle"}
    )

    if ($UseTestmon) {
        $modules += @{Name = "pytest-testmon"; Description = "Plugin pour exécuter uniquement les tests affectés"}
    }

    foreach ($module in $modules) {
        if (-not (Test-PythonModule -ModuleName $module.Name)) {
            Write-Host "Installation de $($module.Name) ($($module.Description))..." -ForegroundColor Yellow
            python -m pip install $module.Name

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Impossible d'installer $($module.Name). Certaines fonctionnalités pourraient ne pas fonctionner."
            }
        } else {
            Write-Host "$($module.Name) est déjà installé." -ForegroundColor Green
        }
    }
}

# Vérifier que pytest est installé
if (-not (Test-PythonModule -ModuleName "pytest")) {
    Write-Warning "pytest n'est pas installé. Installation recommandée: python -m pip install pytest pytest-cov pytest-xdist"

    if (-not $InstallDependencies) {
        $installNow = Read-Host "Voulez-vous installer les dépendances maintenant? (O/N)"
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
    Write-Error "Le script run_testomnibus.py n'a pas été trouvé dans $PSScriptRoot."
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

# Exécuter la commande
Write-Host "Exécution de TestOmnibus..." -ForegroundColor Cyan
Write-Host "Commande: $cmd" -ForegroundColor DarkGray
Invoke-Expression $cmd

# Vérifier le code de retour
if ($LASTEXITCODE -eq 0) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
} else {
    Write-Host "Des tests ont échoué. Consultez le rapport pour plus de détails." -ForegroundColor Red
}

# Ouvrir le rapport HTML si généré et demandé
if ($GenerateReport -and $OpenReport) {
    $reportFiles = Get-ChildItem -Path $ReportDirectory -Filter "testomnibus_report_*.html" | Sort-Object LastWriteTime -Descending

    if ($reportFiles.Count -gt 0) {
        $latestReport = $reportFiles[0].FullName
        Write-Host "Ouverture du rapport HTML le plus récent: $latestReport" -ForegroundColor Yellow
        Start-Process $latestReport
    } else {
        Write-Warning "Aucun rapport HTML n'a été trouvé dans $ReportDirectory."
    }
}

# Ouvrir le rapport Allure si généré et demandé
if ($GenerateAllureReport -and $OpenAllureReport) {
    $allureReportDir = Join-Path -Path (Split-Path -Parent $AllureDirectory) -ChildPath "allure-report"

    if (Test-Path -Path $allureReportDir) {
        Write-Host "Ouverture du rapport Allure: $allureReportDir" -ForegroundColor Yellow

        # Vérifier si allure est installé
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
            # Ouvrir le répertoire du rapport
            Start-Process $allureReportDir
            Write-Warning "Allure n'est pas installé ou n'est pas dans le PATH. Le répertoire du rapport a été ouvert à la place."
            Write-Warning "Pour installer Allure, consultez https://docs.qameta.io/allure/"
        }
    } else {
        Write-Warning "Aucun rapport Allure n'a été trouvé dans $allureReportDir."
    }
}

# Afficher des informations sur les rapports Jenkins si générés
if ($GenerateJenkinsReport) {
    $jenkinsFiles = Get-ChildItem -Path $JenkinsDirectory -Filter "*.xml" -ErrorAction SilentlyContinue

    if ($jenkinsFiles.Count -gt 0) {
        Write-Host "Rapports JUnit pour Jenkins générés dans ${JenkinsDirectory}:" -ForegroundColor Yellow
        foreach ($file in $jenkinsFiles) {
            Write-Host "  - $($file.Name)" -ForegroundColor Gray
        }
        Write-Host "Ces rapports peuvent être utilisés par Jenkins pour afficher les résultats des tests." -ForegroundColor Gray
    } else {
        Write-Warning "Aucun rapport JUnit n'a été trouvé dans $JenkinsDirectory."
    }
}

return $LASTEXITCODE
