Help on module CodeManager:

NAME
    CodeManager - Module de gestion de code pour MCP.

DESCRIPTION
    Ce module fournit une classe de base pour g�rer les op�rations sur le code dans le contexte MCP.
    Il permet de rechercher, analyser et obtenir la structure du code.

CLASSES
    builtins.object
        CodeManager

    class CodeManager(builtins.object)
     |  CodeManager(base_path: Optional[str] = None, cache_path: Optional[str] = None)
     |
     |  Gestionnaire de code pour MCP.
     |
     |  Cette classe fournit les fonctionnalit�s de base pour g�rer le code :
     |  - Rechercher du code
     |  - Analyser du code
     |  - Obtenir la structure du code
     |
     |  Methods defined here:
     |
     |  __init__(self, base_path: Optional[str] = None, cache_path: Optional[str] = None)
     |      Initialise le gestionnaire de code.
     |
     |      Args:
     |          base_path (Optional[str]): Chemin de base pour le code.
     |              Si non sp�cifi�, utilise le r�pertoire courant.
     |          cache_path (Optional[str]): Chemin pour le cache des analyses.
     |              Si non sp�cifi�, utilise un emplacement par d�faut.
     |
     |  analyze_code(self, file_path: str, rules: Optional[List[str]] = None) -> Dict[str, Any]
     |      Analyse un fichier de code.
     |
     |      Args:
     |          file_path (str): Chemin du fichier � analyser
     |          rules (Optional[List[str]]): Liste des r�gles d'analyse � appliquer
     |
     |      Returns:
     |          Dict[str, Any]: R�sultat de l'analyse
     |
     |  get_code_structure(self, file_path: str) -> Dict[str, Any]
     |      Obtient la structure d'un fichier de code.
     |
     |      Args:
     |          file_path (str): Chemin du fichier
     |
     |      Returns:
     |          Dict[str, Any]: Structure du code
     |
     |  search_code(self, query: str, paths: Optional[List[str]] = None, languages: Optional[List[str]] = None, recursive: bool = True, case_sensitive: bool = False, whole_word: bool = False, regex: bool = False, max_results: int = 100) -> List[Dict[str, Any]]
     |      Recherche du code correspondant � une requ�te.
     |
     |      Args:
     |          query (str): Requ�te de recherche
     |          paths (Optional[List[str]]): Liste des chemins � rechercher
     |          languages (Optional[List[str]]): Liste des langages � inclure
     |          recursive (bool): Recherche r�cursive dans les sous-dossiers
     |          case_sensitive (bool): Recherche sensible � la casse
     |          whole_word (bool): Recherche de mots entiers
     |          regex (bool): Interpr�te la requ�te comme une expression r�guli�re
     |          max_results (int): Nombre maximum de r�sultats
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des r�sultats de recherche
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

    Set = typing.Set
        A generic version of set.

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

    logger = <Logger mcp.code (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\code\codemanager.py


