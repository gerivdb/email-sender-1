# Tests unitaires pour le module PredictiveModel
# Utilise pytest

import os
import sys
import json
import pytest
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from unittest.mock import patch, MagicMock

# Ajouter le répertoire des modules au chemin de recherche
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'modules')))

# Importer le module à tester
import PredictiveModel

# Données de test
@pytest.fixture
def test_metrics():
    """Génère des données de test pour les métriques"""
    metrics = []
    base_date = datetime.now() - timedelta(days=7)
    
    # Générer des données pour 7 jours avec des mesures toutes les heures
    for day in range(7):
        for hour in range(24):
            current_date = base_date + timedelta(days=day, hours=hour)
            
            # Simuler des tendances et des motifs
            cpu_usage = 30 + 20 * np.sin(hour / 12 * np.pi) + day * 2 + np.random.normal(0, 5)
            memory_usage = 40 + 10 * np.sin(hour / 8 * np.pi) + day * 1.5 + np.random.normal(0, 3)
            disk_usage = 50 + day * 0.5 + np.random.normal(0, 1)
            network_usage = 20 + 15 * np.sin(hour / 6 * np.pi) + np.random.normal(0, 4)
            
            # Ajouter une anomalie le 5ème jour à 15h
            if day == 5 and hour == 15:
                cpu_usage += 40
                memory_usage += 30
            
            metrics.append({
                "Timestamp": current_date.isoformat(),
                "CPU.Usage": max(0, min(100, cpu_usage)),
                "Memory.Usage": max(0, min(100, memory_usage)),
                "Disk.Usage": max(0, min(100, disk_usage)),
                "Network.BandwidthUsage": max(0, min(100, network_usage))
            })
    
    return metrics

@pytest.fixture
def predictor():
    """Crée une instance de PerformancePredictor avec une configuration de test"""
    config = {
        "model_dir": os.path.join(os.environ.get("TEMP", "/tmp"), "test_models"),
        "history_size": 12,
        "forecast_horizon": 6,
        "anomaly_sensitivity": 0.1,
        "training_ratio": 0.8,
        "metrics_to_predict": ["CPU.Usage", "Memory.Usage", "Disk.Usage", "Network.BandwidthUsage"],
        "retraining_interval": 1
    }
    
    # Créer le répertoire de modèles s'il n'existe pas
    os.makedirs(config["model_dir"], exist_ok=True)
    
    return PredictiveModel.PerformancePredictor(config)

# Tests d'initialisation
def test_initialization(predictor):
    """Teste l'initialisation du prédicteur"""
    assert predictor is not None
    assert predictor.config is not None
    assert predictor.config["model_dir"] is not None
    assert predictor.config["history_size"] == 12
    assert predictor.config["forecast_horizon"] == 6
    assert predictor.config["anomaly_sensitivity"] == 0.1
    assert predictor.config["training_ratio"] == 0.8
    assert "CPU.Usage" in predictor.config["metrics_to_predict"]

# Tests de préparation des données
def test_prepare_data(predictor, test_metrics):
    """Teste la préparation des données pour l'entraînement"""
    X, y = predictor._prepare_data(test_metrics, "CPU.Usage")
    assert X is not None
    assert y is not None
    assert len(X) > 0
    assert len(y) > 0
    assert "hour" in X.columns
    assert "day_of_week" in X.columns
    assert "lag_1" in X.columns

# Tests d'entraînement des modèles
def test_train_model(predictor, test_metrics):
    """Teste l'entraînement des modèles"""
    results = predictor.train(test_metrics, force=True)
    assert results is not None
    assert "CPU.Usage" in results
    assert results["CPU.Usage"]["status"] == "success"
    assert "metrics" in results["CPU.Usage"]
    assert "mse" in results["CPU.Usage"]["metrics"]
    assert "importance" in results["CPU.Usage"]

# Tests de prédiction
def test_predict(predictor, test_metrics):
    """Teste la prédiction des valeurs futures"""
    # D'abord entraîner le modèle
    predictor.train(test_metrics, force=True)
    
    # Ensuite faire des prédictions
    results = predictor.predict(test_metrics, horizon=3)
    assert results is not None
    assert "CPU.Usage" in results
    assert results["CPU.Usage"]["status"] == "success"
    assert "predictions" in results["CPU.Usage"]
    assert "timestamps" in results["CPU.Usage"]
    assert len(results["CPU.Usage"]["predictions"]) == 3

