Help on module dependency_manager:

NAME
    dependency_manager - Module de gestion des dépendances pour le cache.

DESCRIPTION
    Ce module fournit des fonctionnalités pour gérer les dépendances entre les éléments du cache
    et faciliter l'invalidation des éléments liés.

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

CLASSES
    builtins.object
        DependencyManager

    class DependencyManager(builtins.object)
     |  DependencyManager(storage_path: Optional[str] = None)
     |
     |  Gestionnaire de dépendances pour le cache.
     |
     |  Cette classe permet de suivre les dépendances entre les éléments du cache
     |  et de faciliter l'invalidation des éléments liés.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: Optional[str] = None)
     |      Initialise le gestionnaire de dépendances.
     |
     |      Args:
     |          storage_path (str, optional): Chemin vers le fichier de stockage des dépendances.
     |              Si None, utilise un stockage en mémoire uniquement.
     |
     |  add_dependencies(self, key: str, dependencies: List[str]) -> None
     |      Ajoute plusieurs dépendances pour une clé de cache.
     |
     |      Args:
     |          key (str): Clé de cache.
     |          dependencies (List[str]): Liste des dépendances à ajouter.
     |
     |  add_dependency(self, key: str, dependency: str) -> None
     |      Ajoute une dépendance pour une clé de cache.
     |
     |      Args:
     |          key (str): Clé de cache.
     |          dependency (str): Dépendance à ajouter.
     |
     |  add_tag(self, key: str, tag: str) -> None
     |      Ajoute un tag à une clé de cache.
     |
     |      Args:
     |          key (str): Clé de cache.
     |          tag (str): Tag à ajouter.
     |
     |  add_tags(self, key: str, tags: List[str]) -> None
     |      Ajoute plusieurs tags à une clé de cache.
     |
     |      Args:
     |          key (str): Clé de cache.
     |          tags (List[str]): Liste des tags à ajouter.
     |
     |  clear_all(self) -> None
     |      Supprime toutes les dépendances et tags.
     |
     |  clear_key(self, key: str) -> None
     |      Supprime toutes les dépendances et tags d'une clé de cache.
     |
     |      Args:
     |          key (str): Clé de cache.
     |
     |  get_dependencies(self, key: str) -> Set[str]
     |      Récupère les dépendances d'une clé de cache.
     |
     |      Args:
     |          key (str): Clé de cache.
     |
     |      Returns:
     |          Set[str]: Ensemble des dépendances.
     |
     |  get_dependent_keys(self, dependency: str) -> Set[str]
     |      Récupère les clés qui dépendent d'une dépendance donnée.
     |
     |      Args:
     |          dependency (str): Dépendance.
     |
     |      Returns:
     |          Set[str]: Ensemble des clés dépendantes.
     |
     |  get_keys_by_tag(self, tag: str) -> Set[str]
     |      Récupère les clés associées à un tag.
     |
     |      Args:
     |          tag (str): Tag.
     |
     |      Returns:
     |          Set[str]: Ensemble des clés.
     |
     |  get_keys_by_tags(self, tags: List[str], match_all: bool = False) -> Set[str]
     |      Récupère les clés associées à plusieurs tags.
     |
     |      Args:
     |          tags (List[str]): Liste des tags.
     |          match_all (bool, optional): Si True, retourne les clés qui ont tous les tags.
     |              Si False, retourne les clés qui ont au moins un des tags.
     |
     |      Returns:
     |          Set[str]: Ensemble des clés.
     |
     |  get_tags(self, key: str) -> Set[str]
     |      Récupère les tags d'une clé de cache.
     |
     |      Args:
     |          key (str): Clé de cache.
     |
     |      Returns:
     |          Set[str]: Ensemble des tags.
     |
     |  remove_dependency(self, key: str, dependency: str) -> None
     |      Supprime une dépendance pour une clé de cache.
     |
     |      Args:
     |          key (str): Clé de cache.
     |          dependency (str): Dépendance à supprimer.
     |
     |  remove_tag(self, key: str, tag: str) -> None
     |      Supprime un tag d'une clé de cache.
     |
     |      Args:
     |          key (str): Clé de cache.
     |          tag (str): Tag à supprimer.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FUNCTIONS
    create_dependency_manager(storage_path: Optional[str] = None) -> dependency_manager.DependencyManager
        Crée une instance du gestionnaire de dépendances.

        Args:
            storage_path (str, optional): Chemin vers le fichier de stockage des dépendances.
                Si None, utilise un stockage en mémoire uniquement.

        Returns:
            DependencyManager: Instance du gestionnaire de dépendances.

    get_default_manager() -> dependency_manager.DependencyManager
        Récupère l'instance par défaut du gestionnaire de dépendances.

        Returns:
            DependencyManager: Instance par défaut du gestionnaire de dépendances.

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Set = typing.Set
        A generic version of set.

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

    logger = <Logger dependency_manager (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\tools\cache-tools\dependency_manager.py


