Help on module batch_fix_markdown:

NAME
    batch_fix_markdown - Script batch pour appliquer fix_markdown_v3.py à tous les fichiers Markdown d'un répertoire.

FUNCTIONS
    find_markdown_files(root_dir: pathlib.Path, exclude_dirs: Optional[List[str]] = None, exclude_files: Optional[List[str]] = None, include_pattern: Optional[str] = None, recursive: bool = True) -> List[pathlib.Path]
        Trouve tous les fichiers Markdown dans le répertoire spécifié.

        Args:
            root_dir: Répertoire racine pour la recherche
            exclude_dirs: Liste de noms de répertoires à exclure
            exclude_files: Liste de noms de fichiers à exclure
            include_pattern: Motif pour filtrer les fichiers (ex: "phase")
            recursive: Si True, recherche récursivement dans les sous-répertoires

        Returns:
            Liste des chemins de fichiers Markdown trouvés

    main()

    process_markdown_file(file_path: pathlib.Path, fix_script_path: pathlib.Path, additional_args: List[str] = None, dry_run: bool = False) -> bool
        Applique le script fix_markdown_v3.py à un fichier Markdown.

        Args:
            file_path: Chemin du fichier Markdown à traiter
            fix_script_path: Chemin du script fix_markdown_v3.py
            additional_args: Arguments supplémentaires à passer au script
            dry_run: Si True, affiche la commande sans l'exécuter

        Returns:
            True si le traitement a réussi, False sinon

DATA
    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Set = typing.Set
        A generic version of set.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\utils\markdown\batch_fix_markdown.py


