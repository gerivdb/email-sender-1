# Documentation de l'API du module PerformanceAnalyzer

## Introduction

Cette documentation détaille l'API publique du module PerformanceAnalyzer, qui permet de collecter, analyser et visualiser les métriques de performance du système et des applications. Le module est conçu pour être utilisé dans le cadre du projet EMAIL_SENDER_1, mais peut également être utilisé de manière autonome.

## Installation et prérequis

### Prérequis

- PowerShell 5.1 ou PowerShell 7+
- Droits d'administrateur pour certaines fonctionnalités (collecte de métriques système avancées)
- Modules requis : PSCacheManager (pour la mise en cache des métriques)

### Installation

```powershell
# Importer le module

Import-Module -Name ".\modules\PerformanceAnalyzer.psm1"

# Vérifier que le module est correctement importé

Get-Command -Module PerformanceAnalyzer
```plaintext
## Vue d'ensemble des fonctions

Le module PerformanceAnalyzer expose les fonctions principales suivantes :

| Fonction | Description |
|----------|-------------|
| `Initialize-PerformanceAnalyzer` | Initialise le module avec les paramètres spécifiés |
| `Start-PerformanceAnalysis` | Démarre l'analyse des performances |
| `Get-PerformanceReport` | Génère un rapport de performance |
| `Export-PerformanceData` | Exporte les données de performance dans différents formats |
| `Set-PerformanceThreshold` | Définit des seuils d'alerte pour les métriques |
| `Get-PerformanceTrend` | Analyse les tendances des métriques de performance |
| `Find-PerformanceAnomaly` | Détecte les anomalies dans les métriques de performance |
| `Get-OptimizationRecommendation` | Fournit des recommandations d'optimisation |

## Référence des fonctions

### Initialize-PerformanceAnalyzer

Initialise le module PerformanceAnalyzer avec les paramètres spécifiés.

#### Syntaxe

```powershell
Initialize-PerformanceAnalyzer [[-Enabled] <bool>] [[-ConfigPath] <string>] [[-LogPath] <string>] [[-LogLevel] <string>]
```plaintext
#### Paramètres

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `Enabled` | bool | Active ou désactive l'analyseur de performances | `$true` |
| `ConfigPath` | string | Chemin du fichier de configuration | `"$env:TEMP\PerformanceAnalyzer\config.json"` |
| `LogPath` | string | Chemin du fichier de log | `"$env:TEMP\PerformanceAnalyzer\logs.log"` |
| `LogLevel` | string | Niveau de log (DEBUG, INFO, WARNING, ERROR) | `"INFO"` |

#### Retour

Retourne un objet hashtable contenant la configuration actuelle du module.

#### Exemples

```powershell
# Initialisation avec les paramètres par défaut

Initialize-PerformanceAnalyzer

# Initialisation avec des paramètres personnalisés

Initialize-PerformanceAnalyzer -ConfigPath "C:\Config\perf_config.json" -LogPath "C:\Logs\perf.log" -LogLevel "DEBUG"
```plaintext
### Start-PerformanceAnalysis

Collecte et analyse les métriques de performance du système.

#### Syntaxe

```powershell
Start-PerformanceAnalysis [[-Duration] <int>] [[-CollectionInterval] <int>] [[-OutputPath] <string>]
```plaintext
#### Paramètres

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `Duration` | int | Durée de l'analyse en secondes | `60` |
| `CollectionInterval` | int | Intervalle de collecte des métriques en secondes | `5` |
| `OutputPath` | string | Chemin de sortie pour les résultats de l'analyse | `"$env:TEMP\PerformanceAnalyzer\results"` |

#### Retour

Retourne un objet hashtable contenant les résultats de l'analyse, incluant les métriques collectées et les analyses effectuées.

#### Exemples

```powershell
# Analyse avec les paramètres par défaut

$results = Start-PerformanceAnalysis

# Analyse personnalisée

$results = Start-PerformanceAnalysis -Duration 300 -CollectionInterval 10 -OutputPath "C:\Results"
```plaintext
### Get-PerformanceReport

Génère un rapport de performance basé sur les métriques collectées.

#### Syntaxe

```powershell
Get-PerformanceReport [[-ReportType] <string>] [[-TimeRange] <string>] [[-Format] <string>]
```plaintext
#### Paramètres

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `ReportType` | string | Type de rapport (Summary, Detailed) | `"Summary"` |
| `TimeRange` | string | Plage de temps pour le rapport (Last1Hour, Last24Hours, Last7Days) | `"Last1Hour"` |
| `Format` | string | Format du rapport (Text, HTML, JSON) | `"Text"` |

