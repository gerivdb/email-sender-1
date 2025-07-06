Help on module version_control:

NAME
    version_control - Module de gestion des versions pour le syst�me CRUD th�matique.

DESCRIPTION
    Ce module fournit des fonctionnalit�s pour g�rer les versions des �l�ments
    par th�me, permettant de suivre l'historique des modifications et de restaurer
    des versions ant�rieures.

CLASSES
    builtins.object
        ThematicVersionControl

    class ThematicVersionControl(builtins.object)
     |  ThematicVersionControl(storage_path: str, versions_path: Optional[str] = None)
     |
     |  Classe pour la gestion des versions des �l�ments par th�me.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, versions_path: Optional[str] = None)
     |      Initialise le gestionnaire de versions th�matique.
     |
     |      Args:
     |          storage_path: Chemin vers le r�pertoire de stockage des donn�es
     |          versions_path: Chemin vers le r�pertoire de stockage des versions (optionnel)
     |
     |  compare_versions(self, item_id: str, version1: int, version2: int) -> Dict[str, Any]
     |      Compare deux versions d'un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          version1: Num�ro de la premi�re version
     |          version2: Num�ro de la deuxi�me version
     |
     |      Returns:
     |          Dictionnaire des diff�rences entre les versions
     |
     |  create_version(self, item: Dict[str, Any], version_tag: Optional[str] = None, version_message: Optional[str] = None) -> Dict[str, Any]
     |      Cr�e une nouvelle version d'un �l�ment.
     |
     |      Args:
     |          item: �l�ment � versionner
     |          version_tag: Tag de version (optionnel)
     |          version_message: Message de version (optionnel)
     |
     |      Returns:
     |          M�tadonn�es de la version cr��e
     |
     |  get_version(self, item_id: str, version_number: int) -> Optional[Dict[str, Any]]
     |      R�cup�re une version sp�cifique d'un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          version_number: Num�ro de version
     |
     |      Returns:
     |          �l�ment � la version sp�cifi�e, ou None si la version n'existe pas
     |
     |  get_versions(self, item_id: str) -> List[Dict[str, Any]]
     |      R�cup�re toutes les versions d'un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |
     |      Returns:
     |          Liste des m�tadonn�es de versions, tri�es par num�ro de version d�croissant
     |
     |  get_versions_by_theme(self, theme: str, item_id: Optional[str] = None) -> Dict[str, List[Dict[str, Any]]]
     |      R�cup�re les versions des �l�ments d'un th�me.
     |
     |      Args:
     |          theme: Th�me des �l�ments
     |          item_id: Identifiant de l'�l�ment (optionnel)
     |
     |      Returns:
     |          Dictionnaire des versions par �l�ment
     |
     |  restore_version(self, item_id: str, version_number: int, storage_path: Optional[str] = None) -> Optional[Dict[str, Any]]
     |      Restaure une version sp�cifique d'un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          version_number: Num�ro de version
     |          storage_path: Chemin vers le r�pertoire de stockage (optionnel)
     |
     |      Returns:
     |          �l�ment restaur�, ou None si la restauration a �chou�
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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\version_control.py


