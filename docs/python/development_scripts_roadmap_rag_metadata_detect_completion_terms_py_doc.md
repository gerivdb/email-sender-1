Help on module detect_completion_terms:

NAME
    detect_completion_terms

DESCRIPTION
    Script pour détecter les termes de réalisation dans un texte.
    Ce script identifie les expressions qui indiquent qu'une tâche a été réalisée ou terminée.

    Usage:
        python detect_completion_terms.py -t "Tâche: Développer la fonctionnalité X (terminée)"
        python detect_completion_terms.py -i chemin/vers/fichier.txt
        python detect_completion_terms.py -t "Tâche: Implémentation terminée" --format json

    Options:
        -t, --text TEXT       Texte à analyser
        -i, --input FILE      Fichier d'entrée à analyser
        --format FORMAT       Format de sortie (text, json, csv)
        --debug               Activer le mode débogage

FUNCTIONS
    analyze_text_for_completion_terms(text)
        Analyse un texte pour détecter les termes de réalisation.

    extract_completion_terms(text)
        Extrait les termes de réalisation à partir d'un texte.

    format_output(analysis_result, format_type)
        Formate les résultats selon le format spécifié.

    main()

DATA
    COMPLETION_INDICATORS = ['terminé', 'terminée', 'terminés', 'terminées...
    COMPLETION_TERM_PATTERNS = ['(?:termine[e]?|terminé[e]?|complete[e]?|c...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\metadata\detect_completion_terms.py


