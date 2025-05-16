#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant des outils pour la génération de documentation.

Ce module fournit des outils pour générer de la documentation à partir du code source,
extraire des informations de documentation, etc.
"""

import os
import sys
import re
import ast
import inspect
import importlib.util
from typing import Dict, Any, Optional, List, Union, Callable
from pathlib import Path
import docstring_parser

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer le gestionnaire de cache
from ..utils.cache_manager import cached

class DocumentationTools:
    """Classe contenant des outils pour la génération de documentation."""

    @staticmethod
    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def extract_docstrings(code: str) -> Dict[str, Any]:
        """
        Extrait les docstrings d'un code Python.

        Args:
            code: Code Python à analyser

        Returns:
            Dictionnaire contenant les docstrings extraites
        """
        try:
            # Analyser le code avec ast
            tree = ast.parse(code)

            # Extraire les docstrings
            docstrings = {
                "module": ast.get_docstring(tree),
                "classes": {},
                "functions": {}
            }

            # Extraire les docstrings des classes et fonctions
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    class_docstring = ast.get_docstring(node)
                    methods = {}

                    for subnode in node.body:
                        if isinstance(subnode, ast.FunctionDef):
                            method_docstring = ast.get_docstring(subnode)
                            if method_docstring:
                                methods[subnode.name] = method_docstring

                    docstrings["classes"][node.name] = {
                        "docstring": class_docstring,
                        "methods": methods
                    }

                elif isinstance(node, ast.FunctionDef):
                    # Vérifier si la fonction est une méthode de classe
                    is_method = False
                    for class_node in ast.walk(tree):
                        if isinstance(class_node, ast.ClassDef):
                            for method in class_node.body:
                                if isinstance(method, ast.FunctionDef) and method.name == node.name:
                                    is_method = True
                                    break

                    if not is_method:
                        function_docstring = ast.get_docstring(node)
                        if function_docstring:
                            docstrings["functions"][node.name] = function_docstring

            return docstrings
        except Exception as e:
            return {"error": str(e)}

    @staticmethod
    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def generate_function_documentation(code: str, function_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Génère de la documentation pour une fonction spécifique ou toutes les fonctions du code.

        Args:
            code: Code Python contenant la fonction
            function_name: Nom de la fonction à documenter (optionnel, toutes les fonctions si non spécifié)

        Returns:
            Dictionnaire contenant la documentation générée
        """
        try:
            # Analyser le code avec ast
            tree = ast.parse(code)

            # Trouver les fonctions
            functions = {}
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    if function_name is None or node.name == function_name:
                        # Extraire les paramètres
                        params = []
                        for arg in node.args.args:
                            param_name = arg.arg
                            param_type = None

                            # Extraire le type d'annotation s'il existe
                            if arg.annotation:
                                param_type = ast.unparse(arg.annotation)

                            params.append({
                                "name": param_name,
                                "type": param_type
                            })

                        # Extraire le type de retour
                        return_type = None
                        if node.returns:
                            return_type = ast.unparse(node.returns)

                        # Extraire le docstring
                        docstring = ast.get_docstring(node)

                        # Analyser le docstring s'il existe
                        parsed_docstring = None
                        if docstring:
                            try:
                                parsed_docstring = docstring_parser.parse(docstring)

                                # Extraire les paramètres du docstring
                                docstring_params = {}
                                for param in parsed_docstring.params:
                                    docstring_params[param.arg_name] = {
                                        "description": param.description,
                                        "type": param.type_name
                                    }

                                # Extraire le type de retour du docstring
                                docstring_return = None
                                if parsed_docstring.returns:
                                    docstring_return = {
                                        "description": parsed_docstring.returns.description,
                                        "type": parsed_docstring.returns.type_name
                                    }

                                parsed_docstring = {
                                    "short_description": parsed_docstring.short_description,
                                    "long_description": parsed_docstring.long_description,
                                    "params": docstring_params,
                                    "returns": docstring_return
                                }
                            except Exception:
                                parsed_docstring = None

                        # Générer la documentation
                        functions[node.name] = {
                            "params": params,
                            "return_type": return_type,
                            "docstring": docstring,
                            "parsed_docstring": parsed_docstring,
                            "line": node.lineno
                        }

                        # Si on cherche une fonction spécifique et qu'on l'a trouvée, on s'arrête
                        if function_name is not None and node.name == function_name:
                            break

            # Si on cherche une fonction spécifique et qu'on ne l'a pas trouvée
            if function_name is not None and function_name not in functions:
                return {"error": f"Fonction '{function_name}' non trouvée dans le code"}

            return {"functions": functions}
        except Exception as e:
            return {"error": str(e)}

    @staticmethod
    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def generate_class_documentation(code: str, class_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Génère de la documentation pour une classe spécifique ou toutes les classes du code.

        Args:
            code: Code Python contenant la classe
            class_name: Nom de la classe à documenter (optionnel, toutes les classes si non spécifié)

        Returns:
            Dictionnaire contenant la documentation générée
        """
        try:
            # Analyser le code avec ast
            tree = ast.parse(code)

            # Trouver les classes
            classes = {}
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    if class_name is None or node.name == class_name:
                        # Extraire les bases
                        bases = []
                        for base in node.bases:
                            if isinstance(base, ast.Name):
                                bases.append(base.id)
                            else:
                                bases.append(ast.unparse(base))

                        # Extraire le docstring
                        docstring = ast.get_docstring(node)

                        # Analyser le docstring s'il existe
                        parsed_docstring = None
                        if docstring:
                            try:
                                parsed_docstring = docstring_parser.parse(docstring)
                                parsed_docstring = {
                                    "short_description": parsed_docstring.short_description,
                                    "long_description": parsed_docstring.long_description
                                }
                            except Exception:
                                parsed_docstring = None

                        # Extraire les méthodes
                        methods = {}
                        for subnode in node.body:
                            if isinstance(subnode, ast.FunctionDef):
                                # Extraire les paramètres
                                params = []
                                for arg in subnode.args.args:
                                    if arg.arg != "self":  # Ignorer le paramètre self
                                        param_name = arg.arg
                                        param_type = None

                                        # Extraire le type d'annotation s'il existe
                                        if arg.annotation:
                                            param_type = ast.unparse(arg.annotation)

                                        params.append({
                                            "name": param_name,
                                            "type": param_type
                                        })

                                # Extraire le type de retour
                                return_type = None
                                if subnode.returns:
                                    return_type = ast.unparse(subnode.returns)

                                # Extraire le docstring
                                method_docstring = ast.get_docstring(subnode)

                                methods[subnode.name] = {
                                    "params": params,
                                    "return_type": return_type,
                                    "docstring": method_docstring,
                                    "line": subnode.lineno
                                }

                        # Générer la documentation
                        classes[node.name] = {
                            "bases": bases,
                            "docstring": docstring,
                            "parsed_docstring": parsed_docstring,
                            "methods": methods,
                            "line": node.lineno
                        }

                        # Si on cherche une classe spécifique et qu'on l'a trouvée, on s'arrête
                        if class_name is not None and node.name == class_name:
                            break

            # Si on cherche une classe spécifique et qu'on ne l'a pas trouvée
            if class_name is not None and class_name not in classes:
                return {"error": f"Classe '{class_name}' non trouvée dans le code"}

            return {"classes": classes}
        except Exception as e:
            return {"error": str(e)}

    @staticmethod
    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def generate_markdown_documentation(code: str) -> str:
        """
        Génère de la documentation au format Markdown pour un code Python.

        Args:
            code: Code Python à documenter

        Returns:
            Documentation au format Markdown
        """
        try:
            # Extraire les docstrings
            docstrings = DocumentationTools.extract_docstrings(code)

            # Générer la documentation des fonctions
            functions_doc = DocumentationTools.generate_function_documentation(code)

            # Générer la documentation des classes
            classes_doc = DocumentationTools.generate_class_documentation(code)

            # Construire la documentation Markdown
            markdown = []

            # Titre du module
            module_name = "Module"
            if "module" in docstrings and docstrings["module"]:
                # Extraire le nom du module à partir du docstring
                module_match = re.search(r"Module\s+(\w+)", docstrings["module"])
                if module_match:
                    module_name = module_match.group(1)

            markdown.append(f"# {module_name}")
            markdown.append("")

            # Description du module
            if "module" in docstrings and docstrings["module"]:
                markdown.append(docstrings["module"])
                markdown.append("")

            # Documentation des fonctions
            if "functions" in functions_doc and functions_doc["functions"]:
                markdown.append("## Fonctions")
                markdown.append("")

                for func_name, func_info in functions_doc["functions"].items():
                    markdown.append(f"### `{func_name}`")
                    markdown.append("")

                    # Signature de la fonction
                    params_str = ", ".join([f"{param['name']}: {param['type'] or 'Any'}" for param in func_info["params"]])
                    return_type = func_info["return_type"] or "Any"
                    markdown.append(f"```python")
                    markdown.append(f"def {func_name}({params_str}) -> {return_type}:")
                    markdown.append(f"```")
                    markdown.append("")

                    # Description de la fonction
                    if "parsed_docstring" in func_info and func_info["parsed_docstring"]:
                        parsed = func_info["parsed_docstring"]
                        if "short_description" in parsed and parsed["short_description"]:
                            markdown.append(parsed["short_description"])
                            markdown.append("")

                        if "long_description" in parsed and parsed["long_description"]:
                            markdown.append(parsed["long_description"])
                            markdown.append("")
                    elif "docstring" in func_info and func_info["docstring"]:
                        markdown.append(func_info["docstring"])
                        markdown.append("")

                    # Paramètres
                    if func_info["params"]:
                        markdown.append("#### Paramètres")
                        markdown.append("")

                        for param in func_info["params"]:
                            param_name = param["name"]
                            param_type = param["type"] or "Any"
                            param_desc = ""

                            if "parsed_docstring" in func_info and func_info["parsed_docstring"] and "params" in func_info["parsed_docstring"]:
                                if param_name in func_info["parsed_docstring"]["params"]:
                                    param_desc = func_info["parsed_docstring"]["params"][param_name]["description"] or ""

                            markdown.append(f"- `{param_name}` (`{param_type}`): {param_desc}")

                        markdown.append("")

                    # Valeur de retour
                    return_desc = ""
                    if "parsed_docstring" in func_info and func_info["parsed_docstring"] and "returns" in func_info["parsed_docstring"] and func_info["parsed_docstring"]["returns"]:
                        return_desc = func_info["parsed_docstring"]["returns"]["description"] or ""

                    markdown.append("#### Retourne")
                    markdown.append("")
                    markdown.append(f"`{return_type}`: {return_desc}")
                    markdown.append("")

            # Documentation des classes
            if "classes" in classes_doc and classes_doc["classes"]:
                markdown.append("## Classes")
                markdown.append("")

                for class_name, class_info in classes_doc["classes"].items():
                    markdown.append(f"### `{class_name}`")
                    markdown.append("")

                    # Héritage
                    if class_info["bases"]:
                        bases_str = ", ".join(class_info["bases"])
                        markdown.append(f"Hérite de: `{bases_str}`")
                        markdown.append("")

                    # Description de la classe
                    if "parsed_docstring" in class_info and class_info["parsed_docstring"]:
                        parsed = class_info["parsed_docstring"]
                        if "short_description" in parsed and parsed["short_description"]:
                            markdown.append(parsed["short_description"])
                            markdown.append("")

                        if "long_description" in parsed and parsed["long_description"]:
                            markdown.append(parsed["long_description"])
                            markdown.append("")
                    elif "docstring" in class_info and class_info["docstring"]:
                        markdown.append(class_info["docstring"])
                        markdown.append("")

                    # Méthodes
                    if "methods" in class_info and class_info["methods"]:
                        markdown.append("#### Méthodes")
                        markdown.append("")

                        for method_name, method_info in class_info["methods"].items():
                            markdown.append(f"##### `{method_name}`")
                            markdown.append("")

                            # Signature de la méthode
                            params_str = ", ".join(["self"] + [f"{param['name']}: {param['type'] or 'Any'}" for param in method_info["params"]])
                            return_type = method_info["return_type"] or "Any"
                            markdown.append(f"```python")
                            markdown.append(f"def {method_name}({params_str}) -> {return_type}:")
                            markdown.append(f"```")
                            markdown.append("")

                            # Description de la méthode
                            if "docstring" in method_info and method_info["docstring"]:
                                markdown.append(method_info["docstring"])
                                markdown.append("")

            return "\n".join(markdown)
        except Exception as e:
            return f"Erreur lors de la génération de la documentation: {str(e)}"
