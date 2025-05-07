#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test des métriques de stabilité des clusters.
"""

import numpy as np
import matplotlib.pyplot as plt
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
from cluster_stability_metrics import (
    calculate_resolution_robustness,
    evaluate_resolution_robustness_quality,
    calculate_cluster_reproducibility,
    evaluate_reproducibility_quality,
    establish_cluster_stability_quality_thresholds,
    evaluate_cluster_stability_quality
)

def generate_test_data(n_samples=300, n_features=2, centers=4, cluster_std=1.0, random_state=42):
    """
    Génère des données de test pour le clustering.

    Args:
        n_samples: Nombre d'échantillons
        n_features: Nombre de caractéristiques
        centers: Nombre de centres (clusters)
        cluster_std: Écart-type des clusters
        random_state: Graine aléatoire

    Returns:
        X: Données générées
        y: Étiquettes réelles
    """
    X, y, _ = make_blobs(
        n_samples=n_samples,
        n_features=n_features,
        centers=centers,
        cluster_std=cluster_std,
        random_state=random_state
    )
    return X, y

def test_resolution_robustness():
    """
    Teste le calcul de la robustesse face aux variations de résolution.
    """
    print("\n=== Test du calcul de la robustesse face aux variations de résolution ===")

    # Générer des données avec différents niveaux de séparation
    datasets = [
        ("Clusters bien séparés", 0.5),
        ("Clusters moyennement séparés", 1.0),
        ("Clusters peu séparés", 2.0)
    ]

    for name, cluster_std in datasets:
        print(f"\n--- {name} (std={cluster_std}) ---")

        # Générer les données
        X, _ = generate_test_data(cluster_std=cluster_std)

        # Appliquer K-means
        kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
        labels = kmeans.fit_predict(X)

        # Calculer la robustesse face aux variations de résolution
        robustness_metrics = calculate_resolution_robustness(X, labels, n_clusters=4)

        # Évaluer la qualité
        quality_results = evaluate_resolution_robustness_quality(robustness_metrics)

        # Afficher les résultats
        print(f"Stabilité moyenne: {robustness_metrics['mean_stability']:.4f}")
        print(f"Stabilité minimale: {robustness_metrics['min_stability']:.4f}")
        print(f"Déplacement moyen des centroids: {robustness_metrics['mean_centroid_shift']:.4f}")
        print(f"Cohérence moyenne des étiquettes: {robustness_metrics['mean_label_consistency']:.4f}")
        print(f"Robustesse globale: {robustness_metrics['global_robustness']:.4f}")
        print(f"Qualité de la stabilité: {quality_results['stability_quality']}")
        print(f"Qualité du déplacement des centroids: {quality_results['centroid_shift_quality']}")
        print(f"Qualité de la cohérence des étiquettes: {quality_results['label_consistency_quality']}")
        print(f"Qualité de la robustesse globale: {quality_results['global_robustness_quality']}")
        print(f"Qualité globale: {quality_results['overall_quality']}")

    return robustness_metrics, quality_results

def test_cluster_reproducibility():
    """
    Teste le calcul de la reproductibilité des clusters.
    """
    print("\n=== Test du calcul de la reproductibilité des clusters ===")

    # Générer des données avec différents niveaux de séparation
    datasets = [
        ("Clusters bien séparés", 0.5),
        ("Clusters moyennement séparés", 1.0),
        ("Clusters peu séparés", 2.0)
    ]

    for name, cluster_std in datasets:
        print(f"\n--- {name} (std={cluster_std}) ---")

        # Générer les données
        X, _ = generate_test_data(cluster_std=cluster_std)

        # Définir la méthode de clustering
        def kmeans_clustering(n_clusters, random_state):
            return KMeans(n_clusters=n_clusters, random_state=random_state, n_init=10)

        # Calculer la reproductibilité des clusters
        reproducibility_metrics = calculate_cluster_reproducibility(
            X=X,
            clustering_method=kmeans_clustering,
            n_clusters=4,
            n_iterations=10,
            subsample_size=0.8,
            random_state=42
        )

        # Évaluer la qualité
        quality_results = evaluate_reproducibility_quality(reproducibility_metrics)

        # Afficher les résultats
        print(f"Score de Rand ajusté moyen: {reproducibility_metrics['rand_scores']['mean']:.4f}")
        print(f"Score d'information mutuelle ajustée moyen: {reproducibility_metrics['ami_scores']['mean']:.4f}")
        print(f"Stabilité moyenne des centroids: {reproducibility_metrics['centroid_stabilities']['mean']:.4f}")
        print(f"Stabilité moyenne des appartenances: {reproducibility_metrics['membership_stabilities']['mean']:.4f}")
        print(f"Reproductibilité globale: {reproducibility_metrics['global_reproducibility']:.4f}")
        print(f"Qualité du score de Rand: {quality_results['rand_quality']}")
        print(f"Qualité du score d'information mutuelle: {quality_results['ami_quality']}")
        print(f"Qualité de la stabilité des centroids: {quality_results['centroid_stability_quality']}")
        print(f"Qualité de la stabilité des appartenances: {quality_results['membership_stability_quality']}")
        print(f"Qualité de la reproductibilité globale: {quality_results['global_reproducibility_quality']}")
        print(f"Qualité globale: {quality_results['overall_quality']}")

    return reproducibility_metrics, quality_results

def test_cluster_stability_quality():
    """
    Teste l'évaluation de la qualité de la stabilité des clusters.
    """
    print("\n=== Test de l'évaluation de la qualité de la stabilité des clusters ===")

    # Générer des données avec différents niveaux de séparation
    datasets = [
        ("Clusters bien séparés", 0.5),
        ("Clusters moyennement séparés", 1.0),
        ("Clusters peu séparés", 2.0)
    ]

    for name, cluster_std in datasets:
        print(f"\n--- {name} (std={cluster_std}) ---")

        # Générer les données
        X, _ = generate_test_data(cluster_std=cluster_std)

        # Appliquer K-means
        kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
        labels = kmeans.fit_predict(X)

        # Définir la méthode de clustering
        def kmeans_clustering(n_clusters, random_state):
            return KMeans(n_clusters=n_clusters, random_state=random_state, n_init=10)

        # Évaluer la qualité de la stabilité des clusters
        stability_quality = evaluate_cluster_stability_quality(
            X=X,
            labels=labels,
            clustering_method=kmeans_clustering,
            n_clusters=4,
            data_dimensionality=2,
            data_sparsity="medium",
            n_resamplings=5,
            n_iterations=5,
            subsample_size=0.8,
            random_state=42
        )

        # Afficher les résultats
        print(f"Qualité de la robustesse: {stability_quality['robustness_quality']['overall_quality']}")
        print(f"Qualité de la reproductibilité: {stability_quality['reproducibility_quality']['overall_quality']}")
        print(f"Score de stabilité globale: {stability_quality['global_stability_score']:.4f}")
        print(f"Qualité de la stabilité globale: {stability_quality['global_stability_quality']}")
        print(f"Qualité globale: {stability_quality['overall_quality']}")

    return stability_quality

def visualize_clusters_with_stability(X, labels, stability_quality):
    """
    Visualise les clusters avec leur qualité de stabilité.

    Args:
        X: Données d'entrée
        labels: Étiquettes des clusters
        stability_quality: Résultats de l'évaluation de la qualité de la stabilité
    """
    # Vérifier que les données sont en 2D
    if X.shape[1] != 2:
        print("La visualisation n'est possible qu'en 2D.")
        return

    # Créer la figure
    plt.figure(figsize=(10, 8))

    # Couleurs pour les clusters
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf']

    # Tracer les points
    for i in range(len(np.unique(labels))):
        cluster_points = X[labels == i]
        plt.scatter(cluster_points[:, 0], cluster_points[:, 1], c=colors[i % len(colors)], label=f'Cluster {i+1}', alpha=0.7)

    # Ajouter les informations de qualité
    robustness_quality = stability_quality['robustness_quality']['overall_quality']
    reproducibility_quality = stability_quality['reproducibility_quality']['overall_quality']
    global_stability_quality = stability_quality['global_stability_quality']
    overall_quality = stability_quality['overall_quality']
    global_stability_score = stability_quality['global_stability_score']

    plt.title(f'Clusters avec évaluation de la stabilité\nQualité globale: {overall_quality} (Score: {global_stability_score:.2f})')
    plt.xlabel('Caractéristique 1')
    plt.ylabel('Caractéristique 2')
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)

    # Ajouter une annotation avec les détails de qualité
    plt.annotate(
        f"Qualité de robustesse: {robustness_quality}\nQualité de reproductibilité: {reproducibility_quality}\nQualité de stabilité globale: {global_stability_quality}",
        xy=(0.02, 0.02),
        xycoords='axes fraction',
        bbox=dict(boxstyle="round,pad=0.5", fc="white", ec="gray", alpha=0.8)
    )

    plt.tight_layout()
    plt.show()

def main():
    """
    Fonction principale pour exécuter les tests.
    """
    print("=== Tests des métriques de stabilité des clusters ===")

    # Tester le calcul de la robustesse face aux variations de résolution
    robustness_metrics, robustness_quality = test_resolution_robustness()

    # Tester le calcul de la reproductibilité des clusters
    reproducibility_metrics, reproducibility_quality = test_cluster_reproducibility()

    # Tester l'évaluation de la qualité de la stabilité des clusters
    stability_quality = test_cluster_stability_quality()

    # Visualiser les clusters avec leur qualité de stabilité
    print("\n=== Visualisation des clusters avec leur qualité de stabilité ===")

    # Générer des données
    X, _ = generate_test_data(cluster_std=1.0)

    # Appliquer K-means
    kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
    labels = kmeans.fit_predict(X)

    # Définir la méthode de clustering
    def kmeans_clustering(n_clusters, random_state):
        return KMeans(n_clusters=n_clusters, random_state=random_state, n_init=10)

    # Évaluer la qualité de la stabilité des clusters
    stability_quality = evaluate_cluster_stability_quality(
        X=X,
        labels=labels,
        clustering_method=kmeans_clustering,
        n_clusters=4,
        data_dimensionality=2,
        data_sparsity="medium",
        n_resamplings=5,
        n_iterations=5,
        subsample_size=0.8,
        random_state=42
    )

    # Visualiser les clusters
    visualize_clusters_with_stability(X, labels, stability_quality)

    return 0

if __name__ == "__main__":
    main()

