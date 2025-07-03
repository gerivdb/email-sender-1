Help on module search_code:

NAME
    search_code - Outil MCP pour rechercher du code.

DESCRIPTION
    Cet outil permet de rechercher du code dans des fichiers en fonction de différents critères.

CLASSES
    builtins.object
        SearchCodeSchema

    class SearchCodeSchema(builtins.object)
     |  Schéma pour l'outil search_code.
     |
     |  Static methods defined here:
     |
     |  get_schema() -> Dict[str, Any]
     |      Récupère le schéma de l'outil.
     |
     |      Returns:
     |          Dict[str, Any]: Schéma de l'outil
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
    register_tool(mcp_server, code_manager: src.mcp.core.code.CodeManager.CodeManager) -> None
        Enregistre l'outil search_code auprès du serveur MCP.

        Args:
            mcp_server: Instance du serveur MCP
            code_manager (CodeManager): Instance du gestionnaire de code

    search_code(code_manager: src.mcp.core.code.CodeManager.CodeManager, params: Dict[str, Any]) -> Dict[str, Any]
        Recherche du code correspondant à une requête.

        Args:
            code_manager (CodeManager): Instance du gestionnaire de code
            params (Dict[str, Any]): Paramètres de la recherche

        Returns:
            Dict[str, Any]: Résultats de la recherche

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    logger = <Logger mcp.code.tools.search_code (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\code\tools\search_code.py


