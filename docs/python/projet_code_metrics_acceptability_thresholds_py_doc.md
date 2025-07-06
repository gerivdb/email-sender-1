Help on module acceptability_thresholds:

NAME
    acceptability_thresholds - Module pour établir des seuils d'acceptabilité pour les métriques composites.

CLASSES
    builtins.object
        AcceptabilityThresholds

    class AcceptabilityThresholds(builtins.object)
     |  AcceptabilityThresholds(config_path: Optional[str] = None, dist_config_path: Optional[str] = None)
     |
     |  Classe pour gérer les seuils d'acceptabilité des métriques composites.
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: Optional[str] = None, dist_config_path: Optional[str] = None)
     |      Initialise les seuils d'acceptabilité.
     |
     |      Args:
     |          config_path: Chemin vers le fichier de configuration des seuils
     |          dist_config_path: Chemin vers le fichier de configuration des seuils par type de distribution
     |
     |  evaluate_acceptability(self, errors: Dict[str, Union[float, Dict[str, Dict[str, float]]]], context: str = 'default', distribution_type: Optional[str] = None) -> Tuple[bool, Dict[str, bool]]
     |      Évalue si les erreurs sont acceptables selon les seuils définis.
     |
     |      Args:
     |          errors: Dictionnaire des erreurs (total_error et composantes)
     |          context: Contexte d'analyse
     |          distribution_type: Type de distribution
     |
     |      Returns:
     |          acceptable: Booléen indiquant si les erreurs sont globalement acceptables
     |          component_results: Dictionnaire indiquant l'acceptabilité de chaque composante
     |
     |  get_acceptability_level(self, error_value: float, threshold: float) -> str
     |      Détermine le niveau d'acceptabilité d'une erreur.
     |
     |      Args:
     |          error_value: Valeur de l'erreur
     |          threshold: Seuil d'acceptabilité
     |
     |      Returns:
     |          level: Niveau d'acceptabilité (excellent, good, acceptable, poor, unacceptable)
     |
     |  get_detailed_evaluation(self, errors: Dict[str, Union[float, Dict[str, Dict[str, float]]]], context: str = 'default', distribution_type: Optional[str] = None) -> Dict[str, Dict[str, Union[float, str, bool, int]]]
     |      Fournit une évaluation détaillée des erreurs par rapport aux seuils.
     |
     |      Args:
     |          errors: Dictionnaire des erreurs (total_error et composantes)
     |          context: Contexte d'analyse
     |          distribution_type: Type de distribution
     |
     |      Returns:
     |          evaluation: Dictionnaire contenant l'évaluation détaillée
     |
     |  get_thresholds(self, context: str = 'default', distribution_type: Optional[str] = None) -> Dict[str, float]
     |      Obtient les seuils d'acceptabilité pour un contexte donné.
     |
     |      Args:
     |          context: Contexte d'analyse (monitoring, stability, etc.)
     |          distribution_type: Type de distribution (normal, asymmetric, etc.)
     |
     |      Returns:
     |          thresholds: Dictionnaire des seuils d'acceptabilité
     |
     |  save_custom_thresholds(self, thresholds: Dict[str, Dict[str, float]], config_path: str) -> bool
     |      Sauvegarde des seuils personnalisés dans un fichier de configuration.
     |
     |      Args:
     |          thresholds: Dictionnaire des seuils personnalisés
     |          config_path: Chemin du fichier de configuration
     |
     |      Returns:
     |          success: Booléen indiquant si la sauvegarde a réussi
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FUNCTIONS
    generate_default_config(output_path: str) -> bool
        Génère un fichier de configuration par défaut pour les seuils d'acceptabilité.

        Args:
            output_path: Chemin du fichier de sortie

        Returns:
            success: Booléen indiquant si la génération a réussi

DATA
    DISTRIBUTION_THRESHOLDS_AVAILABLE = False
    Dict = typing.Dict
        A generic version of dict.

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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\acceptability_thresholds.py


