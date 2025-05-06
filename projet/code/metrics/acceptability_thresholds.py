#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour établir des seuils d'acceptabilité pour les métriques composites.
"""

import json
import os
from typing import Dict, Tuple, Union, Optional, cast

# Importer le module de gestion des seuils par type de distribution
try:
    from distribution_thresholds import DistributionThresholds
    DISTRIBUTION_THRESHOLDS_AVAILABLE = True
except ImportError:
    DISTRIBUTION_THRESHOLDS_AVAILABLE = False


class AcceptabilityThresholds:
    """
    Classe pour gérer les seuils d'acceptabilité des métriques composites.
    """

    def __init__(self, config_path: Optional[str] = None, dist_config_path: Optional[str] = None):
        """
        Initialise les seuils d'acceptabilité.

        Args:
            config_path: Chemin vers le fichier de configuration des seuils
            dist_config_path: Chemin vers le fichier de configuration des seuils par type de distribution
        """
        # Seuils par défaut pour différents contextes
        self.default_thresholds = {
            "monitoring": {
                "total_error": 15.0,
                "mean_error": 5.0,
                "variance_error": 10.0,
                "skewness_error": 20.0,
                "kurtosis_error": 25.0
            },
            "stability": {
                "total_error": 12.0,
                "mean_error": 8.0,
                "variance_error": 5.0,
                "skewness_error": 15.0,
                "kurtosis_error": 20.0
            },
            "anomaly_detection": {
                "total_error": 10.0,
                "mean_error": 10.0,
                "variance_error": 10.0,
                "skewness_error": 5.0,
                "kurtosis_error": 10.0
            },
            "characterization": {
                "total_error": 8.0,
                "mean_error": 5.0,
                "variance_error": 5.0,
                "skewness_error": 5.0,
                "kurtosis_error": 5.0
            },
            "default": {
                "total_error": 10.0,
                "mean_error": 7.0,
                "variance_error": 7.0,
                "skewness_error": 10.0,
                "kurtosis_error": 15.0
            }
        }

        # Charger les seuils personnalisés si un fichier de configuration est fourni
        self.custom_thresholds = {}
        if config_path and os.path.exists(config_path):
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    self.custom_thresholds = json.load(f)
            except (json.JSONDecodeError, IOError) as e:
                print(f"Erreur lors du chargement du fichier de configuration: {e}")

        # Initialiser le gestionnaire de seuils par type de distribution
        self.dist_thresholds = None
        if DISTRIBUTION_THRESHOLDS_AVAILABLE:
            self.dist_thresholds = DistributionThresholds(dist_config_path)

    def get_thresholds(self, context: str = "default", distribution_type: Optional[str] = None) -> Dict[str, float]:
        """
        Obtient les seuils d'acceptabilité pour un contexte donné.

        Args:
            context: Contexte d'analyse (monitoring, stability, etc.)
            distribution_type: Type de distribution (normal, asymmetric, etc.)

        Returns:
            thresholds: Dictionnaire des seuils d'acceptabilité
        """
        # Utiliser les seuils par type de distribution si disponibles
        if self.dist_thresholds is not None and distribution_type is not None:
            try:
                # Obtenir les seuils depuis le module de gestion des seuils par type de distribution
                return self.dist_thresholds.get_thresholds(distribution_type, context)
            except Exception as e:
                print(f"Erreur lors de la récupération des seuils par type de distribution: {e}")
                print("Utilisation des seuils par défaut.")

        # Méthode traditionnelle si les seuils par type de distribution ne sont pas disponibles
        # Obtenir les seuils de base pour le contexte
        if context in self.default_thresholds:
            base_thresholds = self.default_thresholds[context].copy()
        else:
            base_thresholds = self.default_thresholds["default"].copy()

        # Ajuster les seuils en fonction du type de distribution
        if distribution_type:
            adjusted_thresholds = self._adjust_for_distribution(base_thresholds, distribution_type)
        else:
            adjusted_thresholds = base_thresholds

        # Appliquer les seuils personnalisés si disponibles
        if context in self.custom_thresholds:
            for key, value in self.custom_thresholds[context].items():
                adjusted_thresholds[key] = value

        return adjusted_thresholds

    def _adjust_for_distribution(self, thresholds: Dict[str, float], distribution_type: str) -> Dict[str, float]:
        """
        Ajuste les seuils en fonction du type de distribution.

        Args:
            thresholds: Seuils de base
            distribution_type: Type de distribution

        Returns:
            adjusted_thresholds: Seuils ajustés
        """
        adjusted_thresholds = thresholds.copy()

        if distribution_type == "normal" or distribution_type == "quasiNormal":
            # Pour les distributions normales, les moments supérieurs sont moins importants
            adjusted_thresholds["skewness_error"] *= 1.5
            adjusted_thresholds["kurtosis_error"] *= 1.5

        elif distribution_type == "asymmetric" or distribution_type == "moderatelyAsymmetric":
            # Pour les distributions asymétriques, l'asymétrie est critique
            adjusted_thresholds["skewness_error"] *= 0.8

        elif distribution_type == "highlyAsymmetric":
            # Pour les distributions fortement asymétriques, l'asymétrie est très critique
            adjusted_thresholds["skewness_error"] *= 0.6
            adjusted_thresholds["mean_error"] *= 1.2

        elif distribution_type == "multimodal":
            # Pour les distributions multimodales, la variance est critique
            adjusted_thresholds["variance_error"] *= 0.7

        elif distribution_type == "leptokurtic":
            # Pour les distributions leptokurtiques, l'aplatissement est critique
            adjusted_thresholds["kurtosis_error"] *= 0.7

        return adjusted_thresholds

    def evaluate_acceptability(self, errors: Dict[str, Union[float, Dict[str, Dict[str, float]]]], context: str = "default",
                              distribution_type: Optional[str] = None) -> Tuple[bool, Dict[str, bool]]:
        """
        Évalue si les erreurs sont acceptables selon les seuils définis.

        Args:
            errors: Dictionnaire des erreurs (total_error et composantes)
            context: Contexte d'analyse
            distribution_type: Type de distribution

        Returns:
            acceptable: Booléen indiquant si les erreurs sont globalement acceptables
            component_results: Dictionnaire indiquant l'acceptabilité de chaque composante
        """
        # Obtenir les seuils pour le contexte et le type de distribution
        thresholds = self.get_thresholds(context, distribution_type)

        # Extraire les erreurs
        total_error = cast(float, errors.get("total_error", 0.0))
        components = cast(Dict[str, Dict[str, float]], errors.get("components", {}))

        # Évaluer l'acceptabilité de chaque composante
        component_results = {}

        # Vérifier l'erreur totale
        component_results["total_error"] = total_error <= thresholds["total_error"]

        # Vérifier les erreurs par composante
        for component, threshold_key in [
            ("mean", "mean_error"),
            ("variance", "variance_error"),
            ("skewness", "skewness_error"),
            ("kurtosis", "kurtosis_error")
        ]:
            if component in components:
                error_value = components[component].get("raw_error", 0.0)
                component_results[component] = error_value <= thresholds[threshold_key]

        # Déterminer l'acceptabilité globale
        # Une métrique est acceptable si l'erreur totale est acceptable ET
        # si au moins 3 des 4 composantes sont acceptables
        acceptable_components = sum(1 for k, v in component_results.items() if k != "total_error" and v)
        acceptable = component_results["total_error"] and acceptable_components >= 3

        return acceptable, component_results

    def save_custom_thresholds(self, thresholds: Dict[str, Dict[str, float]], config_path: str) -> bool:
        """
        Sauvegarde des seuils personnalisés dans un fichier de configuration.

        Args:
            thresholds: Dictionnaire des seuils personnalisés
            config_path: Chemin du fichier de configuration

        Returns:
            success: Booléen indiquant si la sauvegarde a réussi
        """
        try:
            # Créer le répertoire parent s'il n'existe pas
            os.makedirs(os.path.dirname(config_path), exist_ok=True)

            # Sauvegarder les seuils
            with open(config_path, 'w') as f:
                json.dump(thresholds, f, indent=4)

            # Mettre à jour les seuils personnalisés
            self.custom_thresholds = thresholds

            return True
        except (IOError, OSError) as e:
            print(f"Erreur lors de la sauvegarde des seuils personnalisés: {e}")
            return False

    def get_acceptability_level(self, error_value: float, threshold: float) -> str:
        """
        Détermine le niveau d'acceptabilité d'une erreur.

        Args:
            error_value: Valeur de l'erreur
            threshold: Seuil d'acceptabilité

        Returns:
            level: Niveau d'acceptabilité (excellent, good, acceptable, poor, unacceptable)
        """
        ratio = error_value / threshold if threshold > 0 else float('inf')

        if ratio <= 0.5:
            return "excellent"
        elif ratio <= 0.8:
            return "good"
        elif ratio <= 1.0:
            return "acceptable"
        elif ratio <= 1.5:
            return "poor"
        else:
            return "unacceptable"

    def get_detailed_evaluation(self, errors: Dict[str, Union[float, Dict[str, Dict[str, float]]]], context: str = "default",
                               distribution_type: Optional[str] = None) -> Dict[str, Dict[str, Union[float, str, bool, int]]]:
        """
        Fournit une évaluation détaillée des erreurs par rapport aux seuils.

        Args:
            errors: Dictionnaire des erreurs (total_error et composantes)
            context: Contexte d'analyse
            distribution_type: Type de distribution

        Returns:
            evaluation: Dictionnaire contenant l'évaluation détaillée
        """
        # Obtenir les seuils pour le contexte et le type de distribution
        thresholds = self.get_thresholds(context, distribution_type)

        # Extraire les erreurs
        total_error = cast(float, errors.get("total_error", 0.0))
        components = cast(Dict[str, Dict[str, float]], errors.get("components", {}))

        # Préparer l'évaluation détaillée
        evaluation: Dict[str, Dict[str, Union[float, str, bool, int]]] = {
            "total_error": {
                "value": total_error,
                "threshold": thresholds["total_error"],
                "acceptable": total_error <= thresholds["total_error"],
                "level": self.get_acceptability_level(total_error, thresholds["total_error"])
            }
        }

        # Évaluer chaque composante
        for component, threshold_key in [
            ("mean", "mean_error"),
            ("variance", "variance_error"),
            ("skewness", "skewness_error"),
            ("kurtosis", "kurtosis_error")
        ]:
            if component in components:
                error_value = components[component].get("raw_error", 0.0)
                threshold = thresholds[threshold_key]

                evaluation[component] = {
                    "value": error_value,
                    "threshold": threshold,
                    "acceptable": error_value <= threshold,
                    "level": self.get_acceptability_level(error_value, threshold)
                }

        # Déterminer l'acceptabilité globale
        acceptable_components = sum(1 for k, v in evaluation.items() if k != "total_error" and k != "overall" and v.get("acceptable", False))
        evaluation["overall"] = {
            "acceptable": evaluation["total_error"]["acceptable"] and acceptable_components >= 3,
            "acceptable_components": acceptable_components,
            "total_components": len(evaluation) - 2  # -2 pour exclure total_error et overall
        }

        return evaluation


def generate_default_config(output_path: str) -> bool:
    """
    Génère un fichier de configuration par défaut pour les seuils d'acceptabilité.

    Args:
        output_path: Chemin du fichier de sortie

    Returns:
        success: Booléen indiquant si la génération a réussi
    """
    thresholds = AcceptabilityThresholds().default_thresholds

    try:
        # Créer le répertoire parent s'il n'existe pas
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # Sauvegarder les seuils
        with open(output_path, 'w') as f:
            json.dump(thresholds, f, indent=4)

        return True
    except (IOError, OSError) as e:
        print(f"Erreur lors de la génération du fichier de configuration: {e}")
        return False


if __name__ == "__main__":
    # Exemple d'utilisation
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--generate-config":
        # Générer un fichier de configuration par défaut
        output_path = sys.argv[2] if len(sys.argv) > 2 else "config/acceptability_thresholds.json"
        if generate_default_config(output_path):
            print(f"Fichier de configuration généré avec succès: {output_path}")
        else:
            print("Échec de la génération du fichier de configuration")
    else:
        # Créer une instance avec les seuils par défaut
        thresholds = AcceptabilityThresholds()

        # Afficher les seuils pour différents contextes
        for context in ["monitoring", "stability", "anomaly_detection", "characterization", "default"]:
            print(f"\nSeuils pour le contexte '{context}':")
            for metric, value in thresholds.get_thresholds(context).items():
                print(f"  {metric}: {value}")

        # Exemple d'évaluation d'acceptabilité
        errors = {
            "total_error": 8.5,
            "components": {
                "mean": {"raw_error": 3.2},
                "variance": {"raw_error": 6.8},
                "skewness": {"raw_error": 12.5},
                "kurtosis": {"raw_error": 9.7}
            }
        }

        print("\nÉvaluation d'acceptabilité pour le contexte 'monitoring':")
        acceptable, results = thresholds.evaluate_acceptability(errors, "monitoring")
        print(f"Acceptable: {acceptable}")
        for component, result in results.items():
            print(f"  {component}: {'Acceptable' if result else 'Non acceptable'}")

        # Exemple d'évaluation détaillée
        print("\nÉvaluation détaillée pour le contexte 'monitoring':")
        evaluation = thresholds.get_detailed_evaluation(errors, "monitoring")
        for component, details in evaluation.items():
            if component != "overall":
                print(f"  {component}: {details['value']:.2f}/{details['threshold']:.2f} - {details['level']}")
        print(f"  Globalement: {'Acceptable' if evaluation['overall']['acceptable'] else 'Non acceptable'} "
              f"({evaluation['overall']['acceptable_components']}/{evaluation['overall']['total_components']} composantes acceptables)")
