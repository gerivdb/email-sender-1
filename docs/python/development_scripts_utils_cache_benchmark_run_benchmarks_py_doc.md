Help on module run_benchmarks:

NAME
    run_benchmarks - Script d'ex�cution des benchmarks pour le syst�me de cache.

DESCRIPTION
    Ce script permet d'ex�cuter une suite de benchmarks sur diff�rentes
    impl�mentations du syst�me de cache et de g�n�rer des rapports comparatifs.

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

FUNCTIONS
    create_cache(cache_type: str, **kwargs) -> Any
        Cr�e une instance de cache du type sp�cifi�.

        Args:
            cache_type (str): Type de cache � cr�er.
            **kwargs: Param�tres suppl�mentaires pour le cache.

        Returns:
            Any: Instance du cache.

    main()
        Fonction principale.

    run_benchmark_suite(test_suite: List[Dict[str, Any]]) -> List[str]
        Ex�cute une suite de benchmarks et g�n�re des rapports.

        Args:
            test_suite (List[Dict[str, Any]]): Liste des sp�cifications de test.

        Returns:
            List[str]: Liste des chemins des fichiers de rapport g�n�r�s.

    run_single_benchmark(test_spec) -> str
        Ex�cute un benchmark unique et g�n�re un rapport.

        Args:
            test_spec: Sp�cification du test (Dict[str, Any] ou CacheTestSpec).

        Returns:
            str: Chemin du fichier de rapport g�n�r�.

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\utils\cache\benchmark\run_benchmarks.py


