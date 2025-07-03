Help on module thematic_views:

NAME
    thematic_views - Module de vues th�matiques personnalis�es.

DESCRIPTION
    Ce module fournit des fonctionnalit�s pour cr�er et g�rer des vues
    personnalis�es bas�es sur des th�mes et des crit�res de recherche.

CLASSES
    builtins.object
        ThematicView
        ThematicViewManager

    class ThematicView(builtins.object)
     |  ThematicView(name: str, description: str = '', search_criteria: Optional[Dict[str, Any]] = None)
     |
     |  Classe repr�sentant une vue th�matique personnalis�e.
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, description: str = '', search_criteria: Optional[Dict[str, Any]] = None)
     |      Initialise une vue th�matique personnalis�e.
     |
     |      Args:
     |          name: Nom de la vue
     |          description: Description de la vue (optionnel)
     |          search_criteria: Crit�res de recherche pour la vue (optionnel)
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit la vue en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire repr�sentant la vue
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'ThematicView'
     |      Cr�e une vue � partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire repr�sentant la vue
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
     |  Classe pour g�rer les vues th�matiques personnalis�es.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, views_path: Optional[str] = None)
     |      Initialise le gestionnaire de vues th�matiques.
     |
     |      Args:
     |          storage_path: Chemin vers le r�pertoire de stockage des donn�es
     |          views_path: Chemin vers le r�pertoire de stockage des vues (optionnel)
     |
     |  clone_view(self, view_id: str, new_name: Optional[str] = None) -> Optional[thematic_views.ThematicView]
     |      Clone une vue th�matique existante.
     |
     |      Args:
     |          view_id: Identifiant de la vue � cloner
     |          new_name: Nouveau nom pour la vue clon�e (optionnel)
     |
     |      Returns:
     |          Vue th�matique clon�e ou None si la vue source n'existe pas
     |
     |  create_view(self, name: str, description: str = '', search_criteria: Optional[Dict[str, Any]] = None) -> thematic_views.ThematicView
     |      Cr�e une nouvelle vue th�matique.
     |
     |      Args:
     |          name: Nom de la vue
     |          description: Description de la vue (optionnel)
     |          search_criteria: Crit�res de recherche pour la vue (optionnel)
     |
     |      Returns:
     |          Vue th�matique cr��e
     |
     |  delete_view(self, view_id: str) -> bool
     |      Supprime une vue th�matique.
     |
     |      Args:
     |          view_id: Identifiant de la vue � supprimer
     |
     |      Returns:
     |          True si la vue a �t� supprim�e, False sinon
     |
     |  execute_view(self, view_id: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Ex�cute une vue th�matique pour r�cup�rer les �l�ments correspondants.
     |
     |      Args:
     |          view_id: Identifiant de la vue � ex�cuter
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant aux crit�res de la vue
     |
     |  get_all_views(self) -> List[thematic_views.ThematicView]
     |      R�cup�re toutes les vues th�matiques.
     |
     |      Returns:
     |          Liste des vues th�matiques
     |
     |  get_view(self, view_id: str) -> Optional[thematic_views.ThematicView]
     |      R�cup�re une vue th�matique par son identifiant.
     |
     |      Args:
     |          view_id: Identifiant de la vue � r�cup�rer
     |
     |      Returns:
     |          Vue th�matique ou None si la vue n'existe pas
     |
     |  update_view(self, view_id: str, name: Optional[str] = None, description: Optional[str] = None, search_criteria: Optional[Dict[str, Any]] = None) -> Optional[thematic_views.ThematicView]
     |      Met � jour une vue th�matique existante.
     |
     |      Args:
     |          view_id: Identifiant de la vue � mettre � jour
     |          name: Nouveau nom de la vue (optionnel)
     |          description: Nouvelle description de la vue (optionnel)
     |          search_criteria: Nouveaux crit�res de recherche pour la vue (optionnel)
     |
     |      Returns:
     |          Vue th�matique mise � jour ou None si la vue n'existe pas
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


