Help on module cluster_stability_metrics:

NAME
    cluster_stability_metrics - Module pour d�finir les m�triques de stabilit� des clusters.

FUNCTIONS
    calculate_centroid_shift(centroids1: numpy.ndarray, centroids2: numpy.ndarray) -> float
        Calcule le d�placement moyen entre deux ensembles de centroids.

        Args:
            centroids1: Premier ensemble de centroids
            centroids2: Deuxi�me ensemble de centroids

        Returns:
            float: D�placement moyen des centroids

    calculate_cluster_correspondence(labels1: numpy.ndarray, labels2: numpy.ndarray) -> float
        Calcule la correspondance entre deux ensembles d'�tiquettes de cluster.

        Args:
            labels1: Premier ensemble d'�tiquettes
            labels2: Deuxi�me ensemble d'�tiquettes

        Returns:
            float: Score de correspondance (0-1, o� 1 = correspondance parfaite)

    calculate_cluster_reproducibility(X: numpy.ndarray, clustering_method: Callable, n_clusters: int, n_iterations: int = 20, subsample_size: float = 0.8, random_state: int = 42) -> Dict[str, Any]
        Calcule la reproductibilit� des clusters en utilisant des sous-�chantillonnages r�p�t�s.

        Args:
            X: Donn�es d'entr�e (n_samples, n_features)
            clustering_method: M�thode de clustering � utiliser (doit accepter n_clusters et random_state)
            n_clusters: Nombre de clusters
            n_iterations: Nombre d'it�rations pour le sous-�chantillonnage
            subsample_size: Taille du sous-�chantillon (proportion des donn�es)
            random_state: Graine al�atoire

        Returns:
            Dict[str, Any]: M�triques de reproductibilit� des clusters

    calculate_label_consistency(labels1: numpy.ndarray, labels2: numpy.ndarray) -> float
        Calcule la coh�rence des �tiquettes entre deux ensembles d'�tiquettes de cluster.

        Args:
            labels1: Premier ensemble d'�tiquettes
            labels2: Deuxi�me ensemble d'�tiquettes

        Returns:
            float: Score de coh�rence (0-1, o� 1 = coh�rence parfaite)

    calculate_resolution_robustness(X: numpy.ndarray, labels: numpy.ndarray, n_clusters: int, resolutions: Optional[List[float]] = None, n_resamplings: int = 10) -> Dict[str, Any]
        Calcule la robustesse des clusters face aux variations de r�solution.

        Args:
            X: Donn�es d'entr�e (n_samples, n_features)
            labels: �tiquettes de cluster pour chaque �chantillon (n_samples,)
            n_clusters: Nombre de clusters
            resolutions: Liste des facteurs de r�solution � tester (par d�faut: [0.5, 0.75, 1.0, 1.25, 1.5])
            n_resamplings: Nombre de r�-�chantillonnages pour chaque r�solution

        Returns:
            Dict[str, Any]: M�triques de robustesse face aux variations de r�solution

    define_reproducibility_thresholds(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, float]]
        D�finit les seuils pour les m�triques de reproductibilit� des clusters.

        Args:
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, float]]: Seuils pour les m�triques de reproductibilit�

    establish_cluster_stability_quality_thresholds(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, Dict[str, float]]]
        �tablit les seuils de qualit� pour la stabilit� des clusters en combinant
        les crit�res de robustesse face aux variations de r�solution et de reproductibilit�.

        Args:
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, Dict[str, float]]]: Seuils de qualit� pour la stabilit� des clusters

    establish_resolution_robustness_criteria(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, float]]
        �tablit les crit�res de robustesse face aux variations de r�solution.

        Args:
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, float]]: Crit�res de robustesse face aux variations de r�solution

    evaluate_cluster_stability_quality(X: numpy.ndarray, labels: numpy.ndarray, clustering_method: Callable, n_clusters: int, thresholds: Optional[Dict[str, Dict[str, Dict[str, float]]]] = None, data_dimensionality: int = 2, data_sparsity: str = 'medium', resolutions: Optional[List[float]] = None, n_resamplings: int = 10, n_iterations: int = 20, subsample_size: float = 0.8, random_state: int = 42) -> Dict[str, Any]
        �value la qualit� globale de la stabilit� des clusters en combinant
        les m�triques de robustesse face aux variations de r�solution et de reproductibilit�.

        Args:
            X: Donn�es d'entr�e (n_samples, n_features)
            labels: �tiquettes de cluster pour chaque �chantillon (n_samples,)
            clustering_method: M�thode de clustering � utiliser (doit accepter n_clusters et random_state)
            n_clusters: Nombre de clusters
            thresholds: Seuils de qualit� pour la stabilit� des clusters (optionnel)
            data_dimensionality: Nombre de dimensions des donn�es
            data_sparsity: Densit� des donn�es ("low", "medium", "high")
            resolutions: Liste des facteurs de r�solution � tester (par d�faut: [0.5, 0.75, 1.0, 1.25, 1.5])
            n_resamplings: Nombre de r�-�chantillonnages pour chaque r�solution
            n_iterations: Nombre d'it�rations pour le sous-�chantillonnage
            subsample_size: Taille du sous-�chantillon (proportion des donn�es)
            random_state: Graine al�atoire

        Returns:
            Dict[str, Any]: �valuation de la qualit� de la stabilit� des clusters

    evaluate_reproducibility_quality(reproducibility_metrics: Dict[str, Any], thresholds: Optional[Dict[str, Dict[str, float]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, str]
        �value la qualit� de la reproductibilit� des clusters.

        Args:
            reproducibility_metrics: M�triques de reproductibilit� des clusters
            thresholds: Seuils pour les m�triques de reproductibilit� (optionnel)
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, str]: �valuation de la qualit�

    evaluate_resolution_robustness_quality(robustness_metrics: Dict[str, Any], criteria: Optional[Dict[str, Dict[str, float]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, str]
        �value la qualit� de la robustesse face aux variations de r�solution.

        Args:
            robustness_metrics: M�triques de robustesse face aux variations de r�solution
            criteria: Crit�res de robustesse (optionnel)
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, str]: �valuation de la qualit�

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


