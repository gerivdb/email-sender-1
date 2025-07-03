Help on module __init__:

NAME
    __init__ - Module d'initialisation pour le package langchain.

DESCRIPTION
    Ce module expose les classes et fonctions principales du package langchain.

CLASSES
    builtins.object
        src.langchain.agents.base_agent.BaseAgent
            src.langchain.agents.github_analysis_agent.GitHubAnalysisAgent
            src.langchain.agents.performance_analysis_agent.PerformanceAnalysisAgent
            src.langchain.agents.server_diagnostic_agent.ServerDiagnosticAgent
        src.langchain.chains.llm_chains.base_llm_chain.BaseLLMChain
            src.langchain.chains.llm_chains.email_analysis_chain.EmailAnalysisChain
            src.langchain.chains.llm_chains.email_generation_chain.EmailGenerationChain
        src.langchain.chains.router_chains.base_router_chain.BaseRouterChain
            src.langchain.chains.router_chains.email_response_router_chain.EmailResponseRouterChain
        src.langchain.chains.sequential_chains.base_sequential_chain.BaseSequentialChain
            src.langchain.chains.sequential_chains.email_processing_chain.EmailProcessingChain
        src.langchain.tools.code_analysis_tools.CodeAnalysisTools
        src.langchain.tools.documentation_tools.DocumentationTools
        src.langchain.tools.github_tools.GitHubTools
        src.langchain.tools.performance_analysis_tools.PerformanceAnalysisTools
        src.langchain.tools.recommendation_tools.RecommendationTools
        src.langchain.tools.server_diagnostic_tools.ServerDiagnosticTools

    class BaseAgent(builtins.object)
     |  BaseAgent(llm: langchain_core.language_models.base.BaseLanguageModel, tools: Sequence[langchain_core.tools.base.BaseTool], agent_type: str = 'react', prompt_template: Union[str, langchain_core.prompts.prompt.PromptTemplate, langchain_core.prompts.chat.ChatPromptTemplate, NoneType] = None, verbose: bool = False, handle_parsing_errors: bool = True)
     |
     |  Classe de base pour les agents Langchain du projet EMAIL_SENDER_1.
     |
     |  Cette classe fournit une interface commune et des fonctionnalit�s partag�es
     |  pour tous les agents Langchain utilis�s dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.base.BaseLanguageModel, tools: Sequence[langchain_core.tools.base.BaseTool], agent_type: str = 'react', prompt_template: Union[str, langchain_core.prompts.prompt.PromptTemplate, langchain_core.prompts.chat.ChatPromptTemplate, NoneType] = None, verbose: bool = False, handle_parsing_errors: bool = True)
     |      Initialise une nouvelle instance de BaseAgent.
     |
     |      Args:
     |          llm: Le mod�le de langage � utiliser
     |          tools: Les outils � mettre � disposition de l'agent
     |          agent_type: Le type d'agent � cr�er ("react" ou "openai_functions")
     |          prompt_template: Le template de prompt � utiliser (optionnel)
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |          handle_parsing_errors: G�rer les erreurs de parsing (d�faut: True)
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Ex�cute l'agent avec les entr�es fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entr�e
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_tools(self) -> List[langchain_core.tools.base.BaseTool]
     |      Retourne la liste des outils disponibles pour l'agent.
     |
     |      Returns:
     |          Liste des outils
     |
     |  run(self, input_text: str) -> str
     |      Ex�cute l'agent avec le texte d'entr�e fourni.
     |
     |      Args:
     |          input_text: Texte d'entr�e pour l'agent
     |
     |      Returns:
     |          La sortie g�n�r�e par l'agent
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

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

    class CodeAnalysisTools(builtins.object)
     |  Classe contenant des outils pour l'analyse de code avanc�e.
     |
     |  Static methods defined here:
     |
     |  analyze_code_structure(directory_path: str, file_pattern: str = '*.py') -> Dict[str, Any]
     |      Analyse la structure du code dans un r�pertoire.
     |
     |      Args:
     |          directory_path: Chemin vers le r�pertoire � analyser
     |          file_pattern: Pattern pour filtrer les fichiers (d�faut: "*.py")
     |
     |      Returns:
     |          Dictionnaire contenant les r�sultats de l'analyse
     |
     |  analyze_python_code(code: str) -> Dict[str, Any]
     |      Analyse du code Python pour d�tecter les probl�mes et �valuer sa qualit�.
     |
     |      Args:
     |          code: Code Python � analyser
     |
     |      Returns:
     |          Dictionnaire contenant les r�sultats de l'analyse
     |
     |  detect_code_smells(code: str) -> List[Dict[str, Any]]
     |      D�tecte les "code smells" (mauvaises pratiques) dans le code.
     |
     |      Args:
     |          code: Code � analyser
     |
     |      Returns:
     |          Liste des code smells d�tect�s
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class DocumentationTools(builtins.object)
     |  Classe contenant des outils pour la g�n�ration de documentation.
     |
     |  Static methods defined here:
     |
     |  extract_docstrings(code: str) -> Dict[str, Any]
     |      Extrait les docstrings d'un code Python.
     |
     |      Args:
     |          code: Code Python � analyser
     |
     |      Returns:
     |          Dictionnaire contenant les docstrings extraites
     |
     |  generate_class_documentation(code: str, class_name: Optional[str] = None) -> Dict[str, Any]
     |      G�n�re de la documentation pour une classe sp�cifique ou toutes les classes du code.
     |
     |      Args:
     |          code: Code Python contenant la classe
     |          class_name: Nom de la classe � documenter (optionnel, toutes les classes si non sp�cifi�)
     |
     |      Returns:
     |          Dictionnaire contenant la documentation g�n�r�e
     |
     |  generate_function_documentation(code: str, function_name: Optional[str] = None) -> Dict[str, Any]
     |      G�n�re de la documentation pour une fonction sp�cifique ou toutes les fonctions du code.
     |
     |      Args:
     |          code: Code Python contenant la fonction
     |          function_name: Nom de la fonction � documenter (optionnel, toutes les fonctions si non sp�cifi�)
     |
     |      Returns:
     |          Dictionnaire contenant la documentation g�n�r�e
     |
     |  generate_markdown_documentation(code: str) -> str
     |      G�n�re de la documentation au format Markdown pour un code Python.
     |
     |      Args:
     |          code: Code Python � documenter
     |
     |      Returns:
     |          Documentation au format Markdown
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

    class GitHubAnalysisAgent(src.langchain.agents.base_agent.BaseAgent)
     |  GitHubAnalysisAgent(llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |
     |  Agent sp�cialis� dans l'analyse des d�p�ts GitHub.
     |
     |  Cet agent utilise les outils GitHub pour analyser les d�p�ts,
     |  explorer le code, et fournir des insights sur la structure et le contenu.
     |
     |  Method resolution order:
     |      GitHubAnalysisAgent
     |      src.langchain.agents.base_agent.BaseAgent
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |      Initialise une nouvelle instance de GitHubAnalysisAgent.
     |
     |      Args:
     |          llm: Le mod�le de langage � utiliser
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |          handle_parsing_errors: G�rer les erreurs de parsing (d�faut: True)
     |
     |  analyze_repository(self, repo_owner: str, repo_name: str) -> Dict[str, Any]
     |      Analyse un d�p�t GitHub et fournit un rapport d�taill�.
     |
     |      Args:
     |          repo_owner: Propri�taire du d�p�t (utilisateur ou organisation)
     |          repo_name: Nom du d�p�t
     |
     |      Returns:
     |          Dictionnaire contenant le rapport d'analyse
     |
     |  search_repository(self, repo_owner: str, repo_name: str, query: str) -> Dict[str, Any]
     |      Recherche du code dans un d�p�t GitHub et fournit une analyse des r�sultats.
     |
     |      Args:
     |          repo_owner: Propri�taire du d�p�t (utilisateur ou organisation)
     |          repo_name: Nom du d�p�t
     |          query: Requ�te de recherche
     |
     |      Returns:
     |          Dictionnaire contenant les r�sultats de recherche et l'analyse
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Ex�cute l'agent avec les entr�es fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entr�e
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_tools(self) -> List[langchain_core.tools.base.BaseTool]
     |      Retourne la liste des outils disponibles pour l'agent.
     |
     |      Returns:
     |          Liste des outils
     |
     |  run(self, input_text: str) -> str
     |      Ex�cute l'agent avec le texte d'entr�e fourni.
     |
     |      Args:
     |          input_text: Texte d'entr�e pour l'agent
     |
     |      Returns:
     |          La sortie g�n�r�e par l'agent
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class GitHubTools(builtins.object)
     |  Classe contenant des outils pour interagir avec GitHub.
     |
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  get_file_content = StructuredTool(name='get_file_content', descript......
     |
     |  get_repo_info = StructuredTool(name='get_repo_info', description...Git...
     |
     |  list_repo_branches = StructuredTool(name='list_repo_branches', descri....
     |
     |  list_repo_contents = StructuredTool(name='list_repo_contents', descri....
     |
     |  search_code = StructuredTool(name='search_code', description='...n Git...

    class PerformanceAnalysisAgent(src.langchain.agents.base_agent.BaseAgent)
     |  PerformanceAnalysisAgent(llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |
     |  Agent sp�cialis� dans l'analyse de performance.
     |
     |  Cet agent utilise les outils d'analyse de performance pour mesurer et analyser
     |  les performances des applications, identifier les goulots d'�tranglement et
     |  proposer des optimisations.
     |
     |  Method resolution order:
     |      PerformanceAnalysisAgent
     |      src.langchain.agents.base_agent.BaseAgent
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |      Initialise une nouvelle instance de PerformanceAnalysisAgent.
     |
     |      Args:
     |          llm: Le mod�le de langage � utiliser
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |          handle_parsing_errors: G�rer les erreurs de parsing (d�faut: True)
     |
     |  analyze_all_performance_data(self) -> Dict[str, Any]
     |      Analyse toutes les donn�es de performance collect�es.
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse globale des performances
     |
     |  analyze_endpoint_performance(self, url: str, method: str = 'GET', iterations: int = 5) -> Dict[str, Any]
     |      Analyse les performances d'un endpoint HTTP.
     |
     |      Args:
     |          url: URL de l'endpoint
     |          method: M�thode HTTP (d�faut: GET)
     |          iterations: Nombre d'it�rations (d�faut: 5)
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse des performances
     |
     |  compare_endpoints(self, endpoints: List[Dict[str, Any]]) -> Dict[str, Any]
     |      Compare les performances de plusieurs endpoints.
     |
     |      Args:
     |          endpoints: Liste de dictionnaires contenant les informations des endpoints
     |                    (chaque dictionnaire doit avoir les cl�s 'url' et 'method')
     |
     |      Returns:
     |          Dictionnaire contenant la comparaison des performances
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Ex�cute l'agent avec les entr�es fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entr�e
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_tools(self) -> List[langchain_core.tools.base.BaseTool]
     |      Retourne la liste des outils disponibles pour l'agent.
     |
     |      Returns:
     |          Liste des outils
     |
     |  run(self, input_text: str) -> str
     |      Ex�cute l'agent avec le texte d'entr�e fourni.
     |
     |      Args:
     |          input_text: Texte d'entr�e pour l'agent
     |
     |      Returns:
     |          La sortie g�n�r�e par l'agent
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class PerformanceAnalysisTools(builtins.object)
     |  Classe contenant des outils pour l'analyse de performance.
     |
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  analyze_performance_data = StructuredTool(name='analyze_performance_da...
     |
     |  clear_performance_data = StructuredTool(name='clear_performance_data',...
     |
     |  measure_endpoint_performance = StructuredTool(name='measure_endpoint_p...
     |
     |  measure_function_performance = StructuredTool(name='measure_function_p...
     |
     |  record_custom_metric = StructuredTool(name='record_custom_metric', des...

    class RecommendationTools(builtins.object)
     |  Classe contenant des outils de recommandation.
     |
     |  Static methods defined here:
     |
     |  recommend_architecture_improvements(directory_path: str) -> Dict[str, Any]
     |      Recommande des am�liorations d'architecture pour un projet Python.
     |
     |      Args:
     |          directory_path: Chemin vers le r�pertoire du projet
     |
     |      Returns:
     |          Dictionnaire contenant les recommandations
     |
     |  recommend_code_improvements(code: str) -> Dict[str, Any]
     |      Recommande des am�liorations pour un code Python.
     |
     |      Args:
     |          code: Code Python � analyser
     |
     |      Returns:
     |          Dictionnaire contenant les recommandations
     |
     |  recommend_technology_stack(requirements: List[str]) -> Dict[str, List[str]]
     |      Recommande une pile technologique bas�e sur les exigences du projet.
     |
     |      Args:
     |          requirements: Liste des exigences du projet
     |
     |      Returns:
     |          Dictionnaire contenant les recommandations de technologies
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class ServerDiagnosticAgent(src.langchain.agents.base_agent.BaseAgent)
     |  ServerDiagnosticAgent(llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |
     |  Agent sp�cialis� dans le diagnostic des serveurs.
     |
     |  Cet agent utilise les outils de diagnostic pour surveiller et analyser
     |  les serveurs, identifier les probl�mes et proposer des solutions.
     |
     |  Method resolution order:
     |      ServerDiagnosticAgent
     |      src.langchain.agents.base_agent.BaseAgent
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.base.BaseLanguageModel, verbose: bool = False, handle_parsing_errors: bool = True)
     |      Initialise une nouvelle instance de ServerDiagnosticAgent.
     |
     |      Args:
     |          llm: Le mod�le de langage � utiliser
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |          handle_parsing_errors: G�rer les erreurs de parsing (d�faut: True)
     |
     |  analyze_logs(self, log_file: str, num_lines: int = 100, filter_text: Optional[str] = None) -> Dict[str, Any]
     |      Analyse les logs d'un serveur et identifie les probl�mes potentiels.
     |
     |      Args:
     |          log_file: Chemin vers le fichier de log
     |          num_lines: Nombre de lignes � analyser (d�faut: 100)
     |          filter_text: Texte pour filtrer les entr�es (optionnel)
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse des logs
     |
     |  check_server_health(self, host: str, ports: List[int], endpoints: List[str]) -> Dict[str, Any]
     |      V�rifie la sant� d'un serveur en testant les ports et endpoints.
     |
     |      Args:
     |          host: Nom d'h�te ou adresse IP du serveur
     |          ports: Liste des ports � v�rifier
     |          endpoints: Liste des endpoints HTTP � v�rifier
     |
     |      Returns:
     |          Dictionnaire contenant le rapport de sant�
     |
     |  diagnose_system(self) -> Dict[str, Any]
     |      Diagnostique le syst�me et fournit un rapport d�taill�.
     |
     |      Returns:
     |          Dictionnaire contenant le rapport de diagnostic
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Ex�cute l'agent avec les entr�es fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entr�e
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_tools(self) -> List[langchain_core.tools.base.BaseTool]
     |      Retourne la liste des outils disponibles pour l'agent.
     |
     |      Returns:
     |          Liste des outils
     |
     |  run(self, input_text: str) -> str
     |      Ex�cute l'agent avec le texte d'entr�e fourni.
     |
     |      Args:
     |          input_text: Texte d'entr�e pour l'agent
     |
     |      Returns:
     |          La sortie g�n�r�e par l'agent
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class ServerDiagnosticTools(builtins.object)
     |  Classe contenant des outils pour le diagnostic des serveurs.
     |
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  check_http_endpoint = StructuredTool(name='check_http_endpoint', descr...
     |
     |  check_port_status = StructuredTool(name='check_port_status', descrip.....
     |
     |  get_log_entries = StructuredTool(name='get_log_entries', descripti...s...
     |
     |  get_process_info = StructuredTool(name='get_process_info', descript......
     |
     |  get_system_info = StructuredTool(name='get_system_info', descripti...s...

DATA
    __all__ = ['BaseLLMChain', 'EmailGenerationChain', 'EmailAnalysisChain...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\__init__.py


