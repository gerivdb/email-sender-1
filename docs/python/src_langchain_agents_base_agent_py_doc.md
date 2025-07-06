Help on module base_agent:

NAME
    base_agent - Module contenant la classe de base pour les agents Langchain.

DESCRIPTION
    Ce module fournit une classe de base pour les agents Langchain qui peuvent être utilisés
    dans différents contextes du projet EMAIL_SENDER_1.

CLASSES
    builtins.object
        BaseAgent

    class BaseAgent(builtins.object)
     |  BaseAgent(llm: langchain_core.language_models.base.BaseLanguageModel, tools: Sequence[langchain_core.tools.base.BaseTool], agent_type: str = 'react', prompt_template: Union[str, langchain_core.prompts.prompt.PromptTemplate, langchain_core.prompts.chat.ChatPromptTemplate, NoneType] = None, verbose: bool = False, handle_parsing_errors: bool = True)
     |
     |  Classe de base pour les agents Langchain du projet EMAIL_SENDER_1.
     |
     |  Cette classe fournit une interface commune et des fonctionnalités partagées
     |  pour tous les agents Langchain utilisés dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.base.BaseLanguageModel, tools: Sequence[langchain_core.tools.base.BaseTool], agent_type: str = 'react', prompt_template: Union[str, langchain_core.prompts.prompt.PromptTemplate, langchain_core.prompts.chat.ChatPromptTemplate, NoneType] = None, verbose: bool = False, handle_parsing_errors: bool = True)
     |      Initialise une nouvelle instance de BaseAgent.
     |
     |      Args:
     |          llm: Le modèle de langage à utiliser
     |          tools: Les outils à mettre à disposition de l'agent
     |          agent_type: Le type d'agent à créer ("react" ou "openai_functions")
     |          prompt_template: Le template de prompt à utiliser (optionnel)
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |          handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
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
     |  Data descriptors defined here:
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

    Sequence = typing.Sequence
        A generic version of collections.abc.Sequence.

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
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\agents\base_agent.py


