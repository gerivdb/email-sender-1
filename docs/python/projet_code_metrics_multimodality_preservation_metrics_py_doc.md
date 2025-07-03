Help on module multimodality_preservation_metrics:

NAME
    multimodality_preservation_metrics

DESCRIPTION
    Module impl�mentant des m�triques de conservation de la multimodalit� pour �valuer
    la qualit� des histogrammes et des repr�sentations de distributions.

    Ce module fournit des fonctions pour d�tecter les modes dans une distribution et
    mesurer � quel point ces modes sont pr�serv�s dans une repr�sentation simplifi�e.

FUNCTIONS
    calculate_mode_preservation(original_data: numpy.ndarray, reconstructed_data: numpy.ndarray, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1) -> Dict[str, Any]
        Calcule les m�triques de pr�servation des modes entre les donn�es originales
        et les donn�es reconstruites.

        Args:
            original_data: Donn�es originales
            reconstructed_data: Donn�es reconstruites
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            mode_prominence: Pro�minence minimale pour qu'un pic soit consid�r� comme un mode
            mode_width: Largeur minimale pour qu'un pic soit consid�r� comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit consid�r� comme un mode

        Returns:
            Dict[str, Any]: M�triques de pr�servation des modes

    calculate_multimodality_preservation_score(original_data: numpy.ndarray, reconstructed_data: numpy.ndarray, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1, weights: Optional[Dict[str, float]] = None) -> float
        Calcule un score global de pr�servation de la multimodalit� entre 0 et 1.

        Args:
            original_data: Donn�es originales
            reconstructed_data: Donn�es reconstruites
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            mode_prominence: Pro�minence minimale pour qu'un pic soit consid�r� comme un mode
            mode_width: Largeur minimale pour qu'un pic soit consid�r� comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit consid�r� comme un mode
            weights: Poids pour les diff�rentes composantes du score

        Returns:
            float: Score de pr�servation de la multimodalit� (0-1)

    compare_binning_strategies_multimodality_preservation(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins: int = 20, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1) -> Dict[str, Dict[str, Any]]
        Compare diff�rentes strat�gies de binning en termes de pr�servation de la multimodalit�.

        Args:
            data: Donn�es originales
            strategies: Liste des strat�gies de binning � comparer
            num_bins: Nombre de bins pour les histogrammes
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            mode_prominence: Pro�minence minimale pour qu'un pic soit consid�r� comme un mode
            mode_width: Largeur minimale pour qu'un pic soit consid�r� comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit consid�r� comme un mode

        Returns:
            Dict[str, Dict[str, Any]]: R�sultats de comparaison par strat�gie

    detect_modes(data: numpy.ndarray, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1, grid_points: int = 1000) -> Dict[str, Any]
        D�tecte les modes dans une distribution en utilisant l'estimation par noyau
        de la densit� (KDE) et la d�tection de pics.

        Args:
            data: Donn�es d'entr�e
            kde_bandwidth: Largeur de bande pour l'estimation KDE ('scott', 'silverman' ou valeur num�rique)
            mode_prominence: Pro�minence minimale pour qu'un pic soit consid�r� comme un mode
            mode_width: Largeur minimale pour qu'un pic soit consid�r� comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit consid�r� comme un mode
            grid_points: Nombre de points pour la grille d'�valuation KDE

        Returns:
            Dict[str, Any]: Informations sur les modes d�tect�s

    evaluate_multimodality_preservation_quality(score: float) -> str
        �value la qualit� de pr�servation de la multimodalit� en fonction du score.

        Args:
            score: Score de pr�servation de la multimodalit� (0-1)

        Returns:
            str: Niveau de qualit�

    find_optimal_bin_count_for_multimodality_preservation(data: numpy.ndarray, strategy: str = 'uniform', min_bins: int = 5, max_bins: int = 100, step: int = 5, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1, target_score: float = 0.9) -> Dict[str, Any]
        Trouve le nombre optimal de bins pour pr�server la multimodalit�.

        Args:
            data: Donn�es originales
            strategy: Strat�gie de binning
            min_bins: Nombre minimum de bins � tester
            max_bins: Nombre maximum de bins � tester
            step: Pas d'incr�mentation du nombre de bins
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            mode_prominence: Pro�minence minimale pour qu'un pic soit consid�r� comme un mode
            mode_width: Largeur minimale pour qu'un pic soit consid�r� comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit consid�r� comme un mode
            target_score: Score cible de pr�servation de la multimodalit�

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

    DEFAULT_KDE_BANDWIDTH = 'scott'
    DEFAULT_MODE_HEIGHT = 0.1
    DEFAULT_MODE_PROMINENCE = 0.05
    DEFAULT_MODE_WIDTH = 0.1
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    T = ~T
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\multimodality_preservation_metrics.py


