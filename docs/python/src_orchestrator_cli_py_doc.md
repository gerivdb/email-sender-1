Help on module cli:

NAME
    cli - Interface de ligne de commande pour le syst�me CRUD modulaire th�matique.

DESCRIPTION
    Ce module fournit une interface de ligne de commande pour interagir avec
    le syst�me CRUD modulaire th�matique.

FUNCTIONS
    create_parser() -> argparse.ArgumentParser
        Cr�e le parseur d'arguments pour l'interface de ligne de commande.

        Returns:
            Parseur d'arguments

    format_output(data: Any, output_format: str) -> str
        Formate les donn�es de sortie.

        Args:
            data: Donn�es � formater
            output_format: Format de sortie (json ou text)

        Returns:
            Donn�es format�es

    main()
        Point d'entr�e principal de l'interface de ligne de commande.

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\cli.py


