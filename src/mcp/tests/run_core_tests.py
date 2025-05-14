#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour exécuter tous les tests du Core MCP.

Ce script exécute tous les tests unitaires pour le Core MCP.
"""

import sys
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer les tests
from src.mcp.tests.core.test_mcp_core import TestMCPCore
from src.mcp.tests.core.test_tools_manager import TestToolsManager
from src.mcp.tests.core.test_memory_manager import TestMemory, TestMemoryManager
from src.mcp.tests.roadmap.test_cognitive_architecture import TestCognitiveNode, TestCosmos, TestGalaxy, TestStellarSystem
from src.mcp.tests.roadmap.test_cognitive_manager import TestCognitiveManager

def run_tests():
    """Exécute tous les tests du Core MCP."""
    # Créer une suite de tests
    test_suite = unittest.TestSuite()

    # Ajouter les tests
    test_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(TestMCPCore))
    test_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(TestToolsManager))
    test_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(TestMemory))
    test_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(TestMemoryManager))
    test_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(TestCognitiveNode))
    test_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(TestCosmos))
    test_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(TestGalaxy))
    test_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(TestStellarSystem))
    test_suite.addTest(unittest.TestLoader().loadTestsFromTestCase(TestCognitiveManager))

    # Exécuter les tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)

    # Retourner le résultat
    return result.wasSuccessful()

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
