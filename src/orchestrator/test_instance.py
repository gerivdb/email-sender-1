#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test de création d'une instance de ThematicDeleteArchive.
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

print("Test de création d'une instance de ThematicDeleteArchive...")
sys.stdout.flush()

# Créer un répertoire temporaire
temp_dir = tempfile.mkdtemp()
storage_path = os.path.join(temp_dir, "storage")
archive_path = os.path.join(temp_dir, "archive")

try:
    # Créer les répertoires
    os.makedirs(storage_path, exist_ok=True)
    os.makedirs(archive_path, exist_ok=True)
    
    print(f"Répertoires créés: {storage_path}, {archive_path}")
    sys.stdout.flush()
    
    # Importer la classe ThematicDeleteArchive
    from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
    
    # Créer une instance de ThematicDeleteArchive
    print("Création d'une instance de ThematicDeleteArchive...")
    sys.stdout.flush()
    
    delete_archive = ThematicDeleteArchive(storage_path, archive_path)
    
    print("Instance de ThematicDeleteArchive créée avec succès!")
    sys.stdout.flush()
    
    print(f"Chemin de stockage: {delete_archive.storage_path}")
    sys.stdout.flush()
    
    print(f"Chemin d'archivage: {delete_archive.archive_path}")
    sys.stdout.flush()
    
    print("Test terminé avec succès!")
    sys.stdout.flush()
    
except Exception as e:
    print(f"ERREUR: {str(e)}")
    sys.stdout.flush()
    import traceback
    traceback.print_exc()
    sys.exit(1)

finally:
    # Supprimer le répertoire temporaire
    print(f"Suppression du répertoire temporaire {temp_dir}...")
    sys.stdout.flush()
    shutil.rmtree(temp_dir)

sys.exit(0)
