Help on module server_diagnostic_agent:

NAME
    server_diagnostic_agent - Module contenant l'agent de diagnostic des serveurs.

DESCRIPTION
    Ce module fournit une impl�mentation sp�cifique de BaseAgent pour
    diagnostiquer les serveurs dans le cadre du projet EMAIL_SENDER_1.

CLASSES
    src.langchain.agents.base_agent.BaseAgent(builtins.object)
        ServerDiagnosticAgent

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


