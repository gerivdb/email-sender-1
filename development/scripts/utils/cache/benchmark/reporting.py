#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de génération de rapports pour les benchmarks du système de cache.

Ce module fournit les fonctions nécessaires pour générer des rapports
détaillés sur les performances du système de cache.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import json
import time
from pathlib import Path
from typing import Dict, List, Any, Optional, Union


def generate_report(results: Dict[str, Any], config: Dict[str, Any]) -> str:
    """
    Génère un rapport détaillé des résultats du benchmark.
    
    Args:
        results (Dict[str, Any]): Résultats du benchmark.
        config (Dict[str, Any]): Configuration du benchmark.
        
    Returns:
        str: Chemin du fichier de rapport généré.
    """
    # Créer un timestamp pour le rapport
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    
    # Créer le répertoire de sortie s'il n'existe pas
    output_dir = config.get("output_dir", os.path.join(
        os.path.dirname(os.path.abspath(__file__)), 'reports'
    ))
    os.makedirs(output_dir, exist_ok=True)
    
    # Créer le rapport
    report = {
        "timestamp": timestamp,
        "config": config,
        "results": results,
        "summary": generate_summary(results, config)
    }
    
    # Enregistrer le rapport
    report_file = os.path.join(
        output_dir,
        f"cache_benchmark_{config['cache_type']}_{config['benchmark_type']}_{timestamp}.json"
    )
    
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2)
    
    # Générer un rapport HTML si possible
    try:
        html_file = generate_html_report(report, report_file)
        print(f"Rapport HTML généré: {html_file}")
    except Exception as e:
        print(f"Erreur lors de la génération du rapport HTML: {e}")
    
    return report_file


