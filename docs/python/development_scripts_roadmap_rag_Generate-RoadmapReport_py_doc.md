Help on module Generate-RoadmapReport:

NAME
    Generate-RoadmapReport

DESCRIPTION
    # Generate-RoadmapReport.py
    # Script pour g�n�rer des rapports d'analyse sur les roadmaps
    # Version: 1.0
    # Date: 2025-05-15

CLASSES
    builtins.object
        RoadmapReportGenerator

    class RoadmapReportGenerator(builtins.object)
     |  RoadmapReportGenerator(collection_name: str = 'roadmaps', qdrant_host: str = 'localhost', qdrant_port: int = 6333, output_dir: str = 'projet/roadmaps/reports')
     |
     |  Classe pour g�n�rer des rapports d'analyse sur les roadmaps
     |
     |  Methods defined here:
     |
     |  __init__(self, collection_name: str = 'roadmaps', qdrant_host: str = 'localhost', qdrant_port: int = 6333, output_dir: str = 'projet/roadmaps/reports')
     |      Initialise le g�n�rateur de rapports
     |
     |      Args:
     |          collection_name: Nom de la collection Qdrant
     |          qdrant_host: H�te du serveur Qdrant
     |          qdrant_port: Port du serveur Qdrant
     |          output_dir: Dossier de sortie pour les rapports
     |
     |  generate_completion_report(self, output_path: str = None, filter_condition: Optional[Dict[str, Any]] = None) -> str
     |      G�n�re un rapport sur le taux de compl�tion des t�ches
     |
     |      Args:
     |          output_path: Chemin vers le fichier de sortie
     |          filter_condition: Condition de filtrage pour Qdrant
     |
     |      Returns:
     |          Chemin vers le fichier g�n�r�
     |
     |  generate_priority_report(self, output_path: str = None, filter_condition: Optional[Dict[str, Any]] = None) -> str
     |      G�n�re un rapport sur la distribution des priorit�s
     |
     |      Args:
     |          output_path: Chemin vers le fichier de sortie
     |          filter_condition: Condition de filtrage pour Qdrant
     |
     |      Returns:
     |          Chemin vers le fichier g�n�r�
     |
     |  generate_progress_report(self, output_path: str = None, filter_condition: Optional[Dict[str, Any]] = None, time_period: str = 'weekly') -> str
     |      G�n�re un rapport sur la progression des t�ches
     |
     |      Args:
     |          output_path: Chemin vers le fichier de sortie
     |          filter_condition: Condition de filtrage pour Qdrant
     |          time_period: P�riode de temps pour l'analyse (daily, weekly, monthly)
     |
     |      Returns:
     |          Chemin vers le fichier g�n�r�
     |
     |  get_all_tasks(self) -> List[Dict[str, Any]]
     |      R�cup�re toutes les t�ches de la collection
     |
     |      Returns:
     |          Liste de t�ches
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
    main()
        Fonction principale

DATA
    DEFAULT_COLLECTION = 'roadmaps'
    DEFAULT_OUTPUT_DIR = 'projet/roadmaps/reports'
    DEFAULT_QDRANT_HOST = 'localhost'
    DEFAULT_QDRANT_PORT = 6333
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

    logger = <Logger Generate-RoadmapReport (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\generate-roadmapreport.py


