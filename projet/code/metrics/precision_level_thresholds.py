#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour définir des seuils généraux par niveau de précision.
"""

import numpy as np
import json
import os
from typing import Dict, List, Tuple, Union, Optional


class PrecisionLevelThresholds:
    """
    Classe pour gérer les seuils généraux par niveau de précision.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialise les seuils par niveau de précision.
        
        Args:
            config_path: Chemin vers le fichier de configuration des seuils
        """
        # Définir les niveaux de précision standards
        self.precision_levels = {
            "high": {
                "description": "Haute précision - Pour les analyses critiques et la recherche",
                "total_error": 5.0,
                "mean_error": 3.0,
                "variance_error": 5.0,
                "skewness_error": 8.0,
                "kurtosis_error": 10.0,
                "confidence_interval": 0.99
            },
            "medium": {
                "description": "Précision moyenne - Pour les analyses opérationnelles",
                "total_error": 10.0,
                "mean_error": 7.0,
                "variance_error": 10.0,
                "skewness_error": 15.0,
                "kurtosis_error": 20.0,
                "confidence_interval": 0.95
            },
            "low": {
                "description": "Précision basse - Pour les analyses exploratoires",
                "total_error": 20.0,
                "mean_error": 15.0,
                "variance_error": 20.0,
                "skewness_error": 30.0,
                "kurtosis_error": 40.0,
                "confidence_interval": 0.90
            },
            "minimal": {
                "description": "Précision minimale - Pour les aperçus rapides",
                "total_error": 30.0,
                "mean_error": 25.0,
                "variance_error": 30.0,
                "skewness_error": 50.0,
                "kurtosis_error": 60.0,
                "confidence_interval": 0.80
            }
        }
        
        # Charger les seuils personnalisés si un fichier de configuration est fourni
        self.custom_levels = {}
        if config_path and os.path.exists(config_path):
            try:
                with open(config_path, 'r') as f:
                    self.custom_levels = json.load(f)
            except (json.JSONDecodeError, IOError) as e:
                print(f"Erreur lors du chargement du fichier de configuration: {e}")
    
    def get_precision_level(self, level_name: str) -> Dict[str, Union[str, float]]:
        """
        Obtient les seuils pour un niveau de précision donné.
        
        Args:
            level_name: Nom du niveau de précision
            
        Returns:
            level_config: Configuration du niveau de précision
        """
        # Vérifier si le niveau existe dans les niveaux personnalisés
        if level_name in self.custom_levels:
            return self.custom_levels[level_name]
        
        # Vérifier si le niveau existe dans les niveaux standards
        if level_name in self.precision_levels:
            return self.precision_levels[level_name]
        
        # Si le niveau n'existe pas, retourner le niveau moyen par défaut
        print(f"Niveau de précision '{level_name}' non trouvé. Utilisation du niveau 'medium' par défaut.")
        return self.precision_levels["medium"]
    
    def get_all_precision_levels(self) -> Dict[str, Dict[str, Union[str, float]]]:
        """
        Obtient tous les niveaux de précision disponibles.
        
        Returns:
            all_levels: Dictionnaire de tous les niveaux de précision
        """
        # Combiner les niveaux standards et personnalisés
        all_levels = {**self.precision_levels, **self.custom_levels}
        return all_levels
    
    def add_custom_precision_level(self, level_name: str, level_config: Dict[str, Union[str, float]]) -> bool:
        """
        Ajoute un niveau de précision personnalisé.
        
        Args:
            level_name: Nom du niveau de précision
            level_config: Configuration du niveau de précision
            
        Returns:
            success: Booléen indiquant si l'ajout a réussi
        """
        # Vérifier que la configuration contient les champs requis
        required_fields = ["description", "total_error", "mean_error", "variance_error", 
                          "skewness_error", "kurtosis_error", "confidence_interval"]
        
        for field in required_fields:
            if field not in level_config:
                print(f"Champ requis '{field}' manquant dans la configuration du niveau de précision.")
                return False
        
        # Ajouter le niveau personnalisé
        self.custom_levels[level_name] = level_config
        return True
    
    def save_custom_levels(self, config_path: str) -> bool:
        """
        Sauvegarde les niveaux de précision personnalisés dans un fichier de configuration.
        
        Args:
            config_path: Chemin du fichier de configuration
            
        Returns:
            success: Booléen indiquant si la sauvegarde a réussi
        """
        try:
            # Créer le répertoire parent s'il n'existe pas
            os.makedirs(os.path.dirname(config_path), exist_ok=True)
            
            # Sauvegarder les niveaux personnalisés
            with open(config_path, 'w') as f:
                json.dump(self.custom_levels, f, indent=4)
            
            return True
        except (IOError, OSError) as e:
            print(f"Erreur lors de la sauvegarde des niveaux de précision personnalisés: {e}")
            return False
    
    def get_thresholds_for_context(self, precision_level: str, context: str) -> Dict[str, float]:
        """
        Obtient les seuils pour un niveau de précision et un contexte donnés.
        
        Args:
            precision_level: Niveau de précision
            context: Contexte d'analyse
            
        Returns:
            thresholds: Dictionnaire des seuils
        """
        # Obtenir la configuration du niveau de précision
        level_config = self.get_precision_level(precision_level)
        
        # Définir les facteurs d'ajustement par contexte
        context_factors = {
            "monitoring": {
                "total_error": 1.0,
                "mean_error": 0.8,
                "variance_error": 1.0,
                "skewness_error": 1.2,
                "kurtosis_error": 1.5
            },
            "stability": {
                "total_error": 0.9,
                "mean_error": 1.0,
                "variance_error": 0.7,
                "skewness_error": 1.0,
                "kurtosis_error": 1.2
            },
            "anomaly_detection": {
                "total_error": 0.8,
                "mean_error": 1.0,
                "variance_error": 0.9,
                "skewness_error": 0.6,
                "kurtosis_error": 0.7
            },
            "characterization": {
                "total_error": 0.7,
                "mean_error": 0.7,
                "variance_error": 0.7,
                "skewness_error": 0.7,
                "kurtosis_error": 0.7
            },
            "default": {
                "total_error": 1.0,
                "mean_error": 1.0,
                "variance_error": 1.0,
                "skewness_error": 1.0,
                "kurtosis_error": 1.0
            }
        }
        
        # Obtenir les facteurs pour le contexte
        if context in context_factors:
            factors = context_factors[context]
        else:
            factors = context_factors["default"]
        
        # Appliquer les facteurs aux seuils
        thresholds = {}
        for metric in ["total_error", "mean_error", "variance_error", "skewness_error", "kurtosis_error"]:
            thresholds[metric] = level_config[metric] * factors[metric]
        
        return thresholds
    
    def get_confidence_interval(self, precision_level: str) -> float:
        """
        Obtient l'intervalle de confiance pour un niveau de précision donné.
        
        Args:
            precision_level: Niveau de précision
            
        Returns:
            confidence_interval: Intervalle de confiance
        """
        level_config = self.get_precision_level(precision_level)
        return level_config["confidence_interval"]
    
    def get_sample_size_recommendation(self, precision_level: str, distribution_type: str = "normal") -> int:
        """
        Recommande une taille d'échantillon minimale pour un niveau de précision donné.
        
        Args:
            precision_level: Niveau de précision
            distribution_type: Type de distribution
            
        Returns:
            sample_size: Taille d'échantillon recommandée
        """
        # Obtenir l'intervalle de confiance
        confidence = self.get_confidence_interval(precision_level)
        
        # Définir les tailles d'échantillon de base par type de distribution
        base_sizes = {
            "normal": 30,
            "asymmetric": 50,
            "multimodal": 100,
            "leptokurtic": 80,
            "default": 50
        }
        
        # Obtenir la taille de base
        if distribution_type in base_sizes:
            base_size = base_sizes[distribution_type]
        else:
            base_size = base_sizes["default"]
        
        # Calculer la taille d'échantillon recommandée
        # Plus l'intervalle de confiance est élevé, plus la taille d'échantillon doit être grande
        confidence_factor = 1.0 / (1.0 - confidence)
        sample_size = int(base_size * confidence_factor)
        
        return sample_size
    
    def get_bin_count_recommendation(self, precision_level: str, sample_size: int) -> int:
        """
        Recommande un nombre de bins pour un niveau de précision et une taille d'échantillon donnés.
        
        Args:
            precision_level: Niveau de précision
            sample_size: Taille de l'échantillon
            
        Returns:
            bin_count: Nombre de bins recommandé
        """
        # Obtenir la configuration du niveau de précision
        level_config = self.get_precision_level(precision_level)
        
        # Définir les facteurs de bins par niveau de précision
        bin_factors = {
            "high": 1.5,
            "medium": 1.0,
            "low": 0.7,
            "minimal": 0.5
        }
        
        # Obtenir le facteur pour le niveau de précision
        if precision_level in bin_factors:
            factor = bin_factors[precision_level]
        else:
            factor = bin_factors["medium"]
        
        # Calculer le nombre de bins recommandé
        # Utiliser la règle de Sturges comme base: k = 1 + log2(n)
        bin_count = int(factor * (1 + np.log2(sample_size)))
        
        # Limiter le nombre de bins
        bin_count = max(5, min(100, bin_count))
        
        return bin_count


def generate_default_config(output_path: str) -> bool:
    """
    Génère un fichier de configuration par défaut pour les niveaux de précision.
    
    Args:
        output_path: Chemin du fichier de sortie
        
    Returns:
        success: Booléen indiquant si la génération a réussi
    """
    # Créer une instance avec les niveaux par défaut
    precision_levels = PrecisionLevelThresholds()
    
    # Obtenir tous les niveaux de précision
    levels = precision_levels.get_all_precision_levels()
    
    try:
        # Créer le répertoire parent s'il n'existe pas
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Sauvegarder les niveaux
        with open(output_path, 'w') as f:
            json.dump(levels, f, indent=4)
        
        return True
    except (IOError, OSError) as e:
        print(f"Erreur lors de la génération du fichier de configuration: {e}")
        return False


if __name__ == "__main__":
    # Exemple d'utilisation
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--generate-config":
        # Générer un fichier de configuration par défaut
        output_path = sys.argv[2] if len(sys.argv) > 2 else "config/precision_levels.json"
        if generate_default_config(output_path):
            print(f"Fichier de configuration généré avec succès: {output_path}")
        else:
            print("Échec de la génération du fichier de configuration")
    else:
        # Créer une instance avec les niveaux par défaut
        precision_levels = PrecisionLevelThresholds()
        
        # Afficher les niveaux de précision disponibles
        print("Niveaux de précision disponibles:")
        for level_name, level_config in precision_levels.get_all_precision_levels().items():
            print(f"\n{level_name}:")
            print(f"  Description: {level_config['description']}")
            print(f"  Intervalle de confiance: {level_config['confidence_interval']}")
            print("  Seuils:")
            for metric in ["total_error", "mean_error", "variance_error", "skewness_error", "kurtosis_error"]:
                print(f"    {metric}: {level_config[metric]}")
        
        # Exemple de recommandation de taille d'échantillon
        print("\nRecommandations de taille d'échantillon:")
        for level in ["high", "medium", "low", "minimal"]:
            for dist_type in ["normal", "asymmetric", "multimodal", "leptokurtic"]:
                sample_size = precision_levels.get_sample_size_recommendation(level, dist_type)
                print(f"  {level} - {dist_type}: {sample_size} échantillons")
        
        # Exemple de recommandation de nombre de bins
        print("\nRecommandations de nombre de bins:")
        for level in ["high", "medium", "low", "minimal"]:
            for sample_size in [100, 500, 1000, 5000]:
                bin_count = precision_levels.get_bin_count_recommendation(level, sample_size)
                print(f"  {level} - {sample_size} échantillons: {bin_count} bins")
        
        # Exemple de seuils ajustés par contexte
        print("\nSeuils ajustés par contexte pour le niveau 'medium':")
        for context in ["monitoring", "stability", "anomaly_detection", "characterization", "default"]:
            thresholds = precision_levels.get_thresholds_for_context("medium", context)
            print(f"\n  Contexte: {context}")
            for metric, value in thresholds.items():
                print(f"    {metric}: {value:.2f}")
