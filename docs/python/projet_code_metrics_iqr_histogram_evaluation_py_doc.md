Help on module iqr_histogram_evaluation:

NAME
    iqr_histogram_evaluation

DESCRIPTION
    Module pour �valuer la pr�cision de l'estimation de l'IQR (�cart interquartile)
    � partir d'histogrammes.

FUNCTIONS
    evaluate_histogram_iqr_precision(data: numpy.ndarray, bin_counts: List[int], criteria: Optional[Dict[str, Any]] = None, distribution_type: str = 'symmetric') -> Dict[str, Any]
        �value la pr�cision de l'estimation de l'IQR � partir d'histogrammes
        avec diff�rents nombres de bins.

        Args:
            data: Donn�es brutes
            bin_counts: Liste des nombres de bins � tester
            criteria: Crit�res de pr�cision pour l'estimation de l'IQR (optionnel)
            distribution_type: Type de distribution ('symmetric', 'heavy_tailed', 'multimodal', 'general')

        Returns:
            Dict[str, Any]: �valuation de la pr�cision pour diff�rents nombres de bins

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_histogram_evaluation.py


