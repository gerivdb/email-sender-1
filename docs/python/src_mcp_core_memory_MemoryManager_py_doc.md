Help on module MemoryManager:

NAME
    MemoryManager - Module de gestion de m�moire pour MCP.

DESCRIPTION
    Ce module fournit une classe de base pour g�rer les m�moires dans le contexte MCP.
    Il permet d'ajouter, rechercher, lister et supprimer des m�moires.

CLASSES
    builtins.object
        MemoryManager

    class MemoryManager(builtins.object)
     |  MemoryManager(storage_path: str = None)
     |
     |  Gestionnaire de m�moire pour MCP.
     |
     |  Cette classe fournit les fonctionnalit�s de base pour g�rer les m�moires :
     |  - Ajouter des m�moires
     |  - Rechercher des m�moires
     |  - Lister les m�moires
     |  - Supprimer des m�moires
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str = None)
     |      Initialise le gestionnaire de m�moire.
     |
     |      Args:
     |          storage_path (str, optional): Chemin vers le fichier de stockage des m�moires.
     |              Si non sp�cifi�, utilise un emplacement par d�faut.
     |
     |  add_memory(self, content: str, metadata: Dict[str, Any] = None) -> str
     |      Ajoute une nouvelle m�moire.
     |
     |      Args:
     |          content (str): Contenu de la m�moire
     |          metadata (Dict[str, Any], optional): M�tadonn�es associ�es � la m�moire
     |
     |      Returns:
     |          str: Identifiant unique de la m�moire cr��e
     |
     |  delete_memory(self, memory_id: str) -> bool
     |      Supprime une m�moire.
     |
     |      Args:
     |          memory_id (str): Identifiant de la m�moire � supprimer
     |
     |      Returns:
     |          bool: True si la suppression a r�ussi, False sinon
     |
     |  get_memory(self, memory_id: str) -> Optional[Dict[str, Any]]
     |      R�cup�re une m�moire par son ID.
     |
     |      Args:
     |          memory_id (str): Identifiant de la m�moire � r�cup�rer
     |
     |      Returns:
     |          Optional[Dict[str, Any]]: La m�moire si trouv�e, None sinon
     |
     |  list_memories(self, filter_func: Callable[[Dict[str, Any]], bool] = None) -> List[Dict[str, Any]]
     |      Liste toutes les m�moires, avec filtrage optionnel.
     |
     |      Args:
     |          filter_func (Callable[[Dict[str, Any]], bool], optional):
     |              Fonction de filtrage qui prend une m�moire et retourne True si elle doit �tre incluse
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des m�moires correspondant au filtre
     |
     |  search_memory(self, query: str, limit: int = 5) -> List[Dict[str, Any]]
     |      Recherche des m�moires par correspondance simple.
     |
     |      Note: Cette impl�mentation est basique et utilise une recherche textuelle simple.
     |      Pour une recherche plus avanc�e, il faudrait int�grer une base de donn�es vectorielle.
     |
     |      Args:
     |          query (str): Requ�te de recherche
     |          limit (int, optional): Nombre maximum de r�sultats � retourner
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des m�moires correspondant � la requ�te
     |
     |  update_memory(self, memory_id: str, content: str = None, metadata: Dict[str, Any] = None) -> bool
     |      Met � jour une m�moire existante.
     |
     |      Args:
     |          memory_id (str): Identifiant de la m�moire � mettre � jour
     |          content (str, optional): Nouveau contenu de la m�moire
     |          metadata (Dict[str, Any], optional): Nouvelles m�tadonn�es � fusionner
     |
     |      Returns:
     |          bool: True si la mise � jour a r�ussi, False sinon
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


