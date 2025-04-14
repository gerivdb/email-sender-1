<#
.SYNOPSIS
    Teste le hook post-commit sur le dernier commit.
.DESCRIPTION
    Ce script teste le hook post-commit sur le dernier commit.
    Il simule l'exécution du hook post-commit sans effectuer de commit réel.
.PARAMETER JournalPath
    Chemin du journal de développement à mettre à jour.
.PARAMETER ReportPath
    Chemin du rapport d'analyse à générer.
.PARAMETER IncludeAllFiles
    Inclut tous les fichiers modifiés dans l'analyse, pas seulement les fichiers PowerShell.
.PARAMETER SkipJournalUpdate
    Ne met pas à jour le journal de développement.
.EXAMPLE
    .\Test-PostCommitHook.ps1
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$JournalPath,

    [Parameter()]
    [string]$ReportPath,

    [Parameter()]
    [switch]$IncludeAllFiles,

    [Parameter()]
    [switch]$SkipJournalUpdate,

    [Parameter()]
    [switch]$VerboseOutput
)

# Obtenir le chemin du dépôt Git
$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
    Write-Error "Ce script doit être exécuté dans un dépôt Git."
    exit 1
}

# Définir les chemins par défaut si non spécifiés
if (-not $JournalPath) {
    $JournalPath = Join-Path -Path $repoRoot -ChildPath "journal_de_bord_test.md"
}

if (-not $ReportPath) {
    $reportDir = Join-Path -Path $repoRoot -ChildPath "git-hooks\reports"
    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    $ReportPath = Join-Path -Path $reportDir -ChildPath "post-commit-test-report.md"
}

Write-Host "Test du hook post-commit sur le dernier commit..." -ForegroundColor Cyan

# Exécuter le script d'enrichissement
$scriptPath = Join-Path -Path $repoRoot -ChildPath "git-hooks\Enrich-DevelopmentLog.ps1"

$params = @(
    "-JournalPath", $JournalPath,
    "-ReportPath", $ReportPath
)

if ($IncludeAllFiles) {
    $params += "-IncludeAllFiles"
}

if ($SkipJournalUpdate) {
    $params += "-SkipJournalUpdate"
}

if ($VerboseOutput) {
    $params += "-Verbose"
}

# Exécuter le script
$command = "& '$scriptPath' $($params -join ' ')"
Write-Host "Exécution de la commande: $command" -ForegroundColor Yellow
Invoke-Expression $command

$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "`nTest réussi. Le hook post-commit a été exécuté avec succès." -ForegroundColor Green
} else {
    Write-Host "`nTest échoué. Le hook post-commit a rencontré une erreur." -ForegroundColor Red
}

# Afficher le rapport
if (Test-Path -Path $ReportPath) {
    Write-Host "`nRapport de test:" -ForegroundColor Cyan
    Get-Content -Path $ReportPath | ForEach-Object {
        Write-Host $_
    }
}

# Afficher le journal
if (-not $SkipJournalUpdate -and (Test-Path -Path $JournalPath)) {
    Write-Host "`nJournal de développement:" -ForegroundColor Cyan
    Get-Content -Path $JournalPath | ForEach-Object {
        Write-Host $_
    }
}
