Help on module mode_interpretability_metrics:

NAME
    mode_interpretability_metrics

DESCRIPTION
    Module impl�mentant des m�triques d'interpr�tabilit� des modes
    pour �valuer la fid�lit� perceptuelle des repr�sentations de distributions.

    Ce module fournit des fonctions pour quantifier la facilit� avec laquelle
    un utilisateur peut identifier et comprendre les diff�rents modes (pics)
    dans une distribution.

FUNCTIONS
    calculate_interpretability_score(clarity: float, distinctness: float, consistency: float = 1.0) -> float
        Calcule un score global d'interpr�tabilit� des modes.

        Args:
            clarity: Score de clart� des modes
            distinctness: Score de distinctivit� des modes
            consistency: Score de coh�rence des modes (si applicable)

        Returns:
            float: Score global d'interpr�tabilit� (0-1)

    calculate_mode_clarity(mode_info: Dict[str, Any]) -> float
        Calcule la clart� des modes, bas�e sur leur pro�minence et leur s�paration.

        Args:
            mode_info: Informations sur les modes d�tect�s

        Returns:
            float: Score de clart� des modes (0-1)

    calculate_mode_consistency(original_mode_info: Dict[str, Any], simplified_mode_info: Dict[str, Any]) -> float
        Calcule la coh�rence des modes entre une distribution originale et sa version simplifi�e.

        Args:
            original_mode_info: Informations sur les modes de la distribution originale
            simplified_mode_info: Informations sur les modes de la distribution simplifi�e

        Returns:
            float: Score de coh�rence des modes (0-1)

    calculate_mode_distinctness(mode_info: Dict[str, Any]) -> float
        Calcule la distinctivit� des modes, bas�e sur leur largeur relative.

        Args:
            mode_info: Informations sur les modes d�tect�s

        Returns:
            float: Score de distinctivit� des modes (0-1)

    compare_binning_strategies_interpretability(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins: int = 20, prominence_threshold: float = 0.1) -> Dict[str, Dict[str, Any]]
        Compare diff�rentes strat�gies de binning en termes d'interpr�tabilit� des modes.

        Args:
            data: Donn�es originales
            strategies: Liste des strat�gies de binning � comparer
            num_bins: Nombre de bins pour les histogrammes
            prominence_threshold: Seuil de pro�minence pour la d�tection des modes

        Returns:
            Dict[str, Dict[str, Any]]: R�sultats de comparaison par strat�gie

    detect_modes(data: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, bin_counts: Optional[numpy.ndarray] = None, prominence_threshold: float = 0.1) -> Dict[str, Any]
        D�tecte les modes (pics) dans une distribution.

        Args:
            data: Donn�es brutes (utilis�es si bin_counts est None)
            bin_edges: Limites des bins (utilis�es si bin_counts est None)
            bin_counts: Valeurs de l'histogramme (si None, calcul�es � partir de data)
            prominence_threshold: Seuil de pro�minence pour consid�rer un pic

        Returns:
            Dict[str, Any]: Informations sur les modes d�tect�s

    evaluate_histogram_interpretability(data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, reference_mode_info: Optional[Dict[str, Any]] = None, prominence_threshold: float = 0.1) -> Dict[str, Any]
        �value l'interpr�tabilit� des modes d'un histogramme.

        Args:
            data: Donn�es originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Valeurs de l'histogramme
            reference_mode_info: Informations sur les modes de r�f�rence (si disponible)
            prominence_threshold: Seuil de pro�minence pour la d�tection des modes

        Returns:
            Dict[str, Any]: R�sultats de l'�valuation

    evaluate_interpretability_quality(score: float) -> str
        �value la qualit� d'interpr�tabilit� des modes en fonction du score.

        Args:
            score: Score d'interpr�tabilit� (0-1)

        Returns:
            str: Niveau de qualit�

    find_optimal_binning_strategy_interpretability(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins_range: Optional[List[int]] = None, prominence_threshold: float = 0.1) -> Dict[str, Any]
        Trouve la strat�gie de binning optimale en termes d'interpr�tabilit� des modes.

        Args:
            data: Donn�es originales
            strategies: Liste des strat�gies de binning � comparer
            num_bins_range: Liste des nombres de bins � tester
            prominence_threshold: Seuil de pro�minence pour la d�tection des modes

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

    DEFAULT_EPSILON = 1e-10
    DEFAULT_PROMINENCE = 0.1
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\mode_interpretability_metrics.py


