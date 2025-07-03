Help on module iqr_optimization:

NAME
    iqr_optimization - Module pour d�terminer la r�solution optimale pour l'estimation de l'IQR.

FUNCTIONS
    determine_optimal_resolution_for_iqr(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], quality_threshold: str = 'good') -> Dict[str, Any]
        D�termine la r�solution optimale pour l'estimation de l'IQR.

        Args:
            histogram_results: R�sultats de l'�valuation pour les histogrammes
            kde_results: R�sultats de l'�valuation pour les KDEs
            quality_threshold: Seuil de qualit� minimal ('excellent', 'good', 'acceptable', 'poor')

        Returns:
            Dict[str, Any]: R�solutions optimales pour l'estimation de l'IQR

DATA
    Dict = typing.Dict
        A generic version of dict.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_optimization.py


