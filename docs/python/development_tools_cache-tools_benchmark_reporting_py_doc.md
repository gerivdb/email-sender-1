Help on module reporting:

NAME
    reporting - Module de g�n�ration de rapports pour les benchmarks du syst�me de cache.

DESCRIPTION
    Ce module fournit les fonctions n�cessaires pour g�n�rer des rapports
    d�taill�s sur les performances du syst�me de cache.

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

FUNCTIONS
    compare_reports(report_files: List[str]) -> Dict[str, Any]
        Compare plusieurs rapports de benchmark.

        Args:
            report_files (List[str]): Liste des chemins des fichiers de rapport.

        Returns:
            Dict[str, Any]: R�sultats de la comparaison.

    generate_html_report(report: Dict[str, Any], json_file: str) -> str
        G�n�re un rapport HTML � partir du rapport JSON.

        Args:
            report (Dict[str, Any]): Rapport au format JSON.
            json_file (str): Chemin du fichier JSON.

        Returns:
            str: Chemin du fichier HTML g�n�r�.

    generate_report(results: Dict[str, Any], config: Dict[str, Any]) -> str
        G�n�re un rapport d�taill� des r�sultats du benchmark.

        Args:
            results (Dict[str, Any]): R�sultats du benchmark.
            config (Dict[str, Any]): Configuration du benchmark.

        Returns:
            str: Chemin du fichier de rapport g�n�r�.

    generate_summary(results: Dict[str, Any], config: Dict[str, Any]) -> Dict[str, Any]
        G�n�re un r�sum� des r�sultats du benchmark.

        Args:
            results (Dict[str, Any]): R�sultats du benchmark.
            config (Dict[str, Any]): Configuration du benchmark.

        Returns:
            Dict[str, Any]: R�sum� des r�sultats.

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Union = typing.Union
        Union type; Union[X, Y] means either X or Y.

        On Python 3.10 and higher, the | operator
        can also be used to denote unions;
        X | Y means the same thing to the type checker as Union[X, Y].

        To define a union, use e.g. Union[int, str]. Details:
        - The arguments must be types and there must be at least one.
        - None as an argument is a special case and is replaced by
          type(None).
        - Unions of unions are flattened, e.g.::

            assert Union[Union[int, str], float] == Union[int, str, float]

        - Unions of a single argument vanish, e.g.::

            assert Union[int] == int  # The constructor actually returns int

        - Redundant arguments are skipped, e.g.::

            assert Union[int, str, int] == Union[int, str]

        - When comparing unions, the argument order is ignored, e.g.::

            assert Union[int, str] == Union[str, int]

        - You cannot subclass or instantiate a union.
        - You can use Optional[X] as a shorthand for Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\tools\cache-tools\benchmark\reporting.py


