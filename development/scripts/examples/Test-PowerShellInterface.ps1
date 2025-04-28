# Script de test pour l'interface PowerShell du module PerformancePredictor
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PerformancePredictor.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "Module importÃ© avec succÃ¨s: $modulePath" -ForegroundColor Green
} else {
    Write-Error "Module not found: $modulePath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PowerShellInterfaceTest_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "RÃ©pertoire de test crÃ©Ã©: $testDir" -ForegroundColor Green

# Initialiser le module
Write-Host "Initialisation du module PerformancePredictor..." -ForegroundColor Cyan
$config = Initialize-PerformancePredictor -ConfigPath "$testDir\config.json" -LogPath "$testDir\logs.log" -ModelStoragePath "$testDir\models" -PredictionHorizon 6 -AnomalySensitivity "Medium" -RetrainingInterval 1
Write-Host "Module initialisÃ© avec succÃ¨s" -ForegroundColor Green
Write-Host "Configuration: $($config | ConvertTo-Json -Compress)" -ForegroundColor Green

# CrÃ©er des mÃ©triques de test
Write-Host "CrÃ©ation de mÃ©triques de test..." -ForegroundColor Cyan
$metrics = @()
$startTime = (Get-Date).AddDays(-1)

for ($i = 0; $i -lt 24; $i++) {
    $timestamp = $startTime.AddHours($i)
    $cpuUsage = 50.0

    $metrics += [PSCustomObject]@{
        Timestamp = $timestamp
        CPU       = [PSCustomObject]@{
            Usage = $cpuUsage
        }
    }
}
Write-Host "MÃ©triques crÃ©Ã©es: $($metrics.Count) points" -ForegroundColor Green

# Exporter les mÃ©triques au format JSON
Write-Host "Exportation des mÃ©triques au format JSON..." -ForegroundColor Cyan
$jsonPath = Join-Path -Path $testDir -ChildPath "metrics.json"

# Convertir les mÃ©triques au format JSON
$formattedMetrics = $metrics | ForEach-Object {
    @{
        Timestamp   = if ($_.Timestamp -is [DateTime]) { $_.Timestamp.ToString('o') } else { $_.Timestamp }
        "CPU.Usage" = $_.CPU.Usage
    }
}

# Exporter les mÃ©triques au format JSON
$formattedMetrics | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
Write-Host "MÃ©triques exportÃ©es vers: $jsonPath" -ForegroundColor Green

# Tester l'appel direct Ã  Python
$pythonScript = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveModel.py"
if (Test-Path -Path $pythonScript) {
    Write-Host "Test d'appel direct Ã  Python..." -ForegroundColor Cyan

    # EntraÃ®ner le modÃ¨le
    Write-Host "EntraÃ®nement du modÃ¨le..." -ForegroundColor Yellow
    $trainOutput = python $pythonScript --action train --input $jsonPath --config "$testDir\config.json" --force

    try {
        $trainResult = $trainOutput | ConvertFrom-Json
        if ($trainResult.'CPU.Usage'.status -eq "success") {
            Write-Host "  SUCCÃˆS: ModÃ¨le entraÃ®nÃ© avec succÃ¨s" -ForegroundColor Green
        } else {
            Write-Host "  Ã‰CHEC: Ã‰chec de l'entraÃ®nement du modÃ¨le" -ForegroundColor Red
            Write-Host "  Message: $($trainResult.'CPU.Usage'.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ERREUR: Impossible de convertir la sortie en JSON" -ForegroundColor Red
        Write-Host "  Sortie brute: $trainOutput" -ForegroundColor Yellow
    }
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "RÃ©pertoire de test supprimÃ©: $testDir" -ForegroundColor Green
}
