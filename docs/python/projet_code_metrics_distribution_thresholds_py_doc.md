Help on module distribution_thresholds:

NAME
    distribution_thresholds - Module de gestion des seuils adaptés par type de distribution.

DESCRIPTION
    Ce module permet de charger et d'utiliser les seuils définis pour différents types
    de distributions statistiques. Il fournit des fonctions pour obtenir les seuils
    appropriés en fonction du type de distribution et du contexte d'analyse.

CLASSES
    builtins.object
        DistributionThresholds

    class DistributionThresholds(builtins.object)
     |  DistributionThresholds(config_path: Optional[str] = None)
     |
     |  Classe pour gérer les seuils adaptés par type de distribution.
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: Optional[str] = None)
     |      Initialise la classe avec les seuils par défaut ou personnalisés.
     |
     |      Args:
     |          config_path: Chemin vers le fichier de configuration des seuils
     |
     |  get_context_description(self, context: str) -> str
     |      Obtient la description d'un contexte.
     |
     |      Args:
     |          context: Contexte
     |
     |      Returns:
     |          description: Description du contexte
     |
     |  get_contexts(self) -> List[str]
     |      Obtient la liste des contextes disponibles.
     |
     |      Returns:
     |          contexts: Liste des contextes
     |
     |  get_detection_criteria(self, distribution_type: str) -> Dict[str, Any]
     |      Obtient les critères de détection pour un type de distribution.
     |
     |      Args:
     |          distribution_type: Type de distribution
     |
     |      Returns:
     |          criteria: Dictionnaire des critères de détection
     |
     |  get_distribution_description(self, distribution_type: str) -> str
     |      Obtient la description d'un type de distribution.
     |
     |      Args:
     |          distribution_type: Type de distribution
     |
     |      Returns:
     |          description: Description du type de distribution
     |
     |  get_distribution_types(self) -> List[str]
     |      Obtient la liste des types de distribution disponibles.
     |
     |      Returns:
     |          types: Liste des types de distribution
     |
     |  get_gmci_thresholds(self, distribution_type: str, use_case: Optional[str] = None) -> Dict[str, float]
     |      Obtient les seuils GMCI (Global Moment Conservation Index) pour un type de distribution et un cas d'utilisation.
     |
     |      Args:
     |          distribution_type: Type de distribution
     |          use_case: Cas d'utilisation (optionnel)
     |
     |      Returns:
     |          thresholds: Dictionnaire des seuils GMCI
     |
     |  get_sample_size(self, distribution_type: str) -> int
     |      Obtient la taille d'échantillon recommandée pour un type de distribution.
     |
     |      Args:
     |          distribution_type: Type de distribution
     |
     |      Returns:
     |          sample_size: Taille d'échantillon recommandée
     |
     |  get_thresholds(self, distribution_type: str, context: str = 'default', use_case: Optional[str] = None) -> Dict[str, float]
     |      Obtient les seuils pour un type de distribution, un contexte et un cas d'utilisation donnés.
     |
     |      Args:
     |          distribution_type: Type de distribution
     |          context: Contexte d'analyse
     |          use_case: Cas d'utilisation (optionnel)
     |
     |      Returns:
     |          thresholds: Dictionnaire des seuils
     |
     |  get_use_case_description(self, use_case: str) -> str
     |      Obtient la description d'un cas d'utilisation.
     |
     |      Args:
     |          use_case: Cas d'utilisation
     |
     |      Returns:
     |          description: Description du cas d'utilisation
     |
     |  get_use_case_gmci_thresholds(self, distribution_type: str, use_case: str) -> Dict[str, float]
     |      Obtient les seuils GMCI spécifiques à un cas d'utilisation pour un type de distribution donné.
     |
     |      Args:
     |          distribution_type: Type de distribution
     |          use_case: Cas d'utilisation
     |
     |      Returns:
     |          thresholds: Dictionnaire des seuils GMCI spécifiques au cas d'utilisation
     |
     |  get_use_case_thresholds(self, distribution_type: str, use_case: str) -> Dict[str, float]
     |      Obtient les seuils spécifiques à un cas d'utilisation pour un type de distribution donné.
     |
     |      Args:
     |          distribution_type: Type de distribution
     |          use_case: Cas d'utilisation
     |
     |      Returns:
     |          thresholds: Dictionnaire des seuils spécifiques au cas d'utilisation
     |
     |  get_use_cases(self) -> List[str]
     |      Obtient la liste des cas d'utilisation disponibles.
     |
     |      Returns:
     |          use_cases: Liste des cas d'utilisation
     |
     |  save_thresholds(self, thresholds: Dict[str, Any]) -> bool
     |      Sauvegarde les seuils dans le fichier de configuration.
     |
     |      Args:
     |          thresholds: Dictionnaire des seuils
     |
     |      Returns:
     |          success: Booléen indiquant si la sauvegarde a réussi
     |
     |  update_context(self, context: str, config: Dict[str, Any]) -> bool
     |      Met à jour la configuration d'un contexte.
     |
     |      Args:
     |          context: Contexte
     |          config: Configuration du contexte
     |
     |      Returns:
     |          success: Booléen indiquant si la mise à jour a réussi
     |
     |  update_distribution_type(self, distribution_type: str, config: Dict[str, Any]) -> bool
     |      Met à jour la configuration d'un type de distribution.
     |
     |      Args:
     |          distribution_type: Type de distribution
     |          config: Configuration du type de distribution
     |
     |      Returns:
     |          success: Booléen indiquant si la mise à jour a réussi
     |
     |  update_use_case(self, use_case: str, config: Dict[str, Any]) -> bool
     |      Met à jour la configuration d'un cas d'utilisation.
     |
     |      Args:
     |          use_case: Cas d'utilisation
     |          config: Configuration du cas d'utilisation
     |
     |      Returns:
     |          success: Booléen indiquant si la mise à jour a réussi
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
    generate_default_config(output_path: str = 'D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\projet\\config\\distribution_thresholds.json') -> bool
        Génère un fichier de configuration par défaut pour les seuils par type de distribution.

        Args:
            output_path: Chemin du fichier de sortie

        Returns:
            success: Booléen indiquant si la génération a réussi

DATA
    DEFAULT_CONFIG_PATH = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\pro...
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\distribution_thresholds.py


