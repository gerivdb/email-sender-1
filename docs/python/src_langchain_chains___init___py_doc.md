Help on module __init__:

NAME
    __init__ - Module d'initialisation pour les cha�nes Langchain.

DESCRIPTION
    Ce module expose les classes et fonctions principales du package chains.

CLASSES
    builtins.object
        src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain
            src.langchain.chains.llm_chains.email_analysis_chain.EmailAnalysisChain
            src.langchain.chains.llm_chains.email_generation_chain.EmailGenerationChain
        src.langchain.chains.router_chains.base_router_chain.BaseRouterChain
            src.langchain.chains.router_chains.email_response_router_chain.EmailResponseRouterChain
        src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain
            src.langchain.chains.sequential_chains.email_processing_chain.EmailProcessingChain

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

    class BaseSequentialChain(builtins.object)
     |  BaseSequentialChain(chains: Sequence[langchain.chains.base.Chain], verbose: bool = False, return_intermediate_steps: bool = False)
     |
     |  Classe de base pour les cha�nes s�quentielles du projet EMAIL_SENDER_1.
     |
     |  Cette classe fournit une interface commune et des fonctionnalit�s partag�es
     |  pour toutes les cha�nes s�quentielles utilis�es dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, chains: Sequence[langchain.chains.base.Chain], verbose: bool = False, return_intermediate_steps: bool = False)
     |      Initialise une nouvelle instance de BaseSequentialChain.
     |
     |      Args:
     |          chains: S�quence de cha�nes � ex�cuter en s�quence
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |          return_intermediate_steps: Retourner les r�sultats interm�diaires (d�faut: False)
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
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class EmailAnalysisChain(src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain)
     |  EmailAnalysisChain(llm: langchain_core.language_models.llms.BaseLLM, prompt_template: Optional[str] = None, output_parser: Optional[langchain_core.output_parsers.base.BaseOutputParser] = None, verbose: bool = False)
     |
     |  Cha�ne LLM sp�cialis�e pour l'analyse des r�ponses aux emails.
     |
     |  Cette cha�ne utilise un mod�le de langage pour analyser les r�ponses
     |  aux emails et extraire des informations structur�es.
     |
     |  Method resolution order:
     |      EmailAnalysisChain
     |      src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.llms.BaseLLM, prompt_template: Optional[str] = None, output_parser: Optional[langchain_core.output_parsers.base.BaseOutputParser] = None, verbose: bool = False)
     |      Initialise une nouvelle instance de EmailAnalysisChain.
     |
     |      Args:
     |          llm: Le mod�le de langage � utiliser
     |          prompt_template: Le template de prompt � utiliser (optionnel, utilise le template par d�faut si non fourni)
     |          output_parser: Le parser de sortie � utiliser (optionnel, utilise JsonOutputParser si non fourni)
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |
     |  analyze_email(self, email_original: str, reponse_email: str) -> Dict[str, Any]
     |      Analyse une r�ponse � un email.
     |
     |      Args:
     |          email_original: L'email original envoy�
     |          reponse_email: La r�ponse re�ue � analyser
     |
     |      Returns:
     |          Dictionnaire contenant les r�sultats de l'analyse
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  DEFAULT_TEMPLATE = "\n    Tu es un assistant sp�cialis� dans l'analys....
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
    __all__ = ['BaseLLMChain', 'EmailGenerationChain', 'EmailAnalysisChain...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\chains\__init__.py


