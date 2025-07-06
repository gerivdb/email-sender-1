Help on module weighted_moment_metrics:

NAME
    weighted_moment_metrics - Module impl�mentant des m�triques pond�r�es pour chaque moment statistique.

FUNCTIONS
    calculate_total_weighted_error(real_data, bin_edges, bin_counts, weights=None)
        Calcule l'erreur totale pond�r�e pour tous les moments.

        Args:
            real_data: Donn�es r�elles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weights: Liste des poids [w\u2081, w\u2082, w\u2083, w\u2084] pour chaque moment

        Returns:
            total_weighted_error: Erreur totale pond�r�e
            component_errors: Dictionnaire des erreurs par composante

    weighted_kurtosis_error(real_data, bin_edges, bin_counts, weight=1.0)
        Calcule l'erreur pond�r�e pour l'aplatissement.

        Args:
            real_data: Donn�es r�elles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weight: Poids attribu� � cette m�trique

        Returns:
            weighted_error: Erreur pond�r�e
            raw_error: Erreur brute (non pond�r�e)

    weighted_mean_error(real_data, bin_edges, bin_counts, weight=1.0)
        Calcule l'erreur pond�r�e pour la moyenne.

        Args:
            real_data: Donn�es r�elles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weight: Poids attribu� � cette m�trique

        Returns:
            weighted_error: Erreur pond�r�e
            raw_error: Erreur brute (non pond�r�e)

    weighted_skewness_error(real_data, bin_edges, bin_counts, weight=1.0)
        Calcule l'erreur pond�r�e pour l'asym�trie.

        Args:
            real_data: Donn�es r�elles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weight: Poids attribu� � cette m�trique

        Returns:
            weighted_error: Erreur pond�r�e
            raw_error: Erreur brute (non pond�r�e)

    weighted_variance_error(real_data, bin_edges, bin_counts, weight=1.0, apply_correction=True)
        Calcule l'erreur pond�r�e pour la variance.

        Args:
            real_data: Donn�es r�elles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weight: Poids attribu� � cette m�trique
            apply_correction: Appliquer la correction de Sheppard

        Returns:
            weighted_error: Erreur pond�r�e
            raw_error: Erreur brute (non pond�r�e)

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\weighted_moment_metrics.py


