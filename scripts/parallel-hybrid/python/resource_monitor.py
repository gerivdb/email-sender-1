#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de surveillance des ressources pour l'architecture hybride PowerShell-Python.

Ce module fournit des fonctions pour surveiller l'utilisation des ressources système
pendant l'exécution des tâches parallèles.

Auteur: Augment Agent
Date: 2025-04-10
Version: 1.0
"""

import os
import sys
import json
import time
import argparse
import threading
import psutil
from datetime import datetime


class ResourceMonitor:
    """Classe pour la surveillance des ressources système."""
    
    def __init__(self, output_file=None, interval=1.0, max_samples=0):
        """
        Initialise le moniteur de ressources.
        
        Args:
            output_file (str, optional): Fichier de sortie pour les données de surveillance.
                Si None, utilise la sortie standard.
            interval (float, optional): Intervalle de surveillance en secondes.
                Par défaut: 1.0.
            max_samples (int, optional): Nombre maximum d'échantillons à collecter.
                Par défaut: 0 (illimité).
        """
        self.output_file = output_file
        self.interval = interval
        self.max_samples = max_samples
        self.samples = []
        self.running = False
        self.thread = None
        self.start_time = None
    
    def start(self):
        """Démarre la surveillance des ressources."""
        if self.running:
            return
        
        self.running = True
        self.start_time = time.time()
        self.samples = []
        
        # Démarrer la surveillance dans un thread séparé
        self.thread = threading.Thread(target=self._monitor_loop)
        self.thread.daemon = True
        self.thread.start()
    
    def stop(self):
        """Arrête la surveillance des ressources."""
        self.running = False
        if self.thread:
            self.thread.join()
        
        # Écrire les données de surveillance
        self._write_samples()
    
    def _monitor_loop(self):
        """Boucle de surveillance des ressources."""
        sample_count = 0
        
        while self.running:
            # Collecter un échantillon
            sample = self._collect_sample()
            self.samples.append(sample)
            sample_count += 1
            
            # Vérifier si le nombre maximum d'échantillons est atteint
            if self.max_samples > 0 and sample_count >= self.max_samples:
                self.running = False
                break
            
            # Attendre l'intervalle de surveillance
            time.sleep(self.interval)
    
    def _collect_sample(self):
        """
        Collecte un échantillon des ressources système.
        
        Returns:
            dict: Échantillon des ressources système.
        """
        # Obtenir les informations sur le processus actuel
        process = psutil.Process(os.getpid())
        
        # Collecter les informations sur les ressources
        sample = {
            "timestamp": time.time(),
            "elapsed": time.time() - self.start_time,
            "process": {
                "cpu_percent": process.cpu_percent(interval=0),
                "memory_percent": process.memory_percent(),
                "memory_info": {
                    "rss": process.memory_info().rss,
                    "vms": process.memory_info().vms
                },
                "num_threads": process.num_threads(),
                "status": process.status()
            },
            "system": {
                "cpu_percent": psutil.cpu_percent(interval=0),
                "memory": {
                    "total": psutil.virtual_memory().total,
                    "available": psutil.virtual_memory().available,
                    "percent": psutil.virtual_memory().percent
                },
                "swap": {
                    "total": psutil.swap_memory().total,
                    "used": psutil.swap_memory().used,
                    "percent": psutil.swap_memory().percent
                },
                "disk": {
                    "total": psutil.disk_usage('/').total,
                    "used": psutil.disk_usage('/').used,
                    "percent": psutil.disk_usage('/').percent
                }
            }
        }
        
        # Collecter les informations sur les E/S si disponibles
        try:
            io_counters = process.io_counters()
            sample["process"]["io_counters"] = {
                "read_count": io_counters.read_count,
                "write_count": io_counters.write_count,
                "read_bytes": io_counters.read_bytes,
                "write_bytes": io_counters.write_bytes
            }
        except (psutil.AccessDenied, AttributeError):
            pass
        
        # Collecter les informations sur les descripteurs de fichiers si disponibles
        try:
            sample["process"]["num_fds"] = process.num_fds()
        except (psutil.AccessDenied, AttributeError):
            pass
        
        # Collecter les informations sur les connexions réseau si disponibles
        try:
            connections = process.connections()
            sample["process"]["connections"] = len(connections)
        except (psutil.AccessDenied, AttributeError):
            pass
        
        return sample
    
    def _write_samples(self):
        """Écrit les échantillons collectés dans le fichier de sortie."""
        if not self.samples:
            return
        
        if self.output_file:
            try:
                with open(self.output_file, 'w', encoding='utf-8') as f:
                    json.dump(self.samples, f, indent=2)
            except Exception as e:
                print(f"Erreur lors de l'écriture des données de surveillance : {e}", file=sys.stderr)
        else:
            # Écrire sur la sortie standard
            print(json.dumps(self.samples, indent=2))
    
    def get_summary(self):
        """
        Génère un résumé des données de surveillance.
        
        Returns:
            dict: Résumé des données de surveillance.
        """
        if not self.samples:
            return {}
        
        # Calculer les statistiques
        cpu_values = [sample["process"]["cpu_percent"] for sample in self.samples]
        memory_values = [sample["process"]["memory_percent"] for sample in self.samples]
        system_cpu_values = [sample["system"]["cpu_percent"] for sample in self.samples]
        system_memory_values = [sample["system"]["memory"]["percent"] for sample in self.samples]
        
        summary = {
            "start_time": self.start_time,
            "end_time": time.time(),
            "duration": time.time() - self.start_time,
            "num_samples": len(self.samples),
            "process": {
                "cpu_percent": {
                    "min": min(cpu_values),
                    "max": max(cpu_values),
                    "avg": sum(cpu_values) / len(cpu_values)
                },
                "memory_percent": {
                    "min": min(memory_values),
                    "max": max(memory_values),
                    "avg": sum(memory_values) / len(memory_values)
                }
            },
            "system": {
                "cpu_percent": {
                    "min": min(system_cpu_values),
                    "max": max(system_cpu_values),
                    "avg": sum(system_cpu_values) / len(system_cpu_values)
                },
                "memory_percent": {
                    "min": min(system_memory_values),
                    "max": max(system_memory_values),
                    "avg": sum(system_memory_values) / len(system_memory_values)
                }
            }
        }
        
        return summary


def main():
    """Fonction principale pour l'exécution en ligne de commande."""
    parser = argparse.ArgumentParser(description='Moniteur de ressources pour l\'architecture hybride PowerShell-Python')
    parser.add_argument('--output', help='Fichier de sortie pour les données de surveillance')
    parser.add_argument('--interval', type=float, default=1.0, help='Intervalle de surveillance en secondes')
    parser.add_argument('--max-samples', type=int, default=0, help='Nombre maximum d\'échantillons à collecter')
    parser.add_argument('--summary', action='store_true', help='Afficher uniquement le résumé des données de surveillance')
    
    args = parser.parse_args()
    
    # Initialiser le moniteur de ressources
    monitor = ResourceMonitor(
        output_file=args.output,
        interval=args.interval,
        max_samples=args.max_samples
    )
    
    try:
        print(f"Démarrage de la surveillance des ressources (intervalle: {args.interval}s)...", file=sys.stderr)
        monitor.start()
        
        # Attendre l'arrêt manuel ou le nombre maximum d'échantillons
        if args.max_samples > 0:
            # Attendre la fin de la surveillance
            while monitor.running:
                time.sleep(0.1)
        else:
            # Attendre l'arrêt manuel (Ctrl+C)
            while True:
                time.sleep(1)
    
    except KeyboardInterrupt:
        print("Arrêt de la surveillance des ressources...", file=sys.stderr)
    
    finally:
        # Arrêter la surveillance
        monitor.stop()
        
        # Afficher le résumé si demandé
        if args.summary:
            summary = monitor.get_summary()
            print(json.dumps(summary, indent=2))
        
        print(f"Surveillance terminée. {len(monitor.samples)} échantillons collectés.", file=sys.stderr)


if __name__ == "__main__":
    main()
