# Tests unitaires simplifiés pour le module PerformancePredictor
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PerformancePredictor.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "Module importé avec succès: $modulePath" -ForegroundColor Green
} else {
    Write-Error "Module not found: $modulePath"
    exit 1
}

# Vérifier que les fonctions du module sont disponibles
$requiredFunctions = @(
    'Initialize-PerformancePredictor',
    'Start-ModelTraining',
    'Get-PerformancePrediction',
    'Find-PerformanceAnomaly',
    'Get-PerformanceTrend',
    'Export-PredictionReport'
)

$missingFunctions = @()
foreach ($function in $requiredFunctions) {
    if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
        $missingFunctions += $function
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Error "Fonctions manquantes dans le module: $($missingFunctions -join ', ')"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PerformancePredictorTests_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir" -ForegroundColor Green

# Fonction pour générer des métriques de test
function New-TestMetrics {
    param (
        [int]$Count = 24,
        [datetime]$StartTime = (Get-Date).AddDays(-1)
    )

    $metrics = @()
    
    for ($i = 0; $i -lt $Count; $i++) {
        $timestamp = $StartTime.AddHours($i)
        
        # Simuler des tendances et des motifs
        $hour = $timestamp.Hour
        $cpuUsage = 30 + 20 * [Math]::Sin($hour / 12 * [Math]::PI) + (Get-Random -Minimum -5 -Maximum 5)
        $memoryUsage = 40 + 10 * [Math]::Sin($hour / 8 * [Math]::PI) + (Get-Random -Minimum -3 -Maximum 3)
        $diskUsage = 50 + 0.5 * $i + (Get-Random -Minimum -1 -Maximum 1)
        $networkUsage = 20 + 15 * [Math]::Sin($hour / 6 * [Math]::PI) + (Get-Random -Minimum -4 -Maximum 4)
        
        # Ajouter une anomalie à la 15ème heure
        if ($i -eq 15) {
            $cpuUsage += 40
            $memoryUsage += 30
        }
        
        $metrics += [PSCustomObject]@{
            Timestamp = $timestamp
            CPU = [PSCustomObject]@{
                Usage = [Math]::Max(0, [Math]::Min(100, $cpuUsage))
            }
            Memory = [PSCustomObject]@{
                Physical = [PSCustomObject]@{
                    UsagePercent = [Math]::Max(0, [Math]::Min(100, $memoryUsage))
                }
            }
            Disk = [PSCustomObject]@{
                Usage = [PSCustomObject]@{
                    Average = [Math]::Max(0, [Math]::Min(100, $diskUsage))
                }
            }
            Network = [PSCustomObject]@{
                BandwidthUsage = [Math]::Max(0, [Math]::Min(100, $networkUsage))
            }
        }
    }
    
    return $metrics
}

# Tests simples
Write-Host "Exécution des tests simples..." -ForegroundColor Cyan

# Test 1: Initialisation du module
Write-Host "Test 1: Initialisation du module" -ForegroundColor Yellow
try {
    $config = Initialize-PerformancePredictor -ConfigPath "$testDir\config.json" -LogPath "$testDir\logs.log" -ModelStoragePath "$testDir\models" -PredictionHorizon 6 -AnomalySensitivity "Medium" -RetrainingInterval 1
    
    if ($config -and $config.ConfigPath -eq "$testDir\config.json") {
        Write-Host "  SUCCÈS: Module initialisé avec succès" -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de l'initialisation du module" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERREUR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Génération des métriques de test
Write-Host "Test 2: Génération des métriques de test" -ForegroundColor Yellow
try {
    $metrics = New-TestMetrics -Count 48
    
    if ($metrics -and $metrics.Count -eq 48) {
        Write-Host "  SUCCÈS: Métriques générées avec succès" -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de la génération des métriques" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERREUR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 3: Exportation des métriques au format JSON
Write-Host "Test 3: Exportation des métriques au format JSON" -ForegroundColor Yellow
try {
    $jsonPath = Join-Path -Path $testDir -ChildPath "metrics.json"
    
    # Convertir les métriques au format JSON
    $formattedMetrics = $metrics | ForEach-Object {
        @{
            Timestamp = if ($_.Timestamp -is [DateTime]) { $_.Timestamp.ToString('o') } else { $_.Timestamp }
            "CPU.Usage" = $_.CPU.Usage
            "Memory.Usage" = $_.Memory.Physical.UsagePercent
            "Disk.Usage" = $_.Disk.Usage.Average
            "Network.BandwidthUsage" = $_.Network.BandwidthUsage
        }
    }
    
    # Exporter les métriques au format JSON
    $formattedMetrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding utf8
    
    if (Test-Path -Path $jsonPath) {
        Write-Host "  SUCCÈS: Métriques exportées avec succès" -ForegroundColor Green
    } else {
        Write-Host "  ÉCHEC: Échec de l'exportation des métriques" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERREUR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Répertoire de test supprimé: $testDir" -ForegroundColor Green
}

Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
