Help on module sentiment_analysis:

NAME
    sentiment_analysis

CLASSES
    builtins.object
        SentimentAnalysis

    class SentimentAnalysis(builtins.object)
     |  Analyse de sentiment pour les entrées du journal.
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  analyze_sentiment_by_section(self) -> Dict[str, Any]
     |      Analyse le sentiment par section du journal.
     |
     |  analyze_sentiment_with_textblob(self) -> Dict[str, Any]
     |      Analyse le sentiment des entrées avec TextBlob.
     |
     |  analyze_sentiment_with_transformers(self) -> Dict[str, Any]
     |      Analyse le sentiment des entrées avec un modèle Transformers.
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

    logger = <Logger journal_sentiment (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\analysis\sentiment_analysis.py


