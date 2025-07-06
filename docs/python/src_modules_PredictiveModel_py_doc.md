Help on module PredictiveModel:

NAME
    PredictiveModel

DESCRIPTION
    Module de mod�les pr�dictifs pour l'analyse des performances
    Ce module fournit des fonctionnalit�s d'analyse pr�dictive des m�triques de performance
    Author: EMAIL_SENDER_1 Team
    Version: 1.0.0

CLASSES
    builtins.object
        PerformancePredictor

    class PerformancePredictor(builtins.object)
     |  PerformancePredictor(config: Dict = None)
     |
     |  Classe principale pour la pr�diction des performances
     |
     |  Methods defined here:
     |
     |  __init__(self, config: Dict = None)
     |      Initialise le pr�dicteur de performances
     |
     |      Args:
     |          config: Configuration personnalis�e (facultatif)
     |
     |  analyze_trends(self, data: List[Dict]) -> Dict[str, Any]
     |      Analyse les tendances dans les donn�es
     |
     |      Args:
     |          data: Liste de dictionnaires contenant les m�triques
     |
     |      Returns:
     |          Dictionnaire contenant l'analyse des tendances
     |
     |  detect_anomalies(self, data: List[Dict]) -> Dict[str, Any]
     |      D�tecte les anomalies dans les donn�es
     |
     |      Args:
     |          data: Liste de dictionnaires contenant les m�triques
     |
     |      Returns:
     |          Dictionnaire contenant les anomalies d�tect�es
     |
     |  predict(self, data: List[Dict], horizon: int = None) -> Dict[str, Any]
     |      Pr�dit les valeurs futures des m�triques
     |
     |      Args:
     |          data: Liste de dictionnaires contenant les m�triques historiques
     |          horizon: Nombre de points � pr�dire (utilise la valeur de configuration par d�faut si non sp�cifi�)
     |
     |      Returns:
     |          Dictionnaire contenant les pr�dictions
     |
     |  train(self, data: List[Dict], force: bool = False) -> Dict[str, Any]
     |      Entra�ne les mod�les pr�dictifs
     |
     |      Args:
     |          data: Liste de dictionnaires contenant les m�triques
     |          force: Force le r�entra�nement m�me si l'intervalle n'est pas atteint
     |
     |      Returns:
     |          Dictionnaire contenant les r�sultats de l'entra�nement
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
        Charge les m�triques � partir d'un fichier JSON

        Args:
            file_path: Chemin du fichier JSON

        Returns:
            Liste de dictionnaires contenant les m�triques

    save_predictions_to_json(predictions: Dict[str, Any], file_path: str) -> None
        Sauvegarde les pr�dictions dans un fichier JSON

        Args:
            predictions: Dictionnaire contenant les pr�dictions
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


