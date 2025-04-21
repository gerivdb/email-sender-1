# Script de test pour l'interface PowerShell du module PerformancePredictor
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PerformancePredictor.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "Module importé avec succès: $modulePath" -ForegroundColor Green
} else {
    Write-Error "Module not found: $modulePath"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PowerShellInterfaceTest_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir" -ForegroundColor Green

# Initialiser le module
Write-Host "Initialisation du module PerformancePredictor..." -ForegroundColor Cyan
$config = Initialize-PerformancePredictor -ConfigPath "$testDir\config.json" -LogPath "$testDir\logs.log" -ModelStoragePath "$testDir\models" -PredictionHorizon 6 -AnomalySensitivity "Medium" -RetrainingInterval 1
Write-Host "Module initialisé avec succès" -ForegroundColor Green
Write-Host "Configuration: $($config | ConvertTo-Json -Compress)" -ForegroundColor Green

# Créer des métriques de test
Write-Host "Création de métriques de test..." -ForegroundColor Cyan
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
Write-Host "Métriques créées: $($metrics.Count) points" -ForegroundColor Green

# Exporter les métriques au format JSON
Write-Host "Exportation des métriques au format JSON..." -ForegroundColor Cyan
$jsonPath = Join-Path -Path $testDir -ChildPath "metrics.json"

# Convertir les métriques au format JSON
$formattedMetrics = $metrics | ForEach-Object {
    @{
        Timestamp   = if ($_.Timestamp -is [DateTime]) { $_.Timestamp.ToString('o') } else { $_.Timestamp }
        "CPU.Usage" = $_.CPU.Usage
    }
}

# Exporter les métriques au format JSON
$formattedMetrics | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
Write-Host "Métriques exportées vers: $jsonPath" -ForegroundColor Green

# Tester l'appel direct à Python
$pythonScript = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveModel.py"
if (Test-Path -Path $pythonScript) {
    Write-Host "Test d'appel direct à Python..." -ForegroundColor Cyan

    # Entraîner le modèle
    Write-Host "Entraînement du modèle..." -ForegroundColor Yellow
    $trainOutput = python $pythonScript --action train --input $jsonPath --config "$testDir\config.json" --force

    try {
        $trainResult = $trainOutput | ConvertFrom-Json
        if ($trainResult.'CPU.Usage'.status -eq "success") {
            Write-Host "  SUCCÈS: Modèle entraîné avec succès" -ForegroundColor Green
        } else {
            Write-Host "  ÉCHEC: Échec de l'entraînement du modèle" -ForegroundColor Red
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
    Write-Host "Répertoire de test supprimé: $testDir" -ForegroundColor Green
}
