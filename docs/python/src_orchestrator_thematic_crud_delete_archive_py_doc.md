Help on module delete_archive:

NAME
    delete_archive - Module de suppression et archivage thématique.

DESCRIPTION
    Ce module fournit des fonctionnalités pour supprimer et archiver des éléments
    de roadmap par thème et autres critères.

CLASSES
    builtins.object
        ThematicDeleteArchive

    class ThematicDeleteArchive(builtins.object)
     |  ThematicDeleteArchive(storage_path: str, archive_path: Optional[str] = None)
     |
     |  Classe pour la suppression et l'archivage thématique.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, archive_path: Optional[str] = None)
     |      Initialise le gestionnaire de suppression et d'archivage thématique.
     |
     |      Args:
     |          storage_path: Chemin vers le répertoire de stockage des données
     |          archive_path: Chemin vers le répertoire d'archivage (optionnel)
     |
     |  archive_item(self, item_id: str, reason: Optional[str] = None) -> bool
     |      Archive un élément sans le supprimer.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à archiver
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          True si l'élément a été archivé, False sinon
     |
     |  archive_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any], reason: Optional[str] = None) -> Dict[str, Any]
     |      Archive des éléments selon une méthode de sélection spécifiée.
     |
     |      Args:
     |          selection_method: Méthode de sélection à utiliser
     |          selection_params: Paramètres pour la méthode de sélection
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments archivés, etc.)
     |
     |  archive_items_by_theme(self, theme: str, reason: Optional[str] = None) -> int
     |      Archive tous les éléments d'un thème sans les supprimer.
     |
     |      Args:
     |          theme: Thème des éléments à archiver
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          Nombre d'éléments archivés
     |
     |  delete_item(self, item_id: str, permanent: bool = False, reason: Optional[str] = None) -> bool
     |      Supprime un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à supprimer
     |          permanent: Si True, supprime définitivement l'élément sans l'archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          True si l'élément a été supprimé, False sinon
     |
     |  delete_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any], permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des éléments selon une méthode de sélection spécifiée.
     |
     |      Args:
     |          selection_method: Méthode de sélection à utiliser
     |          selection_params: Paramètres pour la méthode de sélection
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
     |
     |  delete_items_by_theme(self, theme: str, permanent: bool = False, reason: Optional[str] = None) -> int
     |      Supprime tous les éléments d'un thème.
     |
     |      Args:
     |          theme: Thème des éléments à supprimer
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Nombre d'éléments supprimés
     |
     |  delete_items_by_theme_exclusivity(self, theme: str, exclusivity_threshold: float = 0.8, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des éléments selon l'exclusivité d'un thème.
     |
     |      Args:
     |          theme: Thème principal
     |          exclusivity_threshold: Seuil d'exclusivité (0.0 à 1.0)
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
     |
     |  delete_items_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des éléments selon une hiérarchie thématique.
     |
     |      Args:
     |          theme: Thème principal
     |          include_subthemes: Si True, inclut les sous-thèmes
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
     |
     |  delete_items_by_theme_weight(self, theme: str, min_weight: float = 0.5, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des éléments selon le poids d'un thème.
     |
     |      Args:
     |          theme: Thème à rechercher
     |          min_weight: Poids minimum du thème (0.0 à 1.0)
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
     |
     |  get_archive_statistics(self) -> Dict[str, Any]
     |      Récupère des statistiques sur les archives.
     |
     |      Returns:
     |          Statistiques sur les archives (nombre d'éléments, taille, etc.)
     |
     |  get_archived_items(self, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Récupère les éléments archivés.
     |
     |      Args:
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments archivés
     |
     |  get_archived_items_by_theme(self, theme: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Récupère les éléments archivés par thème.
     |
     |      Args:
     |          theme: Thème des éléments à récupérer
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments archivés pour le thème spécifié
     |
     |  restore_archived_item(self, item_id: str) -> bool
     |      Restaure un élément archivé.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à restaurer
     |
     |      Returns:
     |          True si l'élément a été restauré, False sinon
     |
     |  rotate_archives(self, max_age_days: int = 90, max_items: int = 1000, backup_dir: Optional[str] = None) -> Dict[str, Any]
     |      Effectue une rotation des archives en déplaçant les archives anciennes vers un répertoire de sauvegarde
     |      ou en les supprimant.
     |
     |      Args:
     |          max_age_days: Âge maximum des archives en jours (défaut: 90)
     |          max_items: Nombre maximum d'éléments à conserver (défaut: 1000)
     |          backup_dir: Répertoire de sauvegarde (optionnel, si None les archives sont supprimées)
     |
     |      Returns:
     |          Statistiques sur la rotation (nombre d'éléments déplacés/supprimés, etc.)
     |
     |  search_archived_items(self, query: str, themes: Optional[List[str]] = None, metadata_filters: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des éléments dans les archives.
     |
     |      Args:
     |          query: Requête textuelle à rechercher dans le contenu
     |          themes: Liste des thèmes à inclure dans la recherche (optionnel)
     |          metadata_filters: Filtres de métadonnées (optionnel)
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments archivés correspondant aux critères de recherche
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

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\delete_archive.py


