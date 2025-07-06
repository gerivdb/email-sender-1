Help on module get_code_structure:

NAME
    get_code_structure - Outil MCP pour obtenir la structure d'un fichier de code.

DESCRIPTION
    Cet outil permet d'extraire la structure d'un fichier de code (classes, fonctions, imports, etc.).

CLASSES
    builtins.object
        GetCodeStructureSchema

    class GetCodeStructureSchema(builtins.object)
     |  Sch�ma pour l'outil get_code_structure.
     |
     |  Static methods defined here:
     |
     |  get_schema() -> Dict[str, Any]
     |      R�cup�re le sch�ma de l'outil.
     |
     |      Returns:
     |          Dict[str, Any]: Sch�ma de l'outil
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
    get_code_structure(code_manager: src.mcp.core.code.CodeManager.CodeManager, params: Dict[str, Any]) -> Dict[str, Any]
        Obtient la structure d'un fichier de code.

        Args:
            code_manager (CodeManager): Instance du gestionnaire de code
            params (Dict[str, Any]): Param�tres de la requ�te

        Returns:
            Dict[str, Any]: Structure du code

    register_tool(mcp_server, code_manager: src.mcp.core.code.CodeManager.CodeManager) -> None
        Enregistre l'outil get_code_structure aupr�s du serveur MCP.

        Args:
            mcp_server: Instance du serveur MCP
            code_manager (CodeManager): Instance du gestionnaire de code

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    logger = <Logger mcp.code.tools.get_code_structure (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\code\tools\get_code_structure.py


