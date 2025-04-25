#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de modèles prédictifs pour l'analyse des performances
Ce module fournit des fonctionnalités d'analyse prédictive des métriques de performance
Author: EMAIL_SENDER_1 Team
Version: 1.0.0
"""

import os
import json
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Union, Tuple, Optional, Any
import joblib
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestRegressor, IsolationForest
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

# Configuration par défaut
DEFAULT_CONFIG = {
    "model_dir": os.path.join(os.environ.get("TEMP", "/tmp"), "PerformanceAnalyzer", "models"),
    "history_size": 24,  # Nombre de points de données historiques à utiliser
    "forecast_horizon": 12,  # Nombre de points de données à prédire
    "anomaly_sensitivity": 0.05,  # Seuil de sensibilité pour la détection d'anomalies (plus petit = plus sensible)
    "training_ratio": 0.8,  # Ratio de données utilisées pour l'entraînement
    "metrics_to_predict": ["CPU.Usage", "Memory.Usage", "Disk.Usage", "Network.BandwidthUsage"],
    "retraining_interval": 7,  # Jours entre les réentraînements
}

class PerformancePredictor:
    """Classe principale pour la prédiction des performances"""
    
    def __init__(self, config: Dict = None):
        """
        Initialise le prédicteur de performances
        
        Args:
            config: Configuration personnalisée (facultatif)
        """
        self.config = DEFAULT_CONFIG.copy()
        if config:
            self.config.update(config)
        
        # Créer le répertoire des modèles s'il n'existe pas
        os.makedirs(self.config["model_dir"], exist_ok=True)
        
        # Initialiser les modèles
        self.models = {}
        self.scalers = {}
        self.anomaly_detectors = {}
        self.last_training_date = {}
        
        # Charger les modèles existants
        self._load_models()
    
    def _load_models(self) -> None:
        """Charge les modèles existants depuis le disque"""
        for metric in self.config["metrics_to_predict"]:
            model_path = os.path.join(self.config["model_dir"], f"{metric.replace('.', '_')}_model.joblib")
            scaler_path = os.path.join(self.config["model_dir"], f"{metric.replace('.', '_')}_scaler.joblib")
            anomaly_detector_path = os.path.join(self.config["model_dir"], f"{metric.replace('.', '_')}_anomaly.joblib")
            metadata_path = os.path.join(self.config["model_dir"], f"{metric.replace('.', '_')}_metadata.json")
            
            if os.path.exists(model_path) and os.path.exists(scaler_path):
                try:
                    self.models[metric] = joblib.load(model_path)
                    self.scalers[metric] = joblib.load(scaler_path)
                    
                    if os.path.exists(anomaly_detector_path):
                        self.anomaly_detectors[metric] = joblib.load(anomaly_detector_path)
                    
                    if os.path.exists(metadata_path):
                        with open(metadata_path, 'r') as f:
                            metadata = json.load(f)
                            self.last_training_date[metric] = datetime.fromisoformat(metadata.get("last_training_date", "2000-01-01"))
                except Exception as e:
                    print(f"Erreur lors du chargement du modèle pour {metric}: {e}")
    
    def _save_models(self, metric: str) -> None:
        """
        Sauvegarde les modèles sur le disque
        
        Args:
            metric: Nom de la métrique
        """
        if metric in self.models and metric in self.scalers:
            model_path = os.path.join(self.config["model_dir"], f"{metric.replace('.', '_')}_model.joblib")
            scaler_path = os.path.join(self.config["model_dir"], f"{metric.replace('.', '_')}_scaler.joblib")
            metadata_path = os.path.join(self.config["model_dir"], f"{metric.replace('.', '_')}_metadata.json")
            
            joblib.dump(self.models[metric], model_path)
            joblib.dump(self.scalers[metric], scaler_path)
            
            if metric in self.anomaly_detectors:
                anomaly_detector_path = os.path.join(self.config["model_dir"], f"{metric.replace('.', '_')}_anomaly.joblib")
                joblib.dump(self.anomaly_detectors[metric], anomaly_detector_path)
            
            # Sauvegarder les métadonnées
            metadata = {
                "last_training_date": datetime.now().isoformat(),
                "metric": metric,
                "config": self.config
            }
            
            with open(metadata_path, 'w') as f:
                json.dump(metadata, f, indent=2)
    
    def _prepare_data(self, data: List[Dict], metric_path: str) -> Tuple[pd.DataFrame, np.ndarray]:
        """
        Prépare les données pour l'entraînement ou la prédiction
        
        Args:
            data: Liste de dictionnaires contenant les métriques
            metric_path: Chemin d'accès à la métrique (ex: "CPU.Usage")
        
        Returns:
            Tuple contenant les features et les valeurs cibles
        """
        # Extraire la valeur de la métrique à partir du chemin
        def extract_metric_value(item, path):
            parts = path.split('.')
            current = item
            for part in parts:
                if isinstance(current, dict) and part in current:
                    current = current[part]
                else:
                    return None
            return current
        
        # Extraire les timestamps et les valeurs
        timestamps = []
        values = []
        
        for item in data:
            if "Timestamp" in item:
                timestamp = item["Timestamp"]
                if isinstance(timestamp, str):
                    timestamp = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                timestamps.append(timestamp)
                
                value = extract_metric_value(item, metric_path)
                if value is not None:
                    values.append(float(value))
                else:
                    values.append(np.nan)
        
        # Créer un DataFrame
        df = pd.DataFrame({"timestamp": timestamps, "value": values})
        df = df.dropna()
        
        if df.empty:
            raise ValueError(f"Aucune donnée valide trouvée pour la métrique {metric_path}")
        
        # Trier par timestamp
        df = df.sort_values("timestamp")
        
        # Créer des features temporelles
        df["hour"] = df["timestamp"].dt.hour
        df["day_of_week"] = df["timestamp"].dt.dayofweek
        df["day_of_month"] = df["timestamp"].dt.day
        df["month"] = df["timestamp"].dt.month
        df["is_weekend"] = df["day_of_week"].apply(lambda x: 1 if x >= 5 else 0)
        
        # Créer des lags (valeurs précédentes)
        for i in range(1, min(self.config["history_size"] + 1, len(df))):
            df[f"lag_{i}"] = df["value"].shift(i)
        
        # Supprimer les lignes avec des NaN (dues aux lags)
        df = df.dropna()
        
        if df.empty:
            raise ValueError(f"Pas assez de données historiques pour la métrique {metric_path}")
        
        # Séparer les features et la cible
        X = df.drop(["timestamp", "value"], axis=1)
        y = df["value"].values
        
        return X, y
    
    def train(self, data: List[Dict], force: bool = False) -> Dict[str, Any]:
        """
        Entraîne les modèles prédictifs
        
        Args:
            data: Liste de dictionnaires contenant les métriques
            force: Force le réentraînement même si l'intervalle n'est pas atteint
        
        Returns:
            Dictionnaire contenant les résultats de l'entraînement
        """
        results = {}
        
        for metric in self.config["metrics_to_predict"]:
            # Vérifier si le réentraînement est nécessaire
            if not force and metric in self.last_training_date:
                days_since_training = (datetime.now() - self.last_training_date[metric]).days
                if days_since_training < self.config["retraining_interval"]:
                    results[metric] = {
                        "status": "skipped",
                        "message": f"Le modèle a été entraîné il y a {days_since_training} jours (intervalle: {self.config['retraining_interval']} jours)"
                    }
                    continue
            
            try:
                # Préparer les données
                X, y = self._prepare_data(data, metric)
                
                if len(X) < 10:  # Vérifier qu'il y a suffisamment de données
                    results[metric] = {
                        "status": "error",
                        "message": f"Pas assez de données pour entraîner le modèle (minimum 10, trouvé {len(X)})"
                    }
                    continue
                
                # Diviser les données en ensembles d'entraînement et de test
                X_train, X_test, y_train, y_test = train_test_split(
                    X, y, train_size=self.config["training_ratio"], shuffle=False
                )
                
                # Normaliser les données
                scaler = StandardScaler()
                X_train_scaled = scaler.fit_transform(X_train)
                X_test_scaled = scaler.transform(X_test)
                
                # Entraîner le modèle de régression
                model = RandomForestRegressor(n_estimators=100, random_state=42)
                model.fit(X_train_scaled, y_train)
                
                # Évaluer le modèle
                y_pred = model.predict(X_test_scaled)
                mse = mean_squared_error(y_test, y_pred)
                mae = mean_absolute_error(y_test, y_pred)
                r2 = r2_score(y_test, y_pred)
                
                # Entraîner le détecteur d'anomalies
                anomaly_detector = IsolationForest(contamination=self.config["anomaly_sensitivity"], random_state=42)
                anomaly_detector.fit(X_train_scaled)
                
                # Sauvegarder les modèles
                self.models[metric] = model
                self.scalers[metric] = scaler
                self.anomaly_detectors[metric] = anomaly_detector
                self.last_training_date[metric] = datetime.now()
                
                self._save_models(metric)
                
                results[metric] = {
                    "status": "success",
                    "metrics": {
                        "mse": mse,
                        "mae": mae,
                        "r2": r2
                    },
                    "importance": dict(zip(X.columns, model.feature_importances_)),
                    "samples": len(X)
                }
                
            except Exception as e:
                results[metric] = {
                    "status": "error",
                    "message": str(e)
                }
        
        return results
    
    def predict(self, data: List[Dict], horizon: int = None) -> Dict[str, Any]:
        """
        Prédit les valeurs futures des métriques
        
        Args:
            data: Liste de dictionnaires contenant les métriques historiques
            horizon: Nombre de points à prédire (utilise la valeur de configuration par défaut si non spécifié)
        
        Returns:
            Dictionnaire contenant les prédictions
        """
        if horizon is None:
            horizon = self.config["forecast_horizon"]
        
        results = {}
        
        for metric in self.config["metrics_to_predict"]:
            if metric not in self.models or metric not in self.scalers:
                results[metric] = {
                    "status": "error",
                    "message": f"Aucun modèle entraîné pour la métrique {metric}"
                }
                continue
            
            try:
                # Préparer les données
                X, y = self._prepare_data(data, metric)
                
                if len(X) < self.config["history_size"]:
                    results[metric] = {
                        "status": "error",
                        "message": f"Pas assez de données historiques (minimum {self.config['history_size']}, trouvé {len(X)})"
                    }
                    continue
                
                # Utiliser les données les plus récentes
                latest_data = X.iloc[-1:].copy()
                
                # Normaliser les données
                latest_data_scaled = self.scalers[metric].transform(latest_data)
                
                # Prédictions
                predictions = []
                timestamps = []
                
                # Dernière date connue
                last_timestamp = data[-1]["Timestamp"]
                if isinstance(last_timestamp, str):
                    last_timestamp = datetime.fromisoformat(last_timestamp.replace('Z', '+00:00'))
                
                # Intervalle moyen entre les points de données
                if len(data) > 1:
                    first_timestamp = data[0]["Timestamp"]
                    if isinstance(first_timestamp, str):
                        first_timestamp = datetime.fromisoformat(first_timestamp.replace('Z', '+00:00'))
                    
                    avg_interval = (last_timestamp - first_timestamp) / (len(data) - 1)
                else:
                    avg_interval = timedelta(minutes=5)  # Valeur par défaut
                
                current_data = latest_data.copy()
                current_timestamp = last_timestamp
                
                for i in range(horizon):
                    # Prédire la valeur suivante
                    current_data_scaled = self.scalers[metric].transform(current_data)
                    prediction = self.models[metric].predict(current_data_scaled)[0]
                    
                    # Ajouter la prédiction aux résultats
                    current_timestamp = current_timestamp + avg_interval
                    timestamps.append(current_timestamp.isoformat())
                    predictions.append(float(prediction))
                    
                    # Mettre à jour les données pour la prochaine prédiction
                    for j in range(self.config["history_size"] - 1, 0, -1):
                        if f"lag_{j}" in current_data.columns and f"lag_{j-1}" in current_data.columns:
                            current_data[f"lag_{j}"] = current_data[f"lag_{j-1}"]
                    
                    if "lag_1" in current_data.columns:
                        current_data["lag_1"] = prediction
                    
                    # Mettre à jour les features temporelles
                    current_data["hour"] = current_timestamp.hour
                    current_data["day_of_week"] = current_timestamp.weekday()
                    current_data["day_of_month"] = current_timestamp.day
                    current_data["month"] = current_timestamp.month
                    current_data["is_weekend"] = 1 if current_timestamp.weekday() >= 5 else 0
                
                results[metric] = {
                    "status": "success",
                    "predictions": predictions,
                    "timestamps": timestamps
                }
                
            except Exception as e:
                results[metric] = {
                    "status": "error",
                    "message": str(e)
                }
        
        return results
    
    def detect_anomalies(self, data: List[Dict]) -> Dict[str, Any]:
        """
        Détecte les anomalies dans les données
        
        Args:
            data: Liste de dictionnaires contenant les métriques
        
        Returns:
            Dictionnaire contenant les anomalies détectées
        """
        results = {}
        
        for metric in self.config["metrics_to_predict"]:
            if metric not in self.models or metric not in self.scalers or metric not in self.anomaly_detectors:
                results[metric] = {
                    "status": "error",
                    "message": f"Aucun modèle d'anomalie entraîné pour la métrique {metric}"
                }
                continue
            
            try:
                # Préparer les données
                X, y = self._prepare_data(data, metric)
                
                # Normaliser les données
                X_scaled = self.scalers[metric].transform(X)
                
                # Détecter les anomalies
                anomaly_scores = self.anomaly_detectors[metric].decision_function(X_scaled)
                anomaly_predictions = self.anomaly_detectors[metric].predict(X_scaled)
                
                # Convertir les prédictions (-1 = anomalie, 1 = normal) en booléens
                is_anomaly = [pred == -1 for pred in anomaly_predictions]
                
                # Extraire les timestamps
                timestamps = [item["Timestamp"] for item in data if "Timestamp" in item]
                if len(timestamps) > len(is_anomaly):
                    timestamps = timestamps[-len(is_anomaly):]
                
                # Créer la liste des anomalies
                anomalies = []
                for i, (timestamp, anomaly, score, value) in enumerate(zip(timestamps, is_anomaly, anomaly_scores, y)):
                    if anomaly:
                        if isinstance(timestamp, datetime):
                            timestamp = timestamp.isoformat()
                        
                        anomalies.append({
                            "timestamp": timestamp,
                            "value": float(value),
                            "score": float(score),
                            "severity": "high" if score < -0.5 else "medium"
                        })
                
                results[metric] = {
                    "status": "success",
                    "anomalies": anomalies,
                    "anomaly_count": sum(is_anomaly),
                    "total_points": len(is_anomaly)
                }
                
            except Exception as e:
                results[metric] = {
                    "status": "error",
                    "message": str(e)
                }
        
        return results
    
    def analyze_trends(self, data: List[Dict]) -> Dict[str, Any]:
        """
        Analyse les tendances dans les données
        
        Args:
            data: Liste de dictionnaires contenant les métriques
        
        Returns:
            Dictionnaire contenant l'analyse des tendances
        """
        results = {}
        
        for metric in self.config["metrics_to_predict"]:
            try:
                # Extraire la valeur de la métrique à partir du chemin
                def extract_metric_value(item, path):
                    parts = path.split('.')
                    current = item
                    for part in parts:
                        if isinstance(current, dict) and part in current:
                            current = current[part]
                        else:
                            return None
                    return current
                
                # Extraire les timestamps et les valeurs
                timestamps = []
                values = []
                
                for item in data:
                    if "Timestamp" in item:
                        timestamp = item["Timestamp"]
                        if isinstance(timestamp, str):
                            timestamp = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                        timestamps.append(timestamp)
                        
                        value = extract_metric_value(item, metric)
                        if value is not None:
                            values.append(float(value))
                        else:
                            values.append(np.nan)
                
                # Créer un DataFrame
                df = pd.DataFrame({"timestamp": timestamps, "value": values})
                df = df.dropna()
                
                if df.empty:
                    results[metric] = {
                        "status": "error",
                        "message": f"Aucune donnée valide trouvée pour la métrique {metric}"
                    }
                    continue
                
                # Trier par timestamp
                df = df.sort_values("timestamp")
                
                # Calculer les statistiques de base
                stats = {
                    "mean": float(df["value"].mean()),
                    "median": float(df["value"].median()),
                    "min": float(df["value"].min()),
                    "max": float(df["value"].max()),
                    "std": float(df["value"].std()),
                    "count": int(len(df))
                }
                
                # Calculer la tendance linéaire
                X = np.array(range(len(df))).reshape(-1, 1)
                y = df["value"].values
                
                model = LinearRegression()
                model.fit(X, y)
                
                slope = float(model.coef_[0])
                intercept = float(model.intercept_)
                
                # Déterminer la direction de la tendance
                if abs(slope) < 0.001:
                    trend_direction = "stable"
                elif slope > 0:
                    trend_direction = "croissante"
                else:
                    trend_direction = "décroissante"
                
                # Calculer la force de la tendance (R²)
                y_pred = model.predict(X)
                r2 = r2_score(y, y_pred)
                
                # Déterminer la force de la tendance
                if r2 < 0.3:
                    trend_strength = "faible"
                elif r2 < 0.7:
                    trend_strength = "modérée"
                else:
                    trend_strength = "forte"
                
                # Calculer la variation en pourcentage
                if len(df) > 1:
                    first_value = df["value"].iloc[0]
                    last_value = df["value"].iloc[-1]
                    
                    if first_value != 0:
                        percent_change = ((last_value - first_value) / first_value) * 100
                    else:
                        percent_change = float('inf') if last_value > 0 else 0
                else:
                    percent_change = 0
                
                # Calculer la saisonnalité (si suffisamment de données)
                seasonality = "inconnue"
                if len(df) >= 24:  # Au moins 24 points pour détecter une saisonnalité
                    # Calculer l'autocorrélation
                    autocorr = pd.Series(df["value"]).autocorr(lag=12)
                    
                    if abs(autocorr) > 0.5:
                        seasonality = "détectée"
                    else:
                        seasonality = "non détectée"
                
                results[metric] = {
                    "status": "success",
                    "statistics": stats,
                    "trend": {
                        "direction": trend_direction,
                        "strength": trend_strength,
                        "slope": slope,
                        "intercept": intercept,
                        "r2": float(r2),
                        "percent_change": float(percent_change)
                    },
                    "seasonality": seasonality
                }
                
            except Exception as e:
                results[metric] = {
                    "status": "error",
                    "message": str(e)
                }
        
        return results

def load_metrics_from_json(file_path: str) -> List[Dict]:
    """
    Charge les métriques à partir d'un fichier JSON
    
    Args:
        file_path: Chemin du fichier JSON
    
    Returns:
        Liste de dictionnaires contenant les métriques
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Si les données sont dans un format imbriqué, extraire la liste de métriques
    if isinstance(data, dict) and "Metrics" in data:
        return data["Metrics"]
    elif isinstance(data, dict) and "metrics" in data:
        return data["metrics"]
    elif isinstance(data, list):
        return data
    else:
        raise ValueError("Format de données non reconnu")

