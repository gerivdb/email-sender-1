=== Test des métriques basées sur l'entropie ===

1. Test du calcul de l'entropie de Shannon
Entropie de Shannon: 1.8464 bits

2. Test de l'estimation de l'entropie différentielle
Distribution normal: 5.9637 bits
Distribution asymmetric: 6.0665 bits
Distribution leptokurtic: 6.5550 bits
Distribution multimodal: 6.8576 bits

3. Test du calcul de la divergence KL
Divergence KL: 0.0660 bits

4. Test du calcul de la divergence JS
Divergence JS: 0.0174 bits

5. Test du calcul de la perte d'information

Distribution normal:
  Stratégie uniform:
    Entropie originale: 5.9637 bits
    Entropie reconstruite: 5.9842 bits
    Ratio de préservation: 1.0034
    Ratio de perte: -0.0034
  Stratégie quantile:
    Entropie originale: 5.9637 bits
    Entropie reconstruite: 6.0960 bits
    Ratio de préservation: 1.0222
    Ratio de perte: -0.0222
  Stratégie logarithmic:
    Entropie originale: 5.9637 bits
    Entropie reconstruite: 5.9675 bits
    Ratio de préservation: 1.0006
    Ratio de perte: -0.0006

Distribution asymmetric:
  Stratégie uniform:
    Entropie originale: 6.0665 bits
    Entropie reconstruite: 6.0862 bits
    Ratio de préservation: 1.0033
    Ratio de perte: -0.0033
  Stratégie quantile:
    Entropie originale: 6.0665 bits
    Entropie reconstruite: 6.1460 bits
    Ratio de préservation: 1.0131
    Ratio de perte: -0.0131
  Stratégie logarithmic:
    Entropie originale: 6.0665 bits
    Entropie reconstruite: 6.0819 bits
    Ratio de préservation: 1.0025
    Ratio de perte: -0.0025

Distribution leptokurtic:
  Stratégie uniform:
    Entropie originale: 6.5550 bits
    Entropie reconstruite: 6.5992 bits
    Ratio de préservation: 1.0067
    Ratio de perte: -0.0067
  Stratégie quantile:
    Entropie originale: 6.5550 bits
    Entropie reconstruite: 6.7709 bits
    Ratio de préservation: 1.0329
    Ratio de perte: -0.0329
  Stratégie logarithmic:
    Entropie originale: 6.5550 bits
    Entropie reconstruite: 7.6611 bits
    Ratio de préservation: 1.1687
    Ratio de perte: -0.1687

Distribution multimodal:
  Stratégie uniform:
    Entropie originale: 6.8576 bits
    Entropie reconstruite: 6.8644 bits
    Ratio de préservation: 1.0010
    Ratio de perte: -0.0010
  Stratégie quantile:
    Entropie originale: 6.8576 bits
    Entropie reconstruite: 6.9186 bits
    Ratio de préservation: 1.0089
    Ratio de perte: -0.0089
  Stratégie logarithmic:
    Entropie originale: 6.8576 bits
    Entropie reconstruite: 6.8768 bits
    Ratio de préservation: 1.0028
    Ratio de perte: -0.0028

6. Test de la recherche du nombre optimal de bins

Distribution normal:
  Stratégie uniform: 5 bins (ratio: 1.0344)
  Stratégie quantile: 5 bins (ratio: 1.0845)
  Stratégie logarithmic: 5 bins (ratio: 1.0407)

Distribution asymmetric:
  Stratégie uniform: 5 bins (ratio: 1.0286)
  Stratégie quantile: 5 bins (ratio: 1.0554)
  Stratégie logarithmic: 5 bins (ratio: 1.0415)

Distribution leptokurtic:
  Stratégie uniform: 5 bins (ratio: 1.1044)
  Stratégie quantile: 5 bins (ratio: 1.1635)
  Stratégie logarithmic: 5 bins (ratio: 1.2052)

Distribution multimodal:
  Stratégie uniform: 5 bins (ratio: 1.0273)
  Stratégie quantile: 5 bins (ratio: 1.0328)
  Stratégie logarithmic: 5 bins (ratio: 1.0298)

Test terminé avec succès!
Help on module entropy_metrics_test:

NAME
    entropy_metrics_test - Test complet des métriques basées sur l'entropie.

FUNCTIONS
    calculate_information_loss(original_data, bin_edges, bin_counts, base=2.0)
        # Fonction pour calculer la perte d'information

    calculate_jensen_shannon_divergence(p, q, base=2.0)
        # Fonction pour calculer la divergence JS

    calculate_kl_divergence(p, q, base=2.0)
        # Fonction pour calculer la divergence KL

    calculate_shannon_entropy(probabilities, base=2.0)
        # Fonction pour calculer l'entropie de Shannon

    compare_binning_strategies(data, strategies=None, num_bins=20, base=2.0)
        # Fonction pour comparer différentes stratégies de binning

    estimate_differential_entropy(data, kde_bandwidth='scott', base=2.0, num_samples=1000)
        # Fonction pour estimer l'entropie différentielle

    find_optimal_bin_count(data, strategy='uniform', min_bins=5, max_bins=100, step=5, base=2.0)
        # Fonction pour trouver le nombre optimal de bins

    reconstruct_data_from_histogram(bin_edges, bin_counts, method='uniform')
        # Fonction pour reconstruire les données à partir d'un histogramme

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

    __warningregistry__ = {'version': 73}
    data = array([ 52.6973727 ,  83.33885746,  94.97415126,...157  , 116.1...
    dist_name = 'multimodal'
    distributions = {'asymmetric': array([ 56.66685669,  44.79498834,  27....
    entropy = np.float64(6.8575965374809815)
    js_div = np.float64(0.017425777279838614)
    kl_div = np.float64(0.0660149997115376)
    metrics = {'histogram_entropy': np.float64(3.909321395432848), 'inform...
    optimization = {'best_ratio': np.float64(1.0298350839889479), 'optimal...
    p = array([0.1, 0.4, 0.5])
    probabilities = array([0.1, 0.2, 0.3, 0.4])
    q = array([0.2, 0.3, 0.5])
    result = {'bin_counts': array([  1,   6,   7,  23,  37,  62,  78, 106,...
    results = {'logarithmic': {'bin_counts': array([  1,   6,   7,  23,  3...
    strategy = 'logarithmic'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\entropy_metrics_test.py


