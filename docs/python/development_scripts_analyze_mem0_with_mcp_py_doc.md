Help on module analyze_mem0_with_mcp:

NAME
    analyze_mem0_with_mcp

DESCRIPTION
    Script pour analyser le dépôt mem0ai/mem0 avec MCP Git Ingest.
    Ce script permet d'explorer la structure du dépôt et de lire les fichiers importants
    pour évaluer si OpenMemory MCP serait utile et compatible avec Augment.

FUNCTIONS
    analyze_mcp_features(files_content)
        Analyse les fichiers pour détecter les fonctionnalités MCP.

    generate_report(structure, files_content)
        Génère un rapport d'analyse du dépôt.

    async get_directory_structure()
        Obtient la structure du dépôt GitHub.

    install_requirements()
        Installe les dépendances nécessaires.

    async main()
        Fonction principale.

    async read_important_files()
        Lit le contenu des fichiers importants du dépôt GitHub.

    async run_mcp_command(tool, params)
        Exécute une commande MCP Git Ingest.

    save_results(structure, files_content)
        Sauvegarde les résultats de l'analyse dans des fichiers.

DATA
    IMPORTANT_FILES = ['README.md', 'pyproject.toml', 'setup.py', 'mem0/__...
    OUTPUT_DIR = WindowsPath('output/mem0-analysis')
    REPO_URL = 'https://github.com/mem0ai/mem0'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\analyze_mem0_with_mcp.py


