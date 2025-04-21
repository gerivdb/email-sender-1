# Documentation technique des modèles prédictifs

## Architecture

L'implémentation des modèles prédictifs repose sur une architecture hybride PowerShell/Python :

1. **Interface PowerShell** (`PerformancePredictor.psm1`) : Fournit une interface conviviale pour les utilisateurs PowerShell, gère la configuration et les appels au module Python.

2. **Moteur de prédiction Python** (`PredictiveModel.py`) : Implémente les algorithmes d'apprentissage automatique pour la prédiction, la détection d'anomalies et l'analyse des tendances.

3. **Stockage des modèles** : Les modèles entraînés sont stockés sous forme de fichiers `.joblib` dans un répertoire configurable.

4. **Journalisation** : Les événements et les erreurs sont journalisés dans un fichier de log configurable.

## Diagramme d'architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Interface PowerShell                         │
│                 (PerformancePredictor.psm1)                      │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Module Python Principal                       │
│                     (PredictiveModel.py)                         │
└───┬───────────────────┬────────────────────┬───────────────────┘
    │                   │                    │
    ▼                   ▼                    ▼
┌─────────────┐   ┌─────────────┐    ┌─────────────────┐
│ Modèles de  │   │ Modèles de  │    │   Modèles de    │
│ Régression  │   │ Détection   │    │ Classification  │
└─────────────┘   └─────────────┘    └─────────────────┘
    │                   │                    │
    └───────────────────┼────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Stockage des Modèles                           │
