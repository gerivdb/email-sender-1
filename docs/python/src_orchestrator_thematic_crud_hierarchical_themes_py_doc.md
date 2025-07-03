Help on module hierarchical_themes:

NAME
    hierarchical_themes - Module de gestion des thèmes hiérarchiques.

DESCRIPTION
    Ce module fournit des fonctionnalités pour gérer des thèmes organisés de manière hiérarchique,
    avec des relations parent-enfant entre les thèmes.

CLASSES
    builtins.object
        HierarchicalThemeManager

    class HierarchicalThemeManager(builtins.object)
     |  HierarchicalThemeManager(config_path: Optional[str] = None)
     |
     |  Gestionnaire de thèmes hiérarchiques.
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: Optional[str] = None)
     |      Initialise le gestionnaire de thèmes hiérarchiques.
     |
     |      Args:
     |          config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
     |
     |  get_child_themes(self, theme: str) -> List[str]
     |      Récupère les thèmes enfants d'un thème.
     |
     |      Args:
     |          theme: Thème dont on veut récupérer les enfants
     |
     |      Returns:
     |          Liste des thèmes enfants
     |
     |  get_parent_themes(self, theme: str) -> List[str]
     |      Récupère les thèmes parents d'un thème.
     |
     |      Args:
     |          theme: Thème dont on veut récupérer les parents
     |
     |      Returns:
     |          Liste des thèmes parents
     |
     |  get_theme_keywords(self, theme: str) -> List[str]
     |      Récupère les mots-clés d'un thème, y compris ceux hérités de ses parents.
     |
     |      Args:
     |          theme: Thème dont on veut récupérer les mots-clés
     |
     |      Returns:
     |          Liste des mots-clés
     |
     |  get_theme_path(self, theme: str) -> List[str]
     |      Récupère le chemin complet d'un thème dans la hiérarchie.
     |
     |      Args:
     |          theme: Thème dont on veut récupérer le chemin
     |
     |      Returns:
     |          Liste des thèmes formant le chemin (du plus général au plus spécifique)
     |
     |  propagate_theme_scores(self, theme_scores: Dict[str, float]) -> Dict[str, float]
     |      Propage les scores des thèmes à leurs parents et enfants.
     |
     |      Args:
     |          theme_scores: Dictionnaire des scores par thème
     |
     |      Returns:
     |          Dictionnaire des scores propagés
     |
     |  save_config(self, config_path: str) -> None
     |      Sauvegarde la configuration des thèmes dans un fichier.
     |
     |      Args:
     |          config_path: Chemin vers le fichier de configuration
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Set = typing.Set
        A generic version of set.

    Tuple = typing.Tuple
        Deprecated alias to builtins.tuple.

        Tuple[X, Y] is the cross-product type of X and Y.

        Example: Tuple[T1, T2] is a tuple of two elements corresponding
        to type variables T1 and T2.  Tuple[int, float, str] is a tuple
        of an int, a float and a string.

        To specify a variable-length tuple of homogeneous type, use Tuple[T, ...].

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\hierarchical_themes.py


