Help on module recognize_actual_duration_formats:

NAME
    recognize_actual_duration_formats

DESCRIPTION
    Script pour reconnaître les formats de durée réelle dans un texte.
    Ce script identifie et analyse différents formats d'expression de durée réelle.

    Usage:
        python recognize_actual_duration_formats.py -t "Tâche: Développer la fonctionnalité X (a pris 4 heures)"
        python recognize_actual_duration_formats.py -i chemin/vers/fichier.txt
        python recognize_actual_duration_formats.py -t "Tâche: 2.5 jours réels" --format json

    Options:
        -t, --text TEXT       Texte à analyser
        -i, --input FILE      Fichier d'entrée à analyser
        --format FORMAT       Format de sortie (text, json, csv)
        --debug               Activer le mode débogage

FUNCTIONS
    analyze_text_for_actual_duration_formats(text)
        Analyse un texte pour reconnaître les formats de durée réelle.

    calculate_date_range_duration(start_date_str, end_date_str)
        Calcule la durée entre deux dates.

    convert_to_hours(value, unit)
        Convertit une durée en heures.

    format_output(analysis_result, format_type)
        Formate les résultats selon le format spécifié.

    main()

    normalize_unit(unit)
        Normalise l'unité de temps.

    recognize_actual_duration_formats(text)
        Reconnaît les formats de durée réelle dans un texte.

DATA
    ACTUAL_DURATION_FORMATS = {'approximate': {'confidence': 0.65, 'descri...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\metadata\recognize_actual_duration_formats.py


