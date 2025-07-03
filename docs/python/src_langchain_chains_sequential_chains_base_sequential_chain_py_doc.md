Help on module base_sequential_chain:

NAME
    base_sequential_chain - Module contenant la classe de base pour les chaînes séquentielles.

DESCRIPTION
    Ce module fournit une classe de base pour les chaînes séquentielles qui peuvent être utilisées
    dans différents contextes du projet EMAIL_SENDER_1.

CLASSES
    builtins.object
        BaseSequentialChain

    class BaseSequentialChain(builtins.object)
     |  BaseSequentialChain(chains: Sequence[langchain.chains.base.Chain], verbose: bool = False, return_intermediate_steps: bool = False)
     |
     |  Classe de base pour les chaînes séquentielles du projet EMAIL_SENDER_1.
     |
     |  Cette classe fournit une interface commune et des fonctionnalités partagées
     |  pour toutes les chaînes séquentielles utilisées dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, chains: Sequence[langchain.chains.base.Chain], verbose: bool = False, return_intermediate_steps: bool = False)
     |      Initialise une nouvelle instance de BaseSequentialChain.
     |
     |      Args:
     |          chains: Séquence de chaînes à exécuter en séquence
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |          return_intermediate_steps: Retourner les résultats intermédiaires (défaut: False)
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Exécute la chaîne séquentielle avec les entrées fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entrée
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_input_keys(self) -> List[str]
     |      Retourne les clés d'entrée de la chaîne.
     |
     |      Returns:
     |          Liste des clés d'entrée
     |
     |  get_output_keys(self) -> List[str]
     |      Retourne les clés de sortie de la chaîne.
     |
     |      Returns:
     |          Liste des clés de sortie
     |
     |  run(self, input_text: str) -> str
     |      Exécute la chaîne séquentielle avec le texte d'entrée fourni.
     |
     |      Args:
     |          input_text: Texte d'entrée pour la première chaîne
     |
     |      Returns:
     |          La sortie générée par la dernière chaîne
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

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\chains\sequential_chains\base_sequential_chain.py


