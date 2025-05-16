#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant des outils pour l'analyse de performance.

Ce module fournit des outils pour analyser les performances des applications,
mesurer les temps d'exécution, identifier les goulots d'étranglement, etc.
"""

import os
import sys
import time
import json
import statistics
from typing import Dict, Any, Optional, List, Callable, Union
from pathlib import Path
from datetime import datetime

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_core.tools import BaseTool, tool

class PerformanceAnalysisTools:
    """Classe contenant des outils pour l'analyse de performance."""
    
    # Stockage des mesures de performance
    _performance_data = {
        "function_timings": {},
        "endpoint_timings": {},
        "custom_metrics": {}
    }
    
    @tool("measure_function_performance")
    def measure_function_performance(function_name: str, iterations: int = 10) -> Dict[str, Any]:
        """
        Mesure les performances d'une fonction en l'exécutant plusieurs fois.
        
        Args:
            function_name: Nom de la fonction à mesurer (doit être dans le namespace global)
            iterations: Nombre d'itérations (défaut: 10)
            
        Returns:
            Dictionnaire contenant les résultats de la mesure
        """
        try:
            # Vérifier si la fonction existe dans le namespace global
            if function_name not in globals():
                return {"error": f"La fonction '{function_name}' n'existe pas dans le namespace global"}
            
            function = globals()[function_name]
            
            if not callable(function):
                return {"error": f"'{function_name}' n'est pas une fonction"}
            
            # Mesurer les performances
            timings = []
            for i in range(iterations):
                start_time = time.time()
                function()
                end_time = time.time()
                execution_time = (end_time - start_time) * 1000  # en millisecondes
                timings.append(execution_time)
            
            # Calculer les statistiques
            avg_time = statistics.mean(timings)
            min_time = min(timings)
            max_time = max(timings)
            median_time = statistics.median(timings)
            stdev_time = statistics.stdev(timings) if len(timings) > 1 else 0
            
            # Stocker les résultats
            result = {
                "function_name": function_name,
                "iterations": iterations,
                "avg_time_ms": avg_time,
                "min_time_ms": min_time,
                "max_time_ms": max_time,
                "median_time_ms": median_time,
                "stdev_ms": stdev_time,
                "timestamp": datetime.now().isoformat()
            }
            
            # Sauvegarder dans le stockage
            PerformanceAnalysisTools._performance_data["function_timings"][function_name] = result
            
            return result
        except Exception as e:
            return {"error": str(e)}
    
    @tool("measure_endpoint_performance")
    def measure_endpoint_performance(url: str, method: str = "GET", iterations: int = 5, timeout: int = 10) -> Dict[str, Any]:
        """
        Mesure les performances d'un endpoint HTTP en effectuant plusieurs requêtes.
        
        Args:
            url: URL de l'endpoint
            method: Méthode HTTP (défaut: GET)
            iterations: Nombre d'itérations (défaut: 5)
            timeout: Timeout en secondes (défaut: 10)
            
        Returns:
            Dictionnaire contenant les résultats de la mesure
        """
        try:
            import requests
            
            # Mesurer les performances
            timings = []
            status_codes = []
            content_lengths = []
            errors = []
            
            for i in range(iterations):
                try:
                    start_time = time.time()
                    response = requests.request(
                        method=method,
                        url=url,
                        timeout=timeout
                    )
                    end_time = time.time()
                    
                    execution_time = (end_time - start_time) * 1000  # en millisecondes
                    timings.append(execution_time)
                    status_codes.append(response.status_code)
                    content_lengths.append(len(response.content))
                except Exception as e:
                    errors.append(str(e))
            
            # Calculer les statistiques
            if timings:
                avg_time = statistics.mean(timings)
                min_time = min(timings)
                max_time = max(timings)
                median_time = statistics.median(timings)
                stdev_time = statistics.stdev(timings) if len(timings) > 1 else 0
            else:
                avg_time = min_time = max_time = median_time = stdev_time = 0
            
            # Stocker les résultats
            result = {
                "url": url,
                "method": method,
                "iterations": iterations,
                "successful_requests": len(timings),
                "failed_requests": len(errors),
                "avg_time_ms": avg_time,
                "min_time_ms": min_time,
                "max_time_ms": max_time,
                "median_time_ms": median_time,
                "stdev_ms": stdev_time,
                "status_codes": status_codes,
                "avg_content_length": statistics.mean(content_lengths) if content_lengths else 0,
                "errors": errors,
                "timestamp": datetime.now().isoformat()
            }
            
            # Sauvegarder dans le stockage
            endpoint_key = f"{method}:{url}"
            PerformanceAnalysisTools._performance_data["endpoint_timings"][endpoint_key] = result
            
            return result
        except Exception as e:
            return {"error": str(e)}
    
    @tool("analyze_performance_data")
    def analyze_performance_data() -> Dict[str, Any]:
        """
        Analyse les données de performance collectées.
        
        Returns:
            Dictionnaire contenant l'analyse des données de performance
        """
        try:
            data = PerformanceAnalysisTools._performance_data
            
            # Analyser les données de performance des fonctions
            function_analysis = {}
            for function_name, timing_data in data["function_timings"].items():
                function_analysis[function_name] = {
                    "avg_time_ms": timing_data["avg_time_ms"],
                    "calls": timing_data["iterations"],
                    "last_measured": timing_data["timestamp"]
                }
            
            # Analyser les données de performance des endpoints
            endpoint_analysis = {}
            for endpoint_key, timing_data in data["endpoint_timings"].items():
                endpoint_analysis[endpoint_key] = {
                    "avg_time_ms": timing_data["avg_time_ms"],
                    "success_rate": timing_data["successful_requests"] / timing_data["iterations"] * 100,
                    "calls": timing_data["iterations"],
                    "last_measured": timing_data["timestamp"]
                }
            
            # Analyser les métriques personnalisées
            custom_metrics_analysis = {}
            for metric_name, metric_data in data["custom_metrics"].items():
                if isinstance(metric_data, list) and metric_data:
                    custom_metrics_analysis[metric_name] = {
                        "avg_value": statistics.mean(metric_data),
                        "min_value": min(metric_data),
                        "max_value": max(metric_data),
                        "count": len(metric_data)
                    }
                else:
                    custom_metrics_analysis[metric_name] = {
                        "value": metric_data,
                        "type": type(metric_data).__name__
                    }
            
            return {
                "function_analysis": function_analysis,
                "endpoint_analysis": endpoint_analysis,
                "custom_metrics_analysis": custom_metrics_analysis,
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {"error": str(e)}
    
    @tool("record_custom_metric")
    def record_custom_metric(metric_name: str, value: Union[int, float, str, bool, List[Union[int, float]]]) -> Dict[str, Any]:
        """
        Enregistre une métrique personnalisée.
        
        Args:
            metric_name: Nom de la métrique
            value: Valeur de la métrique (nombre, chaîne, booléen ou liste de nombres)
            
        Returns:
            Dictionnaire confirmant l'enregistrement
        """
        try:
            # Stocker la métrique
            if metric_name in PerformanceAnalysisTools._performance_data["custom_metrics"]:
                # Si la métrique existe déjà et est une liste, ajouter la nouvelle valeur
                if isinstance(PerformanceAnalysisTools._performance_data["custom_metrics"][metric_name], list):
                    if isinstance(value, (int, float)):
                        PerformanceAnalysisTools._performance_data["custom_metrics"][metric_name].append(value)
                    else:
                        # Si la nouvelle valeur n'est pas un nombre, remplacer la métrique
                        PerformanceAnalysisTools._performance_data["custom_metrics"][metric_name] = value
                else:
                    # Si la métrique existe mais n'est pas une liste, la remplacer
                    PerformanceAnalysisTools._performance_data["custom_metrics"][metric_name] = value
            else:
                # Si la métrique n'existe pas, la créer
                PerformanceAnalysisTools._performance_data["custom_metrics"][metric_name] = value
            
            return {
                "status": "success",
                "metric_name": metric_name,
                "value": value,
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {"error": str(e)}
    
    @tool("clear_performance_data")
    def clear_performance_data() -> Dict[str, Any]:
        """
        Efface toutes les données de performance collectées.
        
        Returns:
            Dictionnaire confirmant l'effacement
        """
        try:
            # Sauvegarder le nombre d'entrées avant effacement
            function_count = len(PerformanceAnalysisTools._performance_data["function_timings"])
            endpoint_count = len(PerformanceAnalysisTools._performance_data["endpoint_timings"])
            metric_count = len(PerformanceAnalysisTools._performance_data["custom_metrics"])
            
            # Effacer les données
            PerformanceAnalysisTools._performance_data = {
                "function_timings": {},
                "endpoint_timings": {},
                "custom_metrics": {}
            }
            
            return {
                "status": "success",
                "cleared_data": {
                    "function_timings": function_count,
                    "endpoint_timings": endpoint_count,
                    "custom_metrics": metric_count
                },
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {"error": str(e)}
