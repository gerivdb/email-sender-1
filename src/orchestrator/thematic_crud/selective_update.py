#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de mise à jour sélective par thème.

Ce module fournit des fonctionnalités pour mettre à jour sélectivement des
éléments en fonction de leurs thèmes.
"""

import os
import sys
import json
import re
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Set, Tuple
from pathlib import Path
from collections import defaultdict

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer le gestionnaire de thèmes hiérarchiques
from src.orchestrator.thematic_crud.hierarchical_themes import HierarchicalThemeManager
from src.orchestrator.thematic_crud.theme_change_detector import ThemeChangeDetector

class ThematicSectionExtractor:
    """Classe pour l'extraction de sections thématiques dans le contenu."""
    
    def __init__(self, themes_config_path: Optional[str] = None):
        """
        Initialise l'extracteur de sections thématiques.
        
        Args:
            themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
        """
        # Initialiser le gestionnaire de thèmes hiérarchiques
        self.theme_manager = HierarchicalThemeManager(themes_config_path)
        
        # Récupérer les thèmes et les mots-clés du gestionnaire
        self.themes = self.theme_manager.themes
        self.theme_keywords = self.theme_manager.theme_keywords
    
    def extract_sections(self, content: str) -> Dict[str, List[Dict[str, Any]]]:
        """
        Extrait les sections thématiques d'un contenu.
        
        Args:
            content: Contenu à analyser
            
        Returns:
            Dictionnaire des sections par thème
        """
        # Diviser le contenu en paragraphes
        paragraphs = self._split_into_paragraphs(content)
        
        # Analyser chaque paragraphe
        sections = defaultdict(list)
        
        for i, paragraph in enumerate(paragraphs):
            # Attribuer des thèmes au paragraphe
            themes = self._attribute_themes_to_paragraph(paragraph)
            
            # Ajouter le paragraphe aux sections correspondantes
            for theme, score in themes.items():
                sections[theme].append({
                    'index': i,
                    'content': paragraph,
                    'score': score
                })
        
        return dict(sections)
    
    def extract_section_by_theme(self, content: str, theme: str, 
                               min_score: float = 0.3) -> List[Dict[str, Any]]:
        """
        Extrait les sections correspondant à un thème spécifique.
        
        Args:
            content: Contenu à analyser
            theme: Thème à rechercher
            min_score: Score minimum pour considérer qu'une section appartient au thème
            
        Returns:
            Liste des sections correspondant au thème
        """
        # Extraire toutes les sections
        all_sections = self.extract_sections(content)
        
        # Récupérer les sections du thème spécifié
        theme_sections = all_sections.get(theme, [])
        
        # Filtrer par score minimum
        return [section for section in theme_sections if section['score'] >= min_score]
    
    def _split_into_paragraphs(self, content: str) -> List[str]:
        """
        Divise un contenu en paragraphes.
        
        Args:
            content: Contenu à diviser
            
        Returns:
            Liste des paragraphes
        """
        # Diviser par lignes vides
        paragraphs = re.split(r'\n\s*\n', content)
        
        # Nettoyer les paragraphes
        return [p.strip() for p in paragraphs if p.strip()]
    
    def _attribute_themes_to_paragraph(self, paragraph: str) -> Dict[str, float]:
        """
        Attribue des thèmes à un paragraphe.
        
        Args:
            paragraph: Paragraphe à analyser
            
        Returns:
            Dictionnaire des thèmes avec leurs scores
        """
        scores = {}
        
        # Convertir en minuscules
        paragraph_lower = paragraph.lower()
        
        # Calculer les scores pour chaque thème
        for theme, keywords in self.theme_keywords.items():
            theme_score = 0
            matches = 0
            
            for keyword in keywords:
                keyword_lower = keyword.lower()
                if keyword_lower in paragraph_lower:
                    matches += 1
                    
                    # Donner plus de poids aux mots-clés plus longs
                    length_factor = min(1.0, len(keyword) / 10.0)
                    theme_score += 1.0 + length_factor
            
            # Normaliser le score
            if keywords:
                normalized_score = theme_score / len(keywords)
                
                # Appliquer un bonus pour la diversité des mots-clés
                if matches > 1:
                    diversity_bonus = min(0.5, matches / len(keywords))
                    normalized_score *= (1.0 + diversity_bonus)
                
                if normalized_score > 0:
                    scores[theme] = min(1.0, normalized_score)
        
        return scores

