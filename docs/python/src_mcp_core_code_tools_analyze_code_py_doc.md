Help on module analyze_code:

NAME
    analyze_code - Outil MCP pour analyser du code.

DESCRIPTION
    Cet outil permet d'analyser un fichier de code pour obtenir des m�triques et d�tecter des probl�mes.

CLASSES
    builtins.object
        AnalyzeCodeSchema

    class AnalyzeCodeSchema(builtins.object)
     |  Sch�ma pour l'outil analyze_code.
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
    analyze_code(code_manager: src.mcp.core.code.CodeManager.CodeManager, params: Dict[str, Any]) -> Dict[str, Any]
        Analyse un fichier de code.

        Args:
            code_manager (CodeManager): Instance du gestionnaire de code
            params (Dict[str, Any]): Param�tres de l'analyse

        Returns:
            Dict[str, Any]: R�sultat de l'analyse

    register_tool(mcp_server, code_manager: src.mcp.core.code.CodeManager.CodeManager) -> None
        Enregistre l'outil analyze_code aupr�s du serveur MCP.

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

    logger = <Logger mcp.code.tools.analyze_code (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\code\tools\analyze_code.py


