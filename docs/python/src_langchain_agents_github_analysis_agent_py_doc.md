Help on module github_analysis_agent:

NAME
    github_analysis_agent - Module contenant l'agent d'analyse de d�p�t GitHub.

DESCRIPTION
    Ce module fournit une impl�mentation sp�cifique de BaseAgent pour
    analyser les d�p�ts GitHub dans le cadre du projet EMAIL_SENDER_1.

CLASSES
    src.langchain.agents.base_agent.BaseAgent(builtins.object)
        GitHubAnalysisAgent

    class GitHubAnalysisAgent(src.langchain.agents.base_agent.BaseAgent)
     |  GitHubAnalysisAgent(llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |
     |  Agent sp�cialis� dans l'analyse des d�p�ts GitHub.
     |
     |  Cet agent utilise les outils GitHub pour analyser les d�p�ts,
     |  explorer le code, et fournir des insights sur la structure et le contenu.
     |
     |  Method resolution order:
     |      GitHubAnalysisAgent
     |      src.langchain.agents.base_agent.BaseAgent
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |      Initialise une nouvelle instance de GitHubAnalysisAgent.
     |
     |      Args:
     |          llm: Le mod�le de langage � utiliser
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |          handle_parsing_errors: G�rer les erreurs de parsing (d�faut: True)
     |
     |  analyze_repository(self, repo_owner: str, repo_name: str) -> Dict[str, Any]
     |      Analyse un d�p�t GitHub et fournit un rapport d�taill�.
     |
     |      Args:
     |          repo_owner: Propri�taire du d�p�t (utilisateur ou organisation)
     |          repo_name: Nom du d�p�t
     |
     |      Returns:
     |          Dictionnaire contenant le rapport d'analyse
     |
     |  search_repository(self, repo_owner: str, repo_name: str, query: str) -> Dict[str, Any]
     |      Recherche du code dans un d�p�t GitHub et fournit une analyse des r�sultats.
     |
     |      Args:
     |          repo_owner: Propri�taire du d�p�t (utilisateur ou organisation)
     |          repo_name: Nom du d�p�t
     |          query: Requ�te de recherche
     |
     |      Returns:
     |          Dictionnaire contenant les r�sultats de recherche et l'analyse
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Ex�cute l'agent avec les entr�es fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entr�e
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_tools(self) -> List[langchain_core.tools.base.BaseTool]
     |      Retourne la liste des outils disponibles pour l'agent.
     |
     |      Returns:
     |          Liste des outils
     |
     |  run(self, input_text: str) -> str
     |      Ex�cute l'agent avec le texte d'entr�e fourni.
     |
     |      Args:
     |          input_text: Texte d'entr�e pour l'agent
     |
     |      Returns:
     |          La sortie g�n�r�e par l'agent
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

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
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\agents\github_analysis_agent.py


