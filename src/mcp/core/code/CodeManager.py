#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de gestion de code pour MCP.

Ce module fournit une classe de base pour gérer les opérations sur le code dans le contexte MCP.
Il permet de rechercher, analyser et obtenir la structure du code.
"""

import os
import re
import ast
import json
import logging
import fnmatch
from pathlib import Path
from typing import Dict, List, Any, Optional, Union, Tuple, Set

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.code")

class CodeManager:
    """
    Gestionnaire de code pour MCP.

    Cette classe fournit les fonctionnalités de base pour gérer le code :
    - Rechercher du code
    - Analyser du code
    - Obtenir la structure du code
    """

    def __init__(self, base_path: Optional[str] = None, cache_path: Optional[str] = None):
        """
        Initialise le gestionnaire de code.

        Args:
            base_path (Optional[str]): Chemin de base pour le code.
                Si non spécifié, utilise le répertoire courant.
            cache_path (Optional[str]): Chemin pour le cache des analyses.
                Si non spécifié, utilise un emplacement par défaut.
        """
        # Définir le chemin de base
        self.base_path = base_path or os.getcwd()

        # Définir le chemin du cache
        if cache_path:
            self.cache_path = cache_path
        else:
            # Chemin par défaut dans le dossier de l'utilisateur
            user_home = os.path.expanduser("~")
            mcp_dir = os.path.join(user_home, ".mcp", "code_cache")
            os.makedirs(mcp_dir, exist_ok=True)
            self.cache_path = mcp_dir

        # Initialiser le cache des analyses
        self.analysis_cache = {}

        # Définir les extensions de fichiers par langage
        self.language_extensions = {
            "python": [".py", ".pyw", ".pyx", ".pxd", ".pxi"],
            "javascript": [".js", ".jsx", ".mjs"],
            "typescript": [".ts", ".tsx"],
            "java": [".java"],
            "csharp": [".cs"],
            "cpp": [".cpp", ".cc", ".cxx", ".h", ".hpp", ".hxx"],
            "php": [".php"],
            "ruby": [".rb"],
            "go": [".go"],
            "rust": [".rs"],
            "powershell": [".ps1", ".psm1", ".psd1"],
            "shell": [".sh", ".bash", ".zsh"],
            "batch": [".bat", ".cmd"],
            "html": [".html", ".htm"],
            "css": [".css", ".scss", ".sass", ".less"],
            "json": [".json"],
            "yaml": [".yml", ".yaml"],
            "markdown": [".md", ".markdown"],
            "xml": [".xml"],
            "sql": [".sql"]
        }

        # Définir les commentaires par langage
        self.language_comments = {
            "python": ["#", '"""', "'''"],
            "javascript": ["//", "/*", "*/"],
            "typescript": ["//", "/*", "*/"],
            "java": ["//", "/*", "*/"],
            "csharp": ["//", "/*", "*/"],
            "cpp": ["//", "/*", "*/"],
            "php": ["//", "#", "/*", "*/"],
            "ruby": ["#", "=begin", "=end"],
            "go": ["//", "/*", "*/"],
            "rust": ["//", "/*", "*/"],
            "powershell": ["#", "<#", "#>"],
            "shell": ["#"],
            "batch": ["REM", "::"],
            "html": ["<!--", "-->"],
            "css": ["/*", "*/"],
            "json": [],
            "yaml": ["#"],
            "markdown": [],
            "xml": ["<!--", "-->"],
            "sql": ["--", "/*", "*/"]
        }

        logger.info(f"Gestionnaire de code initialisé avec base: {self.base_path}, cache: {self.cache_path}")

    def _get_absolute_path(self, path: str) -> str:
        """
        Convertit un chemin relatif en chemin absolu.

        Args:
            path (str): Chemin relatif ou absolu

        Returns:
            str: Chemin absolu
        """
        if os.path.isabs(path):
            return path
        return os.path.abspath(os.path.join(self.base_path, path))

    def _detect_language(self, file_path: str) -> Optional[str]:
        """
        Détecte le langage d'un fichier en fonction de son extension.

        Args:
            file_path (str): Chemin du fichier

        Returns:
            Optional[str]: Langage détecté ou None si non reconnu
        """
        _, ext = os.path.splitext(file_path.lower())

        for language, extensions in self.language_extensions.items():
            if ext in extensions:
                return language

        return None

    def _read_file(self, file_path: str) -> Optional[str]:
        """
        Lit le contenu d'un fichier.

        Args:
            file_path (str): Chemin du fichier

        Returns:
            Optional[str]: Contenu du fichier ou None en cas d'erreur
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        except UnicodeDecodeError:
            try:
                # Essayer avec une autre encodage
                with open(file_path, 'r', encoding='latin-1') as f:
                    return f.read()
            except Exception as e:
                logger.error(f"Erreur lors de la lecture du fichier {file_path}: {e}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de la lecture du fichier {file_path}: {e}")
            return None

    def search_code(self, query: str, paths: Optional[List[str]] = None,
                   languages: Optional[List[str]] = None, recursive: bool = True,
                   case_sensitive: bool = False, whole_word: bool = False,
                   regex: bool = False, max_results: int = 100) -> List[Dict[str, Any]]:
        """
        Recherche du code correspondant à une requête.

        Args:
            query (str): Requête de recherche
            paths (Optional[List[str]]): Liste des chemins à rechercher
            languages (Optional[List[str]]): Liste des langages à inclure
            recursive (bool): Recherche récursive dans les sous-dossiers
            case_sensitive (bool): Recherche sensible à la casse
            whole_word (bool): Recherche de mots entiers
            regex (bool): Interprète la requête comme une expression régulière
            max_results (int): Nombre maximum de résultats

        Returns:
            List[Dict[str, Any]]: Liste des résultats de recherche
        """
        # Utiliser le chemin de base si aucun chemin n'est spécifié
        if not paths:
            paths = [self.base_path]

        # Convertir les chemins en chemins absolus
        abs_paths = [self._get_absolute_path(path) for path in paths]

        # Préparer la requête
        if not regex:
            # Échapper les caractères spéciaux
            query = re.escape(query)

            # Ajouter les limites de mots si nécessaire
            if whole_word:
                query = r'\b' + query + r'\b'

        # Compiler l'expression régulière
        flags = 0 if case_sensitive else re.IGNORECASE
        pattern = re.compile(query, flags)

        # Initialiser les résultats
        results = []

        # Parcourir les chemins
        for path in abs_paths:
            # Vérifier si le chemin existe
            if not os.path.exists(path):
                logger.warning(f"Le chemin {path} n'existe pas")
                continue

            # Si le chemin est un fichier
            if os.path.isfile(path):
                # Vérifier le langage si spécifié
                language = self._detect_language(path)
                if languages and language not in languages:
                    continue

                # Rechercher dans le fichier
                file_results = self._search_in_file(path, pattern)
                results.extend(file_results)

            # Si le chemin est un dossier
            elif os.path.isdir(path):
                # Parcourir le dossier
                for root, dirs, files in os.walk(path):
                    # Ignorer les sous-dossiers si non récursif
                    if not recursive and root != path:
                        continue

                    # Parcourir les fichiers
                    for file in files:
                        file_path = os.path.join(root, file)

                        # Vérifier le langage si spécifié
                        language = self._detect_language(file_path)
                        if languages and language not in languages:
                            continue

                        # Rechercher dans le fichier
                        file_results = self._search_in_file(file_path, pattern)
                        results.extend(file_results)

                        # Limiter le nombre de résultats
                        if len(results) >= max_results:
                            break

                    # Limiter le nombre de résultats
                    if len(results) >= max_results:
                        break

        # Trier les résultats par pertinence (nombre d'occurrences)
        results.sort(key=lambda x: x["occurrences"], reverse=True)

        # Limiter le nombre de résultats
        results = results[:max_results]

        logger.info(f"Recherche pour '{query}': {len(results)} résultats")
        return results

    def _search_in_file(self, file_path: str, pattern: re.Pattern) -> List[Dict[str, Any]]:
        """
        Recherche dans un fichier.

        Args:
            file_path (str): Chemin du fichier
            pattern (re.Pattern): Pattern de recherche

        Returns:
            List[Dict[str, Any]]: Liste des résultats de recherche
        """
        # Lire le contenu du fichier
        content = self._read_file(file_path)
        if content is None:
            return []

        # Rechercher toutes les occurrences
        matches = list(pattern.finditer(content))
        if not matches:
            return []

        # Calculer les numéros de ligne
        lines = content.splitlines()
        line_offsets = [0]
        for line in lines:
            line_offsets.append(line_offsets[-1] + len(line) + 1)  # +1 pour le saut de ligne

        # Préparer les résultats
        results = []

        # Regrouper les occurrences par fichier
        occurrences = []

        for match in matches:
            # Trouver le numéro de ligne
            start_offset = match.start()
            line_number = 0
            for i, offset in enumerate(line_offsets):
                if offset > start_offset:
                    line_number = i
                    break

            # Extraire la ligne
            line = lines[line_number - 1] if line_number > 0 else ""

            # Ajouter l'occurrence
            occurrences.append({
                "line_number": line_number,
                "line": line,
                "start": match.start(),
                "end": match.end(),
                "match": match.group()
            })

        # Ajouter le résultat
        if occurrences:
            results.append({
                "file_path": file_path,
                "language": self._detect_language(file_path),
                "occurrences": len(occurrences),
                "matches": occurrences[:10]  # Limiter le nombre d'occurrences par fichier
            })

        return results

    def analyze_code(self, file_path: str, rules: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Analyse un fichier de code.

        Args:
            file_path (str): Chemin du fichier à analyser
            rules (Optional[List[str]]): Liste des règles d'analyse à appliquer

        Returns:
            Dict[str, Any]: Résultat de l'analyse
        """
        # Convertir le chemin en chemin absolu
        abs_path = self._get_absolute_path(file_path)

        # Vérifier si le fichier existe
        if not os.path.exists(abs_path):
            logger.warning(f"Le fichier {abs_path} n'existe pas")
            return {
                "success": False,
                "error": f"Le fichier {abs_path} n'existe pas",
                "file_path": abs_path
            }

        # Vérifier si c'est un fichier
        if not os.path.isfile(abs_path):
            logger.warning(f"Le chemin {abs_path} n'est pas un fichier")
            return {
                "success": False,
                "error": f"Le chemin {abs_path} n'est pas un fichier",
                "file_path": abs_path
            }

        # Détecter le langage
        language = self._detect_language(abs_path)
        if not language:
            logger.warning(f"Langage non reconnu pour le fichier {abs_path}")
            return {
                "success": False,
                "error": f"Langage non reconnu pour le fichier {abs_path}",
                "file_path": abs_path
            }

        # Lire le contenu du fichier
        content = self._read_file(abs_path)
        if content is None:
            return {
                "success": False,
                "error": f"Impossible de lire le fichier {abs_path}",
                "file_path": abs_path
            }

        # Initialiser le résultat
        result = {
            "success": True,
            "file_path": abs_path,
            "language": language,
            "size": os.path.getsize(abs_path),
            "line_count": len(content.splitlines()),
            "char_count": len(content),
            "metrics": {},
            "issues": []
        }

        # Analyser le code selon le langage
        if language == "python":
            self._analyze_python_code(abs_path, content, result, rules)
        elif language in ["javascript", "typescript"]:
            self._analyze_js_ts_code(abs_path, content, result, rules)
        elif language == "powershell":
            self._analyze_powershell_code(abs_path, content, result, rules)
        else:
            # Analyse générique pour les autres langages
            self._analyze_generic_code(abs_path, content, result, rules)

        return result

    def _analyze_python_code(self, file_path: str, content: str, result: Dict[str, Any], rules: Optional[List[str]]) -> None:
        """
        Analyse du code Python.

        Args:
            file_path (str): Chemin du fichier
            content (str): Contenu du fichier
            result (Dict[str, Any]): Dictionnaire de résultat à mettre à jour
            rules (Optional[List[str]]): Liste des règles d'analyse à appliquer
        """
        try:
            # Parser le code Python
            tree = ast.parse(content)

            # Compter les classes, fonctions et imports
            class_count = 0
            function_count = 0
            method_count = 0
            import_count = 0

            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    class_count += 1
                elif isinstance(node, ast.FunctionDef):
                    # Vérifier si c'est une méthode de classe
                    if isinstance(node.parent, ast.ClassDef) if hasattr(node, 'parent') else False:
                        method_count += 1
                    else:
                        function_count += 1
                elif isinstance(node, ast.Import) or isinstance(node, ast.ImportFrom):
                    import_count += 1

            # Ajouter les métriques
            result["metrics"] = {
                "class_count": class_count,
                "function_count": function_count,
                "method_count": method_count,
                "import_count": import_count
            }

            # Rechercher les problèmes courants
            issues = []

            # Vérifier les lignes trop longues
            if "line_length" in rules if rules else True:
                for i, line in enumerate(content.splitlines()):
                    if len(line) > 100:  # PEP 8 recommande 79 caractères max
                        issues.append({
                            "rule": "line_length",
                            "severity": "warning",
                            "message": f"Ligne trop longue ({len(line)} caractères)",
                            "line": i + 1,
                            "column": 1
                        })

            # Vérifier les TODOs
            if "todo_comments" in rules if rules else True:
                todo_pattern = re.compile(r"#\s*(TODO|FIXME|XXX|BUG|HACK):", re.IGNORECASE)
                for i, line in enumerate(content.splitlines()):
                    match = todo_pattern.search(line)
                    if match:
                        issues.append({
                            "rule": "todo_comments",
                            "severity": "info",
                            "message": f"Commentaire TODO trouvé: {line.strip()}",
                            "line": i + 1,
                            "column": match.start() + 1
                        })

            # Ajouter les problèmes
            result["issues"] = issues

        except SyntaxError as e:
            # Erreur de syntaxe dans le code Python
            result["issues"].append({
                "rule": "syntax_error",
                "severity": "error",
                "message": f"Erreur de syntaxe: {str(e)}",
                "line": e.lineno if hasattr(e, 'lineno') else 1,
                "column": e.offset if hasattr(e, 'offset') else 1
            })
        except Exception as e:
            logger.error(f"Erreur lors de l'analyse du code Python {file_path}: {e}")

    def _analyze_js_ts_code(self, file_path: str, content: str, result: Dict[str, Any], rules: Optional[List[str]]) -> None:
        """
        Analyse du code JavaScript/TypeScript.

        Args:
            file_path (str): Chemin du fichier
            content (str): Contenu du fichier
            result (Dict[str, Any]): Dictionnaire de résultat à mettre à jour
            rules (Optional[List[str]]): Liste des règles d'analyse à appliquer
        """
        # Analyse basique pour JavaScript/TypeScript
        # Compter les fonctions, classes et imports
        function_pattern = re.compile(r"(function\s+\w+|const\s+\w+\s*=\s*function|const\s+\w+\s*=\s*\(.*?\)\s*=>|class\s+\w+|import\s+.*?from)", re.MULTILINE)

        function_count = len(re.findall(r"function\s+\w+|\w+\s*=\s*function|\w+\s*=\s*\(.*?\)\s*=>", content))
        class_count = len(re.findall(r"class\s+\w+", content))
        import_count = len(re.findall(r"import\s+.*?from", content))

        # Ajouter les métriques
        result["metrics"] = {
            "function_count": function_count,
            "class_count": class_count,
            "import_count": import_count
        }

        # Rechercher les problèmes courants
        issues = []

        # Vérifier les lignes trop longues
        if "line_length" in rules if rules else True:
            for i, line in enumerate(content.splitlines()):
                if len(line) > 100:
                    issues.append({
                        "rule": "line_length",
                        "severity": "warning",
                        "message": f"Ligne trop longue ({len(line)} caractères)",
                        "line": i + 1,
                        "column": 1
                    })

        # Vérifier les TODOs
        if "todo_comments" in rules if rules else True:
            todo_pattern = re.compile(r"//\s*(TODO|FIXME|XXX|BUG|HACK):", re.IGNORECASE)
            for i, line in enumerate(content.splitlines()):
                match = todo_pattern.search(line)
                if match:
                    issues.append({
                        "rule": "todo_comments",
                        "severity": "info",
                        "message": f"Commentaire TODO trouvé: {line.strip()}",
                        "line": i + 1,
                        "column": match.start() + 1
                    })

        # Ajouter les problèmes
        result["issues"] = issues

    def _analyze_powershell_code(self, file_path: str, content: str, result: Dict[str, Any], rules: Optional[List[str]]) -> None:
        """
        Analyse du code PowerShell.

        Args:
            file_path (str): Chemin du fichier
            content (str): Contenu du fichier
            result (Dict[str, Any]): Dictionnaire de résultat à mettre à jour
            rules (Optional[List[str]]): Liste des règles d'analyse à appliquer
        """
        # Analyse basique pour PowerShell
        # Compter les fonctions et les alias
        function_count = len(re.findall(r"function\s+\w+-\w+", content))
        alias_count = len(re.findall(r"Set-Alias", content))

        # Ajouter les métriques
        result["metrics"] = {
            "function_count": function_count,
            "alias_count": alias_count
        }

        # Rechercher les problèmes courants
        issues = []

        # Vérifier les lignes trop longues
        if "line_length" in rules if rules else True:
            for i, line in enumerate(content.splitlines()):
                if len(line) > 100:
                    issues.append({
                        "rule": "line_length",
                        "severity": "warning",
                        "message": f"Ligne trop longue ({len(line)} caractères)",
                        "line": i + 1,
                        "column": 1
                    })

        # Vérifier les TODOs
        if "todo_comments" in rules if rules else True:
            todo_pattern = re.compile(r"#\s*(TODO|FIXME|XXX|BUG|HACK):", re.IGNORECASE)
            for i, line in enumerate(content.splitlines()):
                match = todo_pattern.search(line)
                if match:
                    issues.append({
                        "rule": "todo_comments",
                        "severity": "info",
                        "message": f"Commentaire TODO trouvé: {line.strip()}",
                        "line": i + 1,
                        "column": match.start() + 1
                    })

        # Ajouter les problèmes
        result["issues"] = issues

    def _analyze_generic_code(self, file_path: str, content: str, result: Dict[str, Any], rules: Optional[List[str]]) -> None:
        """
        Analyse générique du code.

        Args:
            file_path (str): Chemin du fichier
            content (str): Contenu du fichier
            result (Dict[str, Any]): Dictionnaire de résultat à mettre à jour
            rules (Optional[List[str]]): Liste des règles d'analyse à appliquer
        """
        # Analyse basique pour les autres langages
        # Compter les lignes non vides et les commentaires
        lines = content.splitlines()
        non_empty_lines = [line for line in lines if line.strip()]

        # Ajouter les métriques
        result["metrics"] = {
            "non_empty_line_count": len(non_empty_lines)
        }

        # Rechercher les problèmes courants
        issues = []

        # Vérifier les lignes trop longues
        if "line_length" in rules if rules else True:
            for i, line in enumerate(lines):
                if len(line) > 100:
                    issues.append({
                        "rule": "line_length",
                        "severity": "warning",
                        "message": f"Ligne trop longue ({len(line)} caractères)",
                        "line": i + 1,
                        "column": 1
                    })

        # Ajouter les problèmes
        result["issues"] = issues

    def get_code_structure(self, file_path: str) -> Dict[str, Any]:
        """
        Obtient la structure d'un fichier de code.

        Args:
            file_path (str): Chemin du fichier

        Returns:
            Dict[str, Any]: Structure du code
        """
        # Convertir le chemin en chemin absolu
        abs_path = self._get_absolute_path(file_path)

        # Vérifier si le fichier existe
        if not os.path.exists(abs_path):
            logger.warning(f"Le fichier {abs_path} n'existe pas")
            return {
                "success": False,
                "error": f"Le fichier {abs_path} n'existe pas",
                "file_path": abs_path
            }

        # Vérifier si c'est un fichier
        if not os.path.isfile(abs_path):
            logger.warning(f"Le chemin {abs_path} n'est pas un fichier")
            return {
                "success": False,
                "error": f"Le chemin {abs_path} n'est pas un fichier",
                "file_path": abs_path
            }

        # Détecter le langage
        language = self._detect_language(abs_path)
        if not language:
            logger.warning(f"Langage non reconnu pour le fichier {abs_path}")
            return {
                "success": False,
                "error": f"Langage non reconnu pour le fichier {abs_path}",
                "file_path": abs_path
            }

        # Lire le contenu du fichier
        content = self._read_file(abs_path)
        if content is None:
            return {
                "success": False,
                "error": f"Impossible de lire le fichier {abs_path}",
                "file_path": abs_path
            }

        # Initialiser le résultat
        result = {
            "success": True,
            "file_path": abs_path,
            "language": language,
            "size": os.path.getsize(abs_path),
            "line_count": len(content.splitlines()),
            "char_count": len(content),
            "structure": {}
        }

        # Extraire la structure selon le langage
        if language == "python":
            self._extract_python_structure(content, result)
        elif language in ["javascript", "typescript"]:
            self._extract_js_ts_structure(content, result)
        elif language == "powershell":
            self._extract_powershell_structure(content, result)
        else:
            # Extraction générique pour les autres langages
            self._extract_generic_structure(content, result)

        return result

    def _extract_python_structure(self, content: str, result: Dict[str, Any]) -> None:
        """
        Extrait la structure d'un fichier Python.

        Args:
            content (str): Contenu du fichier
            result (Dict[str, Any]): Dictionnaire de résultat à mettre à jour
        """
        try:
            # Parser le code Python
            tree = ast.parse(content)

            # Extraire les imports
            imports = []
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for name in node.names:
                        imports.append({
                            "type": "import",
                            "name": name.name,
                            "alias": name.asname,
                            "line": node.lineno
                        })
                elif isinstance(node, ast.ImportFrom):
                    module = node.module or ""
                    for name in node.names:
                        imports.append({
                            "type": "import_from",
                            "module": module,
                            "name": name.name,
                            "alias": name.asname,
                            "line": node.lineno
                        })

            # Extraire les classes et fonctions de premier niveau
            classes = []
            functions = []

            for node in ast.iter_child_nodes(tree):
                if isinstance(node, ast.ClassDef):
                    # Extraire les méthodes de la classe
                    methods = []
                    for child in ast.iter_child_nodes(node):
                        if isinstance(child, ast.FunctionDef):
                            methods.append({
                                "type": "method",
                                "name": child.name,
                                "line": child.lineno,
                                "args": [arg.arg for arg in child.args.args],
                                "decorators": [str(d) for d in child.decorator_list]
                            })

                    classes.append({
                        "type": "class",
                        "name": node.name,
                        "line": node.lineno,
                        "bases": [str(b) for b in node.bases],
                        "methods": methods
                    })
                elif isinstance(node, ast.FunctionDef):
                    functions.append({
                        "type": "function",
                        "name": node.name,
                        "line": node.lineno,
                        "args": [arg.arg for arg in node.args.args],
                        "decorators": [str(d) for d in node.decorator_list]
                    })

            # Ajouter la structure
            result["structure"] = {
                "imports": imports,
                "classes": classes,
                "functions": functions
            }

        except SyntaxError as e:
            # Erreur de syntaxe dans le code Python
            result["structure"] = {
                "error": f"Erreur de syntaxe: {str(e)}",
                "line": e.lineno if hasattr(e, 'lineno') else 1
            }
        except Exception as e:
            logger.error(f"Erreur lors de l'extraction de la structure Python: {e}")
            result["structure"] = {
                "error": f"Erreur lors de l'extraction de la structure: {str(e)}"
            }

    def _extract_js_ts_structure(self, content: str, result: Dict[str, Any]) -> None:
        """
        Extrait la structure d'un fichier JavaScript/TypeScript.

        Args:
            content (str): Contenu du fichier
            result (Dict[str, Any]): Dictionnaire de résultat à mettre à jour
        """
        # Extraction basique pour JavaScript/TypeScript
        # Extraire les imports
        import_pattern = re.compile(r"import\s+(?:{([^}]+)}|([^\s;]+))\s+from\s+['\"]([^'\"]+)['\"]", re.MULTILINE)
        imports = []

        for match in import_pattern.finditer(content):
            line_number = content[:match.start()].count('\n') + 1
            if match.group(1):  # Import avec destructuration
                names = [name.strip() for name in match.group(1).split(',')]
                module = match.group(3)
                for name in names:
                    if ' as ' in name:
                        original, alias = name.split(' as ')
                        imports.append({
                            "type": "import",
                            "name": original.strip(),
                            "alias": alias.strip(),
                            "module": module,
                            "line": line_number
                        })
                    else:
                        imports.append({
                            "type": "import",
                            "name": name,
                            "module": module,
                            "line": line_number
                        })
            else:  # Import par défaut
                imports.append({
                    "type": "import",
                    "name": match.group(2),
                    "module": match.group(3),
                    "line": line_number
                })

        # Extraire les classes
        class_pattern = re.compile(r"class\s+(\w+)(?:\s+extends\s+(\w+))?\s*{", re.MULTILINE)
        classes = []

        for match in class_pattern.finditer(content):
            line_number = content[:match.start()].count('\n') + 1
            classes.append({
                "type": "class",
                "name": match.group(1),
                "extends": match.group(2),
                "line": line_number
            })

        # Extraire les fonctions
        function_pattern = re.compile(r"(?:function\s+(\w+)|const\s+(\w+)\s*=\s*function|const\s+(\w+)\s*=\s*\(([^)]*)\)\s*=>)", re.MULTILINE)
        functions = []

        for match in function_pattern.finditer(content):
            line_number = content[:match.start()].count('\n') + 1
            name = match.group(1) or match.group(2) or match.group(3)
            args = []
            if match.group(4):
                args = [arg.strip() for arg in match.group(4).split(',')]

            functions.append({
                "type": "function",
                "name": name,
                "args": args,
                "line": line_number
            })

        # Ajouter la structure
        result["structure"] = {
            "imports": imports,
            "classes": classes,
            "functions": functions
        }

    def _extract_powershell_structure(self, content: str, result: Dict[str, Any]) -> None:
        """
        Extrait la structure d'un fichier PowerShell.

        Args:
            content (str): Contenu du fichier
            result (Dict[str, Any]): Dictionnaire de résultat à mettre à jour
        """
        # Extraction basique pour PowerShell
        # Extraire les fonctions
        function_pattern = re.compile(r"function\s+(\w+-\w+)(?:\s*{|\s+\()", re.MULTILINE | re.IGNORECASE)
        functions = []

        for match in function_pattern.finditer(content):
            line_number = content[:match.start()].count('\n') + 1
            functions.append({
                "type": "function",
                "name": match.group(1),
                "line": line_number
            })

        # Extraire les alias
        alias_pattern = re.compile(r"Set-Alias\s+(?:-Name\s+)?(\w+)\s+(?:-Value\s+)?(\S+)", re.MULTILINE | re.IGNORECASE)
        aliases = []

        for match in alias_pattern.finditer(content):
            line_number = content[:match.start()].count('\n') + 1
            aliases.append({
                "type": "alias",
                "name": match.group(1),
                "value": match.group(2),
                "line": line_number
            })

        # Ajouter la structure
        result["structure"] = {
            "functions": functions,
            "aliases": aliases
        }

    def _extract_generic_structure(self, content: str, result: Dict[str, Any]) -> None:
        """
        Extrait la structure générique d'un fichier.

        Args:
            content (str): Contenu du fichier
            result (Dict[str, Any]): Dictionnaire de résultat à mettre à jour
        """
        # Extraction basique pour les autres langages
        # Diviser le contenu en sections
        lines = content.splitlines()
        sections = []

        current_section = None
        section_content = []

        for i, line in enumerate(lines):
            # Détecter les lignes qui pourraient être des en-têtes de section
            stripped = line.strip()
            if stripped and (all(c == '=' for c in stripped) or all(c == '-' for c in stripped) or all(c == '#' for c in stripped)):
                # Fin de section précédente
                if current_section and section_content:
                    sections.append({
                        "title": current_section,
                        "content": "\n".join(section_content),
                        "line": i - len(section_content)
                    })

                # Nouvelle section
                if i > 0 and lines[i-1].strip():
                    current_section = lines[i-1].strip()
                    section_content = []
                else:
                    current_section = None
                    section_content = []
            elif stripped.startswith('#') and len(stripped) > 1:
                # En-tête Markdown
                # Fin de section précédente
                if current_section and section_content:
                    sections.append({
                        "title": current_section,
                        "content": "\n".join(section_content),
                        "line": i - len(section_content)
                    })

                # Nouvelle section
                current_section = stripped.lstrip('#').strip()
                section_content = []
            elif current_section is not None:
                section_content.append(line)

        # Ajouter la dernière section
        if current_section and section_content:
            sections.append({
                "title": current_section,
                "content": "\n".join(section_content),
                "line": len(lines) - len(section_content)
            })

        # Ajouter la structure
        result["structure"] = {
            "sections": sections
        }
