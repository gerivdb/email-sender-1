Help on module theme_change_detector:

NAME
    theme_change_detector - Module de détection des changements thématiques.

DESCRIPTION
    Ce module fournit des fonctionnalités pour détecter et analyser les changements
    thématiques dans les éléments au fil du temps.

CLASSES
    builtins.object
        ThemeChangeDetector

    class ThemeChangeDetector(builtins.object)
     |  ThemeChangeDetector(themes_config_path: Optional[str] = None, significance_threshold: float = 0.2)
     |
     |  Classe pour la détection et l'analyse des changements thématiques.
     |
     |  Methods defined here:
     |
     |  __init__(self, themes_config_path: Optional[str] = None, significance_threshold: float = 0.2)
     |      Initialise le détecteur de changements thématiques.
     |
     |      Args:
     |          themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
     |          significance_threshold: Seuil de significativité pour les changements (défaut: 0.2)
     |
     |  analyze_theme_evolution(self, theme_history: List[Dict[str, Any]]) -> Dict[str, Any]
     |      Analyse l'évolution des thèmes au fil du temps.
     |
     |      Args:
     |          theme_history: Liste des thèmes attribués à différents moments
     |
     |      Returns:
     |          Analyse de l'évolution thématique
     |
     |  detect_changes(self, old_themes: Dict[str, float], new_themes: Dict[str, float]) -> Dict[str, Any]
     |      Détecte les changements thématiques entre deux ensembles de thèmes.
     |
     |      Args:
     |          old_themes: Anciens thèmes avec leurs scores
     |          new_themes: Nouveaux thèmes avec leurs scores
     |
     |      Returns:
     |          Dictionnaire des changements thématiques
     |
     |  detect_theme_drift(self, original_themes: Dict[str, float], current_themes: Dict[str, float]) -> Dict[str, Any]
     |      Détecte la dérive thématique entre les thèmes originaux et actuels.
     |
     |      Args:
     |          original_themes: Thèmes originaux avec leurs scores
     |          current_themes: Thèmes actuels avec leurs scores
     |
     |      Returns:
     |          Analyse de la dérive thématique
     |
     |  suggest_theme_corrections(self, content: str, current_themes: Dict[str, float], expected_themes: Optional[List[str]] = None) -> Dict[str, Any]
     |      Suggère des corrections thématiques basées sur le contenu et les attentes.
     |
     |      Args:
     |          content: Contenu de l'élément
     |          current_themes: Thèmes actuels avec leurs scores
     |          expected_themes: Thèmes attendus (optionnel)
     |
     |      Returns:
     |          Suggestions de corrections thématiques
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

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\theme_change_detector.py


