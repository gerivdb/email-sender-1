Help on module path_manager:

NAME
    path_manager

DESCRIPTION
    Gestionnaire de chemins pour projets Python
    -------------------------------------------
    Ce module fournit des classes et fonctions pour g�rer les chemins de fichiers
    de mani�re coh�rente dans un projet, en prenant en charge les chemins relatifs
    et absolus, ainsi que la normalisation des chemins.

CLASSES
    builtins.object
        PathManager

    class PathManager(builtins.object)
     |  PathManager(project_root: Optional[str] = None)
     |
     |  Classe pour g�rer les chemins de fichiers dans un projet.
     |
     |  Cette classe fournit des m�thodes pour convertir entre chemins relatifs et absolus,
     |  normaliser les chemins, et rechercher des fichiers.
     |
     |  Methods defined here:
     |
     |  __init__(self, project_root: Optional[str] = None)
     |      Initialise le gestionnaire de chemins.
     |
     |      Args:
     |          project_root: Chemin racine du projet. Si None, utilise le r�pertoire courant.
     |
     |  add_path_mapping(self, name: str, path: Union[str, pathlib.Path]) -> None
     |      Ajoute un nouveau mapping de chemin au gestionnaire de chemins.
     |
     |      Args:
     |          name: Nom du mapping de chemin.
     |          path: Chemin � mapper. Peut �tre un chemin absolu ou relatif au r�pertoire racine du projet.
     |
     |  find_files(self, directory: Union[str, pathlib.Path], pattern: Union[str, List[str]] = '*', recurse: bool = False, exclude_directories: List[str] = None, exclude_files: List[str] = None, include_pattern: str = '') -> List[str]
     |      Recherche des fichiers dans un r�pertoire avec des options avanc�es.
     |
     |      Args:
     |          directory: R�pertoire dans lequel rechercher les fichiers.
     |          pattern: Mod�le de recherche pour les fichiers. Peut �tre une cha�ne ou un tableau de cha�nes.
     |          recurse: Si True, recherche r�cursivement dans les sous-r�pertoires.
     |          exclude_directories: Liste de noms de r�pertoires � exclure de la recherche.
     |          exclude_files: Liste de noms de fichiers � exclure de la recherche.
     |          include_pattern: Mod�le suppl�mentaire pour filtrer les fichiers inclus.
     |
     |      Returns:
     |          Liste des chemins de fichiers trouv�s.
     |
     |  get_path_mappings(self) -> Dict[str, pathlib.Path]
     |      Obtient tous les mappings de chemins d�finis dans le gestionnaire de chemins.
     |
     |      Returns:
     |          Dictionnaire des mappings de chemins.
     |
     |  get_project_path(self, relative_path: str, base_path: str = '') -> pathlib.Path
     |      Obtient le chemin absolu � partir d'un chemin relatif au r�pertoire racine du projet.
     |
     |      Args:
     |          relative_path: Chemin relatif au r�pertoire racine du projet.
     |          base_path: Chemin de base � utiliser pour la r�solution. Par d�faut, utilise le r�pertoire racine du projet.
     |
     |      Returns:
     |          Chemin absolu.
     |
     |  get_relative_path(self, absolute_path: Union[str, pathlib.Path], base_path: str = '') -> str
     |      Obtient le chemin relatif � partir d'un chemin absolu.
     |
     |      Args:
     |          absolute_path: Chemin absolu � convertir.
     |          base_path: Chemin de base � utiliser pour la conversion. Par d�faut, utilise le r�pertoire racine du projet.
     |
     |      Returns:
     |          Chemin relatif.
     |
     |  is_relative_path(self, path: Union[str, pathlib.Path]) -> bool
     |      V�rifie si un chemin est relatif.
     |
     |      Args:
     |          path: Chemin � v�rifier.
     |
     |      Returns:
     |          True si le chemin est relatif, False sinon.
     |
     |  ----------------------------------------------------------------------
     |  Static methods defined here:
     |
     |  has_path_accents(path: str) -> bool
     |      V�rifie si un chemin contient des caract�res accentu�s.
     |
     |      Args:
     |          path: Chemin � v�rifier.
     |
     |      Returns:
     |          True si le chemin contient des caract�res accentu�s, False sinon.
     |
     |  has_path_spaces(path: str) -> bool
     |      V�rifie si un chemin contient des espaces.
     |
     |      Args:
     |          path: Chemin � v�rifier.
     |
     |      Returns:
     |          True si le chemin contient des espaces, False sinon.
     |
     |  normalize_path(path: Union[str, pathlib.Path], force_windows_style: bool = False, force_unix_style: bool = False) -> str
     |      Normalise un chemin en fonction du syst�me d'exploitation.
     |
     |      Args:
     |          path: Chemin � normaliser.
     |          force_windows_style: Si True, force l'utilisation du style Windows (backslashes).
     |          force_unix_style: Si True, force l'utilisation du style Unix (forward slashes).
     |
     |      Returns:
     |          Chemin normalis�.
     |
     |  normalize_path_full(path: str) -> str
     |      Normalise un chemin en rempla�ant les caract�res accentu�s et les espaces.
     |
     |      Args:
     |          path: Chemin � normaliser.
     |
     |      Returns:
     |          Chemin normalis�.
     |
     |  remove_path_accents(path: str) -> str
     |      Convertit un chemin avec des caract�res accentu�s en chemin sans accents.
     |
     |      Args:
     |          path: Chemin � convertir.
     |
     |      Returns:
     |          Chemin sans accents.
     |
     |  replace_path_spaces(path: str) -> str
     |      Convertit un chemin avec des espaces en chemin avec des underscores.
     |
     |      Args:
     |          path: Chemin � convertir.
     |
     |      Returns:
     |          Chemin avec des underscores.
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
    find_files(directory: Union[str, pathlib.Path], pattern: Union[str, List[str]] = '*', recurse: bool = False, exclude_directories: List[str] = None, exclude_files: List[str] = None, include_pattern: str = '') -> List[str]
        Recherche des fichiers dans un r�pertoire avec des options avanc�es.

        Args:
            directory: R�pertoire dans lequel rechercher les fichiers.
            pattern: Mod�le de recherche pour les fichiers. Peut �tre une cha�ne ou un tableau de cha�nes.
            recurse: Si True, recherche r�cursivement dans les sous-r�pertoires.
            exclude_directories: Liste de noms de r�pertoires � exclure de la recherche.
            exclude_files: Liste de noms de fichiers � exclure de la recherche.
            include_pattern: Mod�le suppl�mentaire pour filtrer les fichiers inclus.

        Returns:
            Liste des chemins de fichiers trouv�s.

    get_project_path(relative_path: str, base_path: str = '') -> pathlib.Path
        Obtient le chemin absolu � partir d'un chemin relatif au r�pertoire racine du projet.

        Args:
            relative_path: Chemin relatif au r�pertoire racine du projet.
            base_path: Chemin de base � utiliser pour la r�solution. Par d�faut, utilise le r�pertoire racine du projet.

        Returns:
            Chemin absolu.

    get_relative_path(absolute_path: Union[str, pathlib.Path], base_path: str = '') -> str
        Obtient le chemin relatif � partir d'un chemin absolu.

        Args:
            absolute_path: Chemin absolu � convertir.
            base_path: Chemin de base � utiliser pour la conversion. Par d�faut, utilise le r�pertoire racine du projet.

        Returns:
            Chemin relatif.

    has_path_accents(path: str) -> bool
        V�rifie si un chemin contient des caract�res accentu�s.

        Args:
            path: Chemin � v�rifier.

        Returns:
            True si le chemin contient des caract�res accentu�s, False sinon.

    has_path_spaces(path: str) -> bool
        V�rifie si un chemin contient des espaces.

        Args:
            path: Chemin � v�rifier.

        Returns:
            True si le chemin contient des espaces, False sinon.

    normalize_path(path: Union[str, pathlib.Path], force_windows_style: bool = False, force_unix_style: bool = False) -> str
        Normalise un chemin en fonction du syst�me d'exploitation.

        Args:
            path: Chemin � normaliser.
            force_windows_style: Si True, force l'utilisation du style Windows (backslashes).
            force_unix_style: Si True, force l'utilisation du style Unix (forward slashes).

        Returns:
            Chemin normalis�.

    normalize_path_full(path: str) -> str
        Normalise un chemin en rempla�ant les caract�res accentu�s et les espaces.

        Args:
            path: Chemin � normaliser.

        Returns:
            Chemin normalis�.

    remove_path_accents(path: str) -> str
        Convertit un chemin avec des caract�res accentu�s en chemin sans accents.

        Args:
            path: Chemin � convertir.

        Returns:
            Chemin sans accents.

    replace_path_spaces(path: str) -> str
        Convertit un chemin avec des espaces en chemin avec des underscores.

        Args:
            path: Chemin � convertir.

        Returns:
            Chemin avec des underscores.

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

    path_manager = <path_manager.PathManager object>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\tools\json-tools\path_manager.py


