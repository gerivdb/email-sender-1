Help on module email_generation_chain:

NAME
    email_generation_chain - Module contenant la cha�ne LLM pour la g�n�ration d'emails.

DESCRIPTION
    Ce module fournit une impl�mentation sp�cifique de BaseLLMChain pour
    la g�n�ration d'emails personnalis�s dans le cadre du projet EMAIL_SENDER_1.

CLASSES
    src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain(builtins.object)
        EmailGenerationChain

    class EmailGenerationChain(src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain)
     |  EmailGenerationChain(llm: langchain_core.language_models.llms.BaseLLM, prompt_template: Optional[str] = None, output_parser: Optional[langchain_core.output_parsers.base.BaseOutputParser] = None, verbose: bool = False)
     |
     |  Cha�ne LLM sp�cialis�e pour la g�n�ration d'emails personnalis�s.
     |
     |  Cette cha�ne utilise un mod�le de langage pour g�n�rer des emails
     |  personnalis�s en fonction des informations sur le contact, l'entreprise,
     |  et d'autres variables contextuelles.
     |
     |  Method resolution order:
     |      EmailGenerationChain
     |      src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.llms.BaseLLM, prompt_template: Optional[str] = None, output_parser: Optional[langchain_core.output_parsers.base.BaseOutputParser] = None, verbose: bool = False)
     |      Initialise une nouvelle instance de EmailGenerationChain.
     |
     |      Args:
     |          llm: Le mod�le de langage � utiliser
     |          prompt_template: Le template de prompt � utiliser (optionnel, utilise le template par d�faut si non fourni)
     |          output_parser: Le parser de sortie � utiliser (optionnel)
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |
     |  generate_email(self, nom_contact: str, entreprise_contact: str, role_contact: str, nom_offre: str, description_offre: str, disponibilites: str, info_personnalisation: str) -> str
     |      G�n�re un email personnalis� avec les informations fournies.
     |
     |      Args:
     |          nom_contact: Nom du contact
     |          entreprise_contact: Nom de l'entreprise du contact
     |          role_contact: R�le du contact dans l'entreprise
     |          nom_offre: Nom de l'offre � pr�senter
     |          description_offre: Description de l'offre
     |          disponibilites: Disponibilit�s pour un appel ou une rencontre
     |          info_personnalisation: Informations suppl�mentaires pour personnaliser le message
     |
     |      Returns:
     |          L'email g�n�r�
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  DEFAULT_TEMPLATE = '\n    Tu es un assistant sp�cialis� dans la r�dac....
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain:
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
     |  Data descriptors inherited from src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain:
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\chains\llm_chains\email_generation_chain.py


