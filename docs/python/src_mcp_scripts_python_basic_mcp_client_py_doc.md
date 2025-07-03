Help on module basic_mcp_client:

NAME
    basic_mcp_client - Client MCP basique pour tester le serveur MCP.

DESCRIPTION
    Ce script montre comment utiliser le client MCP pour interagir avec le serveur MCP basique.

FUNCTIONS
    call_mcp_tool(server_path, tool_name, params=None)
        Appelle un outil MCP via le protocole MCP standard (stdio).

        Args:
            server_path: Le chemin vers le script du serveur MCP.
            tool_name: Le nom de l'outil à appeler.
            params: Les paramètres à passer à l'outil.

        Returns:
            Le résultat de l'appel à l'outil.

    main()
        Fonction principale qui montre comment utiliser le client MCP.

DATA
    logger = <Logger basic_mcp_client (DEBUG)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\scripts\python\basic_mcp_client.py


