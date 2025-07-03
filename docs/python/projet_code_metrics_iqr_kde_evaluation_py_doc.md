Help on module iqr_kde_evaluation:

NAME
    iqr_kde_evaluation

DESCRIPTION
    Module pour �valuer la pr�cision de l'estimation de l'IQR (�cart interquartile)
    � partir de KDEs.

FUNCTIONS
    evaluate_kde_iqr_precision(data: numpy.ndarray, kde_points: List[int], criteria: Optional[Dict[str, Any]] = None, distribution_type: str = 'symmetric') -> Dict[str, Any]
        �value la pr�cision de l'estimation de l'IQR � partir de KDEs
        avec diff�rents nombres de points.

        Args:
            data: Donn�es brutes
            kde_points: Liste des nombres de points � tester
            criteria: Crit�res de pr�cision pour l'estimation de l'IQR (optionnel)
            distribution_type: Type de distribution ('symmetric', 'heavy_tailed', 'multimodal', 'general')

        Returns:
            Dict[str, Any]: �valuation de la pr�cision pour diff�rents nombres de points

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_kde_evaluation.py


