#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour exécuter tous les tests des outils de code MCP.

Ce script exécute tous les tests unitaires pour les outils de code MCP.
"""

import os
import sys
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer les tests
from src.mcp.tests.code.test_code_manager import TestCodeManager
from src.mcp.tests.code.test_code_tools import TestCodeTools

def run_tests():
    """Exécute tous les tests des outils de code MCP."""
    # Créer une suite de tests
    test_suite = unittest.TestSuite()
    
    # Ajouter les tests
    test_suite.addTest(unittest.makeSuite(TestCodeManager))
    test_suite.addTest(unittest.makeSuite(TestCodeTools))
    
    # Exécuter les tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)
    
    # Retourner le résultat
    return result.wasSuccessful()

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