#### Retour

Retourne un objet contenant le rapport de performance dans le format spécifié.

#### Exemples

```powershell
# Rapport sommaire au format texte

$report = Get-PerformanceReport

# Rapport détaillé au format HTML

$report = Get-PerformanceReport -ReportType "Detailed" -TimeRange "Last24Hours" -Format "HTML"
```plaintext
### Export-PerformanceData

Exporte les données de performance dans différents formats.

#### Syntaxe

```powershell
Export-PerformanceData [[-OutputPath] <string>] [[-Format] <string>] [[-TimeRange] <string>] [[-MetricTypes] <array>]
```plaintext
#### Paramètres

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `OutputPath` | string | Chemin du fichier de sortie | `"$env:TEMP\PerformanceAnalyzer\export.csv"` |
| `Format` | string | Format d'exportation (CSV, JSON, XML) | `"CSV"` |
| `TimeRange` | string | Plage de temps pour l'exportation (Last1Hour, Last24Hours, Last7Days, All) | `"Last24Hours"` |
| `MetricTypes` | array | Types de métriques à exporter (CPU, Memory, Disk, Network, All) | `@("All")` |

#### Retour

Retourne un objet FileInfo représentant le fichier exporté.

#### Exemples

```powershell
# Exporter toutes les métriques au format CSV

Export-PerformanceData -OutputPath "C:\Exports\metrics.csv"

# Exporter uniquement les métriques CPU et mémoire au format JSON

Export-PerformanceData -OutputPath "C:\Exports\cpu_memory.json" -Format "JSON" -MetricTypes @("CPU", "Memory")
```plaintext
### Set-PerformanceThreshold

Définit des seuils d'alerte pour les métriques de performance.

#### Syntaxe

```powershell
Set-PerformanceThreshold [-MetricName] <string> [-Threshold] <double> [[-Duration] <int>] [[-Action] <scriptblock>]
```plaintext
#### Paramètres

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `MetricName` | string | Nom de la métrique (ex: CPU.Usage, Memory.Available) | - |
| `Threshold` | double | Valeur seuil | - |
| `Duration` | int | Durée pendant laquelle le seuil doit être dépassé (en secondes) | `60` |
| `Action` | scriptblock | Action à exécuter lorsque le seuil est dépassé | `$null` |

#### Retour

Retourne un objet représentant le seuil configuré.

#### Exemples

```powershell
# Définir un seuil d'alerte pour l'utilisation CPU

Set-PerformanceThreshold -MetricName "CPU.Usage" -Threshold 90 -Duration 300

# Définir un seuil avec une action personnalisée

Set-PerformanceThreshold -MetricName "Memory.Available" -Threshold 500 -Duration 120 -Action {
    Send-MailMessage -To "admin@example.com" -Subject "Alerte mémoire" -Body "Mémoire disponible faible"
}
```plaintext
### Get-PerformanceTrend

Analyse les tendances des métriques de performance.

#### Syntaxe

```powershell
Get-PerformanceTrend [-MetricName] <string> [[-TimeRange] <string>] [[-Resolution] <string>]
```plaintext
#### Paramètres

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `MetricName` | string | Nom de la métrique (ex: CPU.Usage, Memory.Available) | - |
| `TimeRange` | string | Plage de temps pour l'analyse (Last1Hour, Last24Hours, Last7Days) | `"Last24Hours"` |
| `Resolution` | string | Résolution des données (Minute, Hour, Day) | `"Hour"` |

#### Retour

Retourne un objet contenant l'analyse de tendance pour la métrique spécifiée.

#### Exemples

```powershell
# Analyser la tendance d'utilisation CPU

$trend = Get-PerformanceTrend -MetricName "CPU.Usage"

# Analyser la tendance de mémoire disponible avec une résolution fine

$trend = Get-PerformanceTrend -MetricName "Memory.Available" -TimeRange "Last1Hour" -Resolution "Minute"
```plaintext
### Find-PerformanceAnomaly

Détecte les anomalies dans les métriques de performance.

#### Syntaxe

