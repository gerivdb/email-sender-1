# Guide d'utilisation du module PerformancePredictor

## Introduction

Le module PerformancePredictor fournit des fonctionnalités avancées de prédiction des performances, de détection d'anomalies et d'analyse des tendances. Il utilise des modèles d'apprentissage automatique pour prédire les valeurs futures des métriques de performance, détecter les comportements anormaux et analyser les tendances à long terme.

## Prérequis

- PowerShell 5.1 ou supérieur
- Python 3.8 ou supérieur
- Bibliothèques Python : numpy, pandas, scikit-learn, joblib, matplotlib

Pour installer les dépendances Python, exécutez le script d'installation :

```powershell
.\scripts\setup\Install-PredictiveModelDependencies.ps1
```

## Installation

1. Importez le module dans votre script PowerShell :

```powershell
Import-Module -Path ".\modules\PerformancePredictor.psm1" -Force
```

2. Initialisez le module avec la configuration souhaitée :

```powershell
Initialize-PerformancePredictor -ConfigPath "C:\Config\perf_config.json" -LogPath "C:\Logs\perf.log" -ModelStoragePath "C:\Models"
```

## Fonctionnalités principales

### Initialisation du module

```powershell
Initialize-PerformancePredictor -ConfigPath "C:\Config\perf_config.json" -LogPath "C:\Logs\perf.log" -ModelStoragePath "C:\Models" -PredictionHorizon 24 -AnomalySensitivity "Medium" -RetrainingInterval 7
```

Paramètres :
- `ConfigPath` : Chemin du fichier de configuration
- `LogPath` : Chemin du fichier de log
- `ModelStoragePath` : Chemin de stockage des modèles
- `PredictionHorizon` : Nombre de points à prédire dans le futur (défaut : 24)
- `AnomalySensitivity` : Sensibilité de la détection d'anomalies (Low, Medium, High)
- `RetrainingInterval` : Intervalle de réentraînement des modèles en jours (défaut : 7)
- `MetricsToPredictString` : Liste des métriques à prédire, séparées par des virgules

### Entraînement des modèles

```powershell
Start-ModelTraining -Metrics $metrics -Force
```

Paramètres :
- `Metrics` : Métriques à utiliser pour l'entraînement
- `Force` : Force le réentraînement même si l'intervalle n'est pas atteint
- `MetricNames` : Noms des métriques spécifiques à entraîner

### Prédiction des valeurs futures

```powershell
Get-PerformancePrediction -Metrics $metrics -MetricName "CPU.Usage" -Horizon 12
```

Paramètres :
- `Metrics` : Métriques historiques à utiliser pour la prédiction
- `MetricName` : Nom de la métrique à prédire
- `Horizon` : Nombre de points à prédire dans le futur

### Détection d'anomalies

```powershell
Find-PerformanceAnomaly -Metrics $metrics -MetricName "Memory.Usage" -Sensitivity "High"
```

Paramètres :
- `Metrics` : Métriques à analyser
- `MetricName` : Nom de la métrique à analyser
- `Sensitivity` : Sensibilité de la détection d'anomalies (Low, Medium, High)

### Analyse des tendances

```powershell
Get-PerformanceTrend -Metrics $metrics -MetricName "ResponseTime"
```

Paramètres :
- `Metrics` : Métriques à analyser
- `MetricName` : Nom de la métrique à analyser

### Génération de rapports

```powershell
Export-PredictionReport -Metrics $metrics -OutputPath "C:\Reports\rapport.html" -Format "HTML" -Horizon 24 -MetricNames @("CPU.Usage", "Memory.Usage")
```

Paramètres :
- `Metrics` : Métriques à analyser
- `OutputPath` : Chemin du fichier de sortie pour le rapport
- `Format` : Format du rapport (JSON, HTML, CSV)
- `Horizon` : Horizon de prédiction
- `MetricNames` : Noms des métriques à inclure dans le rapport

## Format des métriques

Les métriques doivent être fournies sous forme d'un tableau d'objets PowerShell avec la structure suivante :

```powershell
$metrics = @(
    [PSCustomObject]@{
        Timestamp = Get-Date
        CPU = [PSCustomObject]@{
            Usage = 45.2  # Pourcentage d'utilisation CPU
        }
        Memory = [PSCustomObject]@{
            Physical = [PSCustomObject]@{
                UsagePercent = 62.5  # Pourcentage d'utilisation mémoire
            }
        }
        Disk = [PSCustomObject]@{
            Usage = [PSCustomObject]@{
                Average = 78.3  # Pourcentage d'utilisation disque
            }
        }
        Network = [PSCustomObject]@{
            BandwidthUsage = 35.7  # Pourcentage d'utilisation bande passante
        }
        ResponseTime = 120.5  # Temps de réponse en ms
        ErrorRate = 1.2  # Taux d'erreurs en %
        ThroughputRate = 1500.0  # Débit en requêtes/seconde
    }
)
```

## Exemples d'utilisation

### Exemple complet

Voir le script d'exemple `scripts/examples/Use-PerformancePredictor.ps1` pour un exemple complet d'utilisation du module.

### Prédiction et détection d'anomalies

```powershell
# Importer le module
Import-Module -Path ".\modules\PerformancePredictor.psm1" -Force

# Initialiser le module
Initialize-PerformancePredictor -ModelStoragePath "C:\Models"

# Collecter des métriques
$metrics = Get-PerformanceMetrics -Days 7

# Entraîner les modèles
Start-ModelTraining -Metrics $metrics -Force

# Faire des prédictions
$cpuPrediction = Get-PerformancePrediction -Metrics $metrics -MetricName "CPU.Usage" -Horizon 24

# Détecter les anomalies
$memoryAnomalies = Find-PerformanceAnomaly -Metrics $metrics -MetricName "Memory.Usage" -Sensitivity "High"

# Analyser les tendances
$responseTrend = Get-PerformanceTrend -Metrics $metrics -MetricName "ResponseTime"

# Générer un rapport
Export-PredictionReport -Metrics $metrics -OutputPath "C:\Reports\rapport.html" -Format "HTML"
```

## Dépannage

### Problèmes courants

1. **Python n'est pas installé ou n'est pas dans le PATH**
   - Assurez-vous que Python est installé et accessible depuis PowerShell
   - Vérifiez avec `python --version`

2. **Bibliothèques Python manquantes**
   - Exécutez le script d'installation des dépendances
   - Vérifiez avec `pip list`

3. **Erreurs lors de l'entraînement des modèles**
   - Vérifiez que les métriques contiennent suffisamment de données (au moins 24 points)
   - Vérifiez que les métriques sont au format correct

4. **Erreurs lors de la prédiction**
   - Assurez-vous que les modèles ont été entraînés avant de faire des prédictions
   - Vérifiez que la métrique demandée est incluse dans la configuration

### Journalisation

Le module écrit des logs dans le fichier spécifié par le paramètre `LogPath`. Consultez ce fichier pour obtenir des informations détaillées sur les erreurs et les avertissements.

## Références

- [Documentation scikit-learn](https://scikit-learn.org/stable/documentation.html)
- [Documentation pandas](https://pandas.pydata.org/docs/)
- [Documentation numpy](https://numpy.org/doc/stable/)
- [Documentation PowerShell](https://docs.microsoft.com/en-us/powershell/)
