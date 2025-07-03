Help on module binning_strategies_comparison:

NAME
    binning_strategies_comparison - Module pour comparer les performances des diff�rentes strat�gies de binning.

FUNCTIONS
    compare_binning_strategies_for_resolution(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins: int = 20, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Dict[str, Any]]
        Compare diff�rentes strat�gies de binning en termes de r�solution.

        Args:
            data: Donn�es � analyser
            strategies: Liste des strat�gies de binning � comparer
            num_bins: Nombre de bins pour les histogrammes
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Dict[str, Any]]: R�sultats de comparaison par strat�gie

    find_optimal_binning_for_resolution(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins_range: Optional[List[int]] = None, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Trouve la strat�gie de binning optimale en termes de r�solution.

        Args:
            data: Donn�es � analyser
            strategies: Liste des strat�gies de binning � comparer
            num_bins_range: Liste des nombres de bins � tester
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: R�sultats de l'optimisation

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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\binning_strategies_comparison.py


