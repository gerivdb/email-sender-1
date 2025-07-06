Help on module version_control:

NAME
    version_control - Module de gestion des versions pour le système CRUD thématique.

DESCRIPTION
    Ce module fournit des fonctionnalités pour gérer les versions des éléments
    par thème, permettant de suivre l'historique des modifications et de restaurer
    des versions antérieures.

CLASSES
    builtins.object
        ThematicVersionControl

    class ThematicVersionControl(builtins.object)
     |  ThematicVersionControl(storage_path: str, versions_path: Optional[str] = None)
     |
     |  Classe pour la gestion des versions des éléments par thème.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, versions_path: Optional[str] = None)
     |      Initialise le gestionnaire de versions thématique.
     |
     |      Args:
     |          storage_path: Chemin vers le répertoire de stockage des données
     |          versions_path: Chemin vers le répertoire de stockage des versions (optionnel)
     |
     |  compare_versions(self, item_id: str, version1: int, version2: int) -> Dict[str, Any]
     |      Compare deux versions d'un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          version1: Numéro de la première version
     |          version2: Numéro de la deuxième version
     |
     |      Returns:
     |          Dictionnaire des différences entre les versions
     |
     |  create_version(self, item: Dict[str, Any], version_tag: Optional[str] = None, version_message: Optional[str] = None) -> Dict[str, Any]
     |      Crée une nouvelle version d'un élément.
     |
     |      Args:
     |          item: Élément à versionner
     |          version_tag: Tag de version (optionnel)
     |          version_message: Message de version (optionnel)
     |
     |      Returns:
     |          Métadonnées de la version créée
     |
     |  get_version(self, item_id: str, version_number: int) -> Optional[Dict[str, Any]]
     |      Récupère une version spécifique d'un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          version_number: Numéro de version
     |
     |      Returns:
     |          Élément à la version spécifiée, ou None si la version n'existe pas
     |
     |  get_versions(self, item_id: str) -> List[Dict[str, Any]]
     |      Récupère toutes les versions d'un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |
     |      Returns:
     |          Liste des métadonnées de versions, triées par numéro de version décroissant
     |
     |  get_versions_by_theme(self, theme: str, item_id: Optional[str] = None) -> Dict[str, List[Dict[str, Any]]]
     |      Récupère les versions des éléments d'un thème.
     |
     |      Args:
     |          theme: Thème des éléments
     |          item_id: Identifiant de l'élément (optionnel)
     |
     |      Returns:
     |          Dictionnaire des versions par élément
     |
     |  restore_version(self, item_id: str, version_number: int, storage_path: Optional[str] = None) -> Optional[Dict[str, Any]]
     |      Restaure une version spécifique d'un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          version_number: Numéro de version
     |          storage_path: Chemin vers le répertoire de stockage (optionnel)
     |
     |      Returns:
     |          Élément restauré, ou None si la restauration a échoué
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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\version_control.py


