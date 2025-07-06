Help on module JsonSegmenter:

NAME
    JsonSegmenter - Module de segmentation JSON pour EMAIL_SENDER_1.

DESCRIPTION
    Ce module fournit des fonctionnalités avancées pour parser, segmenter,
    valider et analyser des données JSON, avec un support particulier pour
    les fichiers volumineux et les structures complexes.

    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0.0
    Date: 2025-06-06

CLASSES
    builtins.object
        JsonSegmenter

    class JsonSegmenter(builtins.object)
     |  JsonSegmenter(max_chunk_size_kb: int = 10, preserve_structure: bool = True)
     |
     |  Classe principale pour la segmentation et l'analyse de données JSON.
     |
     |  Cette classe fournit des méthodes pour charger, valider, analyser et
     |  segmenter des données JSON, avec un support particulier pour les
     |  fichiers volumineux et les structures complexes.
     |
     |  Methods defined here:
     |
     |  __init__(self, max_chunk_size_kb: int = 10, preserve_structure: bool = True)
     |      Initialise un nouveau segmenteur JSON.
     |
     |      Args:
     |          max_chunk_size_kb: Taille maximale des segments en KB
     |          preserve_structure: Si True, préserve la structure JSON dans les segments
     |
     |  analyze(self, data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
     |      Analyse les données JSON et retourne des informations détaillées.
     |
     |      Args:
     |          data: Données JSON à analyser (utilise les données actuelles si None)
     |
     |      Returns:
     |          Dictionnaire contenant les informations d'analyse
     |
     |  load_file(self, file_path: Union[str, pathlib.Path]) -> Dict[str, Any]
     |      Charge un fichier JSON.
     |
     |      Args:
     |          file_path: Chemin du fichier à charger
     |
     |      Returns:
     |          Données JSON chargées
     |
     |      Raises:
     |          FileNotFoundError: Si le fichier n'existe pas
     |          json.JSONDecodeError: Si le fichier n'est pas un JSON valide
     |
     |  load_string(self, json_string: str) -> Dict[str, Any]
     |      Charge une chaîne JSON.
     |
     |      Args:
     |          json_string: Chaîne JSON à charger
     |
     |      Returns:
     |          Données JSON chargées
     |
     |      Raises:
     |          json.JSONDecodeError: Si la chaîne n'est pas un JSON valide
     |
     |  segment(self, data: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]
     |      Segmente les données JSON en morceaux plus petits.
     |
     |      Args:
     |          data: Données JSON à segmenter (utilise les données actuelles si None)
     |
     |      Returns:
     |          Liste des segments JSON
     |
     |  segment_to_files(self, output_dir: Union[str, pathlib.Path], prefix: str = 'segment_') -> List[str]
     |      Segmente les données JSON actuelles et enregistre les segments dans des fichiers.
     |
     |      Args:
     |          output_dir: Répertoire de sortie
     |          prefix: Préfixe pour les noms de fichiers
     |
     |      Returns:
     |          Liste des chemins des fichiers créés
     |
     |  validate(self, schema: Optional[Dict[str, Any]] = None) -> Tuple[bool, List[str]]
     |      Valide les données JSON actuelles.
     |
     |      Args:
     |          schema: Schéma JSON pour la validation (optionnel)
     |
     |      Returns:
     |          Tuple (est_valide, erreurs)
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
    analyze_file(file_path: str, output_file: Optional[str] = None) -> Dict[str, Any]
        Analyse un fichier JSON et retourne des informations détaillées.

        Args:
            file_path: Chemin du fichier JSON
            output_file: Fichier de sortie pour l'analyse (optionnel)

        Returns:
            Dictionnaire contenant les informations d'analyse

    segment_file(file_path: str, output_dir: str, max_chunk_size_kb: int = 10, preserve_structure: bool = True) -> List[str]
        Segmente un fichier JSON et enregistre les segments dans des fichiers.

        Args:
            file_path: Chemin du fichier JSON
            output_dir: Répertoire de sortie
            max_chunk_size_kb: Taille maximale des segments en KB
            preserve_structure: Si True, préserve la structure JSON dans les segments

        Returns:
            Liste des chemins des fichiers créés

    validate_file(file_path: str, schema_file: Optional[str] = None) -> Tuple[bool, List[str]]
        Valide un fichier JSON.

        Args:
            file_path: Chemin du fichier JSON
            schema_file: Chemin du fichier de schéma JSON (optionnel)

        Returns:
            Tuple (est_valide, erreurs)

DATA
    Dict = typing.Dict
        A generic version of dict.

    Iterator = typing.Iterator
        A generic version of collections.abc.Iterator.

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

    logger = <Logger JsonSegmenter (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\modules\jsonsegmenter.py


