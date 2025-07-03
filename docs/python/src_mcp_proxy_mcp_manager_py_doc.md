Help on module mcp_manager:

NAME
    mcp_manager - Module de gestion MCP avec support pour le proxy unifi�

CLASSES
    builtins.object
        MCPManager

    class MCPManager(builtins.object)
     |  MCPManager(config_path: str = 'config.json')
     |
     |  Gestionnaire pour les serveurs MCP avec support pour le proxy unifi�
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: str = 'config.json')
     |      Initialise le gestionnaire MCP
     |
     |      Args:
     |          config_path: Chemin vers le fichier de configuration
     |
     |  check_health(self, server_name: Optional[str] = None) -> Dict[str, Any]
     |      V�rifie la sant� d'un serveur MCP
     |
     |      Args:
     |          server_name: Nom du serveur (optionnel)
     |
     |      Returns:
     |          Informations de sant� du serveur
     |
     |  get_config(self, server_name: Optional[str] = None) -> Dict[str, Any]
     |      R�cup�re la configuration d'un serveur MCP
     |
     |      Args:
     |          server_name: Nom du serveur (optionnel)
     |
     |      Returns:
     |          Configuration du serveur
     |
     |  get_server_url(self, server_name: Optional[str] = None) -> str
     |      R�cup�re l'URL du serveur sp�cifi� ou du serveur actif
     |
     |      Args:
     |          server_name: Nom du serveur (optionnel)
     |
     |      Returns:
     |          URL du serveur
     |
     |  send_request(self, endpoint: str, method: str = 'GET', data: Any = None, params: Dict[str, Any] = None, server_name: Optional[str] = None) -> requests.models.Response
     |      Envoie une requ�te au serveur MCP
     |
     |      Args:
     |          endpoint: Point de terminaison de l'API
     |          method: M�thode HTTP (GET, POST, etc.)
     |          data: Donn�es � envoyer (pour POST, PUT, etc.)
     |          params: Param�tres de requ�te
     |          server_name: Nom du serveur (optionnel, utilise le serveur actif par d�faut)
     |
     |      Returns:
     |          R�ponse de la requ�te
     |
     |  set_active_server(self, server_name: str) -> None
     |      D�finit le serveur actif
     |
     |      Args:
     |          server_name: Nom du serveur � activer
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FUNCTIONS
    load_config(config_path: str = 'config.json') -> Dict[str, Any]
        Charge la configuration depuis un fichier JSON

        Args:
            config_path: Chemin vers le fichier de configuration

        Returns:
            Dict contenant la configuration

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\proxy\mcp_manager.py


