#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test d'importation de ThematicDeleteArchive.
"""

import os
import sys
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

print("Test d'importation de ThematicDeleteArchive...")
sys.stdout.flush()

try:
    from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
    print("Importation réussie!")
    sys.stdout.flush()
except Exception as e:
    print(f"ERREUR: {str(e)}")
    sys.stdout.flush()
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("Test terminé avec succès!")
sys.stdout.flush()
sys.exit(0)
