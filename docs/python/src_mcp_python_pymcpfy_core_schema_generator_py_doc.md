Help on module schema_generator:

NAME
    schema_generator - Schema generator for MCP functions.

CLASSES
    builtins.object
        SchemaGenerator

    class SchemaGenerator(builtins.object)
     |  Generate MCP schema from Python functions.
     |
     |  Static methods defined here:
     |
     |  generate_parameter_schema(func: Callable) -> Dict[str, Dict[str, Any]]
     |      Generate parameter schema from function signature.
     |
     |  generate_return_schema(func: Callable) -> Dict[str, Any]
     |      Generate return type schema from function.
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\python\pymcpfy\core\schema_generator.py


