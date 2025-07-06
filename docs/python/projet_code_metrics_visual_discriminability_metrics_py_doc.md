Help on module visual_discriminability_metrics:

NAME
    visual_discriminability_metrics

DESCRIPTION
    Module impl�mentant des m�triques de discriminabilit� visuelle
    pour �valuer la fid�lit� perceptuelle des repr�sentations de distributions.

    Ce module fournit des fonctions pour quantifier la facilit� avec laquelle
    un utilisateur peut distinguer visuellement diff�rentes parties d'un histogramme.

FUNCTIONS
    calculate_discriminability_score(local_contrast: numpy.ndarray, threshold: float = 0.05) -> float
        Calcule un score de discriminabilit� visuelle bas� sur le contraste local.

        Args:
            local_contrast: Contraste local pour chaque bin
            threshold: Seuil de contraste minimal perceptible

        Returns:
            float: Score de discriminabilit� (0-1)

    calculate_local_contrast(histogram: numpy.ndarray) -> numpy.ndarray
        Calcule le contraste local pour chaque bin de l'histogramme.

        Le contraste local est une mesure de la diff�rence relative entre un bin
        et ses voisins, ce qui affecte la discriminabilit� visuelle.

        Args:
            histogram: Valeurs de l'histogramme

        Returns:
            np.ndarray: Contraste local pour chaque bin

    calculate_region_discriminability(histogram: numpy.ndarray, region_indices: List[Tuple[int, int]]) -> Dict[str, Any]
        Calcule la discriminabilit� visuelle entre diff�rentes r�gions d'un histogramme.

        Args:
            histogram: Valeurs de l'histogramme
            region_indices: Liste de tuples (d�but, fin) d�finissant les r�gions

        Returns:
            Dict[str, Any]: R�sultats de discriminabilit� entre r�gions

    compare_binning_strategies_discriminability(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins: int = 20) -> Dict[str, Dict[str, Any]]
        Compare diff�rentes strat�gies de binning en termes de discriminabilit� visuelle.

        Args:
            data: Donn�es originales
            strategies: Liste des strat�gies de binning � comparer
            num_bins: Nombre de bins pour les histogrammes

        Returns:
            Dict[str, Dict[str, Any]]: R�sultats de comparaison par strat�gie

    evaluate_discriminability_quality(score: float) -> str
        �value la qualit� de discriminabilit� visuelle en fonction du score.

        Args:
            score: Score de discriminabilit� (0-1)

        Returns:
            str: Niveau de qualit�

    evaluate_histogram_discriminability(bin_counts: numpy.ndarray, threshold: float = 0.05) -> Dict[str, Any]
        �value la discriminabilit� visuelle d'un histogramme.

        Args:
            bin_counts: Valeurs de l'histogramme
            threshold: Seuil de contraste minimal perceptible

        Returns:
            Dict[str, Any]: R�sultats de l'�valuation

    find_optimal_binning_strategy_discriminability(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins_range: Optional[List[int]] = None) -> Dict[str, Any]
        Trouve la strat�gie de binning optimale en termes de discriminabilit� visuelle.

        Args:
            data: Donn�es originales
            strategies: Liste des strat�gies de binning � comparer
            num_bins_range: Liste des nombres de bins � tester

        Returns:
            Dict[str, Any]: R�sultats de l'optimisation

DATA
    Callable = typing.Callable
        Deprecated alias to collections.abc.Callable.

        Callable[[int], str] signifies a function that takes a single
        parameter of type int and returns a str.

        The subscription syntax must always be used with exactly two
        values: the argument list and the return type.
        The argument list must be a list of types, a ParamSpec,
        Concatenate or ellipsis. The return type must be a single type.

        There is no syntax to indicate optional or keyword arguments;
        such function types are rarely used as callback types.

    DEFAULT_CONTRAST_THRESHOLD = 0.05
    DEFAULT_EPSILON = 1e-10
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\visual_discriminability_metrics.py


