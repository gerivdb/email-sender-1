Help on module base_router_chain:

NAME
    base_router_chain - Module contenant la classe de base pour les chaînes de routage.

DESCRIPTION
    Ce module fournit une classe de base pour les chaînes de routage qui peuvent être utilisées
    dans différents contextes du projet EMAIL_SENDER_1.

CLASSES
    builtins.object
        BaseRouterChain

    class BaseRouterChain(builtins.object)
     |  BaseRouterChain(llm: langchain_core.language_models.llms.BaseLLM, destination_chains: Mapping[str, langchain.chains.base.Chain], default_chain: langchain.chains.base.Chain, router_template: Optional[str] = None, verbose: bool = False)
     |
     |  Classe de base pour les chaînes de routage du projet EMAIL_SENDER_1.
     |
     |  Cette classe fournit une interface commune et des fonctionnalités partagées
     |  pour toutes les chaînes de routage utilisées dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.llms.BaseLLM, destination_chains: Mapping[str, langchain.chains.base.Chain], default_chain: langchain.chains.base.Chain, router_template: Optional[str] = None, verbose: bool = False)
     |      Initialise une nouvelle instance de BaseRouterChain.
     |
     |      Args:
     |          llm: Le modèle de langage à utiliser pour le routage
     |          destination_chains: Dictionnaire des chaînes de destination (clé: nom, valeur: chaîne)
     |          default_chain: Chaîne à utiliser par défaut si aucune correspondance n'est trouvée
     |          router_template: Template de prompt pour le routeur (optionnel)
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
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


