# Script de test pour l'intégration avec Python
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# Vérifier que Python est installé
try {
    $pythonVersion = python --version
    Write-Host "Python détecté: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Error "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.8+ et réessayer."
    exit 1
}

# Vérifier que les bibliothèques nécessaires sont installées
Write-Host "Vérification des bibliothèques Python..." -ForegroundColor Cyan
$requiredLibraries = @("numpy", "pandas", "sklearn", "joblib")
$missingLibraries = @()

foreach ($library in $requiredLibraries) {
    $result = python -c "try:
    import $library
    print('OK')
except ImportError:
    print('MISSING')"
    if ($result -ne "OK") {
        $missingLibraries += $library
    }
}

if ($missingLibraries.Count -gt 0) {
    Write-Host "Bibliothèques manquantes: $($missingLibraries -join ', ')" -ForegroundColor Yellow
    Write-Host "Exécutez le script d'installation des dépendances: .\scripts\setup\Install-PredictiveModelDependencies.ps1" -ForegroundColor Yellow
} else {
    Write-Host "Toutes les bibliothèques nécessaires sont installées." -ForegroundColor Green
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PythonIntegrationTest_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir" -ForegroundColor Green

# Créer un fichier de métriques de test
$metricsFile = Join-Path -Path $testDir -ChildPath "test_metrics.json"
$metrics = @()

for ($i = 0; $i -lt 24; $i++) {
    $timestamp = (Get-Date).AddHours(-24 + $i)
    $cpuUsage = 30 + 20 * [Math]::Sin($i / 12 * [Math]::PI) + (Get-Random -Minimum -5 -Maximum 5)

    $metrics += @{
        Timestamp   = $timestamp.ToString('o')
        "CPU.Usage" = [Math]::Max(0, [Math]::Min(100, $cpuUsage))
    }
}

$metrics | ConvertTo-Json -Depth 10 | Set-Content -Path $metricsFile -Encoding UTF8
Write-Host "Fichier de métriques créé: $metricsFile" -ForegroundColor Green

# Créer un fichier de configuration
$configFile = Join-Path -Path $testDir -ChildPath "config.json"
$config = @{
    model_dir           = Join-Path -Path $testDir -ChildPath "models"
    history_size        = 12
    forecast_horizon    = 6
    anomaly_sensitivity = 0.05
    training_ratio      = 0.8
    metrics_to_predict  = @("CPU.Usage")
    retraining_interval = 1
}

New-Item -Path $config.model_dir -ItemType Directory -Force | Out-Null
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8
Write-Host "Fichier de configuration créé: $configFile" -ForegroundColor Green

# Tester l'appel direct à Python
$pythonScript = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveModel.py"
if (Test-Path -Path $pythonScript) {
    Write-Host "Test d'appel direct à Python..." -ForegroundColor Cyan

    # Entraîner le modèle
    Write-Host "Entraînement du modèle..." -ForegroundColor Yellow
    $trainOutput = python $pythonScript --action train --input $metricsFile --config $configFile --force

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

    # Faire des prédictions
    Write-Host "Prédiction des valeurs futures..." -ForegroundColor Yellow
    $predictOutput = python $pythonScript --action predict --input $metricsFile --config $configFile --horizon 3

    try {
        $predictResult = $predictOutput | ConvertFrom-Json
        if ($predictResult.'CPU.Usage'.status -eq "success") {
            Write-Host "  SUCCÈS: Prédictions générées avec succès" -ForegroundColor Green
            Write-Host "  Prédictions: $($predictResult.'CPU.Usage'.predictions -join ', ')" -ForegroundColor Green
        } else {
            Write-Host "  ÉCHEC: Échec de la génération des prédictions" -ForegroundColor Red
            Write-Host "  Message: $($predictResult.'CPU.Usage'.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ERREUR: Impossible de convertir la sortie en JSON" -ForegroundColor Red
        Write-Host "  Sortie brute: $predictOutput" -ForegroundColor Yellow
    }
} else {
    Write-Host "Script Python non trouvé: $pythonScript" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Répertoire de test supprimé: $testDir" -ForegroundColor Green
}
