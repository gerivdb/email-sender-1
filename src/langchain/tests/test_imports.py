#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test d'importation des modules Langchain.

Ce module vérifie que tous les modules Langchain peuvent être importés correctement.
"""

import os
import sys
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

class TestImports(unittest.TestCase):
    """Tests pour vérifier les importations."""
    
    def test_import_tools(self):
        """Teste l'importation des outils."""
        try:
            from src.langchain.tools import (
                CodeAnalysisTools,
                DocumentationTools,
                RecommendationTools
            )
            self.assertTrue(True)
        except ImportError as e:
            self.fail(f"Erreur d'importation: {str(e)}")
    
    def test_import_agents(self):
        """Teste l'importation des agents."""
        try:
            from src.langchain.agents import (
                BaseAgent,
                GitHubAnalysisAgent,
                ServerDiagnosticAgent,
                PerformanceAnalysisAgent
            )
            self.assertTrue(True)
        except ImportError as e:
            self.fail(f"Erreur d'importation: {str(e)}")
    
    def test_import_chains(self):
        """Teste l'importation des chaînes."""
        try:
            from src.langchain.chains import (
                BaseLLMChain,
                EmailGenerationChain,
                EmailAnalysisChain,
                BaseSequentialChain,
                EmailProcessingChain,
                BaseRouterChain,
                EmailResponseRouterChain
            )
            self.assertTrue(True)
        except ImportError as e:
            self.fail(f"Erreur d'importation: {str(e)}")

if __name__ == '__main__':
    unittest.main()
