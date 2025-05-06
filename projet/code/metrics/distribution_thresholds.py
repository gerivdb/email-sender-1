#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module de gestion des seuils adaptés par type de distribution.

Ce module permet de charger et d'utiliser les seuils définis pour différents types
de distributions statistiques. Il fournit des fonctions pour obtenir les seuils
appropriés en fonction du type de distribution et du contexte d'analyse.
"""

import os
import json
from typing import Dict, Optional, Union, List, Tuple, Any

# Chemin par défaut vers le fichier de configuration des seuils
DEFAULT_CONFIG_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
                                  "config", "distribution_thresholds.json")


class DistributionThresholds:
    """
    Classe pour gérer les seuils adaptés par type de distribution.
    """

    def __init__(self, config_path: Optional[str] = None):
        """
        Initialise la classe avec les seuils par défaut ou personnalisés.

        Args:
            config_path: Chemin vers le fichier de configuration des seuils
        """
        self.config_path = config_path or DEFAULT_CONFIG_PATH
        self.thresholds = self._load_thresholds()

    def _load_thresholds(self) -> Dict[str, Any]:
        """
        Charge les seuils depuis le fichier de configuration.

        Returns:
            thresholds: Dictionnaire des seuils par type de distribution
        """
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError) as e:
            print(f"Erreur lors du chargement du fichier de configuration: {e}")
            # Retourner une structure vide en cas d'erreur
            return {"distribution_types": {}, "contexts": {}}

    def get_distribution_types(self) -> List[str]:
        """
        Obtient la liste des types de distribution disponibles.

        Returns:
            types: Liste des types de distribution
        """
        return list(self.thresholds.get("distribution_types", {}).keys())

    def get_contexts(self) -> List[str]:
        """
        Obtient la liste des contextes disponibles.

        Returns:
            contexts: Liste des contextes
        """
        return list(self.thresholds.get("contexts", {}).keys())

    def get_use_cases(self) -> List[str]:
        """
        Obtient la liste des cas d'utilisation disponibles.

        Returns:
            use_cases: Liste des cas d'utilisation
        """
        return list(self.thresholds.get("use_cases", {}).keys())

    def get_thresholds(self, distribution_type: str, context: str = "default", use_case: Optional[str] = None) -> Dict[str, float]:
        """
        Obtient les seuils pour un type de distribution, un contexte et un cas d'utilisation donnés.

        Args:
            distribution_type: Type de distribution
            context: Contexte d'analyse
            use_case: Cas d'utilisation (optionnel)

        Returns:
            thresholds: Dictionnaire des seuils
        """
        # Si un cas d'utilisation est spécifié, essayer d'obtenir les seuils spécifiques à ce cas d'utilisation
        if use_case is not None:
            use_case_thresholds = self.get_use_case_thresholds(distribution_type, use_case)
            if use_case_thresholds:
                return use_case_thresholds

        # Sinon, utiliser les seuils par défaut avec le contexte spécifié
        # Vérifier si le type de distribution existe
        dist_types = self.thresholds.get("distribution_types", {})
        if distribution_type not in dist_types:
            print(f"Type de distribution '{distribution_type}' non trouvé. Utilisation du type 'normal'.")
            distribution_type = "normal"
            # Si normal n'existe pas non plus, retourner un dictionnaire vide
            if distribution_type not in dist_types:
                return {}

        # Vérifier si le contexte existe
        contexts = self.thresholds.get("contexts", {})
        if context not in contexts:
            print(f"Contexte '{context}' non trouvé. Utilisation du contexte 'default'.")
            context = "default"
            # Si default n'existe pas non plus, retourner les seuils sans ajustement
            if context not in contexts:
                return dist_types[distribution_type].get("thresholds", {})

        # Obtenir les seuils de base pour le type de distribution
        base_thresholds = dist_types[distribution_type].get("thresholds", {})

        # Obtenir les facteurs pour le contexte
        context_factors = contexts[context].get("factors", {})

        # Appliquer les facteurs aux seuils
        adjusted_thresholds = {}
        for metric, value in base_thresholds.items():
            factor = context_factors.get(metric, 1.0)
            adjusted_thresholds[metric] = value * factor

        return adjusted_thresholds

    def get_use_case_thresholds(self, distribution_type: str, use_case: str) -> Dict[str, float]:
        """
        Obtient les seuils spécifiques à un cas d'utilisation pour un type de distribution donné.

        Args:
            distribution_type: Type de distribution
            use_case: Cas d'utilisation

        Returns:
            thresholds: Dictionnaire des seuils spécifiques au cas d'utilisation
        """
        # Vérifier si le cas d'utilisation existe
        use_cases = self.thresholds.get("use_cases", {})
        if use_case not in use_cases:
            print(f"Cas d'utilisation '{use_case}' non trouvé. Utilisation des seuils par défaut.")
            return {}

        # Vérifier si le type de distribution est défini pour ce cas d'utilisation
        use_case_thresholds = use_cases[use_case].get("thresholds", {})
        if distribution_type not in use_case_thresholds:
            print(f"Type de distribution '{distribution_type}' non défini pour le cas d'utilisation '{use_case}'. Utilisation des seuils par défaut.")
            return {}

        # Retourner les seuils spécifiques au cas d'utilisation pour ce type de distribution
        return use_case_thresholds[distribution_type]

    def get_gmci_thresholds(self, distribution_type: str, use_case: Optional[str] = None) -> Dict[str, float]:
        """
        Obtient les seuils GMCI (Global Moment Conservation Index) pour un type de distribution et un cas d'utilisation.

        Args:
            distribution_type: Type de distribution
            use_case: Cas d'utilisation (optionnel)

        Returns:
            thresholds: Dictionnaire des seuils GMCI
        """
        # Si un cas d'utilisation est spécifié, essayer d'obtenir les seuils GMCI spécifiques à ce cas d'utilisation
        if use_case is not None:
            use_case_gmci_thresholds = self.get_use_case_gmci_thresholds(distribution_type, use_case)
            if use_case_gmci_thresholds:
                return use_case_gmci_thresholds

        # Sinon, utiliser les seuils GMCI par défaut
        # Vérifier si le type de distribution existe
        dist_types = self.thresholds.get("distribution_types", {})
        if distribution_type not in dist_types:
            print(f"Type de distribution '{distribution_type}' non trouvé. Utilisation du type 'normal'.")
            distribution_type = "normal"
            # Si normal n'existe pas non plus, retourner un dictionnaire vide
            if distribution_type not in dist_types:
                return {}

        return dist_types[distribution_type].get("gmci_thresholds", {})

    def get_use_case_gmci_thresholds(self, distribution_type: str, use_case: str) -> Dict[str, float]:
        """
        Obtient les seuils GMCI spécifiques à un cas d'utilisation pour un type de distribution donné.

        Args:
            distribution_type: Type de distribution
            use_case: Cas d'utilisation

        Returns:
            thresholds: Dictionnaire des seuils GMCI spécifiques au cas d'utilisation
        """
        # Vérifier si le cas d'utilisation existe
        use_cases = self.thresholds.get("use_cases", {})
        if use_case not in use_cases:
            print(f"Cas d'utilisation '{use_case}' non trouvé. Utilisation des seuils GMCI par défaut.")
            return {}

        # Vérifier si les seuils GMCI sont définis pour ce cas d'utilisation
        use_case_gmci_thresholds = use_cases[use_case].get("gmci_thresholds", {})
        if distribution_type not in use_case_gmci_thresholds:
            print(f"Type de distribution '{distribution_type}' non défini pour les seuils GMCI du cas d'utilisation '{use_case}'. Utilisation des seuils GMCI par défaut.")
            return {}

        # Retourner les seuils GMCI spécifiques au cas d'utilisation pour ce type de distribution
        return use_case_gmci_thresholds[distribution_type]

    def get_sample_size(self, distribution_type: str) -> int:
        """
        Obtient la taille d'échantillon recommandée pour un type de distribution.

        Args:
            distribution_type: Type de distribution

        Returns:
            sample_size: Taille d'échantillon recommandée
        """
        # Vérifier si le type de distribution existe
        dist_types = self.thresholds.get("distribution_types", {})
        if distribution_type not in dist_types:
            print(f"Type de distribution '{distribution_type}' non trouvé. Utilisation du type 'normal'.")
            distribution_type = "normal"
            # Si normal n'existe pas non plus, retourner une valeur par défaut
            if distribution_type not in dist_types:
                return 30

        return dist_types[distribution_type].get("sample_size", 30)

    def get_detection_criteria(self, distribution_type: str) -> Dict[str, Any]:
        """
        Obtient les critères de détection pour un type de distribution.

        Args:
            distribution_type: Type de distribution

        Returns:
            criteria: Dictionnaire des critères de détection
        """
        # Vérifier si le type de distribution existe
        dist_types = self.thresholds.get("distribution_types", {})
        if distribution_type not in dist_types:
            print(f"Type de distribution '{distribution_type}' non trouvé. Utilisation du type 'normal'.")
            distribution_type = "normal"
            # Si normal n'existe pas non plus, retourner un dictionnaire vide
            if distribution_type not in dist_types:
                return {}

        return dist_types[distribution_type].get("detection_criteria", {})

    def get_distribution_description(self, distribution_type: str) -> str:
        """
        Obtient la description d'un type de distribution.

        Args:
            distribution_type: Type de distribution

        Returns:
            description: Description du type de distribution
        """
        # Vérifier si le type de distribution existe
        dist_types = self.thresholds.get("distribution_types", {})
        if distribution_type not in dist_types:
            return f"Type de distribution '{distribution_type}' non trouvé."

        return dist_types[distribution_type].get("description", "")

    def get_context_description(self, context: str) -> str:
        """
        Obtient la description d'un contexte.

        Args:
            context: Contexte

        Returns:
            description: Description du contexte
        """
        # Vérifier si le contexte existe
        contexts = self.thresholds.get("contexts", {})
        if context not in contexts:
            return f"Contexte '{context}' non trouvé."

        return contexts[context].get("description", "")

    def get_use_case_description(self, use_case: str) -> str:
        """
        Obtient la description d'un cas d'utilisation.

        Args:
            use_case: Cas d'utilisation

        Returns:
            description: Description du cas d'utilisation
        """
        # Vérifier si le cas d'utilisation existe
        use_cases = self.thresholds.get("use_cases", {})
        if use_case not in use_cases:
            return f"Cas d'utilisation '{use_case}' non trouvé."

        return use_cases[use_case].get("description", "")

    def save_thresholds(self, thresholds: Dict[str, Any]) -> bool:
        """
        Sauvegarde les seuils dans le fichier de configuration.

        Args:
            thresholds: Dictionnaire des seuils

        Returns:
            success: Booléen indiquant si la sauvegarde a réussi
        """
        try:
            with open(self.config_path, 'w', encoding='utf-8') as f:
                json.dump(thresholds, f, indent=2, ensure_ascii=False)
            self.thresholds = thresholds
            return True
        except (IOError, OSError) as e:
            print(f"Erreur lors de la sauvegarde des seuils: {e}")
            return False

    def update_distribution_type(self, distribution_type: str, config: Dict[str, Any]) -> bool:
        """
        Met à jour la configuration d'un type de distribution.

        Args:
            distribution_type: Type de distribution
            config: Configuration du type de distribution

        Returns:
            success: Booléen indiquant si la mise à jour a réussi
        """
        thresholds = self.thresholds.copy()
        thresholds.get("distribution_types", {})[distribution_type] = config
        return self.save_thresholds(thresholds)

    def update_context(self, context: str, config: Dict[str, Any]) -> bool:
        """
        Met à jour la configuration d'un contexte.

        Args:
            context: Contexte
            config: Configuration du contexte

        Returns:
            success: Booléen indiquant si la mise à jour a réussi
        """
        thresholds = self.thresholds.copy()
        thresholds.get("contexts", {})[context] = config
        return self.save_thresholds(thresholds)

    def update_use_case(self, use_case: str, config: Dict[str, Any]) -> bool:
        """
        Met à jour la configuration d'un cas d'utilisation.

        Args:
            use_case: Cas d'utilisation
            config: Configuration du cas d'utilisation

        Returns:
            success: Booléen indiquant si la mise à jour a réussi
        """
        thresholds = self.thresholds.copy()
        thresholds.get("use_cases", {})[use_case] = config
        return self.save_thresholds(thresholds)


def generate_default_config(output_path: str = DEFAULT_CONFIG_PATH) -> bool:
    """
    Génère un fichier de configuration par défaut pour les seuils par type de distribution.

    Args:
        output_path: Chemin du fichier de sortie

    Returns:
        success: Booléen indiquant si la génération a réussi
    """
    # Configuration par défaut
    default_config = {
        "distribution_types": {
            "quasiNormal": {
                "description": "Distribution quasi-normale avec asymétrie et aplatissement proches de la normale",
                "thresholds": {
                    "total_error": 10.0,
                    "mean_error": 7.0,
                    "variance_error": 7.0,
                    "skewness_error": 15.0,
                    "kurtosis_error": 20.0
                },
                "gmci_thresholds": {
                    "excellent": 0.88,
                    "veryGood": 0.78,
                    "good": 0.68,
                    "acceptable": 0.58,
                    "limited": 0.48
                },
                "sample_size": 30,
                "detection_criteria": {
                    "skewness_range": [-0.5, 0.5],
                    "kurtosis_range": [2.5, 3.5]
                }
            },
            "normal": {
                "description": "Distribution normale standard",
                "thresholds": {
                    "total_error": 10.0,
                    "mean_error": 7.0,
                    "variance_error": 7.0,
                    "skewness_error": 15.0,
                    "kurtosis_error": 20.0
                },
                "gmci_thresholds": {
                    "excellent": 0.88,
                    "veryGood": 0.78,
                    "good": 0.68,
                    "acceptable": 0.58,
                    "limited": 0.48
                },
                "sample_size": 30,
                "detection_criteria": {
                    "skewness_range": [-0.5, 0.5],
                    "kurtosis_range": [2.5, 3.5]
                }
            },
            "moderatelyAsymmetric": {
                "description": "Distribution avec asymétrie modérée",
                "thresholds": {
                    "total_error": 12.0,
                    "mean_error": 8.0,
                    "variance_error": 8.0,
                    "skewness_error": 10.0,
                    "kurtosis_error": 15.0
                },
                "gmci_thresholds": {
                    "excellent": 0.90,
                    "veryGood": 0.80,
                    "good": 0.70,
                    "acceptable": 0.60,
                    "limited": 0.50
                },
                "sample_size": 50,
                "detection_criteria": {
                    "skewness_range": [0.5, 1.5],
                    "kurtosis_range": [2.0, 5.0]
                }
            },
            "highlyAsymmetric": {
                "description": "Distribution fortement asymétrique",
                "thresholds": {
                    "total_error": 15.0,
                    "mean_error": 10.0,
                    "variance_error": 10.0,
                    "skewness_error": 8.0,
                    "kurtosis_error": 12.0
                },
                "gmci_thresholds": {
                    "excellent": 0.92,
                    "veryGood": 0.82,
                    "good": 0.72,
                    "acceptable": 0.62,
                    "limited": 0.52
                },
                "sample_size": 80,
                "detection_criteria": {
                    "skewness_range": [1.5, None],
                    "kurtosis_range": [None, None]
                }
            },
            "multimodal": {
                "description": "Distribution avec plusieurs modes",
                "thresholds": {
                    "total_error": 15.0,
                    "mean_error": 10.0,
                    "variance_error": 7.0,
                    "skewness_error": 12.0,
                    "kurtosis_error": 15.0
                },
                "gmci_thresholds": {
                    "excellent": 0.90,
                    "veryGood": 0.80,
                    "good": 0.70,
                    "acceptable": 0.60,
                    "limited": 0.50
                },
                "sample_size": 100,
                "detection_criteria": {
                    "multimodal": True
                }
            },
            "leptokurtic": {
                "description": "Distribution avec aplatissement élevé (queues lourdes)",
                "thresholds": {
                    "total_error": 15.0,
                    "mean_error": 8.0,
                    "variance_error": 10.0,
                    "skewness_error": 12.0,
                    "kurtosis_error": 10.0
                },
                "gmci_thresholds": {
                    "excellent": 0.90,
                    "veryGood": 0.80,
                    "good": 0.70,
                    "acceptable": 0.60,
                    "limited": 0.50
                },
                "sample_size": 80,
                "detection_criteria": {
                    "kurtosis_range": [5.0, None]
                }
            },
            "asymmetric": {
                "description": "Distribution asymétrique (générique)",
                "thresholds": {
                    "total_error": 12.0,
                    "mean_error": 8.0,
                    "variance_error": 8.0,
                    "skewness_error": 10.0,
                    "kurtosis_error": 15.0
                },
                "gmci_thresholds": {
                    "excellent": 0.90,
                    "veryGood": 0.80,
                    "good": 0.70,
                    "acceptable": 0.60,
                    "limited": 0.50
                },
                "sample_size": 50,
                "detection_criteria": {
                    "skewness_range": [0.5, None]
                }
            }
        },
        "contexts": {
            "monitoring": {
                "description": "Surveillance continue des systèmes",
                "factors": {
                    "total_error": 1.5,
                    "mean_error": 0.7,
                    "variance_error": 1.0,
                    "skewness_error": 2.0,
                    "kurtosis_error": 2.5
                }
            },
            "stability": {
                "description": "Analyse de stabilité des systèmes",
                "factors": {
                    "total_error": 1.2,
                    "mean_error": 1.1,
                    "variance_error": 0.7,
                    "skewness_error": 1.5,
                    "kurtosis_error": 2.0
                }
            },
            "anomaly_detection": {
                "description": "Détection d'anomalies",
                "factors": {
                    "total_error": 1.0,
                    "mean_error": 1.4,
                    "variance_error": 1.4,
                    "skewness_error": 0.5,
                    "kurtosis_error": 1.0
                }
            },
            "characterization": {
                "description": "Caractérisation précise des distributions",
                "factors": {
                    "total_error": 0.8,
                    "mean_error": 0.7,
                    "variance_error": 0.7,
                    "skewness_error": 0.5,
                    "kurtosis_error": 0.5
                }
            },
            "default": {
                "description": "Contexte par défaut",
                "factors": {
                    "total_error": 1.0,
                    "mean_error": 1.0,
                    "variance_error": 1.0,
                    "skewness_error": 1.0,
                    "kurtosis_error": 1.0
                }
            }
        },
        "use_cases": {
            "latency_analysis": {
                "description": "Analyse de latence des systèmes",
                "thresholds": {
                    "normal": {
                        "total_error": 8.0,
                        "mean_error": 5.0,
                        "variance_error": 8.0,
                        "skewness_error": 12.0,
                        "kurtosis_error": 15.0
                    },
                    "multimodal": {
                        "total_error": 12.0,
                        "mean_error": 8.0,
                        "variance_error": 6.0,
                        "skewness_error": 10.0,
                        "kurtosis_error": 12.0
                    },
                    "leptokurtic": {
                        "total_error": 12.0,
                        "mean_error": 6.0,
                        "variance_error": 8.0,
                        "skewness_error": 10.0,
                        "kurtosis_error": 8.0
                    }
                },
                "gmci_thresholds": {
                    "normal": {
                        "excellent": 0.92,
                        "veryGood": 0.85,
                        "good": 0.75,
                        "acceptable": 0.65,
                        "limited": 0.55
                    },
                    "multimodal": {
                        "excellent": 0.95,
                        "veryGood": 0.85,
                        "good": 0.75,
                        "acceptable": 0.65,
                        "limited": 0.55
                    },
                    "leptokurtic": {
                        "excellent": 0.92,
                        "veryGood": 0.82,
                        "good": 0.72,
                        "acceptable": 0.62,
                        "limited": 0.52
                    }
                }
            },
            "throughput_analysis": {
                "description": "Analyse de débit des systèmes",
                "thresholds": {
                    "normal": {
                        "total_error": 10.0,
                        "mean_error": 6.0,
                        "variance_error": 8.0,
                        "skewness_error": 15.0,
                        "kurtosis_error": 20.0
                    },
                    "asymmetric": {
                        "total_error": 12.0,
                        "mean_error": 7.0,
                        "variance_error": 7.0,
                        "skewness_error": 8.0,
                        "kurtosis_error": 12.0
                    },
                    "highlyAsymmetric": {
                        "total_error": 15.0,
                        "mean_error": 8.0,
                        "variance_error": 8.0,
                        "skewness_error": 6.0,
                        "kurtosis_error": 10.0
                    }
                },
                "gmci_thresholds": {
                    "normal": {
                        "excellent": 0.90,
                        "veryGood": 0.80,
                        "good": 0.70,
                        "acceptable": 0.60,
                        "limited": 0.50
                    },
                    "asymmetric": {
                        "excellent": 0.92,
                        "veryGood": 0.82,
                        "good": 0.72,
                        "acceptable": 0.62,
                        "limited": 0.52
                    },
                    "highlyAsymmetric": {
                        "excellent": 0.94,
                        "veryGood": 0.84,
                        "good": 0.74,
                        "acceptable": 0.64,
                        "limited": 0.54
                    }
                }
            },
            "cache_analysis": {
                "description": "Analyse des performances de cache",
                "thresholds": {
                    "normal": {
                        "total_error": 8.0,
                        "mean_error": 5.0,
                        "variance_error": 6.0,
                        "skewness_error": 12.0,
                        "kurtosis_error": 15.0
                    },
                    "multimodal": {
                        "total_error": 10.0,
                        "mean_error": 7.0,
                        "variance_error": 5.0,
                        "skewness_error": 10.0,
                        "kurtosis_error": 12.0
                    },
                    "leptokurtic": {
                        "total_error": 12.0,
                        "mean_error": 6.0,
                        "variance_error": 8.0,
                        "skewness_error": 10.0,
                        "kurtosis_error": 8.0
                    }
                },
                "gmci_thresholds": {
                    "normal": {
                        "excellent": 0.92,
                        "veryGood": 0.85,
                        "good": 0.75,
                        "acceptable": 0.65,
                        "limited": 0.55
                    },
                    "multimodal": {
                        "excellent": 0.95,
                        "veryGood": 0.85,
                        "good": 0.75,
                        "acceptable": 0.65,
                        "limited": 0.55
                    },
                    "leptokurtic": {
                        "excellent": 0.92,
                        "veryGood": 0.82,
                        "good": 0.72,
                        "acceptable": 0.62,
                        "limited": 0.52
                    }
                }
            }
        }
    }

    try:
        # Créer le répertoire parent s'il n'existe pas
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # Sauvegarder la configuration
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, indent=2, ensure_ascii=False)

        return True
    except (IOError, OSError) as e:
        print(f"Erreur lors de la génération du fichier de configuration: {e}")
        return False


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--generate-config":
        # Générer un fichier de configuration par défaut
        output_path = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_CONFIG_PATH
        if generate_default_config(output_path):
            print(f"Fichier de configuration généré avec succès: {output_path}")
        else:
            print("Échec de la génération du fichier de configuration")
    else:
        # Exemple d'utilisation
        thresholds = DistributionThresholds()

        # Afficher les types de distribution disponibles
        print("Types de distribution disponibles:")
        for dist_type in thresholds.get_distribution_types():
            print(f"  - {dist_type}: {thresholds.get_distribution_description(dist_type)}")

        print("\nContextes disponibles:")
        for context in thresholds.get_contexts():
            print(f"  - {context}: {thresholds.get_context_description(context)}")

        print("\nCas d'utilisation disponibles:")
        for use_case in thresholds.get_use_cases():
            print(f"  - {use_case}: {thresholds.get_use_case_description(use_case)}")

        # Afficher les seuils pour différents types de distribution et contextes
        for dist_type in thresholds.get_distribution_types():
            print(f"\nSeuils pour le type de distribution '{dist_type}':")
            for context in thresholds.get_contexts():
                print(f"  Contexte '{context}':")
                for metric, value in thresholds.get_thresholds(dist_type, context).items():
                    print(f"    {metric}: {value:.2f}")

        # Afficher les seuils pour différents cas d'utilisation
        for use_case in thresholds.get_use_cases():
            print(f"\nSeuils pour le cas d'utilisation '{use_case}':")
            for dist_type in thresholds.get_distribution_types():
                use_case_thresholds = thresholds.get_thresholds(dist_type, use_case=use_case)
                if use_case_thresholds:
                    print(f"  Type de distribution '{dist_type}':")
                    for metric, value in use_case_thresholds.items():
                        print(f"    {metric}: {value:.2f}")

            print(f"\nSeuils GMCI pour le cas d'utilisation '{use_case}':")
            for dist_type in thresholds.get_distribution_types():
                use_case_gmci_thresholds = thresholds.get_gmci_thresholds(dist_type, use_case=use_case)
                if use_case_gmci_thresholds:
                    print(f"  Type de distribution '{dist_type}':")
                    for level, value in use_case_gmci_thresholds.items():
                        print(f"    {level}: {value:.2f}")
