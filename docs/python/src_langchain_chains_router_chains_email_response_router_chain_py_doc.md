Help on module email_response_router_chain:

NAME
    email_response_router_chain - Module contenant une cha�ne de routage pour les r�ponses aux emails.

DESCRIPTION
    Ce module fournit une impl�mentation sp�cifique de BaseRouterChain pour
    router les r�ponses aux emails vers diff�rentes cha�nes de traitement
    en fonction du type de r�ponse.

CLASSES
    src.langchain.chains.router_chains.base_router_chain.BaseRouterChain(builtins.object)
        EmailResponseRouterChain

    class EmailResponseRouterChain(src.langchain.chains.router_chains.base_router_chain.BaseRouterChain)
     |  EmailResponseRouterChain(llm: langchain_core.language_models.llms.BaseLLM, verbose: bool = False)
     |
     |  Cha�ne de routage pour les r�ponses aux emails.
     |
     |  Cette cha�ne analyse les r�ponses aux emails et les route vers diff�rentes
     |  cha�nes de traitement en fonction du type de r�ponse.
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
     |          llm: Le mod�le de langage � utiliser
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |
     |  route_email_response(self, email_response: str) -> str
     |      Route une r�ponse d'email vers la cha�ne de traitement appropri�e.
     |
     |      Args:
     |          email_response: La r�ponse d'email � router
     |
     |      Returns:
     |          La r�ponse g�n�r�e par la cha�ne de destination
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.chains.router_chains.base_router_chain.BaseRouterChain:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Ex�cute la cha�ne de routage avec les entr�es fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entr�e
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_destination_chains(self) -> List[str]
     |      Retourne la liste des noms des cha�nes de destination.
     |
     |      Returns:
     |          Liste des noms des cha�nes de destination
     |
     |  run(self, input_text: str) -> str
     |      Ex�cute la cha�ne de routage avec le texte d'entr�e fourni.
     |
     |      Args:
     |          input_text: Texte d'entr�e � router
     |
     |      Returns:
     |          La sortie g�n�r�e par la cha�ne de destination s�lectionn�e
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


