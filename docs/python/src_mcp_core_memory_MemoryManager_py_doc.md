Help on module MemoryManager:

NAME
    MemoryManager - Module de gestion de mémoire pour MCP.

DESCRIPTION
    Ce module fournit une classe de base pour gérer les mémoires dans le contexte MCP.
    Il permet d'ajouter, rechercher, lister et supprimer des mémoires.

CLASSES
    builtins.object
        MemoryManager

    class MemoryManager(builtins.object)
     |  MemoryManager(storage_path: str = None)
     |
     |  Gestionnaire de mémoire pour MCP.
     |
     |  Cette classe fournit les fonctionnalités de base pour gérer les mémoires :
     |  - Ajouter des mémoires
     |  - Rechercher des mémoires
     |  - Lister les mémoires
     |  - Supprimer des mémoires
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str = None)
     |      Initialise le gestionnaire de mémoire.
     |
     |      Args:
     |          storage_path (str, optional): Chemin vers le fichier de stockage des mémoires.
     |              Si non spécifié, utilise un emplacement par défaut.
     |
     |  add_memory(self, content: str, metadata: Dict[str, Any] = None) -> str
     |      Ajoute une nouvelle mémoire.
     |
     |      Args:
     |          content (str): Contenu de la mémoire
     |          metadata (Dict[str, Any], optional): Métadonnées associées à la mémoire
     |
     |      Returns:
     |          str: Identifiant unique de la mémoire créée
     |
     |  delete_memory(self, memory_id: str) -> bool
     |      Supprime une mémoire.
     |
     |      Args:
     |          memory_id (str): Identifiant de la mémoire à supprimer
     |
     |      Returns:
     |          bool: True si la suppression a réussi, False sinon
     |
     |  get_memory(self, memory_id: str) -> Optional[Dict[str, Any]]
     |      Récupère une mémoire par son ID.
     |
     |      Args:
     |          memory_id (str): Identifiant de la mémoire à récupérer
     |
     |      Returns:
     |          Optional[Dict[str, Any]]: La mémoire si trouvée, None sinon
     |
     |  list_memories(self, filter_func: Callable[[Dict[str, Any]], bool] = None) -> List[Dict[str, Any]]
     |      Liste toutes les mémoires, avec filtrage optionnel.
     |
     |      Args:
     |          filter_func (Callable[[Dict[str, Any]], bool], optional):
     |              Fonction de filtrage qui prend une mémoire et retourne True si elle doit être incluse
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des mémoires correspondant au filtre
     |
     |  search_memory(self, query: str, limit: int = 5) -> List[Dict[str, Any]]
     |      Recherche des mémoires par correspondance simple.
     |
     |      Note: Cette implémentation est basique et utilise une recherche textuelle simple.
     |      Pour une recherche plus avancée, il faudrait intégrer une base de données vectorielle.
     |
     |      Args:
     |          query (str): Requête de recherche
     |          limit (int, optional): Nombre maximum de résultats à retourner
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des mémoires correspondant à la requête
     |
     |  update_memory(self, memory_id: str, content: str = None, metadata: Dict[str, Any] = None) -> bool
     |      Met à jour une mémoire existante.
     |
     |      Args:
     |          memory_id (str): Identifiant de la mémoire à mettre à jour
     |          content (str, optional): Nouveau contenu de la mémoire
     |          metadata (Dict[str, Any], optional): Nouvelles métadonnées à fusionner
     |
     |      Returns:
     |          bool: True si la mise à jour a réussi, False sinon
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
    Callable = typing.Callable
        Deprecated alias to collections.abc.Callable.

        Callable[[int], str] signifies a function that takes a single
        parameter of type int and returns a str.

        The subscription syntax must always be used with exactly two
        values: the argument list and the return type.
        The argument list must be a list of types, a ParamSpec,
        Concatenate or ellipsis. The return type must be a single type.

        There is no syntax to indicate optional or keyword arguments;
        such function types are rarely used as callback types.

    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

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

    logger = <Logger mcp.memory (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\memory\memorymanager.py


