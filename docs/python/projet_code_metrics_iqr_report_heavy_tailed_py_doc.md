Help on module iqr_report_heavy_tailed:

NAME
    iqr_report_heavy_tailed

DESCRIPTION
    Module pour créer un rapport complet sur la précision de l'estimation de l'IQR
    pour les distributions à queue lourde.

FUNCTIONS
    create_iqr_precision_report_heavy_tailed(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur la précision de l'estimation de l'IQR
        pour les distributions à queue lourde.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'IQR

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_report_heavy_tailed.py


