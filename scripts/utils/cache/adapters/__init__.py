#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Package d'adaptateurs de cache.

Ce package fournit des adaptateurs de cache pour différents types de requêtes et d'API.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

from scripts.utils.cache.adapters.cache_adapter import CacheAdapter
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter, create_http_adapter_from_config
from scripts.utils.cache.adapters.n8n_adapter import N8nCacheAdapter, create_n8n_adapter_from_config

__all__ = [
    'CacheAdapter',
    'HttpCacheAdapter',
    'create_http_adapter_from_config',
    'N8nCacheAdapter',
    'create_n8n_adapter_from_config'
]
