# Generate-RoadmapVisualization.py
# Script pour générer des visualisations graphiques des roadmaps
# Version: 1.0
# Date: 2025-05-15

import os
import json
import re
import logging
import argparse
from typing import List, Dict, Any, Optional, Tuple
import numpy as np
from datetime import datetime

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

try:
    import matplotlib.pyplot as plt
    import networkx as nx
    from pyvis.network import Network
except ImportError:
    logger.error("Dépendances manquantes. Installez-les avec: pip install matplotlib networkx pyvis")
    exit(1)

class RoadmapVisualizer:
    """Classe pour générer des visualisations graphiques des roadmaps"""
    
    def __init__(self, output_dir: str = "projet/roadmaps/analysis/visualizations"):
        """Initialise le visualiseur de roadmaps
        
        Args:
            output_dir: Dossier de sortie pour les visualisations
        """
        self.output_dir = output_dir
        
        # Créer le dossier de sortie s'il n'existe pas
        os.makedirs(output_dir, exist_ok=True)
    
    def parse_markdown(self, file_path: str) -> Dict[str, Any]:
        """Parse un fichier markdown de roadmap
        
        Args:
            file_path: Chemin vers le fichier markdown
            
        Returns:
            Dictionnaire contenant la structure de la roadmap
        """
        logger.info(f"Parsing du fichier {file_path}...")
        
        # Lire le contenu du fichier
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Extraire le titre
        title_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
        title = title_match.group(1).strip() if title_match else os.path.basename(file_path)
        
        # Extraire les sections et les tâches
        sections = []
        tasks = []
        
        lines = content.split("\n")
        current_section = None
        current_path = []
        
        for i, line in enumerate(lines):
            # Détecter les en-têtes
            header_match = re.match(r"^(#+)\s+(.+)$", line)
            if header_match:
                level = len(header_match.group(1))
                section_title = header_match.group(2).strip()
                
                # Mettre à jour le chemin de navigation
                current_path = current_path[:level-1] + [section_title]
                
                if level == 2:  # Sections principales (##)
                    current_section = {
                        "title": section_title,
                        "level": level,
                        "path": "/".join(current_path),
                        "line": i + 1
                    }
                    sections.append(current_section)
            
            # Détecter les tâches
            task_match = re.match(r"\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$", line)
            if task_match:
                completed = task_match.group(1).lower() == "x"
                task_id = task_match.group(2)
                task_text = task_match.group(3).strip()
                
                # Calculer le niveau d'indentation
                indent_match = re.match(r"^(\s*)", line)
                indent = len(indent_match.group(1)) if indent_match else 0
                indent_level = indent // 2
                
                task = {
                    "text": task_text,
                    "completed": completed,
                    "id": task_id,
                    "indent_level": indent_level,
                    "section": current_section["title"] if current_section else None,
                    "path": "/".join(current_path),
                    "line": i + 1
                }
                tasks.append(task)
        
        return {
            "title": title,
            "file_path": file_path,
            "sections": sections,
            "tasks": tasks
        }
    
    def generate_task_graph(self, roadmap: Dict[str, Any], output_path: str) -> None:
        """Génère un graphe des tâches
        
        Args:
            roadmap: Dictionnaire contenant la structure de la roadmap
            output_path: Chemin vers le fichier de sortie
        """
        logger.info(f"Génération du graphe des tâches pour {roadmap['title']}...")
        
        # Créer un graphe dirigé
        G = nx.DiGraph()
        
        # Ajouter les sections comme nœuds
        for section in roadmap["sections"]:
            G.add_node(section["title"], type="section", path=section["path"])
        
        # Ajouter les tâches comme nœuds
        task_nodes = {}
        for task in roadmap["tasks"]:
            node_id = task["id"] if task["id"] else f"task_{task['line']}"
            task_nodes[node_id] = task
            G.add_node(node_id, type="task", text=task["text"], completed=task["completed"], path=task["path"])
            
            # Ajouter une arête entre la section et la tâche
            if task["section"]:
                G.add_edge(task["section"], node_id)
        
        # Ajouter des arêtes entre les tâches parentes et enfants
        for task in roadmap["tasks"]:
            node_id = task["id"] if task["id"] else f"task_{task['line']}"
            
            # Trouver la tâche parente
            if task["indent_level"] > 0:
                # Parcourir les tâches précédentes pour trouver la tâche parente
                for i in range(len(roadmap["tasks"]) - 1, -1, -1):
                    prev_task = roadmap["tasks"][i]
                    if prev_task["line"] < task["line"] and prev_task["indent_level"] == task["indent_level"] - 1:
                        parent_id = prev_task["id"] if prev_task["id"] else f"task_{prev_task['line']}"
                        G.add_edge(parent_id, node_id)
                        break
        
        # Créer un réseau interactif
        net = Network(height="800px", width="100%", directed=True)
        
        # Ajouter les nœuds et les arêtes
        for node in G.nodes():
            node_data = G.nodes[node]
            if node_data["type"] == "section":
                net.add_node(node, label=node, title=node_data["path"], color="#6E9CD2", shape="box", font={"size": 20})
            else:
                color = "#4CAF50" if node_data["completed"] else "#F44336"
                net.add_node(node, label=node_data["text"], title=node_data["path"], color=color, shape="ellipse")
        
        for edge in G.edges():
            net.add_edge(edge[0], edge[1])
        
        # Enregistrer le graphe
        net.save_graph(output_path)
        logger.info(f"Graphe des tâches enregistré dans {output_path}")
    
    def generate_completion_chart(self, roadmap: Dict[str, Any], output_path: str) -> None:
        """Génère un graphique de complétion des tâches par section
        
        Args:
            roadmap: Dictionnaire contenant la structure de la roadmap
            output_path: Chemin vers le fichier de sortie
        """
        logger.info(f"Génération du graphique de complétion pour {roadmap['title']}...")
        
        # Calculer le taux de complétion par section
        section_stats = {}
        for task in roadmap["tasks"]:
            section = task["section"]
            if section not in section_stats:
                section_stats[section] = {"total": 0, "completed": 0}
            
            section_stats[section]["total"] += 1
            if task["completed"]:
                section_stats[section]["completed"] += 1
        
        # Préparer les données pour le graphique
        sections = []
        completion_rates = []
        
        for section, stats in section_stats.items():
            if section and stats["total"] > 0:
                sections.append(section)
                completion_rate = (stats["completed"] / stats["total"]) * 100
                completion_rates.append(completion_rate)
        
        # Créer le graphique
        plt.figure(figsize=(12, 8))
        bars = plt.barh(sections, completion_rates, color="#6E9CD2")
        
        # Ajouter les pourcentages sur les barres
        for i, bar in enumerate(bars):
            plt.text(bar.get_width() + 1, bar.get_y() + bar.get_height()/2, f"{completion_rates[i]:.1f}%", va="center")
        
        plt.xlabel("Taux de complétion (%)")
        plt.title(f"Taux de complétion des tâches par section - {roadmap['title']}")
        plt.xlim(0, 105)  # Limiter l'axe x à 105% pour laisser de la place aux étiquettes
        plt.tight_layout()
        
        # Enregistrer le graphique
        plt.savefig(output_path)
        logger.info(f"Graphique de complétion enregistré dans {output_path}")
        plt.close()
    
    def generate_task_distribution_chart(self, roadmap: Dict[str, Any], output_path: str) -> None:
        """Génère un graphique de distribution des tâches par niveau d'indentation
        
        Args:
            roadmap: Dictionnaire contenant la structure de la roadmap
            output_path: Chemin vers le fichier de sortie
        """
        logger.info(f"Génération du graphique de distribution des tâches pour {roadmap['title']}...")
        
        # Calculer la distribution des tâches par niveau d'indentation
        indent_stats = {}
        for task in roadmap["tasks"]:
            indent_level = task["indent_level"]
            if indent_level not in indent_stats:
                indent_stats[indent_level] = {"total": 0, "completed": 0}
            
            indent_stats[indent_level]["total"] += 1
            if task["completed"]:
                indent_stats[indent_level]["completed"] += 1
        
        # Préparer les données pour le graphique
        indent_levels = sorted(indent_stats.keys())
        total_tasks = [indent_stats[level]["total"] for level in indent_levels]
        completed_tasks = [indent_stats[level]["completed"] for level in indent_levels]
        
        # Créer le graphique
        plt.figure(figsize=(10, 6))
        
        x = np.arange(len(indent_levels))
        width = 0.35
        
        plt.bar(x - width/2, total_tasks, width, label="Total", color="#6E9CD2")
        plt.bar(x + width/2, completed_tasks, width, label="Terminées", color="#4CAF50")
        
        plt.xlabel("Niveau d'indentation")
        plt.ylabel("Nombre de tâches")
        plt.title(f"Distribution des tâches par niveau d'indentation - {roadmap['title']}")
        plt.xticks(x, [f"Niveau {level}" for level in indent_levels])
        plt.legend()
        plt.tight_layout()
        
        # Enregistrer le graphique
        plt.savefig(output_path)
        logger.info(f"Graphique de distribution des tâches enregistré dans {output_path}")
        plt.close()
    
    def generate_visualizations(self, file_path: str) -> None:
        """Génère toutes les visualisations pour un fichier de roadmap
        
        Args:
            file_path: Chemin vers le fichier markdown
        """
        # Parser le fichier markdown
        roadmap = self.parse_markdown(file_path)
        
        # Créer un sous-dossier pour les visualisations de ce fichier
        file_name = os.path.splitext(os.path.basename(file_path))[0]
        output_subdir = os.path.join(self.output_dir, file_name)
        os.makedirs(output_subdir, exist_ok=True)
        
        # Générer le graphe des tâches
        task_graph_path = os.path.join(output_subdir, "task_graph.html")
        self.generate_task_graph(roadmap, task_graph_path)
        
        # Générer le graphique de complétion
        completion_chart_path = os.path.join(output_subdir, "completion_chart.png")
        self.generate_completion_chart(roadmap, completion_chart_path)
        
        # Générer le graphique de distribution des tâches
        distribution_chart_path = os.path.join(output_subdir, "task_distribution_chart.png")
        self.generate_task_distribution_chart(roadmap, distribution_chart_path)
        
        # Générer un fichier index.html
        index_path = os.path.join(output_subdir, "index.html")
        with open(index_path, "w", encoding="utf-8") as f:
            f.write(f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Visualisations de {roadmap['title']}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px; }}
        h1 {{ color: #333; }}
        .container {{ display: flex; flex-wrap: wrap; }}
        .chart {{ margin: 10px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }}
        .chart h2 {{ color: #666; }}
        img {{ max-width: 100%; }}
    </style>
</head>
<body>
    <h1>Visualisations de {roadmap['title']}</h1>
    <p>Généré le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    
    <div class="container">
        <div class="chart">
            <h2>Graphe des tâches</h2>
            <iframe src="task_graph.html" width="800" height="600" frameborder="0"></iframe>
        </div>
        
        <div class="chart">
            <h2>Taux de complétion par section</h2>
            <img src="completion_chart.png" alt="Taux de complétion par section">
        </div>
        
        <div class="chart">
            <h2>Distribution des tâches par niveau d'indentation</h2>
            <img src="task_distribution_chart.png" alt="Distribution des tâches par niveau d'indentation">
        </div>
    </div>
</body>
</html>""")
        
        logger.info(f"Fichier index.html généré dans {index_path}")
        logger.info(f"Toutes les visualisations ont été générées pour {file_path}")

def main():
    """Fonction principale"""
    parser = argparse.ArgumentParser(description="Génère des visualisations graphiques des roadmaps")
    parser.add_argument("--file", "-f", required=True, help="Chemin vers le fichier markdown de roadmap")
    parser.add_argument("--output-dir", "-o", default="projet/roadmaps/analysis/visualizations", help="Dossier de sortie pour les visualisations")
    
    args = parser.parse_args()
    
    # Vérifier si le fichier existe
    if not os.path.isfile(args.file):
        logger.error(f"Le fichier {args.file} n'existe pas.")
        exit(1)
    
    # Créer le visualiseur
    visualizer = RoadmapVisualizer(output_dir=args.output_dir)
    
    # Générer les visualisations
    visualizer.generate_visualizations(args.file)

if __name__ == "__main__":
    main()
