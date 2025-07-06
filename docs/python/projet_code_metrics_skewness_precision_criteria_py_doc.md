Help on module skewness_precision_criteria:

NAME
    skewness_precision_criteria - Module pour définir les critères de précision pour l'estimation de l'asymétrie (skewness).

FUNCTIONS
    define_skewness_error_thresholds_by_distribution_type(distribution_type: str = 'normal') -> Dict[str, float]
        Établit les seuils d'erreur relative pour l'estimation de l'asymétrie
        en fonction du type de distribution.

        Args:
            distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'heavy_tailed')

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'asymétrie

    define_skewness_error_thresholds_by_magnitude(skewness_magnitude: str = 'medium') -> Dict[str, float]
        Établit les seuils d'erreur relative pour l'estimation de l'asymétrie
        en fonction de l'amplitude de l'asymétrie.

        Args:
            skewness_magnitude: Amplitude de l'asymétrie ('low', 'medium', 'high')
                - 'low': |skewness| < 0.5
                - 'medium': 0.5 <= |skewness| < 1.0
                - 'high': |skewness| >= 1.0

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'asymétrie

    define_skewness_error_thresholds_by_sample_size(sample_size: int = 100) -> Dict[str, float]
        Établit les seuils d'erreur relative pour l'estimation de l'asymétrie
        en fonction de la taille de l'échantillon.

        Args:
            sample_size: Taille de l'échantillon

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'asymétrie

    define_skewness_precision_criteria(relative_error_threshold: float = 0.1, confidence_level: float = 0.95) -> Dict[str, Any]
        Établit les critères de précision pour l'estimation de l'asymétrie.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 10%)
            confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)

        Returns:
            Dict[str, Any]: Critères de précision pour l'estimation de l'asymétrie

DATA
    Dict = typing.Dict
        A generic version of dict.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\skewness_precision_criteria.py