```powershell
Find-PerformanceAnomaly [[-TimeRange] <string>] [[-MetricTypes] <array>] [[-Sensitivity] <string>]
```plaintext
#### Paramètres

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `TimeRange` | string | Plage de temps pour la détection (Last1Hour, Last24Hours, Last7Days) | `"Last24Hours"` |
| `MetricTypes` | array | Types de métriques à analyser (CPU, Memory, Disk, Network, All) | `@("All")` |
| `Sensitivity` | string | Sensibilité de la détection (Low, Medium, High) | `"Medium"` |

#### Retour

Retourne un tableau d'objets représentant les anomalies détectées.

#### Exemples

```powershell
# Détecter toutes les anomalies

$anomalies = Find-PerformanceAnomaly

# Détecter les anomalies CPU avec une sensibilité élevée

$anomalies = Find-PerformanceAnomaly -MetricTypes @("CPU") -Sensitivity "High"
```plaintext
### Get-OptimizationRecommendation

Fournit des recommandations d'optimisation basées sur l'analyse des métriques de performance.

#### Syntaxe

```powershell
Get-OptimizationRecommendation [[-TimeRange] <string>] [[-Categories] <array>] [[-Priority] <string>]
```plaintext
#### Paramètres

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `TimeRange` | string | Plage de temps pour l'analyse (Last1Hour, Last24Hours, Last7Days) | `"Last7Days"` |
| `Categories` | array | Catégories de recommandations (CPU, Memory, Disk, Network, Application, All) | `@("All")` |
| `Priority` | string | Priorité minimale des recommandations (Low, Medium, High) | `"Medium"` |

#### Retour

Retourne un tableau d'objets représentant les recommandations d'optimisation.

#### Exemples

```powershell
# Obtenir toutes les recommandations

$recommendations = Get-OptimizationRecommendation

# Obtenir uniquement les recommandations de haute priorité pour le disque

$recommendations = Get-OptimizationRecommendation -Categories @("Disk") -Priority "High"
```plaintext
## Fonctions d'analyse spécialisées

### Measure-CPUMetrics

Analyse les métriques CPU pour identifier les tendances, les anomalies et les problèmes de performance.

#### Syntaxe

```powershell
Measure-CPUMetrics [-CPUMetrics] <array>
```plaintext
#### Paramètres

| Paramètre | Type | Description |
|-----------|------|-------------|
| `CPUMetrics` | array | Tableau de métriques CPU à analyser |

#### Retour

Retourne un objet hashtable contenant l'analyse détaillée des métriques CPU, incluant les statistiques, les tendances, les anomalies et les recommandations.

#### Exemples

```powershell
# Analyser les métriques CPU collectées

$cpuAnalysis = Measure-CPUMetrics -CPUMetrics $metrics.CPU
```plaintext
### Measure-MemoryMetrics

Analyse les métriques mémoire pour identifier les tendances, les anomalies et les problèmes de performance.

#### Syntaxe

```powershell
Measure-MemoryMetrics [-MemoryMetrics] <array>
```plaintext
#### Paramètres

| Paramètre | Type | Description |
|-----------|------|-------------|
| `MemoryMetrics` | array | Tableau de métriques mémoire à analyser |

#### Retour

Retourne un objet hashtable contenant l'analyse détaillée des métriques mémoire, incluant les statistiques, les tendances, les anomalies et les recommandations.

#### Exemples

```powershell
# Analyser les métriques mémoire collectées

$memoryAnalysis = Measure-MemoryMetrics -MemoryMetrics $metrics.Memory
```plaintext
### Measure-DiskMetrics

Analyse les métriques disque pour identifier les tendances, les anomalies et les problèmes de performance.

#### Syntaxe

```powershell
Measure-DiskMetrics [-DiskMetrics] <array>
```plaintext
#### Paramètres

| Paramètre | Type | Description |
|-----------|------|-------------|
| `DiskMetrics` | array | Tableau de métriques disque à analyser |

#### Retour

Retourne un objet hashtable contenant l'analyse détaillée des métriques disque, incluant les statistiques, les tendances, les anomalies et les recommandations.

#### Exemples

```powershell
# Analyser les métriques disque collectées

$diskAnalysis = Measure-DiskMetrics -DiskMetrics $metrics.Disk
```plaintext
### Measure-NetworkMetrics

Analyse les métriques réseau pour identifier les tendances, les anomalies et les problèmes de performance.

#### Syntaxe

```powershell
Measure-NetworkMetrics [-NetworkMetrics] <array>
```plaintext
#### Paramètres

