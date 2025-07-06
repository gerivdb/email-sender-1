Help on module email_processing_chain:

NAME
    email_processing_chain - Module contenant une chaîne séquentielle pour le traitement des emails.

DESCRIPTION
    Ce module fournit une implémentation spécifique de BaseSequentialChain pour
    le traitement complet des emails dans le cadre du projet EMAIL_SENDER_1.

CLASSES
    src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain(builtins.object)
        EmailProcessingChain

    class EmailProcessingChain(src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain)
     |  EmailProcessingChain(llm: langchain_core.language_models.llms.BaseLLM, verbose: bool = False, return_intermediate_steps: bool = False)
     |
     |  Chaîne séquentielle pour le traitement complet des emails.
     |
     |  Cette chaîne combine l'analyse des réponses aux emails et la génération
     |  de réponses appropriées en fonction de l'analyse.
     |
     |  Method resolution order:
     |      EmailProcessingChain
     |      src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.llms.BaseLLM, verbose: bool = False, return_intermediate_steps: bool = False)
     |      Initialise une nouvelle instance de EmailProcessingChain.
     |
     |      Args:
     |          llm: Le modèle de langage à utiliser
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |          return_intermediate_steps: Retourner les résultats intermédiaires (défaut: False)
     |
     |  process_email(self, email_original: str, reponse_email: str) -> Dict[str, Any]
     |      Traite une réponse à un email et génère une réponse appropriée.
     |
     |      Args:
     |          email_original: L'email original envoyé
     |          reponse_email: La réponse reçue à analyser
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse et la réponse générée
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain:
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
     |  Data descriptors inherited from src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain:
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\chains\sequential_chains\email_processing_chain.py


