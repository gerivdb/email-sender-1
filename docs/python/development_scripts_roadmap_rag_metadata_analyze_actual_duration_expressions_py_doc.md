Help on module analyze_actual_duration_expressions:

NAME
    analyze_actual_duration_expressions

DESCRIPTION
    Script pour analyser les expressions de durée effective/réelle dans un texte.
    Ce script détecte les expressions qui indiquent une durée réelle (par opposition à une estimation).

    Usage:
        python analyze_actual_duration_expressions.py -t "Tâche: Développer la fonctionnalité X (a pris 4 heures)"
        python analyze_actual_duration_expressions.py -i chemin/vers/fichier.txt
        python analyze_actual_duration_expressions.py -t "Tâche: 2.5 jours réels" --format json

    Options:
        -t, --text TEXT       Texte à analyser
        -i, --input FILE      Fichier d'entrée à analyser
        --format FORMAT       Format de sortie (text, json, csv)

FUNCTIONS
    analyze_text_for_actual_durations(text)
        Analyse un texte pour détecter les expressions de durée effective.

    extract_actual_durations(text)
        Extrait les expressions de durée effective à partir d'un texte.

    format_output(analysis_result, format_type)
        Formate les résultats selon le format spécifié.

    main()

    normalize_unit(unit)
        Normalise l'unité de temps.

DATA
    ACTUAL_DURATION_INDICATORS = ['réel', 'réelle', 'réels', 'réelles', 'e...
    ACTUAL_DURATION_PATTERNS = [r'(?:a\s+pris|a\s+dure|a\s+duré|a\s+necess...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\metadata\analyze_actual_duration_expressions.py


