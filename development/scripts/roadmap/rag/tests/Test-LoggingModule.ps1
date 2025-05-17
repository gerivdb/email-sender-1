#Requires -Version 5.1
<#
.SYNOPSIS
    Teste le module de journalisation.
.DESCRIPTION
    Ce script teste les fonctionnalités du module de journalisation.
.NOTES
    Nom: Test-LoggingModule.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-06-10
#>

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path -Path $scriptPath -ChildPath "..\modules"
$loggingModulePath = Join-Path -Path $modulesPath -ChildPath "Logging.psm1"

if (-not (Test-Path -Path $loggingModulePath)) {
    Write-Error "Le module de journalisation n'existe pas: $loggingModulePath"
    exit 1
}

Import-Module $loggingModulePath -Force

# Initialiser le système de journalisation avec un chemin de log spécifique pour les tests
$logPath = Join-Path -Path $env:TEMP -ChildPath "test-logging.log"
Initialize-Logging -LogPath $logPath -LogLevel "DEBUG" -EnableConsoleOutput $true -EnableFileOutput $true

Write-Host "Module de journalisation importé avec succès" -ForegroundColor Green
Write-Host "Chemin du fichier de log: $logPath" -ForegroundColor Green

# Tester les différents niveaux de log
Write-Log "Ceci est un message de débogage" -Level "DEBUG"
Write-Log "Ceci est un message d'information" -Level "INFO"
Write-Log "Ceci est un message d'avertissement" -Level "WARNING"
Write-Log "Ceci est un message d'erreur" -Level "ERROR"
Write-Log "Ceci est un message de succès" -Level "SUCCESS"

# Tester la rotation des logs
Write-Host "Test de la rotation des logs..." -ForegroundColor Yellow
Rotate-Logs

# Tester la récupération des logs récents
Write-Host "Test de la récupération des logs récents..." -ForegroundColor Yellow
$recentLogs = Get-RecentLogs -Count 10
Write-Host "Logs récents:" -ForegroundColor Yellow
$recentLogs | ForEach-Object { Write-Host $_ }

# Tester la récupération des logs filtrés par niveau
Write-Host "Test de la récupération des logs filtrés par niveau..." -ForegroundColor Yellow
$errorLogs = Get-RecentLogs -Level "ERROR"
Write-Host "Logs d'erreur:" -ForegroundColor Yellow
$errorLogs | ForEach-Object { Write-Host $_ }

# Tester la récupération des logs filtrés par motif
Write-Host "Test de la récupération des logs filtrés par motif..." -ForegroundColor Yellow
$patternLogs = Get-RecentLogs -Pattern "message"
Write-Host "Logs contenant 'message':" -ForegroundColor Yellow
$patternLogs | ForEach-Object { Write-Host $_ }

Write-Host "Tests terminés avec succès" -ForegroundColor Green
