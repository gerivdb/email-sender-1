Help on module extract_estimations:

NAME
    extract_estimations

DESCRIPTION
    Script pour extraire les estimations de durée à partir d'un texte.
    Ce script détecte les expressions d'estimation de temps et les convertit en format standard.

    Usage:
        python extract_estimations.py -t "Tâche: Développer la fonctionnalité X (environ 4 heures)"
        python extract_estimations.py -i chemin/vers/fichier.txt
        python extract_estimations.py -t "Tâche: 2.5 jours" --format json

    Options:
        -t, --text TEXT       Texte à analyser
        -i, --input FILE      Fichier d'entrée à analyser
        --format FORMAT       Format de sortie (text, json, csv)

FUNCTIONS
    extract_estimations(text)
        Extrait les estimations de durée à partir d'un texte.

    format_output(estimations, format_type)
        Formate les estimations selon le format spécifié.

    main()

    normalize_unit(unit)
        Normalise l'unité de temps.

DATA
    CONVERSION_FACTORS = {'d': 8, 'day': 8, 'days': 8, 'h': 1, 'heure': 1,...
    ESTIMATION_PATTERNS = [r'(?:environ|approximativement|~|\u2248|env\.|approx...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\metadata\extract_estimations.py


