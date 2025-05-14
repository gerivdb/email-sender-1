#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour exécuter les tests du module de mémoire MCP.

Ce script exécute tous les tests unitaires pour le module de mémoire MCP.
"""

import os
import sys
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent))

# Importer les modules de test
from mcp.tests.memory.test_memory_manager import TestMemoryManager
from mcp.tests.memory.test_memory_tools import TestMemoryTools

def run_tests():
    """Exécute tous les tests du module de mémoire MCP."""
    # Créer une suite de tests
    test_suite = unittest.TestSuite()

    # Ajouter les tests
    test_suite.addTest(unittest.makeSuite(TestMemoryManager))
    test_suite.addTest(unittest.makeSuite(TestMemoryTools))

    # Exécuter les tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)

    # Retourner le code de sortie
    return 0 if result.wasSuccessful() else 1

if __name__ == "__main__":
    sys.exit(run_tests())