| Paramètre | Type | Description |
|-----------|------|-------------|
| `NetworkMetrics` | array | Tableau de métriques réseau à analyser |

#### Retour

Retourne un objet hashtable contenant l'analyse détaillée des métriques réseau, incluant les statistiques, les tendances, les anomalies et les recommandations.

#### Exemples

```powershell
# Analyser les métriques réseau collectées

$networkAnalysis = Measure-NetworkMetrics -NetworkMetrics $metrics.Network
```plaintext
### Measure-Metrics

Analyse l'ensemble des métriques collectées pour identifier les tendances, les anomalies et les problèmes de performance.

#### Syntaxe

```powershell
Measure-Metrics [-Metrics] <array>
```plaintext
#### Paramètres

| Paramètre | Type | Description |
|-----------|------|-------------|
| `Metrics` | array | Tableau de métriques à analyser |

#### Retour

Retourne un objet hashtable contenant l'analyse détaillée de toutes les métriques, incluant les analyses spécifiques pour chaque type de métrique, les problèmes identifiés et les recommandations.

#### Exemples

```powershell
# Analyser toutes les métriques collectées

$analysis = Measure-Metrics -Metrics $metrics
```plaintext
### Get-MetricTrend

Calcule la tendance (croissante, décroissante ou stable) d'une série de valeurs.

#### Syntaxe

```powershell
Get-MetricTrend [-Values] <array>
```plaintext
#### Paramètres

| Paramètre | Type | Description |
|-----------|------|-------------|
| `Values` | array | Série de valeurs à analyser |

#### Retour

Retourne une chaîne indiquant la tendance : "Croissante", "Décroissante" ou "Stable".

#### Exemples

```powershell
# Calculer la tendance d'une série de valeurs

$trend = Get-MetricTrend -Values @(10, 15, 20, 25, 30)
```plaintext
## Intégration avec MetricsCollector

Le module PerformanceAnalyzer s'intègre étroitement avec le module MetricsCollector pour la collecte des métriques. Voici les principales fonctions du module MetricsCollector utilisées par PerformanceAnalyzer :

### Initialize-MetricsCollector

Initialise le collecteur de métriques avec les paramètres spécifiés.

#### Syntaxe

```powershell
Initialize-MetricsCollector [[-Enabled] <bool>] [[-CollectionInterval] <int>] [[-StoragePath] <string>] [[-MaxStorageSize] <int>] [[-CollectCPU] <bool>] [[-CollectMemory] <bool>] [[-CollectDisk] <bool>] [[-CollectNetwork] <bool>] [[-CollectApplication] <bool>] [[-TopProcessCount] <int>]
```plaintext
### Start-MetricsCollection

Démarre la collecte de métriques en arrière-plan.

#### Syntaxe

```powershell
Start-MetricsCollection [[-NoBackground] <switch>]
```plaintext
### Stop-MetricsCollection

Arrête la collecte de métriques en arrière-plan.

#### Syntaxe

```powershell
Stop-MetricsCollection
```plaintext
### Get-CPUMetrics

Collecte les métriques CPU.

#### Syntaxe

```powershell
Get-CPUMetrics
```plaintext
### Get-MemoryMetrics

Collecte les métriques mémoire.

#### Syntaxe

```powershell
Get-MemoryMetrics
```plaintext
### Get-DiskMetrics

Collecte les métriques disque.

#### Syntaxe

```powershell
Get-DiskMetrics
```plaintext
### Get-NetworkMetrics

Collecte les métriques réseau.

#### Syntaxe

```powershell
Get-NetworkMetrics
```plaintext
## Exemples d'utilisation

### Analyse rapide des performances

```powershell
# Importer le module

Import-Module -Name ".\modules\PerformanceAnalyzer.psm1"

# Initialiser le module

Initialize-PerformanceAnalyzer

# Effectuer une analyse rapide (1 minute)

$results = Start-PerformanceAnalysis -Duration 60 -CollectionInterval 5

# Afficher les résultats

$results.Analysis.CPU.Usage
$results.Analysis.Memory.Usage
$results.Analysis.Disk.Usage
$results.Analysis.Network.BandwidthUsage

# Afficher les recommandations

$results.Analysis.Recommendations
```plaintext
### Surveillance continue avec alertes

