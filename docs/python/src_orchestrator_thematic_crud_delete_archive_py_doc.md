Help on module delete_archive:

NAME
    delete_archive - Module de suppression et archivage th�matique.

DESCRIPTION
    Ce module fournit des fonctionnalit�s pour supprimer et archiver des �l�ments
    de roadmap par th�me et autres crit�res.

CLASSES
    builtins.object
        ThematicDeleteArchive

    class ThematicDeleteArchive(builtins.object)
     |  ThematicDeleteArchive(storage_path: str, archive_path: Optional[str] = None)
     |
     |  Classe pour la suppression et l'archivage th�matique.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, archive_path: Optional[str] = None)
     |      Initialise le gestionnaire de suppression et d'archivage th�matique.
     |
     |      Args:
     |          storage_path: Chemin vers le r�pertoire de stockage des donn�es
     |          archive_path: Chemin vers le r�pertoire d'archivage (optionnel)
     |
     |  archive_item(self, item_id: str, reason: Optional[str] = None) -> bool
     |      Archive un �l�ment sans le supprimer.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � archiver
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          True si l'�l�ment a �t� archiv�, False sinon
     |
     |  archive_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any], reason: Optional[str] = None) -> Dict[str, Any]
     |      Archive des �l�ments selon une m�thode de s�lection sp�cifi�e.
     |
     |      Args:
     |          selection_method: M�thode de s�lection � utiliser
     |          selection_params: Param�tres pour la m�thode de s�lection
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments archiv�s, etc.)
     |
     |  archive_items_by_theme(self, theme: str, reason: Optional[str] = None) -> int
     |      Archive tous les �l�ments d'un th�me sans les supprimer.
     |
     |      Args:
     |          theme: Th�me des �l�ments � archiver
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          Nombre d'�l�ments archiv�s
     |
     |  delete_item(self, item_id: str, permanent: bool = False, reason: Optional[str] = None) -> bool
     |      Supprime un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � supprimer
     |          permanent: Si True, supprime d�finitivement l'�l�ment sans l'archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          True si l'�l�ment a �t� supprim�, False sinon
     |
     |  delete_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any], permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des �l�ments selon une m�thode de s�lection sp�cifi�e.
     |
     |      Args:
     |          selection_method: M�thode de s�lection � utiliser
     |          selection_params: Param�tres pour la m�thode de s�lection
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments supprim�s, etc.)
     |
     |  delete_items_by_theme(self, theme: str, permanent: bool = False, reason: Optional[str] = None) -> int
     |      Supprime tous les �l�ments d'un th�me.
     |
     |      Args:
     |          theme: Th�me des �l�ments � supprimer
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Nombre d'�l�ments supprim�s
     |
     |  delete_items_by_theme_exclusivity(self, theme: str, exclusivity_threshold: float = 0.8, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des �l�ments selon l'exclusivit� d'un th�me.
     |
     |      Args:
     |          theme: Th�me principal
     |          exclusivity_threshold: Seuil d'exclusivit� (0.0 � 1.0)
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments supprim�s, etc.)
     |
     |  delete_items_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des �l�ments selon une hi�rarchie th�matique.
     |
     |      Args:
     |          theme: Th�me principal
     |          include_subthemes: Si True, inclut les sous-th�mes
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments supprim�s, etc.)
     |
     |  delete_items_by_theme_weight(self, theme: str, min_weight: float = 0.5, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des �l�ments selon le poids d'un th�me.
     |
     |      Args:
     |          theme: Th�me � rechercher
     |          min_weight: Poids minimum du th�me (0.0 � 1.0)
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments supprim�s, etc.)
     |
     |  get_archive_statistics(self) -> Dict[str, Any]
     |      R�cup�re des statistiques sur les archives.
     |
     |      Returns:
     |          Statistiques sur les archives (nombre d'�l�ments, taille, etc.)
     |
     |  get_archived_items(self, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      R�cup�re les �l�ments archiv�s.
     |
     |      Args:
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments archiv�s
     |
     |  get_archived_items_by_theme(self, theme: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      R�cup�re les �l�ments archiv�s par th�me.
     |
     |      Args:
     |          theme: Th�me des �l�ments � r�cup�rer
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments archiv�s pour le th�me sp�cifi�
     |
     |  restore_archived_item(self, item_id: str) -> bool
     |      Restaure un �l�ment archiv�.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � restaurer
     |
     |      Returns:
     |          True si l'�l�ment a �t� restaur�, False sinon
     |
     |  rotate_archives(self, max_age_days: int = 90, max_items: int = 1000, backup_dir: Optional[str] = None) -> Dict[str, Any]
     |      Effectue une rotation des archives en d�pla�ant les archives anciennes vers un r�pertoire de sauvegarde
     |      ou en les supprimant.
     |
     |      Args:
     |          max_age_days: �ge maximum des archives en jours (d�faut: 90)
     |          max_items: Nombre maximum d'�l�ments � conserver (d�faut: 1000)
     |          backup_dir: R�pertoire de sauvegarde (optionnel, si None les archives sont supprim�es)
     |
     |      Returns:
     |          Statistiques sur la rotation (nombre d'�l�ments d�plac�s/supprim�s, etc.)
     |
     |  search_archived_items(self, query: str, themes: Optional[List[str]] = None, metadata_filters: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des �l�ments dans les archives.
     |
     |      Args:
     |          query: Requ�te textuelle � rechercher dans le contenu
     |          themes: Liste des th�mes � inclure dans la recherche (optionnel)
     |          metadata_filters: Filtres de m�tadonn�es (optionnel)
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments archiv�s correspondant aux crit�res de recherche
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


