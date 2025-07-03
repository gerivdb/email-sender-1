Help on module __init__:

NAME
    __init__ - Module d'initialisation pour les chaînes Langchain.

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

DATA
    __all__ = ['BaseLLMChain', 'EmailGenerationChain', 'EmailAnalysisChain...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\chains\__init__.py


