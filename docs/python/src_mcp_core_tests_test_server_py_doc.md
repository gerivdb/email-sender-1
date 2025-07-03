Help on module test_server:

NAME
    test_server - Tests unitaires pour le serveur FastAPI.

DESCRIPTION
    Ce script contient les tests unitaires pour le serveur FastAPI qui expose des outils similaires à MCP.

FUNCTIONS
    test_add_endpoint()
        Teste l'endpoint add.

    test_add_endpoint_with_invalid_input()
        Teste l'endpoint add avec des entrées invalides.

    async test_add_function()
        Teste la fonction add.

    test_get_system_info_endpoint()
        Teste l'endpoint get_system_info.

    async test_get_system_info_function()
        Teste la fonction get_system_info.

    test_list_tools_endpoint()
        Teste l'endpoint de liste des outils.

    test_multiply_endpoint()
        Teste l'endpoint multiply.

    test_multiply_endpoint_with_invalid_input()
        Teste l'endpoint multiply avec des entrées invalides.

    async test_multiply_function()
        Teste la fonction multiply.

    test_nonexistent_endpoint()
        Teste un endpoint qui n'existe pas.

    test_root_endpoint()
        Teste l'endpoint racine.

DATA
    app = <fastapi.applications.FastAPI object>
    client = <starlette.testclient.TestClient object>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\tests\test_server.py


