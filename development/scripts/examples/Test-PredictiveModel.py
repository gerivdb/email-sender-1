#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de test pour le module PredictiveModel
"""

import os
import sys
import json
import numpy as np
from datetime import datetime, timedelta

# Ajouter le répertoire des modules au chemin de recherche
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'modules')))

# Importer le module à tester
try:
    import PredictiveModel
    print("Module PredictiveModel importé avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation du module PredictiveModel: {e}")
    sys.exit(1)

# Créer un répertoire temporaire pour les tests
test_dir = os.path.join(os.environ.get("TEMP", "/tmp"), f"PredictiveModelTest_{datetime.now().strftime('%Y%m%d%H%M%S')}")
os.makedirs(test_dir, exist_ok=True)
print(f"Répertoire de test créé: {test_dir}")

# Créer un fichier de métriques de test
metrics_file = os.path.join(test_dir, "test_metrics.json")
metrics = []

for i in range(24):
    timestamp = (datetime.now() - timedelta(hours=24) + timedelta(hours=i)).isoformat()
    cpu_usage = 30 + 20 * np.sin(i / 12 * np.pi) + np.random.normal(0, 5)
    
    metrics.append({
        "Timestamp": timestamp,
        "CPU.Usage": max(0, min(100, cpu_usage))
    })

with open(metrics_file, 'w', encoding='utf-8') as f:
    json.dump(metrics, f, indent=2)
print(f"Fichier de métriques créé: {metrics_file}")

# Créer un fichier de configuration
config_file = os.path.join(test_dir, "config.json")
config = {
    "model_dir": os.path.join(test_dir, "models"),
    "history_size": 12,
    "forecast_horizon": 6,
    "anomaly_sensitivity": 0.05,
    "training_ratio": 0.8,
    "metrics_to_predict": ["CPU.Usage"],
    "retraining_interval": 1
}

os.makedirs(config["model_dir"], exist_ok=True)
with open(config_file, 'w', encoding='utf-8') as f:
    json.dump(config, f, indent=2)
print(f"Fichier de configuration créé: {config_file}")

# Tester le module PredictiveModel
print("\nTest du module PredictiveModel...")

# Initialiser le prédicteur
predictor = PredictiveModel.PerformancePredictor(config)
print("Prédicteur initialisé avec succès")

# Entraîner le modèle
print("\nEntraînement du modèle...")
train_result = predictor.train(metrics, force=True)
print(f"Résultat de l'entraînement: {json.dumps(train_result, indent=2)}")

# Faire des prédictions
print("\nPrédiction des valeurs futures...")
predict_result = predictor.predict(metrics, horizon=3)
print(f"Résultat de la prédiction: {json.dumps(predict_result, indent=2)}")

# Détecter les anomalies
print("\nDétection des anomalies...")
anomalies_result = predictor.detect_anomalies(metrics)
print(f"Résultat de la détection d'anomalies: {json.dumps(anomalies_result, indent=2)}")

# Analyser les tendances
print("\nAnalyse des tendances...")
trends_result = predictor.analyze_trends(metrics)
print(f"Résultat de l'analyse des tendances: {json.dumps(trends_result, indent=2)}")

print("\nTest terminé avec succès!")
