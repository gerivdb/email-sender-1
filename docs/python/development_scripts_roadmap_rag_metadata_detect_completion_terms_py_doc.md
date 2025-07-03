Help on module detect_completion_terms:

NAME
    detect_completion_terms

DESCRIPTION
    Script pour d�tecter les termes de r�alisation dans un texte.
    Ce script identifie les expressions qui indiquent qu'une t�che a �t� r�alis�e ou termin�e.

    Usage:
        python detect_completion_terms.py -t "T�che: D�velopper la fonctionnalit� X (termin�e)"
        python detect_completion_terms.py -i chemin/vers/fichier.txt
        python detect_completion_terms.py -t "T�che: Impl�mentation termin�e" --format json

    Options:
        -t, --text TEXT       Texte � analyser
        -i, --input FILE      Fichier d'entr�e � analyser
        --format FORMAT       Format de sortie (text, json, csv)
        --debug               Activer le mode d�bogage

FUNCTIONS
    analyze_text_for_completion_terms(text)
        Analyse un texte pour d�tecter les termes de r�alisation.

    extract_completion_terms(text)
        Extrait les termes de r�alisation � partir d'un texte.

    format_output(analysis_result, format_type)
        Formate les r�sultats selon le format sp�cifi�.

    main()

DATA
    COMPLETION_INDICATORS = ['termin�', 'termin�e', 'termin�s', 'termin�es...
    COMPLETION_TERM_PATTERNS = ['(?:termine[e]?|termin�[e]?|complete[e]?|c...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\metadata\detect_completion_terms.py


