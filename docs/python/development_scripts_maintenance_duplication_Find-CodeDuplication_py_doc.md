Help on module Find-CodeDuplication:

NAME
    Find-CodeDuplication - Script de d�tection des duplications de code.

DESCRIPTION
    Ce script analyse les scripts pour d�tecter les duplications de code et g�n�re
    un rapport d�taill� des duplications trouv�es. Il utilise plusieurs m�thodes
    pour identifier les duplications, y compris la comparaison de cha�nes et
    l'analyse de similarit�.

    Utilise le multiprocessing pour acc�l�rer les comparaisons sur de grands volumes de fichiers.

FUNCTIONS
    calculate_similarity(text1, text2)
        Calcule la similarit� entre deux textes.

    compare_blocks(args)
        Compare deux blocs de code pour d�tecter les duplications.

    find_duplications(files, min_line_count, similarity_threshold, show_details=False)
        Trouve les duplications entre les fichiers.

    find_intra_file_duplications(file_path, min_line_count, similarity_threshold)
        Trouve les duplications � l'int�rieur d'un fichier.

    get_code_blocks(normalized_lines, min_line_count)
        Extrait les blocs de code de taille minimale.

    get_normalized_content(file_path)
        Lit et normalise le contenu d'un fichier.

    get_script_files(path, script_type='All')
        Obtient tous les fichiers de script du type sp�cifi�.

    get_script_type(file_path)
        D�termine le type de script � partir de l'extension.

    main()
        Fonction principale.

    process_file(file_path, min_line_count)
        Traite un fichier pour extraire ses blocs de code.

    write_log(message, level='INFO')
        �crit un message de log format�.

DATA
    DEFAULT_MIN_LINES = 5
    DEFAULT_OUTPUT_PATH = 'development/scripts/manager/data/duplication_re...
    DEFAULT_SIMILARITY_THRESHOLD = 0.8

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\maintenance\duplication\find-codeduplication.py


