Help on module kurtosis_precision_criteria:

NAME
    kurtosis_precision_criteria - Module pour d�finir les crit�res de pr�cision pour l'estimation de l'aplatissement (kurtosis).

FUNCTIONS
    define_kurtosis_error_thresholds_by_distribution_type(distribution_type: str = 'normal') -> Dict[str, float]
        �tablit les seuils d'erreur relative pour l'estimation de l'aplatissement
        en fonction du type de distribution.

        Args:
            distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'heavy_tailed')

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'aplatissement

    define_kurtosis_error_thresholds_by_magnitude(kurtosis_magnitude: str = 'medium') -> Dict[str, float]
        �tablit les seuils d'erreur relative pour l'estimation de l'aplatissement
        en fonction de l'amplitude de l'aplatissement.

        Args:
            kurtosis_magnitude: Amplitude de l'aplatissement ('low', 'medium', 'high')
                - 'low': |kurtosis - 3| < 1.0 (proche de la normale)
                - 'medium': 1.0 <= |kurtosis - 3| < 3.0
                - 'high': |kurtosis - 3| >= 3.0

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'aplatissement

    define_kurtosis_error_thresholds_by_sample_size(sample_size: int = 100) -> Dict[str, float]
        �tablit les seuils d'erreur relative pour l'estimation de l'aplatissement
        en fonction de la taille de l'�chantillon.

        Args:
            sample_size: Taille de l'�chantillon

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'aplatissement

    define_kurtosis_precision_criteria(relative_error_threshold: float = 0.15, confidence_level: float = 0.95) -> Dict[str, Any]
        �tablit les crit�res de pr�cision pour l'estimation de l'aplatissement.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable (par d�faut: 15%)
            confidence_level: Niveau de confiance pour les intervalles (par d�faut: 95%)

        Returns:
            Dict[str, Any]: Crit�res de pr�cision pour l'estimation de l'aplatissement

DATA
    Dict = typing.Dict
        A generic version of dict.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\kurtosis_precision_criteria.py


