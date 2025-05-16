#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de création et mise à jour thématique.

Ce module fournit des fonctionnalités pour créer et mettre à jour des éléments
de roadmap avec attribution thématique automatique.
"""

import os
import sys
import json
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Set
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer les modules d'attribution thématique
from src.orchestrator.thematic_crud.theme_attribution import ThemeAttributor
from src.orchestrator.thematic_crud.advanced_attribution import AdvancedThemeAttributor
from src.orchestrator.thematic_crud.theme_change_detector import ThemeChangeDetector
from src.orchestrator.thematic_crud.selective_update import ThematicSelectiveUpdate

class ThematicCreateUpdate:
    """Classe pour la création et mise à jour thématique."""

    def __init__(self, storage_path: str, themes_config_path: Optional[str] = None,
                use_advanced_attribution: bool = True,
                history_path: Optional[str] = None,
                learning_rate: float = 0.1,
                context_weight: float = 0.3,
                user_feedback_weight: float = 0.5):
        """
        Initialise le gestionnaire de création et mise à jour thématique.

        Args:
            storage_path: Chemin vers le répertoire de stockage des données
            themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
            use_advanced_attribution: Utiliser l'attribution thématique avancée (défaut: True)
            history_path: Chemin vers le fichier d'historique (optionnel)
            learning_rate: Taux d'apprentissage pour l'adaptation (défaut: 0.1)
            context_weight: Poids du contexte dans l'attribution (défaut: 0.3)
            user_feedback_weight: Poids du retour utilisateur (défaut: 0.5)
        """
        self.storage_path = storage_path
        self.use_advanced_attribution = use_advanced_attribution

        # Initialiser les attributeurs thématiques
        self.theme_attributor = ThemeAttributor(themes_config_path)

        if use_advanced_attribution:
            self.advanced_attributor = AdvancedThemeAttributor(
                themes_config_path,
                history_path,
                learning_rate,
                context_weight,
                user_feedback_weight
            )
        else:
            self.advanced_attributor = None

        # Initialiser le détecteur de changements thématiques
        self.change_detector = ThemeChangeDetector(themes_config_path)

        # Initialiser le gestionnaire de mise à jour sélective
        self.selective_update = ThematicSelectiveUpdate(storage_path, themes_config_path)

        # Créer le répertoire de stockage s'il n'existe pas
        os.makedirs(storage_path, exist_ok=True)

        # Créer les sous-répertoires thématiques
        self._create_theme_directories()

    def _create_theme_directories(self) -> None:
        """Crée les sous-répertoires pour chaque thème."""
        for theme in self.theme_attributor.themes.keys():
            theme_dir = os.path.join(self.storage_path, theme)
            os.makedirs(theme_dir, exist_ok=True)

    def create_item(self, content: str, metadata: Dict[str, Any],
                   context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Crée un nouvel élément avec attribution thématique automatique.

        Args:
            content: Contenu de l'élément
            metadata: Métadonnées de l'élément
            context: Contexte d'attribution (optionnel)

        Returns:
            Élément créé avec ses métadonnées enrichies
        """
        # Générer un identifiant unique
        item_id = str(uuid.uuid4())

        # Ajouter les métadonnées de base
        item_metadata = metadata.copy()
        item_metadata['id'] = item_id
        item_metadata['created_at'] = datetime.now().isoformat()
        item_metadata['updated_at'] = item_metadata['created_at']

        # Attribuer les thèmes
        if self.use_advanced_attribution and self.advanced_attributor:
            themes = self.advanced_attributor.attribute_theme(content, item_metadata, context)
        else:
            themes = self.theme_attributor.attribute_theme(content, item_metadata)

        item_metadata['themes'] = themes

        # Créer l'élément
        item = {
            'id': item_id,
            'content': content,
            'metadata': item_metadata
        }

        # Sauvegarder l'élément
        self._save_item(item)

        return item

    def update_item(self, item_id: str, content: Optional[str] = None,
                   metadata: Optional[Dict[str, Any]] = None,
                   context: Optional[Dict[str, Any]] = None,
                   reattribute_themes: bool = True,
                   detect_changes: bool = True) -> Optional[Dict[str, Any]]:
        """
        Met à jour un élément existant avec détection des changements thématiques.

        Args:
            item_id: Identifiant de l'élément à mettre à jour
            content: Nouveau contenu (optionnel)
            metadata: Nouvelles métadonnées (optionnel)
            context: Contexte d'attribution (optionnel)
            reattribute_themes: Réattribuer les thèmes si le contenu a changé (défaut: True)
            detect_changes: Détecter les changements thématiques (défaut: True)

        Returns:
            Élément mis à jour ou None si l'élément n'existe pas
        """
        # Charger l'élément existant
        item = self._load_item(item_id)
        if not item:
            return None

        # Sauvegarder les thèmes actuels
        current_themes = item['metadata'].get('themes', {})

        # Mettre à jour le contenu si fourni
        if content is not None:
            item['content'] = content

        # Mettre à jour les métadonnées si fournies
        if metadata:
            # Conserver certaines métadonnées d'origine
            preserved_keys = ['id', 'created_at', 'themes']
            for key in preserved_keys:
                if key in item['metadata'] and key not in metadata:
                    metadata[key] = item['metadata'][key]

            item['metadata'] = metadata

        # Mettre à jour la date de modification
        item['metadata']['updated_at'] = datetime.now().isoformat()

        # Réattribuer les thèmes si le contenu a changé et si demandé
        if content is not None and reattribute_themes:
            # Utiliser l'attributeur avancé si disponible
            if self.use_advanced_attribution and self.advanced_attributor:
                new_themes = self.advanced_attributor.attribute_theme(
                    content, item['metadata'], context
                )
            else:
                new_themes = self.theme_attributor.attribute_theme(
                    content, item['metadata']
                )

            item['metadata']['themes'] = new_themes

            # Détecter les changements thématiques si demandé
            if detect_changes:
                theme_changes = self.change_detector.detect_changes(current_themes, new_themes)
                if theme_changes['significance'] > 0.1:  # Seuil de significativité
                    item['metadata']['theme_changes'] = theme_changes

                    # Ajouter des informations sur l'évolution thématique
                    if 'theme_history' not in item['metadata']:
                        item['metadata']['theme_history'] = []

                    # Ajouter l'entrée d'historique
                    history_entry = {
                        'timestamp': datetime.now().isoformat(),
                        'themes': new_themes,
                        'changes': {
                            'significance': theme_changes['significance'],
                            'primary_theme_changed': theme_changes['primary_theme_changed'],
                            'added': [item['theme'] for item in theme_changes['added']],
                            'removed': [item['theme'] for item in theme_changes['removed']]
                        }
                    }

                    item['metadata']['theme_history'].append(history_entry)

                    # Limiter la taille de l'historique
                    if len(item['metadata']['theme_history']) > 10:
                        item['metadata']['theme_history'] = item['metadata']['theme_history'][-10:]

        # Sauvegarder l'élément mis à jour
        self._save_item(item)

        return item

    def add_user_feedback(self, item_id: str, user_themes: Dict[str, float]) -> Optional[Dict[str, Any]]:
        """
        Ajoute un retour utilisateur sur l'attribution thématique.

        Args:
            item_id: Identifiant de l'élément
            user_themes: Thèmes attribués par l'utilisateur avec leurs scores

        Returns:
            Élément mis à jour ou None si l'élément n'existe pas
        """
        # Charger l'élément
        item = self._load_item(item_id)
        if not item:
            return None

        # Ajouter le retour utilisateur à l'historique
        if self.use_advanced_attribution and self.advanced_attributor:
            self.advanced_attributor.add_user_feedback(item_id, user_themes)

        # Mettre à jour les thèmes de l'élément
        item['metadata']['themes'] = user_themes
        item['metadata']['updated_at'] = datetime.now().isoformat()
        item['metadata']['user_feedback'] = True

        # Sauvegarder l'élément mis à jour
        self._save_item(item)

        return item

    def update_theme_sections(self, item_id: str, theme: str,
                            new_content: str) -> Optional[Dict[str, Any]]:
        """
        Met à jour les sections d'un élément correspondant à un thème spécifique.

        Args:
            item_id: Identifiant de l'élément à mettre à jour
            theme: Thème des sections à mettre à jour
            new_content: Nouveau contenu pour les sections

        Returns:
            Élément mis à jour ou None si l'élément n'existe pas
        """
        return self.selective_update.update_theme_sections(item_id, theme, new_content)

    def merge_theme_content(self, item_id: str, theme: str,
                          content_to_merge: str) -> Optional[Dict[str, Any]]:
        """
        Fusionne du contenu dans les sections d'un élément correspondant à un thème.

        Args:
            item_id: Identifiant de l'élément à mettre à jour
            theme: Thème des sections à mettre à jour
            content_to_merge: Contenu à fusionner

        Returns:
            Élément mis à jour ou None si l'élément n'existe pas
        """
        return self.selective_update.merge_theme_content(item_id, theme, content_to_merge)

    def update_multiple_themes(self, item_id: str,
                             theme_updates: Dict[str, str]) -> Optional[Dict[str, Any]]:
        """
        Met à jour plusieurs thèmes d'un élément en une seule opération.

        Args:
            item_id: Identifiant de l'élément à mettre à jour
            theme_updates: Dictionnaire des thèmes à mettre à jour avec leur nouveau contenu

        Returns:
            Élément mis à jour ou None si l'élément n'existe pas
        """
        return self.selective_update.update_multiple_themes(item_id, theme_updates)

    def extract_and_update_theme(self, source_item_id: str, target_item_id: str,
                               theme: str) -> Optional[Dict[str, Any]]:
        """
        Extrait les sections d'un thème d'un élément source et les applique à un élément cible.

        Args:
            source_item_id: Identifiant de l'élément source
            target_item_id: Identifiant de l'élément cible
            theme: Thème à extraire et appliquer

        Returns:
            Élément cible mis à jour ou None si l'un des éléments n'existe pas
        """
        return self.selective_update.extract_and_update_theme(source_item_id, target_item_id, theme)

    def analyze_theme_evolution(self, item_id: str) -> Optional[Dict[str, Any]]:
        """
        Analyse l'évolution des thèmes d'un élément au fil du temps.

        Args:
            item_id: Identifiant de l'élément

        Returns:
            Analyse de l'évolution thématique ou None si l'élément n'existe pas
        """
        # Charger l'élément
        item = self._load_item(item_id)
        if not item:
            return None

        # Vérifier si l'historique thématique existe
        if 'theme_history' not in item['metadata'] or not item['metadata']['theme_history']:
            return {
                'trend': 'stable',
                'emerging_themes': [],
                'declining_themes': [],
                'stable_themes': list(item['metadata'].get('themes', {}).keys()),
                'history_available': False
            }

        # Analyser l'évolution thématique
        return self.change_detector.analyze_theme_evolution(item['metadata']['theme_history'])

    def suggest_theme_corrections(self, item_id: str,
                                expected_themes: Optional[List[str]] = None) -> Optional[Dict[str, Any]]:
        """
        Suggère des corrections thématiques pour un élément.

        Args:
            item_id: Identifiant de l'élément
            expected_themes: Thèmes attendus (optionnel)

        Returns:
            Suggestions de corrections thématiques ou None si l'élément n'existe pas
        """
        # Charger l'élément
        item = self._load_item(item_id)
        if not item:
            return None

        # Suggérer des corrections
        return self.change_detector.suggest_theme_corrections(
            item['content'],
            item['metadata'].get('themes', {}),
            expected_themes
        )

    def _save_item(self, item: Dict[str, Any]) -> None:
        """
        Sauvegarde un élément dans le stockage.

        Args:
            item: Élément à sauvegarder
        """
        item_id = item['id']

        # Sauvegarder dans le répertoire principal
        main_path = os.path.join(self.storage_path, f"{item_id}.json")
        with open(main_path, 'w', encoding='utf-8') as f:
            json.dump(item, f, ensure_ascii=False, indent=2)

        # Sauvegarder dans les répertoires thématiques
        themes = item['metadata'].get('themes', {})
        for theme in themes.keys():
            theme_dir = os.path.join(self.storage_path, theme)
            os.makedirs(theme_dir, exist_ok=True)

            theme_path = os.path.join(theme_dir, f"{item_id}.json")
            with open(theme_path, 'w', encoding='utf-8') as f:
                json.dump(item, f, ensure_ascii=False, indent=2)

    def _load_item(self, item_id: str) -> Optional[Dict[str, Any]]:
        """
        Charge un élément depuis le stockage.

        Args:
            item_id: Identifiant de l'élément à charger

        Returns:
            Élément chargé ou None si l'élément n'existe pas
        """
        item_path = os.path.join(self.storage_path, f"{item_id}.json")

        if not os.path.exists(item_path):
            return None

        try:
            with open(item_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Erreur lors du chargement de l'élément {item_id}: {str(e)}")
            return None
