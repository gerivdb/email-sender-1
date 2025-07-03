Help on module email_generation_chain:

NAME
    email_generation_chain - Module contenant la chaîne LLM pour la génération d'emails.

DESCRIPTION
    Ce module fournit une implémentation spécifique de BaseLLMChain pour
    la génération d'emails personnalisés dans le cadre du projet EMAIL_SENDER_1.

CLASSES
    src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain(builtins.object)
        EmailGenerationChain

    class EmailGenerationChain(src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain)
     |  EmailGenerationChain(llm: langchain_core.language_models.llms.BaseLLM, prompt_template: Optional[str] = None, output_parser: Optional[langchain_core.output_parsers.base.BaseOutputParser] = None, verbose: bool = False)
     |
     |  Chaîne LLM spécialisée pour la génération d'emails personnalisés.
     |
     |  Cette chaîne utilise un modèle de langage pour générer des emails
     |  personnalisés en fonction des informations sur le contact, l'entreprise,
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
     |          llm: Le modèle de langage à utiliser
     |          prompt_template: Le template de prompt à utiliser (optionnel, utilise le template par défaut si non fourni)
     |          output_parser: Le parser de sortie à utiliser (optionnel)
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |
     |  generate_email(self, nom_contact: str, entreprise_contact: str, role_contact: str, nom_offre: str, description_offre: str, disponibilites: str, info_personnalisation: str) -> str
     |      Génère un email personnalisé avec les informations fournies.
     |
     |      Args:
     |          nom_contact: Nom du contact
     |          entreprise_contact: Nom de l'entreprise du contact
     |          role_contact: Rôle du contact dans l'entreprise
     |          nom_offre: Nom de l'offre à présenter
     |          description_offre: Description de l'offre
     |          disponibilites: Disponibilités pour un appel ou une rencontre
     |          info_personnalisation: Informations supplémentaires pour personnaliser le message
     |
     |      Returns:
     |          L'email généré
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  DEFAULT_TEMPLATE = '\n    Tu es un assistant spécialisé dans la rédac....
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain:
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


