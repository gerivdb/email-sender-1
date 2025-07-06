Help on module iqr_visualization:

NAME
    iqr_visualization - Module pour visualiser les résultats de l'évaluation de la précision de l'IQR.

FUNCTIONS
    plot_iqr_precision_evaluation(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], title: str = "Évaluation de la précision de l'estimation de l'IQR", save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'évaluation de la précision de l'estimation de l'IQR.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            title: Titre du graphique
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

DATA
    Dict = typing.Dict
        A generic version of dict.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_visualization.py


