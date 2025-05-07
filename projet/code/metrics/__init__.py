# -*- coding: utf-8 -*-
"""
Package metrics pour l'évaluation de la qualité des histogrammes et des clusters.
"""

# Importer les fonctions principales de séparation des clusters
from .cluster_separation_metrics import (
    calculate_inter_cluster_distance,
    evaluate_inter_cluster_distance_quality,
    calculate_silhouette_metrics,
    evaluate_silhouette_quality,
    define_cluster_separation_thresholds,
    evaluate_cluster_quality
)

# Importer les fonctions principales de cohésion des clusters
from .cluster_cohesion_metrics import (
    calculate_intra_cluster_variance,
    establish_intra_cluster_variance_criteria,
    evaluate_intra_cluster_variance_quality,
    calculate_cluster_density_metrics,
    define_density_metrics_thresholds,
    evaluate_density_metrics_quality,
    establish_cluster_cohesion_quality_thresholds,
    evaluate_cluster_cohesion_quality
)

# Importer les fonctions principales de stabilité des clusters
from .cluster_stability_metrics import (
    calculate_resolution_robustness,
    establish_resolution_robustness_criteria,
    evaluate_resolution_robustness_quality,
    calculate_cluster_reproducibility,
    define_reproducibility_thresholds,
    evaluate_reproducibility_quality,
    establish_cluster_stability_quality_thresholds,
    evaluate_cluster_stability_quality
)
