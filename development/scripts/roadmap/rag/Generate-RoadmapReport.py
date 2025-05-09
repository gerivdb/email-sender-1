# Generate-RoadmapReport.py
# Script pour générer des rapports d'analyse sur les roadmaps
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
import matplotlib.pyplot as plt
from collections import Counter, defaultdict

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
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
except ImportError:
    logger.error("Dépendances manquantes. Installez-les avec: pip install qdrant-client matplotlib")
    exit(1)

# Configuration par défaut
DEFAULT_COLLECTION = "roadmaps"
DEFAULT_QDRANT_HOST = "localhost"
DEFAULT_QDRANT_PORT = 6333
DEFAULT_OUTPUT_DIR = "projet/roadmaps/reports"

class RoadmapReportGenerator:
    """Classe pour générer des rapports d'analyse sur les roadmaps"""
    
    def __init__(
        self,
        collection_name: str = DEFAULT_COLLECTION,
        qdrant_host: str = DEFAULT_QDRANT_HOST,
        qdrant_port: int = DEFAULT_QDRANT_PORT,
        output_dir: str = DEFAULT_OUTPUT_DIR
    ):
        """Initialise le générateur de rapports
        
        Args:
            collection_name: Nom de la collection Qdrant
            qdrant_host: Hôte du serveur Qdrant
            qdrant_port: Port du serveur Qdrant
            output_dir: Dossier de sortie pour les rapports
        """
        self.collection_name = collection_name
        self.qdrant_host = qdrant_host
        self.qdrant_port = qdrant_port
        self.output_dir = output_dir
        
        # Connexion à Qdrant
        logger.info(f"Connexion à Qdrant ({qdrant_host}:{qdrant_port})...")
        self.client = QdrantClient(host=qdrant_host, port=qdrant_port)
        
        # Créer le dossier de sortie s'il n'existe pas
        os.makedirs(output_dir, exist_ok=True)
    
    def get_all_tasks(self) -> List[Dict[str, Any]]:
        """Récupère toutes les tâches de la collection
        
        Returns:
            Liste de tâches
        """
        logger.info(f"Récupération de toutes les tâches de la collection {self.collection_name}...")
        
        # Récupérer toutes les tâches
        scroll_result = self.client.scroll(
            collection_name=self.collection_name,
            limit=10000  # Limite élevée pour récupérer toutes les tâches
        )
        
        # Extraire les payloads
        tasks = [point.payload for point in scroll_result[0]]
        
        logger.info(f"Récupéré {len(tasks)} tâches.")
        return tasks
    
    def generate_completion_report(
        self,
        output_path: str = None,
        filter_condition: Optional[Dict[str, Any]] = None
    ) -> str:
        """Génère un rapport sur le taux de complétion des tâches
        
        Args:
            output_path: Chemin vers le fichier de sortie
            filter_condition: Condition de filtrage pour Qdrant
            
        Returns:
            Chemin vers le fichier généré
        """
        logger.info("Génération du rapport de complétion...")
        
        # Récupérer toutes les tâches
        tasks = self.get_all_tasks()
        
        # Filtrer les tâches si nécessaire
        if filter_condition:
            # Implémenter le filtrage côté client (simplifié)
            filtered_tasks = []
            for task in tasks:
                match = True
                for key, value in filter_condition.items():
                    if key not in task or task[key] != value:
                        match = False
                        break
                if match:
                    filtered_tasks.append(task)
            tasks = filtered_tasks
            logger.info(f"Filtré à {len(tasks)} tâches.")
        
        # Calculer les statistiques de complétion
        total_tasks = len(tasks)
        completed_tasks = sum(1 for task in tasks if task.get("completed", False))
        completion_rate = (completed_tasks / total_tasks) * 100 if total_tasks > 0 else 0
        
        # Calculer les statistiques par fichier
        files_stats = defaultdict(lambda: {"total": 0, "completed": 0})
        for task in tasks:
            file_path = task.get("file_path", "Unknown")
            files_stats[file_path]["total"] += 1
            if task.get("completed", False):
                files_stats[file_path]["completed"] += 1
        
        # Calculer les taux de complétion par fichier
        for file_path, stats in files_stats.items():
            stats["completion_rate"] = (stats["completed"] / stats["total"]) * 100 if stats["total"] > 0 else 0
        
        # Trier les fichiers par taux de complétion
        sorted_files = sorted(files_stats.items(), key=lambda x: x[1]["completion_rate"], reverse=True)
        
        # Générer le graphique de complétion par fichier
        plt.figure(figsize=(12, 8))
        
        file_names = [os.path.basename(file_path) for file_path, _ in sorted_files[:10]]  # Top 10 fichiers
        completion_rates = [stats["completion_rate"] for _, stats in sorted_files[:10]]
        
        bars = plt.barh(file_names, completion_rates, color="#6E9CD2")
        
        # Ajouter les pourcentages sur les barres
        for i, bar in enumerate(bars):
            plt.text(bar.get_width() + 1, bar.get_y() + bar.get_height()/2, f"{completion_rates[i]:.1f}%", va="center")
        
        plt.xlabel("Taux de complétion (%)")
        plt.title("Taux de complétion des tâches par fichier")
        plt.xlim(0, 105)  # Limiter l'axe x à 105% pour laisser de la place aux étiquettes
        plt.tight_layout()
        
        # Enregistrer le graphique
        chart_path = os.path.join(self.output_dir, "completion_by_file.png")
        plt.savefig(chart_path)
        plt.close()
        
        # Générer le rapport
        report = f"""# Rapport de complétion des tâches

*Généré le {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*

## Statistiques globales

- **Nombre total de tâches :** {total_tasks}
- **Tâches terminées :** {completed_tasks}
- **Taux de complétion :** {completion_rate:.2f}%

## Taux de complétion par fichier

| Fichier | Tâches totales | Tâches terminées | Taux de complétion |
|---------|----------------|------------------|-------------------|
"""
        
        # Ajouter les statistiques par fichier
        for file_path, stats in sorted_files:
            file_name = os.path.basename(file_path)
            report += f"| {file_name} | {stats['total']} | {stats['completed']} | {stats['completion_rate']:.2f}% |\n"
        
        report += f"""
## Graphique de complétion par fichier

![Taux de complétion par fichier](completion_by_file.png)

---

*Ce rapport a été généré automatiquement par le système RAG de gestion des roadmaps.*
"""
        
        # Enregistrer le rapport
        if output_path is None:
            output_path = os.path.join(self.output_dir, "completion_report.md")
        
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(report)
        
        logger.info(f"Rapport de complétion généré dans {output_path}")
        return output_path
    
    def generate_priority_report(
        self,
        output_path: str = None,
        filter_condition: Optional[Dict[str, Any]] = None
    ) -> str:
        """Génère un rapport sur la distribution des priorités
        
        Args:
            output_path: Chemin vers le fichier de sortie
            filter_condition: Condition de filtrage pour Qdrant
            
        Returns:
            Chemin vers le fichier généré
        """
        logger.info("Génération du rapport de priorités...")
        
        # Récupérer toutes les tâches
        tasks = self.get_all_tasks()
        
        # Filtrer les tâches si nécessaire
        if filter_condition:
            # Implémenter le filtrage côté client (simplifié)
            filtered_tasks = []
            for task in tasks:
                match = True
                for key, value in filter_condition.items():
                    if key not in task or task[key] != value:
                        match = False
                        break
                if match:
                    filtered_tasks.append(task)
            tasks = filtered_tasks
            logger.info(f"Filtré à {len(tasks)} tâches.")
        
        # Calculer les statistiques de priorité
        priority_counts = Counter()
        for task in tasks:
            priority = task.get("priority", "Non définie")
            priority_counts[priority] += 1
        
        # Générer le graphique de distribution des priorités
        plt.figure(figsize=(10, 6))
        
        priorities = list(priority_counts.keys())
        counts = list(priority_counts.values())
        
        # Trier les priorités si elles sont numériques
        if all(p.isdigit() for p in priorities if p != "Non définie"):
            sorted_items = sorted(priority_counts.items(), key=lambda x: int(x[0]) if x[0].isdigit() else 999)
            priorities = [item[0] for item in sorted_items]
            counts = [item[1] for item in sorted_items]
        
        plt.bar(priorities, counts, color="#6E9CD2")
        
        plt.xlabel("Priorité")
        plt.ylabel("Nombre de tâches")
        plt.title("Distribution des tâches par priorité")
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # Enregistrer le graphique
        chart_path = os.path.join(self.output_dir, "priority_distribution.png")
        plt.savefig(chart_path)
        plt.close()
        
        # Générer le rapport
        report = f"""# Rapport de distribution des priorités

*Généré le {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*

## Statistiques globales

- **Nombre total de tâches :** {len(tasks)}

## Distribution des priorités

| Priorité | Nombre de tâches | Pourcentage |
|----------|------------------|-------------|
"""
        
        # Ajouter les statistiques par priorité
        total_tasks = len(tasks)
        for priority, count in priority_counts.most_common():
            percentage = (count / total_tasks) * 100 if total_tasks > 0 else 0
            report += f"| {priority} | {count} | {percentage:.2f}% |\n"
        
        report += f"""
## Graphique de distribution des priorités

![Distribution des tâches par priorité](priority_distribution.png)

---

*Ce rapport a été généré automatiquement par le système RAG de gestion des roadmaps.*
"""
        
        # Enregistrer le rapport
        if output_path is None:
            output_path = os.path.join(self.output_dir, "priority_report.md")
        
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(report)
        
        logger.info(f"Rapport de priorités généré dans {output_path}")
        return output_path
    
    def generate_progress_report(
        self,
        output_path: str = None,
        filter_condition: Optional[Dict[str, Any]] = None,
        time_period: str = "weekly"
    ) -> str:
        """Génère un rapport sur la progression des tâches
        
        Args:
            output_path: Chemin vers le fichier de sortie
            filter_condition: Condition de filtrage pour Qdrant
            time_period: Période de temps pour l'analyse (daily, weekly, monthly)
            
        Returns:
            Chemin vers le fichier généré
        """
        logger.info("Génération du rapport de progression...")
        
        # Récupérer toutes les tâches
        tasks = self.get_all_tasks()
        
        # Filtrer les tâches si nécessaire
        if filter_condition:
            # Implémenter le filtrage côté client (simplifié)
            filtered_tasks = []
            for task in tasks:
                match = True
                for key, value in filter_condition.items():
                    if key not in task or task[key] != value:
                        match = False
                        break
                if match:
                    filtered_tasks.append(task)
            tasks = filtered_tasks
            logger.info(f"Filtré à {len(tasks)} tâches.")
        
        # Calculer les statistiques de progression
        total_tasks = len(tasks)
        completed_tasks = sum(1 for task in tasks if task.get("completed", False))
        completion_rate = (completed_tasks / total_tasks) * 100 if total_tasks > 0 else 0
        
        # Simuler des données de progression dans le temps (à remplacer par des données réelles)
        # Dans une implémentation réelle, ces données proviendraient de l'historique des modifications
        dates = ["2025-05-01", "2025-05-08", "2025-05-15", "2025-05-22", "2025-05-29"]
        completion_rates = [20, 35, 50, 65, completion_rate]
        
        # Générer le graphique de progression
        plt.figure(figsize=(10, 6))
        
        plt.plot(dates, completion_rates, marker='o', linestyle='-', color="#6E9CD2")
        
        plt.xlabel("Date")
        plt.ylabel("Taux de complétion (%)")
        plt.title("Progression du taux de complétion des tâches")
        plt.xticks(rotation=45)
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        
        # Enregistrer le graphique
        chart_path = os.path.join(self.output_dir, "progress_chart.png")
        plt.savefig(chart_path)
        plt.close()
        
        # Générer le rapport
        report = f"""# Rapport de progression des tâches

*Généré le {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*

## Statistiques actuelles

- **Nombre total de tâches :** {total_tasks}
- **Tâches terminées :** {completed_tasks}
- **Taux de complétion actuel :** {completion_rate:.2f}%

## Progression dans le temps

| Date | Taux de complétion |
|------|-------------------|
"""
        
        # Ajouter les statistiques de progression
        for date, rate in zip(dates, completion_rates):
            report += f"| {date} | {rate:.2f}% |\n"
        
        report += f"""
## Graphique de progression

![Progression du taux de complétion](progress_chart.png)

---

*Ce rapport a été généré automatiquement par le système RAG de gestion des roadmaps.*
"""
        
        # Enregistrer le rapport
        if output_path is None:
            output_path = os.path.join(self.output_dir, "progress_report.md")
        
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(report)
        
        logger.info(f"Rapport de progression généré dans {output_path}")
        return output_path

