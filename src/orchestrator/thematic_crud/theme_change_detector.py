#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de détection des changements thématiques.

Ce module fournit des fonctionnalités pour détecter et analyser les changements
thématiques dans les éléments au fil du temps.
"""

import os
import sys
import json
import re
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Union, Set, Tuple
from pathlib import Path
from collections import defaultdict

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer le gestionnaire de thèmes hiérarchiques
from src.orchestrator.thematic_crud.hierarchical_themes import HierarchicalThemeManager

class ThemeChangeDetector:
    """Classe pour la détection et l'analyse des changements thématiques."""
    
    def __init__(self, themes_config_path: Optional[str] = None,
                significance_threshold: float = 0.2):
        """
        Initialise le détecteur de changements thématiques.
        
        Args:
            themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
            significance_threshold: Seuil de significativité pour les changements (défaut: 0.2)
        """
        # Initialiser le gestionnaire de thèmes hiérarchiques
        self.theme_manager = HierarchicalThemeManager(themes_config_path)
        
        # Récupérer les thèmes du gestionnaire
        self.themes = self.theme_manager.themes
        
        # Seuil de significativité pour les changements
        self.significance_threshold = significance_threshold
    
    def detect_changes(self, old_themes: Dict[str, float], new_themes: Dict[str, float]) -> Dict[str, Any]:
        """
        Détecte les changements thématiques entre deux ensembles de thèmes.
        
        Args:
            old_themes: Anciens thèmes avec leurs scores
            new_themes: Nouveaux thèmes avec leurs scores
            
        Returns:
            Dictionnaire des changements thématiques
        """
        changes = {
            'added': [],
            'removed': [],
            'increased': [],
            'decreased': [],
            'unchanged': [],
            'significance': 0.0,
            'primary_theme_changed': False,
            'primary_themes': {
                'old': None,
                'new': None
            }
        }
        
        # Détecter les thèmes ajoutés et supprimés
        old_theme_keys = set(old_themes.keys())
        new_theme_keys = set(new_themes.keys())
        
        # Thèmes ajoutés
        for theme in new_theme_keys - old_theme_keys:
            changes['added'].append({
                'theme': theme,
                'score': new_themes[theme]
            })
        
        # Thèmes supprimés
        for theme in old_theme_keys - new_theme_keys:
            changes['removed'].append({
                'theme': theme,
                'score': old_themes[theme]
            })
        
        # Détecter les changements de score
        for theme in old_theme_keys & new_theme_keys:
            old_score = old_themes[theme]
            new_score = new_themes[theme]
            
            # Calculer la variation relative
            if old_score > 0:
                relative_change = (new_score - old_score) / old_score
            else:
                relative_change = 1.0 if new_score > 0 else 0.0
            
            if relative_change > self.significance_threshold:
                changes['increased'].append({
                    'theme': theme,
                    'old_score': old_score,
                    'new_score': new_score,
                    'change': relative_change
                })
            elif relative_change < -self.significance_threshold:
                changes['decreased'].append({
                    'theme': theme,
                    'old_score': old_score,
                    'new_score': new_score,
                    'change': relative_change
                })
            else:
                changes['unchanged'].append({
                    'theme': theme,
                    'old_score': old_score,
                    'new_score': new_score,
                    'change': relative_change
                })
        
        # Calculer la significativité globale des changements
        changes['significance'] = self._calculate_significance(changes)
        
        # Détecter le changement de thème principal
        old_primary = self._get_primary_theme(old_themes)
        new_primary = self._get_primary_theme(new_themes)
        
        changes['primary_themes']['old'] = old_primary
        changes['primary_themes']['new'] = new_primary
        changes['primary_theme_changed'] = old_primary != new_primary
        
        return changes
    
    def analyze_theme_evolution(self, theme_history: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Analyse l'évolution des thèmes au fil du temps.
        
        Args:
            theme_history: Liste des thèmes attribués à différents moments
            
        Returns:
            Analyse de l'évolution thématique
        """
        if not theme_history:
            return {
                'trend': 'stable',
                'emerging_themes': [],
                'declining_themes': [],
                'stable_themes': []
            }
        
        # Trier l'historique par date
        sorted_history = sorted(theme_history, key=lambda x: x.get('timestamp', ''))
        
        # Extraire les thèmes de chaque point de l'historique
        theme_points = []
        for point in sorted_history:
            if 'themes' in point and isinstance(point['themes'], dict):
                theme_points.append({
                    'timestamp': point.get('timestamp', ''),
                    'themes': point['themes']
                })
        
        if len(theme_points) < 2:
            return {
                'trend': 'stable',
                'emerging_themes': [],
                'declining_themes': [],
                'stable_themes': list(theme_points[0]['themes'].keys()) if theme_points else []
            }
        
        # Analyser les tendances
        first_point = theme_points[0]
        last_point = theme_points[-1]
        
        # Détecter les changements entre le premier et le dernier point
        changes = self.detect_changes(first_point['themes'], last_point['themes'])
        
        # Identifier les thèmes émergents, déclinants et stables
        emerging_themes = [item['theme'] for item in changes['added']]
        emerging_themes.extend([item['theme'] for item in changes['increased']])
        
        declining_themes = [item['theme'] for item in changes['removed']]
        declining_themes.extend([item['theme'] for item in changes['decreased']])
        
        stable_themes = [item['theme'] for item in changes['unchanged']]
        
        # Déterminer la tendance globale
        if changes['significance'] > 0.5:
            if changes['primary_theme_changed']:
                trend = 'major_shift'
            else:
                trend = 'evolving'
        elif changes['significance'] > 0.2:
            trend = 'gradual_change'
        else:
            trend = 'stable'
        
        return {
            'trend': trend,
            'emerging_themes': emerging_themes,
            'declining_themes': declining_themes,
            'stable_themes': stable_themes,
            'significance': changes['significance'],
            'primary_theme_changed': changes['primary_theme_changed'],
            'primary_themes': changes['primary_themes'],
            'period': {
                'start': first_point['timestamp'],
                'end': last_point['timestamp']
            }
        }
    
    def detect_theme_drift(self, original_themes: Dict[str, float], 
                          current_themes: Dict[str, float]) -> Dict[str, Any]:
        """
        Détecte la dérive thématique entre les thèmes originaux et actuels.
        
        Args:
            original_themes: Thèmes originaux avec leurs scores
            current_themes: Thèmes actuels avec leurs scores
            
        Returns:
            Analyse de la dérive thématique
        """
        # Détecter les changements
        changes = self.detect_changes(original_themes, current_themes)
        
        # Calculer la distance thématique
        distance = self._calculate_theme_distance(original_themes, current_themes)
        
        # Analyser la cohérence thématique
        coherence = self._analyze_theme_coherence(original_themes, current_themes)
        
        # Déterminer le type de dérive
        if distance > 0.7:
            drift_type = 'complete_shift'
        elif distance > 0.4:
            drift_type = 'significant_drift'
        elif distance > 0.2:
            drift_type = 'moderate_drift'
        else:
            drift_type = 'minimal_drift'
        
        return {
            'drift_type': drift_type,
            'distance': distance,
            'coherence': coherence,
            'changes': changes
        }
    
    def suggest_theme_corrections(self, content: str, current_themes: Dict[str, float],
                                expected_themes: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Suggère des corrections thématiques basées sur le contenu et les attentes.
        
        Args:
            content: Contenu de l'élément
            current_themes: Thèmes actuels avec leurs scores
            expected_themes: Thèmes attendus (optionnel)
            
        Returns:
            Suggestions de corrections thématiques
        """
        suggestions = {
            'add': [],
            'remove': [],
            'adjust': [],
            'explanation': {}
        }
        
        # Analyser les mots-clés dans le contenu
        content_keywords = self._extract_keywords(content)
        
        # Identifier les thèmes potentiels basés sur les mots-clés
        potential_themes = {}
        for theme, keywords in self.theme_manager.theme_keywords.items():
            matches = []
            for keyword in keywords:
                if keyword.lower() in content_keywords:
                    matches.append(keyword)
            
            if matches:
                potential_themes[theme] = {
                    'matches': matches,
                    'match_count': len(matches)
                }
        
        # Comparer avec les thèmes actuels
        for theme, data in potential_themes.items():
            if theme not in current_themes and data['match_count'] >= 2:
                # Suggérer d'ajouter ce thème
                suggestions['add'].append({
                    'theme': theme,
                    'reason': f"Contient {data['match_count']} mots-clés associés: {', '.join(data['matches'][:3])}"
                })
                suggestions['explanation'][theme] = f"Le contenu contient plusieurs mots-clés associés au thème '{theme}'"
        
        for theme in current_themes:
            if theme not in potential_themes and current_themes[theme] < 0.4:
                # Suggérer de supprimer ce thème
                suggestions['remove'].append({
                    'theme': theme,
                    'reason': "Peu de correspondance avec le contenu"
                })
                suggestions['explanation'][theme] = f"Le thème '{theme}' a un score faible et ne correspond pas aux mots-clés du contenu"
        
        # Prendre en compte les thèmes attendus
        if expected_themes:
            for theme in expected_themes:
                if theme not in current_themes and theme in self.themes:
                    # Suggérer d'ajouter ce thème attendu
                    suggestions['add'].append({
                        'theme': theme,
                        'reason': "Thème attendu"
                    })
                    suggestions['explanation'][theme] = f"Le thème '{theme}' est attendu mais n'est pas présent"
        
        return suggestions
    
    def _get_primary_theme(self, themes: Dict[str, float]) -> Optional[str]:
        """
        Récupère le thème principal (avec le score le plus élevé).
        
        Args:
            themes: Dictionnaire des thèmes avec leurs scores
            
        Returns:
            Thème principal ou None si aucun thème
        """
        if not themes:
            return None
        
        return max(themes.items(), key=lambda x: x[1])[0]
    
    def _calculate_significance(self, changes: Dict[str, Any]) -> float:
        """
        Calcule la significativité globale des changements.
        
        Args:
            changes: Dictionnaire des changements thématiques
            
        Returns:
            Score de significativité (entre 0 et 1)
        """
        # Pondérer les différents types de changements
        added_weight = 0.7
        removed_weight = 0.6
        increased_weight = 0.5
        decreased_weight = 0.4
        
        # Calculer le score pour chaque type de changement
        added_score = len(changes['added']) * added_weight
        removed_score = len(changes['removed']) * removed_weight
        
        increased_score = 0
        for item in changes['increased']:
            increased_score += abs(item['change']) * increased_weight
        
        decreased_score = 0
        for item in changes['decreased']:
            decreased_score += abs(item['change']) * decreased_weight
        
        # Combiner les scores
        total_score = added_score + removed_score + increased_score + decreased_score
        
        # Normaliser le score (limiter à 1.0)
        return min(1.0, total_score)
    
    def _calculate_theme_distance(self, themes_a: Dict[str, float], 
                                themes_b: Dict[str, float]) -> float:
        """
        Calcule la distance entre deux ensembles de thèmes.
        
        Args:
            themes_a: Premier ensemble de thèmes
            themes_b: Deuxième ensemble de thèmes
            
        Returns:
            Distance thématique (entre 0 et 1)
        """
        # Récupérer tous les thèmes
        all_themes = set(themes_a.keys()) | set(themes_b.keys())
        
        if not all_themes:
            return 0.0
        
        # Calculer la distance euclidienne normalisée
        sum_squared_diff = 0.0
        for theme in all_themes:
            score_a = themes_a.get(theme, 0.0)
            score_b = themes_b.get(theme, 0.0)
            sum_squared_diff += (score_a - score_b) ** 2
        
        # Normaliser par le nombre de thèmes
        distance = (sum_squared_diff / len(all_themes)) ** 0.5
        
        # Limiter à 1.0
        return min(1.0, distance)
    
    def _analyze_theme_coherence(self, themes_a: Dict[str, float], 
                               themes_b: Dict[str, float]) -> Dict[str, Any]:
        """
        Analyse la cohérence entre deux ensembles de thèmes.
        
        Args:
            themes_a: Premier ensemble de thèmes
            themes_b: Deuxième ensemble de thèmes
            
        Returns:
            Analyse de la cohérence thématique
        """
        # Récupérer les thèmes principaux
        primary_a = self._get_primary_theme(themes_a)
        primary_b = self._get_primary_theme(themes_b)
        
        # Calculer le chevauchement des thèmes
        themes_a_set = set(themes_a.keys())
        themes_b_set = set(themes_b.keys())
        
        overlap = themes_a_set & themes_b_set
        overlap_ratio = len(overlap) / len(themes_a_set | themes_b_set) if themes_a_set | themes_b_set else 0.0
        
        # Analyser la relation hiérarchique
        hierarchical_relation = "none"
        if primary_a and primary_b:
            if primary_a == primary_b:
                hierarchical_relation = "same"
            elif primary_b in self.theme_manager.get_parent_themes(primary_a):
                hierarchical_relation = "specialization"
            elif primary_a in self.theme_manager.get_parent_themes(primary_b):
                hierarchical_relation = "generalization"
            elif set(self.theme_manager.get_parent_themes(primary_a)) & set(self.theme_manager.get_parent_themes(primary_b)):
                hierarchical_relation = "siblings"
        
        return {
            'overlap_ratio': overlap_ratio,
            'common_themes': list(overlap),
            'hierarchical_relation': hierarchical_relation,
            'primary_themes': {
                'a': primary_a,
                'b': primary_b
            }
        }
    
    def _extract_keywords(self, content: str) -> Set[str]:
        """
        Extrait les mots-clés d'un contenu.
        
        Args:
            content: Contenu à analyser
            
        Returns:
            Ensemble des mots-clés extraits
        """
        # Convertir en minuscules
        content = content.lower()
        
        # Extraire les mots
        words = re.findall(r'\b\w+\b', content)
        
        # Filtrer les mots courts
        keywords = {word for word in words if len(word) > 3}
        
        return keywords
