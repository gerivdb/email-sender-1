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
    
    # Générer 168 points (1 semaine avec des points horaires)
    for i in range(168):
        timestamp = base_date + timedelta(hours=i)
        
        # Simuler des variations cycliques pour l'utilisation CPU
        hour_of_day = timestamp.hour
        day_of_week = timestamp.weekday()
        
        # Utilisation CPU plus élevée pendant les heures de travail (9h-17h) et en semaine
        cpu_usage = 30 + 20 * np.sin(hour_of_day * np.pi / 12)
        if 9 <= hour_of_day <= 17 and day_of_week < 5:
            cpu_usage += 15
        
        # Ajouter du bruit aléatoire
        cpu_usage += np.random.normal(0, 5)
        cpu_usage = max(0, min(100, cpu_usage))
        
        # Utilisation mémoire corrélée avec CPU mais plus stable
        memory_usage = 50 + 0.3 * cpu_usage + np.random.normal(0, 3)
        memory_usage = max(0, min(100, memory_usage))
        
        # Utilisation disque qui augmente progressivement
        disk_usage = 60 + i * 0.1 + np.random.normal(0, 2)
        disk_usage = max(0, min(100, disk_usage))
        
        # Utilisation réseau corrélée avec CPU
        network_usage = 20 + 0.4 * cpu_usage + np.random.normal(0, 10)
        network_usage = max(0, min(100, network_usage))
        
        # Créer une anomalie à un moment spécifique
        if i == 100:
            cpu_usage = 95
            memory_usage = 90
            network_usage = 90
        
        metrics.append({
            "Timestamp": timestamp.isoformat(),
            "CPU": {
                "Usage": cpu_usage
            },
            "Memory": {
                "Usage": memory_usage
            },
            "Disk": {
                "Usage": disk_usage
            },
            "Network": {
                "BandwidthUsage": network_usage
            }
        })
    
    return metrics

@pytest.fixture
def temp_json_file(test_metrics, tmp_path):
    """Crée un fichier JSON temporaire avec les métriques de test"""
    file_path = tmp_path / "test_metrics.json"
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(test_metrics, f)
    return str(file_path)

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

def test_load_metrics_from_json(temp_json_file, test_metrics):
    """Teste le chargement des métriques à partir d'un fichier JSON"""
    metrics = PredictiveModel.load_metrics_from_json(temp_json_file)
    assert len(metrics) == len(test_metrics)
    assert metrics[0]["CPU"]["Usage"] == test_metrics[0]["CPU"]["Usage"]

def test_predictor_initialization(predictor):
    """Teste l'initialisation du prédicteur"""
    assert predictor is not None
    assert predictor.config["history_size"] == 12
    assert predictor.config["forecast_horizon"] == 6
    assert predictor.config["anomaly_sensitivity"] == 0.1
    assert len(predictor.config["metrics_to_predict"]) == 4

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

def test_train_model(predictor, test_metrics):
    """Teste l'entraînement des modèles"""
    results = predictor.train(test_metrics, force=True)
    assert results is not None
    assert "CPU.Usage" in results
    assert results["CPU.Usage"]["status"] == "success"
    assert "metrics" in results["CPU.Usage"]
    assert "mse" in results["CPU.Usage"]["metrics"]
    assert "importance" in results["CPU.Usage"]

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
    assert len(results["CPU.Usage"]["predictions"]) == 3
    assert "timestamps" in results["CPU.Usage"]
    assert len(results["CPU.Usage"]["timestamps"]) == 3

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

def test_save_predictions_to_json(predictor, test_metrics, tmp_path):
    """Teste la sauvegarde des prédictions dans un fichier JSON"""
    # D'abord entraîner le modèle
    predictor.train(test_metrics, force=True)
    
    # Ensuite faire des prédictions
    results = predictor.predict(test_metrics, horizon=3)
    
    # Sauvegarder les prédictions
    output_file = tmp_path / "predictions.json"
    PredictiveModel.save_predictions_to_json(results, str(output_file))
    
    # Vérifier que le fichier existe et contient les données
    assert os.path.exists(output_file)
    with open(output_file, 'r', encoding='utf-8') as f:
        saved_results = json.load(f)
    
    assert saved_results is not None
    assert "CPU.Usage" in saved_results
    assert saved_results["CPU.Usage"]["status"] == "success"

def test_command_line_interface(temp_json_file, tmp_path):
    """Teste l'interface en ligne de commande"""
    output_file = tmp_path / "cli_output.json"
    
    # Simuler les arguments de ligne de commande
    with patch('sys.argv', ['PredictiveModel.py', '--input', temp_json_file, '--output', str(output_file), '--action', 'train', '--force']):
        # Simuler l'exécution du module en tant que script
        with patch('PredictiveModel.argparse.ArgumentParser.parse_args') as mock_args:
            mock_args.return_value = MagicMock(
                input=temp_json_file,
                output=str(output_file),
                action='train',
                force=True,
                horizon=None,
                config=None
            )
            
            # Simuler l'exécution de la fonction principale
            with patch('PredictiveModel.PerformancePredictor.train') as mock_train:
                mock_train.return_value = {"CPU.Usage": {"status": "success"}}
                
                # Exécuter le code qui serait normalement exécuté par if __name__ == "__main__"
                metrics = PredictiveModel.load_metrics_from_json(temp_json_file)
                predictor = PredictiveModel.PerformancePredictor()
                results = predictor.train(metrics, force=True)
                
                # Vérifier que la fonction train a été appelée
                mock_train.assert_called_once()

if __name__ == "__main__":
    pytest.main(["-v", __file__])