def main():
    """Fonction principale"""
    parser = argparse.ArgumentParser(description="Génère des rapports d'analyse sur les roadmaps")
    parser.add_argument("--report-type", "-t", choices=["completion", "priority", "progress"], required=True, help="Type de rapport à générer")
    parser.add_argument("--filter-file", "-f", help="Fichier JSON contenant les filtres à appliquer")
    parser.add_argument("--output", "-o", help="Chemin vers le fichier de sortie")
    parser.add_argument("--collection", "-c", default=DEFAULT_COLLECTION, help=f"Nom de la collection Qdrant (défaut: {DEFAULT_COLLECTION})")
    parser.add_argument("--host", default=DEFAULT_QDRANT_HOST, help=f"Hôte du serveur Qdrant (défaut: {DEFAULT_QDRANT_HOST})")
    parser.add_argument("--port", type=int, default=DEFAULT_QDRANT_PORT, help=f"Port du serveur Qdrant (défaut: {DEFAULT_QDRANT_PORT})")
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR, help=f"Dossier de sortie pour les rapports (défaut: {DEFAULT_OUTPUT_DIR})")
    parser.add_argument("--time-period", choices=["daily", "weekly", "monthly"], default="weekly", help="Période de temps pour l'analyse de progression (défaut: weekly)")
    
    args = parser.parse_args()
    
    # Charger les filtres si spécifiés
    filter_condition = None
    if args.filter_file:
        with open(args.filter_file, "r", encoding="utf-8") as f:
            filter_condition = json.load(f)
    
    # Créer le générateur de rapports
    generator = RoadmapReportGenerator(
        collection_name=args.collection,
        qdrant_host=args.host,
        qdrant_port=args.port,
        output_dir=args.output_dir
    )
    
    # Générer le rapport demandé
    if args.report_type == "completion":
        generator.generate_completion_report(
            output_path=args.output,
            filter_condition=filter_condition
        )
    
    elif args.report_type == "priority":
        generator.generate_priority_report(
            output_path=args.output,
            filter_condition=filter_condition
        )
    
    elif args.report_type == "progress":
        generator.generate_progress_report(
            output_path=args.output,
            filter_condition=filter_condition,
            time_period=args.time_period
        )

if __name__ == "__main__":
    main()
