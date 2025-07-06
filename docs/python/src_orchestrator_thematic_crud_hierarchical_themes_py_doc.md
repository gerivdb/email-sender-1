Help on module hierarchical_themes:

NAME
    hierarchical_themes - Module de gestion des th�mes hi�rarchiques.

DESCRIPTION
    Ce module fournit des fonctionnalit�s pour g�rer des th�mes organis�s de mani�re hi�rarchique,
    avec des relations parent-enfant entre les th�mes.

CLASSES
    builtins.object
        HierarchicalThemeManager

    class HierarchicalThemeManager(builtins.object)
     |  HierarchicalThemeManager(config_path: Optional[str] = None)
     |
     |  Gestionnaire de th�mes hi�rarchiques.
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: Optional[str] = None)
     |      Initialise le gestionnaire de th�mes hi�rarchiques.
     |
     |      Args:
     |          config_path: Chemin vers le fichier de configuration des th�mes (optionnel)
     |
     |  get_child_themes(self, theme: str) -> List[str]
     |      R�cup�re les th�mes enfants d'un th�me.
     |
     |      Args:
     |          theme: Th�me dont on veut r�cup�rer les enfants
     |
     |      Returns:
     |          Liste des th�mes enfants
     |
     |  get_parent_themes(self, theme: str) -> List[str]
     |      R�cup�re les th�mes parents d'un th�me.
     |
     |      Args:
     |          theme: Th�me dont on veut r�cup�rer les parents
     |
     |      Returns:
     |          Liste des th�mes parents
     |
     |  get_theme_keywords(self, theme: str) -> List[str]
     |      R�cup�re les mots-cl�s d'un th�me, y compris ceux h�rit�s de ses parents.
     |
     |      Args:
     |          theme: Th�me dont on veut r�cup�rer les mots-cl�s
     |
     |      Returns:
     |          Liste des mots-cl�s
     |
     |  get_theme_path(self, theme: str) -> List[str]
     |      R�cup�re le chemin complet d'un th�me dans la hi�rarchie.
     |
     |      Args:
     |          theme: Th�me dont on veut r�cup�rer le chemin
     |
     |      Returns:
     |          Liste des th�mes formant le chemin (du plus g�n�ral au plus sp�cifique)
     |
     |  propagate_theme_scores(self, theme_scores: Dict[str, float]) -> Dict[str, float]
     |      Propage les scores des th�mes � leurs parents et enfants.
     |
     |      Args:
     |          theme_scores: Dictionnaire des scores par th�me
     |
     |      Returns:
     |          Dictionnaire des scores propag�s
     |
     |  save_config(self, config_path: str) -> None
     |      Sauvegarde la configuration des th�mes dans un fichier.
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


