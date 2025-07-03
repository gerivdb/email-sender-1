Help on module adaptive_binning_resolution:

NAME
    adaptive_binning_resolution - Module pour l'algorithme adaptatif de maximisation de la résolution des histogrammes.

FUNCTIONS
    create_adaptive_binning(data: numpy.ndarray, target_resolution: str = 'high', max_bins: int = 100) -> Tuple[numpy.ndarray, Dict[str, Any]]
        Crée un binning adaptatif qui maximise la résolution en fonction des caractéristiques de la distribution.

        Args:
            data: Données à analyser
            target_resolution: Niveau de résolution cible ("high", "medium", "low")
            max_bins: Nombre maximum de bins

        Returns:
            Tuple[np.ndarray, Dict[str, Any]]: Limites des bins et métadonnées

    detect_distribution_characteristics(data: numpy.ndarray) -> Dict[str, Any]
        Détecte les caractéristiques importantes de la distribution pour optimiser le binning.

        Args:
            data: Données à analyser

        Returns:
            Dict[str, Any]: Caractéristiques de la distribution

    evaluate_adaptive_binning_resolution(data: numpy.ndarray, target_resolution: str = 'high', max_bins: int = 100, compare_with_standard: bool = True) -> Dict[str, Any]
        Évalue la résolution obtenue avec le binning adaptatif et compare avec les stratégies standard.

        Args:
            data: Données à analyser
            target_resolution: Niveau de résolution cible ("high", "medium", "low")
            max_bins: Nombre maximum de bins
            compare_with_standard: Si True, compare avec les stratégies standard

        Returns:
            Dict[str, Any]: Résultats de l'évaluation

    plot_adaptive_binning_resolution(evaluation_results: Dict[str, Any], save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise les résultats de l'évaluation du binning adaptatif.

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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\adaptive_binning_resolution.py


