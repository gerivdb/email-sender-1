Help on module selective_update:

NAME
    selective_update - Module de mise à jour sélective par thème.

DESCRIPTION
    Ce module fournit des fonctionnalités pour mettre à jour sélectivement des
    éléments en fonction de leurs thèmes.

CLASSES
    builtins.object
        ThematicSectionExtractor
        ThematicSelectiveUpdate

    class ThematicSectionExtractor(builtins.object)
     |  ThematicSectionExtractor(themes_config_path: Optional[str] = None)
     |
     |  Classe pour l'extraction de sections thématiques dans le contenu.
     |
     |  Methods defined here:
     |
     |  __init__(self, themes_config_path: Optional[str] = None)
     |      Initialise l'extracteur de sections thématiques.
     |
     |      Args:
     |          themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
     |
     |  extract_section_by_theme(self, content: str, theme: str, min_score: float = 0.3) -> List[Dict[str, Any]]
     |      Extrait les sections correspondant à un thème spécifique.
     |
     |      Args:
     |          content: Contenu à analyser
     |          theme: Thème à rechercher
     |          min_score: Score minimum pour considérer qu'une section appartient au thème
     |
     |      Returns:
     |          Liste des sections correspondant au thème
     |
     |  extract_sections(self, content: str) -> Dict[str, List[Dict[str, Any]]]
     |      Extrait les sections thématiques d'un contenu.
     |
     |      Args:
     |          content: Contenu à analyser
     |
     |      Returns:
     |          Dictionnaire des sections par thème
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class ThematicSelectiveUpdate(builtins.object)
     |  ThematicSelectiveUpdate(storage_path: str, themes_config_path: Optional[str] = None)
     |
     |  Classe pour la mise à jour sélective par thème.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, themes_config_path: Optional[str] = None)
     |      Initialise le gestionnaire de mise à jour sélective par thème.
     |
     |      Args:
     |          storage_path: Chemin vers le répertoire de stockage des données
     |          themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
     |
     |  extract_and_update_theme(self, source_item_id: str, target_item_id: str, theme: str) -> Optional[Dict[str, Any]]
     |      Extrait les sections d'un thème d'un élément source et les applique à un élément cible.
     |
     |      Args:
     |          source_item_id: Identifiant de l'élément source
     |          target_item_id: Identifiant de l'élément cible
     |          theme: Thème à extraire et appliquer
     |
     |      Returns:
     |          Élément cible mis à jour ou None si l'un des éléments n'existe pas
     |
     |  merge_theme_content(self, item_id: str, theme: str, content_to_merge: str) -> Optional[Dict[str, Any]]
     |      Fusionne du contenu dans les sections d'un élément correspondant à un thème.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          theme: Thème des sections à mettre à jour
     |          content_to_merge: Contenu à fusionner
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  update_multiple_themes(self, item_id: str, theme_updates: Dict[str, str]) -> Optional[Dict[str, Any]]
     |      Met à jour plusieurs thèmes d'un élément en une seule opération.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          theme_updates: Dictionnaire des thèmes à mettre à jour avec leur nouveau contenu
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  update_theme_sections(self, item_id: str, theme: str, new_content: str) -> Optional[Dict[str, Any]]
     |      Met à jour les sections d'un élément correspondant à un thème spécifique.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          theme: Thème des sections à mettre à jour
     |          new_content: Nouveau contenu pour les sections
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\selective_update.py


