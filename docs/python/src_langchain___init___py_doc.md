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
     |  Cette classe fournit une interface commune et des fonctionnalités partagées
     |  pour tous les agents Langchain utilisés dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, llm: langchain_core.language_models.base.BaseLanguageModel, tools: Sequence[langchain_core.tools.base.BaseTool], agent_type: str = 'react', prompt_template: Union[str, langchain_core.prompts.prompt.PromptTemplate, langchain_core.prompts.chat.ChatPromptTemplate, NoneType] = None, verbose: bool = False, handle_parsing_errors: bool = True)
     |      Initialise une nouvelle instance de BaseAgent.
     |
     |      Args:
     |          llm: Le modèle de langage à utiliser
     |          tools: Les outils à mettre à disposition de l'agent
     |          agent_type: Le type d'agent à créer ("react" ou "openai_functions")
     |          prompt_template: Le template de prompt à utiliser (optionnel)
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |          handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Exécute l'agent avec les entrées fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entrée
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
     |      Exécute l'agent avec le texte d'entrée fourni.
     |
     |      Args:
     |          input_text: Texte d'entrée pour l'agent
     |
     |      Returns:
     |          La sortie générée par l'agent
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

    class CodeAnalysisTools(builtins.object)
     |  Classe contenant des outils pour l'analyse de code avancée.
     |
     |  Static methods defined here:
     |
     |  analyze_code_structure(directory_path: str, file_pattern: str = '*.py') -> Dict[str, Any]
     |      Analyse la structure du code dans un répertoire.
     |
     |      Args:
     |          directory_path: Chemin vers le répertoire à analyser
     |          file_pattern: Pattern pour filtrer les fichiers (défaut: "*.py")
     |
     |      Returns:
     |          Dictionnaire contenant les résultats de l'analyse
     |
     |  analyze_python_code(code: str) -> Dict[str, Any]
     |      Analyse du code Python pour détecter les problèmes et évaluer sa qualité.
     |
     |      Args:
     |          code: Code Python à analyser
     |
     |      Returns:
     |          Dictionnaire contenant les résultats de l'analyse
     |
     |  detect_code_smells(code: str) -> List[Dict[str, Any]]
     |      Détecte les "code smells" (mauvaises pratiques) dans le code.
     |
     |      Args:
     |          code: Code à analyser
     |
     |      Returns:
     |          Liste des code smells détectés
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
     |  Classe contenant des outils pour la génération de documentation.
     |
     |  Static methods defined here:
     |
     |  extract_docstrings(code: str) -> Dict[str, Any]
     |      Extrait les docstrings d'un code Python.
     |
     |      Args:
     |          code: Code Python à analyser
     |
     |      Returns:
     |          Dictionnaire contenant les docstrings extraites
     |
     |  generate_class_documentation(code: str, class_name: Optional[str] = None) -> Dict[str, Any]
     |      Génère de la documentation pour une classe spécifique ou toutes les classes du code.
     |
     |      Args:
     |          code: Code Python contenant la classe
     |          class_name: Nom de la classe à documenter (optionnel, toutes les classes si non spécifié)
     |
     |      Returns:
     |          Dictionnaire contenant la documentation générée
     |
     |  generate_function_documentation(code: str, function_name: Optional[str] = None) -> Dict[str, Any]
     |      Génère de la documentation pour une fonction spécifique ou toutes les fonctions du code.
     |
     |      Args:
     |          code: Code Python contenant la fonction
     |          function_name: Nom de la fonction à documenter (optionnel, toutes les fonctions si non spécifié)
     |
     |      Returns:
     |          Dictionnaire contenant la documentation générée
     |
     |  generate_markdown_documentation(code: str) -> str
     |      Génère de la documentation au format Markdown pour un code Python.
     |
     |      Args:
     |          code: Code Python à documenter
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
     |  Chaîne LLM spécialisée pour l'analyse des réponses aux emails.
     |
     |  Cette chaîne utilise un modèle de langage pour analyser les réponses
     |  aux emails et extraire des informations structurées.
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
     |          llm: Le modèle de langage à utiliser
     |          prompt_template: Le template de prompt à utiliser (optionnel, utilise le template par défaut si non fourni)
     |          output_parser: Le parser de sortie à utiliser (optionnel, utilise JsonOutputParser si non fourni)
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |
     |  analyze_email(self, email_original: str, reponse_email: str) -> Dict[str, Any]
     |      Analyse une réponse à un email.
     |
     |      Args:
     |          email_original: L'email original envoyé
     |          reponse_email: La réponse reçue à analyser
     |
     |      Returns:
     |          Dictionnaire contenant les résultats de l'analyse
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  DEFAULT_TEMPLATE = "\n    Tu es un assistant spécialisé dans l'analys....
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

    class EmailResponseRouterChain(src.langchain.chains.router_chains.base_router_chain.BaseRouterChain)
     |  EmailResponseRouterChain(llm: langchain_core.language_models.llms.BaseLLM, verbose: bool = False)
     |
     |  Chaîne de routage pour les réponses aux emails.
     |
     |  Cette chaîne analyse les réponses aux emails et les route vers différentes
     |  chaînes de traitement en fonction du type de réponse.
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
     |          llm: Le modèle de langage à utiliser
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |
     |  route_email_response(self, email_response: str) -> str
     |      Route une réponse d'email vers la chaîne de traitement appropriée.
     |
     |      Args:
     |          email_response: La réponse d'email à router
     |
     |      Returns:
     |          La réponse générée par la chaîne de destination
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.chains.router_chains.base_router_chain.BaseRouterChain:
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
     |  Agent spécialisé dans l'analyse des dépôts GitHub.
     |
     |  Cet agent utilise les outils GitHub pour analyser les dépôts,
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
     |          llm: Le modèle de langage à utiliser
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |          handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
     |
     |  analyze_repository(self, repo_owner: str, repo_name: str) -> Dict[str, Any]
     |      Analyse un dépôt GitHub et fournit un rapport détaillé.
     |
     |      Args:
     |          repo_owner: Propriétaire du dépôt (utilisateur ou organisation)
     |          repo_name: Nom du dépôt
     |
     |      Returns:
     |          Dictionnaire contenant le rapport d'analyse
     |
     |  search_repository(self, repo_owner: str, repo_name: str, query: str) -> Dict[str, Any]
     |      Recherche du code dans un dépôt GitHub et fournit une analyse des résultats.
     |
     |      Args:
     |          repo_owner: Propriétaire du dépôt (utilisateur ou organisation)
     |          repo_name: Nom du dépôt
     |          query: Requête de recherche
     |
     |      Returns:
     |          Dictionnaire contenant les résultats de recherche et l'analyse
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Exécute l'agent avec les entrées fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entrée
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
     |      Exécute l'agent avec le texte d'entrée fourni.
     |
     |      Args:
     |          input_text: Texte d'entrée pour l'agent
     |
     |      Returns:
     |          La sortie générée par l'agent
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
     |  Agent spécialisé dans l'analyse de performance.
     |
     |  Cet agent utilise les outils d'analyse de performance pour mesurer et analyser
     |  les performances des applications, identifier les goulots d'étranglement et
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
     |          llm: Le modèle de langage à utiliser
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |          handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
     |
     |  analyze_all_performance_data(self) -> Dict[str, Any]
     |      Analyse toutes les données de performance collectées.
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse globale des performances
     |
     |  analyze_endpoint_performance(self, url: str, method: str = 'GET', iterations: int = 5) -> Dict[str, Any]
     |      Analyse les performances d'un endpoint HTTP.
     |
     |      Args:
     |          url: URL de l'endpoint
     |          method: Méthode HTTP (défaut: GET)
     |          iterations: Nombre d'itérations (défaut: 5)
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse des performances
     |
     |  compare_endpoints(self, endpoints: List[Dict[str, Any]]) -> Dict[str, Any]
     |      Compare les performances de plusieurs endpoints.
     |
     |      Args:
     |          endpoints: Liste de dictionnaires contenant les informations des endpoints
     |                    (chaque dictionnaire doit avoir les clés 'url' et 'method')
     |
     |      Returns:
     |          Dictionnaire contenant la comparaison des performances
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Exécute l'agent avec les entrées fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entrée
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
     |      Exécute l'agent avec le texte d'entrée fourni.
     |
     |      Args:
     |          input_text: Texte d'entrée pour l'agent
     |
     |      Returns:
     |          La sortie générée par l'agent
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
     |      Recommande des améliorations d'architecture pour un projet Python.
     |
     |      Args:
     |          directory_path: Chemin vers le répertoire du projet
     |
     |      Returns:
     |          Dictionnaire contenant les recommandations
     |
     |  recommend_code_improvements(code: str) -> Dict[str, Any]
     |      Recommande des améliorations pour un code Python.
     |
     |      Args:
     |          code: Code Python à analyser
     |
     |      Returns:
     |          Dictionnaire contenant les recommandations
     |
     |  recommend_technology_stack(requirements: List[str]) -> Dict[str, List[str]]
     |      Recommande une pile technologique basée sur les exigences du projet.
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
     |  Agent spécialisé dans le diagnostic des serveurs.
     |
     |  Cet agent utilise les outils de diagnostic pour surveiller et analyser
     |  les serveurs, identifier les problèmes et proposer des solutions.
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
     |          llm: Le modèle de langage à utiliser
     |          verbose: Afficher les étapes intermédiaires (défaut: False)
     |          handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
     |
     |  analyze_logs(self, log_file: str, num_lines: int = 100, filter_text: Optional[str] = None) -> Dict[str, Any]
     |      Analyse les logs d'un serveur et identifie les problèmes potentiels.
     |
     |      Args:
     |          log_file: Chemin vers le fichier de log
     |          num_lines: Nombre de lignes à analyser (défaut: 100)
     |          filter_text: Texte pour filtrer les entrées (optionnel)
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse des logs
     |
     |  check_server_health(self, host: str, ports: List[int], endpoints: List[str]) -> Dict[str, Any]
     |      Vérifie la santé d'un serveur en testant les ports et endpoints.
     |
     |      Args:
     |          host: Nom d'hôte ou adresse IP du serveur
     |          ports: Liste des ports à vérifier
     |          endpoints: Liste des endpoints HTTP à vérifier
     |
     |      Returns:
     |          Dictionnaire contenant le rapport de santé
     |
     |  diagnose_system(self) -> Dict[str, Any]
     |      Diagnostique le système et fournit un rapport détaillé.
     |
     |      Returns:
     |          Dictionnaire contenant le rapport de diagnostic
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from src.langchain.agents.base_agent.BaseAgent:
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Exécute l'agent avec les entrées fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entrée
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
     |      Exécute l'agent avec le texte d'entrée fourni.
     |
     |      Args:
     |          input_text: Texte d'entrée pour l'agent
     |
     |      Returns:
     |          La sortie générée par l'agent
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


