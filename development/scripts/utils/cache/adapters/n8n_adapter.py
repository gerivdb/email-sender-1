#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'adaptateur de cache pour l'API n8n.

Ce module fournit un adaptateur de cache spécifique pour l'API n8n,
permettant de mettre en cache les résultats des requêtes à l'API.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import json
import hashlib
import time
from typing import Any, Dict, List, Optional, Tuple, Union, Callable
import requests
from requests.models import Response

# Importer l'adaptateur HTTP
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter
from scripts.utils.cache.local_cache import LocalCache


class N8nCacheAdapter(HttpCacheAdapter):
    """Adaptateur de cache pour l'API n8n."""

    def __init__(self, api_url: str = None, api_key: str = None, 
                cache: LocalCache = None, config_path: str = None):
        """
        Initialise l'adaptateur de cache pour l'API n8n.

        Args:
            api_url (str, optional): URL de base de l'API n8n.
                Si None, utilise la valeur de la configuration.
            api_key (str, optional): Clé API pour l'authentification.
                Si None, utilise la valeur de la configuration.
            cache (LocalCache, optional): Instance de LocalCache à utiliser.
                Si None, une nouvelle instance sera créée.
            config_path (str, optional): Chemin vers un fichier de configuration JSON.
                Si fourni, les paramètres du fichier de configuration seront utilisés.
        """
        super().__init__(cache, config_path)
        
        # Configuration par défaut pour l'API n8n
        self.n8n_config = {
            "api_url": api_url or self.config.get("api_url", "http://localhost:5678/api/v1"),
            "api_key": api_key or self.config.get("api_key", ""),
            "default_ttl": self.config.get("default_ttl", 3600),
            "workflows_ttl": self.config.get("workflows_ttl", 3600),
            "executions_ttl": self.config.get("executions_ttl", 1800),
            "credentials_ttl": self.config.get("credentials_ttl", 7200),
            "tags_ttl": self.config.get("tags_ttl", 7200),
            "users_ttl": self.config.get("users_ttl", 7200)
        }
        
        # Mettre à jour la configuration
        self.config.update(self.n8n_config)
        
        # Préparer les en-têtes par défaut
        self.default_headers = {}
        if self.config["api_key"]:
            self.default_headers["X-N8N-API-KEY"] = self.config["api_key"]

    def get_ttl_for_endpoint(self, endpoint: str) -> int:
        """
        Détermine la durée de vie pour un endpoint spécifique.

        Args:
            endpoint (str): Endpoint de l'API.

        Returns:
            int: Durée de vie en secondes.
        """
        if "workflows" in endpoint:
            return self.config["workflows_ttl"]
        elif "executions" in endpoint:
            return self.config["executions_ttl"]
        elif "credentials" in endpoint:
            return self.config["credentials_ttl"]
        elif "tags" in endpoint:
            return self.config["tags_ttl"]
        elif "users" in endpoint:
            return self.config["users_ttl"]
        else:
            return self.config["default_ttl"]

    def get_workflows(self, active: bool = None, tags: List[str] = None, 
                     force_refresh: bool = False) -> List[Dict[str, Any]]:
        """
        Récupère la liste des workflows.

        Args:
            active (bool, optional): Filtre par état d'activation.
            tags (List[str], optional): Filtre par tags.
            force_refresh (bool, optional): Si True, ignore le cache et force une nouvelle requête.

        Returns:
            List[Dict[str, Any]]: Liste des workflows.
        """
        # Construire les paramètres de la requête
        params = {}
        if active is not None:
            params["active"] = active
        if tags:
            params["tags"] = ",".join(tags)
        
        # Construire l'URL
        url = f"{self.config['api_url']}/workflows"
        
        # Effectuer la requête avec mise en cache
        response = self.cached_request(
            "GET", 
            url, 
            params=params, 
            headers=self.default_headers,
            ttl=self.config["workflows_ttl"],
            force_refresh=force_refresh
        )
        
        # Vérifier si la requête a réussi
        response.raise_for_status()
        
        # Extraire les données
        data = response.json()
        
        # Retourner les workflows
        return data.get("data", [])

    def get_workflow(self, workflow_id: str, force_refresh: bool = False) -> Dict[str, Any]:
        """
        Récupère un workflow par son ID.

        Args:
            workflow_id (str): ID du workflow.
            force_refresh (bool, optional): Si True, ignore le cache et force une nouvelle requête.

        Returns:
            Dict[str, Any]: Détails du workflow.
        """
        # Construire l'URL
        url = f"{self.config['api_url']}/workflows/{workflow_id}"
        
        # Effectuer la requête avec mise en cache
        response = self.cached_request(
            "GET", 
            url, 
            headers=self.default_headers,
            ttl=self.config["workflows_ttl"],
            force_refresh=force_refresh
        )
        
        # Vérifier si la requête a réussi
        response.raise_for_status()
        
        # Extraire les données
        data = response.json()
        
        # Retourner le workflow
        return data

    def get_executions(self, workflow_id: str = None, status: str = None, 
                      limit: int = 20, force_refresh: bool = False) -> List[Dict[str, Any]]:
        """
        Récupère la liste des exécutions.

        Args:
            workflow_id (str, optional): Filtre par ID de workflow.
            status (str, optional): Filtre par statut (success, error, etc.).
            limit (int, optional): Nombre maximum d'exécutions à récupérer.
            force_refresh (bool, optional): Si True, ignore le cache et force une nouvelle requête.

        Returns:
            List[Dict[str, Any]]: Liste des exécutions.
        """
        # Construire les paramètres de la requête
        params = {"limit": limit}
        if workflow_id:
            params["workflowId"] = workflow_id
        if status:
            params["status"] = status
        
        # Construire l'URL
        url = f"{self.config['api_url']}/executions"
        
        # Effectuer la requête avec mise en cache
        response = self.cached_request(
            "GET", 
            url, 
            params=params, 
            headers=self.default_headers,
            ttl=self.config["executions_ttl"],
            force_refresh=force_refresh
        )
        
        # Vérifier si la requête a réussi
        response.raise_for_status()
        
        # Extraire les données
        data = response.json()
        
        # Retourner les exécutions
        return data.get("data", [])

    def execute_workflow(self, workflow_id: str, data: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Exécute un workflow.

        Args:
            workflow_id (str): ID du workflow à exécuter.
            data (Dict[str, Any], optional): Données à passer au workflow.

        Returns:
            Dict[str, Any]: Résultat de l'exécution.
        """
        # Construire l'URL
        url = f"{self.config['api_url']}/workflows/{workflow_id}/execute"
        
        # Préparer les données
        json_data = data or {}
        
        # Effectuer la requête (sans mise en cache car c'est une opération d'écriture)
        response = requests.post(
            url, 
            json=json_data, 
            headers=self.default_headers
        )
        
        # Vérifier si la requête a réussi
        response.raise_for_status()
        
        # Extraire les données
        data = response.json()
        
        # Invalider le cache pour les exécutions
        self.invalidate_url(f"{self.config['api_url']}/executions")
        
        # Retourner le résultat
        return data

    def get_tags(self, force_refresh: bool = False) -> List[Dict[str, Any]]:
        """
        Récupère la liste des tags.

        Args:
            force_refresh (bool, optional): Si True, ignore le cache et force une nouvelle requête.

        Returns:
            List[Dict[str, Any]]: Liste des tags.
        """
        # Construire l'URL
        url = f"{self.config['api_url']}/tags"
        
        # Effectuer la requête avec mise en cache
        response = self.cached_request(
            "GET", 
            url, 
            headers=self.default_headers,
            ttl=self.config["tags_ttl"],
            force_refresh=force_refresh
        )
        
        # Vérifier si la requête a réussi
        response.raise_for_status()
        
        # Extraire les données
        data = response.json()
        
        # Retourner les tags
        return data.get("data", [])

    def invalidate_workflows_cache(self) -> None:
        """Invalide le cache des workflows."""
        self.invalidate_url(f"{self.config['api_url']}/workflows")

    def invalidate_executions_cache(self) -> None:
        """Invalide le cache des exécutions."""
        self.invalidate_url(f"{self.config['api_url']}/executions")

    def invalidate_tags_cache(self) -> None:
        """Invalide le cache des tags."""
        self.invalidate_url(f"{self.config['api_url']}/tags")

    def invalidate_all_cache(self) -> None:
        """Invalide tout le cache de l'API n8n."""
        self.invalidate_url(self.config['api_url'])


# Fonction utilitaire pour créer un adaptateur n8n à partir d'un fichier de configuration
def create_n8n_adapter_from_config(config_path: str) -> N8nCacheAdapter:
    """
    Crée une instance de N8nCacheAdapter à partir d'un fichier de configuration.

    Args:
        config_path (str): Chemin vers le fichier de configuration JSON.

    Returns:
        N8nCacheAdapter: Instance de N8nCacheAdapter configurée.
    """
    return N8nCacheAdapter(config_path=config_path)
