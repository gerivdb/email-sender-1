#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour l'implémentation de techniques d'interpolation pour améliorer la résolution des histogrammes.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from typing import Dict, Optional, Any, Union, List, Tuple
from scipy.interpolate import interp1d, CubicSpline, splrep, splev

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def linear_interpolation(bin_centers: np.ndarray,
                        bin_heights: np.ndarray,
                        num_points: int = 100,
                        extrapolate: bool = False) -> Tuple[np.ndarray, np.ndarray]:
    """
    Effectue une interpolation linéaire entre les bins d'un histogramme.

    Args:
        bin_centers: Centres des bins de l'histogramme
        bin_heights: Hauteurs des bins de l'histogramme
        num_points: Nombre de points pour l'interpolation
        extrapolate: Si True, permet l'extrapolation en dehors de la plage des bins

    Returns:
        Tuple[np.ndarray, np.ndarray]: Points x et y interpolés
    """
    # Vérifier que les entrées sont valides
    if len(bin_centers) != len(bin_heights):
        raise ValueError("Les tableaux bin_centers et bin_heights doivent avoir la même longueur")

    if len(bin_centers) < 2:
        raise ValueError("Au moins deux bins sont nécessaires pour l'interpolation")

    # Créer la fonction d'interpolation linéaire
    if extrapolate:
        f = interp1d(bin_centers, bin_heights, kind='linear', bounds_error=False, fill_value="extrapolate")
    else:
        f = interp1d(bin_centers, bin_heights, kind='linear', bounds_error=False, fill_value=np.nan)

    # Créer une grille de points plus fine pour l'interpolation
    x_min, x_max = np.min(bin_centers), np.max(bin_centers)
    x_interp = np.linspace(x_min, x_max, num_points)

    # Calculer les valeurs interpolées
    y_interp = f(x_interp)

    return x_interp, y_interp

def linear_interpolation_from_histogram(hist_counts: np.ndarray,
                                      bin_edges: np.ndarray,
                                      num_points: int = 100,
                                      extrapolate: bool = False) -> Tuple[np.ndarray, np.ndarray]:
    """
    Effectue une interpolation linéaire à partir des données d'un histogramme.

    Args:
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme
        num_points: Nombre de points pour l'interpolation
        extrapolate: Si True, permet l'extrapolation en dehors de la plage des bins

    Returns:
        Tuple[np.ndarray, np.ndarray]: Points x et y interpolés
    """
    # Vérifier que les entrées sont valides
    if len(hist_counts) != len(bin_edges) - 1:
        raise ValueError("Le tableau hist_counts doit avoir une longueur égale à len(bin_edges) - 1")

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Appeler la fonction d'interpolation linéaire
    return linear_interpolation(bin_centers, hist_counts, num_points, extrapolate)

def plot_linear_interpolation(bin_centers: np.ndarray,
                            bin_heights: np.ndarray,
                            x_interp: np.ndarray,
                            y_interp: np.ndarray,
                            title: str = "Interpolation linéaire de l'histogramme",
                            save_path: Optional[str] = None,
                            show_plot: bool = True) -> None:
    """
    Visualise l'interpolation linéaire d'un histogramme.

    Args:
        bin_centers: Centres des bins de l'histogramme
        bin_heights: Hauteurs des bins de l'histogramme
        x_interp: Points x interpolés
        y_interp: Points y interpolés
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, ax = plt.subplots(figsize=(10, 6))

    # Tracer l'histogramme original (sous forme de points)
    ax.plot(bin_centers, bin_heights, 'o', markersize=8, color='blue', label='Bins originaux')

    # Tracer la courbe interpolée
    ax.plot(x_interp, y_interp, '-', linewidth=2, color='red', label='Interpolation linéaire')

    # Configurer le graphique
    ax.set_xlabel('Valeur')
    ax.set_ylabel('Fréquence')
    ax.set_title(title)
    ax.legend()
    ax.grid(True, alpha=0.3)

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

def plot_histogram_with_interpolation(hist_counts: np.ndarray,
                                    bin_edges: np.ndarray,
                                    x_interp: np.ndarray,
                                    y_interp: np.ndarray,
                                    title: str = "Histogramme avec interpolation linéaire",
                                    save_path: Optional[str] = None,
                                    show_plot: bool = True) -> None:
    """
    Visualise un histogramme avec son interpolation linéaire.

    Args:
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme
        x_interp: Points x interpolés
        y_interp: Points y interpolés
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, ax = plt.subplots(figsize=(10, 6))

    # Tracer l'histogramme original
    bin_widths = np.diff(bin_edges)
    ax.bar(bin_edges[:-1], hist_counts, width=bin_widths, alpha=0.5, color='blue', align='edge', label='Histogramme original')

    # Tracer la courbe interpolée
    ax.plot(x_interp, y_interp, '-', linewidth=2, color='red', label='Interpolation linéaire')

    # Configurer le graphique
    ax.set_xlabel('Valeur')
    ax.set_ylabel('Fréquence')
    ax.set_title(title)
    ax.legend()
    ax.grid(True, alpha=0.3)

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

