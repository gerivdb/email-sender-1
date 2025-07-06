Help on module format_roadmap_text_corrected:

NAME
    format_roadmap_text_corrected

DESCRIPTION
    Script pour reformater du texte en format roadmap avec phases, tâches et sous-tâches
    --------------------------------------------------------
    Ce script permet de convertir un texte brut en format roadmap structuré.

FUNCTIONS
    format_line_by_indentation(line: str, level: int) -> str
        Formate une ligne en fonction de son niveau d'indentation.

    format_text_to_roadmap(input_text: str, section_title: str, complexity: str, time_estimate: str) -> str
        Reformate le texte en format roadmap.

    get_indentation_level(line: str) -> int
        Détermine le niveau d'indentation d'une ligne.

    insert_section_in_roadmap(roadmap_path: str, section_content: str, section_number: int, dry_run: bool = False) -> bool
        Insère une section dans la roadmap.

    is_phase_title(line: str) -> bool
        Détermine si une ligne est un titre de phase.

    main()
        Fonction principale.

DATA
    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Tuple = typing.Tuple
        Deprecated alias to builtins.tuple.

        Tuple[X, Y] is the cross-product type of X and Y.

        Example: Tuple[T1, T2] is a tuple of two elements corresponding
        to type variables T1 and T2.  Tuple[int, float, str] is a tuple
        of an int, a float and a string.

        To specify a variable-length tuple of homogeneous type, use Tuple[T, ...].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\python\utils\roadmap\format_roadmap_text_corrected.py


