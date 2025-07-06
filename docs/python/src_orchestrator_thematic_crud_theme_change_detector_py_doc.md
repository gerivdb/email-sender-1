Help on module theme_change_detector:

NAME
    theme_change_detector - Module de d�tection des changements th�matiques.

DESCRIPTION
    Ce module fournit des fonctionnalit�s pour d�tecter et analyser les changements
    th�matiques dans les �l�ments au fil du temps.

CLASSES
    builtins.object
        ThemeChangeDetector

    class ThemeChangeDetector(builtins.object)
     |  ThemeChangeDetector(themes_config_path: Optional[str] = None, significance_threshold: float = 0.2)
     |
     |  Classe pour la d�tection et l'analyse des changements th�matiques.
     |
     |  Methods defined here:
     |
     |  __init__(self, themes_config_path: Optional[str] = None, significance_threshold: float = 0.2)
     |      Initialise le d�tecteur de changements th�matiques.
     |
     |      Args:
     |          themes_config_path: Chemin vers le fichier de configuration des th�mes (optionnel)
     |          significance_threshold: Seuil de significativit� pour les changements (d�faut: 0.2)
     |
     |  analyze_theme_evolution(self, theme_history: List[Dict[str, Any]]) -> Dict[str, Any]
     |      Analyse l'�volution des th�mes au fil du temps.
     |
     |      Args:
     |          theme_history: Liste des th�mes attribu�s � diff�rents moments
     |
     |      Returns:
     |          Analyse de l'�volution th�matique
     |
     |  detect_changes(self, old_themes: Dict[str, float], new_themes: Dict[str, float]) -> Dict[str, Any]
     |      D�tecte les changements th�matiques entre deux ensembles de th�mes.
     |
     |      Args:
     |          old_themes: Anciens th�mes avec leurs scores
     |          new_themes: Nouveaux th�mes avec leurs scores
     |
     |      Returns:
     |          Dictionnaire des changements th�matiques
     |
     |  detect_theme_drift(self, original_themes: Dict[str, float], current_themes: Dict[str, float]) -> Dict[str, Any]
     |      D�tecte la d�rive th�matique entre les th�mes originaux et actuels.
     |
     |      Args:
     |          original_themes: Th�mes originaux avec leurs scores
     |          current_themes: Th�mes actuels avec leurs scores
     |
     |      Returns:
     |          Analyse de la d�rive th�matique
     |
     |  suggest_theme_corrections(self, content: str, current_themes: Dict[str, float], expected_themes: Optional[List[str]] = None) -> Dict[str, Any]
     |      Sugg�re des corrections th�matiques bas�es sur le contenu et les attentes.
     |
     |      Args:
     |          content: Contenu de l'�l�ment
     |          current_themes: Th�mes actuels avec leurs scores
     |          expected_themes: Th�mes attendus (optionnel)
     |
     |      Returns:
     |          Suggestions de corrections th�matiques
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


