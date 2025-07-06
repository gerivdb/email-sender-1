Help on module context:

NAME
    context - Context object for MCP-wrapped functions.

CLASSES
    builtins.object
        MCPContext

    class MCPContext(builtins.object)
     |  MCPContext(transport: Any, connection: Any, metadata: Dict[str, Any] = <factory>, raw_request: Optional[Dict[str, Any]] = None) -> None
     |
     |  Context object passed to MCP-wrapped functions.
     |
     |  Methods defined here:
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __init__(self, transport: Any, connection: Any, metadata: Dict[str, Any] = <factory>, raw_request: Optional[Dict[str, Any]] = None) -> None
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  __repr__(self)
     |      Return repr(self).
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
     |  __annotations__ = {'connection': typing.Any, 'metadata': typing.Dict[s...
     |
     |  __dataclass_fields__ = {'connection': Field(name='connection',type=typ...
     |
     |  __dataclass_params__ = _DataclassParams(init=True,repr=True,eq=True,or...
     |
     |  __hash__ = None
     |
     |  __match_args__ = ('transport', 'connection', 'metadata', 'raw_request'...
     |
     |  raw_request = None

DATA
    Dict = typing.Dict
        A generic version of dict.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\python\pymcpfy\core\context.py


