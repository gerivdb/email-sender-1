Help on module weighted_moment_metrics:

NAME
    weighted_moment_metrics - Module implémentant des métriques pondérées pour chaque moment statistique.

FUNCTIONS
    calculate_total_weighted_error(real_data, bin_edges, bin_counts, weights=None)
        Calcule l'erreur totale pondérée pour tous les moments.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weights: Liste des poids [w\u2081, w\u2082, w\u2083, w\u2084] pour chaque moment

        Returns:
            total_weighted_error: Erreur totale pondérée
            component_errors: Dictionnaire des erreurs par composante

    weighted_kurtosis_error(real_data, bin_edges, bin_counts, weight=1.0)
        Calcule l'erreur pondérée pour l'aplatissement.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weight: Poids attribué à cette métrique

        Returns:
            weighted_error: Erreur pondérée
            raw_error: Erreur brute (non pondérée)

    weighted_mean_error(real_data, bin_edges, bin_counts, weight=1.0)
        Calcule l'erreur pondérée pour la moyenne.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weight: Poids attribué à cette métrique

        Returns:
            weighted_error: Erreur pondérée
            raw_error: Erreur brute (non pondérée)

    weighted_skewness_error(real_data, bin_edges, bin_counts, weight=1.0)
        Calcule l'erreur pondérée pour l'asymétrie.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weight: Poids attribué à cette métrique

        Returns:
            weighted_error: Erreur pondérée
            raw_error: Erreur brute (non pondérée)

    weighted_variance_error(real_data, bin_edges, bin_counts, weight=1.0, apply_correction=True)
        Calcule l'erreur pondérée pour la variance.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weight: Poids attribué à cette métrique
            apply_correction: Appliquer la correction de Sheppard

        Returns:
            weighted_error: Erreur pondérée
            raw_error: Erreur brute (non pondérée)

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\weighted_moment_metrics.py


