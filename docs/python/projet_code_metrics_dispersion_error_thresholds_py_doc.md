Help on module dispersion_error_thresholds:

NAME
    dispersion_error_thresholds - Module pour définir les seuils d'erreur acceptables pour les mesures de dispersion.

FUNCTIONS
    define_dispersion_error_thresholds_high_resolution_histogram(measure: str = 'range') -> Dict[str, float]
        Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
        dans le cas des histogrammes à haute résolution (nombre de bins >= 50).

        Args:
            measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion

    define_dispersion_error_thresholds_kde(measure: str = 'range', resolution: str = 'medium') -> Dict[str, float]
        Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
        dans le cas des KDEs à différentes résolutions.

        Args:
            measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')
            resolution: Résolution de la KDE ('low', 'medium', 'high')

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion

    define_dispersion_error_thresholds_low_resolution_histogram(measure: str = 'range') -> Dict[str, float]
        Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
        dans le cas des histogrammes à faible résolution (nombre de bins < 20).

        Args:
            measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion

    define_dispersion_error_thresholds_multimodal(measure: str = 'range') -> Dict[str, float]
        Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
        dans le cas des distributions multimodales.

        Args:
            measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion

    define_dispersion_error_thresholds_normal(measure: str = 'range') -> Dict[str, float]
        Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
        dans le cas des distributions normales.

        Args:
            measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion

    define_dispersion_error_thresholds_skewed(measure: str = 'range') -> Dict[str, float]
        Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
        dans le cas des distributions asymétriques.

        Args:
            measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

        Returns:
            Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion

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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\dispersion_error_thresholds.py


