#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de spécification de test pour le système de cache.

Ce module définit les structures de données et les classes nécessaires
pour spécifier des tests de performance pour le système de cache.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import json
import hashlib
import time
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Any, Optional, Union, Callable
from enum import Enum


class CacheType(Enum):
    """Types de cache supportés."""
    LRU = "lru"
    LFU = "lfu"
    ARC = "arc"
    FIFO = "fifo"
    TTL = "ttl"
    COMPOSITE = "composite"
    SHARDED = "sharded"
    ASYNC = "async"
    BATCH = "batch"
    THREAD_SAFE = "thread_safe"


class OperationType(Enum):
    """Types d'opérations de cache."""
    GET = "get"
    SET = "set"
    DELETE = "delete"
    CLEAR = "clear"
    GET_MANY = "get_many"
    SET_MANY = "set_many"
    DELETE_MANY = "delete_many"


class DataDistribution(Enum):
    """Distributions de données pour les tests."""
    UNIFORM = "uniform"
    ZIPF = "zipf"
    NORMAL = "normal"
    SEQUENTIAL = "sequential"
    REAL_WORLD = "real_world"


class BenchmarkType(Enum):
    """Types de benchmark."""
    THROUGHPUT = "throughput"
    LATENCY = "latency"
    MEMORY = "memory"
    HIT_RATIO = "hit_ratio"
    CONCURRENCY = "concurrency"
    DURABILITY = "durability"
    RESILIENCE = "resilience"
    MIXED = "mixed"


