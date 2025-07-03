Help on module cluster_cohesion_metrics:

NAME
    cluster_cohesion_metrics - Module pour d�finir les m�triques de coh�sion des clusters et les seuils de qualit� associ�s.

FUNCTIONS
    calculate_cluster_density_metrics(X: numpy.ndarray, labels: numpy.ndarray, k: int = 5) -> Dict[str, Any]
        Calcule les m�triques de densit� pour la coh�sion des clusters.

        Args:
            X: Donn�es d'entr�e (n_samples, n_features)
            labels: �tiquettes de cluster pour chaque �chantillon (n_samples,)
            k: Nombre de voisins � consid�rer pour les m�triques de densit� locale

        Returns:
            Dict[str, Any]: Dictionnaire contenant les m�triques de densit�

    calculate_intra_cluster_variance(X: numpy.ndarray, labels: numpy.ndarray, centroids: Optional[numpy.ndarray] = None) -> Dict[str, Any]
        Calcule la variance intra-cluster pour chaque cluster.

        Args:
            X: Donn�es d'entr�e (n_samples, n_features)
            labels: �tiquettes de cluster pour chaque �chantillon (n_samples,)
            centroids: Coordonn�es des centres de clusters (optionnel)

        Returns:
            Dict[str, Any]: Dictionnaire contenant les variances intra-cluster

    define_density_metrics_thresholds(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, float]]
        D�finit les m�triques de densit� pour la coh�sion des clusters en fonction
        de la dimensionnalit� des donn�es, du nombre de clusters et de la densit� des donn�es.

        Args:
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, float]]: Seuils pour les m�triques de densit�

    establish_cluster_cohesion_quality_thresholds(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, Dict[str, float]]]
        �tablit les seuils de qualit� pour la coh�sion des clusters en fonction
        de la dimensionnalit� des donn�es, du nombre de clusters et de la densit� des donn�es.

        Args:
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, Dict[str, float]]]: Seuils de qualit� pour la coh�sion des clusters

    establish_intra_cluster_variance_criteria(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, float]]
        �tablit les crit�res de variance intra-cluster maximale en fonction
        de la dimensionnalit� des donn�es, du nombre de clusters et de la densit� des donn�es.

        Args:
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, float]]: Crit�res de variance intra-cluster maximale

    evaluate_cluster_cohesion_quality(X: numpy.ndarray, labels: numpy.ndarray, centroids: Optional[numpy.ndarray] = None, thresholds: Optional[Dict[str, Dict[str, Dict[str, float]]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium', k: int = 5) -> Dict[str, Any]
        �value la qualit� globale de la coh�sion des clusters en combinant les m�triques
        de variance intra-cluster et de densit�.

        Args:
            X: Donn�es d'entr�e (n_samples, n_features)
            labels: �tiquettes de cluster pour chaque �chantillon (n_samples,)
            centroids: Coordonn�es des centres de clusters (optionnel)
            thresholds: Seuils de qualit� pour la coh�sion des clusters (optionnel)
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")
            k: Nombre de voisins � consid�rer pour les m�triques de densit� locale

        Returns:
            Dict[str, Any]: �valuation de la qualit� de la coh�sion des clusters

    evaluate_density_metrics_quality(density_metrics: Dict[str, Any], thresholds: Optional[Dict[str, Dict[str, float]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, str]
        �value la qualit� de la coh�sion des clusters bas�e sur les m�triques de densit�.

        Args:
            density_metrics: M�triques de densit� des clusters
            thresholds: Seuils pour les m�triques de densit� (optionnel)
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, str]: �valuation de la qualit�

    evaluate_intra_cluster_variance_quality(variance_metrics: Dict[str, Any], criteria: Optional[Dict[str, Dict[str, float]]] = None, data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, str]
        �value la qualit� de la coh�sion des clusters bas�e sur la variance intra-cluster.

        Args:
            variance_metrics: M�triques de variance intra-cluster
            criteria: Crit�res de variance intra-cluster (optionnel)
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, str]: �valuation de la qualit�

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


