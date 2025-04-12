# Système d'Optimisation Proactive

Ce module fournit un ensemble d'outils pour le monitoring et l'analyse comportementale des scripts, permettant d'optimiser proactivement leur exécution en fonction de leur utilisation réelle.

## Fonctionnalités

- **Monitoring de l'utilisation des scripts** : Enregistre la fréquence, la durée, le succès/échec et les ressources consommées par les scripts.
- **Analyse des logs** : Identifie les scripts les plus utilisés, les plus lents ou ceux échouant le plus souvent.
- **Détection des goulots d'étranglement** : Identifie les problèmes de performance dans les processus parallèles.
- **Analyse des tendances** : Suit l'évolution de l'utilisation et des performances des scripts au fil du temps.
- **Génération de rapports** : Crée des rapports HTML interactifs pour visualiser les données d'utilisation et les tendances.

## Scripts disponibles

### Monitor-ScriptUsage.ps1

Script principal pour le monitoring et l'analyse de l'utilisation des scripts.

```powershell
# Exemple d'utilisation
.\Monitor-ScriptUsage.ps1 -EnableRealTimeMonitoring
.\Monitor-ScriptUsage.ps1 -GenerateReport -ReportPath "reports\usage"
```

#### Paramètres

- `-DatabasePath` : Chemin vers la base de données d'utilisation (par défaut : usage_data.xml dans le dossier courant).
- `-EnableRealTimeMonitoring` : Active le monitoring en temps réel.
- `-GenerateReport` : Génère un rapport HTML.
- `-ReportPath` : Chemin où enregistrer le rapport (par défaut : reports\usage).
- `-AnalysisPeriodDays` : Nombre de jours à analyser (par défaut : 30).

### Detect-Bottlenecks.ps1

Script spécialisé pour détecter les goulots d'étranglement dans les processus parallèles.

```powershell
# Exemple d'utilisation
.\Detect-Bottlenecks.ps1 -DetailedAnalysis
.\Detect-Bottlenecks.ps1 -GenerateReport -ReportPath "reports\bottlenecks"
```

#### Paramètres

- `-DatabasePath` : Chemin vers la base de données d'utilisation (par défaut : usage_data.xml dans le dossier courant).
- `-DetailedAnalysis` : Active l'analyse détaillée des goulots d'étranglement.
- `-GenerateReport` : Génère un rapport HTML.
- `-ReportPath` : Chemin où enregistrer le rapport (par défaut : reports\bottlenecks).

### Analyze-UsageTrends.ps1

Script pour analyser les tendances d'utilisation des scripts au fil du temps.

```powershell
# Exemple d'utilisation
.\Analyze-UsageTrends.ps1 -PeriodDays 60
.\Analyze-UsageTrends.ps1 -GenerateReport -ReportPath "reports\trends"
```

#### Paramètres

- `-DatabasePath` : Chemin vers la base de données d'utilisation (par défaut : usage_data.xml dans le dossier courant).
- `-PeriodDays` : Nombre de jours à analyser (par défaut : 30).
- `-GenerateReport` : Génère un rapport HTML.
- `-ReportPath` : Chemin où enregistrer le rapport (par défaut : reports\trends).

## Intégration avec UsageMonitor

Ce système s'appuie sur le module UsageMonitor existant pour collecter les données d'utilisation. Pour activer le suivi d'utilisation dans vos scripts, vous pouvez utiliser le script `Add-UsageTracking.ps1` du module UsageMonitor :

```powershell
# Ajouter le suivi d'utilisation à un script ou à un dossier de scripts
..\UsageMonitor\Add-UsageTracking.ps1 -Path "chemin\vers\votre\script.ps1"
..\UsageMonitor\Add-UsageTracking.ps1 -Path "chemin\vers\votre\dossier" -Recurse
```

## Rapports générés

Les rapports HTML générés incluent :

- **Rapport d'utilisation** : Affiche les scripts les plus utilisés, les plus lents, ceux échouant le plus souvent et les goulots d'étranglement détectés.
- **Rapport de goulots d'étranglement** : Fournit une analyse détaillée des goulots d'étranglement dans les processus parallèles, avec des recommandations pour les résoudre.
- **Rapport de tendances** : Montre l'évolution de l'utilisation et des performances des scripts au fil du temps.

## Exemples d'utilisation

### Monitoring en temps réel

```powershell
# Démarrer le monitoring en temps réel
.\Monitor-ScriptUsage.ps1 -EnableRealTimeMonitoring
```

### Analyse hebdomadaire

```powershell
# Créer un rapport hebdomadaire
.\Monitor-ScriptUsage.ps1 -GenerateReport -ReportPath "reports\weekly"
.\Detect-Bottlenecks.ps1 -DetailedAnalysis -GenerateReport -ReportPath "reports\weekly"
.\Analyze-UsageTrends.ps1 -PeriodDays 7 -GenerateReport -ReportPath "reports\weekly"
```

### Intégration dans un pipeline CI/CD

```powershell
# Exemple de script pour intégrer l'analyse dans un pipeline CI/CD
$reportPath = "reports\$(Get-Date -Format 'yyyy-MM-dd')"
.\Monitor-ScriptUsage.ps1 -GenerateReport -ReportPath $reportPath
.\Detect-Bottlenecks.ps1 -DetailedAnalysis -GenerateReport -ReportPath $reportPath
.\Analyze-UsageTrends.ps1 -GenerateReport -ReportPath $reportPath
```

## Prochaines étapes

- Optimisation dynamique de la parallélisation
- Mise en cache prédictive et adaptative
- Suggestions de refactorisation intelligentes
