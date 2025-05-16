#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant des outils pour l'analyse de code avancée.

Ce module fournit des outils pour analyser le code source, détecter les problèmes,
évaluer la qualité du code, etc.
"""

import os
import sys
import re
import ast
import json
import subprocess
from typing import Dict, Any, Optional, List, Union
from pathlib import Path
import importlib.util

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer le gestionnaire de cache
from ..utils.cache_manager import cached

class CodeAnalysisTools:
    """Classe contenant des outils pour l'analyse de code avancée."""

    @staticmethod
    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def analyze_python_code(code: str) -> Dict[str, Any]:
        """
        Analyse du code Python pour détecter les problèmes et évaluer sa qualité.

        Args:
            code: Code Python à analyser

        Returns:
            Dictionnaire contenant les résultats de l'analyse
        """
        try:
            # Analyser le code avec ast
            tree = ast.parse(code)

            # Collecter des statistiques sur le code
            stats = {
                "num_lines": len(code.splitlines()),
                "functions": [],
                "classes": [],
                "imports": [],
                "variables": [],
                "complexity": 0
            }

            # Analyser les fonctions
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    # Calculer la complexité cyclomatique (approximation)
                    complexity = 1
                    for subnode in ast.walk(node):
                        if isinstance(subnode, (ast.If, ast.For, ast.While, ast.Try, ast.ExceptHandler)):
                            complexity += 1

                    stats["functions"].append({
                        "name": node.name,
                        "line": node.lineno,
                        "args": [arg.arg for arg in node.args.args],
                        "complexity": complexity
                    })
                    stats["complexity"] += complexity

                elif isinstance(node, ast.ClassDef):
                    methods = []
                    for subnode in node.body:
                        if isinstance(subnode, ast.FunctionDef):
                            methods.append(subnode.name)

                    stats["classes"].append({
                        "name": node.name,
                        "line": node.lineno,
                        "methods": methods,
                        "bases": [base.id if isinstance(base, ast.Name) else "complex_base" for base in node.bases]
                    })

                elif isinstance(node, ast.Import):
                    for name in node.names:
                        stats["imports"].append({
                            "name": name.name,
                            "alias": name.asname
                        })

                elif isinstance(node, ast.ImportFrom):
                    for name in node.names:
                        stats["imports"].append({
                            "name": f"{node.module}.{name.name}" if node.module else name.name,
                            "alias": name.asname
                        })

                elif isinstance(node, ast.Assign):
                    for target in node.targets:
                        if isinstance(target, ast.Name):
                            stats["variables"].append({
                                "name": target.id,
                                "line": node.lineno
                            })

            # Détecter les problèmes potentiels
            issues = []

            # Fonctions trop complexes
            for func in stats["functions"]:
                if func["complexity"] > 10:
                    issues.append({
                        "type": "high_complexity",
                        "message": f"La fonction '{func['name']}' a une complexité cyclomatique élevée ({func['complexity']})",
                        "line": func["line"],
                        "severity": "warning"
                    })

            # Lignes trop longues
            for i, line in enumerate(code.splitlines(), 1):
                if len(line) > 100:
                    issues.append({
                        "type": "line_too_long",
                        "message": f"La ligne {i} est trop longue ({len(line)} caractères)",
                        "line": i,
                        "severity": "info"
                    })

            # Variables non utilisées (approximation)
            defined_vars = {var["name"] for var in stats["variables"]}
            used_vars = set()

            for node in ast.walk(tree):
                if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Load):
                    used_vars.add(node.id)

            for var_name in defined_vars:
                if var_name not in used_vars and not var_name.startswith("_"):
                    # Trouver la ligne de définition
                    line = next((var["line"] for var in stats["variables"] if var["name"] == var_name), 0)
                    issues.append({
                        "type": "unused_variable",
                        "message": f"La variable '{var_name}' est définie mais non utilisée",
                        "line": line,
                        "severity": "warning"
                    })

            # Calculer un score de qualité (0-100)
            quality_score = 100

            # Pénalités pour les problèmes
            for issue in issues:
                if issue["severity"] == "warning":
                    quality_score -= 5
                elif issue["severity"] == "error":
                    quality_score -= 10
                else:
                    quality_score -= 1

            # Pénalité pour la complexité
            avg_complexity = stats["complexity"] / len(stats["functions"]) if stats["functions"] else 0
            if avg_complexity > 5:
                quality_score -= int(avg_complexity - 5) * 2

            # Limiter le score entre 0 et 100
            quality_score = max(0, min(100, quality_score))

            return {
                "stats": stats,
                "issues": issues,
                "quality_score": quality_score,
                "recommendations": CodeAnalysisTools._generate_recommendations(stats, issues)
            }
        except SyntaxError as e:
            return {
                "error": "Erreur de syntaxe",
                "message": str(e),
                "line": e.lineno,
                "offset": e.offset
            }
        except Exception as e:
            return {"error": str(e)}

    @staticmethod
    def _generate_recommendations(stats: Dict[str, Any], issues: List[Dict[str, Any]]) -> List[str]:
        """
        Génère des recommandations basées sur les statistiques et les problèmes détectés.

        Args:
            stats: Statistiques sur le code
            issues: Problèmes détectés

        Returns:
            Liste de recommandations
        """
        recommendations = []

        # Recommandations basées sur la complexité
        if stats["complexity"] > 0 and len(stats["functions"]) > 0:
            avg_complexity = stats["complexity"] / len(stats["functions"])
            if avg_complexity > 10:
                recommendations.append("Réduire la complexité cyclomatique des fonctions en les décomposant en fonctions plus petites")
            elif avg_complexity > 5:
                recommendations.append("Envisager de simplifier certaines fonctions pour réduire leur complexité")

        # Recommandations basées sur les problèmes
        issue_types = {issue["type"] for issue in issues}

        if "high_complexity" in issue_types:
            recommendations.append("Refactoriser les fonctions complexes en les décomposant en fonctions plus petites et plus spécialisées")

        if "line_too_long" in issue_types:
            recommendations.append("Raccourcir les lignes trop longues pour améliorer la lisibilité")

        if "unused_variable" in issue_types:
            recommendations.append("Supprimer les variables non utilisées pour améliorer la clarté du code")

        # Recommandations générales
        if len(stats["classes"]) > 0:
            recommendations.append("Vérifier que les classes suivent les principes SOLID")

        if len(stats["functions"]) > 5:
            recommendations.append("Organiser les fonctions en modules logiques pour améliorer la maintenabilité")

        return recommendations

    @staticmethod
    @cached(ttl_memory=3600, ttl_disk=86400)  # 1 heure en mémoire, 24 heures sur disque
    def analyze_code_structure(directory_path: str, file_pattern: str = "*.py") -> Dict[str, Any]:
        """
        Analyse la structure du code dans un répertoire.

        Args:
            directory_path: Chemin vers le répertoire à analyser
            file_pattern: Pattern pour filtrer les fichiers (défaut: "*.py")

        Returns:
            Dictionnaire contenant les résultats de l'analyse
        """
        try:
            import glob

            # Vérifier si le répertoire existe
            if not os.path.exists(directory_path) or not os.path.isdir(directory_path):
                return {"error": f"Le répertoire '{directory_path}' n'existe pas ou n'est pas un répertoire"}

            # Trouver tous les fichiers correspondant au pattern
            files = glob.glob(os.path.join(directory_path, "**", file_pattern), recursive=True)

            # Analyser chaque fichier
            file_stats = []
            total_lines = 0
            total_functions = 0
            total_classes = 0

            for file_path in files:
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        content = f.read()

                    # Analyser le contenu
                    analysis = CodeAnalysisTools.analyze_python_code(content)

                    if "error" not in analysis:
                        stats = analysis["stats"]

                        file_stats.append({
                            "file_path": file_path,
                            "num_lines": stats["num_lines"],
                            "num_functions": len(stats["functions"]),
                            "num_classes": len(stats["classes"]),
                            "complexity": stats["complexity"],
                            "quality_score": analysis["quality_score"]
                        })

                        total_lines += stats["num_lines"]
                        total_functions += len(stats["functions"])
                        total_classes += len(stats["classes"])
                except Exception as e:
                    file_stats.append({
                        "file_path": file_path,
                        "error": str(e)
                    })

            # Calculer des statistiques globales
            avg_lines_per_file = total_lines / len(file_stats) if file_stats else 0
            avg_functions_per_file = total_functions / len(file_stats) if file_stats else 0
            avg_classes_per_file = total_classes / len(file_stats) if file_stats else 0

            # Identifier les fichiers les plus complexes
            file_stats.sort(key=lambda x: x.get("complexity", 0) if isinstance(x.get("complexity"), (int, float)) else 0, reverse=True)
            most_complex_files = file_stats[:5] if len(file_stats) > 5 else file_stats

            return {
                "num_files": len(file_stats),
                "total_lines": total_lines,
                "total_functions": total_functions,
                "total_classes": total_classes,
                "avg_lines_per_file": avg_lines_per_file,
                "avg_functions_per_file": avg_functions_per_file,
                "avg_classes_per_file": avg_classes_per_file,
                "most_complex_files": most_complex_files,
                "file_stats": file_stats
            }
        except Exception as e:
            return {"error": str(e)}

    @staticmethod
    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def detect_code_smells(code: str) -> List[Dict[str, Any]]:
        """
        Détecte les "code smells" (mauvaises pratiques) dans le code.

        Args:
            code: Code à analyser

        Returns:
            Liste des code smells détectés
        """
        try:
            code_smells = []

            # Analyser le code avec ast
            tree = ast.parse(code)

            # Détecter les fonctions trop longues
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    # Compter les lignes de la fonction
                    func_lines = len(ast.unparse(node).splitlines())
                    if func_lines > 30:
                        code_smells.append({
                            "type": "long_function",
                            "message": f"La fonction '{node.name}' est trop longue ({func_lines} lignes)",
                            "line": node.lineno,
                            "severity": "warning"
                        })

                    # Détecter les fonctions avec trop de paramètres
                    if len(node.args.args) > 5:
                        code_smells.append({
                            "type": "too_many_parameters",
                            "message": f"La fonction '{node.name}' a trop de paramètres ({len(node.args.args)})",
                            "line": node.lineno,
                            "severity": "warning"
                        })

                    # Détecter les commentaires TODO
                    for i, line in enumerate(ast.unparse(node).splitlines()):
                        if "TODO" in line or "FIXME" in line:
                            code_smells.append({
                                "type": "todo_comment",
                                "message": f"Commentaire TODO/FIXME trouvé dans la fonction '{node.name}'",
                                "line": node.lineno + i,
                                "severity": "info"
                            })

            # Détecter les classes trop grandes
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    # Compter les méthodes de la classe
                    methods = [n for n in node.body if isinstance(n, ast.FunctionDef)]
                    if len(methods) > 10:
                        code_smells.append({
                            "type": "large_class",
                            "message": f"La classe '{node.name}' a trop de méthodes ({len(methods)})",
                            "line": node.lineno,
                            "severity": "warning"
                        })

            # Détecter les imports non utilisés
            imports = []
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for name in node.names:
                        imports.append({
                            "name": name.name,
                            "alias": name.asname,
                            "line": node.lineno
                        })
                elif isinstance(node, ast.ImportFrom):
                    for name in node.names:
                        imports.append({
                            "name": f"{node.module}.{name.name}" if node.module else name.name,
                            "alias": name.asname,
                            "line": node.lineno
                        })

            # Vérifier si les imports sont utilisés
            for imp in imports:
                name = imp["alias"] if imp["alias"] else imp["name"].split(".")[-1]
                used = False

                for node in ast.walk(tree):
                    if isinstance(node, ast.Name) and node.id == name:
                        used = True
                        break

                if not used:
                    code_smells.append({
                        "type": "unused_import",
                        "message": f"Import non utilisé: '{imp['name']}'",
                        "line": imp["line"],
                        "severity": "warning"
                    })

            return code_smells
        except Exception as e:
            return [{"error": str(e)}]
