Help on module erpnext_integration:

NAME
    erpnext_integration

CLASSES
    builtins.object
        ERPNextIntegration

    class ERPNextIntegration(builtins.object)
     |  ERPNextIntegration(config_path: str = 'config.json')
     |
     |  Classe pour l'int�gration avec ERPNext.
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: str = 'config.json')
     |      Initialise la classe ERPNextIntegration.
     |
     |      Args:
     |          config_path: Chemin vers le fichier de configuration
     |
     |  create_note_from_journal_entry(self, entry_path: str) -> Optional[str]
     |      Cr�e une note ERPNext � partir d'une entr�e de journal.
     |
     |      Args:
     |          entry_path: Chemin vers l'entr�e de journal
     |
     |      Returns:
     |          str: Nom de la note cr��e
     |
     |  create_task(self, subject: str, description: str, project: str = None, status: str = 'Open', priority: str = 'Medium') -> Optional[str]
     |      Cr�e une t�che ERPNext.
     |
     |      Args:
     |          subject: Sujet de la t�che
     |          description: Description de la t�che
     |          project: Nom du projet
     |          status: Statut de la t�che
     |          priority: Priorit� de la t�che
     |
     |      Returns:
     |          str: Nom de la t�che cr��e
     |
     |  get_project(self, project_name: str) -> Optional[Dict[str, Any]]
     |      R�cup�re un projet ERPNext.
     |
     |      Args:
     |          project_name: Nom du projet
     |
     |      Returns:
     |          Dict: Projet r�cup�r�
     |
     |  get_projects(self) -> List[Dict[str, Any]]
     |      R�cup�re les projets ERPNext.
     |
     |      Returns:
     |          List[Dict]: Liste des projets
     |
     |  get_task(self, task_name: str) -> Optional[Dict[str, Any]]
     |      R�cup�re une t�che ERPNext.
     |
     |      Args:
     |          task_name: Nom de la t�che
     |
     |      Returns:
     |          Dict: T�che r�cup�r�e
     |
     |  get_tasks(self, project_name: str = None) -> List[Dict[str, Any]]
     |      R�cup�re les t�ches ERPNext.
     |
     |      Args:
     |          project_name: Nom du projet (None pour toutes les t�ches)
     |
     |      Returns:
     |          List[Dict]: Liste des t�ches
     |
     |  save_config(self) -> bool
     |      Sauvegarde la configuration.
     |
     |      Returns:
     |          bool: True si la sauvegarde a r�ussi, False sinon
     |
     |  sync_from_journal(self) -> bool
     |      Synchronise les entr�es du journal vers ERPNext.
     |
     |      Returns:
     |          bool: True si la synchronisation a r�ussi, False sinon
     |
     |  sync_to_journal(self) -> bool
     |      Synchronise les t�ches ERPNext vers le journal.
     |
     |      Returns:
     |          bool: True si la synchronisation a r�ussi, False sinon
     |
     |  update_task(self, task_name: str, data: Dict[str, Any]) -> bool
     |      Met � jour une t�che ERPNext.
     |
     |      Args:
     |          task_name: Nom de la t�che
     |          data: Donn�es � mettre � jour
     |
     |      Returns:
     |          bool: True si la mise � jour a r�ussi, False sinon
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

    logger = <Logger erpnext_integration (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\erpnext_integration.py


