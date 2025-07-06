Help on module PredictiveModel:

NAME
    PredictiveModel

DESCRIPTION
    Module de modèles prédictifs pour l'analyse des performances
    Ce module fournit des fonctionnalités d'analyse prédictive des métriques de performance
    Author: EMAIL_SENDER_1 Team
    Version: 1.0.0

CLASSES
    builtins.object
        PerformancePredictor

    class PerformancePredictor(builtins.object)
     |  PerformancePredictor(config: Dict = None)
     |
     |  Classe principale pour la prédiction des performances
     |
     |  Methods defined here:
     |
     |  __init__(self, config: Dict = None)
     |      Initialise le prédicteur de performances
     |
     |      Args:
     |          config: Configuration personnalisée (facultatif)
     |
     |  analyze_trends(self, data: List[Dict]) -> Dict[str, Any]
     |      Analyse les tendances dans les données
     |
     |      Args:
     |          data: Liste de dictionnaires contenant les métriques
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse des tendances
     |
     |  detect_anomalies(self, data: List[Dict]) -> Dict[str, Any]
     |      Détecte les anomalies dans les données
     |
     |      Args:
     |          data: Liste de dictionnaires contenant les métriques
     |
     |      Returns:
     |          Dictionnaire contenant les anomalies détectées
     |
     |  predict(self, data: List[Dict], horizon: int = None) -> Dict[str, Any]
     |      Prédit les valeurs futures des métriques
     |
     |      Args:
     |          data: Liste de dictionnaires contenant les métriques historiques
     |          horizon: Nombre de points à prédire (utilise la valeur de configuration par défaut si non spécifié)
     |
     |      Returns:
     |          Dictionnaire contenant les prédictions
     |
     |  train(self, data: List[Dict], force: bool = False) -> Dict[str, Any]
     |      Entraîne les modèles prédictifs
     |
     |      Args:
     |          data: Liste de dictionnaires contenant les métriques
     |          force: Force le réentraînement même si l'intervalle n'est pas atteint
     |
     |      Returns:
     |          Dictionnaire contenant les résultats de l'entraînement
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FUNCTIONS
    load_metrics_from_json(file_path: str) -> List[Dict]
        Charge les métriques à partir d'un fichier JSON

        Args:
            file_path: Chemin du fichier JSON

        Returns:
            Liste de dictionnaires contenant les métriques

    save_predictions_to_json(predictions: Dict[str, Any], file_path: str) -> None
        Sauvegarde les prédictions dans un fichier JSON

        Args:
            predictions: Dictionnaire contenant les prédictions
            file_path: Chemin du fichier JSON de sortie

DATA
    DEFAULT_CONFIG = {'anomaly_sensitivity': 0.05, 'forecast_horizon': 12,...
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\modules\predictivemodel.py


