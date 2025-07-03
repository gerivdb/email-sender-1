Help on module fastmcp:

NAME
    fastmcp - Implémentation minimale d'un serveur MCP basé sur FastAPI.

DESCRIPTION
    Ce module fournit une implémentation minimale d'un serveur MCP
    pour tester les outils de mémoire.

CLASSES
    builtins.object
        FastMCP

    class FastMCP(builtins.object)
     |  FastMCP(name: str)
     |
     |  Implémentation minimale d'un serveur MCP basé sur FastAPI.
     |
     |  Cette classe fournit une implémentation minimale pour tester les outils MCP.
     |  Dans une implémentation réelle, elle utiliserait FastAPI pour exposer les outils
     |  via une API REST ou WebSocket.
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str)
     |      Initialise le serveur MCP.
     |
     |      Args:
     |          name (str): Nom du serveur MCP
     |
     |  run(self, host: str = '127.0.0.1', port: int = 8000)
     |      Démarre le serveur MCP.
     |
     |      Dans une implémentation réelle, cette méthode démarrerait un serveur FastAPI.
     |      Pour cette implémentation minimale, elle affiche simplement les outils disponibles
     |      et entre dans une boucle interactive pour tester les outils.
     |
     |      Args:
     |          host (str, optional): Hôte sur lequel écouter. Par défaut "127.0.0.1".
     |          port (int, optional): Port sur lequel écouter. Par défaut 8000.
     |
     |  tool(self, schema: Dict[str, Any] = None)
     |      Décorateur pour enregistrer un outil MCP.
     |
     |      Args:
     |          schema (Dict[str, Any], optional): Schéma JSON de l'outil
     |
     |      Returns:
     |          Callable: Décorateur pour enregistrer l'outil
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

    logger = <Logger mcp.server.fastmcp (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\server\fastmcp.py


