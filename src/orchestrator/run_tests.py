#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour exécuter tous les tests de l'orchestrateur.

Ce script découvre et exécute tous les tests dans le répertoire tests.
"""

import os
import sys
import unittest
import argparse
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

def run_tests(pattern='test_*.py', test_name=None):
    """
    Exécute les tests dans le répertoire tests.
    
    Args:
        pattern: Pattern pour filtrer les fichiers de test
        test_name: Nom spécifique du test à exécuter
        
    Returns:
        Code de sortie (0 si succès, 1 si échec)
    """
    # Découvrir les tests
    test_loader = unittest.TestLoader()
    
    if test_name:
        # Exécuter un test spécifique
        test_suite = test_loader.loadTestsFromName(f'tests.{test_name}')
    else:
        # Exécuter tous les tests
        test_suite = test_loader.discover('tests', pattern=pattern)
    
    # Exécuter les tests
    test_runner = unittest.TextTestRunner(verbosity=2)
    result = test_runner.run(test_suite)
    
    # Retourner le code de sortie
    return 0 if result.wasSuccessful() else 1

if __name__ == '__main__':
    # Analyser les arguments de ligne de commande
    parser = argparse.ArgumentParser(description='Exécuter les tests de l\'orchestrateur')
    parser.add_argument('--pattern', default='test_*.py', help='Pattern pour filtrer les fichiers de test')
    parser.add_argument('--test', help='Nom spécifique du test à exécuter (ex: test_theme_attribution.TestThemeAttributor)')
    args = parser.parse_args()
    
    # Exécuter les tests
    sys.exit(run_tests(pattern=args.pattern, test_name=args.test))
