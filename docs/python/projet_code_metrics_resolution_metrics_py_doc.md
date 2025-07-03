Help on module resolution_metrics:

NAME
    resolution_metrics - Module impl�mentant des m�triques de r�solution pour les histogrammes.

DESCRIPTION
    Ce module fournit des fonctions pour quantifier la r�solution effective
    des histogrammes par rapport � la largeur des modes.

FUNCTIONS
    analyze_bin_count_impact_on_resolution(data: numpy.ndarray, strategy: str = 'uniform', min_bins: int = 5, max_bins: int = 100, step: int = 5) -> Dict[str, Any]
        Analyse l'impact du nombre de bins sur les diff�rentes m�triques de r�solution.

        Cette fonction �tudie comment le nombre de bins affecte la r�solution d'un histogramme
        en calculant plusieurs m�triques de r�solution pour diff�rents nombres de bins.

        Args:
            data: Donn�es originales
            strategy: Strat�gie de binning � utiliser ("uniform", "quantile", "logarithmic")
            min_bins: Nombre minimal de bins � tester
            max_bins: Nombre maximal de bins � tester
            step: Pas entre les nombres de bins � tester

        Returns:
            Dict[str, Any]: R�sultats de l'analyse pour chaque nombre de bins

    calculate_curvature_resolution(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, interpolate: bool = True, smooth: bool = True, sigma: float = 1.0) -> Dict[str, Any]
        Calcule la r�solution bas�e sur la courbure pour chaque pic dans l'histogramme.

        La r�solution bas�e sur la courbure est d�finie comme la capacit� � distinguer
        les changements de direction dans l'histogramme. Une courbure �lev�e indique
        des transitions nettes entre les pics et les vall�es, ce qui correspond � une
        meilleure r�solution.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unit�s r�elles)
            interpolate: Si True, utilise une interpolation pour am�liorer la pr�cision
            smooth: Si True, applique un lissage gaussien pour r�duire le bruit
            sigma: �cart-type pour le lissage gaussien

        Returns:
            Dict[str, Any]: R�sultats contenant les r�solutions bas�es sur la courbure

    calculate_fwhm(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, interpolate: bool = True) -> Dict[str, Any]
        Calcule la largeur � mi-hauteur (FWHM) pour chaque pic dans l'histogramme.

        La largeur � mi-hauteur est une mesure standard de la r�solution d'un pic,
        d�finie comme la largeur du pic � la moiti� de sa hauteur maximale.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unit�s r�elles)
            interpolate: Si True, utilise une interpolation pour am�liorer la pr�cision

        Returns:
            Dict[str, Any]: R�sultats contenant les FWHM pour chaque pic

    calculate_max_slope_resolution(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, interpolate: bool = True, smooth: bool = True, sigma: float = 1.0) -> Dict[str, Any]
        Calcule la r�solution bas�e sur la pente maximale pour chaque pic dans l'histogramme.

        La r�solution bas�e sur la pente maximale est d�finie comme la largeur du pic
        divis�e par la pente maximale sur les flancs du pic. Cette m�trique est particuli�rement
        utile pour �valuer la capacit� � distinguer des pics adjacents.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unit�s r�elles)
            interpolate: Si True, utilise une interpolation pour am�liorer la pr�cision
            smooth: Si True, applique un lissage gaussien pour r�duire le bruit
            sigma: �cart-type pour le lissage gaussien

        Returns:
            Dict[str, Any]: R�sultats contenant les r�solutions bas�es sur la pente maximale

    calculate_relative_resolution(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, mode_distance: Optional[float] = None) -> Dict[str, Any]
        Calcule la r�solution relative de l'histogramme par rapport � la distance entre les modes.

        La r�solution relative est d�finie comme le rapport entre la largeur � mi-hauteur (FWHM)
        moyenne des pics et la distance moyenne entre les pics adjacents. Une r�solution relative
        faible (< 1) indique que les pics sont bien s�par�s, tandis qu'une r�solution relative
        �lev�e (> 1) indique que les pics se chevauchent.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unit�s r�elles)
            mode_distance: Distance moyenne entre les modes (si connue)

        Returns:
            Dict[str, Any]: R�sultats contenant la r�solution relative

    compare_binning_strategies_resolution(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins: int = 20) -> Dict[str, Dict[str, Any]]
        Compare diff�rentes strat�gies de binning en termes de r�solution.

        Args:
            data: Donn�es originales
            strategies: Liste des strat�gies de binning � comparer
            num_bins: Nombre de bins pour les histogrammes

        Returns:
            Dict[str, Dict[str, Any]]: R�sultats de comparaison par strat�gie

    compare_resolution_metrics(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None) -> Dict[str, Any]
        Compare diff�rentes m�triques de r�solution pour un histogramme donn�.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unit�s r�elles)

        Returns:
            Dict[str, Any]: R�sultats de comparaison des diff�rentes m�triques

    derive_bin_width_resolution_relationship(sigma_range: numpy.ndarray = array([ 1.,  2.,  3.,  4.,  5.,  6.,  7.,  8.,  9., 10.]), bin_width_factors: numpy.ndarray = array([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1. , 1.1, 1.2, 1.3,
           1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2. ])) -> Dict[str, Any]
        D�rive la relation th�orique entre la largeur des bins et la r�solution.

        Cette fonction utilise des mod�les th�oriques pour �tablir comment la largeur des bins
        affecte les diff�rentes m�triques de r�solution (FWHM, pente, courbure).

        Args:
            sigma_range: Plage d'�carts-types � tester pour les distributions gaussiennes
            bin_width_factors: Facteurs de largeur de bin par rapport � sigma (bin_width = factor * sigma)

        Returns:
            Dict[str, Any]: R�sultats contenant les relations th�oriques et coefficients

    find_optimal_binning_strategy_resolution(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins_range: Optional[List[int]] = None) -> Dict[str, Any]
        Trouve la strat�gie de binning optimale en termes de r�solution.

        Args:
            data: Donn�es originales
            strategies: Liste des strat�gies de binning � comparer
            num_bins_range: Liste des nombres de bins � tester

        Returns:
            Dict[str, Any]: R�sultats de l'optimisation

    plot_bin_count_impact_on_resolution(analysis_results: Dict[str, Any], save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'impact du nombre de bins sur les diff�rentes m�triques de r�solution.

        Args:
            analysis_results: R�sultats de l'analyse produits par analyze_bin_count_impact_on_resolution
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_bin_width_resolution_relationship(relationship_results: Dict[str, Any], save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise la relation th�orique entre la largeur des bins et la r�solution.

        Args:
            relationship_results: R�sultats de la fonction derive_bin_width_resolution_relationship
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

DATA
    DEFAULT_EPSILON = 1e-10
    DEFAULT_INTERPOLATION_FACTOR = 10
    DEFAULT_SMOOTHING_SIGMA = 1.0
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Tuple = typing.Tuple
        Deprecated alias to builtins.tuple.

        Tuple[X, Y] is the cross-product type of X and Y.

        Example: Tuple[T1, T2] is a tuple of two elements corresponding
        to type variables T1 and T2.  Tuple[int, float, str] is a tuple
        of an int, a float and a string.

        To specify a variable-length tuple of homogeneous type, use Tuple[T, ...].

    Union = typing.Union
        Union type; Union[X, Y] means either X or Y.

        On Python 3.10 and higher, the | operator
        can also be used to denote unions;
        X | Y means the same thing to the type checker as Union[X, Y].

        To define a union, use e.g. Union[int, str]. Details:
        - The arguments must be types and there must be at least one.
        - None as an argument is a special case and is replaced by
          type(None).
        - Unions of unions are flattened, e.g.::

            assert Union[Union[int, str], float] == Union[int, str, float]

        - Unions of a single argument vanish, e.g.::

            assert Union[int] == int  # The constructor actually returns int

        - Redundant arguments are skipped, e.g.::

            assert Union[int, str, int] == Union[int, str]

        - When comparing unions, the argument order is ignored, e.g.::

            assert Union[int, str] == Union[str, int]

        - You cannot subclass or instantiate a union.
        - You can use Optional[X] as a shorthand for Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\resolution_metrics.py