def generate_summary(results: Dict[str, Any], config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Génère un résumé des résultats du benchmark.
    
    Args:
        results (Dict[str, Any]): Résultats du benchmark.
        config (Dict[str, Any]): Configuration du benchmark.
        
    Returns:
        Dict[str, Any]: Résumé des résultats.
    """
    summary = {
        "test_id": config["test_id"],
        "cache_type": config["cache_type"],
        "benchmark_type": config["benchmark_type"],
        "duration_seconds": results["duration_seconds"],
        "total_operations": results["operations"]["total"],
        "operations_per_second": results["throughput"]["operations_per_second"],
        "latency": {},
        "hit_ratio": {},
        "memory_usage": {},
        "success": False,
        "recommendations": []
    }
    
    # Ajouter les statistiques de latence
    for operation in ["get", "set", "delete"]:
        if results["latencies"][operation]["avg"] is not None:
            summary["latency"][operation] = {
                "avg_ms": results["latencies"][operation]["avg"],
                "p95_ms": results["latencies"][operation]["p95"],
                "p99_ms": results["latencies"][operation]["p99"]
            }
    
    # Ajouter les statistiques du taux de succès
    if results["hit_ratio"]["avg"] is not None:
        summary["hit_ratio"] = {
            "avg": results["hit_ratio"]["avg"],
            "min": results["hit_ratio"]["min"],
            "max": results["hit_ratio"]["max"]
        }
    
    # Ajouter les statistiques d'utilisation de la mémoire
    if results["memory_usage"]["avg"] is not None:
        summary["memory_usage"] = {
            "avg_mb": results["memory_usage"]["avg"],
            "max_mb": results["memory_usage"]["max"]
        }
    
    # Déterminer si le test est réussi
    success = True
    
    # Vérifier le taux de succès
    if "expected_hit_ratio" in config and results["hit_ratio"]["avg"] is not None:
        if results["hit_ratio"]["avg"] < config["expected_hit_ratio"]:
            success = False
            summary["recommendations"].append(
                f"Le taux de succès ({results['hit_ratio']['avg']:.2%}) est inférieur "
                f"à la valeur attendue ({config['expected_hit_ratio']:.2%}). "
                "Envisagez d'augmenter la capacité du cache ou d'optimiser la stratégie d'éviction."
            )
    
    # Vérifier la latence
    if "max_latency_ms" in config:
        for operation in ["get", "set", "delete"]:
            if (results["latencies"][operation]["avg"] is not None and
                    results["latencies"][operation]["avg"] > config["max_latency_ms"]):
                success = False
                summary["recommendations"].append(
                    f"La latence moyenne pour l'opération {operation} "
                    f"({results['latencies'][operation]['avg']:.2f} ms) est supérieure "
                    f"à la valeur maximale acceptable ({config['max_latency_ms']:.2f} ms). "
                    "Envisagez d'optimiser l'implémentation du cache ou de réduire la concurrence."
                )
    
    # Vérifier l'utilisation de la mémoire
    if "max_memory_mb" in config and results["memory_usage"]["max"] is not None:
        if results["memory_usage"]["max"] > config["max_memory_mb"]:
            success = False
            summary["recommendations"].append(
                f"L'utilisation maximale de la mémoire ({results['memory_usage']['max']:.2f} Mo) "
                f"est supérieure à la valeur maximale acceptable ({config['max_memory_mb']:.2f} Mo). "
                "Envisagez de réduire la capacité du cache ou d'optimiser la représentation des données."
            )
    
    # Ajouter des recommandations générales
    if success and not summary["recommendations"]:
        summary["recommendations"].append(
            "Les performances du cache sont bonnes. Aucune optimisation n'est nécessaire."
        )
    
    summary["success"] = success
    
    return summary


def generate_html_report(report: Dict[str, Any], json_file: str) -> str:
    """
    Génère un rapport HTML à partir du rapport JSON.
    
    Args:
        report (Dict[str, Any]): Rapport au format JSON.
        json_file (str): Chemin du fichier JSON.
        
    Returns:
        str: Chemin du fichier HTML généré.
    """
    # Créer le chemin du fichier HTML
    html_file = json_file.replace('.json', '.html')
    
    # Extraire les données du rapport
    config = report["config"]
    results = report["results"]
    summary = report["summary"]
    
    # Créer le contenu HTML
    html_content = f"""<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de benchmark - {config['cache_type']} - {config['benchmark_type']}</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }}
        h1, h2, h3 {{
            color: #2c3e50;
        }}
        .success {{
            color: #27ae60;
        }}
        .failure {{
            color: #e74c3c;
        }}
        table {{
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }}
        th, td {{
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }}
        th {{
            background-color: #f2f2f2;
        }}
        tr:nth-child(even) {{
            background-color: #f9f9f9;
        }}
        .recommendation {{
            background-color: #f8f9fa;
            border-left: 4px solid #2980b9;
            padding: 10px;
            margin-bottom: 10px;
        }}
        .chart-container {{
            width: 100%;
            height: 400px;
            margin-bottom: 20px;
        }}
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de benchmark - {config['cache_type']} - {config['benchmark_type']}</h1>
    
    <h2>Résumé</h2>
    <p>
        <strong>Statut:</strong> 
        <span class="{'success' if summary['success'] else 'failure'}">
            {'Succès' if summary['success'] else 'Échec'}
        </span>
    </p>
    <p><strong>Date:</strong> {report['timestamp']}</p>
    <p><strong>Durée:</strong> {results['duration_seconds']:.2f} secondes</p>
    <p><strong>Opérations totales:</strong> {results['operations']['total']}</p>
    <p><strong>Débit:</strong> {results['throughput']['operations_per_second']:.2f} opérations/seconde</p>
    
    <h2>Configuration</h2>
    <table>
        <tr>
            <th>Paramètre</th>
            <th>Valeur</th>
        </tr>
        <tr>
            <td>Type de cache</td>
            <td>{config['cache_type']}</td>
        </tr>
        <tr>
            <td>Type de benchmark</td>
            <td>{config['benchmark_type']}</td>
        </tr>
        <tr>
            <td>Taille du jeu de données</td>
            <td>{config['dataset_size']} éléments</td>
        </tr>
        <tr>
            <td>Taille des valeurs</td>
            <td>{config['value_size']} octets</td>
        </tr>
        <tr>
            <td>Distribution des données</td>
            <td>{config['data_distribution']}</td>
        </tr>
        <tr>
            <td>Niveau de concurrence</td>
            <td>{config['concurrency_level']} threads</td>
        </tr>
    </table>
    
    <h2>Résultats détaillés</h2>
    
    <h3>Latence (ms)</h3>
    <table>
        <tr>
            <th>Opération</th>
            <th>Moyenne</th>
            <th>Min</th>
            <th>Max</th>
            <th>P50</th>
            <th>P95</th>
            <th>P99</th>
        </tr>
"""
    
    # Ajouter les données de latence
    for operation in ["get", "set", "delete"]:
        if results["latencies"][operation]["avg"] is not None:
            html_content += f"""
        <tr>
            <td>{operation.upper()}</td>
            <td>{results['latencies'][operation]['avg']:.2f}</td>
            <td>{results['latencies'][operation]['min']:.2f}</td>
            <td>{results['latencies'][operation]['max']:.2f}</td>
            <td>{results['latencies'][operation]['p50']:.2f}</td>
            <td>{results['latencies'][operation]['p95']:.2f}</td>
            <td>{results['latencies'][operation]['p99']:.2f}</td>
        </tr>"""
    
    html_content += """
    </table>
    
    <h3>Taux de succès du cache</h3>
"""
    
    # Ajouter les données du taux de succès
    if results["hit_ratio"]["avg"] is not None:
        html_content += f"""
    <p><strong>Moyenne:</strong> {results['hit_ratio']['avg']:.2%}</p>
    <p><strong>Min:</strong> {results['hit_ratio']['min']:.2%}</p>
    <p><strong>Max:</strong> {results['hit_ratio']['max']:.2%}</p>
