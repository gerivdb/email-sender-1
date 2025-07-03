Help on module iqr_histogram_evaluation:

NAME
    iqr_histogram_evaluation

DESCRIPTION
    Module pour évaluer la précision de l'estimation de l'IQR (écart interquartile)
    à partir d'histogrammes.

FUNCTIONS
    evaluate_histogram_iqr_precision(data: numpy.ndarray, bin_counts: List[int], criteria: Optional[Dict[str, Any]] = None, distribution_type: str = 'symmetric') -> Dict[str, Any]
        Évalue la précision de l'estimation de l'IQR à partir d'histogrammes
        avec différents nombres de bins.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
            distribution_type: Type de distribution ('symmetric', 'heavy_tailed', 'multimodal', 'general')

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de bins

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_histogram_evaluation.py


