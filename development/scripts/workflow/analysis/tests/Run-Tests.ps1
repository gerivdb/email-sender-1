# Script pour exécuter les tests unitaires du module WorkflowAnalyzer
# Ce script exécute les tests unitaires et génère un rapport de couverture

#Requires -Version 5.1
#Requires -Modules Pester

# Paramètres
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateCoverageReport,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "TestResults"
)

# Définir le chemin complet du dossier de sortie
$OutputFolder = Join-Path -Path $PSScriptRoot -ChildPath $OutputFolder

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Fonction pour afficher un message
function Write-TestMessage {
    param (
        [string]$Message,
        [string]$Status = "INFO"
    )

    $color = switch ($Status) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }

    Write-Host "[$Status] $Message" -ForegroundColor $color
}

# Vérifier si Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-TestMessage "Le module Pester n'est pas installé. Installation en cours..." -Status "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputFolder -ChildPath "TestResults.xml"

# Configurer la couverture de code si demandé
if ($GenerateCoverageReport) {
    $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "WorkflowAnalyzer.psm1"
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = $modulePath
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputFolder -ChildPath "CodeCoverage.xml"
}

# Exécuter les tests
Write-TestMessage "Exécution des tests unitaires..." -Status "INFO"
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher les résultats
if ($testResults.FailedCount -eq 0) {
    Write-TestMessage "Tous les tests ont réussi! ($($testResults.PassedCount) tests réussis)" -Status "SUCCESS"
} else {
    Write-TestMessage "$($testResults.FailedCount) tests ont échoué sur $($testResults.TotalCount) tests." -Status "ERROR"
}

# Générer un rapport HTML si demandé
if ($GenerateCoverageReport) {
    Write-TestMessage "Génération du rapport de couverture..." -Status "INFO"

    # Vérifier si ReportGenerator est installé
    if (-not (Get-Command -Name ReportGenerator -ErrorAction SilentlyContinue)) {
        Write-TestMessage "ReportGenerator n'est pas installé. Installation en cours..." -Status "WARNING"
        dotnet tool install -g dotnet-reportgenerator-globaltool
    }

    # Générer le rapport HTML
    $coverageXmlPath = Join-Path -Path $OutputFolder -ChildPath "CodeCoverage.xml"
    $coverageHtmlPath = Join-Path -Path $OutputFolder -ChildPath "CoverageReport"

    if (Test-Path -Path $coverageXmlPath) {
        ReportGenerator "-reports:$coverageXmlPath" "-targetdir:$coverageHtmlPath" "-reporttypes:Html"

        if (Test-Path -Path $coverageHtmlPath) {
            Write-TestMessage "Rapport de couverture généré dans: $coverageHtmlPath" -Status "SUCCESS"

            # Ouvrir le rapport dans le navigateur par défaut
            Start-Process (Join-Path -Path $coverageHtmlPath -ChildPath "index.htm")
        } else {
            Write-TestMessage "Échec de la génération du rapport de couverture" -Status "ERROR"
        }
    } else {
        Write-TestMessage "Fichier de couverture XML non trouvé" -Status "ERROR"
    }
}

# Afficher le chemin du rapport de test
Write-TestMessage "Rapport de test généré dans: $($pesterConfig.TestResult.OutputPath)" -Status "INFO"
