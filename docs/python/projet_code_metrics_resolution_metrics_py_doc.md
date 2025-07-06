Help on module resolution_metrics:

NAME
    resolution_metrics - Module implémentant des métriques de résolution pour les histogrammes.

DESCRIPTION
    Ce module fournit des fonctions pour quantifier la résolution effective
    des histogrammes par rapport à la largeur des modes.

FUNCTIONS
    analyze_bin_count_impact_on_resolution(data: numpy.ndarray, strategy: str = 'uniform', min_bins: int = 5, max_bins: int = 100, step: int = 5) -> Dict[str, Any]
        Analyse l'impact du nombre de bins sur les différentes métriques de résolution.

        Cette fonction étudie comment le nombre de bins affecte la résolution d'un histogramme
        en calculant plusieurs métriques de résolution pour différents nombres de bins.

        Args:
            data: Données originales
            strategy: Stratégie de binning à utiliser ("uniform", "quantile", "logarithmic")
            min_bins: Nombre minimal de bins à tester
            max_bins: Nombre maximal de bins à tester
            step: Pas entre les nombres de bins à tester

        Returns:
            Dict[str, Any]: Résultats de l'analyse pour chaque nombre de bins

    calculate_curvature_resolution(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, interpolate: bool = True, smooth: bool = True, sigma: float = 1.0) -> Dict[str, Any]
        Calcule la résolution basée sur la courbure pour chaque pic dans l'histogramme.

        La résolution basée sur la courbure est définie comme la capacité à distinguer
        les changements de direction dans l'histogramme. Une courbure élevée indique
        des transitions nettes entre les pics et les vallées, ce qui correspond à une
        meilleure résolution.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)
            interpolate: Si True, utilise une interpolation pour améliorer la précision
            smooth: Si True, applique un lissage gaussien pour réduire le bruit
            sigma: Écart-type pour le lissage gaussien

        Returns:
            Dict[str, Any]: Résultats contenant les résolutions basées sur la courbure

    calculate_fwhm(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, interpolate: bool = True) -> Dict[str, Any]
        Calcule la largeur à mi-hauteur (FWHM) pour chaque pic dans l'histogramme.

        La largeur à mi-hauteur est une mesure standard de la résolution d'un pic,
        définie comme la largeur du pic à la moitié de sa hauteur maximale.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)
            interpolate: Si True, utilise une interpolation pour améliorer la précision

        Returns:
            Dict[str, Any]: Résultats contenant les FWHM pour chaque pic

    calculate_max_slope_resolution(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, interpolate: bool = True, smooth: bool = True, sigma: float = 1.0) -> Dict[str, Any]
        Calcule la résolution basée sur la pente maximale pour chaque pic dans l'histogramme.

        La résolution basée sur la pente maximale est définie comme la largeur du pic
        divisée par la pente maximale sur les flancs du pic. Cette métrique est particulièrement
        utile pour évaluer la capacité à distinguer des pics adjacents.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)
            interpolate: Si True, utilise une interpolation pour améliorer la précision
            smooth: Si True, applique un lissage gaussien pour réduire le bruit
            sigma: Écart-type pour le lissage gaussien

        Returns:
            Dict[str, Any]: Résultats contenant les résolutions basées sur la pente maximale

    calculate_relative_resolution(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, mode_distance: Optional[float] = None) -> Dict[str, Any]
        Calcule la résolution relative de l'histogramme par rapport à la distance entre les modes.

        La résolution relative est définie comme le rapport entre la largeur à mi-hauteur (FWHM)
        moyenne des pics et la distance moyenne entre les pics adjacents. Une résolution relative
        faible (< 1) indique que les pics sont bien séparés, tandis qu'une résolution relative
        élevée (> 1) indique que les pics se chevauchent.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)
            mode_distance: Distance moyenne entre les modes (si connue)

        Returns:
            Dict[str, Any]: Résultats contenant la résolution relative

    compare_binning_strategies_resolution(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins: int = 20) -> Dict[str, Dict[str, Any]]
        Compare différentes stratégies de binning en termes de résolution.

        Args:
            data: Données originales
            strategies: Liste des stratégies de binning à comparer
            num_bins: Nombre de bins pour les histogrammes

        Returns:
            Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie

    compare_resolution_metrics(histogram: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None) -> Dict[str, Any]
        Compare différentes métriques de résolution pour un histogramme donné.

        Args:
            histogram: Valeurs de l'histogramme
            bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)

        Returns:
            Dict[str, Any]: Résultats de comparaison des différentes métriques

    derive_bin_width_resolution_relationship(sigma_range: numpy.ndarray = array([ 1.,  2.,  3.,  4.,  5.,  6.,  7.,  8.,  9., 10.]), bin_width_factors: numpy.ndarray = array([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1. , 1.1, 1.2, 1.3,
           1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2. ])) -> Dict[str, Any]
        Dérive la relation théorique entre la largeur des bins et la résolution.

        Cette fonction utilise des modèles théoriques pour établir comment la largeur des bins
        affecte les différentes métriques de résolution (FWHM, pente, courbure).

        Args:
            sigma_range: Plage d'écarts-types à tester pour les distributions gaussiennes
            bin_width_factors: Facteurs de largeur de bin par rapport à sigma (bin_width = factor * sigma)

        Returns:
            Dict[str, Any]: Résultats contenant les relations théoriques et coefficients

    find_optimal_binning_strategy_resolution(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins_range: Optional[List[int]] = None) -> Dict[str, Any]
        Trouve la stratégie de binning optimale en termes de résolution.

        Args:
            data: Données originales
            strategies: Liste des stratégies de binning à comparer
            num_bins_range: Liste des nombres de bins à tester

        Returns:
            Dict[str, Any]: Résultats de l'optimisation

    plot_bin_count_impact_on_resolution(analysis_results: Dict[str, Any], save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'impact du nombre de bins sur les différentes métriques de résolution.

        Args:
            analysis_results: Résultats de l'analyse produits par analyze_bin_count_impact_on_resolution
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_bin_width_resolution_relationship(relationship_results: Dict[str, Any], save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise la relation théorique entre la largeur des bins et la résolution.

        Args:
            relationship_results: Résultats de la fonction derive_bin_width_resolution_relationship
            save_path: Chemin où sauvegarder la figure (optionnel)
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


