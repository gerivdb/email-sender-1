#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant des outils pour le diagnostic des serveurs.

Ce module fournit des outils pour surveiller et diagnostiquer les serveurs,
analyser les logs, vérifier les performances, etc.
"""

import os
import sys
import json
import subprocess
import platform
import psutil
import requests
from typing import Dict, Any, Optional, List, Union
from pathlib import Path
from datetime import datetime

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_core.tools import BaseTool, tool

class ServerDiagnosticTools:
    """Classe contenant des outils pour le diagnostic des serveurs."""
    
    @tool("get_system_info")
    def get_system_info() -> Dict[str, Any]:
        """
        Récupère les informations système de base.
        
        Returns:
            Dictionnaire contenant les informations système
        """
        try:
            # Informations sur le système d'exploitation
            os_info = {
                "system": platform.system(),
                "release": platform.release(),
                "version": platform.version(),
                "architecture": platform.machine(),
                "processor": platform.processor()
            }
            
            # Informations sur la mémoire
            memory = psutil.virtual_memory()
            memory_info = {
                "total": memory.total,
                "available": memory.available,
                "used": memory.used,
                "percent": memory.percent
            }
            
            # Informations sur le disque
            disk = psutil.disk_usage('/')
            disk_info = {
                "total": disk.total,
                "used": disk.used,
                "free": disk.free,
                "percent": disk.percent
            }
            
            # Informations sur le CPU
            cpu_info = {
                "physical_cores": psutil.cpu_count(logical=False),
                "logical_cores": psutil.cpu_count(logical=True),
                "usage_percent": psutil.cpu_percent(interval=1),
                "frequency": psutil.cpu_freq().current if psutil.cpu_freq() else None
            }
            
            # Informations sur le réseau
            network_info = {
                "interfaces": list(psutil.net_if_addrs().keys()),
                "connections": len(psutil.net_connections())
            }
            
            return {
                "timestamp": datetime.now().isoformat(),
                "os": os_info,
                "memory": memory_info,
                "disk": disk_info,
                "cpu": cpu_info,
                "network": network_info
            }
        except Exception as e:
            return {"error": str(e)}
    
    @tool("get_process_info")
    def get_process_info(process_name: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Récupère les informations sur les processus en cours d'exécution.
        
        Args:
            process_name: Nom du processus à filtrer (optionnel)
            
        Returns:
            Liste des processus avec leurs informations
        """
        try:
            processes = []
            for proc in psutil.process_iter(['pid', 'name', 'username', 'memory_percent', 'cpu_percent', 'create_time', 'status']):
                process_info = proc.info
                
                # Filtrer par nom de processus si spécifié
                if process_name and process_name.lower() not in process_info['name'].lower():
                    continue
                
                # Ajouter des informations supplémentaires
                try:
                    process_info['memory_mb'] = proc.memory_info().rss / (1024 * 1024)
                    process_info['num_threads'] = proc.num_threads()
                    process_info['create_time'] = datetime.fromtimestamp(process_info['create_time']).isoformat()
                except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                    pass
                
                processes.append(process_info)
            
            # Trier par utilisation CPU (décroissant)
            processes.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
            
            return processes
        except Exception as e:
            return [{"error": str(e)}]
    
    @tool("check_port_status")
    def check_port_status(host: str, port: int) -> Dict[str, Any]:
        """
        Vérifie si un port est ouvert sur un hôte.
        
        Args:
            host: Nom d'hôte ou adresse IP
            port: Numéro de port
            
        Returns:
            Dictionnaire indiquant si le port est ouvert
        """
        try:
            import socket
            
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            result = sock.connect_ex((host, port))
            sock.close()
            
            is_open = result == 0
            
            return {
                "host": host,
                "port": port,
                "is_open": is_open,
                "status": "open" if is_open else "closed",
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {
                "host": host,
                "port": port,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    @tool("check_http_endpoint")
    def check_http_endpoint(url: str, method: str = "GET", timeout: int = 10) -> Dict[str, Any]:
        """
        Vérifie la disponibilité d'un endpoint HTTP.
        
        Args:
            url: URL de l'endpoint
            method: Méthode HTTP (défaut: GET)
            timeout: Timeout en secondes (défaut: 10)
            
        Returns:
            Dictionnaire contenant les informations sur la réponse
        """
        try:
            start_time = datetime.now()
            
            response = requests.request(
                method=method,
                url=url,
                timeout=timeout
            )
            
            end_time = datetime.now()
            response_time_ms = (end_time - start_time).total_seconds() * 1000
            
            return {
                "url": url,
                "method": method,
                "status_code": response.status_code,
                "reason": response.reason,
                "response_time_ms": response_time_ms,
                "headers": dict(response.headers),
                "content_length": len(response.content),
                "timestamp": datetime.now().isoformat()
            }
        except requests.exceptions.RequestException as e:
            return {
                "url": url,
                "method": method,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    @tool("get_log_entries")
    def get_log_entries(log_file: str, num_lines: int = 100, filter_text: Optional[str] = None) -> List[str]:
        """
        Récupère les dernières entrées d'un fichier de log.
        
        Args:
            log_file: Chemin vers le fichier de log
            num_lines: Nombre de lignes à récupérer (défaut: 100)
            filter_text: Texte pour filtrer les entrées (optionnel)
            
        Returns:
            Liste des entrées de log
        """
        try:
            if not os.path.exists(log_file):
                return [f"Erreur: Le fichier {log_file} n'existe pas"]
            
            # Lire les dernières lignes du fichier
            with open(log_file, 'r', encoding='utf-8', errors='replace') as f:
                lines = f.readlines()
            
            # Prendre les dernières lignes
            last_lines = lines[-num_lines:] if len(lines) > num_lines else lines
            
            # Filtrer par texte si spécifié
            if filter_text:
                last_lines = [line for line in last_lines if filter_text in line]
            
            return last_lines
        except Exception as e:
            return [f"Erreur lors de la lecture du fichier de log: {str(e)}"]
