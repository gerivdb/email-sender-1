Help on module analyze_actual_duration_expressions:

NAME
    analyze_actual_duration_expressions

DESCRIPTION
    Script pour analyser les expressions de dur�e effective/r�elle dans un texte.
    Ce script d�tecte les expressions qui indiquent une dur�e r�elle (par opposition � une estimation).

    Usage:
        python analyze_actual_duration_expressions.py -t "T�che: D�velopper la fonctionnalit� X (a pris 4 heures)"
        python analyze_actual_duration_expressions.py -i chemin/vers/fichier.txt
        python analyze_actual_duration_expressions.py -t "T�che: 2.5 jours r�els" --format json

    Options:
        -t, --text TEXT       Texte � analyser
        -i, --input FILE      Fichier d'entr�e � analyser
        --format FORMAT       Format de sortie (text, json, csv)

FUNCTIONS
    analyze_text_for_actual_durations(text)
        Analyse un texte pour d�tecter les expressions de dur�e effective.

    extract_actual_durations(text)
        Extrait les expressions de dur�e effective � partir d'un texte.

    format_output(analysis_result, format_type)
        Formate les r�sultats selon le format sp�cifi�.

    main()

    normalize_unit(unit)
        Normalise l'unit� de temps.

DATA
    ACTUAL_DURATION_INDICATORS = ['r�el', 'r�elle', 'r�els', 'r�elles', 'e...
    ACTUAL_DURATION_PATTERNS = [r'(?:a\s+pris|a\s+dure|a\s+dur�|a\s+necess...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\metadata\analyze_actual_duration_expressions.py


