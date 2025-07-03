Help on module memory_manager:

NAME
    memory_manager - Module pour la gestion des mémoires MCP.

DESCRIPTION
    Ce module contient les classes et fonctions pour gérer les mémoires MCP,
    notamment le stockage, la recherche et la gestion du cycle de vie des mémoires.

CLASSES
    builtins.object
        Memory
        MemoryManager

    class Memory(builtins.object)
     |  Memory(content: str, metadata: Optional[Dict[str, Any]] = None, memory_id: Optional[str] = None, embedding: Optional[List[float]] = None)
     |
     |  Classe représentant une mémoire.
     |
     |  Une mémoire contient un contenu textuel, des métadonnées et un embedding vectoriel.
     |
     |  Methods defined here:
     |
     |  __init__(self, content: str, metadata: Optional[Dict[str, Any]] = None, memory_id: Optional[str] = None, embedding: Optional[List[float]] = None)
     |      Initialise une mémoire.
     |
     |      Args:
     |          content (str): Contenu textuel de la mémoire
     |          metadata (Optional[Dict[str, Any]], optional): Métadonnées de la mémoire. Par défaut None.
     |          memory_id (Optional[str], optional): Identifiant de la mémoire. Si None, un UUID est généré.
     |          embedding (Optional[List[float]], optional): Embedding vectoriel de la mémoire. Par défaut None.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit la mémoire en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire représentant la mémoire
     |
     |  update_content(self, content: str) -> None
     |      Met à jour le contenu de la mémoire.
     |
     |      Args:
     |          content (str): Nouveau contenu
     |
     |  update_metadata(self, metadata: Dict[str, Any]) -> None
     |      Met à jour les métadonnées de la mémoire.
     |
     |      Args:
     |          metadata (Dict[str, Any]): Nouvelles métadonnées à fusionner avec les existantes
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'Memory'
     |      Crée une mémoire à partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire représentant la mémoire
     |
     |      Returns:
     |          Memory: Instance de mémoire
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
     |  Gestionnaire des mémoires MCP.
     |
     |  Cette classe gère le stockage, la recherche et le cycle de vie des mémoires.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_provider=None, embedding_provider=None)
     |      Initialise le gestionnaire de mémoires.
     |
     |      Args:
     |          storage_provider: Fournisseur de stockage pour les mémoires
     |          embedding_provider: Fournisseur d'embeddings pour les mémoires
     |
     |  add_memory(self, content: str, metadata: Optional[Dict[str, Any]] = None) -> str
     |      Ajoute une nouvelle mémoire.
     |
     |      Args:
     |          content (str): Contenu textuel de la mémoire
     |          metadata (Optional[Dict[str, Any]], optional): Métadonnées de la mémoire. Par défaut None.
     |
     |      Returns:
     |          str: Identifiant de la mémoire ajoutée
     |
     |  delete_memory(self, memory_id: str) -> bool
     |      Supprime une mémoire.
     |
     |      Args:
     |          memory_id (str): Identifiant de la mémoire
     |
     |      Returns:
     |          bool: True si la suppression a réussi, False sinon
     |
     |  get_memory(self, memory_id: str) -> Optional[memory_manager.Memory]
     |      Récupère une mémoire par son identifiant.
     |
     |      Args:
     |          memory_id (str): Identifiant de la mémoire
     |
     |      Returns:
     |          Optional[Memory]: Mémoire récupérée, ou None si elle n'existe pas
     |
     |  list_memories(self, metadata_filter: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[memory_manager.Memory]
     |      Liste les mémoires, éventuellement filtrées par métadonnées.
     |
     |      Args:
     |          metadata_filter (Optional[Dict[str, Any]], optional): Filtre sur les métadonnées. Par défaut None.
     |          limit (int, optional): Nombre maximum de résultats. Par défaut 100.
     |          offset (int, optional): Décalage pour la pagination. Par défaut 0.
     |
     |      Returns:
     |          List[Memory]: Liste des mémoires
     |
     |  search_memories(self, query: str, limit: int = 10, metadata_filter: Optional[Dict[str, Any]] = None) -> List[Tuple[memory_manager.Memory, float]]
     |      Recherche des mémoires par similarité sémantique.
     |
     |      Args:
     |          query (str): Requête de recherche
     |          limit (int, optional): Nombre maximum de résultats. Par défaut 10.
     |          metadata_filter (Optional[Dict[str, Any]], optional): Filtre sur les métadonnées. Par défaut None.
     |
     |      Returns:
     |          List[Tuple[Memory, float]]: Liste de tuples (mémoire, score) triés par score décroissant
     |
     |  update_memory(self, memory_id: str, content: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None) -> bool
     |      Met à jour une mémoire existante.
     |
     |      Args:
     |          memory_id (str): Identifiant de la mémoire
     |          content (Optional[str], optional): Nouveau contenu. Par défaut None.
     |          metadata (Optional[Dict[str, Any]], optional): Nouvelles métadonnées. Par défaut None.
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


