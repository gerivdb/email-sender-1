Help on module iqr_optimization:

NAME
    iqr_optimization - Module pour déterminer la résolution optimale pour l'estimation de l'IQR.

FUNCTIONS
    determine_optimal_resolution_for_iqr(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], quality_threshold: str = 'good') -> Dict[str, Any]
        Détermine la résolution optimale pour l'estimation de l'IQR.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            quality_threshold: Seuil de qualité minimal ('excellent', 'good', 'acceptable', 'poor')

        Returns:
            Dict[str, Any]: Résolutions optimales pour l'estimation de l'IQR

DATA
    Dict = typing.Dict
        A generic version of dict.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_optimization.py


