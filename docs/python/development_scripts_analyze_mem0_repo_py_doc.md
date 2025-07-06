Help on module analyze_mem0_repo:

NAME
    analyze_mem0_repo

DESCRIPTION
    Script pour analyser le dépôt mem0ai/mem0 avec MCP Git Ingest.
    Ce script permet d'explorer la structure du dépôt et de lire les fichiers importants
    pour évaluer si OpenMemory MCP serait utile et compatible avec Augment.

FUNCTIONS
    generate_report(structure, files_content)
        Génère un rapport d'analyse du dépôt.

    get_directory_structure()
        Obtient la structure du dépôt GitHub.

    install_requirements()
        Installe les dépendances nécessaires.

    main()
        Fonction principale.

    read_important_files(file_paths)
        Lit le contenu des fichiers importants du dépôt GitHub.

    save_results(structure, files_content)
        Sauvegarde les résultats de l'analyse dans des fichiers.

DATA
    REPO_URL = 'https://github.com/mem0ai/mem0'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\analyze_mem0_repo.py


