Help on module shape_error_thresholds:

NAME
    shape_error_thresholds - Module pour définir les seuils d'erreur acceptables pour les mesures de forme.

FUNCTIONS
    define_shape_error_thresholds(measure: str = 'skewness', distribution_type: str = 'normal', sample_size: int = 100) -> Dict[str, float]
        Définit les seuils d'erreur relative acceptables pour les mesures de forme
        en fonction du type de distribution et de la taille de l'échantillon.

        Args:
            measure: Mesure de forme ('skewness', 'kurtosis')
            distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'heavy_tailed', 'general')
            sample_size: Taille de l'échantillon

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour la mesure de forme

    define_shape_error_thresholds_for_histogram(measure: str = 'skewness', distribution_type: str = 'normal', bin_count: int = 50) -> Dict[str, float]
        Définit les seuils d'erreur relative acceptables pour les mesures de forme
        estimées à partir d'histogrammes, en fonction du type de distribution et du nombre de bins.

        Args:
            measure: Mesure de forme ('skewness', 'kurtosis')
            distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'heavy_tailed', 'general')
            bin_count: Nombre de bins de l'histogramme

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour la mesure de forme

DATA
    Dict = typing.Dict
        A generic version of dict.

    DistributionType = typing.Literal['normal', 'skewed', 'multimodal', 'h...
    Literal = typing.Literal
        Special typing form to define literal types (a.k.a. value types).

        This form can be used to indicate to type checkers that the corresponding
        variable or function parameter has a value equivalent to the provided
        literal (or one of several literals)::

            def validate_simple(data: Any) -> Literal[True]:  # always returns True
                ...

            MODE = Literal['r', 'rb', 'w', 'wb']
            def open_helper(file: str, mode: MODE) -> str:
                ...

            open_helper('/some/path', 'r')  # Passes type check
            open_helper('/other/path', 'typo')  # Error in type checker

        Literal[...] cannot be subclassed. At runtime, an arbitrary value
        is allowed as type argument to Literal[...], but type checkers may
        impose restrictions.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\shape_error_thresholds.py


