Help on module embeddings:

NAME
    embeddings

CLASSES
    builtins.object
        JournalEmbeddings

    class JournalEmbeddings(builtins.object)
     |  JournalEmbeddings(model_name: str = 'all-MiniLM-L6-v2')
     |
     |  Gestion des embeddings pour les entrées du journal.
     |
     |  Methods defined here:
     |
     |  __init__(self, model_name: str = 'all-MiniLM-L6-v2')
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  build_faiss_index(self) -> bool
     |      Construit un index FAISS pour une recherche plus rapide.
     |
     |  generate_embeddings(self, force_rebuild: bool = False) -> None
     |      Génère les embeddings pour toutes les entrées du journal.
     |
     |  get_embedding(self, entry_id: str) -> Optional[numpy.ndarray]
     |      Récupère l'embedding d'une entrée.
     |
     |  search_similar(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]
     |      Recherche les entrées similaires à une requête.
     |
     |  search_with_faiss(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]
     |      Recherche les entrées similaires à une requête avec FAISS.
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

    logger = <Logger journal_embeddings (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\analysis\embeddings.py


