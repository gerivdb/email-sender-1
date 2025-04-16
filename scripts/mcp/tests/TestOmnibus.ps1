# Script TestOmnibus pour exécuter tous les tests unitaires des scripts MCP
# Ce script utilise Pester pour exécuter les tests unitaires

param (
    [Parameter(Mandatory = $false)]
    [switch]$InstallPester,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "TestResults",

    [Parameter(Mandatory = $false)]
    [string]$TestFilter = "*"
)

# Fonction pour vérifier si Pester est installé
function Test-PesterInstalled {
    $pesterModule = Get-Module -Name Pester -ListAvailable
    return ($null -ne $pesterModule)
}

# Fonction pour installer Pester
function Install-PesterModule {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
        Write-Host "Module Pester installé avec succès." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erreur lors de l'installation du module Pester: $_" -ForegroundColor Red
        return $false
    }
}

# Vérifier si Pester est installé
if (-not (Test-PesterInstalled)) {
    if ($InstallPester) {
        $success = Install-PesterModule
        if (-not $success) {
            Write-Host "Impossible d'installer Pester. Les tests ne peuvent pas être exécutés." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Le module Pester n'est pas installé. Utilisez le paramètre -InstallPester pour l'installer automatiquement." -ForegroundColor Yellow
        exit 1
    }
}

# Importer le module Pester
Import-Module Pester

# Créer le répertoire de rapport si nécessaire
if ($GenerateReport) {
    if (-not (Test-Path -Path $ReportPath -PathType Container)) {
        New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null
    }
}

# Exécuter les tests
Write-Host "Exécution des tests unitaires..." -ForegroundColor Cyan

# Paramètres pour Invoke-Pester
$pesterParams = @{
    Path     = $PSScriptRoot
    PassThru = $true
}

if ($GenerateReport) {
    $pesterParams.OutputFile = Join-Path -Path $ReportPath -ChildPath "TestResults.xml"
    $pesterParams.OutputFormat = "NUnitXml"
}

# Exécuter les tests
$results = Invoke-Pester @pesterParams

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Total des tests: $($results.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale: $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher les tests échoués
if ($results.FailedCount -gt 0) {
    Write-Host "`nTests échoués:" -ForegroundColor Red
    foreach ($failure in $results.Failed) {
        Write-Host "- $($failure.Name): $($failure.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
}

# Afficher le chemin du rapport si généré
if ($GenerateReport) {
    Write-Host "`nRapports générés dans: $ReportPath" -ForegroundColor Cyan
}

# Retourner un code de sortie basé sur les résultats des tests
exit $results.FailedCount
