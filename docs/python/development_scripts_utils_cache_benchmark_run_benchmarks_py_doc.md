Help on module run_benchmarks:

NAME
    run_benchmarks - Script d'exécution des benchmarks pour le système de cache.

DESCRIPTION
    Ce script permet d'exécuter une suite de benchmarks sur différentes
    implémentations du système de cache et de générer des rapports comparatifs.

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

FUNCTIONS
    create_cache(cache_type: str, **kwargs) -> Any
        Crée une instance de cache du type spécifié.

        Args:
            cache_type (str): Type de cache à créer.
            **kwargs: Paramètres supplémentaires pour le cache.

        Returns:
            Any: Instance du cache.

    main()
        Fonction principale.

    run_benchmark_suite(test_suite: List[Dict[str, Any]]) -> List[str]
        Exécute une suite de benchmarks et génère des rapports.

        Args:
            test_suite (List[Dict[str, Any]]): Liste des spécifications de test.

        Returns:
            List[str]: Liste des chemins des fichiers de rapport générés.

    run_single_benchmark(test_spec) -> str
        Exécute un benchmark unique et génère un rapport.

        Args:
            test_spec: Spécification du test (Dict[str, Any] ou CacheTestSpec).

        Returns:
            str: Chemin du fichier de rapport généré.

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\utils\cache\benchmark\run_benchmarks.py


