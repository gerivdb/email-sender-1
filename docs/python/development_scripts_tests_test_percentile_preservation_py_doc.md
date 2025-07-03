Help on module test_percentile_preservation:

NAME
    test_percentile_preservation - Script de test pour les métriques de préservation des percentiles.

FUNCTIONS
    generate_histogram(data, strategy='uniform', num_bins=20)
        Génère un histogramme selon la stratégie spécifiée.

        Args:
            data: Données à représenter
            strategy: Stratégie de binning
            num_bins: Nombre de bins

        Returns:
            bin_edges: Limites des bins
            bin_counts: Comptage par bin

    generate_test_data(distribution_type='normal', size=1000)
        Génère des données de test selon le type de distribution spécifié.

        Args:
            distribution_type: Type de distribution à générer
            size: Taille de l'échantillon

        Returns:
            data: Données générées

    main()
        Fonction principale exécutant tous les tests.

    test_compare_binning_strategies()
        Teste la comparaison des stratégies de binning.

    test_data_reconstruction()
        Teste la reconstruction des données à partir d'un histogramme.

    test_find_optimal_bin_count()
        Teste la recherche du nombre optimal de bins.

    test_percentile_calculation()
        Teste le calcul des percentiles.

    test_percentile_preservation_error()
        Teste le calcul de l'erreur de préservation des percentiles.

    test_percentile_preservation_score()
        Teste le calcul du score de préservation des percentiles.

    test_percentile_weighted_error()
        Teste le calcul de l'erreur pondérée de préservation des percentiles.

    visualize_percentile_preservation()
        Visualise la préservation des percentiles pour différentes stratégies de binning.

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Tuple = typing.Tuple
        Deprecated alias to builtins.tuple.

        Tuple[X, Y] is the cross-product type of X and Y.

        Example: Tuple[T1, T2] is a tuple of two elements corresponding
        to type variables T1 and T2.  Tuple[int, float, str] is a tuple
        of an int, a float and a string.

        To specify a variable-length tuple of homogeneous type, use Tuple[T, ...].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\tests\test_percentile_preservation.py


