#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de débogage du gestionnaire CRUD.
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

print("Débogage du gestionnaire CRUD...")

# Créer un répertoire temporaire
temp_dir = tempfile.mkdtemp()
print(f"Répertoire temporaire créé: {temp_dir}")

try:
    # Créer les répertoires
    storage_path = os.path.join(temp_dir, "storage")
    archive_path = os.path.join(temp_dir, "archive")
    
    print(f"Création des répertoires {storage_path} et {archive_path}...")
    os.makedirs(storage_path, exist_ok=True)
    os.makedirs(archive_path, exist_ok=True)
    
    # Importer les modules
    print("Importation des modules...")
    from src.orchestrator.thematic_crud.theme_attribution import ThemeAttributor
    print("ThemeAttributor importé.")
    
    from src.orchestrator.thematic_crud.create_update import ThematicCreateUpdate
    print("ThematicCreateUpdate importé.")
    
    from src.orchestrator.thematic_crud.read_search import ThematicReadSearch
    print("ThematicReadSearch importé.")
    
    from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
    print("ThematicDeleteArchive importé.")
    
    # Créer les composants individuels
    print("Création des composants individuels...")
    
    print("Création de ThemeAttributor...")
    theme_attributor = ThemeAttributor()
    print("ThemeAttributor créé.")
    
    print("Création de ThematicCreateUpdate...")
    create_update = ThematicCreateUpdate(storage_path)
    print("ThematicCreateUpdate créé.")
    
    print("Création de ThematicReadSearch...")
    read_search = ThematicReadSearch(storage_path)
    print("ThematicReadSearch créé.")
    
    print("Création de ThematicDeleteArchive...")
    delete_archive = ThematicDeleteArchive(storage_path, archive_path)
    print("ThematicDeleteArchive créé.")
    
    # Importer le gestionnaire CRUD
    print("Importation de ThematicCRUDManager...")
    from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
    print("ThematicCRUDManager importé.")
    
    # Créer un gestionnaire CRUD
    print("Création d'un gestionnaire CRUD...")
    manager = ThematicCRUDManager(storage_path, archive_path)
    print("Gestionnaire CRUD créé avec succès.")
    
    print("Débogage du gestionnaire CRUD terminé avec succès.")

except Exception as e:
    print(f"ERREUR: {str(e)}")
    import traceback
    traceback.print_exc()

finally:
    # Supprimer le répertoire temporaire
    print(f"Suppression du répertoire temporaire {temp_dir}...")
    shutil.rmtree(temp_dir)
