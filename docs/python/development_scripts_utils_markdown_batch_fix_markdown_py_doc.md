Help on module batch_fix_markdown:

NAME
    batch_fix_markdown - Script batch pour appliquer fix_markdown_v3.py � tous les fichiers Markdown d'un r�pertoire.

FUNCTIONS
    find_markdown_files(root_dir: pathlib.Path, exclude_dirs: Optional[List[str]] = None, exclude_files: Optional[List[str]] = None, include_pattern: Optional[str] = None, recursive: bool = True) -> List[pathlib.Path]
        Trouve tous les fichiers Markdown dans le r�pertoire sp�cifi�.

        Args:
            root_dir: R�pertoire racine pour la recherche
            exclude_dirs: Liste de noms de r�pertoires � exclure
            exclude_files: Liste de noms de fichiers � exclure
            include_pattern: Motif pour filtrer les fichiers (ex: "phase")
            recursive: Si True, recherche r�cursivement dans les sous-r�pertoires

        Returns:
            Liste des chemins de fichiers Markdown trouv�s

    main()

    process_markdown_file(file_path: pathlib.Path, fix_script_path: pathlib.Path, additional_args: List[str] = None, dry_run: bool = False) -> bool
        Applique le script fix_markdown_v3.py � un fichier Markdown.

        Args:
            file_path: Chemin du fichier Markdown � traiter
            fix_script_path: Chemin du script fix_markdown_v3.py
            additional_args: Arguments suppl�mentaires � passer au script
            dry_run: Si True, affiche la commande sans l'ex�cuter

        Returns:
            True si le traitement a r�ussi, False sinon

DATA
    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Set = typing.Set
        A generic version of set.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\utils\markdown\batch_fix_markdown.py


