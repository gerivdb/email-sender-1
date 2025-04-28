#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Génère un tableau de bord HTML pour suivre l'évolution des performances.
"""

import os
import json
import datetime
import math
from pathlib import Path

def main():
    """Fonction principale."""
    # Définir le chemin de sortie
    output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "PerformanceDashboard.html")

    # Créer le répertoire parent s'il n'existe pas
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Créer des données de démonstration
    demo_data = {
        "Tri": {
            "Dates": ["2025-04-01", "2025-04-02", "2025-04-03", "2025-04-04", "2025-04-05", "2025-04-06", "2025-04-07", "2025-04-08", "2025-04-09", "2025-04-10", "2025-04-11"],
            "Temps": [120, 118, 115, 110, 105, 102, 98, 95, 92, 90, 85],
            "Moyenne": 102.7,
            "Min": 85,
            "Max": 120,
            "Tendance": -29.2
        },
        "Filtrage": {
            "Dates": ["2025-04-01", "2025-04-02", "2025-04-03", "2025-04-04", "2025-04-05", "2025-04-06", "2025-04-07", "2025-04-08", "2025-04-09", "2025-04-10", "2025-04-11"],
            "Temps": [85, 82, 80, 79, 77, 75, 74, 72, 70, 68, 65],
            "Moyenne": 75.2,
            "Min": 65,
            "Max": 85,
            "Tendance": -23.5
        },
        "Agrégation": {
            "Dates": ["2025-04-01", "2025-04-02", "2025-04-03", "2025-04-04", "2025-04-05", "2025-04-06", "2025-04-07", "2025-04-08", "2025-04-09", "2025-04-10", "2025-04-11"],
            "Temps": [150, 148, 145, 142, 140, 138, 135, 132, 130, 128, 125],
            "Moyenne": 137.5,
            "Min": 125,
            "Max": 150,
            "Tendance": -16.7
        },
        "Traitement parallèle": {
            "Dates": ["2025-04-01", "2025-04-02", "2025-04-03", "2025-04-04", "2025-04-05", "2025-04-06", "2025-04-07", "2025-04-08", "2025-04-09", "2025-04-10", "2025-04-11"],
            "Temps": [200, 180, 160, 150, 140, 130, 120, 110, 100, 90, 80],
            "Moyenne": 132.7,
            "Min": 80,
            "Max": 200,
            "Tendance": -60.0
        }
    }

    # Générer le HTML du tableau de bord
    html = generate_dashboard_html(demo_data)

    # Sauvegarder le tableau de bord
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"Tableau de bord généré : {output_path}")

    # Ouvrir le tableau de bord dans le navigateur par défaut
    os.startfile(output_path)

def generate_dashboard_html(data):
    """Génère le HTML du tableau de bord."""
    now = datetime.datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    count = len(data)

    html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tableau de bord des performances</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }}
        h1, h2, h3 {{
            color: #0078D4;
        }}
        .dashboard {{
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(600px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }}
        .card {{
            background-color: #f5f5f5;
            border-radius: 5px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }}
        .chart-container {{
            width: 100%;
            height: 300px;
            margin-bottom: 20px;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }}
        th, td {{
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }}
        th {{
            background-color: #0078D4;
            color: white;
        }}
        tr:nth-child(even) {{
            background-color: #f2f2f2;
        }}
        .trend-positive {{
            color: green;
        }}
        .trend-negative {{
            color: red;
        }}
        .trend-neutral {{
            color: gray;
        }}
        .summary {{
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }}
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Tableau de bord des performances</h1>
    <p>Date de génération : {now}</p>

    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre de fonctions suivies : {count}</p>
        <p>Période d'analyse : 01/04/2025 - 11/04/2025</p>
        <p>Amélioration moyenne des performances : 32.4%</p>
    </div>

    <div class="dashboard">"""

    for name, data_item in data.items():
        trend_class = "trend-neutral"
        trend_symbol = "→"

        if data_item["Tendance"] < -5:
            trend_class = "trend-positive"
            trend_symbol = "↓"
        elif data_item["Tendance"] > 5:
            trend_class = "trend-negative"
            trend_symbol = "↑"

        name_id = name.replace(" ", "_")
        dates_count = len(data_item["Dates"])
        moyenne = data_item["Moyenne"]
        min_val = data_item["Min"]
        max_val = data_item["Max"]
        tendance = data_item["Tendance"]

        html += f"""        <div class="card">
            <h2>{name}</h2>
            <div class="chart-container">
                <canvas id="chart_{name_id}"></canvas>
            </div>
            <table>
                <tr>
                    <th>Métrique</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Nombre de mesures</td>
                    <td>{dates_count}</td>
                </tr>
                <tr>
                    <td>Temps moyen</td>
                    <td>{moyenne:.2f} ms</td>
                </tr>
                <tr>
                    <td>Temps min/max</td>
                    <td>{min_val} / {max_val} ms</td>
                </tr>
                <tr>
                    <td>Tendance</td>
                    <td class="{trend_class}">{trend_symbol} {tendance:.2f}%</td>
                </tr>
            </table>
        </div>
"""

    html += """    </div>

    <script>
"""

    for name, data_item in data.items():
        name_id = name.replace(" ", "_")
        dates_json = json.dumps(data_item["Dates"])
        temps_json = json.dumps(data_item["Temps"])

        html += f"""        // Graphique pour {name}
        const ctx_{name_id} = document.getElementById('chart_{name_id}').getContext('2d');
        new Chart(ctx_{name_id}, {{
            type: 'line',
            data: {{
                labels: {dates_json},
                datasets: [{{
                    label: '{name}',
                    data: {temps_json},
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1,
                    fill: false
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                scales: {{
                    y: {{
                        beginAtZero: false,
                        title: {{
                            display: true,
                            text: 'Temps d\\'exécution (ms)'
                        }}
                    }},
                    x: {{
                        title: {{
                            display: true,
                            text: 'Date'
                        }}
                    }}
                }}
            }}
        }});
"""

    html += """    </script>
</body>
</html>
"""

    return html

if __name__ == "__main__":
    main()
