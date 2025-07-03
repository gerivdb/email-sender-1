Help on module performance_analysis_agent:

NAME
    performance_analysis_agent - Module contenant l'agent d'analyse de performance.

DESCRIPTION
    Ce module fournit une implémentation spécifique de BaseAgent pour
    analyser les performances des applications dans le cadre du projet EMAIL_SENDER_1.

CLASSES
    src.langchain.agents.base_agent.BaseAgent(builtins.object)
        PerformanceAnalysisAgent

    class PerformanceAnalysisAgent(src.langchain.agents.base_agent.BaseAgent)
     |  PerformanceAnalysisAgent(llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |
     |  Agent spécialisé dans l'analyse de performance.
     |
     |  Cet agent utilise les outils d'analyse de performance pour mesurer et analyser
     |  les performances des applications, identifier les goulots d'étranglement et
     |  proposer des optimisations.
     |
     |  Method resolution order:
     |      PerformanceAnalysisAgent
     |      src.langchain.agents.base_agent.BaseAgent
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |      Initialise une nouvelle instance de PerformanceAnalysisAgent.
     |
     |      Args:
     |          llm: Le modèle de langage à utiliser
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |          handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
     |
     |  analyze_all_performance_data(self) -> Dict[str, Any]
     |      Analyse toutes les données de performance collectées.
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse globale des performances
     |
     |  analyze_endpoint_performance(self, url: str, method: str = 'GET', iterations: int = 5) -> Dict[str, Any]
     |      Analyse les performances d'un endpoint HTTP.
     |
     |      Args:
     |          url: URL de l'endpoint
     |          method: Méthode HTTP (défaut: GET)
     |          iterations: Nombre d'itérations (défaut: 5)
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse des performances
     |
     |  compare_endpoints(self, endpoints: List[Dict[str, Any]]) -> Dict[str, Any]
     |      Compare les performances de plusieurs endpoints.
     |
     |      Args:
     |          endpoints: Liste de dictionnaires contenant les informations des endpoints
     |                    (chaque dictionnaire doit avoir les clés 'url' et 'method')
     |
     |      Returns:
     |          Dictionnaire contenant la comparaison des performances
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Exécute l'agent avec les entrées fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entrée
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
     |      Exécute l'agent avec le texte d'entrée fourni.
     |
     |      Args:
     |          input_text: Texte d'entrée pour l'agent
     |
     |      Returns:
     |          La sortie générée par l'agent
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\agents\performance_analysis_agent.py


