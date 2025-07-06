Help on module github_tools:

NAME
    github_tools - Module contenant des outils pour interagir avec GitHub.

DESCRIPTION
    Ce module fournit des outils pour récupérer des informations sur les dépôts GitHub,
    analyser le code, etc.

CLASSES
    builtins.object
        GitHubTools

    class GitHubTools(builtins.object)
     |  Classe contenant des outils pour interagir avec GitHub.
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
     |  get_file_content = StructuredTool(name='get_file_content', descript......
     |
     |  get_repo_info = StructuredTool(name='get_repo_info', description...Git...
     |
     |  list_repo_branches = StructuredTool(name='list_repo_branches', descri....
     |
     |  list_repo_contents = StructuredTool(name='list_repo_contents', descri....
     |
     |  search_code = StructuredTool(name='search_code', description='...n Git...

DATA
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\tools\github_tools.py


