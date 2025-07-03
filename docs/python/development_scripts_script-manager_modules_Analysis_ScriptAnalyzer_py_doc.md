Attention: graphviz non trouvé. La visualisation ne sera pas disponible.
Help on module ScriptAnalyzer:

NAME
    ScriptAnalyzer - Module d'analyse avancée des scripts.

DESCRIPTION
    Ce module permet d'analyser les scripts du projet pour détecter les dépendances,
    les fonctions, les classes et générer des rapports détaillés.

CLASSES
    builtins.object
        ScriptAnalyzer

    class ScriptAnalyzer(builtins.object)
     |  ScriptAnalyzer(root_directory: str, cache_file: str = '.script_analyzer_cache.pkl')
     |
     |  Analyse les scripts du projet pour détecter les dépendances,
     |  les fonctions, les classes et générer des rapports détaillés.
     |
     |  Methods defined here:
     |
     |  __init__(self, root_directory: str, cache_file: str = '.script_analyzer_cache.pkl')
     |      Initialise l'analyseur de scripts.
     |
     |      Args:
     |          root_directory: Répertoire racine contenant les scripts à analyser
     |          cache_file: Fichier de cache pour stocker les résultats d'analyse
     |
     |  find_duplicated_code(self, min_similarity: float = 0.8) -> List[Dict]
     |      Détecte les duplications de code entre les scripts.
     |
     |      Args:
     |          min_similarity: Seuil minimal de similarité (0.0 à 1.0)
     |
     |      Returns:
     |          Liste des duplications détectées
     |
     |  generate_report(self, output_path: str = 'script_analysis_report') -> None
     |      Génère des rapports sur les scripts analysés.
     |
     |      Args:
     |          output_path: Chemin de base pour les fichiers de rapport (sans extension)
     |
     |  scan_scripts(self, force_rescan: bool = False, extensions: List[str] = None) -> Dict[str, Dict]
     |      Analyse les scripts dans le répertoire racine.
     |
     |      Args:
     |          force_rescan: Force une nouvelle analyse même si un cache existe
     |          extensions: Liste des extensions de fichiers à analyser (par défaut: ['.ps1', '.py', '.cmd', '.bat', '.sh'])
     |
     |      Returns:
     |          Dictionnaire contenant les informations sur les scripts
     |
     |  visualize_dependencies(self, output_path: str = 'script_dependencies') -> None
     |      Génère une visualisation des dépendances entre les scripts.
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


