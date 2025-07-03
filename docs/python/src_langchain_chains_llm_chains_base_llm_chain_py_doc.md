Help on module base_llm_chain:

NAME
    base_llm_chain - Module contenant la classe de base pour les LLMChains.

DESCRIPTION
    Ce module fournit une classe de base pour les LLMChains qui peuvent �tre utilis�es
    dans diff�rents contextes du projet EMAIL_SENDER_1.

CLASSES
    builtins.object
        BaseLLMChain

    class BaseLLMChain(builtins.object)
     |  BaseLLMChain(llm: langchain_core.language_models.llms.BaseLLM, prompt_template: str, output_parser: Optional[langchain_core.output_parsers.base.BaseOutputParser] = None, input_variables: Optional[List[str]] = None, verbose: bool = False)
     |
     |  Classe de base pour les LLMChains du projet EMAIL_SENDER_1.
     |
     |  Cette classe fournit une interface commune et des fonctionnalit�s partag�es
     |  pour toutes les LLMChains utilis�es dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.llms.BaseLLM, prompt_template: str, output_parser: Optional[langchain_core.output_parsers.base.BaseOutputParser] = None, input_variables: Optional[List[str]] = None, verbose: bool = False)
     |      Initialise une nouvelle instance de BaseLLMChain.
     |
     |      Args:
     |          llm: Le mod�le de langage � utiliser
     |          prompt_template: Le template de prompt � utiliser
     |          output_parser: Le parser de sortie � utiliser (optionnel)
     |          input_variables: Les variables d'entr�e du template (optionnel, d�duites du template si non fournies)
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |
     |  apply(self, inputs_list: List[Dict[str, Any]]) -> List[str]
     |      Applique la cha�ne � une liste d'entr�es.
     |
     |      Args:
     |          inputs_list: Liste de dictionnaires des variables d'entr�e
     |
     |      Returns:
     |          Liste des sorties g�n�r�es
     |
     |  get_input_variables(self) -> List[str]
     |      Retourne les variables d'entr�e du template.
     |
     |      Returns:
     |          Liste des variables d'entr�e
     |
     |  get_prompt(self) -> str
     |      Retourne le template de prompt utilis� par la cha�ne.
     |
     |      Returns:
     |          Le template de prompt
     |
     |  predict(self, **kwargs) -> str
     |      Pr�dit la sortie en utilisant les arguments nomm�s.
     |
     |      Args:
     |          **kwargs: Arguments nomm�s correspondant aux variables d'entr�e
     |
     |      Returns:
     |          La sortie g�n�r�e par la cha�ne
     |
     |  run(self, inputs: Dict[str, Any]) -> str
     |      Ex�cute la cha�ne avec les entr�es fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entr�e pour le template
     |
     |      Returns:
     |          La sortie g�n�r�e par la cha�ne
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