@dataclass
class CacheTestSpec:
    """
    Spécification de test pour le système de cache.
    
    Cette classe définit les paramètres d'un test de performance
    pour le système de cache.
    """
    # Identifiant unique du test
    test_id: str
    
    # Type de cache à tester
    cache_type: Union[CacheType, str]
    
    # Type de benchmark à exécuter
    benchmark_type: Union[BenchmarkType, str]
    
    # Taille du jeu de données (nombre d'éléments)
    dataset_size: int
    
    # Taille moyenne des valeurs en octets
    value_size: int
    
    # Distribution des données
    data_distribution: Union[DataDistribution, str] = DataDistribution.UNIFORM
    
    # Mélange d'opérations (pourcentage de chaque type d'opération)
    operation_mix: Dict[Union[OperationType, str], float] = field(
        default_factory=lambda: {
            OperationType.GET: 0.8,
            OperationType.SET: 0.15,
            OperationType.DELETE: 0.05
        }
    )
    
    # Niveau de concurrence (nombre de threads/processus)
    concurrency_level: int = 1
    
    # Durée du test en secondes
    duration_seconds: int = 60
    
    # Taux de succès attendu (hit ratio)
    expected_hit_ratio: float = 0.7
    
    # Latence maximale acceptable en millisecondes
    max_latency_ms: float = 10.0
    
    # Utilisation maximale de la mémoire en Mo
    max_memory_mb: float = 100.0
    
    # Timeout pour le test en secondes
    timeout: int = 300
    
    # Paramètres spécifiques au cache
    cache_params: Dict[str, Any] = field(default_factory=dict)
    
    # Chemin vers le répertoire de sortie des rapports
    output_dir: str = field(default_factory=lambda: os.path.join(
        os.path.dirname(os.path.abspath(__file__)), 'reports'
    ))
    
    def __post_init__(self):
        """Initialisation après la création de l'instance."""
        # Convertir les énumérations en chaînes si nécessaire
        if isinstance(self.cache_type, CacheType):
            self.cache_type = self.cache_type.value
        elif isinstance(self.cache_type, str):
            # Vérifier que la valeur est valide
            if self.cache_type not in [ct.value for ct in CacheType]:
                raise ValueError(f"Type de cache invalide: {self.cache_type}")
        
        if isinstance(self.benchmark_type, BenchmarkType):
            self.benchmark_type = self.benchmark_type.value
        elif isinstance(self.benchmark_type, str):
            if self.benchmark_type not in [bt.value for bt in BenchmarkType]:
                raise ValueError(f"Type de benchmark invalide: {self.benchmark_type}")
        
        if isinstance(self.data_distribution, DataDistribution):
            self.data_distribution = self.data_distribution.value
        elif isinstance(self.data_distribution, str):
            if self.data_distribution not in [dd.value for dd in DataDistribution]:
                raise ValueError(f"Distribution de données invalide: {self.data_distribution}")
        
        # Convertir les clés du mélange d'opérations en chaînes si nécessaire
        operation_mix_str = {}
        for op, value in self.operation_mix.items():
            if isinstance(op, OperationType):
                operation_mix_str[op.value] = value
            else:
                if op not in [ot.value for ot in OperationType]:
                    raise ValueError(f"Type d'opération invalide: {op}")
                operation_mix_str[op] = value
        self.operation_mix = operation_mix_str
        
        # Vérifier que les pourcentages du mélange d'opérations somment à 1
        total = sum(self.operation_mix.values())
        if not 0.99 <= total <= 1.01:  # Permettre une petite marge d'erreur
            raise ValueError(f"La somme des pourcentages du mélange d'opérations doit être 1, mais est {total}")
        
        # Créer le répertoire de sortie s'il n'existe pas
        os.makedirs(self.output_dir, exist_ok=True)
    
    @property
    def test_script(self) -> str:
        """
        Génère un script de test basé sur les paramètres.
        
        Returns:
            str: Script de test.
        """
        return self._generate_test_script()
    
    def _generate_test_script(self) -> str:
        """
        Génère un script de test basé sur les paramètres.
        
        Returns:
            str: Script de test.
        """
        script = f"""#!/usr/bin/env python
# -*- coding: utf-8 -*-

\"\"\"
Script de test pour le cache {self.cache_type}.

Ce script exécute un benchmark de type {self.benchmark_type}
sur un cache de type {self.cache_type} avec les paramètres suivants:
- Taille du jeu de données: {self.dataset_size} éléments
- Taille moyenne des valeurs: {self.value_size} octets
- Distribution des données: {self.data_distribution}
- Mélange d'opérations: {self.operation_mix}
- Niveau de concurrence: {self.concurrency_level} threads/processus
- Durée du test: {self.duration_seconds} secondes
\"\"\"

import os
import time
import random
import statistics
import json
from pathlib import Path

from scripts.utils.cache.benchmark.runner import run_benchmark
from scripts.utils.cache.benchmark.reporting import generate_report
from scripts.utils.cache.optimized_algorithms import create_optimized_cache
from scripts.utils.cache.parallel_cache import create_parallel_cache

# Créer le cache
cache_params = {json.dumps(self.cache_params, indent=4)}
cache = None

if "{self.cache_type}" in ["lru", "lfu", "arc"]:
    cache = create_optimized_cache("{self.cache_type}", capacity=1000)
elif "{self.cache_type}" in ["thread_safe", "sharded", "async", "batch"]:
    cache = create_parallel_cache("{self.cache_type}", **cache_params)
else:
    raise ValueError(f"Type de cache non supporté: {self.cache_type}")

# Configurer le benchmark
config = {{
    "test_id": "{self.test_id}",
    "cache_type": "{self.cache_type}",
    "benchmark_type": "{self.benchmark_type}",
    "dataset_size": {self.dataset_size},
    "value_size": {self.value_size},
    "data_distribution": "{self.data_distribution}",
    "operation_mix": {self.operation_mix},
    "concurrency_level": {self.concurrency_level},
    "duration_seconds": {self.duration_seconds},
    "expected_hit_ratio": {self.expected_hit_ratio},
    "max_latency_ms": {self.max_latency_ms},
    "max_memory_mb": {self.max_memory_mb},
    "timeout": {self.timeout},
    "output_dir": "{self.output_dir}"
}}

# Exécuter le benchmark
results = run_benchmark(cache, config)

# Générer le rapport
report_file = generate_report(results, config)

print(f"Benchmark terminé. Rapport généré: {{report_file}}")
"""
        return script
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit la spécification de test en dictionnaire.
        
        Returns:
            Dict[str, Any]: Dictionnaire représentant la spécification de test.
        """
        return asdict(self)
    
    def to_json(self) -> str:
        """
        Convertit la spécification de test en chaîne JSON.
        
        Returns:
            str: Chaîne JSON représentant la spécification de test.
        """
        return json.dumps(self.to_dict(), indent=4)
    
    def save(self, file_path: Optional[str] = None) -> str:
        """
        Enregistre la spécification de test dans un fichier JSON.
        
        Args:
            file_path (str, optional): Chemin du fichier. Si None, utilise le test_id.
                Par défaut: None.
                
        Returns:
            str: Chemin du fichier enregistré.
        """
        if file_path is None:
            file_path = os.path.join(self.output_dir, f"{self.test_id}.json")
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(self.to_json())
        
        return file_path
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'CacheTestSpec':
        """
        Crée une spécification de test à partir d'un dictionnaire.
        
        Args:
            data (Dict[str, Any]): Dictionnaire représentant la spécification de test.
            
        Returns:
            CacheTestSpec: Spécification de test.
        """
        return cls(**data)
    
    @classmethod
    def from_json(cls, json_str: str) -> 'CacheTestSpec':
        """
        Crée une spécification de test à partir d'une chaîne JSON.
        
        Args:
            json_str (str): Chaîne JSON représentant la spécification de test.
            
        Returns:
            CacheTestSpec: Spécification de test.
        """
        return cls.from_dict(json.loads(json_str))
    
    @classmethod
    def load(cls, file_path: str) -> 'CacheTestSpec':
        """
        Charge une spécification de test à partir d'un fichier JSON.
        
        Args:
            file_path (str): Chemin du fichier.
            
        Returns:
            CacheTestSpec: Spécification de test.
        """
        with open(file_path, 'r', encoding='utf-8') as f:
            return cls.from_json(f.read())
    
    @property
    def unique_id(self) -> str:
        """
        Génère un identifiant unique pour la spécification de test.
        
        Returns:
            str: Identifiant unique.
        """
        # Créer une chaîne représentant les paramètres clés
        key_str = f"{self.cache_type}_{self.benchmark_type}_{self.dataset_size}_{self.value_size}_{self.data_distribution}_{self.concurrency_level}_{self.duration_seconds}"
        
        # Ajouter un hash des paramètres spécifiques au cache
        if self.cache_params:
            cache_params_str = json.dumps(self.cache_params, sort_keys=True)
            key_str += f"_{hashlib.md5(cache_params_str.encode()).hexdigest()[:8]}"
        
        # Ajouter un timestamp pour garantir l'unicité
        key_str += f"_{int(time.time())}"
        
        return key_str


def create_test_spec(
    test_id: str,
    cache_type: Union[CacheType, str],
    benchmark_type: Union[BenchmarkType, str],
    dataset_size: int,
    value_size: int,
    **kwargs
) -> CacheTestSpec:
    """
    Crée une spécification de test pour le système de cache.
    
    Args:
        test_id (str): Identifiant unique du test.
        cache_type (Union[CacheType, str]): Type de cache à tester.
        benchmark_type (Union[BenchmarkType, str]): Type de benchmark à exécuter.
        dataset_size (int): Taille du jeu de données (nombre d'éléments).
        value_size (int): Taille moyenne des valeurs en octets.
        **kwargs: Paramètres supplémentaires pour la spécification de test.
        
    Returns:
        CacheTestSpec: Spécification de test.
    """
    return CacheTestSpec(
        test_id=test_id,
        cache_type=cache_type,
        benchmark_type=benchmark_type,
        dataset_size=dataset_size,
        value_size=value_size,
        **kwargs
    )


def create_standard_test_suite() -> List[CacheTestSpec]:
    """
    Crée une suite de tests standard pour le système de cache.
    
    Returns:
        List[CacheTestSpec]: Liste de spécifications de test.
    """
    test_suite = []
    
    # Tests de performance pour différents types de cache
    for cache_type in [CacheType.LRU, CacheType.LFU, CacheType.ARC]:
        # Test de débit (throughput)
        test_suite.append(create_test_spec(
            test_id=f"throughput_{cache_type.value}",
            cache_type=cache_type,
            benchmark_type=BenchmarkType.THROUGHPUT,
            dataset_size=100000,
            value_size=1024,
            duration_seconds=30
        ))
        
        # Test de latence
        test_suite.append(create_test_spec(
            test_id=f"latency_{cache_type.value}",
            cache_type=cache_type,
            benchmark_type=BenchmarkType.LATENCY,
            dataset_size=10000,
            value_size=1024,
            duration_seconds=30
        ))
        
        # Test de taux de succès (hit ratio)
        test_suite.append(create_test_spec(
            test_id=f"hit_ratio_{cache_type.value}",
            cache_type=cache_type,
            benchmark_type=BenchmarkType.HIT_RATIO,
            dataset_size=10000,
            value_size=1024,
            data_distribution=DataDistribution.ZIPF,
            duration_seconds=30
        ))
    
    # Tests de concurrence
    for concurrency in [2, 4, 8]:
        test_suite.append(create_test_spec(
            test_id=f"concurrency_{concurrency}",
            cache_type=CacheType.THREAD_SAFE,
            benchmark_type=BenchmarkType.CONCURRENCY,
            dataset_size=10000,
            value_size=1024,
            concurrency_level=concurrency,
            duration_seconds=30
        ))
    
    # Tests avec différentes distributions de données
    for distribution in [DataDistribution.UNIFORM, DataDistribution.ZIPF, DataDistribution.SEQUENTIAL]:
        test_suite.append(create_test_spec(
            test_id=f"distribution_{distribution.value}",
            cache_type=CacheType.LRU,
            benchmark_type=BenchmarkType.HIT_RATIO,
            dataset_size=10000,
            value_size=1024,
            data_distribution=distribution,
            duration_seconds=30
        ))
    
    # Tests avec différentes tailles de valeurs
    for value_size in [128, 1024, 8192]:
        test_suite.append(create_test_spec(
            test_id=f"value_size_{value_size}",
            cache_type=CacheType.LRU,
            benchmark_type=BenchmarkType.MEMORY,
            dataset_size=10000,
            value_size=value_size,
            duration_seconds=30
        ))
    
    return test_suite


if __name__ == "__main__":
    # Exemple d'utilisation
    test_spec = create_test_spec(
        test_id="test_lru_throughput",
        cache_type=CacheType.LRU,
        benchmark_type=BenchmarkType.THROUGHPUT,
        dataset_size=10000,
        value_size=1024,
        duration_seconds=30
    )
    
    print(test_spec.to_json())
    
    # Générer un script de test
    script = test_spec.test_script
    print("\nScript de test généré:")
    print(script)
    
    # Créer une suite de tests standard
    test_suite = create_standard_test_suite()
    print(f"\nSuite de tests standard créée avec {len(test_suite)} tests.")
