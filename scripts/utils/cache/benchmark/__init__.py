#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de benchmarking pour le système de cache.

Ce module fournit des outils pour évaluer les performances
du système de cache dans différentes configurations.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

from scripts.utils.cache.benchmark.test_spec import (
    CacheTestSpec, CacheType, BenchmarkType, DataDistribution, OperationType,
    create_test_spec, create_standard_test_suite
)
from scripts.utils.cache.benchmark.runner import run_benchmark
from scripts.utils.cache.benchmark.reporting import generate_report, compare_reports

__all__ = [
    'CacheTestSpec', 'CacheType', 'BenchmarkType', 'DataDistribution', 'OperationType',
    'create_test_spec', 'create_standard_test_suite',
    'run_benchmark',
    'generate_report', 'compare_reports'
]