class ThematicSelectiveUpdate:
    """Classe pour la mise à jour sélective par thème."""
    
    def __init__(self, storage_path: str, themes_config_path: Optional[str] = None):
        """
        Initialise le gestionnaire de mise à jour sélective par thème.
        
        Args:
            storage_path: Chemin vers le répertoire de stockage des données
            themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
        """
        self.storage_path = storage_path
        
        # Initialiser l'extracteur de sections thématiques
        self.section_extractor = ThematicSectionExtractor(themes_config_path)
        
        # Initialiser le détecteur de changements thématiques
        self.change_detector = ThemeChangeDetector(themes_config_path)
        
        # Initialiser le gestionnaire de thèmes hiérarchiques
        self.theme_manager = HierarchicalThemeManager(themes_config_path)
    
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
        # Charger l'élément
        item = self._load_item(item_id)
        if not item:
            return None
        
        # Extraire les sections thématiques
        sections = self.section_extractor.extract_sections(item['content'])
        
        # Vérifier si le thème existe dans l'élément
        if theme not in sections:
            return item
        
        # Extraire les sections du thème spécifié
        theme_sections = sections[theme]
        
        # Diviser le nouveau contenu en paragraphes
        new_paragraphs = self.section_extractor._split_into_paragraphs(new_content)
        
        # Vérifier si le nombre de paragraphes correspond
        if len(new_paragraphs) != len(theme_sections):
            # Si le nombre ne correspond pas, remplacer toutes les sections
            return self._replace_all_theme_sections(item, theme, new_content)
        
        # Mettre à jour les sections une par une
        updated_content = self._update_sections(item['content'], theme_sections, new_paragraphs)
        
        # Mettre à jour l'élément
        return self._update_item_content(item, updated_content)
    
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
        # Charger l'élément
        item = self._load_item(item_id)
        if not item:
            return None
        
        # Extraire les sections thématiques
        sections = self.section_extractor.extract_sections(item['content'])
        
        # Vérifier si le thème existe dans l'élément
        if theme not in sections:
            # Si le thème n'existe pas, ajouter le contenu à la fin
            updated_content = item['content'] + "\n\n" + content_to_merge
            return self._update_item_content(item, updated_content)
        
        # Extraire les sections du thème spécifié
        theme_sections = sections[theme]
        
        # Diviser le contenu à fusionner en paragraphes
        merge_paragraphs = self.section_extractor._split_into_paragraphs(content_to_merge)
        
        # Fusionner le contenu
        updated_content = self._merge_content(item['content'], theme_sections, merge_paragraphs)
        
        # Mettre à jour l'élément
        return self._update_item_content(item, updated_content)
    
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
        # Charger l'élément
        item = self._load_item(item_id)
        if not item:
            return None
        
        # Mettre à jour chaque thème séquentiellement
        updated_item = item
        for theme, content in theme_updates.items():
            updated_item = self.update_theme_sections(item_id, theme, content)
            if not updated_item:
                return None
        
        return updated_item
    
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
        # Charger les éléments
        source_item = self._load_item(source_item_id)
        target_item = self._load_item(target_item_id)
        
        if not source_item or not target_item:
            return None
        
        # Extraire les sections du thème de l'élément source
        source_sections = self.section_extractor.extract_section_by_theme(
            source_item['content'], theme
        )
        
        if not source_sections:
            return target_item
        
        # Construire le contenu à partir des sections extraites
        extracted_content = "\n\n".join([section['content'] for section in source_sections])
        
        # Mettre à jour l'élément cible
        return self.update_theme_sections(target_item_id, theme, extracted_content)
    
    def _replace_all_theme_sections(self, item: Dict[str, Any], theme: str, 
                                  new_content: str) -> Dict[str, Any]:
        """
        Remplace toutes les sections d'un thème par un nouveau contenu.
        
        Args:
            item: Élément à mettre à jour
            theme: Thème des sections à remplacer
            new_content: Nouveau contenu
            
        Returns:
            Élément mis à jour
        """
        # Extraire les sections thématiques
        sections = self.section_extractor.extract_sections(item['content'])
        
        # Vérifier si le thème existe dans l'élément
        if theme not in sections:
            # Si le thème n'existe pas, ajouter le contenu à la fin
            updated_content = item['content'] + "\n\n" + new_content
            return self._update_item_content(item, updated_content)
        
        # Extraire les sections du thème spécifié
        theme_sections = sections[theme]
        
        # Diviser le contenu en paragraphes
        paragraphs = self.section_extractor._split_into_paragraphs(item['content'])
        
        # Créer un ensemble des indices à remplacer
        indices_to_replace = {section['index'] for section in theme_sections}
        
        # Construire le nouveau contenu
        new_paragraphs = []
        theme_content_added = False
        
        for i, paragraph in enumerate(paragraphs):
            if i in indices_to_replace:
                if not theme_content_added:
                    # Ajouter le nouveau contenu à la première occurrence
                    new_paragraphs.append(new_content)
                    theme_content_added = True
            else:
                new_paragraphs.append(paragraph)
        
        # Si le thème n'a pas été ajouté (cas improbable), l'ajouter à la fin
        if not theme_content_added:
            new_paragraphs.append(new_content)
        
        # Joindre les paragraphes
        updated_content = "\n\n".join(new_paragraphs)
        
        # Mettre à jour l'élément
        return self._update_item_content(item, updated_content)
    
    def _update_sections(self, content: str, theme_sections: List[Dict[str, Any]], 
                       new_paragraphs: List[str]) -> str:
        """
        Met à jour des sections spécifiques dans le contenu.
        
        Args:
            content: Contenu original
            theme_sections: Sections à mettre à jour
            new_paragraphs: Nouveaux paragraphes
            
        Returns:
            Contenu mis à jour
        """
        # Diviser le contenu en paragraphes
        paragraphs = self.section_extractor._split_into_paragraphs(content)
        
        # Mettre à jour les paragraphes
        for i, section in enumerate(theme_sections):
            if i < len(new_paragraphs):
                paragraphs[section['index']] = new_paragraphs[i]
        
        # Joindre les paragraphes
        return "\n\n".join(paragraphs)
    
    def _merge_content(self, content: str, theme_sections: List[Dict[str, Any]], 
                     merge_paragraphs: List[str]) -> str:
        """
        Fusionne du contenu dans des sections spécifiques.
        
        Args:
            content: Contenu original
            theme_sections: Sections où fusionner le contenu
            merge_paragraphs: Paragraphes à fusionner
            
        Returns:
            Contenu mis à jour
        """
        # Diviser le contenu en paragraphes
        paragraphs = self.section_extractor._split_into_paragraphs(content)
        
        # Si aucune section thématique, ajouter le contenu à la fin
        if not theme_sections:
            paragraphs.extend(merge_paragraphs)
            return "\n\n".join(paragraphs)
        
        # Trouver la dernière section thématique
        last_section_index = max(section['index'] for section in theme_sections)
        
        # Insérer les paragraphes après la dernière section
        updated_paragraphs = paragraphs[:last_section_index + 1]
        updated_paragraphs.extend(merge_paragraphs)
        updated_paragraphs.extend(paragraphs[last_section_index + 1:])
        
        # Joindre les paragraphes
        return "\n\n".join(updated_paragraphs)
    
    def _update_item_content(self, item: Dict[str, Any], new_content: str) -> Dict[str, Any]:
        """
        Met à jour le contenu d'un élément et recalcule ses thèmes.
        
        Args:
            item: Élément à mettre à jour
            new_content: Nouveau contenu
            
        Returns:
            Élément mis à jour
        """
        # Sauvegarder les thèmes actuels
        current_themes = item['metadata'].get('themes', {})
        
        # Mettre à jour le contenu
        updated_item = item.copy()
        updated_item['content'] = new_content
        
        # Mettre à jour la date de modification
        updated_item['metadata']['updated_at'] = datetime.now().isoformat()
        
        # Sauvegarder l'élément
        self._save_item(updated_item)
        
        return updated_item
    
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
