#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Implémentation minimale d'un serveur MCP basé sur FastAPI.

Ce module fournit une implémentation minimale d'un serveur MCP
pour tester les outils de mémoire.
"""

import json
import logging
import inspect
from typing import Dict, Any, Callable, List, Optional, Union

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.server.fastmcp")

class FastMCP:
    """
    Implémentation minimale d'un serveur MCP basé sur FastAPI.
    
    Cette classe fournit une implémentation minimale pour tester les outils MCP.
    Dans une implémentation réelle, elle utiliserait FastAPI pour exposer les outils
    via une API REST ou WebSocket.
    """
    
    def __init__(self, name: str):
        """
        Initialise le serveur MCP.
        
        Args:
            name (str): Nom du serveur MCP
        """
        self.name = name
        self.tools = {}
        self.schemas = {}
        logger.info(f"Serveur MCP '{name}' initialisé")
    
    def tool(self, schema: Dict[str, Any] = None):
        """
        Décorateur pour enregistrer un outil MCP.
        
        Args:
            schema (Dict[str, Any], optional): Schéma JSON de l'outil
        
        Returns:
            Callable: Décorateur pour enregistrer l'outil
        """
        def decorator(func: Callable):
            # Récupérer le nom de la fonction
            tool_name = func.__name__
            
            # Générer un schéma par défaut si aucun n'est fourni
            if schema is None:
                # Récupérer la signature de la fonction
                sig = inspect.signature(func)
                params = {}
                
                # Générer un schéma pour chaque paramètre
                for name, param in sig.parameters.items():
                    # Ignorer self et cls
                    if name in ["self", "cls"]:
                        continue
                    
                    # Déterminer le type du paramètre
                    param_type = "string"
                    if param.annotation != inspect.Parameter.empty:
                        if param.annotation == int:
                            param_type = "integer"
                        elif param.annotation == float:
                            param_type = "number"
                        elif param.annotation == bool:
                            param_type = "boolean"
                        elif param.annotation == list or param.annotation == List:
                            param_type = "array"
                        elif param.annotation == dict or param.annotation == Dict:
                            param_type = "object"
                    
                    # Ajouter le paramètre au schéma
                    params[name] = {
                        "type": param_type,
                        "description": f"Paramètre {name}"
                    }
                
                # Créer le schéma
                generated_schema = {
                    "name": tool_name,
                    "description": func.__doc__ or f"Outil {tool_name}",
                    "parameters": {
                        "type": "object",
                        "properties": params,
                        "required": list(params.keys())
                    }
                }
                
                # Utiliser le schéma généré
                self.schemas[tool_name] = generated_schema
            else:
                # Utiliser le schéma fourni
                self.schemas[tool_name] = schema
            
            # Enregistrer l'outil
            self.tools[tool_name] = func
            
            logger.info(f"Outil '{tool_name}' enregistré")
            
            return func
        
        return decorator
    
    def run(self, host: str = "127.0.0.1", port: int = 8000):
        """
        Démarre le serveur MCP.
        
        Dans une implémentation réelle, cette méthode démarrerait un serveur FastAPI.
        Pour cette implémentation minimale, elle affiche simplement les outils disponibles
        et entre dans une boucle interactive pour tester les outils.
        
        Args:
            host (str, optional): Hôte sur lequel écouter. Par défaut "127.0.0.1".
            port (int, optional): Port sur lequel écouter. Par défaut 8000.
        """
        logger.info(f"Démarrage du serveur MCP '{self.name}' sur {host}:{port}")
        
        # Afficher les outils disponibles
        logger.info(f"Outils disponibles ({len(self.tools)}):")
        for tool_name in self.tools:
            logger.info(f"  - {tool_name}: {self.schemas[tool_name]['description']}")
        
        # Entrer dans une boucle interactive pour tester les outils
        print(f"\nServeur MCP '{self.name}' démarré sur {host}:{port}")
        print("Entrez 'exit' pour quitter")
        print("Entrez 'tools' pour afficher les outils disponibles")
        print("Entrez '<outil> <params_json>' pour appeler un outil")
        
        while True:
            try:
                # Lire l'entrée utilisateur
                cmd = input("> ")
                
                # Quitter si demandé
                if cmd.lower() == "exit":
                    break
                
                # Afficher les outils si demandé
                if cmd.lower() == "tools":
                    print("\nOutils disponibles:")
                    for tool_name in self.tools:
                        print(f"  - {tool_name}: {self.schemas[tool_name]['description']}")
                    continue
                
                # Sinon, essayer d'appeler un outil
                parts = cmd.split(" ", 1)
                if len(parts) == 0:
                    continue
                
                tool_name = parts[0]
                
                # Vérifier si l'outil existe
                if tool_name not in self.tools:
                    print(f"Erreur: Outil '{tool_name}' non trouvé")
                    continue
                
                # Récupérer les paramètres
                params = {}
                if len(parts) > 1:
                    try:
                        params = json.loads(parts[1])
                    except json.JSONDecodeError:
                        print("Erreur: Paramètres JSON invalides")
                        continue
                
                # Appeler l'outil
                try:
                    result = self.tools[tool_name](params)
                    print("\nRésultat:")
                    print(json.dumps(result, indent=2, ensure_ascii=False))
                except Exception as e:
                    print(f"Erreur lors de l'appel de l'outil: {e}")
            
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"Erreur: {e}")
        
        logger.info(f"Arrêt du serveur MCP '{self.name}'")
        print(f"\nServeur MCP '{self.name}' arrêté")
