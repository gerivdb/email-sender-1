#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation du Tools Manager.

Ce script montre comment utiliser le Tools Manager pour découvrir et utiliser des outils.
"""

import os
import sys
import json
import logging
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
print(f"Ajout du répertoire parent au chemin de recherche: {parent_dir}")
sys.path.append(parent_dir)

# Importer les modules nécessaires
try:
    from src.mcp.core.mcp.tools_manager import ToolsManager
    print("Modules importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    sys.exit(1)

# Configuration du logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("tools_manager_example")

def main():
    """
    Fonction principale.
    """
    # Créer une instance du Tools Manager
    tools_manager = ToolsManager()

    # Chemin vers le package d'outils
    tools_package_path = os.path.join(os.path.dirname(__file__), "tools")

    # Découvrir les outils
    logger.info(f"Découverte des outils dans le package: {tools_package_path}")

    # Ajouter le répertoire parent au sys.path
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))

    discovered_tools = tools_manager.discover_tools(tools_package_path, "src.mcp.examples.tools")
    logger.info(f"Outils découverts: {discovered_tools}")

    # Lister tous les outils
    tools = tools_manager.list_tools()
    logger.info(f"Liste des outils ({len(tools)}):")
    for tool in tools:
        logger.info(f"  - {tool['name']}: {tool['description']}")
        logger.info(f"    Paramètres: {json.dumps(tool['parameters'], indent=2)}")

    # Utiliser quelques outils
    try:
        # Utiliser l'outil add
        add_tool = tools_manager.get_tool("add")
        if add_tool:
            result = add_tool(2, 3)
            logger.info(f"Résultat de add(2, 3): {result}")

        # Utiliser l'outil multiply
        multiply_tool = tools_manager.get_tool("multiply")
        if multiply_tool:
            result = multiply_tool(4, 5)
            logger.info(f"Résultat de multiply(4, 5): {result}")

        # Utiliser l'outil to_upper
        to_upper_tool = tools_manager.get_tool("to_upper")
        if to_upper_tool:
            result = to_upper_tool("hello world")
            logger.info(f"Résultat de to_upper('hello world'): {result}")

        # Utiliser l'outil reverse
        reverse_tool = tools_manager.get_tool("reverse")
        if reverse_tool:
            result = reverse_tool("hello world")
            logger.info(f"Résultat de reverse('hello world'): {result}")

    except Exception as e:
        logger.error(f"Erreur lors de l'utilisation des outils: {e}")

    # Désenregistrer un outil
    tools_manager.unregister_tool("add")
    logger.info("Outil 'add' désenregistré")

    # Vérifier que l'outil a été désenregistré
    tools = tools_manager.list_tools()
    logger.info(f"Liste des outils après désenregistrement ({len(tools)}):")
    for tool in tools:
        logger.info(f"  - {tool['name']}: {tool['description']}")

if __name__ == "__main__":
    main()