"""
    else:
        html_content += """
    <p>Aucune donnée disponible sur le taux de succès.</p>
"""
    
    html_content += """
    <h3>Utilisation de la mémoire</h3>
"""
    
    # Ajouter les données d'utilisation de la mémoire
    if results["memory_usage"]["avg"] is not None:
        html_content += f"""
    <p><strong>Moyenne:</strong> {results['memory_usage']['avg']:.2f} Mo</p>
    <p><strong>Min:</strong> {results['memory_usage']['min']:.2f} Mo</p>
    <p><strong>Max:</strong> {results['memory_usage']['max']:.2f} Mo</p>
"""
    else:
        html_content += """
    <p>Aucune donnée disponible sur l'utilisation de la mémoire.</p>
"""
    
    html_content += """
    <h2>Recommandations</h2>
"""
    
    # Ajouter les recommandations
    for recommendation in summary["recommendations"]:
        html_content += f"""
    <div class="recommendation">
        <p>{recommendation}</p>
    </div>
"""
    
    html_content += """
    <script>
        // Code JavaScript pour les graphiques (à implémenter)
    </script>
</body>
</html>
"""
    
    # Enregistrer le fichier HTML
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    return html_file


def compare_reports(report_files: List[str]) -> Dict[str, Any]:
    """
    Compare plusieurs rapports de benchmark.
    
    Args:
        report_files (List[str]): Liste des chemins des fichiers de rapport.
        
    Returns:
        Dict[str, Any]: Résultats de la comparaison.
    """
    reports = []
    
    # Charger les rapports
    for file_path in report_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            reports.append(json.load(f))
    
    # Extraire les données à comparer
    comparison = {
        "timestamp": time.strftime("%Y%m%d-%H%M%S"),
        "reports": [r["config"]["test_id"] for r in reports],
        "throughput": {
            "labels": [r["config"]["cache_type"] for r in reports],
            "values": [r["results"]["throughput"]["operations_per_second"] for r in reports]
        },
        "latency": {
            "get": {
                "labels": [r["config"]["cache_type"] for r in reports],
                "values": [r["results"]["latencies"]["get"]["avg"] if r["results"]["latencies"]["get"]["avg"] is not None else 0 for r in reports]
            },
            "set": {
                "labels": [r["config"]["cache_type"] for r in reports],
                "values": [r["results"]["latencies"]["set"]["avg"] if r["results"]["latencies"]["set"]["avg"] is not None else 0 for r in reports]
            }
        },
        "hit_ratio": {
            "labels": [r["config"]["cache_type"] for r in reports],
            "values": [r["results"]["hit_ratio"]["avg"] if r["results"]["hit_ratio"]["avg"] is not None else 0 for r in reports]
        },
        "memory_usage": {
            "labels": [r["config"]["cache_type"] for r in reports],
            "values": [r["results"]["memory_usage"]["avg"] if r["results"]["memory_usage"]["avg"] is not None else 0 for r in reports]
        }
    }
    
    return comparison


if __name__ == "__main__":
    # Exemple d'utilisation
    # Créer un rapport fictif
    results = {
        "start_time": time.time() - 30,
        "end_time": time.time(),
        "duration_seconds": 30,
        "operations": {
            "total": 10000,
            "get": 8000,
            "set": 1500,
            "delete": 500
        },
        "latencies": {
            "get": {
                "avg": 1.5,
                "min": 0.5,
                "max": 10.0,
                "p50": 1.2,
                "p95": 3.0,
                "p99": 5.0
            },
            "set": {
                "avg": 2.0,
                "min": 1.0,
                "max": 15.0,
                "p50": 1.8,
                "p95": 4.0,
                "p99": 8.0
            },
            "delete": {
                "avg": 1.8,
                "min": 0.8,
                "max": 12.0,
                "p50": 1.5,
                "p95": 3.5,
                "p99": 6.0
            }
        },
        "hit_ratio": {
            "values": [0.75, 0.78, 0.80, 0.82],
            "avg": 0.79,
            "min": 0.75,
            "max": 0.82
        },
        "memory_usage": {
            "values": [50.0, 52.0, 55.0, 53.0],
            "avg": 52.5,
            "min": 50.0,
            "max": 55.0
        },
        "throughput": {
            "operations_per_second": 333.33
        }
    }
    
    config = {
        "test_id": "test_lru_throughput",
        "cache_type": "lru",
        "benchmark_type": "throughput",
        "dataset_size": 10000,
        "value_size": 1024,
        "data_distribution": "uniform",
        "operation_mix": {
            "get": 0.8,
            "set": 0.15,
            "delete": 0.05
        },
        "concurrency_level": 1,
        "duration_seconds": 30,
        "expected_hit_ratio": 0.7,
        "max_latency_ms": 5.0,
        "max_memory_mb": 100.0
    }
    
    # Générer le rapport
    report_file = generate_report(results, config)
    print(f"Rapport généré: {report_file}")
