Help on module exceptions:

NAME
    exceptions - Module pour les exceptions sp�cifiques � l'architecture cognitive des roadmaps.

MODULE REFERENCE
    https://docs.python.org/3.12/library/exceptions.html

    The following documentation is automatically generated from the Python
    source files.  It may be incomplete, incorrect or include features that
    are considered implementation detail and may vary between Python
    implementations.  When in doubt, consult the module reference at the
    location listed above.

DESCRIPTION
    Ce module contient les exceptions personnalis�es pour l'architecture cognitive des roadmaps.

CLASSES
    builtins.Exception(builtins.BaseException)
        CognitiveArchitectureError
            CircularReferenceError
            InvalidNodeDataError
            InvalidParentError
            NodeHasChildrenError
            NodeNotFoundError
            StorageError

    class CircularReferenceError(CognitiveArchitectureError)
     |  CircularReferenceError(node_id: str, parent_id: str, path: Optional[List[str]] = None)
     |
     |  Exception lev�e lorsqu'une r�f�rence circulaire est d�tect�e.
     |
     |  Method resolution order:
     |      CircularReferenceError
     |      CognitiveArchitectureError
     |      builtins.Exception
     |      builtins.BaseException
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, node_id: str, parent_id: str, path: Optional[List[str]] = None)
     |      Initialise l'exception.
     |
     |      Args:
     |          node_id (str): Identifiant du n�ud
     |          parent_id (str): Identifiant du parent
     |          path (list, optional): Chemin de la r�f�rence circulaire. Par d�faut None.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveArchitectureError:
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from builtins.Exception:
     |
     |  __new__(*args, **kwargs) class method of builtins.Exception
     |      Create and return a new object.  See help(type) for accurate signature.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from builtins.BaseException:
     |
     |  __getattribute__(self, name, /)
     |      Return getattr(self, name).
     |
     |  __reduce__(...)
     |      Helper for pickle.
     |
     |  __repr__(self, /)
     |      Return repr(self).
     |
     |  __setstate__(...)
     |
     |  __str__(self, /)
     |      Return str(self).
     |
     |  add_note(...)
     |      Exception.add_note(note) --
     |      add a note to the exception
     |
     |  with_traceback(...)
     |      Exception.with_traceback(tb) --
     |      set self.__traceback__ to tb and return self.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from builtins.BaseException:
     |
     |  __cause__
     |      exception cause
     |
     |  __context__
     |      exception context
     |
     |  __dict__
     |
     |  __suppress_context__
     |
     |  __traceback__
     |
     |  args

    class CognitiveArchitectureError(builtins.Exception)
     |  Exception de base pour l'architecture cognitive des roadmaps.
     |
     |  Method resolution order:
     |      CognitiveArchitectureError
     |      builtins.Exception
     |      builtins.BaseException
     |      builtins.object
     |
     |  Data descriptors defined here:
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from builtins.Exception:
     |
     |  __init__(self, /, *args, **kwargs)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from builtins.Exception:
     |
     |  __new__(*args, **kwargs) class method of builtins.Exception
     |      Create and return a new object.  See help(type) for accurate signature.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from builtins.BaseException:
     |
     |  __getattribute__(self, name, /)
     |      Return getattr(self, name).
     |
     |  __reduce__(...)
     |      Helper for pickle.
     |
     |  __repr__(self, /)
     |      Return repr(self).
     |
     |  __setstate__(...)
     |
     |  __str__(self, /)
     |      Return str(self).
     |
     |  add_note(...)
     |      Exception.add_note(note) --
     |      add a note to the exception
     |
     |  with_traceback(...)
     |      Exception.with_traceback(tb) --
     |      set self.__traceback__ to tb and return self.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from builtins.BaseException:
     |
     |  __cause__
     |      exception cause
     |
     |  __context__
     |      exception context
     |
     |  __dict__
     |
     |  __suppress_context__
     |
     |  __traceback__
     |
     |  args

    class InvalidNodeDataError(CognitiveArchitectureError)
     |  InvalidNodeDataError(data: dict, missing_field: Optional[str] = None)
     |
     |  Exception lev�e lorsque les donn�es d'un n�ud sont invalides.
     |
     |  Method resolution order:
     |      InvalidNodeDataError
     |      CognitiveArchitectureError
     |      builtins.Exception
     |      builtins.BaseException
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, data: dict, missing_field: Optional[str] = None)
     |      Initialise l'exception.
     |
     |      Args:
     |          data (dict): Donn�es du n�ud
     |          missing_field (str, optional): Champ manquant. Par d�faut None.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveArchitectureError:
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from builtins.Exception:
     |
     |  __new__(*args, **kwargs) class method of builtins.Exception
     |      Create and return a new object.  See help(type) for accurate signature.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from builtins.BaseException:
     |
     |  __getattribute__(self, name, /)
     |      Return getattr(self, name).
     |
     |  __reduce__(...)
     |      Helper for pickle.
     |
     |  __repr__(self, /)
     |      Return repr(self).
     |
     |  __setstate__(...)
     |
     |  __str__(self, /)
     |      Return str(self).
     |
     |  add_note(...)
     |      Exception.add_note(note) --
     |      add a note to the exception
     |
     |  with_traceback(...)
     |      Exception.with_traceback(tb) --
     |      set self.__traceback__ to tb and return self.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from builtins.BaseException:
     |
     |  __cause__
     |      exception cause
     |
     |  __context__
     |      exception context
     |
     |  __dict__
     |
     |  __suppress_context__
     |
     |  __traceback__
     |
     |  args

    class InvalidParentError(CognitiveArchitectureError)
     |  InvalidParentError(parent_id: str, expected_level: str, actual_level: Optional[str] = None)
     |
     |  Exception lev�e lorsqu'un parent est invalide.
     |
     |  Method resolution order:
     |      InvalidParentError
     |      CognitiveArchitectureError
     |      builtins.Exception
     |      builtins.BaseException
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, parent_id: str, expected_level: str, actual_level: Optional[str] = None)
     |      Initialise l'exception.
     |
     |      Args:
     |          parent_id (str): Identifiant du parent invalide
     |          expected_level (str): Niveau hi�rarchique attendu
     |          actual_level (str, optional): Niveau hi�rarchique actuel. Par d�faut None.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveArchitectureError:
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from builtins.Exception:
     |
     |  __new__(*args, **kwargs) class method of builtins.Exception
     |      Create and return a new object.  See help(type) for accurate signature.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from builtins.BaseException:
     |
     |  __getattribute__(self, name, /)
     |      Return getattr(self, name).
     |
     |  __reduce__(...)
     |      Helper for pickle.
     |
     |  __repr__(self, /)
     |      Return repr(self).
     |
     |  __setstate__(...)
     |
     |  __str__(self, /)
     |      Return str(self).
     |
     |  add_note(...)
     |      Exception.add_note(note) --
     |      add a note to the exception
     |
     |  with_traceback(...)
     |      Exception.with_traceback(tb) --
     |      set self.__traceback__ to tb and return self.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from builtins.BaseException:
     |
     |  __cause__
     |      exception cause
     |
     |  __context__
     |      exception context
     |
     |  __dict__
     |
     |  __suppress_context__
     |
     |  __traceback__
     |
     |  args

    class NodeHasChildrenError(CognitiveArchitectureError)
     |  NodeHasChildrenError(node_id: str, children_count: int)
     |
     |  Exception lev�e lorsqu'un n�ud a des enfants et ne peut pas �tre supprim�.
     |
     |  Method resolution order:
     |      NodeHasChildrenError
     |      CognitiveArchitectureError
     |      builtins.Exception
     |      builtins.BaseException
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, node_id: str, children_count: int)
     |      Initialise l'exception.
     |
     |      Args:
     |          node_id (str): Identifiant du n�ud
     |          children_count (int): Nombre d'enfants
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveArchitectureError:
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from builtins.Exception:
     |
     |  __new__(*args, **kwargs) class method of builtins.Exception
     |      Create and return a new object.  See help(type) for accurate signature.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from builtins.BaseException:
     |
     |  __getattribute__(self, name, /)
     |      Return getattr(self, name).
     |
     |  __reduce__(...)
     |      Helper for pickle.
     |
     |  __repr__(self, /)
     |      Return repr(self).
     |
     |  __setstate__(...)
     |
     |  __str__(self, /)
     |      Return str(self).
     |
     |  add_note(...)
     |      Exception.add_note(note) --
     |      add a note to the exception
     |
     |  with_traceback(...)
     |      Exception.with_traceback(tb) --
     |      set self.__traceback__ to tb and return self.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from builtins.BaseException:
     |
     |  __cause__
     |      exception cause
     |
     |  __context__
     |      exception context
     |
     |  __dict__
     |
     |  __suppress_context__
     |
     |  __traceback__
     |
     |  args

    class NodeNotFoundError(CognitiveArchitectureError)
     |  NodeNotFoundError(node_id: str, message: Optional[str] = None)
     |
     |  Exception lev�e lorsqu'un n�ud n'est pas trouv�.
     |
     |  Method resolution order:
     |      NodeNotFoundError
     |      CognitiveArchitectureError
     |      builtins.Exception
     |      builtins.BaseException
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, node_id: str, message: Optional[str] = None)
     |      Initialise l'exception.
     |
     |      Args:
     |          node_id (str): Identifiant du n�ud non trouv�
     |          message (str, optional): Message d'erreur personnalis�. Par d�faut None.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveArchitectureError:
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from builtins.Exception:
     |
     |  __new__(*args, **kwargs) class method of builtins.Exception
     |      Create and return a new object.  See help(type) for accurate signature.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from builtins.BaseException:
     |
     |  __getattribute__(self, name, /)
     |      Return getattr(self, name).
     |
     |  __reduce__(...)
     |      Helper for pickle.
     |
     |  __repr__(self, /)
     |      Return repr(self).
     |
     |  __setstate__(...)
     |
     |  __str__(self, /)
     |      Return str(self).
     |
     |  add_note(...)
     |      Exception.add_note(note) --
     |      add a note to the exception
     |
     |  with_traceback(...)
     |      Exception.with_traceback(tb) --
     |      set self.__traceback__ to tb and return self.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from builtins.BaseException:
     |
     |  __cause__
     |      exception cause
     |
     |  __context__
     |      exception context
     |
     |  __dict__
     |
     |  __suppress_context__
     |
     |  __traceback__
     |
     |  args

    class StorageError(CognitiveArchitectureError)
     |  StorageError(node_id: str, operation: str, cause: Optional[Exception] = None)
     |
     |  Exception lev�e lors d'une erreur de stockage.
     |
     |  Method resolution order:
     |      StorageError
     |      CognitiveArchitectureError
     |      builtins.Exception
     |      builtins.BaseException
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, node_id: str, operation: str, cause: Optional[Exception] = None)
     |      Initialise l'exception.
     |
     |      Args:
     |          node_id (str): Identifiant du n�ud
     |          operation (str): Op�ration qui a �chou�
     |          cause (Exception, optional): Cause de l'erreur. Par d�faut None.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from CognitiveArchitectureError:
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from builtins.Exception:
     |
     |  __new__(*args, **kwargs) class method of builtins.Exception
     |      Create and return a new object.  See help(type) for accurate signature.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from builtins.BaseException:
     |
     |  __getattribute__(self, name, /)
     |      Return getattr(self, name).
     |
     |  __reduce__(...)
     |      Helper for pickle.
     |
     |  __repr__(self, /)
     |      Return repr(self).
     |
     |  __setstate__(...)
     |
     |  __str__(self, /)
     |      Return str(self).
     |
     |  add_note(...)
     |      Exception.add_note(note) --
     |      add a note to the exception
     |
     |  with_traceback(...)
     |      Exception.with_traceback(tb) --
     |      set self.__traceback__ to tb and return self.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from builtins.BaseException:
     |
     |  __cause__
     |      exception cause
     |
     |  __context__
     |      exception context
     |
     |  __dict__
     |
     |  __suppress_context__
     |
     |  __traceback__
     |
     |  args

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
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\roadmap\exceptions.py


