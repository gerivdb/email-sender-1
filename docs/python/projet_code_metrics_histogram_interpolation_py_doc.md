Help on module histogram_interpolation:

NAME
    histogram_interpolation - Module pour l'implémentation de techniques d'interpolation pour améliorer la résolution des histogrammes.

FUNCTIONS
    b_spline_interpolation(bin_centers: numpy.ndarray, bin_heights: numpy.ndarray, num_points: int = 100, degree: int = 3, smoothing: float = 0) -> Tuple[numpy.ndarray, numpy.ndarray]
        Effectue une interpolation par B-splines entre les bins d'un histogramme.

        Args:
            bin_centers: Centres des bins de l'histogramme
            bin_heights: Hauteurs des bins de l'histogramme
            num_points: Nombre de points pour l'interpolation
            degree: Degré des splines (3 pour cubique)
            smoothing: Facteur de lissage (0 pour une interpolation exacte)

        Returns:
            Tuple[np.ndarray, np.ndarray]: Points x et y interpolés

    b_spline_interpolation_from_histogram(hist_counts: numpy.ndarray, bin_edges: numpy.ndarray, num_points: int = 100, degree: int = 3, smoothing: float = 0) -> Tuple[numpy.ndarray, numpy.ndarray]
        Effectue une interpolation par B-splines à partir des données d'un histogramme.

        Args:
            hist_counts: Comptages des bins de l'histogramme
            bin_edges: Limites des bins de l'histogramme
            num_points: Nombre de points pour l'interpolation
            degree: Degré des splines (3 pour cubique)
            smoothing: Facteur de lissage (0 pour une interpolation exacte)

        Returns:
            Tuple[np.ndarray, np.ndarray]: Points x et y interpolés

    cubic_spline_interpolation(bin_centers: numpy.ndarray, bin_heights: numpy.ndarray, num_points: int = 100, extrapolate: bool = False) -> Tuple[numpy.ndarray, numpy.ndarray]
        Effectue une interpolation par splines cubiques entre les bins d'un histogramme.

        Args:
            bin_centers: Centres des bins de l'histogramme
            bin_heights: Hauteurs des bins de l'histogramme
            num_points: Nombre de points pour l'interpolation
            extrapolate: Si True, permet l'extrapolation en dehors de la plage des bins

        Returns:
            Tuple[np.ndarray, np.ndarray]: Points x et y interpolés

    cubic_spline_interpolation_from_histogram(hist_counts: numpy.ndarray, bin_edges: numpy.ndarray, num_points: int = 100, extrapolate: bool = False) -> Tuple[numpy.ndarray, numpy.ndarray]
        Effectue une interpolation par splines cubiques à partir des données d'un histogramme.

        Args:
            hist_counts: Comptages des bins de l'histogramme
            bin_edges: Limites des bins de l'histogramme
            num_points: Nombre de points pour l'interpolation
            extrapolate: Si True, permet l'extrapolation en dehors de la plage des bins

        Returns:
            Tuple[np.ndarray, np.ndarray]: Points x et y interpolés

    evaluate_linear_interpolation(original_data: numpy.ndarray, hist_counts: numpy.ndarray, bin_edges: numpy.ndarray, num_points: int = 100) -> Dict[str, Any]
        Évalue la qualité de l'interpolation linéaire d'un histogramme.

        Args:
            original_data: Données originales utilisées pour créer l'histogramme
            hist_counts: Comptages des bins de l'histogramme
            bin_edges: Limites des bins de l'histogramme
            num_points: Nombre de points pour l'interpolation

        Returns:
            Dict[str, Any]: Métriques d'évaluation de l'interpolation

    linear_interpolation(bin_centers: numpy.ndarray, bin_heights: numpy.ndarray, num_points: int = 100, extrapolate: bool = False) -> Tuple[numpy.ndarray, numpy.ndarray]
        Effectue une interpolation linéaire entre les bins d'un histogramme.

        Args:
            bin_centers: Centres des bins de l'histogramme
            bin_heights: Hauteurs des bins de l'histogramme
            num_points: Nombre de points pour l'interpolation
            extrapolate: Si True, permet l'extrapolation en dehors de la plage des bins

        Returns:
            Tuple[np.ndarray, np.ndarray]: Points x et y interpolés

    linear_interpolation_from_histogram(hist_counts: numpy.ndarray, bin_edges: numpy.ndarray, num_points: int = 100, extrapolate: bool = False) -> Tuple[numpy.ndarray, numpy.ndarray]
        Effectue une interpolation linéaire à partir des données d'un histogramme.

        Args:
            hist_counts: Comptages des bins de l'histogramme
            bin_edges: Limites des bins de l'histogramme
            num_points: Nombre de points pour l'interpolation
            extrapolate: Si True, permet l'extrapolation en dehors de la plage des bins

        Returns:
            Tuple[np.ndarray, np.ndarray]: Points x et y interpolés

    plot_histogram_with_interpolation(hist_counts: numpy.ndarray, bin_edges: numpy.ndarray, x_interp: numpy.ndarray, y_interp: numpy.ndarray, title: str = 'Histogramme avec interpolation linéaire', save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise un histogramme avec son interpolation linéaire.

        Args:
            hist_counts: Comptages des bins de l'histogramme
            bin_edges: Limites des bins de l'histogramme
            x_interp: Points x interpolés
            y_interp: Points y interpolés
            title: Titre du graphique
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_histogram_with_spline_interpolation(hist_counts: numpy.ndarray, bin_edges: numpy.ndarray, x_interp_linear: numpy.ndarray, y_interp_linear: numpy.ndarray, x_interp_cubic: numpy.ndarray, y_interp_cubic: numpy.ndarray, x_interp_bspline: numpy.ndarray, y_interp_bspline: numpy.ndarray, title: str = 'Histogramme avec différentes interpolations', save_path: Optional[str] = None, show_plot: bool = True) -> None
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

    plot_interpolation_evaluation(original_data: numpy.ndarray, hist_counts: numpy.ndarray, bin_edges: numpy.ndarray, evaluation_results: Dict[str, Any], title: str = "Évaluation de l'interpolation linéaire", save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'évaluation de l'interpolation linéaire d'un histogramme.

        Args:
            original_data: Données originales utilisées pour créer l'histogramme
            hist_counts: Comptages des bins de l'histogramme
            bin_edges: Limites des bins de l'histogramme
            evaluation_results: Résultats de l'évaluation de l'interpolation
            title: Titre du graphique
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_linear_interpolation(bin_centers: numpy.ndarray, bin_heights: numpy.ndarray, x_interp: numpy.ndarray, y_interp: numpy.ndarray, title: str = "Interpolation linéaire de l'histogramme", save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'interpolation linéaire d'un histogramme.

        Args:
            bin_centers: Centres des bins de l'histogramme
            bin_heights: Hauteurs des bins de l'histogramme
            x_interp: Points x interpolés
            y_interp: Points y interpolés
            title: Titre du graphique
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_spline_interpolation(bin_centers: numpy.ndarray, bin_heights: numpy.ndarray, x_interp_linear: numpy.ndarray, y_interp_linear: numpy.ndarray, x_interp_cubic: numpy.ndarray, y_interp_cubic: numpy.ndarray, x_interp_bspline: numpy.ndarray, y_interp_bspline: numpy.ndarray, title: str = "Comparaison des méthodes d'interpolation", save_path: Optional[str] = None, show_plot: bool = True) -> None
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

DATA
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\histogram_interpolation.py


