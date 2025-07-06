Help on module performance_analysis_tools:

NAME
    performance_analysis_tools - Module contenant des outils pour l'analyse de performance.

DESCRIPTION
    Ce module fournit des outils pour analyser les performances des applications,
    mesurer les temps d'exécution, identifier les goulots d'étranglement, etc.

CLASSES
    builtins.object
        PerformanceAnalysisTools

    class PerformanceAnalysisTools(builtins.object)
     |  Classe contenant des outils pour l'analyse de performance.
     |
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
     |  analyze_performance_data = StructuredTool(name='analyze_performance_da...
     |
     |  clear_performance_data = StructuredTool(name='clear_performance_data',...
     |
     |  measure_endpoint_performance = StructuredTool(name='measure_endpoint_p...
     |
     |  measure_function_performance = StructuredTool(name='measure_function_p...
     |
     |  record_custom_metric = StructuredTool(name='record_custom_metric', des...

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

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\tools\performance_analysis_tools.py


