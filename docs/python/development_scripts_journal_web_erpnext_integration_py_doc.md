Help on module erpnext_integration:

NAME
    erpnext_integration

CLASSES
    builtins.object
        ERPNextIntegration

    class ERPNextIntegration(builtins.object)
     |  ERPNextIntegration(config_path: str = 'config.json')
     |
     |  Classe pour l'intégration avec ERPNext.
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
     |      Crée une note ERPNext à partir d'une entrée de journal.
     |
     |      Args:
     |          entry_path: Chemin vers l'entrée de journal
     |
     |      Returns:
     |          str: Nom de la note créée
     |
     |  create_task(self, subject: str, description: str, project: str = None, status: str = 'Open', priority: str = 'Medium') -> Optional[str]
     |      Crée une tâche ERPNext.
     |
     |      Args:
     |          subject: Sujet de la tâche
     |          description: Description de la tâche
     |          project: Nom du projet
     |          status: Statut de la tâche
     |          priority: Priorité de la tâche
     |
     |      Returns:
     |          str: Nom de la tâche créée
     |
     |  get_project(self, project_name: str) -> Optional[Dict[str, Any]]
     |      Récupère un projet ERPNext.
     |
     |      Args:
     |          project_name: Nom du projet
     |
     |      Returns:
     |          Dict: Projet récupéré
     |
     |  get_projects(self) -> List[Dict[str, Any]]
     |      Récupère les projets ERPNext.
     |
     |      Returns:
     |          List[Dict]: Liste des projets
     |
     |  get_task(self, task_name: str) -> Optional[Dict[str, Any]]
     |      Récupère une tâche ERPNext.
     |
     |      Args:
     |          task_name: Nom de la tâche
     |
     |      Returns:
     |          Dict: Tâche récupérée
     |
     |  get_tasks(self, project_name: str = None) -> List[Dict[str, Any]]
     |      Récupère les tâches ERPNext.
     |
     |      Args:
     |          project_name: Nom du projet (None pour toutes les tâches)
     |
     |      Returns:
     |          List[Dict]: Liste des tâches
     |
     |  save_config(self) -> bool
     |      Sauvegarde la configuration.
     |
     |      Returns:
     |          bool: True si la sauvegarde a réussi, False sinon
     |
     |  sync_from_journal(self) -> bool
     |      Synchronise les entrées du journal vers ERPNext.
     |
     |      Returns:
     |          bool: True si la synchronisation a réussi, False sinon
     |
     |  sync_to_journal(self) -> bool
     |      Synchronise les tâches ERPNext vers le journal.
     |
     |      Returns:
     |          bool: True si la synchronisation a réussi, False sinon
     |
     |  update_task(self, task_name: str, data: Dict[str, Any]) -> bool
     |      Met à jour une tâche ERPNext.
     |
     |      Args:
     |          task_name: Nom de la tâche
     |          data: Données à mettre à jour
     |
     |      Returns:
     |          bool: True si la mise à jour a réussi, False sinon
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


