Help on module topic_modeling:

NAME
    topic_modeling

CLASSES
    builtins.object
        TopicModeling

    class TopicModeling(builtins.object)
     |  TopicModeling(n_topics: int = 10, n_top_words: int = 10)
     |
     |  Modélisation de sujets pour les entrées du journal.
     |
     |  Methods defined here:
     |
     |  __init__(self, n_topics: int = 10, n_top_words: int = 10)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  extract_topics_bertopic(self) -> Dict[str, Any]
     |      Extrait les sujets des entrées du journal avec BERTopic.
     |
     |  extract_topics_by_section(self) -> Dict[str, Any]
     |      Extrait les sujets par section du journal.
     |
     |  extract_topics_lda(self) -> Dict[str, Any]
     |      Extrait les sujets des entrées du journal avec LDA.
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

    logger = <Logger journal_topics (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\analysis\topic_modeling.py


