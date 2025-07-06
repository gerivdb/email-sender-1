Help on module minimal_mcp_client:

NAME
    minimal_mcp_client - Client MCP minimal pour tester l'intégration avec PowerShell.

DESCRIPTION
    Ce script montre comment utiliser le client MCP pour interagir avec le serveur MCP minimal.

FUNCTIONS
    call_mcp_tool(base_url, tool_name, params=None)
        Appelle un outil MCP via l'API REST.

        Args:
            base_url: L'URL de base du serveur MCP.
            tool_name: Le nom de l'outil à appeler.
            params: Les paramètres à passer à l'outil.

        Returns:
            Le résultat de l'appel à l'outil.

    main()
        Fonction principale qui montre comment utiliser le client MCP.

DATA
    logger = <Logger mcp_client (DEBUG)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\scripts\python\minimal_mcp_client.py


