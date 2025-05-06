#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour vérifier que les seuils par type de distribution fonctionnent correctement.
"""

import os
import sys
import json
import numpy as np
import matplotlib.pyplot as plt
import scipy.stats
from typing import Dict, List, Any, Tuple

# Ajouter le répertoire racine au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))
# Ajouter le répertoire des métriques au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'projet', 'code', 'metrics')))

# Importer les modules nécessaires
try:
    # Essayer d'importer directement depuis le chemin ajouté
    from distribution_thresholds import DistributionThresholds
    from global_moment_conservation_index import calculate_gmci, get_quality_level
    from acceptability_thresholds import AcceptabilityThresholds
except ImportError as e:
    try:
        # Essayer d'importer avec le chemin complet
        from projet.code.metrics.distribution_thresholds import DistributionThresholds
        from projet.code.metrics.global_moment_conservation_index import calculate_gmci, get_quality_level
        from projet.code.metrics.acceptability_thresholds import AcceptabilityThresholds
    except ImportError as e:
        print(f"Erreur d'importation: {e}")
        sys.exit(1)


def generate_distribution(dist_type: str, size: int = 1000) -> np.ndarray:
    """
    Génère une distribution de données selon le type spécifié.

    Args:
        dist_type: Type de distribution à générer
        size: Taille de l'échantillon

    Returns:
        data: Tableau NumPy contenant les données générées
    """
    np.random.seed(42)  # Pour la reproductibilité

    if dist_type == "normal" or dist_type == "quasiNormal":
        # Distribution normale
        return np.random.normal(loc=0, scale=1, size=size)

    elif dist_type == "asymmetric" or dist_type == "moderatelyAsymmetric":
        # Distribution asymétrique (log-normale)
        return np.random.lognormal(mean=0, sigma=0.7, size=size)

    elif dist_type == "highlyAsymmetric":
        # Distribution fortement asymétrique (log-normale avec sigma élevé)
        return np.random.lognormal(mean=0, sigma=1.5, size=size)

    elif dist_type == "multimodal":
        # Distribution multimodale (mélange de deux normales)
        data1 = np.random.normal(loc=-2, scale=0.5, size=size // 2)
        data2 = np.random.normal(loc=2, scale=0.5, size=size // 2)
        return np.concatenate([data1, data2])

    elif dist_type == "leptokurtic":
        # Distribution leptokurtique (t de Student avec peu de degrés de liberté)
        return np.random.standard_t(df=3, size=size)

    else:
        # Par défaut, retourner une distribution normale
        print(f"Type de distribution '{dist_type}' non reconnu. Utilisation de la distribution normale.")
        return np.random.normal(loc=0, scale=1, size=size)


def calculate_distribution_stats(data: np.ndarray) -> Dict[str, float]:
    """
    Calcule les statistiques de base d'une distribution.

    Args:
        data: Données de la distribution

    Returns:
        stats: Dictionnaire des statistiques
    """
    return {
        "mean": float(np.mean(data)),
        "variance": float(np.var(data)),
        "skewness": float(scipy.stats.skew(data)),
        "kurtosis": float(scipy.stats.kurtosis(data, fisher=True) + 3)  # Kurtosis non-Fisher
    }


def test_distribution_thresholds() -> None:
    """
    Teste les seuils par type de distribution.
    """
    # Créer une instance du gestionnaire de seuils
    dist_thresholds = DistributionThresholds()

    # Obtenir les types de distribution disponibles
    dist_types = dist_thresholds.get_distribution_types()
    print(f"Types de distribution disponibles: {', '.join(dist_types)}")

    # Obtenir les contextes disponibles
    contexts = dist_thresholds.get_contexts()
    print(f"Contextes disponibles: {', '.join(contexts)}")

    # Tester les seuils pour chaque type de distribution
    results = []

    for dist_type in dist_types:
        print(f"\n=== Test pour le type de distribution '{dist_type}' ===")

        # Générer des données pour ce type de distribution
        data = generate_distribution(dist_type)

        # Calculer les statistiques de la distribution
        stats = calculate_distribution_stats(data)
        print(f"Statistiques: Moyenne={stats['mean']:.4f}, Variance={stats['variance']:.4f}")
        print(f"             Asymétrie={stats['skewness']:.4f}, Aplatissement={stats['kurtosis']:.4f}")

        # Obtenir les seuils pour ce type de distribution
        for context in contexts:
            thresholds = dist_thresholds.get_thresholds(dist_type, context)
            print(f"\nSeuils pour le contexte '{context}':")
            for metric, value in thresholds.items():
                print(f"  {metric}: {value:.2f}")

        # Obtenir les seuils GMCI pour ce type de distribution
        gmci_thresholds = dist_thresholds.get_gmci_thresholds(dist_type)
        print(f"\nSeuils GMCI:")
        for level, value in gmci_thresholds.items():
            print(f"  {level}: {value:.2f}")

        # Calculer l'IGCM pour cette distribution
        reference_stats = stats.copy()
        current_stats = {k: v * 1.1 for k, v in stats.items()}  # Simuler une légère dégradation

        igcm, component_indices, errors = calculate_gmci(
            current_stats["mean"], current_stats["variance"],
            current_stats["skewness"], current_stats["kurtosis"],
            reference_stats["mean"], reference_stats["variance"],
            reference_stats["skewness"], reference_stats["kurtosis"]
        )

        # Obtenir le niveau de qualité
        quality_level, _ = get_quality_level(igcm, distribution_type=dist_type)

        print(f"\nIGCM: {igcm:.4f}, Qualité: {quality_level}")
        print(f"Indices par composante: Moyenne={component_indices['mean']:.4f}, Variance={component_indices['variance']:.4f}")
        print(f"                       Asymétrie={component_indices['skewness']:.4f}, Aplatissement={component_indices['kurtosis']:.4f}")

        # Stocker les résultats pour la visualisation
        results.append({
            "dist_type": dist_type,
            "data": data,
            "stats": stats,
            "igcm": igcm,
            "quality_level": quality_level,
            "component_indices": component_indices,
            "errors": errors
        })

    # Visualiser les distributions
    visualize_distributions(results)


def visualize_distributions(results: List[Dict[str, Any]]) -> None:
    """
    Visualise les distributions testées.

    Args:
        results: Liste des résultats des tests
    """
    n_distributions = len(results)
    n_cols = 3
    n_rows = (n_distributions + n_cols - 1) // n_cols

    plt.figure(figsize=(15, 5 * n_rows))

    for i, result in enumerate(results):
        plt.subplot(n_rows, n_cols, i + 1)

        # Tracer l'histogramme
        plt.hist(result["data"], bins=30, alpha=0.7, density=True)

        # Ajouter les statistiques
        stats = result["stats"]
        plt.title(f"{result['dist_type']}\nIGCM: {result['igcm']:.4f}, Qualité: {result['quality_level']}")
        plt.xlabel("Valeur")
        plt.ylabel("Densité")

        # Ajouter une annotation avec les statistiques
        annotation = (
            f"Moyenne: {stats['mean']:.4f}\n"
            f"Variance: {stats['variance']:.4f}\n"
            f"Asymétrie: {stats['skewness']:.4f}\n"
            f"Aplatissement: {stats['kurtosis']:.4f}"
        )
        plt.annotate(annotation, xy=(0.05, 0.95), xycoords='axes fraction',
                    fontsize=10, ha='left', va='top',
                    bbox=dict(boxstyle='round', fc='white', alpha=0.8))

    plt.tight_layout()
    plt.savefig("distribution_thresholds_test.png")
    plt.close()

    print("\nVisualisation des distributions enregistrée dans 'distribution_thresholds_test.png'")


def test_use_case_thresholds() -> None:
    """
    Teste les seuils spécifiques par cas d'utilisation.
    """
    print("\n=== Test des seuils par cas d'utilisation ===")

    # Créer une instance du gestionnaire de seuils
    dist_thresholds = DistributionThresholds()

    # Obtenir les cas d'utilisation disponibles
    use_cases = dist_thresholds.get_use_cases()
    print(f"Cas d'utilisation disponibles: {', '.join(use_cases)}")

    # Tester les seuils pour chaque cas d'utilisation
    for use_case in use_cases:
        print(f"\n=== Test pour le cas d'utilisation '{use_case}' ===")
        print(f"Description: {dist_thresholds.get_use_case_description(use_case)}")

        # Tester les seuils pour différents types de distribution
        for dist_type in dist_thresholds.get_distribution_types():
            thresholds = dist_thresholds.get_thresholds(dist_type, use_case=use_case)
            if thresholds:
                print(f"\nSeuils pour le type de distribution '{dist_type}':")
                for metric, value in thresholds.items():
                    print(f"  {metric}: {value:.2f}")

                # Tester les seuils GMCI
                gmci_thresholds = dist_thresholds.get_gmci_thresholds(dist_type, use_case=use_case)
                if gmci_thresholds:
                    print(f"\nSeuils GMCI pour le type de distribution '{dist_type}':")
                    for level, value in gmci_thresholds.items():
                        print(f"  {level}: {value:.2f}")

    # Tester un cas d'utilisation inexistant
    print("\n=== Test pour un cas d'utilisation inexistant ===")
    thresholds = dist_thresholds.get_thresholds("normal", use_case="inexistant")
    print(f"Seuils pour un cas d'utilisation inexistant: {thresholds}")

    # Tester un type de distribution inexistant pour un cas d'utilisation existant
    print("\n=== Test pour un type de distribution inexistant dans un cas d'utilisation ===")
    thresholds = dist_thresholds.get_thresholds("inexistant", use_case=use_cases[0])
    print(f"Seuils pour un type de distribution inexistant: {thresholds}")


def test_acceptability_thresholds() -> None:
    """
    Teste l'intégration des seuils par type de distribution dans AcceptabilityThresholds.
    """
    print("\n=== Test de l'intégration avec AcceptabilityThresholds ===")

    # Créer une instance de AcceptabilityThresholds
    acceptability = AcceptabilityThresholds(
        dist_config_path=os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'projet', 'config', 'distribution_thresholds.json'))
    )

    # Obtenir les seuils pour différents types de distribution et contextes
    contexts = ["monitoring", "stability", "anomaly_detection", "characterization", "default"]
    dist_types = ["normal", "asymmetric", "multimodal", "leptokurtic", "highlyAsymmetric"]

    for dist_type in dist_types:
        print(f"\nSeuils pour le type de distribution '{dist_type}':")

        for context in contexts:
            thresholds = acceptability.get_thresholds(context, dist_type)
            print(f"  Contexte '{context}':")
            for metric, value in thresholds.items():
                print(f"    {metric}: {value:.2f}")


if __name__ == "__main__":
    # Tester les seuils par type de distribution
    test_distribution_thresholds()

    # Tester les seuils par cas d'utilisation
    test_use_case_thresholds()

    # Tester l'intégration avec AcceptabilityThresholds
    test_acceptability_thresholds()
