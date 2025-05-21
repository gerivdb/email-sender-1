#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour vérifier les dépendances.
"""

import sys

def check_dependency(module_name):
    """Vérifie si un module est disponible."""
    try:
        __import__(module_name)
        print(f"{module_name} is available")
        return True
    except ImportError:
        print(f"{module_name} is not available")
        return False

# Liste des dépendances à vérifier
dependencies = [
    "sklearn",
    "numpy",
    "requests",
    "json",
    "re",
    "datetime",
    "collections",
    "pathlib",
    "os",
    "sys",
    "glob",
    "uuid",
    "shutil",
    "tempfile",
    "time",
    "math",
    "pickle"
]

# Vérifier chaque dépendance
for dependency in dependencies:
    check_dependency(dependency)

print("\nEnvironnement Python:")
print(f"Python version: {sys.version}")
print(f"Python executable: {sys.executable}")
