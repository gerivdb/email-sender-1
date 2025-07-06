Help on module email_response_router_chain:

NAME
    email_response_router_chain - Module contenant une chaîne de routage pour les réponses aux emails.

DESCRIPTION
    Ce module fournit une implémentation spécifique de BaseRouterChain pour
    router les réponses aux emails vers différentes chaînes de traitement
    en fonction du type de réponse.

CLASSES
    src.langchain.chains.router_chains.base_router_chain.BaseRouterChain(builtins.object)
        EmailResponseRouterChain

    class EmailResponseRouterChain(src.langchain.chains.router_chains.base_router_chain.BaseRouterChain)
     |  EmailResponseRouterChain(llm: langchain_core.language_models.llms.BaseLLM, verbose: bool = False)
     |
     |  Chaîne de routage pour les réponses aux emails.
     |
     |  Cette chaîne analyse les réponses aux emails et les route vers différentes
     |  chaînes de traitement en fonction du type de réponse.
     |
     |  Method resolution order:
     |      EmailResponseRouterChain
     |      src.langchain.chains.router_chains.base_router_chain.BaseRouterChain
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.llms.BaseLLM, verbose: bool = False)
     |      Initialise une nouvelle instance de EmailResponseRouterChain.
     |
     |      Args:
     |          llm: Le modèle de langage à utiliser
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |
     |  route_email_response(self, email_response: str) -> str
     |      Route une réponse d'email vers la chaîne de traitement appropriée.
     |
     |      Args:
     |          email_response: La réponse d'email à router
     |
     |      Returns:
     |          La réponse générée par la chaîne de destination
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.chains.router_chains.base_router_chain.BaseRouterChain:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Exécute la chaîne de routage avec les entrées fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entrée
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_destination_chains(self) -> List[str]
     |      Retourne la liste des noms des chaînes de destination.
     |
     |      Returns:
     |          Liste des noms des chaînes de destination
     |
     |  run(self, input_text: str) -> str
     |      Exécute la chaîne de routage avec le texte d'entrée fourni.
     |
     |      Args:
     |          input_text: Texte d'entrée à router
     |
     |      Returns:
     |          La sortie générée par la chaîne de destination sélectionnée
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from src.langchain.chains.router_chains.base_router_chain.BaseRouterChain:
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

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\chains\router_chains\email_response_router_chain.py


