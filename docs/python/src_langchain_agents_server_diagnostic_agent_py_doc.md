Help on module server_diagnostic_agent:

NAME
    server_diagnostic_agent - Module contenant l'agent de diagnostic des serveurs.

DESCRIPTION
    Ce module fournit une implémentation spécifique de BaseAgent pour
    diagnostiquer les serveurs dans le cadre du projet EMAIL_SENDER_1.

CLASSES
    src.langchain.agents.base_agent.BaseAgent(builtins.object)
        ServerDiagnosticAgent

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

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\agents\server_diagnostic_agent.py


