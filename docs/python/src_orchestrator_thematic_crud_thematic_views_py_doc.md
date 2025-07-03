Help on module thematic_views:

NAME
    thematic_views - Module de vues thématiques personnalisées.

DESCRIPTION
    Ce module fournit des fonctionnalités pour créer et gérer des vues
    personnalisées basées sur des thèmes et des critères de recherche.

CLASSES
    builtins.object
        ThematicView
        ThematicViewManager

    class ThematicView(builtins.object)
     |  ThematicView(name: str, description: str = '', search_criteria: Optional[Dict[str, Any]] = None)
     |
     |  Classe représentant une vue thématique personnalisée.
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, description: str = '', search_criteria: Optional[Dict[str, Any]] = None)
     |      Initialise une vue thématique personnalisée.
     |
     |      Args:
     |          name: Nom de la vue
     |          description: Description de la vue (optionnel)
     |          search_criteria: Critères de recherche pour la vue (optionnel)
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit la vue en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire représentant la vue
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'ThematicView'
     |      Crée une vue à partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire représentant la vue
     |
     |      Returns:
     |          Instance de ThematicView
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class ThematicViewManager(builtins.object)
     |  ThematicViewManager(storage_path: str, views_path: Optional[str] = None)
     |
     |  Classe pour gérer les vues thématiques personnalisées.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, views_path: Optional[str] = None)
     |      Initialise le gestionnaire de vues thématiques.
     |
     |      Args:
     |          storage_path: Chemin vers le répertoire de stockage des données
     |          views_path: Chemin vers le répertoire de stockage des vues (optionnel)
     |
     |  clone_view(self, view_id: str, new_name: Optional[str] = None) -> Optional[thematic_views.ThematicView]
     |      Clone une vue thématique existante.
     |
     |      Args:
     |          view_id: Identifiant de la vue à cloner
     |          new_name: Nouveau nom pour la vue clonée (optionnel)
     |
     |      Returns:
     |          Vue thématique clonée ou None si la vue source n'existe pas
     |
     |  create_view(self, name: str, description: str = '', search_criteria: Optional[Dict[str, Any]] = None) -> thematic_views.ThematicView
     |      Crée une nouvelle vue thématique.
     |
     |      Args:
     |          name: Nom de la vue
     |          description: Description de la vue (optionnel)
     |          search_criteria: Critères de recherche pour la vue (optionnel)
     |
     |      Returns:
     |          Vue thématique créée
     |
     |  delete_view(self, view_id: str) -> bool
     |      Supprime une vue thématique.
     |
     |      Args:
     |          view_id: Identifiant de la vue à supprimer
     |
     |      Returns:
     |          True si la vue a été supprimée, False sinon
     |
     |  execute_view(self, view_id: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Exécute une vue thématique pour récupérer les éléments correspondants.
     |
     |      Args:
     |          view_id: Identifiant de la vue à exécuter
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments correspondant aux critères de la vue
     |
     |  get_all_views(self) -> List[thematic_views.ThematicView]
     |      Récupère toutes les vues thématiques.
     |
     |      Returns:
     |          Liste des vues thématiques
     |
     |  get_view(self, view_id: str) -> Optional[thematic_views.ThematicView]
     |      Récupère une vue thématique par son identifiant.
     |
     |      Args:
     |          view_id: Identifiant de la vue à récupérer
     |
     |      Returns:
     |          Vue thématique ou None si la vue n'existe pas
     |
     |  update_view(self, view_id: str, name: Optional[str] = None, description: Optional[str] = None, search_criteria: Optional[Dict[str, Any]] = None) -> Optional[thematic_views.ThematicView]
     |      Met à jour une vue thématique existante.
     |
     |      Args:
     |          view_id: Identifiant de la vue à mettre à jour
     |          name: Nouveau nom de la vue (optionnel)
     |          description: Nouvelle description de la vue (optionnel)
     |          search_criteria: Nouveaux critères de recherche pour la vue (optionnel)
     |
     |      Returns:
     |          Vue thématique mise à jour ou None si la vue n'existe pas
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\thematic_views.py


