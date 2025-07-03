Help on module n8n_integration:

NAME
    n8n_integration

CLASSES
    builtins.object
        N8nIntegration

    class N8nIntegration(builtins.object)
     |  N8nIntegration(config_path: str = 'config.json')
     |
     |  Classe pour l'int�gration avec n8n.
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: str = 'config.json')
     |      Initialise la classe N8nIntegration.
     |
     |      Args:
     |          config_path: Chemin vers le fichier de configuration
     |
     |  activate_workflow(self, workflow_id: str, active: bool = True) -> bool
     |      Active ou d�sactive un workflow n8n.
     |
     |      Args:
     |          workflow_id: ID du workflow
     |          active: True pour activer, False pour d�sactiver
     |
     |      Returns:
     |          bool: True si l'op�ration a r�ussi, False sinon
     |
     |  authenticate(self) -> bool
     |      V�rifie l'authentification avec n8n.
     |
     |      Returns:
     |          bool: True si l'authentification a r�ussi, False sinon
     |
     |  create_default_workflows(self) -> Dict[str, str]
     |      Cr�e les workflows n8n par d�faut.
     |
     |      Returns:
     |          Dict[str, str]: Dictionnaire des workflows cr��s (nom -> ID)
     |
     |  create_journal_analysis_workflow(self, name: str = 'Journal Analysis') -> Optional[str]
     |      Cr�e un workflow n8n pour analyser le journal.
     |
     |      Args:
     |          name: Nom du workflow
     |
     |      Returns:
     |          str: ID du workflow cr��
     |
     |  create_journal_entry_workflow(self, name: str = 'Create Journal Entry') -> Optional[str]
     |      Cr�e un workflow n8n pour cr�er une entr�e de journal.
     |
     |      Args:
     |          name: Nom du workflow
     |
     |      Returns:
     |          str: ID du workflow cr��
     |
     |  create_notion_sync_workflow(self, name: str = 'Notion Sync') -> Optional[str]
     |      Cr�e un workflow n8n pour synchroniser avec Notion.
     |
     |      Args:
     |          name: Nom du workflow
     |
     |      Returns:
     |          str: ID du workflow cr��
     |
     |  execute_workflow(self, workflow_id: str, data: Dict[str, Any] = None) -> Optional[Dict[str, Any]]
     |      Ex�cute un workflow n8n.
     |
     |      Args:
     |          workflow_id: ID du workflow
     |          data: Donn�es � passer au workflow
     |
     |      Returns:
     |          Dict: R�sultat de l'ex�cution
     |
     |  get_executions(self, workflow_id: str = None, limit: int = 20) -> List[Dict[str, Any]]
     |      R�cup�re les ex�cutions de workflows n8n.
     |
     |      Args:
     |          workflow_id: ID du workflow (None pour tous les workflows)
     |          limit: Nombre maximum d'ex�cutions � r�cup�rer
     |
     |      Returns:
     |          List[Dict]: Liste des ex�cutions
     |
     |  get_workflow(self, workflow_id: str) -> Optional[Dict[str, Any]]
     |      R�cup�re un workflow n8n.
     |
     |      Args:
     |          workflow_id: ID du workflow
     |
     |      Returns:
     |          Dict: Workflow r�cup�r�
     |
     |  get_workflows(self) -> List[Dict[str, Any]]
     |      R�cup�re les workflows n8n.
     |
     |      Returns:
     |          List[Dict]: Liste des workflows
     |
     |  save_config(self) -> bool
     |      Sauvegarde la configuration.
     |
     |      Returns:
     |          bool: True si la sauvegarde a r�ussi, False sinon
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

    logger = <Logger n8n_integration (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\n8n_integration.py


