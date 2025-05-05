# Script de test pour l'intÃƒÂ©gration avec Python
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# VÃƒÂ©rifier que Python est installÃƒÂ©
try {
    $pythonVersion = python --version
    Write-Host "Python dÃƒÂ©tectÃƒÂ©: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Error "Python n'est pas installÃƒÂ© ou n'est pas dans le PATH. Veuillez installer Python 3.8+ et rÃƒÂ©essayer."
    exit 1
}

# VÃƒÂ©rifier que les bibliothÃƒÂ¨ques nÃƒÂ©cessaires sont installÃƒÂ©es
Write-Host "VÃƒÂ©rification des bibliothÃƒÂ¨ques Python..." -ForegroundColor Cyan
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
    Write-Host "BibliothÃƒÂ¨ques manquantes: $($missingLibraries -join ', ')" -ForegroundColor Yellow
    Write-Host "ExÃƒÂ©cutez le script d'installation des dÃƒÂ©pendances: .\development\scripts\setup\Install-PredictiveModelDependencies.ps1" -ForegroundColor Yellow
} else {
    Write-Host "Toutes les bibliothÃƒÂ¨ques nÃƒÂ©cessaires sont installÃƒÂ©es." -ForegroundColor Green
}

# CrÃƒÂ©er un rÃƒÂ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PythonIntegrationTest_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "RÃƒÂ©pertoire de test crÃƒÂ©ÃƒÂ©: $testDir" -ForegroundColor Green

# CrÃƒÂ©er un fichier de mÃƒÂ©triques de test
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
Write-Host "Fichier de mÃƒÂ©triques crÃƒÂ©ÃƒÂ©: $metricsFile" -ForegroundColor Green

# CrÃƒÂ©er un fichier de configuration
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
Write-Host "Fichier de configuration crÃƒÂ©ÃƒÂ©: $configFile" -ForegroundColor Green

# Tester l'appel direct ÃƒÂ  Python
$pythonScript = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveModel.py"
if (Test-Path -Path $pythonScript) {
    Write-Host "Test d'appel direct ÃƒÂ  Python..." -ForegroundColor Cyan

    # EntraÃƒÂ®ner le modÃƒÂ¨le
    Write-Host "EntraÃƒÂ®nement du modÃƒÂ¨le..." -ForegroundColor Yellow
    $trainOutput = python $pythonScript --action train --input $metricsFile --config $configFile --force

    try {
        $trainResult = $trainOutput | ConvertFrom-Json
        if ($trainResult.'CPU.Usage'.status -eq "success") {
            Write-Host "  SUCCÃƒË†S: ModÃƒÂ¨le entraÃƒÂ®nÃƒÂ© avec succÃƒÂ¨s" -ForegroundColor Green
        } else {
            Write-Host "  Ãƒâ€°CHEC: Ãƒâ€°chec de l'entraÃƒÂ®nement du modÃƒÂ¨le" -ForegroundColor Red
            Write-Host "  Message: $($trainResult.'CPU.Usage'.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ERREUR: Impossible de convertir la sortie en JSON" -ForegroundColor Red
        Write-Host "  Sortie brute: $trainOutput" -ForegroundColor Yellow
    }

    # Faire des prÃƒÂ©dictions
    Write-Host "PrÃƒÂ©diction des valeurs futures..." -ForegroundColor Yellow
    $predictOutput = python $pythonScript --action predict --input $metricsFile --config $configFile --horizon 3

    try {
        $predictResult = $predictOutput | ConvertFrom-Json
        if ($predictResult.'CPU.Usage'.status -eq "success") {
            Write-Host "  SUCCÃƒË†S: PrÃƒÂ©dictions gÃƒÂ©nÃƒÂ©rÃƒÂ©es avec succÃƒÂ¨s" -ForegroundColor Green
            Write-Host "  PrÃƒÂ©dictions: $($predictResult.'CPU.Usage'.predictions -join ', ')" -ForegroundColor Green
        } else {
            Write-Host "  Ãƒâ€°CHEC: Ãƒâ€°chec de la gÃƒÂ©nÃƒÂ©ration des prÃƒÂ©dictions" -ForegroundColor Red
            Write-Host "  Message: $($predictResult.'CPU.Usage'.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ERREUR: Impossible de convertir la sortie en JSON" -ForegroundColor Red
        Write-Host "  Sortie brute: $predictOutput" -ForegroundColor Yellow
    }
} else {
    Write-Host "Script Python non trouvÃƒÂ©: $pythonScript" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "RÃƒÂ©pertoire de test supprimÃƒÂ©: $testDir" -ForegroundColor Green
}
