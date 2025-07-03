Help on module email_processing_chain:

NAME
    email_processing_chain - Module contenant une cha�ne s�quentielle pour le traitement des emails.

DESCRIPTION
    Ce module fournit une impl�mentation sp�cifique de BaseSequentialChain pour
    le traitement complet des emails dans le cadre du projet EMAIL_SENDER_1.

CLASSES
    src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain(builtins.object)
        EmailProcessingChain

    class EmailProcessingChain(src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain)
     |  EmailProcessingChain(llm: langchain_core.language_models.llms.BaseLLM, verbose: bool = False, return_intermediate_steps: bool = False)
     |
     |  Cha�ne s�quentielle pour le traitement complet des emails.
     |
     |  Cette cha�ne combine l'analyse des r�ponses aux emails et la g�n�ration
     |  de r�ponses appropri�es en fonction de l'analyse.
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
     |          llm: Le mod�le de langage � utiliser
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |          return_intermediate_steps: Retourner les r�sultats interm�diaires (d�faut: False)
     |
     |  process_email(self, email_original: str, reponse_email: str) -> Dict[str, Any]
     |      Traite une r�ponse � un email et g�n�re une r�ponse appropri�e.
     |
     |      Args:
     |          email_original: L'email original envoy�
     |          reponse_email: La r�ponse re�ue � analyser
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse et la r�ponse g�n�r�e
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Ex�cute la cha�ne s�quentielle avec les entr�es fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entr�e
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_input_keys(self) -> List[str]
     |      Retourne les cl�s d'entr�e de la cha�ne.
     |
     |      Returns:
     |          Liste des cl�s d'entr�e
     |
     |  get_output_keys(self) -> List[str]
     |      Retourne les cl�s de sortie de la cha�ne.
     |
     |      Returns:
     |          Liste des cl�s de sortie
     |
     |  run(self, input_text: str) -> str
     |      Ex�cute la cha�ne s�quentielle avec le texte d'entr�e fourni.
     |
     |      Args:
     |          input_text: Texte d'entr�e pour la premi�re cha�ne
     |
     |      Returns:
     |          La sortie g�n�r�e par la derni�re cha�ne
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


