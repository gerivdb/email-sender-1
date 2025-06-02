#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script qui garantit une couverture de code à 100% pour les tests du module test_example.
"""

import coverage
import os
import sys
import unittest
import pytest
import importlib.util

def run_coverage():
    """Exécute les tests avec une couverture à 100%."""
    # Charger le module depuis le chemin du fichier
    module_path = "development/scripts/python/testing/examples/test_example.py"
    
    # Configuration de la couverture
    cov = coverage.Coverage(
        source=["development.scripts.python.testing.examples.test_example"],
        omit=["*/__pycache__/*", "*/site-packages/*"],
    )
    
    # Démarrer la mesure de couverture
    cov.start()
    
    # Exécuter tous les tests
    result = pytest.main([module_path, "-v"])
    
    # Arrêter la mesure de couverture
    cov.stop()
    
    # Générer un rapport HTML
    cov.html_report(directory="coverage_html_report")
    
    # Afficher un résumé dans la console
    percentage = cov.report()
    
    print(f"Couverture de code totale: {percentage:.2f}%")
    return percentage

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    percentage = run_coverage()
    # Vérifier si la couverture est à 100%
    if percentage >= 100.0:
        print("✅ Couverture parfaite à 100% atteinte!")
        sys.exit(0)
    else:
        print(f"❌ La couverture est de {percentage:.2f}%, pas encore à 100%")
        sys.exit(1)
