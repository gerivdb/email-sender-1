Help on module Generate-RoadmapVisualization:

NAME
    Generate-RoadmapVisualization

DESCRIPTION
    # Generate-RoadmapVisualization.py
    # Script pour g�n�rer des visualisations graphiques des roadmaps
    # Version: 1.0
    # Date: 2025-05-15

CLASSES
    builtins.object
        RoadmapVisualizer

    class RoadmapVisualizer(builtins.object)
     |  RoadmapVisualizer(output_dir: str = 'projet/roadmaps/analysis/visualizations')
     |
     |  Classe pour g�n�rer des visualisations graphiques des roadmaps
     |
     |  Methods defined here:
     |
     |  __init__(self, output_dir: str = 'projet/roadmaps/analysis/visualizations')
     |      Initialise le visualiseur de roadmaps
     |
     |      Args:
     |          output_dir: Dossier de sortie pour les visualisations
     |
     |  generate_completion_chart(self, roadmap: Dict[str, Any], output_path: str) -> None
     |      G�n�re un graphique de compl�tion des t�ches par section
     |
     |      Args:
     |          roadmap: Dictionnaire contenant la structure de la roadmap
     |          output_path: Chemin vers le fichier de sortie
     |
     |  generate_task_distribution_chart(self, roadmap: Dict[str, Any], output_path: str) -> None
     |      G�n�re un graphique de distribution des t�ches par niveau d'indentation
     |
     |      Args:
     |          roadmap: Dictionnaire contenant la structure de la roadmap
     |          output_path: Chemin vers le fichier de sortie
     |
     |  generate_task_graph(self, roadmap: Dict[str, Any], output_path: str) -> None
     |      G�n�re un graphe des t�ches
     |
     |      Args:
     |          roadmap: Dictionnaire contenant la structure de la roadmap
     |          output_path: Chemin vers le fichier de sortie
     |
     |  generate_visualizations(self, file_path: str) -> None
     |      G�n�re toutes les visualisations pour un fichier de roadmap
     |
     |      Args:
     |          file_path: Chemin vers le fichier markdown
     |
     |  parse_markdown(self, file_path: str) -> Dict[str, Any]
     |      Parse un fichier markdown de roadmap
     |
     |      Args:
     |          file_path: Chemin vers le fichier markdown
     |
     |      Returns:
     |          Dictionnaire contenant la structure de la roadmap
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

    logger = <Logger Generate-RoadmapVisualization (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\generate-roadmapvisualization.py


