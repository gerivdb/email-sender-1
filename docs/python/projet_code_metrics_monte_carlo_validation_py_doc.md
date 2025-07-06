Help on module monte_carlo_validation:

NAME
    monte_carlo_validation - Module pour la validation empirique des relations théoriques par simulation Monte Carlo.

FUNCTIONS
    generate_synthetic_distribution(dist_type: str, params: Dict[str, Any], n_samples: int = 10000) -> Tuple[numpy.ndarray, Dict[str, Any]]
        Génère une distribution synthétique avec des paramètres connus.

        Args:
            dist_type: Type de distribution ('gaussian', 'bimodal', 'multimodal')
            params: Paramètres de la distribution
            n_samples: Nombre d'échantillons à générer

        Returns:
            Tuple[np.ndarray, Dict[str, Any]]: Données générées et paramètres théoriques

    plot_monte_carlo_validation_results(results: Dict[str, Any], save_path: Optional[str] = None, show_plot: bool = True) -> None
        Visualise les résultats de la validation Monte Carlo.

        Args:
            results: Résultats de la validation Monte Carlo
            save_path: Chemin où sauvegarder la figure (optionnel)
            show_plot: Si True, affiche la figure

    validate_bin_width_resolution_relationship_monte_carlo(dist_type: str = 'gaussian', dist_params: Optional[Dict[str, Any]] = None, bin_width_factors: Optional[numpy.ndarray] = None, n_simulations: int = 100, n_samples: int = 10000) -> Dict[str, Any]
        Valide empiriquement la relation entre largeur des bins et résolution par simulation Monte Carlo.

        Args:
            dist_type: Type de distribution ('gaussian', 'bimodal', 'multimodal')
            dist_params: Paramètres de la distribution
            bin_width_factors: Facteurs de largeur de bin par rapport à sigma
            n_simulations: Nombre de simulations Monte Carlo
            n_samples: Nombre d'échantillons par simulation

        Returns:
            Dict[str, Any]: Résultats de la validation

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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\monte_carlo_validation.py


