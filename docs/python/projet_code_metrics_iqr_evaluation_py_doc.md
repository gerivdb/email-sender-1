Help on module iqr_evaluation:

NAME
    iqr_evaluation

DESCRIPTION
    Module pour �valuer la pr�cision de l'estimation de l'IQR (�cart interquartile)
    � partir d'histogrammes et de KDEs.

FUNCTIONS
    define_iqr_error_thresholds_heavy_tailed(relative_error_threshold: float = 0.05) -> Dict[str, float]
        �tablit les seuils d'erreur relative pour l'estimation de l'IQR
        dans le cas des distributions � queue lourde.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable par d�faut (5%)

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'IQR

    define_iqr_error_thresholds_multimodal(relative_error_threshold: float = 0.05) -> Dict[str, float]
        �tablit les seuils d'erreur relative pour l'estimation de l'IQR
        dans le cas des distributions multimodales.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable par d�faut (5%)

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'IQR

    define_iqr_error_thresholds_symmetric(relative_error_threshold: float = 0.05) -> Dict[str, float]
        �tablit les seuils d'erreur relative pour l'estimation de l'IQR
        dans le cas des distributions sym�triques.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable par d�faut (5%)

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'IQR

    define_iqr_precision_criteria(relative_error_threshold: float = 0.05, confidence_level: float = 0.95) -> Dict[str, Any]
        �tablit les crit�res de pr�cision pour l'estimation de l'IQR.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable (par d�faut: 5%)
            confidence_level: Niveau de confiance pour les intervalles (par d�faut: 95%)

        Returns:
            Dict[str, Any]: Crit�res de pr�cision pour l'estimation de l'IQR

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

    evaluate_iqr_precision(true_iqr: float, estimated_iqr: float, sample_size: int, criteria: Dict[str, Any]) -> Dict[str, Any]
        �value la pr�cision de l'estimation de l'IQR selon les crit�res d�finis.

        Args:
            true_iqr: Valeur r�elle de l'IQR
            estimated_iqr: Valeur estim�e de l'IQR
            sample_size: Taille de l'�chantillon
            criteria: Crit�res de pr�cision pour l'estimation de l'IQR

        Returns:
            Dict[str, Any]: �valuation de la pr�cision de l'estimation

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_evaluation.py


