Help on module dependency_manager:

NAME
    dependency_manager - Module de gestion des d�pendances pour le cache.

DESCRIPTION
    Ce module fournit des fonctionnalit�s pour g�rer les d�pendances entre les �l�ments du cache
    et faciliter l'invalidation des �l�ments li�s.

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

CLASSES
    builtins.object
        DependencyManager

    class DependencyManager(builtins.object)
     |  DependencyManager(storage_path: Optional[str] = None)
     |
     |  Gestionnaire de d�pendances pour le cache.
     |
     |  Cette classe permet de suivre les d�pendances entre les �l�ments du cache
     |  et de faciliter l'invalidation des �l�ments li�s.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: Optional[str] = None)
     |      Initialise le gestionnaire de d�pendances.
     |
     |      Args:
     |          storage_path (str, optional): Chemin vers le fichier de stockage des d�pendances.
     |              Si None, utilise un stockage en m�moire uniquement.
     |
     |  add_dependencies(self, key: str, dependencies: List[str]) -> None
     |      Ajoute plusieurs d�pendances pour une cl� de cache.
     |
     |      Args:
     |          key (str): Cl� de cache.
     |          dependencies (List[str]): Liste des d�pendances � ajouter.
     |
     |  add_dependency(self, key: str, dependency: str) -> None
     |      Ajoute une d�pendance pour une cl� de cache.
     |
     |      Args:
     |          key (str): Cl� de cache.
     |          dependency (str): D�pendance � ajouter.
     |
     |  add_tag(self, key: str, tag: str) -> None
     |      Ajoute un tag � une cl� de cache.
     |
     |      Args:
     |          key (str): Cl� de cache.
     |          tag (str): Tag � ajouter.
     |
     |  add_tags(self, key: str, tags: List[str]) -> None
     |      Ajoute plusieurs tags � une cl� de cache.
     |
     |      Args:
     |          key (str): Cl� de cache.
     |          tags (List[str]): Liste des tags � ajouter.
     |
     |  clear_all(self) -> None
     |      Supprime toutes les d�pendances et tags.
     |
     |  clear_key(self, key: str) -> None
     |      Supprime toutes les d�pendances et tags d'une cl� de cache.
     |
     |      Args:
     |          key (str): Cl� de cache.
     |
     |  get_dependencies(self, key: str) -> Set[str]
     |      R�cup�re les d�pendances d'une cl� de cache.
     |
     |      Args:
     |          key (str): Cl� de cache.
     |
     |      Returns:
     |          Set[str]: Ensemble des d�pendances.
     |
     |  get_dependent_keys(self, dependency: str) -> Set[str]
     |      R�cup�re les cl�s qui d�pendent d'une d�pendance donn�e.
     |
     |      Args:
     |          dependency (str): D�pendance.
     |
     |      Returns:
     |          Set[str]: Ensemble des cl�s d�pendantes.
     |
     |  get_keys_by_tag(self, tag: str) -> Set[str]
     |      R�cup�re les cl�s associ�es � un tag.
     |
     |      Args:
     |          tag (str): Tag.
     |
     |      Returns:
     |          Set[str]: Ensemble des cl�s.
     |
     |  get_keys_by_tags(self, tags: List[str], match_all: bool = False) -> Set[str]
     |      R�cup�re les cl�s associ�es � plusieurs tags.
     |
     |      Args:
     |          tags (List[str]): Liste des tags.
     |          match_all (bool, optional): Si True, retourne les cl�s qui ont tous les tags.
     |              Si False, retourne les cl�s qui ont au moins un des tags.
     |
     |      Returns:
     |          Set[str]: Ensemble des cl�s.
     |
     |  get_tags(self, key: str) -> Set[str]
     |      R�cup�re les tags d'une cl� de cache.
     |
     |      Args:
     |          key (str): Cl� de cache.
     |
     |      Returns:
     |          Set[str]: Ensemble des tags.
     |
     |  remove_dependency(self, key: str, dependency: str) -> None
     |      Supprime une d�pendance pour une cl� de cache.
     |
     |      Args:
     |          key (str): Cl� de cache.
     |          dependency (str): D�pendance � supprimer.
     |
     |  remove_tag(self, key: str, tag: str) -> None
     |      Supprime un tag d'une cl� de cache.
     |
     |      Args:
     |          key (str): Cl� de cache.
     |          tag (str): Tag � supprimer.
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
        Cr�e une instance du gestionnaire de d�pendances.

        Args:
            storage_path (str, optional): Chemin vers le fichier de stockage des d�pendances.
                Si None, utilise un stockage en m�moire uniquement.

        Returns:
            DependencyManager: Instance du gestionnaire de d�pendances.

    get_default_manager() -> dependency_manager.DependencyManager
        R�cup�re l'instance par d�faut du gestionnaire de d�pendances.

        Returns:
            DependencyManager: Instance par d�faut du gestionnaire de d�pendances.

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
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\utils\cache\dependency_manager.py


