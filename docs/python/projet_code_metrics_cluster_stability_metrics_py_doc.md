Help on module cluster_stability_metrics:

NAME
    cluster_stability_metrics - Module pour définir les métriques de stabilité des clusters.

FUNCTIONS
    calculate_centroid_shift(centroids1: numpy.ndarray, centroids2: numpy.ndarray) -> float
        Calcule le déplacement moyen entre deux ensembles de centroids.

        Args:
            centroids1: Premier ensemble de centroids
            centroids2: Deuxième ensemble de centroids

        Returns:
            float: Déplacement moyen des centroids

    calculate_cluster_correspondence(labels1: numpy.ndarray, labels2: numpy.ndarray) -> float
        Calcule la correspondance entre deux ensembles d'étiquettes de cluster.

        Args:
            labels1: Premier ensemble d'étiquettes
            labels2: Deuxième ensemble d'étiquettes

        Returns:
            float: Score de correspondance (0-1, où 1 = correspondance parfaite)

    calculate_cluster_reproducibility(X: numpy.ndarray, clustering_method: Callable, n_clusters: int, n_iterations: int = 20, subsample_size: float = 0.8, random_state: int = 42) -> Dict[str, Any]
        Calcule la reproductibilité des clusters en utilisant des sous-échantillonnages répétés.

        Args:
            X: Données d'entrée (n_samples, n_features)
            clustering_method: Méthode de clustering à utiliser (doit accepter n_clusters et random_state)
            n_clusters: Nombre de clusters
            n_iterations: Nombre d'itérations pour le sous-échantillonnage
            subsample_size: Taille du sous-échantillon (proportion des données)
            random_state: Graine aléatoire

        Returns:
            Dict[str, Any]: Métriques de reproductibilité des clusters

    calculate_label_consistency(labels1: numpy.ndarray, labels2: numpy.ndarray) -> float
        Calcule la cohérence des étiquettes entre deux ensembles d'étiquettes de cluster.

        Args:
            labels1: Premier ensemble d'étiquettes
            labels2: Deuxième ensemble d'étiquettes

        Returns:
            float: Score de cohérence (0-1, où 1 = cohérence parfaite)

    calculate_resolution_robustness(X: numpy.ndarray, labels: numpy.ndarray, n_clusters: int, resolutions: Optional[List[float]] = None, n_resamplings: int = 10) -> Dict[str, Any]
        Calcule la robustesse des clusters face aux variations de résolution.

        Args:
            X: Données d'entrée (n_samples, n_features)
            labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
            n_clusters: Nombre de clusters
            resolutions: Liste des facteurs de résolution à tester (par défaut: [0.5, 0.75, 1.0, 1.25, 1.5])
            n_resamplings: Nombre de ré-échantillonnages pour chaque résolution

        Returns:
            Dict[str, Any]: Métriques de robustesse face aux variations de résolution

    define_reproducibility_thresholds(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, float]]
        Définit les seuils pour les métriques de reproductibilité des clusters.

        Args:
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, float]]: Seuils pour les métriques de reproductibilité

    establish_cluster_stability_quality_thresholds(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, Dict[str, float]]]
        Établit les seuils de qualité pour la stabilité des clusters en combinant
        les critères de robustesse face aux variations de résolution et de reproductibilité.

        Args:
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, Dict[str, float]]]: Seuils de qualité pour la stabilité des clusters

    establish_resolution_robustness_criteria(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, float]]
        Établit les critères de robustesse face aux variations de résolution.

        Args:
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, float]]: Critères de robustesse face aux variations de résolution

    evaluate_cluster_stability_quality(X: numpy.ndarray, labels: numpy.ndarray, clustering_method: Callable, n_clusters: int, thresholds: Optional[Dict[str, Dict[str, Dict[str, float]]]] = None, data_dimensionality: int = 2, data_sparsity: str = 'medium', resolutions: Optional[List[float]] = None, n_resamplings: int = 10, n_iterations: int = 20, subsample_size: float = 0.8, random_state: int = 42) -> Dict[str, Any]
        Évalue la qualité globale de la stabilité des clusters en combinant
        les métriques de robustesse face aux variations de résolution et de reproductibilité.

        Args:
            X: Données d'entrée (n_samples, n_features)
            labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
            clustering_method: Méthode de clustering à utiliser (doit accepter n_clusters et random_state)
            n_clusters: Nombre de clusters
            thresholds: Seuils de qualité pour la stabilité des clusters (optionnel)
            data_dimensionality: Nombre de dimensions des données
            data_sparsity: Densité des données ("low", "medium", "high")
            resolutions: Liste des facteurs de résolution à tester (par défaut: [0.5, 0.75, 1.0, 1.25, 1.5])
            n_resamplings: Nombre de ré-échantillonnages pour chaque résolution
            n_iterations: Nombre d'itérations pour le sous-échantillonnage
            subsample_size: Taille du sous-échantillon (proportion des données)
            random_state: Graine aléatoire

        Returns:
            Dict[str, Any]: Évaluation de la qualité de la stabilité des clusters

    evaluate_reproducibility_quality(reproducibility_metrics: Dict[str, Any], thresholds: Optional[Dict[str, Dict[str, float]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, str]
        Évalue la qualité de la reproductibilité des clusters.

        Args:
            reproducibility_metrics: Métriques de reproductibilité des clusters
            thresholds: Seuils pour les métriques de reproductibilité (optionnel)
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, str]: Évaluation de la qualité

    evaluate_resolution_robustness_quality(robustness_metrics: Dict[str, Any], criteria: Optional[Dict[str, Dict[str, float]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, str]
        Évalue la qualité de la robustesse face aux variations de résolution.

        Args:
            robustness_metrics: Métriques de robustesse face aux variations de résolution
            criteria: Critères de robustesse (optionnel)
            data_dimensionality: Nombre de dimensions des données
            cluster_count: Nombre de clusters
            data_sparsity: Densité des données ("low", "medium", "high")

        Returns:
            Dict[str, str]: Évaluation de la qualité

DATA
    Callable = typing.Callable
        Deprecated alias to collections.abc.Callable.

        Callable[[int], str] signifies a function that takes a single
        parameter of type int and returns a str.

        The subscription syntax must always be used with exactly two
        values: the argument list and the return type.
        The argument list must be a list of types, a ParamSpec,
        Concatenate or ellipsis. The return type must be a single type.

        There is no syntax to indicate optional or keyword arguments;
        such function types are rarely used as callback types.

    DEFAULT_EPSILON = 1e-10
    DEFAULT_N_ITERATIONS = 20
    DEFAULT_N_RESAMPLINGS = 10
    DEFAULT_SUBSAMPLE_SIZE = 0.8
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\cluster_stability_metrics.py


