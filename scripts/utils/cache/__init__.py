#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Package de cache.

Ce package fournit des fonctionnalités pour la mise en cache de données,
l'invalidation du cache et la gestion des dépendances.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.dependency_manager import DependencyManager, get_default_manager
from scripts.utils.cache.invalidation import CacheInvalidator, get_default_invalidator
from scripts.utils.cache.purge_scheduler import PurgeScheduler, get_default_scheduler
from scripts.utils.cache.adapters.cache_adapter import CacheAdapter
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter, create_http_adapter_from_config
from scripts.utils.cache.adapters.n8n_adapter import N8nCacheAdapter, create_n8n_adapter_from_config

__all__ = [
    'LocalCache',
    'DependencyManager',
    'get_default_manager',
    'CacheInvalidator',
    'get_default_invalidator',
    'PurgeScheduler',
    'get_default_scheduler',
    'CacheAdapter',
    'HttpCacheAdapter',
    'create_http_adapter_from_config',
    'N8nCacheAdapter',
    'create_n8n_adapter_from_config'
]
