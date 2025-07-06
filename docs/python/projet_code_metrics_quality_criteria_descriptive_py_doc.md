Help on module quality_criteria_descriptive:

NAME
    quality_criteria_descriptive

DESCRIPTION
    Module pour définir les critères de qualité pour l'analyse descriptive,
    notamment les critères de précision pour l'estimation des paramètres statistiques.

FUNCTIONS
    create_central_tendency_error_report(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur les seuils d'erreur acceptables pour les mesures de tendance centrale.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur les seuils d'erreur acceptables

    create_iqr_precision_report_heavy_tailed(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], criteria: Optional[Dict[str, Any]] = None, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur la précision de l'estimation de l'IQR
        pour les distributions à queue lourde.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'IQR

    create_iqr_precision_report_multimodal(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], criteria: Optional[Dict[str, Any]] = None, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur la précision de l'estimation de l'IQR
        pour les distributions multimodales.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'IQR

    create_iqr_precision_report_symmetric(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], criteria: Optional[Dict[str, Any]] = None, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur la précision de l'estimation de l'IQR
        pour les distributions symétriques.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'IQR

    create_mean_precision_report(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], criteria: Optional[Dict[str, Any]] = None, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur la précision de l'estimation de la moyenne.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de la moyenne (optionnel)
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la précision de l'estimation de la moyenne

    create_median_precision_report(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], criteria: Optional[Dict[str, Any]] = None, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur la précision de l'estimation de la médiane.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de la médiane (optionnel)
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la précision de l'estimation de la médiane

    create_std_precision_report_multimodal(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], criteria: Optional[Dict[str, Any]] = None, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur la précision de l'estimation de l'écart-type
        pour les distributions multimodales.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'écart-type

    create_std_precision_report_normal(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], criteria: Optional[Dict[str, Any]] = None, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur la précision de l'estimation de l'écart-type
        pour les distributions normales.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'écart-type

    create_std_precision_report_skewed(data: numpy.ndarray, bin_counts: List[int] = [10, 20, 50, 100, 200], kde_points: List[int] = [100, 200, 500, 1000, 2000], criteria: Optional[Dict[str, Any]] = None, save_path: Optional[str] = None, show_plot: bool = True) -> Dict[str, Any]
        Crée un rapport complet sur la précision de l'estimation de l'écart-type
        pour les distributions asymétriques.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

        Returns:
            Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'écart-type

    define_central_tendency_error_thresholds(distribution_type: str = 'general') -> Dict[str, Dict[str, float]]
        Définit les seuils d'erreur acceptables pour les mesures de tendance centrale
        en fonction du type de distribution.

        Args:
            distribution_type: Type de distribution ('general', 'normal', 'skewed', 'multimodal')

        Returns:
            Dict[str, Dict[str, float]]: Seuils d'erreur acceptables pour les mesures de tendance centrale

    define_iqr_error_thresholds_heavy_tailed(relative_error_threshold: float = 0.05) -> Dict[str, float]
        Établit les seuils d'erreur relative pour l'estimation de l'IQR
        dans le cas des distributions à queue lourde.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'IQR

    define_iqr_error_thresholds_multimodal(relative_error_threshold: float = 0.05) -> Dict[str, float]
        Établit les seuils d'erreur relative pour l'estimation de l'IQR
        dans le cas des distributions multimodales.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'IQR

    define_iqr_error_thresholds_symmetric(relative_error_threshold: float = 0.05) -> Dict[str, float]
        Établit les seuils d'erreur relative pour l'estimation de l'IQR
        dans le cas des distributions symétriques.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'IQR

    define_iqr_precision_criteria(relative_error_threshold: float = 0.05, confidence_level: float = 0.95) -> Dict[str, Any]
        Établit les critères de précision pour l'estimation de l'IQR.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 5%)
            confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)

        Returns:
            Dict[str, Any]: Critères de précision pour l'estimation de l'IQR

    define_mean_precision_criteria(relative_error_threshold: float = 0.05, confidence_level: float = 0.95) -> Dict[str, Any]
        Établit les critères de précision pour l'estimation de la moyenne.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 5%)
            confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)

        Returns:
            Dict[str, Any]: Critères de précision pour l'estimation de la moyenne

    define_median_precision_criteria(relative_error_threshold: float = 0.05, confidence_level: float = 0.95) -> Dict[str, Any]
        Établit les critères de précision pour l'estimation de la médiane.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 5%)
            confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)

        Returns:
            Dict[str, Any]: Critères de précision pour l'estimation de la médiane

    define_std_error_thresholds_multimodal(relative_error_threshold: float = 0.05) -> Dict[str, float]
        Établit les seuils d'erreur relative pour l'estimation de l'écart-type
        dans le cas des distributions multimodales.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'écart-type

    define_std_error_thresholds_normal(relative_error_threshold: float = 0.05) -> Dict[str, float]
        Établit les seuils d'erreur relative pour l'estimation de l'écart-type
        dans le cas des distributions normales.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'écart-type

    define_std_error_thresholds_skewed(relative_error_threshold: float = 0.05) -> Dict[str, float]
        Établit les seuils d'erreur relative pour l'estimation de l'écart-type
        dans le cas des distributions asymétriques.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour l'écart-type

    define_std_precision_criteria(relative_error_threshold: float = 0.05, confidence_level: float = 0.95) -> Dict[str, Any]
        Établit les critères de précision pour l'estimation de l'écart-type.

        Args:
            relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 5%)
            confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)

        Returns:
            Dict[str, Any]: Critères de précision pour l'estimation de l'écart-type

    determine_distribution_type(data: numpy.ndarray) -> str
        Détermine le type de distribution des données.

        Args:
            data: Données brutes

        Returns:
            str: Type de distribution ('normal', 'skewed', 'multimodal', 'general')

    determine_optimal_resolution_for_iqr(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], quality_threshold: str = 'good') -> Dict[str, Any]
        Détermine la résolution optimale pour l'estimation de l'IQR.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            quality_threshold: Seuil de qualité minimal ('excellent', 'good', 'acceptable', 'poor')

        Returns:
            Dict[str, Any]: Résolutions optimales pour l'estimation de l'IQR

    determine_optimal_resolution_for_mean(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], quality_threshold: str = 'good') -> Dict[str, Any]
        Détermine la résolution optimale pour l'estimation de la moyenne.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            quality_threshold: Seuil de qualité minimal ('excellent', 'good', 'acceptable', 'poor')

        Returns:
            Dict[str, Any]: Résolutions optimales pour l'estimation de la moyenne

    determine_optimal_resolution_for_median(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], quality_threshold: str = 'good') -> Dict[str, Any]
        Détermine la résolution optimale pour l'estimation de la médiane.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            quality_threshold: Seuil de qualité minimal ('excellent', 'good', 'acceptable', 'poor')

        Returns:
            Dict[str, Any]: Résolutions optimales pour l'estimation de la médiane

    determine_optimal_resolution_for_std(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], quality_threshold: str = 'good') -> Dict[str, Any]
        Détermine la résolution optimale pour l'estimation de l'écart-type.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            quality_threshold: Seuil de qualité minimal ('excellent', 'good', 'acceptable', 'poor')

        Returns:
            Dict[str, Any]: Résolutions optimales pour l'estimation de l'écart-type

    evaluate_histogram_iqr_precision(data: numpy.ndarray, bin_counts: List[int], criteria: Optional[Dict[str, Any]] = None, distribution_type: str = 'symmetric') -> Dict[str, Any]
        Évalue la précision de l'estimation de l'IQR à partir d'histogrammes
        avec différents nombres de bins.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
            distribution_type: Type de distribution ('symmetric', 'heavy_tailed', 'multimodal', 'general')

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de bins

    evaluate_histogram_mean_precision(data: numpy.ndarray, bin_counts: List[int], criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
        Évalue la précision de l'estimation de la moyenne à partir d'histogrammes
        avec différents nombres de bins.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            criteria: Critères de précision pour l'estimation de la moyenne (optionnel)

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de bins

    evaluate_histogram_median_precision(data: numpy.ndarray, bin_counts: List[int], criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
        Évalue la précision de l'estimation de la médiane à partir d'histogrammes
        avec différents nombres de bins.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            criteria: Critères de précision pour l'estimation de la médiane (optionnel)

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de bins

    evaluate_histogram_std_precision(data: numpy.ndarray, bin_counts: List[int], criteria: Optional[Dict[str, Any]] = None, distribution_type: str = 'normal') -> Dict[str, Any]
        Évalue la précision de l'estimation de l'écart-type à partir d'histogrammes
        avec différents nombres de bins.

        Args:
            data: Données brutes
            bin_counts: Liste des nombres de bins à tester
            criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
            distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'general')

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de bins

    evaluate_iqr_precision(true_iqr: float, estimated_iqr: float, sample_size: int, criteria: Dict[str, Any]) -> Dict[str, Any]
        Évalue la précision de l'estimation de l'IQR selon les critères définis.

        Args:
            true_iqr: Valeur réelle de l'IQR
            estimated_iqr: Valeur estimée de l'IQR
            sample_size: Taille de l'échantillon
            criteria: Critères de précision pour l'estimation de l'IQR

        Returns:
            Dict[str, Any]: Évaluation de la précision de l'estimation

    evaluate_kde_iqr_precision(data: numpy.ndarray, kde_points: List[int], criteria: Optional[Dict[str, Any]] = None, distribution_type: str = 'symmetric') -> Dict[str, Any]
        Évalue la précision de l'estimation de l'IQR à partir de KDEs
        avec différents nombres de points.

        Args:
            data: Données brutes
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
            distribution_type: Type de distribution ('symmetric', 'heavy_tailed', 'multimodal', 'general')

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de points

    evaluate_kde_mean_precision(data: numpy.ndarray, kde_points: List[int], criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
        Évalue la précision de l'estimation de la moyenne à partir de KDEs
        avec différents nombres de points.

        Args:
            data: Données brutes
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de la moyenne (optionnel)

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de points

    evaluate_kde_median_precision(data: numpy.ndarray, kde_points: List[int], criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
        Évalue la précision de l'estimation de la médiane à partir de KDEs
        avec différents nombres de points.

        Args:
            data: Données brutes
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de la médiane (optionnel)

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de points

    evaluate_kde_std_precision(data: numpy.ndarray, kde_points: List[int], criteria: Optional[Dict[str, Any]] = None, distribution_type: str = 'normal') -> Dict[str, Any]
        Évalue la précision de l'estimation de l'écart-type à partir de KDEs
        avec différents nombres de points.

        Args:
            data: Données brutes
            kde_points: Liste des nombres de points à tester
            criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
            distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'general')

        Returns:
            Dict[str, Any]: Évaluation de la précision pour différents nombres de points

    evaluate_mean_precision(true_mean: float, estimated_mean: float, sample_size: int, std_dev: float, criteria: Dict[str, Any]) -> Dict[str, Any]
        Évalue la précision de l'estimation de la moyenne selon les critères définis.

        Args:
            true_mean: Valeur réelle de la moyenne
            estimated_mean: Valeur estimée de la moyenne
            sample_size: Taille de l'échantillon
            std_dev: Écart-type de l'échantillon
            criteria: Critères de précision pour l'estimation de la moyenne

        Returns:
            Dict[str, Any]: Évaluation de la précision de l'estimation

    evaluate_median_precision(true_median: float, estimated_median: float, sample_size: int, iqr: float, criteria: Dict[str, Any]) -> Dict[str, Any]
        Évalue la précision de l'estimation de la médiane selon les critères définis.

        Args:
            true_median: Valeur réelle de la médiane
            estimated_median: Valeur estimée de la médiane
            sample_size: Taille de l'échantillon
            iqr: Écart interquartile de l'échantillon
            criteria: Critères de précision pour l'estimation de la médiane

        Returns:
            Dict[str, Any]: Évaluation de la précision de l'estimation

    evaluate_std_precision(true_std: float, estimated_std: float, sample_size: int, criteria: Dict[str, Any]) -> Dict[str, Any]
        Évalue la précision de l'estimation de l'écart-type selon les critères définis.

        Args:
            true_std: Valeur réelle de l'écart-type
            estimated_std: Valeur estimée de l'écart-type
            sample_size: Taille de l'échantillon
            criteria: Critères de précision pour l'estimation de l'écart-type

        Returns:
            Dict[str, Any]: Évaluation de la précision de l'estimation

    get_recommended_error_thresholds(data: numpy.ndarray) -> Dict[str, Dict[str, float]]
        Obtient les seuils d'erreur recommandés pour les mesures de tendance centrale
        en fonction du type de distribution des données.

        Args:
            data: Données brutes

        Returns:
            Dict[str, Dict[str, float]]: Seuils d'erreur recommandés

    plot_iqr_precision_evaluation(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], title: str = "Évaluation de la précision de l'estimation de l'IQR", save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'évaluation de la précision de l'estimation de l'IQR.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            title: Titre du graphique
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_mean_precision_evaluation(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], title: str = "Évaluation de la précision de l'estimation de la moyenne", save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'évaluation de la précision de l'estimation de la moyenne.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            title: Titre du graphique
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_median_precision_evaluation(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], title: str = "Évaluation de la précision de l'estimation de la médiane", save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'évaluation de la précision de l'estimation de la médiane.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            title: Titre du graphique
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    plot_std_precision_evaluation(histogram_results: Dict[str, Any], kde_results: Dict[str, Any], title: str = "Évaluation de la précision de l'estimation de l'écart-type", save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise l'évaluation de la précision de l'estimation de l'écart-type.

        Args:
            histogram_results: Résultats de l'évaluation pour les histogrammes
            kde_results: Résultats de l'évaluation pour les KDEs
            title: Titre du graphique
            save_path: Chemin où sauvegarder la figure (optionnel)
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\quality_criteria_descriptive.py