def cubic_spline_interpolation(bin_centers: np.ndarray,
                          bin_heights: np.ndarray,
                          num_points: int = 100,
                          extrapolate: bool = False) -> Tuple[np.ndarray, np.ndarray]:
    """
    Effectue une interpolation par splines cubiques entre les bins d'un histogramme.

    Args:
        bin_centers: Centres des bins de l'histogramme
        bin_heights: Hauteurs des bins de l'histogramme
        num_points: Nombre de points pour l'interpolation
        extrapolate: Si True, permet l'extrapolation en dehors de la plage des bins

    Returns:
        Tuple[np.ndarray, np.ndarray]: Points x et y interpolés
    """
    # Vérifier que les entrées sont valides
    if len(bin_centers) != len(bin_heights):
        raise ValueError("Les tableaux bin_centers et bin_heights doivent avoir la même longueur")

    if len(bin_centers) < 4:
        raise ValueError("Au moins quatre bins sont nécessaires pour l'interpolation par splines cubiques")

    # Créer la fonction d'interpolation par splines cubiques
    cs = CubicSpline(bin_centers, bin_heights, bc_type='natural' if not extrapolate else 'not-a-knot')

    # Créer une grille de points plus fine pour l'interpolation
    x_min, x_max = np.min(bin_centers), np.max(bin_centers)
    x_interp = np.linspace(x_min, x_max, num_points)

    # Calculer les valeurs interpolées
    y_interp = cs(x_interp)

    # Assurer que les valeurs interpolées sont non négatives (pour les histogrammes)
    y_interp = np.maximum(y_interp, 0)

    return x_interp, y_interp

def cubic_spline_interpolation_from_histogram(hist_counts: np.ndarray,
                                            bin_edges: np.ndarray,
                                            num_points: int = 100,
                                            extrapolate: bool = False) -> Tuple[np.ndarray, np.ndarray]:
    """
    Effectue une interpolation par splines cubiques à partir des données d'un histogramme.

    Args:
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme
        num_points: Nombre de points pour l'interpolation
        extrapolate: Si True, permet l'extrapolation en dehors de la plage des bins

    Returns:
        Tuple[np.ndarray, np.ndarray]: Points x et y interpolés
    """
    # Vérifier que les entrées sont valides
    if len(hist_counts) != len(bin_edges) - 1:
        raise ValueError("Le tableau hist_counts doit avoir une longueur égale à len(bin_edges) - 1")

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Appeler la fonction d'interpolation par splines cubiques
    return cubic_spline_interpolation(bin_centers, hist_counts, num_points, extrapolate)

def b_spline_interpolation(bin_centers: np.ndarray,
                         bin_heights: np.ndarray,
                         num_points: int = 100,
                         degree: int = 3,
                         smoothing: float = 0) -> Tuple[np.ndarray, np.ndarray]:
    """
    Effectue une interpolation par B-splines entre les bins d'un histogramme.

    Args:
        bin_centers: Centres des bins de l'histogramme
        bin_heights: Hauteurs des bins de l'histogramme
        num_points: Nombre de points pour l'interpolation
        degree: Degré des splines (3 pour cubique)
        smoothing: Facteur de lissage (0 pour une interpolation exacte)

    Returns:
        Tuple[np.ndarray, np.ndarray]: Points x et y interpolés
    """
    # Vérifier que les entrées sont valides
    if len(bin_centers) != len(bin_heights):
        raise ValueError("Les tableaux bin_centers et bin_heights doivent avoir la même longueur")

    if len(bin_centers) <= degree:
        raise ValueError(f"Au moins {degree + 1} bins sont nécessaires pour l'interpolation par B-splines de degré {degree}")

    # Créer la représentation B-spline
    tck = splrep(bin_centers, bin_heights, k=degree, s=smoothing)

    # Créer une grille de points plus fine pour l'interpolation
    x_min, x_max = np.min(bin_centers), np.max(bin_centers)
    x_interp = np.linspace(x_min, x_max, num_points)

    # Calculer les valeurs interpolées
    y_interp = splev(x_interp, tck)

    # Assurer que les valeurs interpolées sont non négatives (pour les histogrammes)
    y_interp = np.maximum(y_interp, 0)

    return x_interp, y_interp

