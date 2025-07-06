Help on module Merge-SimilarScripts:

NAME
    Merge-SimilarScripts - Script de fusion des scripts similaires.

DESCRIPTION
    Ce script utilise le rapport généré par Find-CodeDuplication.py pour fusionner
    les scripts similaires et éliminer les duplications de code. Il crée des fonctions
    réutilisables pour le code dupliqué et met à jour les références.

    Utilise difflib pour une fusion intelligente et multiprocessing pour le traitement parallèle.

FUNCTIONS
    create_function(block_text, function_name, script_type)
        Crée une fonction à partir d'un bloc de code.

    create_function_call(function_name, script_type, library_path)
        Crée un appel de fonction.

    create_function_library(function_name, function_body, script_type, library_path, apply=False)
        Crée une bibliothèque de fonctions.

    generate_function_name(block_text, script_type, index)
        Génère un nom de fonction à partir d'un bloc de code.

    get_file_extension(script_type)
        Retourne l'extension de fichier pour un type de script.

    get_script_type(file_path)
        Détermine le type de script à partir de l'extension.

    main()
        Fonction principale.

    merge_duplications(duplications, library_path, min_duplication_count, apply=False)
        Fusionne les duplications.

    update_script_with_function_call(file_path, block_text, function_call, apply=False)
        Remplace un bloc de code par un appel de fonction.

    validate_merge(file1, file2, block1, block2, similarity)
        Demande une validation manuelle avant fusion.

    write_log(message, level='INFO')
        Écrit un message de log formaté.

DATA
    DEFAULT_INPUT_PATH = 'development/scripts/manager/data/duplication_rep...
    DEFAULT_LIBRARY_PATH = 'development/scripts/common/lib'
    DEFAULT_MIN_DUPLICATION_COUNT = 2
    DEFAULT_OUTPUT_PATH = 'development/scripts/manager/data/merge_report.j...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\maintenance\duplication\merge-similarscripts.py


