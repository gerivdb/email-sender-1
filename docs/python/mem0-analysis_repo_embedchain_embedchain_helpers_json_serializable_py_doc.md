Help on module json_serializable:

NAME
    json_serializable

CLASSES
    builtins.object
        JSONSerializable

    class JSONSerializable(builtins.object)
     |  A class to represent a JSON serializable object.
     |
     |  This class provides methods to serialize and deserialize objects,
     |  as well as to save serialized objects to a file and load them back.
     |
     |  Methods defined here:
     |
     |  save_to_file(self, filename: str) -> None
     |      Save the serialized object to a file.
     |
     |      Args:
     |          filename (str): The path to the file where the object should be saved.
     |
     |  serialize(self) -> str
     |      Serialize the object to a JSON-formatted string.
     |
     |      Returns:
     |          str: A JSON string representation of the object.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  deserialize(json_str: str) -> Any
     |      Deserialize a JSON-formatted string to an object.
     |      If it fails, a default class is returned instead.
     |      Note: This *returns* an instance, it's not automatically loaded on the calling class.
     |
     |      Example:
     |          app = App.deserialize(json_str)
     |
     |      Args:
     |          json_str (str): A JSON string representation of an object.
     |
     |      Returns:
     |          Object: The deserialized object.
     |
     |  load_from_file(filename: str) -> Any
     |      Load and deserialize an object from a file.
     |
     |      Args:
     |          filename (str): The path to the file from which the object should be loaded.
     |
     |      Returns:
     |          Object: The deserialized object.
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
    register_deserializable(cls: Type[~T]) -> Type[~T]
        A class decorator to register a class as deserializable.

        When a class is decorated with @register_deserializable, it becomes
        a part of the set of classes that the JSONSerializable class can
        deserialize.

        Deserialization is in essence loading attributes from a json file.
        This decorator is a security measure put in place to make sure that
        you don't load attributes that were initially part of another class.

        Example:
            @register_deserializable
            class ChildClass(JSONSerializable):
                def __init__(self, ...):
                    # initialization logic

        Args:
            cls (Type): The class to be registered.

        Returns:
            Type: The same class, after registration.

DATA
    T = ~T
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

    logger = <Logger json_serializable (WARNING)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\embedchain\embedchain\helpers\json_serializable.py


