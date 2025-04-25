#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'adaptateur de cache pour les requêtes HTTP.

Ce module fournit un adaptateur de cache pour les requêtes HTTP
utilisant la bibliothèque requests.

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
from urllib.parse import urlparse, parse_qsl, urlencode, urlunparse

# Importer l'adaptateur de cache générique
from scripts.utils.cache.adapters.cache_adapter import CacheAdapter
from scripts.utils.cache.local_cache import LocalCache


class HttpCacheAdapter(CacheAdapter):
    """Adaptateur de cache pour les requêtes HTTP."""

    def __init__(self, cache: LocalCache = None, config_path: str = None):
        """
        Initialise l'adaptateur de cache pour les requêtes HTTP.

        Args:
            cache (LocalCache, optional): Instance de LocalCache à utiliser.
                Si None, une nouvelle instance sera créée.
            config_path (str, optional): Chemin vers un fichier de configuration JSON.
                Si fourni, les paramètres du fichier de configuration seront utilisés.
        """
        super().__init__(cache, config_path)

        # Configuration par défaut pour les requêtes HTTP
        self.default_config = {
            "default_ttl": 3600,  # 1 heure
            "methods_to_cache": ["GET", "HEAD"],
            "status_codes_to_cache": [200],
            "ignore_query_params": [],
            "ignore_headers": ["User-Agent", "Accept-Encoding", "Connection"],
            "vary_headers": ["Accept", "Accept-Language", "Content-Type"]
        }

        # Fusionner la configuration par défaut avec la configuration fournie
        for key, value in self.default_config.items():
            if key not in self.config:
                self.config[key] = value

    def generate_cache_key(self, method: str, url: str,
                          params: Dict = None, headers: Dict = None,
                          data: Any = None, json_data: Dict = None,
                          **kwargs) -> str:
        """
        Génère une clé de cache unique pour une requête HTTP.

        Args:
            method (str): Méthode HTTP (GET, POST, etc.).
            url (str): URL de la requête.
            params (Dict, optional): Paramètres de la requête.
            headers (Dict, optional): En-têtes de la requête.
            data (Any, optional): Données de la requête.
            json_data (Dict, optional): Données JSON de la requête.
            **kwargs: Arguments supplémentaires.

        Returns:
            str: Clé de cache unique.
        """
        # Normaliser l'URL
        parsed_url = urlparse(url)

        # Extraire et trier les paramètres de l'URL
        url_params = dict(parse_qsl(parsed_url.query))

        # Fusionner avec les paramètres fournis
        if params:
            url_params.update(params)

        # Filtrer les paramètres à ignorer
        for param in self.config["ignore_query_params"]:
            if param in url_params:
                del url_params[param]

        # Reconstruire l'URL sans les paramètres
        clean_url = urlunparse((
            parsed_url.scheme,
            parsed_url.netloc,
            parsed_url.path,
            parsed_url.params,
            '',
            ''
        ))

        # Filtrer les en-têtes à ignorer
        filtered_headers = {}
        if headers:
            filtered_headers = {k: v for k, v in headers.items()
                               if k not in self.config["ignore_headers"]}

        # Construire les composants de la clé
        key_components = {
            "method": method.upper(),
            "url": clean_url,
            "params": url_params,
            "headers": {k: v for k, v in filtered_headers.items()
                       if k in self.config["vary_headers"]},
            "data": data,
            "json": json_data
        }

        # Générer un hash SHA-256
        hash_obj = hashlib.sha256()
        hash_obj.update(json.dumps(key_components, sort_keys=True).encode('utf-8'))

        return f"http:{hash_obj.hexdigest()}"

    def serialize_response(self, response: Response) -> Dict[str, Any]:
        """
        Sérialise une réponse HTTP pour le stockage dans le cache.

        Args:
            response (Response): Réponse HTTP à sérialiser.

        Returns:
            Dict[str, Any]: Réponse sérialisée.
        """
        # Extraire les informations importantes de la réponse
        serialized = {
            "url": response.url,
            "status_code": response.status_code,
            "headers": dict(response.headers),
            "content": response.content.decode('utf-8', errors='replace') if response.content else None,
            "encoding": response.encoding,
            "elapsed": response.elapsed.total_seconds(),
            "timestamp": time.time()
        }

        return serialized

    def deserialize_response(self, serialized_response: Dict[str, Any]) -> Response:
        """
        Désérialise une réponse HTTP du cache.

        Args:
            serialized_response (Dict[str, Any]): Réponse HTTP sérialisée.

        Returns:
            Response: Réponse HTTP désérialisée.
        """
        # Créer une nouvelle réponse
        response = Response()

        # Restaurer les attributs de la réponse
        response.url = serialized_response["url"]
        response.status_code = serialized_response["status_code"]
        response.headers = requests.structures.CaseInsensitiveDict(serialized_response["headers"])
        response._content = serialized_response["content"].encode('utf-8') if serialized_response["content"] else b''
        response.encoding = serialized_response["encoding"]
        # Utiliser datetime.timedelta au lieu de requests.models.timedelta
        from datetime import timedelta
        response.elapsed = timedelta(seconds=serialized_response["elapsed"])

        # Ajouter un attribut pour indiquer que la réponse vient du cache
        response.from_cache = True
        response.cached_at = serialized_response["timestamp"]

        return response

    def should_cache_response(self, method: str, response: Response) -> bool:
        """
        Détermine si une réponse doit être mise en cache.

        Args:
            method (str): Méthode HTTP utilisée pour la requête.
            response (Response): Réponse HTTP.

        Returns:
            bool: True si la réponse doit être mise en cache, False sinon.
        """
        # Vérifier si la méthode est cacheable
        if method.upper() not in self.config["methods_to_cache"]:
            return False

        # Vérifier si le code de statut est cacheable
        if response.status_code not in self.config["status_codes_to_cache"]:
            return False

        # Vérifier les en-têtes de cache
        cache_control = response.headers.get('Cache-Control', '')
        if 'no-store' in cache_control or 'no-cache' in cache_control:
            return False

        return True

    def get_ttl_from_response(self, response: Response) -> Optional[int]:
        """
        Détermine la durée de vie d'une réponse à partir de ses en-têtes.

        Args:
            response (Response): Réponse HTTP.

        Returns:
            Optional[int]: Durée de vie en secondes ou None pour utiliser la valeur par défaut.
        """
        # Vérifier l'en-tête Cache-Control
        cache_control = response.headers.get('Cache-Control', '')
        if 'max-age=' in cache_control:
            try:
                max_age = int(cache_control.split('max-age=')[1].split(',')[0])
                return max_age
            except (ValueError, IndexError):
                pass

        # Vérifier l'en-tête Expires
        expires = response.headers.get('Expires')
        if expires:
            try:
                from email.utils import parsedate_to_datetime
                expires_date = parsedate_to_datetime(expires)
                now = time.time()
                ttl = int(expires_date.timestamp() - now)
                return max(0, ttl)
            except Exception:
                pass

        # Utiliser la valeur par défaut
        return self.config["default_ttl"]

    def cached_request(self, method: str, url: str, ttl: Optional[int] = None,
                      force_refresh: bool = False, **kwargs) -> Response:
        """
        Effectue une requête HTTP avec mise en cache.

        Args:
            method (str): Méthode HTTP (GET, POST, etc.).
            url (str): URL de la requête.
            ttl (int, optional): Durée de vie de la réponse en secondes.
                Si None, utilise la durée de vie déterminée à partir de la réponse.
            force_refresh (bool, optional): Si True, ignore le cache et force une nouvelle requête.
            **kwargs: Arguments supplémentaires à passer à requests.request().

        Returns:
            Response: Réponse HTTP (du cache ou fraîche).
        """
        # Générer la clé de cache
        params = kwargs.get('params', {})
        headers = kwargs.get('headers', {})
        data = kwargs.get('data')
        json_data = kwargs.get('json')

        # Retirer les paramètres spéciaux pour éviter les doublons
        request_kwargs = kwargs.copy()
        if 'params' in request_kwargs:
            del request_kwargs['params']
        if 'headers' in request_kwargs:
            del request_kwargs['headers']
        if 'data' in request_kwargs:
            del request_kwargs['data']
        if 'json' in request_kwargs:
            del request_kwargs['json']

        cache_key = self.generate_cache_key(
            method, url, params=params, headers=headers, data=data, json_data=json_data, **request_kwargs
        )

        # Vérifier si la réponse est dans le cache (sauf si force_refresh est True)
        if not force_refresh:
            cached_response = self.get_cached_response(cache_key)
            if cached_response is not None:
                return cached_response

        # Effectuer la requête
        response = requests.request(method, url, **kwargs)

        # Vérifier si la réponse doit être mise en cache
        if self.should_cache_response(method, response):
            # Déterminer la durée de vie
            effective_ttl = ttl if ttl is not None else self.get_ttl_from_response(response)

            # Mettre en cache la réponse
            self.cache_response(cache_key, response, effective_ttl)

        return response

    def get(self, url: str, **kwargs) -> Response:
        """
        Effectue une requête GET avec mise en cache.

        Args:
            url (str): URL de la requête.
            **kwargs: Arguments supplémentaires à passer à requests.get().

        Returns:
            Response: Réponse HTTP (du cache ou fraîche).
        """
        return self.cached_request('GET', url, **kwargs)

    def post(self, url: str, **kwargs) -> Response:
        """
        Effectue une requête POST avec mise en cache.

        Args:
            url (str): URL de la requête.
            **kwargs: Arguments supplémentaires à passer à requests.post().

        Returns:
            Response: Réponse HTTP (du cache ou fraîche).
        """
        return self.cached_request('POST', url, **kwargs)

    def put(self, url: str, **kwargs) -> Response:
        """
        Effectue une requête PUT avec mise en cache.

        Args:
            url (str): URL de la requête.
            **kwargs: Arguments supplémentaires à passer à requests.put().

        Returns:
            Response: Réponse HTTP (du cache ou fraîche).
        """
        return self.cached_request('PUT', url, **kwargs)

    def delete(self, url: str, **kwargs) -> Response:
        """
        Effectue une requête DELETE avec mise en cache.

        Args:
            url (str): URL de la requête.
            **kwargs: Arguments supplémentaires à passer à requests.delete().

        Returns:
            Response: Réponse HTTP (du cache ou fraîche).
        """
        return self.cached_request('DELETE', url, **kwargs)

    def head(self, url: str, **kwargs) -> Response:
        """
        Effectue une requête HEAD avec mise en cache.

        Args:
            url (str): URL de la requête.
            **kwargs: Arguments supplémentaires à passer à requests.head().

        Returns:
            Response: Réponse HTTP (du cache ou fraîche).
        """
        return self.cached_request('HEAD', url, **kwargs)

    def options(self, url: str, **kwargs) -> Response:
        """
        Effectue une requête OPTIONS avec mise en cache.

        Args:
            url (str): URL de la requête.
            **kwargs: Arguments supplémentaires à passer à requests.options().

        Returns:
            Response: Réponse HTTP (du cache ou fraîche).
        """
        return self.cached_request('OPTIONS', url, **kwargs)

    def patch(self, url: str, **kwargs) -> Response:
        """
        Effectue une requête PATCH avec mise en cache.

        Args:
            url (str): URL de la requête.
            **kwargs: Arguments supplémentaires à passer à requests.patch().

        Returns:
            Response: Réponse HTTP (du cache ou fraîche).
        """
        return self.cached_request('PATCH', url, **kwargs)

    def invalidate_url(self, url: str, method: str = None) -> int:
        """
        Invalide toutes les entrées du cache pour une URL donnée.

        Args:
            url (str): URL à invalider.
            method (str, optional): Méthode HTTP à invalider. Si None, invalide toutes les méthodes.

        Returns:
            int: Nombre d'entrées invalidées.
        """
        # Cette méthode est une approximation car nous ne pouvons pas facilement
        # rechercher des clés par motif dans DiskCache. Dans une implémentation réelle,
        # nous pourrions utiliser une base de données pour stocker les métadonnées des clés.
        # Pour l'instant, nous vidons simplement tout le cache.
        self.cache.clear()
        return 1  # Nombre d'entrées invalidées (approximatif)


# Fonction utilitaire pour créer un adaptateur HTTP à partir d'un fichier de configuration
def create_http_adapter_from_config(config_path: str) -> HttpCacheAdapter:
    """
    Crée une instance de HttpCacheAdapter à partir d'un fichier de configuration.

    Args:
        config_path (str): Chemin vers le fichier de configuration JSON.

    Returns:
        HttpCacheAdapter: Instance de HttpCacheAdapter configurée.
    """
    return HttpCacheAdapter(config_path=config_path)
