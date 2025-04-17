#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour les décorateurs de cache.

Ce module contient les tests unitaires pour les décorateurs de cache
utilisés pour faciliter l'intégration du cache dans l'application.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import time
import unittest
from unittest.mock import patch, MagicMock
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..')))
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.decorators import (
    cached, cached_property, cached_class, timed_cache, cache_result
)


class TestCachedDecorator(unittest.TestCase):
    """Tests pour le décorateur cached."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.cache = LocalCache()
        self.cache.clear()

        # Compteur d'appels pour vérifier si la fonction est réellement appelée
        self.call_count = 0

    def tearDown(self):
        """Nettoyage après chaque test."""
        self.cache.clear()

    def test_cached_decorator(self):
        """Teste le décorateur cached."""
        # Définir une fonction à mettre en cache
        @cached(cache_instance=self.cache)
        def test_function(param):
            self.call_count += 1
            return f"result_{param}"

        # Premier appel (exécute la fonction)
        result1 = test_function("test")
        self.assertEqual(result1, "result_test")
        self.assertEqual(self.call_count, 1)

        # Deuxième appel (utilise le cache)
        result2 = test_function("test")
        self.assertEqual(result2, "result_test")
        self.assertEqual(self.call_count, 1)  # Le compteur ne doit pas augmenter

        # Appel avec un paramètre différent (exécute la fonction)
        result3 = test_function("other")
        self.assertEqual(result3, "result_other")
        self.assertEqual(self.call_count, 2)

    def test_cached_decorator_with_ttl(self):
        """Teste le décorateur cached avec TTL."""
        # Définir une fonction à mettre en cache avec un TTL court
        @cached(ttl=1, cache_instance=self.cache)
        def test_function(param):
            self.call_count += 1
            return f"result_{param}"

        # Premier appel (exécute la fonction)
        result1 = test_function("test")
        self.assertEqual(result1, "result_test")
        self.assertEqual(self.call_count, 1)

        # Deuxième appel immédiat (utilise le cache)
        result2 = test_function("test")
        self.assertEqual(result2, "result_test")
        self.assertEqual(self.call_count, 1)

        # Attendre l'expiration du TTL
        time.sleep(1.1)

        # Troisième appel après expiration (exécute la fonction)
        result3 = test_function("test")
        self.assertEqual(result3, "result_test")
        self.assertEqual(self.call_count, 2)

    def test_cached_decorator_with_key_prefix(self):
        """Teste le décorateur cached avec un préfixe de clé."""
        # Définir une fonction à mettre en cache avec un préfixe
        @cached(key_prefix="prefix:", cache_instance=self.cache)
        def test_function(param):
            self.call_count += 1
            return f"result_{param}"

        # Premier appel (exécute la fonction)
        result = test_function("test")
        self.assertEqual(result, "result_test")
        self.assertEqual(self.call_count, 1)

        # Vérifier que la clé a le bon préfixe
        cache_key = test_function.get_cache_key("test")
        self.assertTrue(cache_key.startswith("prefix:"))

    def test_invalidate_cache(self):
        """Teste l'invalidation du cache."""
        # Définir une fonction à mettre en cache
        @cached(cache_instance=self.cache)
        def test_function(param):
            self.call_count += 1
            return f"result_{param}"

        # Premier appel (exécute la fonction)
        result1 = test_function("test")
        self.assertEqual(result1, "result_test")
        self.assertEqual(self.call_count, 1)

        # Invalider le cache
        test_function.invalidate_cache("test")

        # Deuxième appel après invalidation (exécute la fonction)
        result2 = test_function("test")
        self.assertEqual(result2, "result_test")
        self.assertEqual(self.call_count, 2)


class TestCachedPropertyDecorator(unittest.TestCase):
    """Tests pour le décorateur cached_property."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.cache = LocalCache()
        self.cache.clear()

    def tearDown(self):
        """Nettoyage après chaque test."""
        self.cache.clear()

    def test_cached_property_decorator(self):
        """Teste le décorateur cached_property."""
        # Utiliser un compteur global pour suivre les appels
        global property_call_count
        property_call_count = 0

        # Définir une classe avec une propriété mise en cache
        class TestClass:
            def __init__(self, value):
                self.value = value

            @cached_property(cache_instance=self.cache)
            def expensive_property(self):
                global property_call_count
                property_call_count += 1
                return f"result_{self.value}"

        # Créer une instance
        instance = TestClass("test")

        # Premier accès (calcule la propriété)
        result1 = instance.expensive_property
        self.assertEqual(result1, "result_test")
        self.assertEqual(property_call_count, 1)

        # Deuxième accès (utilise le cache)
        result2 = instance.expensive_property
        self.assertEqual(result2, "result_test")
        self.assertEqual(property_call_count, 1)  # Le compteur ne doit pas augmenter

        # Créer une autre instance
        instance2 = TestClass("other")

        # Accès à la propriété de la deuxième instance (calcule la propriété)
        result3 = instance2.expensive_property
        self.assertEqual(result3, "result_other")
        self.assertEqual(property_call_count, 2)


# Variables globales pour les tests
property_call_count = 0
class_init_count = 0

class TestCachedClassDecorator(unittest.TestCase):
    """Tests pour le décorateur cached_class."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.cache = LocalCache()
        self.cache.clear()
        # Réinitialiser le compteur global
        global class_init_count
        class_init_count = 0

    def tearDown(self):
        """Nettoyage après chaque test."""
        self.cache.clear()

    def test_cached_class_decorator(self):
        """Teste le décorateur cached_class."""
        # Définir une classe mise en cache
        @cached_class(cache_instance=self.cache)
        class TestClass:
            def __init__(self, value):
                self.value = value
                global class_init_count
                class_init_count += 1

            def get_value(self):
                return f"result_{self.value}"

        # Première création d'instance (appelle le constructeur)
        instance1 = TestClass("test")
        self.assertEqual(instance1.get_value(), "result_test")
        self.assertEqual(class_init_count, 1)

        # Deuxième création d'instance avec les mêmes paramètres (appelle le constructeur)
        instance2 = TestClass("test")
        self.assertEqual(instance2.get_value(), "result_test")
        self.assertEqual(class_init_count, 2)  # Le constructeur est appelé à nouveau

        # Création d'instance avec des paramètres différents (appelle le constructeur)
        instance3 = TestClass("other")
        self.assertEqual(instance3.get_value(), "result_other")
        self.assertEqual(class_init_count, 3)

    def test_invalidate_cache(self):
        """Teste l'invalidation du cache."""
        # Utiliser une fonction simple pour tester l'invalidation
        call_count = [0]  # Utiliser une liste pour pouvoir modifier la valeur dans la fonction

        @cached(cache_instance=self.cache)
        def test_function(param):
            call_count[0] += 1
            return f"result_{param}"

        # Premier appel (exécute la fonction)
        result1 = test_function("test")
        self.assertEqual(result1, "result_test")
        self.assertEqual(call_count[0], 1)

        # Deuxième appel (utilise le cache)
        result2 = test_function("test")
        self.assertEqual(result2, "result_test")
        self.assertEqual(call_count[0], 1)  # Le compteur ne doit pas augmenter

        # Invalider le cache
        test_function.invalidate_cache("test")

        # Troisième appel après invalidation (exécute la fonction)
        result3 = test_function("test")
        self.assertEqual(result3, "result_test")
        self.assertEqual(call_count[0], 2)


