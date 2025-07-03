Help on module cluster_separation_metrics:

NAME
    cluster_separation_metrics - Module pour d�finir les m�triques de s�paration des clusters et les seuils de qualit� associ�s.

FUNCTIONS
    calculate_inter_cluster_distance(centroids: numpy.ndarray) -> Dict[str, Any]
        Calcule les distances entre les centres des clusters.

        Args:
            centroids: Tableau des coordonn�es des centres de clusters (n_clusters, n_features)

        Returns:
            Dict[str, Any]: Dictionnaire contenant les distances inter-clusters

    calculate_silhouette_metrics(X: numpy.ndarray, labels: numpy.ndarray) -> Dict[str, Any]
        Calcule les m�triques de silhouette pour �valuer la qualit� des clusters.

        Args:
            X: Donn�es d'entr�e (n_samples, n_features)
            labels: �tiquettes de cluster pour chaque �chantillon (n_samples,)

        Returns:
            Dict[str, Any]: Dictionnaire contenant les m�triques de silhouette

    define_cluster_separation_thresholds(data_dimensionality: int = 2, cluster_count: int = 5, data_sparsity: str = 'medium') -> Dict[str, Dict[str, float]]
        D�finit les seuils de qualit� pour la s�paration des clusters en fonction
        de la dimensionnalit� des donn�es, du nombre de clusters et de la densit� des donn�es.

        Args:
            data_dimensionality: Nombre de dimensions des donn�es
            cluster_count: Nombre de clusters
            data_sparsity: Densit� des donn�es ("low", "medium", "high")

        Returns:
            Dict[str, Dict[str, float]]: Seuils pour diff�rentes m�triques

    evaluate_cluster_quality(X: numpy.ndarray, labels: numpy.ndarray, centroids: Optional[numpy.ndarray] = None) -> Dict[str, Any]
        �value la qualit� globale du clustering en combinant plusieurs m�triques.

        Args:
            X: Donn�es d'entr�e (n_samples, n_features)
            labels: �tiquettes de cluster pour chaque �chantillon (n_samples,)
            centroids: Coordonn�es des centres de clusters (optionnel)

        Returns:
            Dict[str, Any]: R�sultats de l'�valuation

    evaluate_inter_cluster_distance_quality(min_distance: float, threshold: float = 0.1) -> str
        �value la qualit� de la s�paration des clusters bas�e sur la distance minimale inter-clusters.

        Args:
            min_distance: Distance minimale entre deux clusters
            threshold: Seuil minimal de distance acceptable

        Returns:
            str: Niveau de qualit� ("Excellente", "Tr�s bonne", "Bonne", "Acceptable", "Limit�e", "Insuffisante")

    evaluate_silhouette_quality(silhouette_score: float) -> str
        �value la qualit� du clustering bas�e sur le score de silhouette.

        Args:
            silhouette_score: Score de silhouette (-1 � 1)

        Returns:
            str: Niveau de qualit�

DATA
    DEFAULT_EPSILON = 1e-10
    DEFAULT_MIN_INTER_CLUSTER_DISTANCE = 0.1
    DEFAULT_MIN_SILHOUETTE_SCORE = 0.5
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\cluster_separation_metrics.py


