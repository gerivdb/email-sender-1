Help on module EncodingDetector:

NAME
    EncodingDetector - Module de détection d'encodage pour EMAIL_SENDER_1.

DESCRIPTION
    Ce module fournit des fonctionnalités pour détecter automatiquement
    l'encodage des fichiers texte, JSON et XML.

    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0.0
    Date: 2025-06-06

CLASSES
    builtins.object
        EncodingDetector

    class EncodingDetector(builtins.object)
     |  EncodingDetector(sample_size: int = 4096)
     |
     |  Classe pour détecter l'encodage des fichiers.
     |
     |  Methods defined here:
     |
     |  __init__(self, sample_size: int = 4096)
     |      Initialise un nouveau détecteur d'encodage.
     |
     |      Args:
     |          sample_size: Taille de l'échantillon à analyser (en octets)
     |
     |  detect_file_encoding(self, file_path: Union[str, pathlib.Path]) -> Dict[str, Any]
     |      Détecte l'encodage d'un fichier.
     |
     |      Args:
     |          file_path: Chemin du fichier
     |
     |      Returns:
     |          Dictionnaire contenant les informations d'encodage
     |
     |  detect_string_encoding(self, data: bytes) -> Dict[str, Any]
     |      Détecte l'encodage d'une chaîne de bytes.
     |
     |      Args:
     |          data: Données à analyser
     |
     |      Returns:
     |          Dictionnaire contenant les informations d'encodage
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
    detect_file(file_path: str) -> Dict[str, Any]
        Détecte l'encodage d'un fichier.

        Args:
            file_path: Chemin du fichier

        Returns:
            Dictionnaire contenant les informations d'encodage

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

    logger = <Logger EncodingDetector (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\modules\encodingdetector.py


