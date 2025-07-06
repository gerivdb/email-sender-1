Help on module normalize_estimations:

NAME
    normalize_estimations

DESCRIPTION
    Script pour normaliser les estimations de durée.
    Ce script convertit les estimations de temps en un format standard.

    Usage:
        python normalize_estimations.py -t "4 heures" -u "Hours"
        python normalize_estimations.py -i chemin/vers/fichier.txt -u "Days"
        python normalize_estimations.py -t "2.5 jours" -u "Hours" --format json

    Options:
        -t, --text TEXT       Texte à analyser
        -i, --input FILE      Fichier d'entrée à analyser
        -u, --unit UNIT       Unité cible (Hours, Days, Weeks, Months)
        --format FORMAT       Format de sortie (text, json, csv)

FUNCTIONS
    convert_to_standard(value, source_unit, target_unit)
        Convertit une valeur d'une unité à une autre.

    extract_simple_estimations(text)
        Extrait les estimations simples de durée à partir d'un texte.

    format_output(estimations, format_type)
        Formate les estimations selon le format spécifié.

    main()

    normalize_estimations(estimations, target_unit)
        Normalise les estimations selon l'unité cible.

    normalize_unit(unit)
        Normalise l'unité de temps.

DATA
    CONVERSION_FACTORS = {'Days': 8, 'Hours': 1, 'Minutes': 0.016666666666...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\metadata\normalize_estimations.py


