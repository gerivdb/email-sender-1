Help on module CsvSegmenter:

NAME
    CsvSegmenter - Module de segmentation CSV pour EMAIL_SENDER_1.

DESCRIPTION
    Ce module fournit des fonctionnalit�s avanc�es pour parser, segmenter,
    valider et analyser des donn�es CSV, avec un support particulier pour
    les fichiers volumineux et les structures complexes.

    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0.0
    Date: 2025-06-06

CLASSES
    builtins.object
        CsvSegmenter

    class CsvSegmenter(builtins.object)
     |  CsvSegmenter(max_chunk_size_kb: int = 10, preserve_header: bool = True, delimiter: str = ',', quotechar: str = '"', encoding: str = 'utf-8')
     |
     |  Classe principale pour la segmentation et l'analyse de donn�es CSV.
     |
     |  Cette classe fournit des m�thodes pour charger, valider, analyser et
     |  segmenter des donn�es CSV, avec un support particulier pour les
     |  fichiers volumineux et les structures complexes.
     |
     |  Methods defined here:
     |
     |  __init__(self, max_chunk_size_kb: int = 10, preserve_header: bool = True, delimiter: str = ',', quotechar: str = '"', encoding: str = 'utf-8')
     |      Initialise un nouveau segmenteur CSV.
     |
     |      Args:
     |          max_chunk_size_kb: Taille maximale des segments en KB
     |          preserve_header: Si True, pr�serve l'en-t�te dans chaque segment
     |          delimiter: Caract�re d�limiteur
     |          quotechar: Caract�re de citation
     |          encoding: Encodage du fichier
     |
     |  analyze(self, data: Optional[List[Dict[str, str]]] = None) -> Dict[str, Any]
     |      Analyse les donn�es CSV et retourne des informations d�taill�es.
     |
     |      Args:
     |          data: Donn�es CSV � analyser (utilise les donn�es actuelles si None)
     |
     |      Returns:
     |          Dictionnaire contenant les informations d'analyse
     |
     |  load_file(self, file_path: Union[str, pathlib.Path]) -> List[Dict[str, str]]
     |      Charge un fichier CSV.
     |
     |      Args:
     |          file_path: Chemin du fichier � charger
     |
     |      Returns:
     |          Donn�es CSV charg�es sous forme de liste de dictionnaires
     |
     |      Raises:
     |          FileNotFoundError: Si le fichier n'existe pas
     |          csv.Error: Si le fichier n'est pas un CSV valide
     |
     |  load_string(self, csv_string: str) -> List[Dict[str, str]]
     |      Charge une cha�ne CSV.
     |
     |      Args:
     |          csv_string: Cha�ne CSV � charger
     |
     |      Returns:
     |          Donn�es CSV charg�es sous forme de liste de dictionnaires
     |
     |      Raises:
     |          csv.Error: Si la cha�ne n'est pas un CSV valide
     |
     |  segment(self, data: Optional[List[Dict[str, str]]] = None) -> List[List[Dict[str, str]]]
     |      Segmente les donn�es CSV en morceaux plus petits.
     |
     |      Args:
     |          data: Donn�es CSV � segmenter (utilise les donn�es actuelles si None)
     |
     |      Returns:
     |          Liste des segments CSV
     |
     |  segment_to_files(self, output_dir: Union[str, pathlib.Path], prefix: str = 'segment_') -> List[str]
     |      Segmente les donn�es CSV actuelles et enregistre les segments dans des fichiers.
     |
     |      Args:
     |          output_dir: R�pertoire de sortie
     |          prefix: Pr�fixe pour les noms de fichiers
     |
     |      Returns:
     |          Liste des chemins des fichiers cr��s
     |
     |  validate(self, schema: Optional[Dict[str, Any]] = None) -> Tuple[bool, List[str]]
     |      Valide les donn�es CSV actuelles.
     |
     |      Args:
     |          schema: Sch�ma pour la validation (optionnel)
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
    analyze_file(file_path: str, output_file: Optional[str] = None, delimiter: str = ',', quotechar: str = '"', encoding: str = 'utf-8') -> Dict[str, Any]
        Analyse un fichier CSV et retourne des informations d�taill�es.

        Args:
            file_path: Chemin du fichier CSV
            output_file: Fichier de sortie pour l'analyse (optionnel)
            delimiter: Caract�re d�limiteur
            quotechar: Caract�re de citation
            encoding: Encodage du fichier

        Returns:
            Dictionnaire contenant les informations d'analyse

    segment_file(file_path: str, output_dir: str, max_chunk_size_kb: int = 10, preserve_header: bool = True, delimiter: str = ',', quotechar: str = '"', encoding: str = 'utf-8') -> List[str]
        Segmente un fichier CSV et enregistre les segments dans des fichiers.

        Args:
            file_path: Chemin du fichier CSV
            output_dir: R�pertoire de sortie
            max_chunk_size_kb: Taille maximale des segments en KB
            preserve_header: Si True, pr�serve l'en-t�te dans chaque segment
            delimiter: Caract�re d�limiteur
            quotechar: Caract�re de citation
            encoding: Encodage du fichier

        Returns:
            Liste des chemins des fichiers cr��s

    validate_file(file_path: str, schema_file: Optional[str] = None, delimiter: str = ',', quotechar: str = '"', encoding: str = 'utf-8') -> Tuple[bool, List[str]]
        Valide un fichier CSV.

        Args:
            file_path: Chemin du fichier CSV
            schema_file: Chemin du fichier de sch�ma JSON (optionnel)
            delimiter: Caract�re d�limiteur
            quotechar: Caract�re de citation
            encoding: Encodage du fichier

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

    logger = <Logger CsvSegmenter (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\modules\csvsegmenter.py


