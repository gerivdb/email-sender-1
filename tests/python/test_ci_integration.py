#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour l'intégration CI/CD
"""

import os
import sys
import unittest
import subprocess
from pathlib import Path


class TestCIIntegration(unittest.TestCase):
    """Tests pour l'intégration CI/CD"""

    def setUp(self):
        """Initialisation des tests"""
        # Obtenir le chemin racine du projet
        self.project_root = Path(__file__).parent.parent.parent
        
        # Définir les chemins des scripts
        self.ci_script = self.project_root / "scripts" / "ci" / "run-ci-checks.ps1"
        self.github_workflow = self.project_root / ".github" / "workflows" / "ci.yml"

    def test_ci_script_exists(self):
        """Vérifier que le script CI existe"""
        self.assertTrue(self.ci_script.exists(), f"Le script {self.ci_script} n'existe pas")

    def test_github_workflow_exists(self):
        """Vérifier que le workflow GitHub Actions existe"""
        self.assertTrue(self.github_workflow.exists(), f"Le workflow {self.github_workflow} n'existe pas")

    def test_github_workflow_content(self):
        """Vérifier que le workflow GitHub Actions contient les jobs nécessaires"""
        with open(self.github_workflow, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Vérifier que les jobs nécessaires sont présents
        self.assertIn("lint:", content, "Le job 'lint' est manquant dans le workflow")
        self.assertIn("test:", content, "Le job 'test' est manquant dans le workflow")
        self.assertIn("security:", content, "Le job 'security' est manquant dans le workflow")
        self.assertIn("build:", content, "Le job 'build' est manquant dans le workflow")

    @unittest.skipIf(sys.platform != "win32", "Test uniquement sur Windows")
    def test_ci_script_syntax(self):
        """Vérifier que le script CI ne contient pas d'erreurs de syntaxe PowerShell"""
        # Utiliser PowerShell pour vérifier la syntaxe du script
        result = subprocess.run(
            ["powershell", "-Command", f"Test-ScriptFileInfo -Path '{self.ci_script}' -ErrorAction SilentlyContinue"],
            capture_output=True,
            text=True
        )
        
        # Si le script n'a pas d'erreurs de syntaxe, la commande ne devrait pas échouer
        self.assertEqual(result.returncode, 0, f"Le script {self.ci_script} contient des erreurs de syntaxe")


if __name__ == "__main__":
    unittest.main()
