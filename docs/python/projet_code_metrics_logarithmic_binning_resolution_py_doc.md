Help on module logarithmic_binning_resolution:

NAME
    logarithmic_binning_resolution - Module pour l'�valuation de la r�solution avec binning logarithmique.

FUNCTIONS
    evaluate_logarithmic_binning_resolution(data: numpy.ndarray, min_bins: int = 5, max_bins: int = 100, step: int = 5, theoretical_params: Optional[Dict[str, float]] = None) -> Dict[str, Any]
        �value en d�tail la r�solution obtenue avec le binning logarithmique.

        Args:
            data: Donn�es � analyser
            min_bins: Nombre minimal de bins � tester
            max_bins: Nombre maximal de bins � tester
            step: Pas entre les nombres de bins � tester
            theoretical_params: Param�tres th�oriques de la distribution (optionnel)

        Returns:
            Dict[str, Any]: R�sultats d�taill�s de l'�valuation

    plot_logarithmic_binning_resolution_evaluation(evaluation_results: Dict[str, Any], save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise les r�sultats de l'�valuation de la r�solution avec binning logarithmique.

        Args:
            evaluation_results: R�sultats de l'�valuation
            save_path: Chemin o� sauvegarder la figure (optionnel)
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\logarithmic_binning_resolution.py


