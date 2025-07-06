Help on module skewness_precision_criteria:

NAME
    skewness_precision_criteria - Module pour d�finir les crit�res de pr�cision pour l'estimation de l'asym�trie (skewness).

FUNCTIONS
    define_skewness_error_thresholds_by_distribution_type(distribution_type: str = 'normal') -> Dict[str, float]
        �tablit les seuils d'erreur relative pour l'estimation de l'asym�trie
        en fonction du type de distribution.

        Args:
            distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'heavy_tailed')

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'asym�trie

    define_skewness_error_thresholds_by_magnitude(skewness_magnitude: str = 'medium') -> Dict[str, float]
        �tablit les seuils d'erreur relative pour l'estimation de l'asym�trie
        en fonction de l'amplitude de l'asym�trie.

        Args:
            skewness_magnitude: Amplitude de l'asym�trie ('low', 'medium', 'high')
                - 'low': |skewness| < 0.5
                - 'medium': 0.5 <= |skewness| < 1.0
                - 'high': |skewness| >= 1.0

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'asym�trie

    define_skewness_error_thresholds_by_sample_size(sample_size: int = 100) -> Dict[str, float]
        �tablit les seuils d'erreur relative pour l'estimation de l'asym�trie
        en fonction de la taille de l'�chantillon.

        Args:
            sample_size: Taille de l'�chantillon

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'asym�trie

    define_skewness_precision_criteria(relative_error_threshold: float = 0.1, confidence_level: float = 0.95) -> Dict[str, Any]
        �tablit les crit�res de pr�cision pour l'estimation de l'asym�trie.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable (par d�faut: 10%)
            confidence_level: Niveau de confiance pour les intervalles (par d�faut: 95%)

        Returns:
            Dict[str, Any]: Crit�res de pr�cision pour l'estimation de l'asym�trie

DATA
    Dict = typing.Dict
        A generic version of dict.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\skewness_precision_criteria.py


