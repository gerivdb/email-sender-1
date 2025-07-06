Help on module mode_width_adaptive_binning:

NAME
    mode_width_adaptive_binning - Module pour l'implémentation d'une méthode de binning variable selon la largeur des modes.

FUNCTIONS
    calculate_variable_bin_widths(data: numpy.ndarray, modes_info: Dict[str, Any], min_bins_per_mode: int = 5, max_bins_per_mode: int = 20) -> Dict[str, Any]
        Calcule les largeurs de bins variables en fonction des modes détectés.

        Args:
            data: Données à analyser
            modes_info: Informations sur les modes détectés
            min_bins_per_mode: Nombre minimal de bins par mode
            max_bins_per_mode: Nombre maximal de bins par mode

        Returns:
            Dict[str, Any]: Informations sur les largeurs de bins variables

    detect_modes_with_widths(data: numpy.ndarray, kde_bandwidth: Union[str, float] = 'scott', prominence_threshold: float = 0.1, min_height: float = 0.2, min_distance: int = 3, use_kde: bool = True) -> Dict[str, Any]
        Détecte les modes dans une distribution et calcule leurs largeurs.

        Args:
            data: Données à analyser
            kde_bandwidth: Largeur de bande pour l'estimation par noyau (KDE)
            prominence_threshold: Seuil de proéminence pour considérer un pic
            min_height: Hauteur minimale pour considérer un pic
            min_distance: Distance minimale entre les pics en nombre de bins
            use_kde: Si True, utilise l'estimation par noyau (KDE) pour une détection plus précise

        Returns:
            Dict[str, Any]: Informations sur les modes détectés et leurs largeurs

    plot_modes_with_widths(data: numpy.ndarray, modes_info: Dict[str, Any], use_kde: bool = True, kde_bandwidth: Union[str, float] = 'scott', save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise les modes détectés et leurs largeurs.

        Args:
            data: Données à analyser
            modes_info: Informations sur les modes détectés
            use_kde: Si True, utilise l'estimation par noyau (KDE) pour la visualisation
            kde_bandwidth: Largeur de bande pour l'estimation par noyau (KDE)
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_variable_bin_widths(data: numpy.ndarray, modes_info: Dict[str, Any], bin_info: Dict[str, Any], save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise les largeurs de bins variables en fonction des modes détectés.

        Args:
            data: Données à analyser
            modes_info: Informations sur les modes détectés
            bin_info: Informations sur les largeurs de bins variables
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

DATA
    Dict = typing.Dict
        A generic version of dict.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Union = typing.Union
        Union type; Union[X, Y] means either X or Y.

        On Python 3.10 and higher, the | operator
        can also be used to denote unions;
        X | Y means the same thing to the type checker as Union[X, Y].

        To define a union, use e.g. Union[int, str]. Details:
        - The arguments must be types and there must be at least one.
        - None as an argument is a special case and is replaced by
          type(None).
        - Unions of unions are flattened, e.g.::

            assert Union[Union[int, str], float] == Union[int, str, float]

        - Unions of a single argument vanish, e.g.::

            assert Union[int] == int  # The constructor actually returns int

        - Redundant arguments are skipped, e.g.::

            assert Union[int, str, int] == Union[int, str]

        - When comparing unions, the argument order is ignored, e.g.::

            assert Union[int, str] == Union[str, int]

        - You cannot subclass or instantiate a union.
        - You can use Optional[X] as a shorthand for Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\mode_width_adaptive_binning.py


