Help on module global_moment_conservation_index:

NAME
    global_moment_conservation_index

DESCRIPTION
    Module implémentant l'algorithme de calcul de l'indice global de conservation des moments statistiques
    pour les histogrammes de latence.

FUNCTIONS
    calculate_global_moment_conservation_index(real_data, bin_edges, bin_counts, weights=None, thresholds=None, saturation_values=None, context=None)
        Calcule l'indice global de conservation des moments.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            weights: Poids des moments [w\u2081, w\u2082, w\u2083, w\u2084]
            thresholds: Seuils d'acceptabilité [T\u2081, T\u2082, T\u2083, T\u2084]
            saturation_values: Valeurs de saturation [S\u2081, S\u2082, S\u2083, S\u2084]
            context: Contexte d'analyse pour pondération adaptative

        Returns:
            igcm: Indice global de conservation des moments
            component_indices: Indices individuels pour chaque moment
            errors: Erreurs relatives pour chaque moment

    calculate_kurtosis_relative_error(real_data, bin_edges, bin_counts)
        Calcule l'erreur relative de l'aplatissement.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme

        Returns:
            relative_error: Erreur relative en pourcentage

    calculate_mean_relative_error(real_data, bin_edges, bin_counts)
        Calcule l'erreur relative de la moyenne.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme

        Returns:
            relative_error: Erreur relative en pourcentage

    calculate_skewness_relative_error(real_data, bin_edges, bin_counts)
        Calcule l'erreur relative de l'asymétrie.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme

        Returns:
            relative_error: Erreur relative en pourcentage

    calculate_variance_relative_error(real_data, bin_edges, bin_counts)
        Calcule l'erreur relative de la variance.

        Args:
            real_data: Données réelles
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme

        Returns:
            relative_error: Erreur relative en pourcentage

    evaluate_histogram_quality(real_data, config, context=None)
        Évalue la qualité d'un histogramme selon l'indice global de conservation des moments.

        Args:
            real_data: Données réelles
            config: Configuration de l'histogramme
            context: Contexte d'analyse

        Returns:
            result: Dictionnaire des résultats d'évaluation

    generate_histogram(data, config)
        Génère un histogramme selon la configuration spécifiée.

        Args:
            data: Données à représenter
            config: Configuration de l'histogramme (nombre de bins, type, etc.)

        Returns:
            bin_edges: Limites des bins
            bin_counts: Comptage par bin

    get_quality_level(igcm, context=None, distribution_type=None, latency_region=None)
        Détermine le niveau de qualité correspondant à l'IGCM.

        Args:
            igcm: Indice global de conservation des moments
            context: Contexte d'analyse (monitoring, stability, etc.)
            distribution_type: Type de distribution (quasiNormal, asymmetric, etc.)
            latency_region: Région de latence (l1l2Cache, l3Memory, etc.)

        Returns:
            quality_level: Niveau de qualité (Excellent, Très bon, etc.)
            thresholds: Seuils utilisés pour l'évaluation

    optimize_histogram_config(real_data, target_quality='Bon', context=None, max_bins=100)
        Optimise la configuration d'un histogramme pour atteindre un niveau de qualité cible.

        Args:
            real_data: Données réelles
            target_quality: Niveau de qualité cible (Excellent, Très bon, Bon, etc.)
            context: Contexte d'analyse
            max_bins: Nombre maximum de bins à considérer

        Returns:
            optimal_config: Configuration optimale de l'histogramme
            evaluation: Évaluation de la qualité avec cette configuration

DATA
    DISTRIBUTION_THRESHOLDS_AVAILABLE = False
    __annotations__ = {}

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\global_moment_conservation_index.py