class TestTimedCacheDecorator(unittest.TestCase):
    """Tests pour le décorateur timed_cache."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Compteur d'appels pour vérifier si la fonction est réellement appelée
        self.call_count = 0

    def test_timed_cache_decorator(self):
        """Teste le décorateur timed_cache."""
        # Définir une fonction avec un cache temporisé
        @timed_cache(seconds=1)
        def test_function(param):
            self.call_count += 1
            return f"result_{param}"

        # Premier appel (exécute la fonction)
        result1 = test_function("test")
        self.assertEqual(result1, "result_test")
        self.assertEqual(self.call_count, 1)

        # Deuxième appel immédiat (utilise le cache)
        result2 = test_function("test")
        self.assertEqual(result2, "result_test")
        self.assertEqual(self.call_count, 1)

        # Attendre l'expiration du cache
        time.sleep(1.1)

        # Troisième appel après expiration (exécute la fonction)
        result3 = test_function("test")
        self.assertEqual(result3, "result_test")
        self.assertEqual(self.call_count, 2)

    def test_timed_cache_with_different_params(self):
        """Teste le décorateur timed_cache avec différents paramètres."""
        # Définir une fonction avec un cache temporisé
        @timed_cache(seconds=1)
        def test_function(param):
            self.call_count += 1
            return f"result_{param}"

        # Appel avec un paramètre
        result1 = test_function("test1")
        self.assertEqual(result1, "result_test1")
        self.assertEqual(self.call_count, 1)

        # Appel avec un paramètre différent
        result2 = test_function("test2")
        self.assertEqual(result2, "result_test2")
        self.assertEqual(self.call_count, 2)

        # Appel à nouveau avec le premier paramètre (utilise le cache)
        result3 = test_function("test1")
        self.assertEqual(result3, "result_test1")
        self.assertEqual(self.call_count, 2)

    def test_timed_cache_clear(self):
        """Teste la méthode cache_clear du décorateur timed_cache."""
        # Définir une fonction avec un cache temporisé
        @timed_cache(seconds=60)
        def test_function(param):
            self.call_count += 1
            return f"result_{param}"

        # Premier appel (exécute la fonction)
        result1 = test_function("test")
        self.assertEqual(result1, "result_test")
        self.assertEqual(self.call_count, 1)

        # Vider le cache
        test_function.cache_clear()

        # Deuxième appel après vidage du cache (exécute la fonction)
        result2 = test_function("test")
        self.assertEqual(result2, "result_test")
        self.assertEqual(self.call_count, 2)


class TestCacheResultDecorator(unittest.TestCase):
    """Tests pour le décorateur cache_result."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.cache = LocalCache()
        self.cache.clear()

        # Compteur d'appels pour vérifier si la fonction est réellement appelée
        self.call_count = 0

    def tearDown(self):
        """Nettoyage après chaque test."""
        self.cache.clear()

    def test_cache_result_decorator(self):
        """Teste le décorateur cache_result."""
        # Définir une fonction qui extrait la clé du résultat
        def extract_key(result):
            return f"key:{result['id']}"

        # Définir une fonction à mettre en cache
        @cache_result(result_key=extract_key, cache_instance=self.cache)
        def test_function(param):
            self.call_count += 1
            return {"id": param, "value": f"result_{param}"}

        # Premier appel (exécute la fonction)
        result1 = test_function("test")
        self.assertEqual(result1, {"id": "test", "value": "result_test"})
        self.assertEqual(self.call_count, 1)

        # Récupérer le résultat du cache
        cached_result = test_function.get_cached("key:test")
        self.assertEqual(cached_result, {"id": "test", "value": "result_test"})

        # Invalider le cache
        test_function.invalidate("key:test")

        # Vérifier que le résultat n'est plus dans le cache
        cached_result = test_function.get_cached("key:test")
        self.assertIsNone(cached_result)


if __name__ == '__main__':
    unittest.main()
