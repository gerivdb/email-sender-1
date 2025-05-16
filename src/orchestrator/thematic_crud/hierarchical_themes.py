#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de gestion des thèmes hiérarchiques.

Ce module fournit des fonctionnalités pour gérer des thèmes organisés de manière hiérarchique,
avec des relations parent-enfant entre les thèmes.
"""

import os
import sys
import json
from typing import Dict, List, Any, Optional, Set, Tuple
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer le gestionnaire de cache
from src.orchestrator.utils.cache_manager import cached

class HierarchicalThemeManager:
    """Gestionnaire de thèmes hiérarchiques."""

    def __init__(self, config_path: Optional[str] = None):
        """
        Initialise le gestionnaire de thèmes hiérarchiques.

        Args:
            config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
        """
        self.themes = {}
        self.theme_hierarchy = {}
        self.theme_keywords = {}

        # Charger la configuration des thèmes
        if config_path and os.path.exists(config_path):
            self._load_config(config_path)
        else:
            self._load_default_config()

    def _load_config(self, config_path: str) -> None:
        """
        Charge la configuration des thèmes à partir d'un fichier.

        Args:
            config_path: Chemin vers le fichier de configuration
        """
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)

                if 'themes' in config:
                    self.themes = config['themes']

                if 'theme_hierarchy' in config:
                    self.theme_hierarchy = config['theme_hierarchy']

                if 'theme_keywords' in config:
                    self.theme_keywords = config['theme_keywords']

                # Vérifier la cohérence de la hiérarchie
                self._validate_hierarchy()
        except Exception as e:
            print(f"Erreur lors du chargement de la configuration des thèmes: {str(e)}")
            self._load_default_config()

    def _load_default_config(self) -> None:
        """Charge la configuration par défaut des thèmes hiérarchiques."""
        self.themes = {
            # Thèmes de haut niveau
            "technical": "Aspects techniques",
            "functional": "Aspects fonctionnels",
            "organizational": "Aspects organisationnels",

            # Sous-thèmes techniques
            "architecture": "Architecture et conception",
            "development": "Développement et implémentation",
            "testing": "Tests et qualité",
            "deployment": "Déploiement et opérations",
            "security": "Sécurité et conformité",
            "performance": "Performance et optimisation",

            # Sous-thèmes fonctionnels
            "ui_ux": "Interface utilisateur et expérience",
            "data": "Données et stockage",
            "integration": "Intégration et API",
            "features": "Fonctionnalités et capacités",

            # Sous-thèmes organisationnels
            "documentation": "Documentation et guides",
            "monitoring": "Monitoring et observabilité",
            "automation": "Automatisation et CI/CD",
            "planning": "Planification et gestion de projet"
        }

        self.theme_hierarchy = {
            "technical": ["architecture", "development", "testing", "deployment", "security", "performance"],
            "functional": ["ui_ux", "data", "integration", "features"],
            "organizational": ["documentation", "monitoring", "automation", "planning"]
        }

        self.theme_keywords = {
            # Thèmes de haut niveau
            "technical": ["technique", "technologie", "ingénierie", "développement"],
            "functional": ["fonctionnel", "métier", "utilisateur", "besoin"],
            "organizational": ["organisation", "processus", "méthode", "gestion"],

            # Sous-thèmes techniques
            "architecture": ["architecture", "conception", "design", "pattern", "structure", "modèle", "framework"],
            "development": ["développement", "code", "implémentation", "programmation", "fonctionnalité", "feature"],
            "testing": ["test", "qualité", "validation", "vérification", "assertion", "couverture"],
            "deployment": ["déploiement", "release", "livraison", "production", "environnement", "infrastructure"],
            "security": ["sécurité", "authentification", "autorisation", "chiffrement", "vulnérabilité", "conformité"],
            "performance": ["performance", "optimisation", "vitesse", "latence", "efficacité", "scalabilité"],

            # Sous-thèmes fonctionnels
            "ui_ux": ["interface", "ui", "ux", "utilisateur", "expérience", "frontend", "visuel"],
            "data": ["données", "base de données", "stockage", "persistance", "modèle de données", "migration"],
            "integration": ["intégration", "api", "service", "webhook", "interopérabilité", "communication"],
            "features": ["fonctionnalité", "capacité", "feature", "user story", "exigence", "besoin"],

            # Sous-thèmes organisationnels
            "documentation": ["documentation", "guide", "manuel", "readme", "wiki", "tutoriel"],
            "monitoring": ["monitoring", "observabilité", "logging", "alertes", "métriques", "dashboards"],
            "automation": ["automatisation", "ci", "cd", "pipeline", "workflow", "script", "tâche"],
            "planning": ["planification", "roadmap", "backlog", "sprint", "milestone", "projet"]
        }

    def _validate_hierarchy(self) -> None:
        """Valide la cohérence de la hiérarchie des thèmes."""
        # Vérifier que tous les thèmes parents existent
        for parent, children in self.theme_hierarchy.items():
            if parent not in self.themes:
                raise ValueError(f"Le thème parent '{parent}' n'existe pas dans la liste des thèmes.")

            # Vérifier que tous les enfants existent
            for child in children:
                if child not in self.themes:
                    raise ValueError(f"Le thème enfant '{child}' n'existe pas dans la liste des thèmes.")

        # Vérifier qu'il n'y a pas de cycles dans la hiérarchie
        visited = set()
        path = []

        def dfs(node):
            if node in path:
                cycle = path[path.index(node):] + [node]
                raise ValueError(f"Cycle détecté dans la hiérarchie des thèmes: {' -> '.join(cycle)}")

            if node in visited:
                return

            visited.add(node)
            path.append(node)

            for child in self.theme_hierarchy.get(node, []):
                dfs(child)

            path.pop()

        for theme in self.themes:
            dfs(theme)

    @cached(ttl_memory=3600, ttl_disk=86400)  # 1 heure en mémoire, 24 heures sur disque
    def get_parent_themes(self, theme: str) -> List[str]:
        """
        Récupère les thèmes parents d'un thème.

        Args:
            theme: Thème dont on veut récupérer les parents

        Returns:
            Liste des thèmes parents
        """
        parents = []

        for parent, children in self.theme_hierarchy.items():
            if theme in children:
                parents.append(parent)
                # Récupérer récursivement les parents du parent
                parents.extend(self.get_parent_themes(parent))

        return parents

    @cached(ttl_memory=3600, ttl_disk=86400)  # 1 heure en mémoire, 24 heures sur disque
    def get_child_themes(self, theme: str) -> List[str]:
        """
        Récupère les thèmes enfants d'un thème.

        Args:
            theme: Thème dont on veut récupérer les enfants

        Returns:
            Liste des thèmes enfants
        """
        children = self.theme_hierarchy.get(theme, [])
        all_children = children.copy()

        # Récupérer récursivement les enfants des enfants
        for child in children:
            all_children.extend(self.get_child_themes(child))

        return all_children

    @cached(ttl_memory=3600, ttl_disk=86400)  # 1 heure en mémoire, 24 heures sur disque
    def get_theme_path(self, theme: str) -> List[str]:
        """
        Récupère le chemin complet d'un thème dans la hiérarchie.

        Args:
            theme: Thème dont on veut récupérer le chemin

        Returns:
            Liste des thèmes formant le chemin (du plus général au plus spécifique)
        """
        parents = self.get_parent_themes(theme)

        # Trier les parents par niveau dans la hiérarchie
        path = []
        current = theme

        while parents:
            # Trouver le parent direct
            direct_parent = None
            for parent in parents:
                if current in self.theme_hierarchy.get(parent, []):
                    direct_parent = parent
                    break

            if direct_parent:
                path.insert(0, direct_parent)
                current = direct_parent
                parents.remove(direct_parent)
            else:
                break

        path.append(theme)
        return path

    def propagate_theme_scores(self, theme_scores: Dict[str, float]) -> Dict[str, float]:
        """
        Propage les scores des thèmes à leurs parents et enfants.

        Args:
            theme_scores: Dictionnaire des scores par thème

        Returns:
            Dictionnaire des scores propagés
        """
        propagated_scores = theme_scores.copy()

        # Propager les scores vers les parents (avec atténuation)
        for theme, score in theme_scores.items():
            parents = self.get_parent_themes(theme)
            for i, parent in enumerate(parents):
                # Atténuer le score en fonction de la distance dans la hiérarchie
                attenuation = 0.7 ** (i + 1)
                propagated_score = score * attenuation

                # Mettre à jour le score du parent si nécessaire
                if parent in propagated_scores:
                    propagated_scores[parent] = max(propagated_scores[parent], propagated_score)
                else:
                    propagated_scores[parent] = propagated_score

        # Propager les scores vers les enfants (avec atténuation)
        for theme, score in theme_scores.items():
            children = self.get_child_themes(theme)
            for i, child in enumerate(children):
                # Atténuer le score en fonction de la distance dans la hiérarchie
                attenuation = 0.5 ** (i + 1)
                propagated_score = score * attenuation

                # Mettre à jour le score de l'enfant si nécessaire
                if child in propagated_scores:
                    propagated_scores[child] = max(propagated_scores[child], propagated_score)
                else:
                    propagated_scores[child] = propagated_score

        return propagated_scores

    @cached(ttl_memory=3600, ttl_disk=86400)  # 1 heure en mémoire, 24 heures sur disque
    def get_theme_keywords(self, theme: str) -> List[str]:
        """
        Récupère les mots-clés d'un thème, y compris ceux hérités de ses parents.

        Args:
            theme: Thème dont on veut récupérer les mots-clés

        Returns:
            Liste des mots-clés
        """
        keywords = self.theme_keywords.get(theme, []).copy()

        # Ajouter les mots-clés des parents
        parents = self.get_parent_themes(theme)
        for parent in parents:
            parent_keywords = self.theme_keywords.get(parent, [])
            keywords.extend(parent_keywords)

        # Éliminer les doublons
        return list(set(keywords))

    def save_config(self, config_path: str) -> None:
        """
        Sauvegarde la configuration des thèmes dans un fichier.

        Args:
            config_path: Chemin vers le fichier de configuration
        """
        config = {
            "themes": self.themes,
            "theme_hierarchy": self.theme_hierarchy,
            "theme_keywords": self.theme_keywords
        }

        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, ensure_ascii=False, indent=2)
