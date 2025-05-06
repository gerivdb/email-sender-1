#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour visualiser les résultats de l'évaluation de la précision de l'IQR.
"""

import matplotlib.pyplot as plt
from typing import Dict, Any, Optional

def plot_iqr_precision_evaluation(histogram_results: Dict[str, Any],
                                kde_results: Dict[str, Any],
                                title: str = "Évaluation de la précision de l'estimation de l'IQR",
                                save_path: Optional[str] = None,
                                show_plot: bool = True) -> None:
    """
    Visualise l'évaluation de la précision de l'estimation de l'IQR.
    
    Args:
        histogram_results: Résultats de l'évaluation pour les histogrammes
        kde_results: Résultats de l'évaluation pour les KDEs
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, axes = plt.subplots(2, 1, figsize=(10, 12))
    
    # Tracer l'erreur relative en fonction du nombre de bins/points
    axes[0].plot(histogram_results["bin_counts"], histogram_results["relative_errors"], 
               'o-', label='Histogramme')
    axes[0].plot(kde_results["kde_points"], kde_results["relative_errors"], 
               's-', label='KDE')
    axes[0].axhline(y=0.05, color='r', linestyle='--', label='Seuil d\'erreur (5%)')
    axes[0].axhline(y=0.015, color='g', linestyle='--', label='Seuil d\'excellence (1.5%)')
    axes[0].set_xscale('log')
    axes[0].set_yscale('log')
    axes[0].set_xlabel('Nombre de bins / points')
    axes[0].set_ylabel('Erreur relative')
    axes[0].set_title(f'Erreur relative en fonction de la résolution - Distribution {histogram_results["distribution_type"]}')
    axes[0].grid(True, alpha=0.3)
    axes[0].legend()
    
    # Tracer la qualité en fonction du nombre de bins/points
    quality_ranks = {"excellent": 4, "good": 3, "acceptable": 2, "poor": 1, "unacceptable": 0}
    hist_quality_ranks = [quality_ranks[q] for q in histogram_results["overall_qualities"]]
    kde_quality_ranks = [quality_ranks[q] for q in kde_results["overall_qualities"]]
    
    axes[1].plot(histogram_results["bin_counts"], hist_quality_ranks, 
               'o-', label='Histogramme')
    axes[1].plot(kde_results["kde_points"], kde_quality_ranks, 
               's-', label='KDE')
    axes[1].set_xscale('log')
    axes[1].set_yticks(list(quality_ranks.values()))
    axes[1].set_yticklabels(list(quality_ranks.keys()))
    axes[1].set_xlabel('Nombre de bins / points')
    axes[1].set_ylabel('Qualité globale')
    axes[1].set_title(f'Qualité de l\'estimation en fonction de la résolution - Distribution {histogram_results["distribution_type"]}')
    axes[1].grid(True, alpha=0.3)
    axes[1].legend()
    
    # Configurer le titre global
    fig.suptitle(title, fontsize=16)
    
    # Ajuster la mise en page
    plt.tight_layout(rect=(0, 0, 1, 0.95))
    
    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
    
    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)
