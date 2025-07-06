Help on module notifier:

NAME
    notifier

CLASSES
    builtins.object
        NotificationManager

    class NotificationManager(builtins.object)
     |  Gestionnaire de notifications pour le journal de bord.
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  get_notifications(self, limit: int = 100, unread_only: bool = False) -> List[Dict[str, Any]]
     |      Récupère les notifications.
     |
     |  mark_all_as_read(self) -> bool
     |      Marque toutes les notifications comme lues.
     |
     |  mark_as_read(self, notification_id: str) -> bool
     |      Marque une notification comme lue.
     |
     |  send_notification(self, notification: Dict[str, Any]) -> None
     |      Envoie une notification via tous les canaux activés.
     |
     |  send_notifications(self, notifications: List[Dict[str, Any]]) -> None
     |      Envoie plusieurs notifications.
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

    logger = <Logger journal_notifications.notifier (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\notifier.py


