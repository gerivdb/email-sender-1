Help on module file_manager:

NAME
    file_manager

DESCRIPTION
    Gestionnaire de fichiers pour projets n8n et Notion
    ---------------------------------------------------
    Ce script aide � organiser, analyser et g�rer les fichiers dans un projet
    utilisant n8n et Notion, en se concentrant sur les workflows et les fichiers JSON.

    Fonctionnalit�s:
    - Analyse des fichiers JSON (notamment workflows n8n)
    - Organisation des fichiers par type et contenu
    - D�tection des caract�res accentu�s probl�matiques
    - Cr�ation d'inventaires de fichiers exportables

CLASSES
    builtins.object
        FileManager

    class FileManager(builtins.object)
     |  FileManager(root_dir: Union[str, pathlib.Path] = '.')
     |
     |  Classe principale pour la gestion des fichiers du projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, root_dir: Union[str, pathlib.Path] = '.')
     |      Initialise le gestionnaire de fichiers.
     |
     |      Args:
     |          root_dir: R�pertoire racine du projet (par d�faut: r�pertoire courant)
     |
     |  analyze_n8n_workflows(self) -> Dict
     |      Analyse les workflows n8n pour extraire des informations utiles.
     |
     |      Returns:
     |          Dictionnaire contenant des statistiques et informations sur les workflows
     |
     |  create_inventory_report(self, output_format: str = 'csv', output_path: Optional[str] = None) -> str
     |      Cr�e un rapport d'inventaire des fichiers.
     |
     |      Args:
     |          output_format: Format de sortie ('csv', 'json', ou 'html')
     |          output_path: Chemin du fichier de sortie (optionnel)
     |
     |      Returns:
     |          Chemin du fichier de rapport g�n�r�
     |
     |  fix_accented_characters(self, target_dir: Union[str, pathlib.Path] = None, create_backup: bool = True) -> List[Dict]
     |      Corrige les probl�mes de caract�res accentu�s dans les noms de fichiers.
     |
     |      Args:
     |          target_dir: R�pertoire cible (par d�faut: utilise root_dir)
     |          create_backup: Si True, cr�e une sauvegarde avant modification
     |
     |      Returns:
     |          Liste des fichiers modifi�s avec leurs anciens et nouveaux noms
     |
     |  organize_files(self, target_dir: Union[str, pathlib.Path], organize_by: str = 'type', move_files: bool = False) -> Dict[str, List[str]]
     |      Organise les fichiers dans des sous-r�pertoires.
     |
     |      Args:
     |          target_dir: R�pertoire cible pour l'organisation
     |          organize_by: Crit�re d'organisation ('type', 'extension', 'date')
     |          move_files: Si True, d�place les fichiers; sinon, les copie
     |
     |      Returns:
     |          Dictionnaire des fichiers organis�s par cat�gorie
     |
     |  scan_directory(self, dir_path: Union[str, pathlib.Path] = None, file_extensions: List[str] = None) -> List[Dict]
     |      Analyse un r�pertoire et cr�e un inventaire des fichiers.
     |
     |      Args:
     |          dir_path: Chemin du r�pertoire � analyser (par d�faut: root_dir)
     |          file_extensions: Liste des extensions de fichiers � inclure (par d�faut: tous)
     |
     |      Returns:
     |          Liste de dictionnaires contenant les m�tadonn�es des fichiers
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
        Fonction principale pour l'ex�cution en ligne de commande.

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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\python\utils\file_utils\file_manager.py


