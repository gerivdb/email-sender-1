Help on module Find-CodeDuplication:

NAME
    Find-CodeDuplication - Script de détection des duplications de code.

DESCRIPTION
    Ce script analyse les scripts pour détecter les duplications de code et génère
    un rapport détaillé des duplications trouvées. Il utilise plusieurs méthodes
    pour identifier les duplications, y compris la comparaison de chaînes et
    l'analyse de similarité.

    Utilise le multiprocessing pour accélérer les comparaisons sur de grands volumes de fichiers.

FUNCTIONS
    calculate_similarity(text1, text2)
        Calcule la similarité entre deux textes.

    compare_blocks(args)
        Compare deux blocs de code pour détecter les duplications.

    find_duplications(files, min_line_count, similarity_threshold, show_details=False)
        Trouve les duplications entre les fichiers.

    find_intra_file_duplications(file_path, min_line_count, similarity_threshold)
        Trouve les duplications à l'intérieur d'un fichier.

    get_code_blocks(normalized_lines, min_line_count)
        Extrait les blocs de code de taille minimale.

    get_normalized_content(file_path)
        Lit et normalise le contenu d'un fichier.

    get_script_files(path, script_type='All')
        Obtient tous les fichiers de script du type spécifié.

    get_script_type(file_path)
        Détermine le type de script à partir de l'extension.

    main()
        Fonction principale.

    process_file(file_path, min_line_count)
        Traite un fichier pour extraire ses blocs de code.

    write_log(message, level='INFO')
        Écrit un message de log formaté.

DATA
    DEFAULT_MIN_LINES = 5
    DEFAULT_OUTPUT_PATH = 'development/scripts/manager/data/duplication_re...
    DEFAULT_SIMILARITY_THRESHOLD = 0.8

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\maintenance\duplication\find-codeduplication.py


