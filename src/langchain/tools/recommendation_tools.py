#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant des outils de recommandation.

Ce module fournit des outils pour générer des recommandations basées sur l'analyse
de code, de données, etc.
"""

import os
import sys
import re
import ast
import json
from typing import Dict, Any, Optional, List, Union
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer le gestionnaire de cache
from ..utils.cache_manager import cached

class RecommendationTools:
    """Classe contenant des outils de recommandation."""

    @staticmethod
    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def recommend_code_improvements(code: str) -> Dict[str, Any]:
        """
        Recommande des améliorations pour un code Python.

        Args:
            code: Code Python à analyser

        Returns:
            Dictionnaire contenant les recommandations
        """
        try:
            # Analyser le code avec ast
            tree = ast.parse(code)

            # Initialiser les recommandations
            recommendations = {
                "style": [],
                "performance": [],
                "maintainability": [],
                "security": [],
                "overall_score": 0
            }

            # Analyser le style du code
            RecommendationTools._analyze_code_style(code, tree, recommendations)

            # Analyser les performances du code
            RecommendationTools._analyze_code_performance(code, tree, recommendations)

            # Analyser la maintenabilité du code
            RecommendationTools._analyze_code_maintainability(code, tree, recommendations)

            # Analyser la sécurité du code
            RecommendationTools._analyze_code_security(code, tree, recommendations)

            # Calculer un score global
            style_score = max(0, 100 - len(recommendations["style"]) * 5)
            performance_score = max(0, 100 - len(recommendations["performance"]) * 5)
            maintainability_score = max(0, 100 - len(recommendations["maintainability"]) * 5)
            security_score = max(0, 100 - len(recommendations["security"]) * 5)

            recommendations["overall_score"] = (style_score + performance_score + maintainability_score + security_score) / 4

            return recommendations
        except Exception as e:
            return {"error": str(e)}

    @staticmethod
    def _analyze_code_style(code: str, tree: ast.AST, recommendations: Dict[str, List[str]]) -> None:
        """
        Analyse le style du code et ajoute des recommandations.

        Args:
            code: Code Python à analyser
            tree: AST du code
            recommendations: Dictionnaire des recommandations à mettre à jour
        """
        # Vérifier la longueur des lignes
        for i, line in enumerate(code.splitlines(), 1):
            if len(line) > 100:
                recommendations["style"].append(f"Ligne {i} trop longue ({len(line)} caractères). Limiter à 100 caractères.")

        # Vérifier les noms de variables
        for node in ast.walk(tree):
            if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Store):
                # Vérifier les conventions de nommage
                if node.id[0].isupper() and not all(c.isupper() for c in node.id):
                    # Les variables ne devraient pas commencer par une majuscule (sauf constantes)
                    recommendations["style"].append(f"Variable '{node.id}' commence par une majuscule. Utiliser snake_case pour les variables.")
                elif "_" not in node.id and len(node.id) > 1 and not node.id.isupper():
                    # Préférer snake_case pour les variables
                    if not any(node.id.startswith(prefix) for prefix in ["i", "j", "k", "x", "y", "z"]):
                        recommendations["style"].append(f"Variable '{node.id}' n'utilise pas snake_case. Préférer des noms comme 'ma_variable'.")

        # Vérifier les noms de fonctions
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                if node.name[0].isupper():
                    recommendations["style"].append(f"Fonction '{node.name}' commence par une majuscule. Utiliser snake_case pour les fonctions.")
                elif "_" not in node.name and len(node.name) > 1 and not node.name.startswith("__"):
                    recommendations["style"].append(f"Fonction '{node.name}' n'utilise pas snake_case. Préférer des noms comme 'ma_fonction'.")

        # Vérifier les noms de classes
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                if not node.name[0].isupper():
                    recommendations["style"].append(f"Classe '{node.name}' ne commence pas par une majuscule. Utiliser PascalCase pour les classes.")
                elif "_" in node.name:
                    recommendations["style"].append(f"Classe '{node.name}' utilise des underscores. Préférer PascalCase comme 'MaClasse'.")

        # Vérifier les docstrings
        for node in ast.walk(tree):
            if isinstance(node, (ast.Module, ast.ClassDef, ast.FunctionDef)):
                if not ast.get_docstring(node):
                    node_type = "module" if isinstance(node, ast.Module) else "classe" if isinstance(node, ast.ClassDef) else "fonction"
                    node_name = getattr(node, "name", "principal") if hasattr(node, "name") else "principal"
                    recommendations["style"].append(f"Le {node_type} '{node_name}' n'a pas de docstring.")

    @staticmethod
    def _analyze_code_performance(code: str, tree: ast.AST, recommendations: Dict[str, List[str]]) -> None:
        """
        Analyse les performances du code et ajoute des recommandations.

        Args:
            code: Code Python à analyser
            tree: AST du code
            recommendations: Dictionnaire des recommandations à mettre à jour
        """
        # Détecter les boucles imbriquées
        for node in ast.walk(tree):
            if isinstance(node, (ast.For, ast.While)):
                for subnode in ast.walk(node):
                    if isinstance(subnode, (ast.For, ast.While)) and subnode != node:
                        recommendations["performance"].append("Boucles imbriquées détectées. Peut causer des problèmes de performance pour de grands ensembles de données.")
                        break

        # Détecter les appels de fonction dans les boucles
        for node in ast.walk(tree):
            if isinstance(node, (ast.For, ast.While)):
                for subnode in ast.walk(node):
                    if isinstance(subnode, ast.Call) and isinstance(subnode.func, ast.Name):
                        recommendations["performance"].append(f"Appel de fonction '{subnode.func.id}' dans une boucle. Envisager de déplacer l'appel hors de la boucle si possible.")

        # Détecter les concaténations de chaînes dans les boucles
        for node in ast.walk(tree):
            if isinstance(node, (ast.For, ast.While)):
                for subnode in ast.walk(node):
                    if isinstance(subnode, ast.BinOp) and isinstance(subnode.op, ast.Add):
                        # Utiliser ast.Constant au lieu de ast.Str (déprécié)
                        if (isinstance(subnode.left, ast.Constant) and isinstance(subnode.left.value, str)) or \
                           (isinstance(subnode.right, ast.Constant) and isinstance(subnode.right.value, str)):
                            recommendations["performance"].append("Concaténation de chaînes dans une boucle. Utiliser ''.join() pour de meilleures performances.")

        # Détecter les listes en compréhension qui pourraient être des générateurs
        for node in ast.walk(tree):
            if isinstance(node, ast.ListComp):
                # Vérifier si la liste en compréhension est utilisée dans un contexte où un générateur suffirait
                parent = getattr(node, "parent", None)
                if parent and isinstance(parent, ast.Call) and isinstance(parent.func, ast.Name):
                    if parent.func.id in ["sum", "min", "max", "all", "any"]:
                        recommendations["performance"].append(f"Liste en compréhension utilisée avec '{parent.func.id}'. Utiliser une expression génératrice (parenthèses au lieu de crochets) pour économiser de la mémoire.")

    @staticmethod
    def _analyze_code_maintainability(code: str, tree: ast.AST, recommendations: Dict[str, List[str]]) -> None:
        """
        Analyse la maintenabilité du code et ajoute des recommandations.

        Args:
            code: Code Python à analyser
            tree: AST du code
            recommendations: Dictionnaire des recommandations à mettre à jour
        """
        # Détecter les fonctions trop longues
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                func_code = ast.unparse(node)
                func_lines = func_code.count("\n") + 1
                if func_lines > 30:
                    recommendations["maintainability"].append(f"Fonction '{node.name}' trop longue ({func_lines} lignes). Décomposer en fonctions plus petites.")

        # Détecter les fonctions avec trop de paramètres
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                if len(node.args.args) > 5:
                    recommendations["maintainability"].append(f"Fonction '{node.name}' a trop de paramètres ({len(node.args.args)}). Utiliser un objet de configuration ou décomposer la fonction.")

        # Détecter les classes trop grandes
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                methods = [n for n in node.body if isinstance(n, ast.FunctionDef)]
                if len(methods) > 10:
                    recommendations["maintainability"].append(f"Classe '{node.name}' a trop de méthodes ({len(methods)}). Décomposer en classes plus petites.")

        # Détecter les variables globales
        global_vars = []
        for node in ast.walk(tree):
            if isinstance(node, ast.Global):
                global_vars.extend(node.names)

        if global_vars:
            recommendations["maintainability"].append(f"Variables globales détectées: {', '.join(global_vars)}. Éviter les variables globales pour améliorer la maintenabilité.")

        # Détecter les commentaires TODO/FIXME
        for i, line in enumerate(code.splitlines(), 1):
            if "TODO" in line or "FIXME" in line:
                recommendations["maintainability"].append(f"Commentaire TODO/FIXME trouvé à la ligne {i}. Résoudre les problèmes en suspens.")

    @staticmethod
    def _analyze_code_security(code: str, tree: ast.AST, recommendations: Dict[str, List[str]]) -> None:
        """
        Analyse la sécurité du code et ajoute des recommandations.

        Args:
            code: Code Python à analyser
            tree: AST du code
            recommendations: Dictionnaire des recommandations à mettre à jour
        """
        # Détecter les imports dangereux
        dangerous_imports = ["pickle", "marshal", "shelve", "subprocess", "os.system", "eval", "exec"]
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for name in node.names:
                    if name.name in dangerous_imports:
                        recommendations["security"].append(f"Import potentiellement dangereux: '{name.name}'. Utiliser avec précaution.")
            elif isinstance(node, ast.ImportFrom):
                if node.module in dangerous_imports:
                    recommendations["security"].append(f"Import potentiellement dangereux: '{node.module}'. Utiliser avec précaution.")

        # Détecter les appels à eval() ou exec()
        for node in ast.walk(tree):
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
                if node.func.id in ["eval", "exec"]:
                    recommendations["security"].append(f"Appel à {node.func.id}() détecté. Éviter d'utiliser eval() ou exec() avec des entrées non fiables.")

        # Détecter les mots de passe en dur
        password_patterns = ["password", "passwd", "pwd", "secret", "key", "token", "api_key"]
        for node in ast.walk(tree):
            if isinstance(node, ast.Assign):
                for target in node.targets:
                    if isinstance(target, ast.Name):
                        if any(pattern in target.id.lower() for pattern in password_patterns):
                            # Utiliser ast.Constant au lieu de ast.Str (déprécié)
                            if isinstance(node.value, ast.Constant) and isinstance(node.value.value, str):
                                recommendations["security"].append(f"Mot de passe ou clé en dur détecté: '{target.id}'. Utiliser des variables d'environnement ou un gestionnaire de secrets.")

        # Détecter les requêtes SQL brutes
        for node in ast.walk(tree):
            # Utiliser ast.Constant au lieu de ast.Str (déprécié)
            if isinstance(node, ast.Constant) and isinstance(node.value, str):
                value = node.value  # Utiliser value au lieu de s (déprécié)
                if "SELECT" in value or "INSERT" in value or "UPDATE" in value or "DELETE" in value:
                    if "?" not in value and "%s" not in value and ":{" not in value:
                        recommendations["security"].append("Requête SQL brute détectée. Utiliser des requêtes paramétrées pour éviter les injections SQL.")

    @staticmethod
    @cached(ttl_memory=3600, ttl_disk=86400)  # 1 heure en mémoire, 24 heures sur disque
    def recommend_architecture_improvements(directory_path: str) -> Dict[str, Any]:
        """
        Recommande des améliorations d'architecture pour un projet Python.

        Args:
            directory_path: Chemin vers le répertoire du projet

        Returns:
            Dictionnaire contenant les recommandations
        """
        try:
            import glob

            # Vérifier si le répertoire existe
            if not os.path.exists(directory_path) or not os.path.isdir(directory_path):
                return {"error": f"Le répertoire '{directory_path}' n'existe pas ou n'est pas un répertoire"}

            # Trouver tous les fichiers Python
            python_files = glob.glob(os.path.join(directory_path, "**", "*.py"), recursive=True)

            # Initialiser les recommandations
            recommendations = {
                "structure": [],
                "dependencies": [],
                "patterns": [],
                "testing": []
            }

            # Analyser la structure du projet
            RecommendationTools._analyze_project_structure(directory_path, python_files, recommendations)

            # Analyser les dépendances
            RecommendationTools._analyze_project_dependencies(python_files, recommendations)

            # Analyser les patterns de conception
            RecommendationTools._analyze_design_patterns(python_files, recommendations)

            # Analyser les tests
            RecommendationTools._analyze_testing(directory_path, python_files, recommendations)

            return recommendations
        except Exception as e:
            return {"error": str(e)}

    @staticmethod
    def _analyze_project_structure(directory_path: str, python_files: List[str], recommendations: Dict[str, List[str]]) -> None:
        """
        Analyse la structure du projet et ajoute des recommandations.

        Args:
            directory_path: Chemin vers le répertoire du projet
            python_files: Liste des fichiers Python du projet
            recommendations: Dictionnaire des recommandations à mettre à jour
        """
        # Vérifier la présence de __init__.py dans les répertoires
        directories = set()
        for file_path in python_files:
            directory = os.path.dirname(file_path)
            if directory != directory_path and directory not in directories:
                directories.add(directory)

                # Vérifier si le répertoire contient un __init__.py
                init_file = os.path.join(directory, "__init__.py")
                if not os.path.exists(init_file):
                    rel_dir = os.path.relpath(directory, directory_path)
                    recommendations["structure"].append(f"Le répertoire '{rel_dir}' ne contient pas de fichier __init__.py. Ajouter un fichier __init__.py pour en faire un package Python.")

        # Vérifier la présence de setup.py ou pyproject.toml
        setup_file = os.path.join(directory_path, "setup.py")
        pyproject_file = os.path.join(directory_path, "pyproject.toml")
        if not os.path.exists(setup_file) and not os.path.exists(pyproject_file):
            recommendations["structure"].append("Aucun fichier setup.py ou pyproject.toml trouvé. Ajouter un fichier de configuration pour faciliter l'installation et la distribution.")

        # Vérifier la présence de README.md
        readme_file = os.path.join(directory_path, "README.md")
        if not os.path.exists(readme_file):
            recommendations["structure"].append("Aucun fichier README.md trouvé. Ajouter un README pour documenter le projet.")

        # Vérifier la présence de tests
        test_dirs = [
            os.path.join(directory_path, "tests"),
            os.path.join(directory_path, "test")
        ]
        if not any(os.path.exists(test_dir) for test_dir in test_dirs):
            recommendations["structure"].append("Aucun répertoire de tests trouvé. Créer un répertoire 'tests' pour les tests unitaires et d'intégration.")

    @staticmethod
    def _analyze_project_dependencies(python_files: List[str], recommendations: Dict[str, List[str]]) -> None:
        """
        Analyse les dépendances du projet et ajoute des recommandations.

        Args:
            python_files: Liste des fichiers Python du projet
            recommendations: Dictionnaire des recommandations à mettre à jour
        """
        # Collecter les imports
        imports = {}
        for file_path in python_files:
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()

                tree = ast.parse(content)

                for node in ast.walk(tree):
                    if isinstance(node, ast.Import):
                        for name in node.names:
                            module_name = name.name.split(".")[0]
                            if module_name not in imports:
                                imports[module_name] = 0
                            imports[module_name] += 1
                    elif isinstance(node, ast.ImportFrom):
                        if node.module:
                            module_name = node.module.split(".")[0]
                            if module_name not in imports:
                                imports[module_name] = 0
                            imports[module_name] += 1
            except Exception:
                pass

        # Vérifier les dépendances courantes
        standard_libs = ["os", "sys", "re", "json", "datetime", "collections", "itertools", "functools", "math", "random", "time", "typing"]
        external_deps = [name for name in imports.keys() if name not in standard_libs and not name.startswith("_")]

        # Vérifier la présence de requirements.txt ou Pipfile
        if external_deps:
            recommendations["dependencies"].append(f"Dépendances externes détectées: {', '.join(external_deps)}. Assurez-vous qu'elles sont documentées dans requirements.txt ou Pipfile.")

        # Vérifier les dépendances circulaires (approximation)
        # Une analyse plus précise nécessiterait de construire un graphe de dépendances
        if len(python_files) > 5:
            recommendations["dependencies"].append("Projet de taille moyenne à grande. Vérifier les dépendances circulaires entre modules qui peuvent causer des problèmes d'importation.")

    @staticmethod
    def _analyze_design_patterns(python_files: List[str], recommendations: Dict[str, List[str]]) -> None:
        """
        Analyse les patterns de conception du projet et ajoute des recommandations.

        Args:
            python_files: Liste des fichiers Python du projet
            recommendations: Dictionnaire des recommandations à mettre à jour
        """
        # Détecter les classes avec des noms suggérant des patterns
        pattern_indicators = {
            "Factory": "Factory Pattern",
            "Builder": "Builder Pattern",
            "Singleton": "Singleton Pattern",
            "Adapter": "Adapter Pattern",
            "Decorator": "Decorator Pattern",
            "Observer": "Observer Pattern",
            "Strategy": "Strategy Pattern"
        }

        detected_patterns = set()

        for file_path in python_files:
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()

                tree = ast.parse(content)

                for node in ast.walk(tree):
                    if isinstance(node, ast.ClassDef):
                        for pattern, pattern_name in pattern_indicators.items():
                            if pattern in node.name:
                                detected_patterns.add(pattern_name)
            except Exception:
                pass

        if detected_patterns:
            recommendations["patterns"].append(f"Patterns de conception détectés: {', '.join(detected_patterns)}. Assurez-vous qu'ils sont correctement implémentés et documentés.")
        else:
            recommendations["patterns"].append("Aucun pattern de conception courant détecté. Envisager d'utiliser des patterns comme Factory, Builder, ou Strategy pour améliorer la modularité et la maintenabilité.")

    @staticmethod
    def _analyze_testing(directory_path: str, python_files: List[str], recommendations: Dict[str, List[str]]) -> None:
        """
        Analyse les tests du projet et ajoute des recommandations.

        Args:
            directory_path: Chemin vers le répertoire du projet
            python_files: Liste des fichiers Python du projet
            recommendations: Dictionnaire des recommandations à mettre à jour
        """
        # Compter les fichiers de test
        test_files = [f for f in python_files if "test" in os.path.basename(f).lower()]

        if not test_files:
            recommendations["testing"].append("Aucun fichier de test trouvé. Ajouter des tests unitaires et d'intégration pour assurer la qualité du code.")
        else:
            # Calculer le ratio de tests
            test_ratio = len(test_files) / len(python_files)
            if test_ratio < 0.2:
                recommendations["testing"].append(f"Ratio de fichiers de test faible ({test_ratio:.2f}). Augmenter la couverture de test pour améliorer la qualité du code.")

        # Vérifier la présence de frameworks de test
        test_frameworks = ["pytest", "unittest", "nose"]
        detected_frameworks = set()

        for file_path in test_files:
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()

                for framework in test_frameworks:
                    if framework in content:
                        detected_frameworks.add(framework)
            except Exception:
                pass

        if not detected_frameworks and test_files:
            recommendations["testing"].append("Aucun framework de test standard détecté. Utiliser pytest ou unittest pour structurer les tests.")

        # Vérifier la présence de fichiers de configuration pour les tests
        pytest_conf = os.path.join(directory_path, "pytest.ini")
        tox_conf = os.path.join(directory_path, "tox.ini")

        if not os.path.exists(pytest_conf) and not os.path.exists(tox_conf) and test_files:
            recommendations["testing"].append("Aucun fichier de configuration pour les tests trouvé. Ajouter pytest.ini ou tox.ini pour configurer les tests.")

    @staticmethod
    @cached(ttl_memory=3600, ttl_disk=86400)  # 1 heure en mémoire, 24 heures sur disque
    def recommend_technology_stack(requirements: List[str]) -> Dict[str, List[str]]:
        """
        Recommande une pile technologique basée sur les exigences du projet.

        Args:
            requirements: Liste des exigences du projet

        Returns:
            Dictionnaire contenant les recommandations de technologies
        """
        # Initialiser les recommandations
        recommendations = {
            "backend": [],
            "frontend": [],
            "database": [],
            "devops": [],
            "testing": []
        }

        # Mots-clés pour la détection des exigences
        backend_keywords = {
            "api": ["FastAPI", "Flask", "Django REST Framework"],
            "web": ["Django", "Flask", "FastAPI"],
            "microservices": ["FastAPI", "Flask", "aiohttp"],
            "async": ["FastAPI", "aiohttp", "Sanic"],
            "performance": ["FastAPI", "Starlette", "uvicorn"],
            "graphql": ["Strawberry", "Ariadne", "Graphene"],
            "serverless": ["AWS Lambda + Chalice", "Azure Functions", "Google Cloud Functions"]
        }

        frontend_keywords = {
            "web": ["React", "Vue.js", "Angular"],
            "spa": ["React", "Vue.js", "Angular"],
            "mobile": ["React Native", "Flutter", "Ionic"],
            "desktop": ["Electron", "PyQt", "Tkinter"],
            "responsive": ["React + Material-UI", "Vue + Vuetify", "Bootstrap"],
            "static": ["Next.js", "Gatsby", "Nuxt.js"]
        }

        database_keywords = {
            "sql": ["PostgreSQL", "MySQL", "SQLite"],
            "nosql": ["MongoDB", "DynamoDB", "Firestore"],
            "graph": ["Neo4j", "ArangoDB", "Amazon Neptune"],
            "time series": ["InfluxDB", "TimescaleDB", "Prometheus"],
            "cache": ["Redis", "Memcached", "Hazelcast"],
            "search": ["Elasticsearch", "Solr", "Meilisearch"]
        }

        devops_keywords = {
            "ci": ["GitHub Actions", "GitLab CI", "Jenkins"],
            "cd": ["ArgoCD", "Spinnaker", "GitHub Actions"],
            "container": ["Docker", "Kubernetes", "Docker Compose"],
            "serverless": ["AWS Lambda", "Azure Functions", "Google Cloud Functions"],
            "monitoring": ["Prometheus + Grafana", "Datadog", "New Relic"],
            "logging": ["ELK Stack", "Loki + Grafana", "Graylog"]
        }

        testing_keywords = {
            "unit": ["pytest", "unittest", "Jest"],
            "integration": ["pytest", "TestContainers", "Cypress"],
            "e2e": ["Selenium", "Cypress", "Playwright"],
            "performance": ["Locust", "JMeter", "k6"],
            "security": ["OWASP ZAP", "Bandit", "Safety"]
        }

        # Analyser les exigences
        for req in requirements:
            req_lower = req.lower()

            # Backend
            for keyword, techs in backend_keywords.items():
                if keyword in req_lower:
                    recommendations["backend"].extend(techs)

            # Frontend
            for keyword, techs in frontend_keywords.items():
                if keyword in req_lower:
                    recommendations["frontend"].extend(techs)

            # Database
            for keyword, techs in database_keywords.items():
                if keyword in req_lower:
                    recommendations["database"].extend(techs)

            # DevOps
            for keyword, techs in devops_keywords.items():
                if keyword in req_lower:
                    recommendations["devops"].extend(techs)

            # Testing
            for keyword, techs in testing_keywords.items():
                if keyword in req_lower:
                    recommendations["testing"].extend(techs)

        # Dédupliquer et trier les recommandations
        for category in recommendations:
            if recommendations[category]:
                # Compter les occurrences pour trier par pertinence
                tech_counts = {}
                for tech in recommendations[category]:
                    if tech not in tech_counts:
                        tech_counts[tech] = 0
                    tech_counts[tech] += 1

                # Trier par nombre d'occurrences (pertinence)
                sorted_techs = sorted(tech_counts.items(), key=lambda x: x[1], reverse=True)
                recommendations[category] = [tech for tech, _ in sorted_techs]
            else:
                # Recommandations par défaut si aucune exigence spécifique
                if category == "backend":
                    recommendations[category] = ["FastAPI", "Django", "Flask"]
                elif category == "frontend":
                    recommendations[category] = ["React", "Vue.js", "Angular"]
                elif category == "database":
                    recommendations[category] = ["PostgreSQL", "MongoDB", "Redis"]
                elif category == "devops":
                    recommendations[category] = ["Docker", "GitHub Actions", "Kubernetes"]
                elif category == "testing":
                    recommendations[category] = ["pytest", "Cypress", "Locust"]

        return recommendations
