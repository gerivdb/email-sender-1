#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de test d'importation des modules.
"""

import os
import sys
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

print("Test d'importation des modules...")

try:
    print("Importation de ThematicCRUDManager...")
    from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
    print("Importation réussie.")
    
    print("Importation de ThematicDeleteArchive...")
    from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
    print("Importation réussie.")
    
    print("Test d'importation des modules terminé avec succès.")

except Exception as e:
    print(f"ERREUR: {str(e)}")
    import traceback
    traceback.print_exc()