│                  (Fichiers .joblib)                             │
└─────────────────────────────────────────────────────────────────┘
```

## Composants principaux

### 1. Interface PowerShell (PerformancePredictor.psm1)

Le module PowerShell fournit les fonctions suivantes :

- `Initialize-PerformancePredictor` : Initialise le module avec la configuration spécifiée
- `Start-ModelTraining` : Entraîne les modèles prédictifs
- `Get-PerformancePrediction` : Prédit les valeurs futures des métriques
- `Find-PerformanceAnomaly` : Détecte les anomalies dans les métriques
- `Get-PerformanceTrend` : Analyse les tendances dans les métriques
- `Export-PredictionReport` : Génère des rapports de prédiction

Ces fonctions communiquent avec le module Python en :
1. Exportant les métriques au format JSON
2. Appelant le script Python avec les paramètres appropriés
3. Analysant la sortie JSON du script Python

### 2. Module Python (PredictiveModel.py)

Le module Python implémente la classe `PerformancePredictor` qui fournit les fonctionnalités suivantes :

- `train()` : Entraîne les modèles sur les données fournies
- `predict()` : Prédit les valeurs futures des métriques
- `detect_anomalies()` : Détecte les anomalies dans les données
- `analyze_trends()` : Analyse les tendances dans les données

#### Algorithmes utilisés

1. **Prédiction** : Random Forest Regressor
   - Avantages : Robuste, gère bien les relations non linéaires, peu sensible aux outliers
   - Hyperparamètres : n_estimators=100, random_state=42

2. **Détection d'anomalies** : Isolation Forest
   - Avantages : Efficace pour les données de haute dimension, rapide, ne nécessite pas de données d'entraînement étiquetées
   - Hyperparamètres : contamination=0.05 (configurable), random_state=42

3. **Analyse de tendances** : Régression linéaire
   - Avantages : Simple, interprétable, rapide
   - Métriques : Pente, R², direction (croissante, décroissante, stable), force (faible, modérée, forte)

### 3. Préparation des données

Le module effectue les étapes suivantes pour préparer les données :

1. **Extraction des caractéristiques temporelles** :
   - Heure du jour
   - Jour de la semaine
   - Jour du mois
   - Mois
   - Indicateur de week-end

2. **Création de lags (valeurs précédentes)** :
   - Jusqu'à 24 valeurs précédentes (configurable)

3. **Normalisation** :
   - StandardScaler pour normaliser les données d'entrée

### 4. Stockage des modèles

Les modèles sont stockés sous forme de fichiers `.joblib` dans le répertoire spécifié :

- `{metric}_model.joblib` : Modèle de régression
- `{metric}_scaler.joblib` : Scaler pour la normalisation
- `{metric}_anomaly.joblib` : Modèle de détection d'anomalies
- `{metric}_metadata.json` : Métadonnées (date d'entraînement, configuration)

### 5. Configuration

La configuration est stockée dans un fichier JSON avec les paramètres suivants :

```json
{
    "model_dir": "C:\\Models",
    "history_size": 24,
    "forecast_horizon": 24,
    "anomaly_sensitivity": 0.05,
    "training_ratio": 0.8,
    "metrics_to_predict": ["CPU.Usage", "Memory.Usage", "Disk.Usage", "Network.BandwidthUsage"],
    "retraining_interval": 7
}
```

## Flux de données

### Flux d'entraînement

1. L'utilisateur appelle `Start-ModelTraining` avec des métriques historiques
2. Les métriques sont exportées au format JSON
3. Le script Python est appelé avec l'action "train"
4. Le script Python charge les métriques, prépare les données et entraîne les modèles
5. Les modèles sont sauvegardés sur le disque
6. Les résultats de l'entraînement sont retournés à PowerShell

### Flux de prédiction

1. L'utilisateur appelle `Get-PerformancePrediction` avec des métriques historiques
2. Les métriques sont exportées au format JSON
3. Le script Python est appelé avec l'action "predict"
4. Le script Python charge les modèles, prépare les données et génère des prédictions
5. Les prédictions sont retournées à PowerShell

## Optimisations

### Performance

- **Mise en cache des modèles** : Les modèles sont chargés une seule fois et réutilisés
- **Réentraînement périodique** : Les modèles sont réentraînés à intervalles réguliers pour s'adapter aux changements
- **Normalisation des données** : Améliore la précision et la stabilité des modèles

### Mémoire

- **Chargement paresseux** : Les modèles sont chargés uniquement lorsqu'ils sont nécessaires
- **Nettoyage des fichiers temporaires** : Les fichiers JSON temporaires sont supprimés après utilisation

## Extensibilité

Le système est conçu pour être facilement extensible :

1. **Nouveaux modèles** : De nouveaux algorithmes peuvent être ajoutés en modifiant le module Python
2. **Nouvelles métriques** : De nouvelles métriques peuvent être ajoutées en les incluant dans la configuration
3. **Nouveaux formats de rapport** : De nouveaux formats peuvent être ajoutés en modifiant la fonction `Export-PredictionReport`

## Sécurité

- **Validation des entrées** : Toutes les entrées sont validées avant d'être utilisées
- **Isolation des processus** : Le module Python s'exécute dans un processus séparé
- **Nettoyage des fichiers temporaires** : Les fichiers temporaires sont supprimés après utilisation

## Journalisation

Le module utilise un système de journalisation détaillé :

- **Niveaux de log** : DEBUG, INFO, WARNING, ERROR
- **Rotation des logs** : Les logs sont automatiquement archivés
- **Journalisation des erreurs** : Les erreurs sont journalisées avec des informations détaillées

## Tests

Le module inclut des tests unitaires et d'intégration :

- **Tests unitaires PowerShell** : Testent les fonctions PowerShell individuellement
- **Tests unitaires Python** : Testent les fonctions Python individuellement
- **Tests d'intégration** : Testent l'interaction entre PowerShell et Python
- **Tests de performance** : Testent les performances des modèles

## Limitations connues

1. **Dépendance à Python** : Le module nécessite Python et plusieurs bibliothèques
2. **Taille des données** : Les performances peuvent se dégrader avec de très grands volumes de données
3. **Précision des prédictions** : La précision dépend de la qualité et de la quantité des données historiques

## Références

- [Documentation scikit-learn](https://scikit-learn.org/stable/documentation.html)
- [Documentation pandas](https://pandas.pydata.org/docs/)
- [Documentation numpy](https://numpy.org/doc/stable/)
- [Documentation PowerShell](https://docs.microsoft.com/en-us/powershell/)
