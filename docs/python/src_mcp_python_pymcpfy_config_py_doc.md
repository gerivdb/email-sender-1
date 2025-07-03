Help on module config:

NAME
    config - Configuration management for PyMCPfy.

CLASSES
    builtins.object
        MCPConfig
        TransportConfig

    class MCPConfig(builtins.object)
     |  MCPConfig(transport: config.TransportConfig = <factory>, backend_url: Optional[str] = None, debug: bool = False, cors_origins: List[str] = <factory>) -> None
     |
     |  Configuration for PyMCPfy.
     |
     |  Methods defined here:
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __init__(self, transport: config.TransportConfig = <factory>, backend_url: Optional[str] = None, debug: bool = False, cors_origins: List[str] = <factory>) -> None
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  __post_init__(self)
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(config_dict: dict) -> 'MCPConfig'
     |      Load configuration from dictionary.
     |
     |  from_file(path: str) -> 'MCPConfig'
     |      Load configuration from YAML file.
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
     |  __annotations__ = {'backend_url': typing.Optional[str], 'cors_origins'...
     |
     |  __dataclass_fields__ = {'backend_url': Field(name='backend_url',type=t...
     |
     |  __dataclass_params__ = _DataclassParams(init=True,repr=True,eq=True,or...
     |
     |  __hash__ = None
     |
     |  __match_args__ = ('transport', 'backend_url', 'debug', 'cors_origins')
     |
     |  backend_url = None
     |
     |  debug = False

    class TransportConfig(builtins.object)
     |  TransportConfig(type: str = 'websocket', host: str = '0.0.0.0', port: int = 8765, ping_interval: int = 30, ping_timeout: int = 30) -> None
     |
     |  Configuration for MCP transport.
     |
     |  Methods defined here:
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __init__(self, type: str = 'websocket', host: str = '0.0.0.0', port: int = 8765, ping_interval: int = 30, ping_timeout: int = 30) -> None
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
     |  __annotations__ = {'host': <class 'str'>, 'ping_interval': <class 'int...
     |
     |  __dataclass_fields__ = {'host': Field(name='host',type=<class 'str'>,d...
     |
     |  __dataclass_params__ = _DataclassParams(init=True,repr=True,eq=True,or...
     |
     |  __hash__ = None
     |
     |  __match_args__ = ('type', 'host', 'port', 'ping_interval', 'ping_timeo...
     |
     |  host = '0.0.0.0'
     |
     |  ping_interval = 30
     |
     |  ping_timeout = 30
     |
     |  port = 8765
     |
     |  type = 'websocket'

FUNCTIONS
    load_config(config: Union[str, dict, NoneType] = None) -> config.MCPConfig
        Load configuration from file, dict, or environment variables.

DATA
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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\python\pymcpfy\config.py