def b_spline_interpolation_from_histogram(hist_counts: np.ndarray,
                                        bin_edges: np.ndarray,
                                        num_points: int = 100,
                                        degree: int = 3,
                                        smoothing: float = 0) -> Tuple[np.ndarray, np.ndarray]:
    """
    Effectue une interpolation par B-splines à partir des données d'un histogramme.

    Args:
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme
        num_points: Nombre de points pour l'interpolation
        degree: Degré des splines (3 pour cubique)
        smoothing: Facteur de lissage (0 pour une interpolation exacte)

    Returns:
        Tuple[np.ndarray, np.ndarray]: Points x et y interpolés
    """
    # Vérifier que les entrées sont valides
    if len(hist_counts) != len(bin_edges) - 1:
        raise ValueError("Le tableau hist_counts doit avoir une longueur égale à len(bin_edges) - 1")

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Appeler la fonction d'interpolation par B-splines
    return b_spline_interpolation(bin_centers, hist_counts, num_points, degree, smoothing)

def plot_spline_interpolation(bin_centers: np.ndarray,
                            bin_heights: np.ndarray,
                            x_interp_linear: np.ndarray,
                            y_interp_linear: np.ndarray,
                            x_interp_cubic: np.ndarray,
                            y_interp_cubic: np.ndarray,
                            x_interp_bspline: np.ndarray,
                            y_interp_bspline: np.ndarray,
                            title: str = "Comparaison des méthodes d'interpolation",
                            save_path: Optional[str] = None,
                            show_plot: bool = True) -> None:
    """
    Visualise et compare différentes méthodes d'interpolation d'un histogramme.

    Args:
        bin_centers: Centres des bins de l'histogramme
        bin_heights: Hauteurs des bins de l'histogramme
        x_interp_linear: Points x de l'interpolation linéaire
        y_interp_linear: Points y de l'interpolation linéaire
        x_interp_cubic: Points x de l'interpolation par splines cubiques
        y_interp_cubic: Points y de l'interpolation par splines cubiques
        x_interp_bspline: Points x de l'interpolation par B-splines
        y_interp_bspline: Points y de l'interpolation par B-splines
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, ax = plt.subplots(figsize=(12, 8))

    # Tracer l'histogramme original (sous forme de points)
    ax.plot(bin_centers, bin_heights, 'o', markersize=8, color='blue', label='Bins originaux')

    # Tracer les courbes interpolées
    ax.plot(x_interp_linear, y_interp_linear, '-', linewidth=2, color='red', label='Interpolation linéaire')
    ax.plot(x_interp_cubic, y_interp_cubic, '--', linewidth=2, color='green', label='Splines cubiques')
    ax.plot(x_interp_bspline, y_interp_bspline, '-.', linewidth=2, color='purple', label='B-splines')

    # Configurer le graphique
    ax.set_xlabel('Valeur')
    ax.set_ylabel('Fréquence')
    ax.set_title(title)
    ax.legend()
    ax.grid(True, alpha=0.3)

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

def plot_histogram_with_spline_interpolation(hist_counts: np.ndarray,
                                           bin_edges: np.ndarray,
                                           x_interp_linear: np.ndarray,
                                           y_interp_linear: np.ndarray,
                                           x_interp_cubic: np.ndarray,
                                           y_interp_cubic: np.ndarray,
                                           x_interp_bspline: np.ndarray,
                                           y_interp_bspline: np.ndarray,
                                           title: str = "Histogramme avec différentes interpolations",
                                           save_path: Optional[str] = None,
                                           show_plot: bool = True) -> None:
    """
    Visualise un histogramme avec différentes méthodes d'interpolation.

    Args:
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme
        x_interp_linear: Points x de l'interpolation linéaire
        y_interp_linear: Points y de l'interpolation linéaire
        x_interp_cubic: Points x de l'interpolation par splines cubiques
        y_interp_cubic: Points y de l'interpolation par splines cubiques
        x_interp_bspline: Points x de l'interpolation par B-splines
        y_interp_bspline: Points y de l'interpolation par B-splines
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, ax = plt.subplots(figsize=(12, 8))

    # Tracer l'histogramme original
    bin_widths = np.diff(bin_edges)
    ax.bar(bin_edges[:-1], hist_counts, width=bin_widths, alpha=0.5, color='blue', align='edge', label='Histogramme original')

    # Tracer les courbes interpolées
    ax.plot(x_interp_linear, y_interp_linear, '-', linewidth=2, color='red', label='Interpolation linéaire')
    ax.plot(x_interp_cubic, y_interp_cubic, '--', linewidth=2, color='green', label='Splines cubiques')
    ax.plot(x_interp_bspline, y_interp_bspline, '-.', linewidth=2, color='purple', label='B-splines')

    # Configurer le graphique
    ax.set_xlabel('Valeur')
    ax.set_ylabel('Fréquence')
    ax.set_title(title)
    ax.legend()
    ax.grid(True, alpha=0.3)

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

