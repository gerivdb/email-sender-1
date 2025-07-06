Help on module tool_interfaces:

NAME
    tool_interfaces

DESCRIPTION
    Module d�finissant les interfaces de base pour les outils MCP.
    Ce module fournit des classes abstraites et des interfaces pour les outils MCP.

CLASSES
    abc.ABC(builtins.object)
        MCPTool
    builtins.object
        ToolParameter
        ToolRegistry
    typing.Generic(builtins.object)
        ToolResult

    class MCPTool(abc.ABC)
     |  MCPTool(name: str, description: str)
     |
     |  Classe abstraite pour les outils MCP.
     |
     |  Method resolution order:
     |      MCPTool
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, description: str)
     |      Initialise un outil MCP.
     |
     |      Args:
     |          name: Nom de l'outil.
     |          description: Description de l'outil.
     |
     |  __repr__(self) -> str
     |      Repr�sentation de l'outil.
     |
     |      Returns:
     |          Repr�sentation sous forme de cha�ne.
     |
     |  execute(self, **kwargs) -> tool_interfaces.ToolResult
     |      Ex�cute l'outil avec les param�tres fournis.
     |
     |      Args:
     |          **kwargs: Param�tres de l'outil.
     |
     |      Returns:
     |          R�sultat de l'ex�cution.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit l'outil en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire repr�sentant l'outil.
     |
     |  to_json_schema(self) -> Dict[str, Any]
     |      Convertit l'outil en sch�ma JSON.
     |
     |      Returns:
     |          Sch�ma JSON repr�sentant l'outil.
     |
     |  validate_parameters(self, **kwargs) -> Tuple[bool, Optional[str]]
     |      Valide les param�tres fournis.
     |
     |      Args:
     |          **kwargs: Param�tres � valider.
     |
     |      Returns:
     |          Tuple (valide, message d'erreur).
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
     |  __abstractmethods__ = frozenset({'execute'})

    class ToolParameter(builtins.object)
     |  ToolParameter(name: str, type_: Type, description: str, required: bool = True, default: Any = None, enum: Optional[List[Any]] = None)
     |
     |  Classe repr�sentant un param�tre d'outil MCP.
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str, type_: Type, description: str, required: bool = True, default: Any = None, enum: Optional[List[Any]] = None)
     |      Initialise un param�tre d'outil.
     |
     |      Args:
     |          name: Nom du param�tre.
     |          type_: Type du param�tre.
     |          description: Description du param�tre.
     |          required: Si le param�tre est requis.
     |          default: Valeur par d�faut du param�tre.
     |          enum: Liste des valeurs possibles pour le param�tre.
     |
     |  __repr__(self) -> str
     |      Repr�sentation du param�tre.
     |
     |      Returns:
     |          Repr�sentation sous forme de cha�ne.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le param�tre en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire repr�sentant le param�tre.
     |
     |  validate(self, value: Any) -> bool
     |      Valide une valeur pour ce param�tre.
     |
     |      Args:
     |          value: Valeur � valider.
     |
     |      Returns:
     |          True si la valeur est valide, False sinon.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'ToolParameter'
     |      Cr�e un param�tre � partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire repr�sentant le param�tre.
     |
     |      Returns:
     |          Param�tre cr��.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class ToolRegistry(builtins.object)
     |  Registre des outils MCP disponibles.
     |
     |  Methods defined here:
     |
     |  __contains__(self, name: str) -> bool
     |      V�rifie si un outil est dans le registre.
     |
     |      Args:
     |          name: Nom de l'outil.
     |
     |      Returns:
     |          True si l'outil est dans le registre, False sinon.
     |
     |  __init__(self)
     |      Initialise le registre d'outils.
     |
     |  __iter__(self)
     |      It�re sur les outils du registre.
     |
     |      Returns:
     |          It�rateur sur les outils.
     |
     |  __len__(self) -> int
     |      Retourne le nombre d'outils dans le registre.
     |
     |      Returns:
     |          Nombre d'outils.
     |
     |  get(self, name: str) -> Optional[tool_interfaces.MCPTool]
     |      R�cup�re un outil par son nom.
     |
     |      Args:
     |          name: Nom de l'outil.
     |
     |      Returns:
     |          Outil correspondant ou None si non trouv�.
     |
     |  get_tool_descriptions(self) -> List[Dict[str, Any]]
     |      R�cup�re les descriptions de tous les outils.
     |
     |      Returns:
     |          Liste des descriptions d'outils.
     |
     |  list_tools(self) -> List[str]
     |      Liste les noms des outils disponibles.
     |
     |      Returns:
     |          Liste des noms d'outils.
     |
     |  register(self, tool: tool_interfaces.MCPTool) -> None
     |      Enregistre un outil dans le registre.
     |
     |      Args:
     |          tool: Outil � enregistrer.
     |
     |  to_json_schema(self) -> Dict[str, Any]
     |      Convertit le registre en sch�ma JSON.
     |
     |      Returns:
     |          Sch�ma JSON repr�sentant le registre.
     |
     |  unregister(self, name: str) -> bool
     |      D�senregistre un outil du registre.
     |
     |      Args:
     |          name: Nom de l'outil � d�senregistrer.
     |
     |      Returns:
     |          True si l'outil a �t� d�senregistr�, False sinon.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class ToolResult(typing.Generic)
     |  ToolResult(success: bool, data: Optional[~T] = None, error: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None)
     |
     |  Classe repr�sentant le r�sultat d'un outil MCP.
     |
     |  Method resolution order:
     |      ToolResult
     |      typing.Generic
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, success: bool, data: Optional[~T] = None, error: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None)
     |      Initialise un r�sultat d'outil.
     |
     |      Args:
     |          success: Si l'ex�cution a r�ussi.
     |          data: Donn�es du r�sultat.
     |          error: Message d'erreur en cas d'�chec.
     |          metadata: M�tadonn�es associ�es au r�sultat.
     |
     |  __repr__(self) -> str
     |      Repr�sentation du r�sultat.
     |
     |      Returns:
     |          Repr�sentation sous forme de cha�ne.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le r�sultat en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire repr�sentant le r�sultat.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  failure(error: str, metadata: Optional[Dict[str, Any]] = None) -> 'ToolResult[T]'
     |      Cr�e un r�sultat d'�chec.
     |
     |      Args:
     |          error: Message d'erreur.
     |          metadata: M�tadonn�es associ�es au r�sultat.
     |
     |      Returns:
     |          R�sultat d'�chec.
     |
     |  success(data: ~T, metadata: Optional[Dict[str, Any]] = None) -> 'ToolResult[T]'
     |      Cr�e un r�sultat de succ�s.
     |
     |      Args:
     |          data: Donn�es du r�sultat.
     |          metadata: M�tadonn�es associ�es au r�sultat.
     |
     |      Returns:
     |          R�sultat de succ�s.
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
     |  __orig_bases__ = (typing.Generic[~T],)
     |
     |  __parameters__ = (~T,)
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
     |
     |  __init_subclass__(...)
     |      Function to initialize subclasses.

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

    T = ~T
    Tuple = typing.Tuple
        Deprecated alias to builtins.tuple.

        Tuple[X, Y] is the cross-product type of X and Y.

        Example: Tuple[T1, T2] is a tuple of two elements corresponding
        to type variables T1 and T2.  Tuple[int, float, str] is a tuple
        of an int, a float and a string.

        To specify a variable-length tuple of homogeneous type, use Tuple[T, ...].

    Type = typing.Type
        Deprecated alias to builtins.type.

        builtins.type or typing.Type can be used to annotate class objects.
        For example, suppose we have the following classes::

            class User: ...  # Abstract base for User classes
            class BasicUser(User): ...
            class ProUser(User): ...
            class TeamUser(User): ...

        And a function that takes a class argument that's a subclass of
        User and returns an instance of the corresponding class::

            def new_user[U](user_class: Type[U]) -> U:
                user = user_class()
                # (Here we could write the user object to a database)
                return user

            joe = new_user(BasicUser)

        At this point the type checker knows that joe has type BasicUser.

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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\mcp\tool_interfaces.py