# Tests de détection d'anomalies
def test_detect_anomalies(predictor, test_metrics):
    """Teste la détection d'anomalies"""
    # D'abord entraîner le modèle
    predictor.train(test_metrics, force=True)
    
    # Ensuite détecter les anomalies
    results = predictor.detect_anomalies(test_metrics)
    assert results is not None
    assert "CPU.Usage" in results
    assert results["CPU.Usage"]["status"] == "success"
    assert "anomalies" in results["CPU.Usage"]
    assert "anomaly_count" in results["CPU.Usage"]
    assert "total_points" in results["CPU.Usage"]

# Tests d'analyse des tendances
def test_analyze_trends(predictor, test_metrics):
    """Teste l'analyse des tendances"""
    results = predictor.analyze_trends(test_metrics)
    assert results is not None
    assert "CPU.Usage" in results
    assert results["CPU.Usage"]["status"] == "success"
    assert "statistics" in results["CPU.Usage"]
    assert "trend" in results["CPU.Usage"]
    assert "direction" in results["CPU.Usage"]["trend"]
    assert "strength" in results["CPU.Usage"]["trend"]
    assert "slope" in results["CPU.Usage"]["trend"]

# Tests de sauvegarde et chargement des modèles
def test_save_load_models(predictor, test_metrics):
    """Teste la sauvegarde et le chargement des modèles"""
    # Entraîner et sauvegarder les modèles
    predictor.train(test_metrics, force=True)
    
    # Créer un nouveau prédicteur avec la même configuration
    new_predictor = PredictiveModel.PerformancePredictor(predictor.config)
    
    # Vérifier que les modèles ont été chargés
    assert "CPU.Usage" in new_predictor.models
    assert new_predictor.models["CPU.Usage"] is not None
    assert "CPU.Usage" in new_predictor.scalers
    assert new_predictor.scalers["CPU.Usage"] is not None

# Tests de gestion des erreurs
def test_error_handling_invalid_data(predictor):
    """Teste la gestion des erreurs avec des données invalides"""
    # Données vides
    results = predictor.train([], force=True)
    assert results is not None
    for metric in predictor.config["metrics_to_predict"]:
        assert results[metric]["status"] == "error"
    
    # Données avec format incorrect
    invalid_data = [{"invalid": "data"}]
    results = predictor.train(invalid_data, force=True)
    assert results is not None
    for metric in predictor.config["metrics_to_predict"]:
        assert results[metric]["status"] == "error"

# Tests de performance
def test_performance(predictor, test_metrics):
    """Teste les performances du prédicteur"""
    import time
    
    # Mesurer le temps d'entraînement
    start_time = time.time()
    predictor.train(test_metrics, force=True)
    training_time = time.time() - start_time
    
    # Mesurer le temps de prédiction
    start_time = time.time()
    predictor.predict(test_metrics, horizon=6)
    prediction_time = time.time() - start_time
    
    # Vérifier que les temps sont raisonnables
    assert training_time < 10  # L'entraînement devrait prendre moins de 10 secondes
    assert prediction_time < 1  # La prédiction devrait prendre moins de 1 seconde

# Tests d'intégration avec l'interface PowerShell
@patch('subprocess.run')
def test_powershell_integration(mock_run, predictor, test_metrics):
    """Teste l'intégration avec PowerShell"""
    # Simuler l'appel depuis PowerShell
    with open('test_metrics.json', 'w') as f:
        json.dump(test_metrics, f)
    
    # Simuler l'exécution du script en ligne de commande
    sys.argv = ['PredictiveModel.py', '--action', 'predict', '--input', 'test_metrics.json', '--horizon', '3']
    
    # Capturer la sortie
    from io import StringIO
    import sys
    original_stdout = sys.stdout
    sys.stdout = StringIO()
    
    # Exécuter la fonction principale
    if hasattr(PredictiveModel, 'main'):
        PredictiveModel.main()
    
    # Récupérer la sortie
    output = sys.stdout.getvalue()
    sys.stdout = original_stdout
    
    # Nettoyer
    if os.path.exists('test_metrics.json'):
        os.remove('test_metrics.json')
    
    # Vérifier que la sortie contient des informations de prédiction
    assert output is not None
    assert len(output) > 0

if __name__ == "__main__":
    pytest.main(["-xvs", __file__])
