#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test simple pour le module PredictiveModel
"""

import os
import sys
import json
from datetime import datetime, timedelta

# Ajouter le répertoire des modules au chemin de recherche
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'modules')))

# Importer le module à tester
import PredictiveModel
print("Module PredictiveModel importé avec succès")

# Créer des métriques de test simples
metrics = []
for i in range(24):
    timestamp = (datetime.now() - timedelta(hours=24) + timedelta(hours=i)).isoformat()
    metrics.append({
        "Timestamp": timestamp,
        "CPU": {
            "Usage": 50.0
        }
    })
print(f"Métriques de test créées: {len(metrics)} points")

# Créer une configuration simple
config = {
    "model_dir": os.path.join(os.environ.get("TEMP", "/tmp"), "test_models"),
    "history_size": 12,
    "forecast_horizon": 6,
    "anomaly_sensitivity": 0.05,
    "training_ratio": 0.8,
    "metrics_to_predict": ["CPU.Usage"],
    "retraining_interval": 1
}
print("Configuration créée")

# Créer le répertoire des modèles
os.makedirs(config["model_dir"], exist_ok=True)
print(f"Répertoire des modèles créé: {config['model_dir']}")

# Initialiser le prédicteur
predictor = PredictiveModel.PerformancePredictor(config)
print("Prédicteur initialisé avec succès")

# Entraîner le modèle
print("Entraînement du modèle...")
train_result = predictor.train(metrics, force=True)
print(f"Résultat de l'entraînement: {train_result}")

# Faire des prédictions
print("\nPrédiction des valeurs futures...")
predict_result = predictor.predict(metrics, horizon=3)
print(f"Résultat de la prédiction: {predict_result}")

# Détecter les anomalies
print("\nDétection des anomalies...")
anomalies_result = predictor.detect_anomalies(metrics)
print(f"Résultat de la détection d'anomalies: {anomalies_result}")

# Analyser les tendances
print("\nAnalyse des tendances...")
trends_result = predictor.analyze_trends(metrics)
print(f"Résultat de l'analyse des tendances: {trends_result}")

print("\nTest terminé avec succès!")
