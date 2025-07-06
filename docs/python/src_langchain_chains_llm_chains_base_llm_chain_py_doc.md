Help on module base_llm_chain:

NAME
    base_llm_chain - Module contenant la classe de base pour les LLMChains.

DESCRIPTION
    Ce module fournit une classe de base pour les LLMChains qui peuvent être utilisées
    dans différents contextes du projet EMAIL_SENDER_1.

CLASSES
    builtins.object
        BaseLLMChain

    class BaseLLMChain(builtins.object)
     |  BaseLLMChain(llm: langchain_core.language_models.llms.BaseLLM, prompt_template: str, output_parser: Optional[langchain_core.output_parsers.base.BaseOutputParser] = None, input_variables: Optional[List[str]] = None, verbose: bool = False)
     |
     |  Classe de base pour les LLMChains du projet EMAIL_SENDER_1.
     |
     |  Cette classe fournit une interface commune et des fonctionnalités partagées
     |  pour toutes les LLMChains utilisées dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.llms.BaseLLM, prompt_template: str, output_parser: Optional[langchain_core.output_parsers.base.BaseOutputParser] = None, input_variables: Optional[List[str]] = None, verbose: bool = False)
     |      Initialise une nouvelle instance de BaseLLMChain.
     |
     |      Args:
     |          llm: Le modèle de langage à utiliser
     |          prompt_template: Le template de prompt à utiliser
     |          output_parser: Le parser de sortie à utiliser (optionnel)
     |          input_variables: Les variables d'entrée du template (optionnel, déduites du template si non fournies)
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |
     |  apply(self, inputs_list: List[Dict[str, Any]]) -> List[str]
     |      Applique la chaîne à une liste d'entrées.
     |
     |      Args:
     |          inputs_list: Liste de dictionnaires des variables d'entrée
     |
     |      Returns:
     |          Liste des sorties générées
     |
     |  get_input_variables(self) -> List[str]
     |      Retourne les variables d'entrée du template.
     |
     |      Returns:
     |          Liste des variables d'entrée
     |
     |  get_prompt(self) -> str
     |      Retourne le template de prompt utilisé par la chaîne.
     |
     |      Returns:
     |          Le template de prompt
     |
     |  predict(self, **kwargs) -> str
     |      Prédit la sortie en utilisant les arguments nommés.
     |
     |      Args:
     |          **kwargs: Arguments nommés correspondant aux variables d'entrée
     |
     |      Returns:
     |          La sortie générée par la chaîne
     |
     |  run(self, inputs: Dict[str, Any]) -> str
     |      Exécute la chaîne avec les entrées fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entrée pour le template
     |
     |      Returns:
     |          La sortie générée par la chaîne
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\chains\llm_chains\base_llm_chain.py


