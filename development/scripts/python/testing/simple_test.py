#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script simple pour exécuter les tests et capturer les erreurs.
"""

import os
import sys
import json
import subprocess
from datetime import datetime

def run_tests(test_directory, pattern="test_*.py"):
    """Exécute les tests et capture les erreurs."""
    cmd = ["python", "-m", "pytest", test_directory, "-v"]
    result = subprocess.run(cmd, capture_output=True, text=True)

    # Analyser la sortie pour extraire les erreurs
    errors = []

    if result.returncode != 0:
        # Extraire les erreurs de la sortie
        lines = result.stdout.split("\n")
        current_error = None

        for line in lines:
            if "FAILED" in line and "::" in line:
                # Nouvelle erreur
                test_path = line.split("::")[0].strip()
                test_name = line.split("::")[-1].split()[0].strip()
                current_error = {
                    "test_path": test_path,
                    "test_name": test_name,
                    "error_type": None,
                    "error_message": None,
                    "traceback": []
                }
                errors.append(current_error)
            elif current_error and "Error:" in line:
                # Type d'erreur
                error_parts = line.split("Error:", 1)
                if len(error_parts) > 1:
                    current_error["error_type"] = error_parts[0].strip() + "Error"
                    current_error["error_message"] = error_parts[1].strip()
            elif current_error and line.strip().startswith("E "):
                # Ligne d'erreur
                current_error["traceback"].append(line.strip())

    # Sauvegarder les erreurs dans un fichier JSON
    error_db = {
        "timestamp": datetime.now().isoformat(),
        "errors": errors
    }

    with open("error_database_simple.json", "w") as f:
        json.dump(error_db, f, indent=2)

    return errors

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python simple_test.py <test_directory> [pattern]")
        sys.exit(1)

    test_directory = sys.argv[1]
    pattern = sys.argv[2] if len(sys.argv) > 2 else "test_*.py"

    errors = run_tests(test_directory, pattern)

    print(f"Trouvé {len(errors)} erreurs.")
    for i, error in enumerate(errors):
        print(f"{i+1}. {error['test_name']} - {error['error_type']}: {error['error_message']}")
