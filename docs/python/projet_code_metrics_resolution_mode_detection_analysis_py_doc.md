Help on module resolution_mode_detection_analysis:

NAME
    resolution_mode_detection_analysis - Module pour analyser l'effet de la r�solution sur la d�tection des modes.

FUNCTIONS
    analyze_mode_detection_vs_resolution(data: numpy.ndarray, metadata: Dict[str, Any], bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], height_threshold: float = 0.1, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Analyse l'effet de la r�solution sur la d�tection des modes.

        Args:
            data: Donn�es de la distribution
            metadata: M�tadonn�es de la distribution
            bin_counts: Liste des nombres de bins � tester pour l'histogramme
            kde_points: Liste des nombres de points � tester pour la KDE
            height_threshold: Seuil relatif de hauteur pour la d�tection des pics
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: R�sultats de l'analyse

    create_bimodal_with_varying_separation(base_position: float = 50, separation_factors: List[float] = [0.5, 1.0, 2.0, 4.0], width: float = 10, num_samples: int = 1000, random_seed: Optional[int] = None) -> Dict[str, Tuple[numpy.ndarray, Dict[str, Any]]]
        Cr�e plusieurs distributions bimodales avec des s�parations variables entre les modes.

        Args:
            base_position: Position de base pour le premier mode
            separation_factors: Facteurs de s�paration entre les modes (en multiples de la largeur)
            width: Largeur des modes
            num_samples: Nombre d'�chantillons � g�n�rer pour chaque distribution
            random_seed: Graine pour le g�n�rateur de nombres al�atoires

        Returns:
            Dict[str, Tuple[np.ndarray, Dict[str, Any]]]: Dictionnaire de distributions et m�tadonn�es

    create_multimodal_distribution(mode_positions: List[float], mode_widths: List[float], mode_heights: Optional[List[float]] = None, num_samples: int = 1000, random_seed: Optional[int] = None) -> Tuple[numpy.ndarray, Dict[str, Any]]
        Cr�e une distribution multimodale avec des positions, largeurs et hauteurs sp�cifi�es.

        Args:
            mode_positions: Positions des modes
            mode_widths: Largeurs des modes (�carts-types pour les gaussiennes)
            mode_heights: Hauteurs relatives des modes (poids)
            num_samples: Nombre d'�chantillons � g�n�rer
            random_seed: Graine pour le g�n�rateur de nombres al�atoires

        Returns:
            Tuple[np.ndarray, Dict[str, Any]]: Donn�es g�n�r�es et m�tadonn�es

    create_multimodal_with_varying_heights(positions: List[float], width: float = 10, height_ratios: List[List[float]] = [[1, 1], [1, 2], [1, 5], [1, 10]], num_samples: int = 1000, random_seed: Optional[int] = None) -> Dict[str, Tuple[numpy.ndarray, Dict[str, Any]]]
        Cr�e plusieurs distributions multimodales avec des hauteurs relatives variables.

        Args:
            positions: Positions des modes
            width: Largeur des modes
            height_ratios: Liste de listes de ratios de hauteurs pour chaque distribution
            num_samples: Nombre d'�chantillons � g�n�rer pour chaque distribution
            random_seed: Graine pour le g�n�rateur de nombres al�atoires

        Returns:
            Dict[str, Tuple[np.ndarray, Dict[str, Any]]]: Dictionnaire de distributions et m�tadonn�es

    create_multimodal_with_varying_widths(positions: List[float], base_width: float = 10, width_factors: List[List[float]] = [[1, 1], [1, 2], [1, 5], [1, 0.5]], num_samples: int = 1000, random_seed: Optional[int] = None) -> Dict[str, Tuple[numpy.ndarray, Dict[str, Any]]]
        Cr�e plusieurs distributions multimodales avec des largeurs variables.

        Args:
            positions: Positions des modes
            base_width: Largeur de base des modes
            width_factors: Liste de listes de facteurs de largeur pour chaque distribution
            num_samples: Nombre d'�chantillons � g�n�rer pour chaque distribution
            random_seed: Graine pour le g�n�rateur de nombres al�atoires

        Returns:
            Dict[str, Tuple[np.ndarray, Dict[str, Any]]]: Dictionnaire de distributions et m�tadonn�es

    create_synthetic_distribution(distribution_type: str, mode_params: List[Dict[str, float]], num_samples: int = 1000, random_seed: Optional[int] = None) -> Tuple[numpy.ndarray, Dict[str, Any]]
        Cr�e une distribution synth�tique avec des modes connus.

        Args:
            distribution_type: Type de distribution ('gaussian', 'lognormal', 'gamma', 'mixture')
            mode_params: Liste de dictionnaires contenant les param�tres des modes
            num_samples: Nombre d'�chantillons � g�n�rer
            random_seed: Graine pour le g�n�rateur de nombres al�atoires

        Returns:
            Tuple[np.ndarray, Dict[str, Any]]: Donn�es g�n�r�es et m�tadonn�es

    detect_modes_from_histogram(hist_counts: numpy.ndarray, bin_edges: numpy.ndarray, height_threshold: float = 0.1, distance: Optional[int] = None, prominence: Optional[float] = None, width: Optional[int] = None) -> Dict[str, Any]
        D�tecte les modes dans un histogramme.

        Args:
            hist_counts: Comptages des bins de l'histogramme
            bin_edges: Limites des bins de l'histogramme
            height_threshold: Seuil relatif de hauteur pour la d�tection des pics (fraction du maximum)
            distance: Distance minimale entre les pics (en nombre de bins)
            prominence: Pro�minence minimale des pics
            width: Largeur minimale des pics

        Returns:
            Dict[str, Any]: Informations sur les modes d�tect�s

    detect_modes_from_kde(data: numpy.ndarray, num_points: int = 1000, height_threshold: float = 0.1, distance_factor: float = 0.05, prominence: Optional[float] = None, width: Optional[int] = None, bandwidth_method: str = 'scott') -> Dict[str, Any]
        D�tecte les modes dans une distribution en utilisant l'estimation par noyau de la densit� (KDE).

        Args:
            data: Donn�es de la distribution
            num_points: Nombre de points pour l'�valuation de la KDE
            height_threshold: Seuil relatif de hauteur pour la d�tection des pics (fraction du maximum)
            distance_factor: Facteur pour calculer la distance minimale entre les pics (fraction de la plage des donn�es)
            prominence: Pro�minence minimale des pics
            width: Largeur minimale des pics
            bandwidth_method: M�thode pour estimer la largeur de bande de la KDE

        Returns:
            Dict[str, Any]: Informations sur les modes d�tect�s

    plot_multiple_distributions(distributions: Dict[str, Tuple[numpy.ndarray, Dict[str, Any]]], num_bins: int = 50, title: str = 'Comparaison de distributions synth�tiques', save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise plusieurs distributions synth�tiques pour comparaison.

        Args:
            distributions: Dictionnaire de distributions et m�tadonn�es
            num_bins: Nombre de bins pour les histogrammes
            title: Titre du graphique
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_synthetic_distribution(data: numpy.ndarray, metadata: Dict[str, Any], num_bins: int = 50, title: Optional[str] = None, save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise une distribution synth�tique avec ses modes connus.

        Args:
            data: Donn�es de la distribution
            metadata: M�tadonn�es de la distribution
            num_bins: Nombre de bins pour l'histogramme
            title: Titre du graphique
            save_path: Chemin o� sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Tuple = typing.Tuple
        Deprecated alias to builtins.tuple.

        Tuple[X, Y] is the cross-product type of X and Y.

        Example: Tuple[T1, T2] is a tuple of two elements corresponding
        to type variables T1 and T2.  Tuple[int, float, str] is a tuple
        of an int, a float and a string.

        To specify a variable-length tuple of homogeneous type, use Tuple[T, ...].

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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\resolution_mode_detection_analysis.py


