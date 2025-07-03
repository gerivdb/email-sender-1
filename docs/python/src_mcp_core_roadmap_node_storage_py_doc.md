Help on module node_storage:

NAME
    node_storage - Module pour le stockage des n�uds cognitifs.

DESCRIPTION
    Ce module contient les interfaces et impl�mentations pour les fournisseurs de stockage
    des n�uds cognitifs.

CLASSES
    builtins.object
        FileNodeStorageProvider
    typing.Protocol(typing.Generic)
        NodeStorageProvider

    class FileNodeStorageProvider(builtins.object)
     |  FileNodeStorageProvider(storage_dir: str)
     |
     |  Fournisseur de stockage des n�uds cognitifs bas� sur des fichiers.
     |
     |  Ce fournisseur stocke les n�uds dans des fichiers JSON.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_dir: str)
     |      Initialise le fournisseur de stockage.
     |
     |      Args:
     |          storage_dir (str): R�pertoire de stockage des n�uds
     |
     |  check_integrity(self, repair: bool = False) -> Tuple[int, int, int]
     |      V�rifie l'int�grit� des donn�es stock�es.
     |
     |      Cette m�thode parcourt tous les fichiers de n�uds et v�rifie leur int�grit�.
     |      Si repair=True, elle tente de r�parer les fichiers corrompus en utilisant les sauvegardes.
     |
     |      Args:
     |          repair (bool, optional): Si True, tente de r�parer les fichiers corrompus. Par d�faut False.
     |
     |      Returns:
     |          Tuple[int, int, int]: (nombre de fichiers v�rifi�s, nombre de fichiers corrompus, nombre de fichiers r�par�s)
     |
     |  delete_node(self, node_id: str) -> bool
     |      Supprime un n�ud.
     |
     |      Cette m�thode supprime le fichier principal et sa sauvegarde.
     |
     |      Args:
     |          node_id (str): Identifiant du n�ud
     |
     |      Returns:
     |          bool: True si la suppression a r�ussi, False sinon
     |
     |  get_node(self, node_id: str) -> Optional[Dict[str, Any]]
     |      R�cup�re un n�ud depuis un fichier JSON.
     |
     |      Cette m�thode essaie de r�cup�rer le n�ud depuis le fichier principal,
     |      et si cela �choue, essaie de le r�cup�rer depuis la sauvegarde.
     |
     |      Args:
     |          node_id (str): Identifiant du n�ud
     |
     |      Returns:
     |          Optional[Dict[str, Any]]: Donn�es du n�ud r�cup�r�, ou None s'il n'existe pas
     |
     |  list_nodes(self, filter_criteria: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]
     |      Liste les n�uds, �ventuellement filtr�s par crit�res.
     |
     |      Args:
     |          filter_criteria (Optional[Dict[str, Any]], optional): Crit�res de filtrage. Par d�faut None.
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des n�uds
     |
     |  store_node(self, node_data: Dict[str, Any]) -> bool
     |      Stocke un n�ud dans un fichier JSON.
     |
     |      Cette m�thode utilise un fichier temporaire pour �viter la corruption des donn�es
     |      en cas d'erreur pendant l'�criture.
     |
     |      Args:
     |          node_data (Dict[str, Any]): Donn�es du n�ud � stocker
     |
     |      Returns:
     |          bool: True si le stockage a r�ussi, False sinon
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
     |  Interface pour les fournisseurs de stockage des n�uds cognitifs.
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
     |      Supprime un n�ud cognitif.
     |
     |      Args:
     |          node_id (str): Identifiant du n�ud
     |
     |      Returns:
     |          bool: True si la suppression a r�ussi, False sinon
     |
     |  get_node(self, node_id: str) -> Optional[Dict[str, Any]]
     |      R�cup�re un n�ud cognitif par son identifiant.
     |
     |      Args:
     |          node_id (str): Identifiant du n�ud
     |
     |      Returns:
     |          Optional[Dict[str, Any]]: Donn�es du n�ud r�cup�r�, ou None s'il n'existe pas
     |
     |  list_nodes(self, filter_criteria: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]
     |      Liste les n�uds cognitifs, �ventuellement filtr�s par crit�res.
     |
     |      Args:
     |          filter_criteria (Optional[Dict[str, Any]], optional): Crit�res de filtrage. Par d�faut None.
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des n�uds
     |
     |  store_node(self, node_data: Dict[str, Any]) -> bool
     |      Stocke un n�ud cognitif.
     |
     |      Args:
     |          node_data (Dict[str, Any]): Donn�es du n�ud � stocker
     |
     |      Returns:
     |          bool: True si le stockage a r�ussi, False sinon
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


