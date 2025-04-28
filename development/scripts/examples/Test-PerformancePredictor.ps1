﻿# Script de test simple pour le module PerformancePredictor
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PerformancePredictor.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "Module PerformancePredictor importÃ© avec succÃ¨s." -ForegroundColor Green
} else {
    Write-Error "Module not found: $modulePath"
    exit 1
}

# CrÃ©er un rÃ©pertoire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PerformancePredictorTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Initialiser le module
Write-Host "Initialisation du module PerformancePredictor..." -ForegroundColor Cyan
Initialize-PerformancePredictor -ConfigPath "$testDir\config.json" -LogPath "$testDir\logs.log" -ModelStoragePath "$testDir\models"

# CrÃ©er des mÃ©triques de test simples
Write-Host "CrÃ©ation de mÃ©triques de test..." -ForegroundColor Cyan
$metrics = @()
$startTime = (Get-Date).AddDays(-1)

for ($i = 0; $i -lt 24; $i++) {
    $timestamp = $startTime.AddHours($i)
    $cpuUsage = 30 + 20 * [Math]::Sin($i / 12 * [Math]::PI) + (Get-Random -Minimum -5 -Maximum 5)

    $metrics += [PSCustomObject]@{
        Timestamp = $timestamp
        CPU       = [PSCustomObject]@{
            Usage = [Math]::Max(0, [Math]::Min(100, $cpuUsage))
        }
    }
}

# Exporter les mÃ©triques au format JSON manuellement
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
$formattedMetrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding utf8

Write-Host "MÃ©triques exportÃ©es vers: $jsonPath" -ForegroundColor Green

# Afficher le contenu du fichier de configuration
Write-Host "Contenu du fichier de configuration:" -ForegroundColor Cyan
if (Test-Path -Path "$testDir\config.json") {
    Get-Content -Path "$testDir\config.json" | Out-Host
} else {
    Write-Warning "Le fichier de configuration n'a pas Ã©tÃ© crÃ©Ã©."
}

Write-Host "Test terminÃ©. Les fichiers gÃ©nÃ©rÃ©s se trouvent dans $testDir" -ForegroundColor Yellow
