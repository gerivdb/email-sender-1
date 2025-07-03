Help on module recognize_actual_duration_formats:

NAME
    recognize_actual_duration_formats

DESCRIPTION
    Script pour reconna�tre les formats de dur�e r�elle dans un texte.
    Ce script identifie et analyse diff�rents formats d'expression de dur�e r�elle.

    Usage:
        python recognize_actual_duration_formats.py -t "T�che: D�velopper la fonctionnalit� X (a pris 4 heures)"
        python recognize_actual_duration_formats.py -i chemin/vers/fichier.txt
        python recognize_actual_duration_formats.py -t "T�che: 2.5 jours r�els" --format json

    Options:
        -t, --text TEXT       Texte � analyser
        -i, --input FILE      Fichier d'entr�e � analyser
        --format FORMAT       Format de sortie (text, json, csv)
        --debug               Activer le mode d�bogage

FUNCTIONS
    analyze_text_for_actual_duration_formats(text)
        Analyse un texte pour reconna�tre les formats de dur�e r�elle.

    calculate_date_range_duration(start_date_str, end_date_str)
        Calcule la dur�e entre deux dates.

    convert_to_hours(value, unit)
        Convertit une dur�e en heures.

    format_output(analysis_result, format_type)
        Formate les r�sultats selon le format sp�cifi�.

    main()

    normalize_unit(unit)
        Normalise l'unit� de temps.

    recognize_actual_duration_formats(text)
        Reconna�t les formats de dur�e r�elle dans un texte.

DATA
    ACTUAL_DURATION_FORMATS = {'approximate': {'confidence': 0.65, 'descri...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\metadata\recognize_actual_duration_formats.py


