Help on module test_multimodality_preservation:

NAME
    test_multimodality_preservation - Script de test pour les m�triques de conservation de la multimodalit�.

FUNCTIONS
    generate_histogram(data, strategy='uniform', num_bins=20)
        G�n�re un histogramme selon la strat�gie sp�cifi�e.

        Args:
            data: Donn�es � repr�senter
            strategy: Strat�gie de binning
            num_bins: Nombre de bins

        Returns:
            bin_edges: Limites des bins
            bin_counts: Comptage par bin

    generate_test_data(distribution_type='normal', size=1000)
        G�n�re des donn�es de test selon le type de distribution sp�cifi�.

        Args:
            distribution_type: Type de distribution � g�n�rer
            size: Taille de l'�chantillon

        Returns:
            data: Donn�es g�n�r�es

    main()
        Fonction principale ex�cutant tous les tests.

    reconstruct_data_from_histogram(bin_edges, bin_counts, method='uniform')
        Reconstruit un ensemble de donn�es approximatif � partir d'un histogramme.

        Args:
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            method: M�thode de reconstruction ("uniform", "midpoint", "random")

        Returns:
            np.ndarray: Donn�es reconstruites

    test_compare_binning_strategies()
        Teste la comparaison des strat�gies de binning.

    test_find_optimal_bin_count()
        Teste la recherche du nombre optimal de bins.

    test_mode_detection()
        Teste la d�tection des modes dans diff�rentes distributions.

    test_mode_preservation()
        Teste le calcul de la pr�servation des modes.

    test_multimodality_preservation_score()
        Teste le calcul du score de pr�servation de la multimodalit�.

    visualize_multimodality_preservation()
        Visualise la pr�servation de la multimodalit� pour diff�rentes strat�gies de binning.

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
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\tests\test_multimodality_preservation.py


