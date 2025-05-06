#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour exécuter les tests unitaires des métriques pondérées.
"""

import unittest
import sys
import os
import time

def run_tests():
    """Exécute les tests unitaires et affiche les résultats."""
    start_time = time.time()
    
    # Découvrir et charger tous les tests
    test_loader = unittest.TestLoader()
    test_suite = test_loader.discover(os.path.dirname(os.path.abspath(__file__)), pattern="test_*.py")
    
    # Exécuter les tests
    test_runner = unittest.TextTestRunner(verbosity=2)
    result = test_runner.run(test_suite)
    
    # Afficher un résumé
    elapsed_time = time.time() - start_time
    print("\n" + "=" * 70)
    print(f"Temps d'exécution: {elapsed_time:.2f} secondes")
    print(f"Tests exécutés: {result.testsRun}")
    print(f"Succès: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"Échecs: {len(result.failures)}")
    print(f"Erreurs: {len(result.errors)}")
    print("=" * 70)
    
    # Retourner le code de sortie
    return 0 if result.wasSuccessful() else 1

if __name__ == "__main__":
    sys.exit(run_tests())
