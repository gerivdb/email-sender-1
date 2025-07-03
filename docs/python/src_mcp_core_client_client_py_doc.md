Help on module client:

NAME
    client - Client Python pour tester le serveur MCP.

DESCRIPTION
    Ce script montre comment utiliser le client MCP pour interagir avec le serveur MCP.

FUNCTIONS
    call_mcp_tool(server_url, tool_name, parameters=None)
        Appelle un outil MCP via l'API REST.

        Args:
            server_url: L'URL du serveur MCP.
            tool_name: Le nom de l'outil à appeler.
            parameters: Les paramètres à passer à l'outil.

        Returns:
            Le résultat de l'appel à l'outil.

    main()
        Fonction principale qui montre comment utiliser le client MCP.

DATA
    logger = <Logger mcp_client (DEBUG)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\client\client.py


