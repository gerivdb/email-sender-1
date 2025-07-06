Help on module analyze_mem0_with_mcp:

NAME
    analyze_mem0_with_mcp

DESCRIPTION
    Script pour analyser le d�p�t mem0ai/mem0 avec MCP Git Ingest.
    Ce script permet d'explorer la structure du d�p�t et de lire les fichiers importants
    pour �valuer si OpenMemory MCP serait utile et compatible avec Augment.

FUNCTIONS
    analyze_mcp_features(files_content)
        Analyse les fichiers pour d�tecter les fonctionnalit�s MCP.

    generate_report(structure, files_content)
        G�n�re un rapport d'analyse du d�p�t.

    async get_directory_structure()
        Obtient la structure du d�p�t GitHub.

    install_requirements()
        Installe les d�pendances n�cessaires.

    async main()
        Fonction principale.

    async read_important_files()
        Lit le contenu des fichiers importants du d�p�t GitHub.

    async run_mcp_command(tool, params)
        Ex�cute une commande MCP Git Ingest.

    save_results(structure, files_content)
        Sauvegarde les r�sultats de l'analyse dans des fichiers.

DATA
    IMPORTANT_FILES = ['README.md', 'pyproject.toml', 'setup.py', 'mem0/__...
    OUTPUT_DIR = WindowsPath('output/mem0-analysis')
    REPO_URL = 'https://github.com/mem0ai/mem0'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\analyze_mem0_with_mcp.py