def save_predictions_to_json(predictions: Dict[str, Any], file_path: str) -> None:
    """
    Sauvegarde les prédictions dans un fichier JSON
    
    Args:
        predictions: Dictionnaire contenant les prédictions
        file_path: Chemin du fichier JSON de sortie
    """
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(predictions, f, indent=2)

# Point d'entrée pour l'exécution en ligne de commande
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Module de prédiction des performances")
    parser.add_argument("--input", "-i", required=True, help="Fichier JSON contenant les métriques")
    parser.add_argument("--output", "-o", help="Fichier JSON de sortie pour les prédictions")
    parser.add_argument("--action", "-a", choices=["train", "predict", "anomalies", "trends"], default="predict", 
                        help="Action à effectuer (train, predict, anomalies, trends)")
    parser.add_argument("--force", "-f", action="store_true", help="Force le réentraînement des modèles")
    parser.add_argument("--horizon", "-hz", type=int, help="Horizon de prédiction (nombre de points)")
    parser.add_argument("--config", "-c", help="Fichier JSON de configuration")
    
    args = parser.parse_args()
    
    # Charger la configuration personnalisée si spécifiée
    config = None
    if args.config:
        with open(args.config, 'r', encoding='utf-8') as f:
            config = json.load(f)
    
    # Charger les métriques
    metrics = load_metrics_from_json(args.input)
    
    # Initialiser le prédicteur
    predictor = PerformancePredictor(config)
    
    # Exécuter l'action demandée
    if args.action == "train":
        results = predictor.train(metrics, force=args.force)
    elif args.action == "predict":
        results = predictor.predict(metrics, horizon=args.horizon)
    elif args.action == "anomalies":
        results = predictor.detect_anomalies(metrics)
    elif args.action == "trends":
        results = predictor.analyze_trends(metrics)
    
    # Afficher les résultats
    print(json.dumps(results, indent=2))
    
    # Sauvegarder les résultats si un fichier de sortie est spécifié
    if args.output:
        save_predictions_to_json(results, args.output)
