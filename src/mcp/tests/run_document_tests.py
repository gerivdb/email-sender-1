#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour exécuter les tests du module de document MCP.

Ce script exécute tous les tests unitaires pour le module de document MCP.
"""

import os
import sys
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent))

# Importer les modules de test
from mcp.tests.document.test_document_manager import TestDocumentManager
from mcp.tests.document.test_document_tools import TestDocumentTools

def run_tests():
    """Exécute tous les tests du module de document MCP."""
    # Créer une suite de tests
    test_suite = unittest.TestSuite()
    
    # Ajouter les tests
    test_suite.addTest(unittest.makeSuite(TestDocumentManager))
    test_suite.addTest(unittest.makeSuite(TestDocumentTools))
    
    # Exécuter les tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)
    
    # Retourner le code de sortie
    return 0 if result.wasSuccessful() else 1

if __name__ == "__main__":
    sys.exit(run_tests())
