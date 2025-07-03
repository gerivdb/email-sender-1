Help on module memory_manager:

NAME
    memory_manager - Module pour la gestion des m�moires MCP.

DESCRIPTION
    Ce module contient les classes et fonctions pour g�rer les m�moires MCP,
    notamment le stockage, la recherche et la gestion du cycle de vie des m�moires.

CLASSES
    builtins.object
        Memory
        MemoryManager

    class Memory(builtins.object)
     |  Memory(content: str, metadata: Optional[Dict[str, Any]] = None, memory_id: Optional[str] = None, embedding: Optional[List[float]] = None)
     |
     |  Classe repr�sentant une m�moire.
     |
     |  Une m�moire contient un contenu textuel, des m�tadonn�es et un embedding vectoriel.
     |
     |  Methods defined here:
     |
     |  __init__(self, content: str, metadata: Optional[Dict[str, Any]] = None, memory_id: Optional[str] = None, embedding: Optional[List[float]] = None)
     |      Initialise une m�moire.
     |
     |      Args:
     |          content (str): Contenu textuel de la m�moire
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es de la m�moire. Par d�faut None.
     |          memory_id (Optional[str], optional): Identifiant de la m�moire. Si None, un UUID est g�n�r�.
     |          embedding (Optional[List[float]], optional): Embedding vectoriel de la m�moire. Par d�faut None.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit la m�moire en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant la m�moire
     |
     |  update_content(self, content: str) -> None
     |      Met � jour le contenu de la m�moire.
     |
     |      Args:
     |          content (str): Nouveau contenu
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met � jour les m�tadonn�es de la m�moire.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles m�tadonn�es � fusionner avec les existantes
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'Memory'
     |      Cr�e une m�moire � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant la m�moire
     |
     |      Returns:
     |          Memory: Instance de m�moire
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class MemoryManager(builtins.object)
     |  MemoryManager(storage_provider=None, embedding_provider=None)
     |
     |  Gestionnaire des m�moires MCP.
     |
     |  Cette classe g�re le stockage, la recherche et le cycle de vie des m�moires.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_provider=None, embedding_provider=None)
     |      Initialise le gestionnaire de m�moires.
     |
     |      Args:
     |          storage_provider: Fournisseur de stockage pour les m�moires
     |          embedding_provider: Fournisseur d'embeddings pour les m�moires
     |
     |  add_memory(self, content: str, metadata: Optional[Dict[str, Any]] = None) -> str
     |      Ajoute une nouvelle m�moire.
     |
     |      Args:
     |          content (str): Contenu textuel de la m�moire
     |          metadata (Optional[Dict[str, Any]], optional): M�tadonn�es de la m�moire. Par d�faut None.
     |
     |      Returns:
     |          str: Identifiant de la m�moire ajout�e
     |
     |  delete_memory(self, memory_id: str) -> bool
     |      Supprime une m�moire.
     |
     |      Args:
     |          memory_id (str): Identifiant de la m�moire
     |
     |      Returns:
     |          bool: True si la suppression a r�ussi, False sinon
     |
     |  get_memory(self, memory_id: str) -> Optional[memory_manager.Memory]
     |      R�cup�re une m�moire par son identifiant.
     |
     |      Args:
     |          memory_id (str): Identifiant de la m�moire
     |
     |      Returns:
     |          Optional[Memory]: M�moire r�cup�r�e, ou None si elle n'existe pas
     |
     |  list_memories(self, metadata_filter: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[memory_manager.Memory]
     |      Liste les m�moires, �ventuellement filtr�es par m�tadonn�es.
     |
     |      Args:
     |          metadata_filter (Optional[Dict[str, Any]], optional): Filtre sur les m�tadonn�es. Par d�faut None.
     |          limit (int, optional): Nombre maximum de r�sultats. Par d�faut 100.
     |          offset (int, optional): D�calage pour la pagination. Par d�faut 0.
     |
     |      Returns:
     |          List[Memory]: Liste des m�moires
     |
     |  search_memories(self, query: str, limit: int = 10, metadata_filter: Optional[Dict[str, Any]] = None) -> List[Tuple[memory_manager.Memory, float]]
     |      Recherche des m�moires par similarit� s�mantique.
     |
     |      Args:
     |          query (str): Requ�te de recherche
     |          limit (int, optional): Nombre maximum de r�sultats. Par d�faut 10.
     |          metadata_filter (Optional[Dict[str, Any]], optional): Filtre sur les m�tadonn�es. Par d�faut None.
     |
     |      Returns:
     |          List[Tuple[Memory, float]]: Liste de tuples (m�moire, score) tri�s par score d�croissant
     |
     |  update_memory(self, memory_id: str, content: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None) -> bool
     |      Met � jour une m�moire existante.
     |
     |      Args:
     |          memory_id (str): Identifiant de la m�moire
     |          content (Optional[str], optional): Nouveau contenu. Par d�faut None.
     |          metadata (Optional[Dict[str, Any]], optional): Nouvelles m�tadonn�es. Par d�faut None.
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
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

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

    logger = <Logger mcp.core.memory_manager (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\mcp\memory_manager.py


