Help on module detector:

NAME
    detector

CLASSES
    builtins.object
        PatternDetector

    class PatternDetector(builtins.object)
     |  Détecteur de patterns dans le journal de bord.
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  add_notification(self, notification: Dict[str, Any]) -> None
     |      Ajoute une notification à l'historique.
     |
     |  detect_all_patterns(self) -> List[Dict[str, Any]]
     |      Détecte tous les patterns et génère des notifications.
     |
     |  detect_sentiment_patterns(self) -> List[Dict[str, Any]]
     |      Détecte les patterns dans les sentiments.
     |
     |  detect_term_frequency_patterns(self) -> List[Dict[str, Any]]
     |      Détecte les patterns dans la fréquence des termes.
     |
     |  detect_topic_patterns(self) -> List[Dict[str, Any]]
     |      Détecte les patterns dans les sujets.
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

    logger = <Logger journal_notifications.detector (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\detector.py


