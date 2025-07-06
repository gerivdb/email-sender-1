Attention: graphviz non trouv�. La visualisation ne sera pas disponible.
Help on module ScriptAnalyzer:

NAME
    ScriptAnalyzer - Module d'analyse avanc�e des scripts.

DESCRIPTION
    Ce module permet d'analyser les scripts du projet pour d�tecter les d�pendances,
    les fonctions, les classes et g�n�rer des rapports d�taill�s.

CLASSES
    builtins.object
        ScriptAnalyzer

    class ScriptAnalyzer(builtins.object)
     |  ScriptAnalyzer(root_directory: str, cache_file: str = '.script_analyzer_cache.pkl')
     |
     |  Analyse les scripts du projet pour d�tecter les d�pendances,
     |  les fonctions, les classes et g�n�rer des rapports d�taill�s.
     |
     |  Methods defined here:
     |
     |  __init__(self, root_directory: str, cache_file: str = '.script_analyzer_cache.pkl')
     |      Initialise l'analyseur de scripts.
     |
     |      Args:
     |          root_directory: R�pertoire racine contenant les scripts � analyser
     |          cache_file: Fichier de cache pour stocker les r�sultats d'analyse
     |
     |  find_duplicated_code(self, min_similarity: float = 0.8) -> List[Dict]
     |      D�tecte les duplications de code entre les scripts.
     |
     |      Args:
     |          min_similarity: Seuil minimal de similarit� (0.0 � 1.0)
     |
     |      Returns:
     |          Liste des duplications d�tect�es
     |
     |  generate_report(self, output_path: str = 'script_analysis_report') -> None
     |      G�n�re des rapports sur les scripts analys�s.
     |
     |      Args:
     |          output_path: Chemin de base pour les fichiers de rapport (sans extension)
     |
     |  scan_scripts(self, force_rescan: bool = False, extensions: List[str] = None) -> Dict[str, Dict]
     |      Analyse les scripts dans le r�pertoire racine.
     |
     |      Args:
     |          force_rescan: Force une nouvelle analyse m�me si un cache existe
     |          extensions: Liste des extensions de fichiers � analyser (par d�faut: ['.ps1', '.py', '.cmd', '.bat', '.sh'])
     |
     |      Returns:
     |          Dictionnaire contenant les informations sur les scripts
     |
     |  visualize_dependencies(self, output_path: str = 'script_dependencies') -> None
     |      G�n�re une visualisation des d�pendances entre les scripts.
     |
     |      Args:
     |          output_path: Chemin de sortie pour le fichier de visualisation (sans extension)
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

DATA
    Dict = typing.Dict
        A generic version of dict.

    GRAPHVIZ_AVAILABLE = False
    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    PANDAS_AVAILABLE = True
    Set = typing.Set
        A generic version of set.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\script-manager\modules\analysis\scriptanalyzer.py


