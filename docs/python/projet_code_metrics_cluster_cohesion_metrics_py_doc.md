Help on module cluster_cohesion_metrics:

NAME
    cluster_cohesion_metrics - Module pour définir les métriques de cohésion des clusters et les seuils de qualité associés.

FUNCTIONS
    calculate_cluster_density_metrics(X: numpy.ndarray, labels: numpy.ndarray, k: int = 5) -> Dict[str, Any]
        Calcule les métriques de densité pour la cohésion des clusters.

        Args:
            X: Données d'entrée (n_samples, n_features)
            labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
            k: Nombre de voisins à considérer pour les métriques de densité locale

        Returns:
            Dict[str, Any]: Dictionnaire contenant les métriques de densité

    calculate_intra_cluster_variance(X: numpy.ndarray, labels: numpy.ndarray, centroids: Optional[numpy.ndarray] = None) -> Dict[str, Any]
        Calcule la variance intra-cluster pour chaque cluster.

        Args:
            X: Données d'entrée (n_samples, n_features)
            labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
            centroids: Coordonnées des centres de clusters (optionnel)

        Returns:
            Dict[str, Any]: Dictionnaire contenant les variances intra-cluster

    define_density_metrics_thresholds(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, float]]
        Définit les métriques de densité pour la cohésion des clusters en fonction
        de la dimensionnalité des données, du nombre de clusters et de la densité des données.

        Args:
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, float]]: Seuils pour les métriques de densité

    establish_cluster_cohesion_quality_thresholds(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, Dict[str, float]]]
        Établit les seuils de qualité pour la cohésion des clusters en fonction
        de la dimensionnalité des données, du nombre de clusters et de la densité des données.

        Args:
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, Dict[str, float]]]: Seuils de qualité pour la cohésion des clusters

    establish_intra_cluster_variance_criteria(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, float]]
        Établit les critères de variance intra-cluster maximale en fonction
        de la dimensionnalité des données, du nombre de clusters et de la densité des données.

        Args:
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, float]]: Critères de variance intra-cluster maximale

    evaluate_cluster_cohesion_quality(X: numpy.ndarray, labels: numpy.ndarray, centroids: Optional[numpy.ndarray] = None, thresholds: Optional[Dict[str, Dict[str, Dict[str, float]]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium', k: int = 5) -> Dict[str, Any]
        Évalue la qualité globale de la cohésion des clusters en combinant les métriques
        de variance intra-cluster et de densité.

        Args:
            X: Données d'entrée (n_samples, n_features)
            labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
            centroids: Coordonnées des centres de clusters (optionnel)
            thresholds: Seuils de qualité pour la cohésion des clusters (optionnel)
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")
            k: Nombre de voisins à considérer pour les métriques de densité locale

        Returns:
            Dict[str, Any]: Évaluation de la qualité de la cohésion des clusters

    evaluate_density_metrics_quality(density_metrics: Dict[str, Any], thresholds: Optional[Dict[str, Dict[str, float]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, str]
        Évalue la qualité de la cohésion des clusters basée sur les métriques de densité.

        Args:
            density_metrics: Métriques de densité des clusters
            thresholds: Seuils pour les métriques de densité (optionnel)
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, str]: Évaluation de la qualité

    evaluate_intra_cluster_variance_quality(variance_metrics: Dict[str, Any], criteria: Optional[Dict[str, Dict[str, float]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, str]
        Évalue la qualité de la cohésion des clusters basée sur la variance intra-cluster.

        Args:
            variance_metrics: Métriques de variance intra-cluster
            criteria: Critères de variance intra-cluster (optionnel)
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, str]: Évaluation de la qualité

DATA
    DEFAULT_EPSILON = 1e-10
    DEFAULT_MAX_INTRA_CLUSTER_VARIANCE = 1.0
    DEFAULT_MIN_DENSITY = 0.1
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\cluster_cohesion_metrics.py


