Help on module register_code_tools:

NAME
    register_code_tools - Module pour enregistrer les outils de code auprès du serveur MCP.

DESCRIPTION
    Ce module fournit une fonction pour enregistrer tous les outils de code auprès du serveur MCP.

FUNCTIONS
    register_code_tools(mcp_server, base_path: Optional[str] = None, cache_path: Optional[str] = None) -> src.mcp.core.code.CodeManager.CodeManager
        Enregistre tous les outils de code auprès du serveur MCP.

        Args:
            mcp_server: Instance du serveur MCP
            base_path (Optional[str]): Chemin de base pour le code
            cache_path (Optional[str]): Chemin pour le cache des analyses

        Returns:
            CodeManager: Instance du gestionnaire de code

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    logger = <Logger mcp.code (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\code\register_code_tools.py


