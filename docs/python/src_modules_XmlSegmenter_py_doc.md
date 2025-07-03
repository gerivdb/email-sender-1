Help on module XmlSegmenter:

NAME
    XmlSegmenter - Module de segmentation XML pour EMAIL_SENDER_1.

DESCRIPTION
    Ce module fournit des fonctionnalit�s avanc�es pour parser, segmenter,
    valider et analyser des donn�es XML, avec un support particulier pour
    les fichiers volumineux et les requ�tes XPath.

    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0.0
    Date: 2025-06-06

CLASSES
    builtins.object
        XmlSegmenter

    class XmlSegmenter(builtins.object)
     |  XmlSegmenter(max_chunk_size_kb: int = 10, preserve_structure: bool = True)
     |
     |  Classe principale pour la segmentation et l'analyse de donn�es XML.
     |
     |  Cette classe fournit des m�thodes pour charger, valider, analyser et
     |  segmenter des donn�es XML, avec un support particulier pour les
     |  fichiers volumineux et les requ�tes XPath.
     |
     |  Methods defined here:
     |
     |  __init__(self, max_chunk_size_kb: int = 10, preserve_structure: bool = True)
     |      Initialise un nouveau segmenteur XML.
     |
     |      Args:
     |          max_chunk_size_kb: Taille maximale des segments en KB
     |          preserve_structure: Si True, pr�serve la structure XML dans les segments
     |
     |  analyze(self) -> Dict[str, Any]
     |      Analyse les donn�es XML et retourne des informations d�taill�es.
     |
     |      Returns:
     |          Dictionnaire contenant les informations d'analyse
     |
     |      Raises:
     |          ValueError: Si aucune donn�e XML n'est charg�e
     |
     |  load_file(self, file_path: Union[str, pathlib.Path]) -> xml.etree.ElementTree.ElementTree
     |      Charge un fichier XML.
     |
     |      Args:
     |          file_path: Chemin du fichier � charger
     |
     |      Returns:
     |          Arbre XML charg�
     |
     |      Raises:
     |          FileNotFoundError: Si le fichier n'existe pas
     |          ET.ParseError: Si le fichier n'est pas un XML valide
     |
     |  load_string(self, xml_string: str) -> xml.etree.ElementTree.ElementTree
     |      Charge une cha�ne XML.
     |
     |      Args:
     |          xml_string: Cha�ne XML � charger
     |
     |      Returns:
     |          Arbre XML charg�
     |
     |      Raises:
     |          ET.ParseError: Si la cha�ne n'est pas un XML valide
     |
     |  segment(self, xpath_expression: Optional[str] = None) -> List[str]
     |      Segmente les donn�es XML en morceaux plus petits.
     |
     |      Args:
     |          xpath_expression: Expression XPath pour s�lectionner les �l�ments � segmenter (optionnel)
     |
     |      Returns:
     |          Liste des segments XML (sous forme de cha�nes)
     |
     |      Raises:
     |          ValueError: Si aucune donn�e XML n'est charg�e
     |
     |  segment_to_files(self, output_dir: Union[str, pathlib.Path], prefix: str = 'segment_', xpath_expression: Optional[str] = None) -> List[str]
     |      Segmente les donn�es XML actuelles et enregistre les segments dans des fichiers.
     |
     |      Args:
     |          output_dir: R�pertoire de sortie
     |          prefix: Pr�fixe pour les noms de fichiers
     |          xpath_expression: Expression XPath pour s�lectionner les �l�ments � segmenter (optionnel)
     |
     |      Returns:
     |          Liste des chemins des fichiers cr��s
     |
     |      Raises:
     |          ValueError: Si aucune donn�e XML n'est charg�e
     |
     |  validate(self, schema_path: Optional[str] = None) -> Tuple[bool, List[str]]
     |      Valide les donn�es XML actuelles.
     |
     |      Args:
     |          schema_path: Chemin du fichier de sch�ma XSD (optionnel)
     |
     |      Returns:
     |          Tuple (est_valide, erreurs)
     |
     |  xpath_query(self, xpath_expression: str) -> List[lxml.etree._Element]
     |      Ex�cute une requ�te XPath sur les donn�es XML actuelles.
     |
     |      Args:
     |          xpath_expression: Expression XPath
     |
     |      Returns:
     |          Liste des �l�ments correspondants
     |
     |      Raises:
     |          ValueError: Si aucune donn�e XML n'est charg�e
     |          etree.XPathError: Si l'expression XPath est invalide
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
        Analyse un fichier XML et retourne des informations d�taill�es.

        Args:
            file_path: Chemin du fichier XML
            output_file: Fichier de sortie pour l'analyse (optionnel)

        Returns:
            Dictionnaire contenant les informations d'analyse

    segment_file(file_path: str, output_dir: str, max_chunk_size_kb: int = 10, preserve_structure: bool = True, xpath: Optional[str] = None) -> List[str]
        Segmente un fichier XML et enregistre les segments dans des fichiers.

        Args:
            file_path: Chemin du fichier XML
            output_dir: R�pertoire de sortie
            max_chunk_size_kb: Taille maximale des segments en KB
            preserve_structure: Si True, pr�serve la structure XML dans les segments
            xpath: Expression XPath pour s�lectionner les �l�ments � segmenter (optionnel)

        Returns:
            Liste des chemins des fichiers cr��s

    validate_file(file_path: str, schema_file: Optional[str] = None) -> Tuple[bool, List[str]]
        Valide un fichier XML.

        Args:
            file_path: Chemin du fichier XML
            schema_file: Chemin du fichier de sch�ma XSD (optionnel)

        Returns:
            Tuple (est_valide, erreurs)

    xpath_query_file(file_path: str, xpath: str) -> List[str]
        Ex�cute une requ�te XPath sur un fichier XML.

        Args:
            file_path: Chemin du fichier XML
            xpath: Expression XPath

        Returns:
            Liste des �l�ments correspondants (sous forme de cha�nes)

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

    logger = <Logger XmlSegmenter (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\modules\xmlsegmenter.py


