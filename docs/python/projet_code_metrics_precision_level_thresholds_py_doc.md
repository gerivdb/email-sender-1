Help on module precision_level_thresholds:

NAME
    precision_level_thresholds - Module pour définir des seuils généraux par niveau de précision.

CLASSES
    builtins.object
        PrecisionLevelThresholds

    class PrecisionLevelThresholds(builtins.object)
     |  PrecisionLevelThresholds(config_path: Optional[str] = None)
     |
     |  Classe pour gérer les seuils généraux par niveau de précision.
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: Optional[str] = None)
     |      Initialise les seuils par niveau de précision.
     |
     |      Args:
     |          config_path: Chemin vers le fichier de configuration des seuils
     |
     |  add_custom_precision_level(self, level_name: str, level_config: Dict[str, Union[str, float]]) -> bool
     |      Ajoute un niveau de précision personnalisé.
     |
     |      Args:
     |          level_name: Nom du niveau de précision
     |          level_config: Configuration du niveau de précision
     |
     |      Returns:
     |          success: Booléen indiquant si l'ajout a réussi
     |
     |  get_all_precision_levels(self) -> Dict[str, Dict[str, Union[str, float]]]
     |      Obtient tous les niveaux de précision disponibles.
     |
     |      Returns:
     |          all_levels: Dictionnaire de tous les niveaux de précision
     |
     |  get_bin_count_recommendation(self, precision_level: str, sample_size: int) -> int
     |      Recommande un nombre de bins pour un niveau de précision et une taille d'échantillon donnés.
     |
     |      Args:
     |          precision_level: Niveau de précision
     |          sample_size: Taille de l'échantillon
     |
     |      Returns:
     |          bin_count: Nombre de bins recommandé
     |
     |  get_confidence_interval(self, precision_level: str) -> float
     |      Obtient l'intervalle de confiance pour un niveau de précision donné.
     |
     |      Args:
     |          precision_level: Niveau de précision
     |
     |      Returns:
     |          confidence_interval: Intervalle de confiance
     |
     |  get_precision_level(self, level_name: str) -> Dict[str, Union[str, float]]
     |      Obtient les seuils pour un niveau de précision donné.
     |
     |      Args:
     |          level_name: Nom du niveau de précision
     |
     |      Returns:
     |          level_config: Configuration du niveau de précision
     |
     |  get_sample_size_recommendation(self, precision_level: str, distribution_type: str = 'normal') -> int
     |      Recommande une taille d'échantillon minimale pour un niveau de précision donné.
     |
     |      Args:
     |          precision_level: Niveau de précision
     |          distribution_type: Type de distribution
     |
     |      Returns:
     |          sample_size: Taille d'échantillon recommandée
     |
     |  get_thresholds_for_context(self, precision_level: str, context: str) -> Dict[str, float]
     |      Obtient les seuils pour un niveau de précision et un contexte donnés.
     |
     |      Args:
     |          precision_level: Niveau de précision
     |          context: Contexte d'analyse
     |
     |      Returns:
     |          thresholds: Dictionnaire des seuils
     |
     |  save_custom_levels(self, config_path: str) -> bool
     |      Sauvegarde les niveaux de précision personnalisés dans un fichier de configuration.
     |
     |      Args:
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
        Génère un fichier de configuration par défaut pour les niveaux de précision.

        Args:
            output_path: Chemin du fichier de sortie

        Returns:
            success: Booléen indiquant si la génération a réussi

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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\precision_level_thresholds.py


