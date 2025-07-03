Help on module quantile_binning_resolution:

NAME
    quantile_binning_resolution - Module pour l'évaluation de la résolution avec binning par quantiles.

FUNCTIONS
    evaluate_quantile_binning_resolution(data: numpy.ndarray, min_bins: int = 5, max_bins: int = 100, step: int = 5, theoretical_params: Optional[Dict[str, float]] = None) -> Dict[str, Any]
        Évalue en détail la résolution obtenue avec le binning par quantiles.

        Args:
            data: Données à analyser
            min_bins: Nombre minimal de bins à tester
            max_bins: Nombre maximal de bins à tester
            step: Pas entre les nombres de bins à tester
            theoretical_params: Paramètres théoriques de la distribution (optionnel)

        Returns:
            Dict[str, Any]: Résultats détaillés de l'évaluation

    plot_quantile_binning_resolution_evaluation(evaluation_results: Dict[str, Any], save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise les résultats de l'évaluation de la résolution avec binning par quantiles.

        Args:
            evaluation_results: Résultats de l'évaluation
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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\quantile_binning_resolution.py


