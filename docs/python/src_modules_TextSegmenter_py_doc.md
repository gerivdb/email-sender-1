Help on module TextSegmenter:

NAME
    TextSegmenter - Module de segmentation de texte pour EMAIL_SENDER_1.

DESCRIPTION
    Ce module fournit des fonctionnalit�s avanc�es pour analyser, segmenter
    et traiter des donn�es textuelles, avec un support particulier pour
    les fichiers volumineux et les analyses intelligentes.

    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0.0
    Date: 2025-06-06

CLASSES
    builtins.object
        TextSegmenter

    class TextSegmenter(builtins.object)
     |  TextSegmenter(max_chunk_size_kb: int = 10, preserve_paragraphs: bool = True, preserve_sentences: bool = True, smart_segmentation: bool = True)
     |
     |  Classe principale pour la segmentation et l'analyse de donn�es textuelles.
     |
     |  Cette classe fournit des m�thodes pour charger, analyser et segmenter
     |  des donn�es textuelles, avec un support particulier pour les fichiers
     |  volumineux et les analyses intelligentes.
     |
     |  Methods defined here:
     |
     |  __init__(self, max_chunk_size_kb: int = 10, preserve_paragraphs: bool = True, preserve_sentences: bool = True, smart_segmentation: bool = True)
     |      Initialise un nouveau segmenteur de texte.
     |
     |      Args:
     |          max_chunk_size_kb: Taille maximale des segments en KB
     |          preserve_paragraphs: Si True, pr�serve les paragraphes dans les segments
     |          preserve_sentences: Si True, pr�serve les phrases dans les segments
     |          smart_segmentation: Si True, utilise la segmentation intelligente
     |
     |  analyze(self, text: Optional[str] = None) -> Dict[str, Any]
     |      Analyse le texte et retourne des informations d�taill�es.
     |
     |      Args:
     |          text: Texte � analyser (utilise le texte actuel si None)
     |
     |      Returns:
     |          Dictionnaire contenant les informations d'analyse
     |
     |      Raises:
     |          ValueError: Si aucun texte n'est charg�
     |
     |  load_file(self, file_path: Union[str, pathlib.Path]) -> str
     |      Charge un fichier texte.
     |
     |      Args:
     |          file_path: Chemin du fichier � charger
     |
     |      Returns:
     |          Texte charg�
     |
     |      Raises:
     |          FileNotFoundError: Si le fichier n'existe pas
     |
     |  load_string(self, text: str) -> str
     |      Charge une cha�ne de texte.
     |
     |      Args:
     |          text: Texte � charger
     |
     |      Returns:
     |          Texte charg�
     |
     |  segment(self, text: Optional[str] = None, method: str = 'auto') -> List[str]
     |      Segmente le texte en morceaux plus petits.
     |
     |      Args:
     |          text: Texte � segmenter (utilise le texte actuel si None)
     |          method: M�thode de segmentation ("auto", "paragraph", "sentence", "word", "char")
     |
     |      Returns:
     |          Liste des segments de texte
     |
     |      Raises:
     |          ValueError: Si aucun texte n'est charg�
     |
     |  segment_to_files(self, output_dir: Union[str, pathlib.Path], prefix: str = 'segment_', method: str = 'auto') -> List[str]
     |      Segmente le texte actuel et enregistre les segments dans des fichiers.
     |
     |      Args:
     |          output_dir: R�pertoire de sortie
     |          prefix: Pr�fixe pour les noms de fichiers
     |          method: M�thode de segmentation
     |
     |      Returns:
     |          Liste des chemins des fichiers cr��s
     |
     |      Raises:
     |          ValueError: Si aucun texte n'est charg�
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
        Analyse un fichier texte et retourne des informations d�taill�es.

        Args:
            file_path: Chemin du fichier texte
            output_file: Fichier de sortie pour l'analyse (optionnel)

        Returns:
            Dictionnaire contenant les informations d'analyse

    segment_file(file_path: str, output_dir: str, max_chunk_size_kb: int = 10, preserve_paragraphs: bool = True, preserve_sentences: bool = True, smart_segmentation: bool = True, method: str = 'auto') -> List[str]
        Segmente un fichier texte et enregistre les segments dans des fichiers.

        Args:
            file_path: Chemin du fichier texte
            output_dir: R�pertoire de sortie
            max_chunk_size_kb: Taille maximale des segments en KB
            preserve_paragraphs: Si True, pr�serve les paragraphes dans les segments
            preserve_sentences: Si True, pr�serve les phrases dans les segments
            smart_segmentation: Si True, utilise la segmentation intelligente
            method: M�thode de segmentation

        Returns:
            Liste des chemins des fichiers cr��s

DATA
    Dict = typing.Dict
        A generic version of dict.

    Iterator = typing.Iterator
        A generic version of collections.abc.Iterator.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Set = typing.Set
        A generic version of set.

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

    logger = <Logger TextSegmenter (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\modules\textsegmenter.py


