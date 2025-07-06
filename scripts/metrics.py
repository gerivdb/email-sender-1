import os
import subprocess
import json
import argparse
import sys

# scripts/metrics.py
# Collecteur et rapporteur de métriques

class MetricsCollector:
    def __init__(self):
        self.go_metrics_path = os.path.join("integration", "cmd", "metrics", "metrics")
        if sys.platform == "win32":
            self.go_metrics_path += ".exe"

    def collect(self):
        """
        Collecte les métriques en appelant l'exécutable Go metrics et retourne les données JSON.
        """
        print(f"Collecte des métriques avec l'exécutable Go à {self.go_metrics_path}...")
        
        if not os.path.exists(self.go_metrics_path):
            print(f"Erreur: L'exécutable Go metrics n'a pas été trouvé à {self.go_metrics_path}")
            print("Veuillez construire l'exécutable Go metrics d'abord (go build -o integration/cmd/metrics/metrics.exe integration/cmd/metrics/main.go).")
            return None

        command = [self.go_metrics_path, "--collect", "--format", "json"]
        
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True)
            if result.stderr:
                print("Go Metrics Errors (stderr):", result.stderr)
            
            metrics_data = json.loads(result.stdout)
            print("Métriques Go collectées avec succès.")
            return metrics_data
        except subprocess.CalledProcessError as e:
            print(f"Erreur lors de la collecte des métriques Go: {e}")
            print(f"Sortie standard: {e.stdout}")
            print(f"Erreur standard: {e.stderr}")
            return None
        except (FileNotFoundError, json.JSONDecodeError) as e:
            print(f"Erreur lors de l'exécution ou du parsing des métriques Go: {e}")
            return None

    def report(self, metrics_data, output_format="text"):
        """
        Génère un rapport des métriques collectées.
        """
        if not metrics_data:
            print("Aucune donnée de métriques à rapporter.")
            return

        if output_format == "json":
            print(json.dumps(metrics_data, indent=2))
        else: # Default to text format
            print("\n--- Rapport de Métriques ---")
            print(f"  Qualité: {metrics_data.get('Quality'):.2f}")
            print(f"  Couverture: {metrics_data.get('Coverage'):.2f}")
            print(f"  Usage: {metrics_data.get('Usage'):.2f}")
            print("--- Fin du Rapport ---")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Collecteur et rapporteur de métriques.")
    parser.add_argument("--collect", action="store_true", help="Collecter les métriques.")
    parser.add_argument("--report", action="store_true", help="Générer un rapport des métriques (collecte implicite si non spécifié).")
    parser.add_argument("--format", type=str, default="text", choices=["text", "json"], help="Format de sortie du rapport (text ou json).")
    args = parser.parse_args()

    collector = MetricsCollector()

    if args.collect:
        metrics = collector.collect()
        if metrics:
            collector.report(metrics, args.format)
    elif args.report:
        # If --report is used without --collect, collect first
        metrics = collector.collect()
        if metrics:
            collector.report(metrics, args.format)
    else:
        # Default behavior: collect and report
        metrics = collector.collect()
        if metrics:
            collector.report(metrics, "text")
