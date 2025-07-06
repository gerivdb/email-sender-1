Help on module iqr_kde_evaluation:

NAME
    iqr_kde_evaluation

DESCRIPTION
    Module pour évaluer la précision de l'estimation de l'IQR (écart interquartile)
    à partir de KDEs.

FUNCTIONS
    evaluate_kde_iqr_precision(data: numpy.ndarray, kde_points: List[int], criteria: Optional[Dict[str, Any]] = None, distribution_type: str = 'symmetric') -> Dict[str, Any]
        Évalue la précision de l'estimation de l'IQR à partir de KDEs
        avec différents nombres de points.

        Args:
            data: Données brutes
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
            distribution_type: Type de distribution ('symmetric', 'heavy_tailed', 'multimodal', 'general')

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de points

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_kde_evaluation.py


