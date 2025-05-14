#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour la gestion des outils MCP.

Ce module contient les classes et fonctions pour gérer les outils MCP,
notamment la découverte, l'enregistrement et la validation des outils.
"""

import os
import sys
import logging
import importlib
import inspect
import pkgutil
import traceback
from typing import Any, Dict, List, Optional, Callable

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.tools_manager")

class ToolsManager:
    """
    Gestionnaire des outils MCP.

    Cette classe gère la découverte, l'enregistrement et la validation des outils MCP.
    """

    def __init__(self):
        """
        Initialise le gestionnaire d'outils.
        """
        self.tools: Dict[str, Callable] = {}
        self.schemas: Dict[str, Dict[str, Any]] = {}
        logger.info("ToolsManager initialisé")

    def discover_tools(self, package_path: str, package_name: Optional[str] = None, recursive: bool = False) -> List[str]:
        """
        Découvre les outils MCP dans un package.

        Args:
            package_path (str): Chemin vers le package contenant les outils
            package_name (Optional[str], optional): Nom du package. Si None, le nom sera dérivé du chemin.
            recursive (bool, optional): Si True, parcourt récursivement les sous-packages. Par défaut False.

        Returns:
            List[str]: Liste des noms des outils découverts
        """
        discovered_tools = []

        # Déterminer le nom du package si non fourni
        if package_name is None:
            package_name = os.path.basename(package_path)

        logger.info(f"Découverte des outils dans le package '{package_name}' ({package_path})")

        # Ajouter le chemin au sys.path si nécessaire
        if package_path not in sys.path:
            sys.path.append(package_path)

        try:
            # Importer le package
            _ = importlib.import_module(package_name)

            # Parcourir les modules du package
            for _, module_name, is_pkg in pkgutil.iter_modules([package_path]):
                if is_pkg and recursive:
                    # C'est un sous-package, le parcourir récursivement si demandé
                    sub_package_path = os.path.join(package_path, module_name)
                    sub_package_name = f"{package_name}.{module_name}"
                    sub_tools = self.discover_tools(sub_package_path, sub_package_name, recursive)
                    discovered_tools.extend(sub_tools)
                    continue
                elif is_pkg:
                    # C'est un sous-package mais on ne le parcourt pas
                    continue

                # Importer le module
                module_full_name = f"{package_name}.{module_name}"
                try:
                    module = importlib.import_module(module_full_name)

                    # Parcourir les attributs du module
                    for attr_name in dir(module):
                        attr = getattr(module, attr_name)

                        # Vérifier si c'est une fonction ou une classe avec un attribut "is_tool"
                        if (inspect.isfunction(attr) or inspect.isclass(attr)) and hasattr(attr, "is_tool"):
                            tool_name = getattr(attr, "tool_name", attr_name)
                            tool_schema = getattr(attr, "tool_schema", {})

                            # Enregistrer l'outil
                            self.register_tool(tool_name, attr, tool_schema)
                            discovered_tools.append(tool_name)
                            logger.info(f"Outil '{tool_name}' découvert dans le module '{module_full_name}'")

                except ImportError as e:
                    logger.error(f"Erreur lors de l'importation du module '{module_full_name}': {e}")
                    logger.debug(traceback.format_exc())
                except Exception as e:
                    logger.error(f"Erreur lors de la découverte des outils dans le module '{module_full_name}': {e}")
                    logger.debug(traceback.format_exc())

        except ImportError as e:
            logger.error(f"Erreur lors de l'importation du package '{package_name}': {e}")
            logger.debug(traceback.format_exc())
        except Exception as e:
            logger.error(f"Erreur lors de la découverte des outils dans le package '{package_name}': {e}")
            logger.debug(traceback.format_exc())

        return discovered_tools

    def register_tool(self, name: str, handler: Callable, schema: Dict[str, Any]) -> None:
        """
        Enregistre un outil MCP.

        Args:
            name (str): Nom de l'outil
            handler (Callable): Fonction de traitement de l'outil
            schema (Dict[str, Any]): Schéma JSON de l'outil
        """
        self.tools[name] = handler
        self.schemas[name] = schema
        logger.info(f"Outil '{name}' enregistré")

    def unregister_tool(self, name: str) -> None:
        """
        Désenregistre un outil MCP.

        Args:
            name (str): Nom de l'outil
        """
        if name in self.tools:
            del self.tools[name]
            del self.schemas[name]
            logger.info(f"Outil '{name}' désenregistré")

    def get_tool(self, name: str) -> Optional[Callable]:
        """
        Récupère un outil MCP par son nom.

        Args:
            name (str): Nom de l'outil

        Returns:
            Optional[Callable]: Fonction de traitement de l'outil, ou None si l'outil n'existe pas
        """
        return self.tools.get(name)

    def get_schema(self, name: str) -> Optional[Dict[str, Any]]:
        """
        Récupère le schéma d'un outil MCP par son nom.

        Args:
            name (str): Nom de l'outil

        Returns:
            Optional[Dict[str, Any]]: Schéma JSON de l'outil, ou None si l'outil n'existe pas
        """
        return self.schemas.get(name)

    def has_tool(self, name: str) -> bool:
        """
        Vérifie si un outil MCP existe.

        Args:
            name (str): Nom de l'outil

        Returns:
            bool: True si l'outil existe, False sinon
        """
        return name in self.tools

    def list_tools(self) -> List[Dict[str, Any]]:
        """
        Liste tous les outils MCP enregistrés.

        Returns:
            List[Dict[str, Any]]: Liste des outils avec leur nom, description et paramètres
        """
        tools = []
        for name, schema in self.schemas.items():
            tools.append({
                "name": name,
                "description": schema.get("description", ""),
                "parameters": schema.get("parameters", {})
            })
        return tools

def tool(name: Optional[str] = None, description: Optional[str] = None, parameters: Optional[Dict[str, Any]] = None):
    """
    Décorateur pour marquer une fonction comme un outil MCP.

    Args:
        name (Optional[str], optional): Nom de l'outil. Si None, le nom de la fonction sera utilisé.
        description (Optional[str], optional): Description de l'outil. Si None, la docstring de la fonction sera utilisée.
        parameters (Optional[Dict[str, Any]], optional): Paramètres de l'outil. Si None, ils seront dérivés de la signature de la fonction.

    Returns:
        Callable: Décorateur
    """
    def decorator(func):
        # Marquer la fonction comme un outil
        func.is_tool = True

        # Définir le nom de l'outil
        func.tool_name = name or func.__name__

        # Définir la description de l'outil
        func.tool_description = description or func.__doc__ or ""

        # Définir les paramètres de l'outil
        if parameters is not None:
            func.tool_parameters = parameters
        else:
            # Dériver les paramètres de la signature de la fonction
            sig = inspect.signature(func)
            params = {}
            for param_name, param in sig.parameters.items():
                if param_name == "self" or param_name == "cls":
                    continue

                param_type = "string"
                if param.annotation != inspect.Parameter.empty:
                    # Obtenir le nom du type pour gérer les types génériques
                    type_name = getattr(param.annotation, "__name__", str(param.annotation))
                    origin = getattr(param.annotation, "__origin__", None)

                    if param.annotation == int or type_name == "int":
                        param_type = "integer"
                    elif param.annotation == float or type_name == "float":
                        param_type = "number"
                    elif param.annotation == bool or type_name == "bool":
                        param_type = "boolean"
                    elif param.annotation == list or type_name == "list" or origin == list:
                        param_type = "array"
                    elif param.annotation == dict or type_name == "dict" or origin == dict:
                        param_type = "object"

                params[param_name] = {
                    "type": param_type,
                    "description": f"Paramètre {param_name}"
                }

            func.tool_parameters = {
                "type": "object",
                "properties": params,
                "required": [param_name for param_name, param in sig.parameters.items()
                            if param.default == inspect.Parameter.empty
                            and param_name != "self" and param_name != "cls"]
            }

        # Définir le schéma de l'outil
        func.tool_schema = {
            "name": func.tool_name,
            "description": func.tool_description,
            "parameters": func.tool_parameters
        }

        return func

    return decorator
