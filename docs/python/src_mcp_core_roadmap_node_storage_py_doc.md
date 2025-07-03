Help on module node_storage:

NAME
    node_storage - Module pour le stockage des nœuds cognitifs.

DESCRIPTION
    Ce module contient les interfaces et implémentations pour les fournisseurs de stockage
    des nœuds cognitifs.

CLASSES
    builtins.object
        FileNodeStorageProvider
    typing.Protocol(typing.Generic)
        NodeStorageProvider

    class FileNodeStorageProvider(builtins.object)
     |  FileNodeStorageProvider(storage_dir: str)
     |
     |  Fournisseur de stockage des nœuds cognitifs basé sur des fichiers.
     |
     |  Ce fournisseur stocke les nœuds dans des fichiers JSON.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_dir: str)
     |      Initialise le fournisseur de stockage.
     |
     |      Args:
     |          storage_dir (str): Répertoire de stockage des nœuds
     |
     |  check_integrity(self, repair: bool = False) -> Tuple[int, int, int]
     |      Vérifie l'intégrité des données stockées.
     |
     |      Cette méthode parcourt tous les fichiers de nœuds et vérifie leur intégrité.
     |      Si repair=True, elle tente de réparer les fichiers corrompus en utilisant les sauvegardes.
     |
     |      Args:
     |          repair (bool, optional): Si True, tente de réparer les fichiers corrompus. Par défaut False.
     |
     |      Returns:
     |          Tuple[int, int, int]: (nombre de fichiers vérifiés, nombre de fichiers corrompus, nombre de fichiers réparés)
     |
     |  delete_node(self, node_id: str) -> bool
     |      Supprime un nœud.
     |
     |      Cette méthode supprime le fichier principal et sa sauvegarde.
     |
     |      Args:
     |          node_id (str): Identifiant du nœud
     |
     |      Returns:
     |          bool: True si la suppression a réussi, False sinon
     |
     |  get_node(self, node_id: str) -> Optional[Dict[str, Any]]
     |      Récupère un nœud depuis un fichier JSON.
     |
     |      Cette méthode essaie de récupérer le nœud depuis le fichier principal,
     |      et si cela échoue, essaie de le récupérer depuis la sauvegarde.
     |
     |      Args:
     |          node_id (str): Identifiant du nœud
     |
     |      Returns:
     |          Optional[Dict[str, Any]]: Données du nœud récupéré, ou None s'il n'existe pas
     |
     |  list_nodes(self, filter_criteria: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]
     |      Liste les nœuds, éventuellement filtrés par critères.
     |
     |      Args:
     |          filter_criteria (Optional[Dict[str, Any]], optional): Critères de filtrage. Par défaut None.
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des nœuds
     |
     |  store_node(self, node_data: Dict[str, Any]) -> bool
     |      Stocke un nœud dans un fichier JSON.
     |
     |      Cette méthode utilise un fichier temporaire pour éviter la corruption des données
     |      en cas d'erreur pendant l'écriture.
     |
     |      Args:
     |          node_data (Dict[str, Any]): Données du nœud à stocker
     |
     |      Returns:
     |          bool: True si le stockage a réussi, False sinon
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class NodeStorageProvider(typing.Protocol)
     |  NodeStorageProvider(*args, **kwargs)
     |
     |  Interface pour les fournisseurs de stockage des nœuds cognitifs.
     |
     |  Method resolution order:
     |      NodeStorageProvider
     |      typing.Protocol
     |      typing.Generic
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__ = _no_init_or_replace_init(self, *args, **kwargs) from typing
     |
     |  delete_node(self, node_id: str) -> bool
     |      Supprime un nœud cognitif.
     |
     |      Args:
     |          node_id (str): Identifiant du nœud
     |
     |      Returns:
     |          bool: True si la suppression a réussi, False sinon
     |
     |  get_node(self, node_id: str) -> Optional[Dict[str, Any]]
     |      Récupère un nœud cognitif par son identifiant.
     |
     |      Args:
     |          node_id (str): Identifiant du nœud
     |
     |      Returns:
     |          Optional[Dict[str, Any]]: Données du nœud récupéré, ou None s'il n'existe pas
     |
     |  list_nodes(self, filter_criteria: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]
     |      Liste les nœuds cognitifs, éventuellement filtrés par critères.
     |
     |      Args:
     |          filter_criteria (Optional[Dict[str, Any]], optional): Critères de filtrage. Par défaut None.
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des nœuds
     |
     |  store_node(self, node_data: Dict[str, Any]) -> bool
     |      Stocke un nœud cognitif.
     |
     |      Args:
     |          node_data (Dict[str, Any]): Données du nœud à stocker
     |
     |      Returns:
     |          bool: True si le stockage a réussi, False sinon
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  __subclasshook__ = _proto_hook(other) from typing
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset()
     |
     |  __annotations__ = {}
     |
     |  __non_callable_proto_members__ = set()
     |
     |  __parameters__ = ()
     |
     |  __protocol_attrs__ = {'delete_node', 'get_node', 'list_nodes', 'store_...
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from typing.Protocol:
     |
     |  __init_subclass__(*args, **kwargs)
     |      Function to initialize subclasses.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from typing.Generic:
     |
     |  __class_getitem__(...)
     |      Parameterizes a generic class.
     |
     |      At least, parameterizing a generic class is the *main* thing this
     |      method does. For example, for some generic class `Foo`, this is called
     |      when we do `Foo[int]` - there, with `cls=Foo` and `params=int`.
     |
     |      However, note that this method is also called when defining generic
     |      classes in the first place with `class Foo[T]: ...`.

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

    logger = <Logger mcp.core.roadmap.node_storage (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\roadmap\node_storage.py


