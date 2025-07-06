Help on module percentile_preservation_metrics:

NAME
    percentile_preservation_metrics

DESCRIPTION
    Module impl�mentant des m�triques de pr�servation des percentiles pour �valuer
    la qualit� des histogrammes et des repr�sentations de distributions.

    Ce module fournit des fonctions pour calculer diff�rentes m�triques qui mesurent
    � quel point les percentiles d'une distribution originale sont pr�serv�s dans
    une repr�sentation simplifi�e (comme un histogramme).

FUNCTIONS
    calculate_percentile_preservation_error(original_data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, percentiles: List[float] = None, reconstruction_method: str = 'uniform') -> Dict[str, Any]
        Calcule l'erreur de pr�servation des percentiles entre les donn�es originales
        et une repr�sentation par histogramme.

        Args:
            original_data: Donn�es originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            percentiles: Liste des percentiles � �valuer
            reconstruction_method: M�thode de reconstruction des donn�es

        Returns:
            Dict[str, Any]: M�triques d'erreur de pr�servation des percentiles

    calculate_percentile_preservation_score(original_data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, percentiles: List[float] = None, reconstruction_method: str = 'uniform', weights: Dict[str, float] = None) -> float
        Calcule un score global de pr�servation des percentiles entre 0 et 1.

        Args:
            original_data: Donn�es originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            percentiles: Liste des percentiles � �valuer
            reconstruction_method: M�thode de reconstruction des donn�es
            weights: Poids pour les diff�rentes composantes du score

        Returns:
            float: Score de pr�servation des percentiles (0-1)

    calculate_percentile_weighted_error(original_data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, percentile_weights: Dict[float, float] = None, reconstruction_method: str = 'uniform') -> Dict[str, Any]
        Calcule l'erreur de pr�servation des percentiles pond�r�e par l'importance
        de chaque percentile.

        Args:
            original_data: Donn�es originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            percentile_weights: Poids pour chaque percentile
            reconstruction_method: M�thode de reconstruction des donn�es

        Returns:
            Dict[str, Any]: M�triques d'erreur pond�r�e

    calculate_percentiles(data: numpy.ndarray, percentiles: List[float] = None) -> Dict[float, float]
        Calcule les percentiles sp�cifi�s pour un ensemble de donn�es.

        Args:
            data: Donn�es d'entr�e
            percentiles: Liste des percentiles � calculer (0-100)

        Returns:
            Dict[float, float]: Dictionnaire des percentiles {percentile: valeur}

    compare_binning_strategies_percentile_preservation(data: numpy.ndarray, strategies: List[str] = None, num_bins: int = 20, percentiles: List[float] = None) -> Dict[str, Dict[str, Any]]
        Compare diff�rentes strat�gies de binning en termes de pr�servation des percentiles.

        Args:
            data: Donn�es originales
            strategies: Liste des strat�gies de binning � comparer
            num_bins: Nombre de bins pour les histogrammes
            percentiles: Liste des percentiles � �valuer

        Returns:
            Dict[str, Dict[str, Any]]: R�sultats de comparaison par strat�gie

    evaluate_percentile_preservation_quality(score: float) -> str
        �value la qualit� de pr�servation des percentiles en fonction du score.

        Args:
            score: Score de pr�servation des percentiles (0-1)

        Returns:
            str: Niveau de qualit�

    find_optimal_bin_count_for_percentile_preservation(data: numpy.ndarray, strategy: str = 'uniform', min_bins: int = 5, max_bins: int = 100, step: int = 5, percentiles: List[float] = None, target_score: float = 0.9) -> Dict[str, Any]
        Trouve le nombre optimal de bins pour pr�server les percentiles.

        Args:
            data: Donn�es originales
            strategy: Strat�gie de binning
            min_bins: Nombre minimum de bins � tester
            max_bins: Nombre maximum de bins � tester
            step: Pas d'incr�mentation du nombre de bins
            percentiles: Liste des percentiles � �valuer
            target_score: Score cible de pr�servation des percentiles

        Returns:
            Dict[str, Any]: R�sultats de l'optimisation

    reconstruct_data_from_histogram(bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, method: str = 'uniform') -> numpy.ndarray
        Reconstruit un ensemble de donn�es approximatif � partir d'un histogramme.

        Args:
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            method: M�thode de reconstruction ("uniform", "midpoint", "random")

        Returns:
            np.ndarray: Donn�es reconstruites

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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\percentile_preservation_metrics.py


