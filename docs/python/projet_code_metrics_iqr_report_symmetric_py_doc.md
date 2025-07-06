Help on module iqr_report_symmetric:

NAME
    iqr_report_symmetric

DESCRIPTION
    Module pour cr�er un rapport complet sur la pr�cision de l'estimation de l'IQR
    pour les distributions sym�triques.

FUNCTIONS
    create_iqr_precision_report_symmetric(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Cr�e un rapport complet sur la pr�cision de l'estimation de l'IQR
        pour les distributions sym�triques.

        Args:
            data: Donn�es brutes
            bin_counts: Liste des nombres de bins � tester
            kde_points: Liste des nombres de points � tester
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la pr�cision de l'estimation de l'IQR

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\iqr_report_symmetric.py