def evaluate_linear_interpolation(original_data: np.ndarray,
                                hist_counts: np.ndarray,
                                bin_edges: np.ndarray,
                                num_points: int = 100) -> Dict[str, Any]:
    """
    Évalue la qualité de l'interpolation linéaire d'un histogramme.

    Args:
        original_data: Données originales utilisées pour créer l'histogramme
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme
        num_points: Nombre de points pour l'interpolation

    Returns:
        Dict[str, Any]: Métriques d'évaluation de l'interpolation
    """
    # Normaliser l'histogramme si nécessaire
    if np.sum(hist_counts) > 0:
        hist_counts_norm = hist_counts / np.sum(hist_counts)
    else:
        hist_counts_norm = hist_counts

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Effectuer l'interpolation linéaire
    x_interp, y_interp = linear_interpolation(bin_centers, hist_counts_norm, num_points)

    # Calculer la densité de probabilité réelle (KDE) à partir des données originales
    from scipy.stats import gaussian_kde
    kde = gaussian_kde(original_data, bw_method='scott')
    y_kde = kde(x_interp)

    # Normaliser la KDE pour qu'elle ait la même intégrale que l'histogramme normalisé
    y_kde = y_kde / np.sum(y_kde) * np.sum(y_interp)

    # Calculer l'erreur quadratique moyenne (MSE) entre l'interpolation et la KDE
    mse = np.mean((y_interp - y_kde) ** 2)

    # Calculer l'erreur absolue moyenne (MAE)
    mae = np.mean(np.abs(y_interp - y_kde))

    # Calculer le coefficient de corrélation
    correlation = np.corrcoef(y_interp, y_kde)[0, 1]

    # Calculer l'erreur relative moyenne
    with np.errstate(divide='ignore', invalid='ignore'):
        relative_error = np.mean(np.abs((y_interp - y_kde) / y_kde))
        relative_error = np.nan_to_num(relative_error, nan=0.0, posinf=0.0, neginf=0.0)

    # Résultats
    return {
        "mse": mse,
        "mae": mae,
        "correlation": correlation,
        "relative_error": relative_error,
        "x_interp": x_interp,
        "y_interp": y_interp,
        "y_kde": y_kde
    }

