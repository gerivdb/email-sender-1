Help on module base_router_chain:

NAME
    base_router_chain - Module contenant la classe de base pour les cha�nes de routage.

DESCRIPTION
    Ce module fournit une classe de base pour les cha�nes de routage qui peuvent �tre utilis�es
    dans diff�rents contextes du projet EMAIL_SENDER_1.

CLASSES
    builtins.object
        BaseRouterChain

    class BaseRouterChain(builtins.object)
     |  BaseRouterChain(llm: langchain_core.language_models.llms.BaseLLM, destination_chains: Mapping[str, langchain.chains.base.Chain], default_chain: langchain.chains.base.Chain, router_template: Optional[str] = None, verbose: bool = False)
     |
     |  Classe de base pour les cha�nes de routage du projet EMAIL_SENDER_1.
     |
     |  Cette classe fournit une interface commune et des fonctionnalit�s partag�es
     |  pour toutes les cha�nes de routage utilis�es dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.llms.BaseLLM, destination_chains: Mapping[str, langchain.chains.base.Chain], default_chain: langchain.chains.base.Chain, router_template: Optional[str] = None, verbose: bool = False)
     |      Initialise une nouvelle instance de BaseRouterChain.
     |
     |      Args:
     |          llm: Le mod�le de langage � utiliser pour le routage
     |          destination_chains: Dictionnaire des cha�nes de destination (cl�: nom, valeur: cha�ne)
     |          default_chain: Cha�ne � utiliser par d�faut si aucune correspondance n'est trouv�e
     |          router_template: Template de prompt pour le routeur (optionnel)
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
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

    MULTI_PROMPT_ROUTER_TEMPLATE = 'Given a raw text input to a language m...
    Mapping = typing.Mapping
        A generic version of collections.abc.Mapping.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\chains\router_chains\base_router_chain.py


