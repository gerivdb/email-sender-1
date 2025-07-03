Help on module theme_attribution:

NAME
    theme_attribution - Module d'attribution thématique automatique.

DESCRIPTION
    Ce module fournit des fonctionnalités pour attribuer automatiquement des thèmes
    à des éléments de roadmap en fonction de leur contenu et de leurs métadonnées.

CLASSES
    builtins.object
        ThemeAttributor

    class ThemeAttributor(builtins.object)
     |  ThemeAttributor(themes_config_path: Optional[str] = None)
     |
     |  Classe pour l'attribution automatique de thèmes.
     |
     |  Methods defined here:
     |
     |  __init__(self, themes_config_path: Optional[str] = None)
     |      Initialise l'attributeur de thèmes.
     |
     |      Args:
     |          themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
     |
     |  attribute_theme(self, content: str, metadata: Optional[Dict[str, Any]] = None) -> Dict[str, float]
     |      Attribue des thèmes à un contenu en fonction de sa similarité avec les thèmes connus.
     |
     |      Args:
     |          content: Contenu textuel à analyser
     |          metadata: Métadonnées associées au contenu (optionnel)
     |
     |      Returns:
     |          Dictionnaire des thèmes attribués avec leur score de confiance
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

    SKLEARN_AVAILABLE = True
    Set = typing.Set
        A generic version of set.

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
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\theme_attribution.py