def plot_interpolation_evaluation(original_data: np.ndarray,
                                hist_counts: np.ndarray,
                                bin_edges: np.ndarray,
                                evaluation_results: Dict[str, Any],
                                title: str = "Évaluation de l'interpolation linéaire",
                                save_path: Optional[str] = None,
                                show_plot: bool = True) -> None:
    """
    Visualise l'évaluation de l'interpolation linéaire d'un histogramme.

    Args:
        original_data: Données originales utilisées pour créer l'histogramme
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme
        evaluation_results: Résultats de l'évaluation de l'interpolation
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Extraire les résultats de l'évaluation
    x_interp = evaluation_results["x_interp"]
    y_interp = evaluation_results["y_interp"]
    y_kde = evaluation_results["y_kde"]
    mse = evaluation_results["mse"]
    mae = evaluation_results["mae"]
    correlation = evaluation_results["correlation"]
    relative_error = evaluation_results["relative_error"]

    # Normaliser l'histogramme si nécessaire
    if np.sum(hist_counts) > 0:
        hist_counts_norm = hist_counts / np.sum(hist_counts)
    else:
        hist_counts_norm = hist_counts

    # Créer la figure
    fig, ax = plt.subplots(figsize=(12, 8))

    # Tracer l'histogramme original
    bin_widths = np.diff(bin_edges)
    ax.bar(bin_edges[:-1], hist_counts_norm, width=bin_widths, alpha=0.3, color='blue', align='edge', label='Histogramme original')

    # Tracer la courbe interpolée
    ax.plot(x_interp, y_interp, '-', linewidth=2, color='red', label='Interpolation linéaire')

    # Tracer la KDE (densité réelle)
    ax.plot(x_interp, y_kde, '--', linewidth=2, color='green', label='Densité réelle (KDE)')

    # Ajouter les métriques d'évaluation au graphique
    metrics_text = f"MSE: {mse:.6f}\nMAE: {mae:.6f}\nCorrélation: {correlation:.4f}\nErreur relative: {relative_error:.4f}"
    ax.text(0.05, 0.95, metrics_text, transform=ax.transAxes, fontsize=10, verticalalignment='top',
           bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    # Configurer le graphique
    ax.set_xlabel('Valeur')
    ax.set_ylabel('Densité de probabilité')
    ax.set_title(title)
    ax.legend()
    ax.grid(True, alpha=0.3)

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

if __name__ == "__main__":
    # Exemple d'utilisation
    print("=== Test des méthodes d'interpolation des histogrammes ===")

    # Générer des distributions synthétiques pour les tests
    np.random.seed(42)  # Pour la reproductibilité

    # Distribution gaussienne
    gaussian_data = np.random.normal(loc=50, scale=10, size=1000)

    # Distribution bimodale
    bimodal_data = np.concatenate([
        np.random.normal(loc=30, scale=5, size=500),
        np.random.normal(loc=70, scale=8, size=500)
    ])

    # Distribution asymétrique (log-normale)
    lognormal_data = np.random.lognormal(mean=1.0, sigma=0.5, size=1000)

    # Tester les différentes méthodes d'interpolation sur différentes distributions
    for name, data in [("Gaussienne", gaussian_data),
                      ("Bimodale", bimodal_data),
                      ("Log-normale", lognormal_data)]:
        print(f"\nDistribution {name}:")

        # Créer l'histogramme avec différents nombres de bins
        for num_bins in [10, 20, 50]:
            print(f"  Nombre de bins: {num_bins}")

            # Calculer l'histogramme
            hist_counts, bin_edges = np.histogram(data, bins=num_bins, density=True)
            bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

            # Effectuer l'interpolation linéaire
            x_interp_linear, y_interp_linear = linear_interpolation(bin_centers, hist_counts, num_points=200)

            # Effectuer l'interpolation par splines cubiques
            if len(bin_centers) >= 4:  # Au moins 4 points pour les splines cubiques
                x_interp_cubic, y_interp_cubic = cubic_spline_interpolation(bin_centers, hist_counts, num_points=200)
            else:
                # Utiliser l'interpolation linéaire si pas assez de points
                x_interp_cubic, y_interp_cubic = x_interp_linear, y_interp_linear

            # Effectuer l'interpolation par B-splines
            degree = min(3, len(bin_centers) - 1)  # Degré maximum possible
            x_interp_bspline, y_interp_bspline = b_spline_interpolation(bin_centers, hist_counts, num_points=200, degree=degree)

            # Visualiser l'histogramme avec les différentes interpolations
            plot_histogram_with_spline_interpolation(
                hist_counts,
                bin_edges,
                x_interp_linear,
                y_interp_linear,
                x_interp_cubic,
                y_interp_cubic,
                x_interp_bspline,
                y_interp_bspline,
                title=f"Comparaison des interpolations - Distribution {name} ({num_bins} bins)",
                save_path=f"spline_interpolation_{name.lower()}_{num_bins}_bins.png",
                show_plot=False
            )

            # Visualiser les points de l'histogramme avec les différentes interpolations
            plot_spline_interpolation(
                bin_centers,
                hist_counts,
                x_interp_linear,
                y_interp_linear,
                x_interp_cubic,
                y_interp_cubic,
                x_interp_bspline,
                y_interp_bspline,
                title=f"Comparaison des interpolations (points) - Distribution {name} ({num_bins} bins)",
                save_path=f"spline_interpolation_points_{name.lower()}_{num_bins}_bins.png",
                show_plot=False
            )

            # Évaluer la qualité des interpolations
            evaluation_linear = evaluate_linear_interpolation(data, hist_counts, bin_edges, num_points=200)

            # Afficher les métriques d'évaluation pour l'interpolation linéaire
            print(f"    Interpolation linéaire:")
            print(f"      MSE: {evaluation_linear['mse']:.6f}")
            print(f"      MAE: {evaluation_linear['mae']:.6f}")
            print(f"      Corrélation: {evaluation_linear['correlation']:.4f}")
            print(f"      Erreur relative: {evaluation_linear['relative_error']:.4f}")

            # Visualiser l'évaluation de l'interpolation linéaire
            plot_interpolation_evaluation(
                data,
                hist_counts,
                bin_edges,
                evaluation_linear,
                title=f"Évaluation de l'interpolation linéaire - Distribution {name} ({num_bins} bins)",
                save_path=f"linear_interpolation_evaluation_{name.lower()}_{num_bins}_bins.png",
                show_plot=False
            )

    print("\nTest terminé avec succès!")
    print("Résultats sauvegardés dans les fichiers PNG correspondants.")
