#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test direct des outils de mémoire MCP.

Ce script teste directement les outils de mémoire MCP sans passer par un serveur MCP.
"""

import os
import sys
import json
import traceback
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
print(f"Ajout du répertoire parent au chemin de recherche: {parent_dir}")
sys.path.append(parent_dir)

# Afficher le chemin de recherche des modules
print("Chemin de recherche des modules:")
for path in sys.path:
    print(f"  - {path}")

# Importer les modules nécessaires
from src.mcp.core.memory.MemoryManager import MemoryManager
from src.mcp.core.memory.tools import add_memories, search_memory, list_memories, delete_memories

def main():
    """Fonction principale pour tester les outils de mémoire."""
    try:
        print("Création du gestionnaire de mémoire...")
        # Créer un gestionnaire de mémoire temporaire
        memory_manager = MemoryManager()
        print("Gestionnaire de mémoire créé avec succès")
    except Exception as e:
        print(f"Erreur lors de la création du gestionnaire de mémoire: {e}")
        traceback.print_exc()
        return

    # Tester l'outil add_memories
    print("\n=== Test de l'outil add_memories ===")
    add_params = {
        "memories": [
            {
                "content": "Ceci est une mémoire de test",
                "metadata": {"category": "test", "priority": "high"}
            },
            {
                "content": "Une autre mémoire pour les tests",
                "metadata": {"category": "test", "priority": "medium"}
            }
        ]
    }

    try:
        print("Appel de add_memories...")
        add_result = add_memories.add_memories(memory_manager, add_params)
        print(f"Résultat de add_memories: {json.dumps(add_result, indent=2, ensure_ascii=False)}")
    except Exception as e:
        print(f"Erreur lors de l'appel de add_memories: {e}")
        traceback.print_exc()

    # Tester l'outil list_memories
    print("\n=== Test de l'outil list_memories ===")
    list_params = {
        "page": 1,
        "page_size": 10
    }

    list_result = list_memories.list_memories(memory_manager, list_params)
    print(f"Résultat de list_memories: {json.dumps(list_result, indent=2, ensure_ascii=False)}")

    # Tester l'outil search_memory
    print("\n=== Test de l'outil search_memory ===")
    search_params = {
        "query": "test",
        "limit": 5
    }

    search_result = search_memory.search_memory(memory_manager, search_params)
    print(f"Résultat de search_memory: {json.dumps(search_result, indent=2, ensure_ascii=False)}")

    # Tester l'outil delete_memories
    print("\n=== Test de l'outil delete_memories ===")
    # Récupérer l'ID de la première mémoire
    memory_id = list_result["items"][0]["id"]

    delete_params = {
        "memory_ids": [memory_id]
    }

    delete_result = delete_memories.delete_memories(memory_manager, delete_params)
    print(f"Résultat de delete_memories: {json.dumps(delete_result, indent=2, ensure_ascii=False)}")

    # Vérifier que la mémoire a bien été supprimée
    print("\n=== Vérification après suppression ===")
    list_result_after = list_memories.list_memories(memory_manager, list_params)
    print(f"Résultat de list_memories après suppression: {json.dumps(list_result_after, indent=2, ensure_ascii=False)}")

if __name__ == "__main__":
    main()
