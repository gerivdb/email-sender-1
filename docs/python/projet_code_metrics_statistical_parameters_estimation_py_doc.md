Help on module statistical_parameters_estimation:

NAME
    statistical_parameters_estimation

DESCRIPTION
    Module pour l'estimation des param�tres statistiques (moyenne, �cart-type, asym�trie, aplatissement)
    et l'analyse de l'impact de la r�solution sur ces estimations.

FUNCTIONS
    calculate_estimation_errors(results: Dict[str, Any]) -> Dict[str, Any]
        Calcule les erreurs d'estimation par rapport aux param�tres calcul�s � partir des donn�es brutes.

        Args:
            results: R�sultats de la comparaison des m�thodes d'estimation

        Returns:
            Dict[str, Any]: Erreurs d'estimation

    compare_estimation_methods(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000]) -> Dict[str, Any]
        Compare les diff�rentes m�thodes d'estimation des param�tres statistiques.

        Args:
            data: Donn�es brutes
            bin_counts: Liste des nombres de bins � tester pour l'histogramme
            kde_points: Liste des nombres de points � tester pour la KDE

        Returns:
            Dict[str, Any]: R�sultats de la comparaison

    compare_normality_tests(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000]) -> Dict[str, Any]
        Compare les r�sultats des tests de normalit� pour diff�rentes m�thodes d'estimation.

        Args:
            data: Donn�es brutes
            bin_counts: Liste des nombres de bins � tester pour l'histogramme
            kde_points: Liste des nombres de points � tester pour la KDE

        Returns:
            Dict[str, Any]: R�sultats de la comparaison

    determine_critical_resolution(results: Dict[str, Any], threshold: float = 0.05, test_type: str = 'shapiro') -> Dict[str, Any]
        D�termine la r�solution critique pour la fiabilit� des tests statistiques.

        Args:
            results: R�sultats de la comparaison des tests de normalit�
            threshold: Seuil de signification
            test_type: Type de test ('shapiro', 'dagostino')

        Returns:
            Dict[str, Any]: R�solutions critiques

    estimate_from_histogram(hist_counts: numpy.ndarray, bin_edges: numpy.ndarray) -> Dict[str, float]
        Estime les param�tres statistiques � partir d'un histogramme.

        Args:
            hist_counts: Comptages des bins de l'histogramme
            bin_edges: Limites des bins de l'histogramme

        Returns:
            Dict[str, float]: Dictionnaire des param�tres statistiques

    estimate_from_kde(data: numpy.ndarray, num_points: int = 1000, bandwidth_method: str = 'scott') -> Dict[str, float]
        Estime les param�tres statistiques � partir d'une estimation par noyau de la densit� (KDE).

        Args:
            data: Donn�es brutes
            num_points: Nombre de points pour l'�valuation de la KDE
            bandwidth_method: M�thode pour estimer la largeur de bande de la KDE

        Returns:
            Dict[str, float]: Dictionnaire des param�tres statistiques

    estimate_from_raw_data(data: numpy.ndarray) -> Dict[str, float]
        Estime les param�tres statistiques � partir des donn�es brutes.

        Args:
            data: Donn�es brutes

        Returns:
            Dict[str, float]: Dictionnaire des param�tres statistiques

    perform_normality_tests(data: numpy.ndarray) -> Dict[str, Any]
        Effectue des tests de normalit� sur les donn�es.

        Args:
            data: Donn�es � tester

        Returns:
            Dict[str, Any]: R�sultats des tests de normalit�

    perform_normality_tests_from_histogram(hist_counts: numpy.ndarray, bin_edges: numpy.ndarray, num_samples: int = 1000) -> Dict[str, Any]
        Effectue des tests de normalit� � partir d'un histogramme.

        Args:
            hist_counts: Comptages des bins de l'histogramme
            bin_edges: Limites des bins de l'histogramme
            num_samples: Nombre d'�chantillons � g�n�rer pour les tests

        Returns:
            Dict[str, Any]: R�sultats des tests de normalit�

    perform_normality_tests_from_kde(data: numpy.ndarray, num_points: int = 1000, num_samples: int = 1000, bandwidth_method: str = 'scott') -> Dict[str, Any]
        Effectue des tests de normalit� � partir d'une estimation par noyau de la densit� (KDE).

        Args:
            data: Donn�es brutes
            num_points: Nombre de points pour l'�valuation de la KDE
            num_samples: Nombre d'�chantillons � g�n�rer pour les tests
            bandwidth_method: M�thode pour estimer la largeur de bande de la KDE

        Returns:
            Dict[str, Any]: R�sultats des tests de normalit�

    plot_estimation_errors(errors: Dict[str, Any], title: str = "Erreurs d'estimation des param�tres statistiques", save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise les erreurs d'estimation des param�tres statistiques.

        Args:
            errors: Erreurs d'estimation
            title: Titre du graphique
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_normality_tests_results(results: Dict[str, Any], title: str = 'R�sultats des tests de normalit�', save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise les r�sultats des tests de normalit�.

        Args:
            results: R�sultats de la comparaison des tests de normalit�
            title: Titre du graphique
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_parameter_vs_resolution(results: Dict[str, Any], parameter: str = 'mean', title: Optional[str] = None, save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'�volution d'un param�tre statistique en fonction de la r�solution.

        Args:
            results: R�sultats de la comparaison des m�thodes d'estimation
            parameter: Param�tre � visualiser ('mean', 'std', 'skewness', 'kurtosis', 'median', 'iqr')
            title: Titre du graphique (optionnel)
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\statistical_parameters_estimation.py