```powershell
# Importer le module

Import-Module -Name ".\modules\PerformanceAnalyzer.psm1"

# Initialiser le module

Initialize-PerformanceAnalyzer

# Définir des seuils d'alerte

Set-PerformanceThreshold -MetricName "CPU.Usage" -Threshold 90 -Duration 300 -Action {
    Send-MailMessage -To "admin@example.com" -Subject "Alerte CPU" -Body "Utilisation CPU élevée"
}

Set-PerformanceThreshold -MetricName "Memory.Available" -Threshold 500 -Duration 120 -Action {
    Send-MailMessage -To "admin@example.com" -Subject "Alerte mémoire" -Body "Mémoire disponible faible"
}

# Démarrer la collecte en arrière-plan

Start-MetricsCollection
```plaintext
### Analyse des tendances et détection d'anomalies

```powershell
# Importer le module

Import-Module -Name ".\modules\PerformanceAnalyzer.psm1"

# Initialiser le module

Initialize-PerformanceAnalyzer

# Analyser les tendances CPU sur les dernières 24 heures

$cpuTrend = Get-PerformanceTrend -MetricName "CPU.Usage" -TimeRange "Last24Hours"

# Détecter les anomalies

$anomalies = Find-PerformanceAnomaly -TimeRange "Last24Hours" -Sensitivity "High"

# Obtenir des recommandations d'optimisation

$recommendations = Get-OptimizationRecommendation -TimeRange "Last7Days" -Priority "High"
```plaintext
### Génération de rapports

```powershell
# Importer le module

Import-Module -Name ".\modules\PerformanceAnalyzer.psm1"

# Initialiser le module

Initialize-PerformanceAnalyzer

# Générer un rapport sommaire au format texte

$summaryReport = Get-PerformanceReport -ReportType "Summary" -TimeRange "Last24Hours" -Format "Text"

# Générer un rapport détaillé au format HTML

$detailedReport = Get-PerformanceReport -ReportType "Detailed" -TimeRange "Last7Days" -Format "HTML"

# Exporter les données de performance au format CSV

Export-PerformanceData -OutputPath "C:\Reports\performance_data.csv" -Format "CSV" -TimeRange "Last7Days"
```plaintext
## Bonnes pratiques

### Performance

- Utilisez des intervalles de collecte appropriés (5-10 secondes pour une analyse en temps réel, 1-5 minutes pour une surveillance continue)
- Limitez la collecte aux métriques nécessaires pour réduire l'impact sur le système
- Utilisez la mise en cache pour optimiser les performances d'analyse

### Stockage

- Configurez une politique de rétention des données adaptée à vos besoins
- Exportez régulièrement les données importantes pour une analyse à long terme
- Utilisez la compression pour réduire l'espace de stockage nécessaire

### Alertes

- Définissez des seuils d'alerte réalistes basés sur les caractéristiques de votre système
- Utilisez des durées appropriées pour éviter les fausses alertes dues à des pics temporaires
- Implémentez des actions d'alerte graduelles (journalisation, notification, action corrective)

## Dépannage

### Problèmes courants

| Problème | Cause possible | Solution |
|----------|----------------|----------|
| Erreur "Access denied" | Droits insuffisants | Exécuter PowerShell en tant qu'administrateur |
| Collecte de métriques lente | Intervalle de collecte trop court | Augmenter l'intervalle de collecte |
| Utilisation élevée des ressources | Collecte de trop de métriques | Limiter les types de métriques collectées |
| Données manquantes | Problème de stockage ou de collecte | Vérifier les logs et les permissions |

### Journalisation

Le module PerformanceAnalyzer génère des logs détaillés qui peuvent être utilisés pour diagnostiquer les problèmes. Les logs sont stockés dans le fichier spécifié par le paramètre `LogPath` lors de l'initialisation du module.

```powershell
# Initialiser le module avec journalisation détaillée

Initialize-PerformanceAnalyzer -LogLevel "DEBUG" -LogPath "C:\Logs\performance_analyzer.log"

# Consulter les logs

Get-Content -Path "C:\Logs\performance_analyzer.log" -Tail 50
```plaintext
## Conclusion

L'API du module PerformanceAnalyzer offre un ensemble complet de fonctionnalités pour la collecte, l'analyse et la visualisation des métriques de performance. Elle est conçue pour être flexible, extensible et facile à utiliser, tout en fournissant des informations détaillées sur les performances du système et des applications.

Pour plus d'informations sur l'architecture du module, consultez le document [PerformanceAnalyzerArchitecture.md](PerformanceAnalyzerArchitecture.md).
