Help on module tools_manager:

NAME
    tools_manager - Module pour la gestion des outils MCP.

DESCRIPTION
    Ce module contient les classes et fonctions pour g�rer les outils MCP,
    notamment la d�couverte, l'enregistrement et la validation des outils.

CLASSES
    builtins.object
        ToolsManager

    class ToolsManager(builtins.object)
     |  Gestionnaire des outils MCP.
     |
     |  Cette classe g�re la d�couverte, l'enregistrement et la validation des outils MCP.
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialise le gestionnaire d'outils.
     |
     |  discover_tools(self, package_path: str, package_name: Optional[str] = None, recursive: bool = False) -> List[str]
     |      D�couvre les outils MCP dans un package.
     |
     |      Args:
     |          package_path (str): Chemin vers le package contenant les outils
     |          package_name (Optional[str], optional): Nom du package. Si None, le nom sera d�riv� du chemin.
     |          recursive (bool, optional): Si True, parcourt r�cursivement les sous-packages. Par d�faut False.
     |
     |      Returns:
     |          List[str]: Liste des noms des outils d�couverts
     |
     |  get_schema(self, name: str) -> Optional[Dict[str, Any]]
     |      R�cup�re le sch�ma d'un outil MCP par son nom.
     |
     |      Args:
     |          name (str): Nom de l'outil
     |
     |      Returns:
     |          Optional[Dict[str, Any]]: Sch�ma JSON de l'outil, ou None si l'outil n'existe pas
     |
     |  get_tool(self, name: str) -> Optional[Callable]
     |      R�cup�re un outil MCP par son nom.
     |
     |      Args:
     |          name (str): Nom de l'outil
     |
     |      Returns:
     |          Optional[Callable]: Fonction de traitement de l'outil, ou None si l'outil n'existe pas
     |
     |  has_tool(self, name: str) -> bool
     |      V�rifie si un outil MCP existe.
     |
     |      Args:
     |          name (str): Nom de l'outil
     |
     |      Returns:
     |          bool: True si l'outil existe, False sinon
     |
     |  list_tools(self) -> List[Dict[str, Any]]
     |      Liste tous les outils MCP enregistr�s.
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des outils avec leur nom, description et param�tres
     |
     |  register_tool(self, name: str, handler: Callable, schema: Dict[str, Any]) -> None
     |      Enregistre un outil MCP.
     |
     |      Args:
     |          name (str): Nom de l'outil
     |          handler (Callable): Fonction de traitement de l'outil
     |          schema (Dict[str, Any]): Sch�ma JSON de l'outil
     |
     |  unregister_tool(self, name: str) -> None
     |      D�senregistre un outil MCP.
     |
     |      Args:
     |          name (str): Nom de l'outil
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
    tool(name: Optional[str] = None, description: Optional[str] = None, parameters: Optional[Dict[str, Any]] = None)
        D�corateur pour marquer une fonction comme un outil MCP.

        Args:
            name (Optional[str], optional): Nom de l'outil. Si None, le nom de la fonction sera utilis�.
            description (Optional[str], optional): Description de l'outil. Si None, la docstring de la fonction sera utilis�e.
            parameters (Optional[Dict[str, Any]], optional): Param�tres de l'outil. Si None, ils seront d�riv�s de la signature de la fonction.

        Returns:
            Callable: D�corateur

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

    logger = <Logger mcp.core.tools_manager (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\mcp\tools_manager.py


