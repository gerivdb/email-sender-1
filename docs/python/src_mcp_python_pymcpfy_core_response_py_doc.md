Help on module response:

NAME
    response - MCP response module.

CLASSES
    builtins.object
        MCPResponse

    class MCPResponse(builtins.object)
     |  MCPResponse(data: Any, status: int = 200, metadata: Dict[str, Any] = <factory>) -> None
     |
     |  Response from MCP request.
     |
     |  Methods defined here:
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __init__(self, data: Any, status: int = 200, metadata: Dict[str, Any] = <factory>) -> None
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convert response to dictionary.
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
     |  __annotations__ = {'data': typing.Any, 'metadata': typing.Dict[str, ty...
     |
     |  __dataclass_fields__ = {'data': Field(name='data',type=typing.Any,defa...
     |
     |  __dataclass_params__ = _DataclassParams(init=True,repr=True,eq=True,or...
     |
     |  __hash__ = None
     |
     |  __match_args__ = ('data', 'status', 'metadata')
     |
     |  status = 200

DATA
    Dict = typing.Dict
        A generic version of dict.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\python\pymcpfy\core\response.py


