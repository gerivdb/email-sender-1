Help on module embedding_manager:

NAME
    embedding_manager

DESCRIPTION
    Module pour g�rer les embeddings vectoriels.
    Ce module fournit des classes et fonctions pour cr�er, manipuler et stocker des embeddings.

CLASSES
    builtins.object
        Embedding
        EmbeddingCollection
        Vector

    class Embedding(builtins.object)
     |  Embedding(vector: embedding_manager.Vector, text: str, metadata: Optional[Dict[str, Any]] = None, id: Optional[str] = None)
     |
     |  Classe repr�sentant un embedding avec m�tadonn�es.
     |
     |  Methods defined here:
     |
     |  __init__(self, vector: embedding_manager.Vector, text: str, metadata: Optional[Dict[str, Any]] = None, id: Optional[str] = None)
     |      Initialise un embedding.
     |
     |      Args:
     |          vector: Vecteur d'embedding.
     |          text: Texte associ� � l'embedding.
     |          metadata: M�tadonn�es associ�es � l'embedding.
     |          id: Identifiant unique de l'embedding (g�n�r� automatiquement si None).
     |
     |  __repr__(self) -> str
     |      Repr�sentation de l'embedding.
     |
     |      Returns:
     |          Repr�sentation sous forme de cha�ne.
     |
     |  save_to_file(self, file_path: str) -> None
     |      Sauvegarde l'embedding dans un fichier JSON.
     |
     |      Args:
     |          file_path: Chemin du fichier de sortie.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit l'embedding en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire repr�sentant l'embedding.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'Embedding'
     |      Cr�e un embedding � partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire repr�sentant l'embedding.
     |
     |      Returns:
     |          Embedding cr��.
     |
     |  load_from_file(file_path: str) -> 'Embedding'
     |      Charge un embedding depuis un fichier JSON.
     |
     |      Args:
     |          file_path: Chemin du fichier d'entr�e.
     |
     |      Returns:
     |          Embedding charg�.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class EmbeddingCollection(builtins.object)
     |  EmbeddingCollection(name: str = 'default')
     |
     |  Classe repr�sentant une collection d'embeddings.
     |
     |  Methods defined here:
     |
     |  __init__(self, name: str = 'default')
     |      Initialise une collection d'embeddings.
     |
     |      Args:
     |          name: Nom de la collection.
     |
     |  __iter__(self)
     |      It�re sur les embeddings de la collection.
     |
     |      Returns:
     |          It�rateur sur les embeddings.
     |
     |  __len__(self) -> int
     |      Retourne le nombre d'embeddings dans la collection.
     |
     |      Returns:
     |          Nombre d'embeddings.
     |
     |  __repr__(self) -> str
     |      Repr�sentation de la collection.
     |
     |      Returns:
     |          Repr�sentation sous forme de cha�ne.
     |
     |  add(self, embedding: embedding_manager.Embedding) -> str
     |      Ajoute un embedding � la collection.
     |
     |      Args:
     |          embedding: Embedding � ajouter.
     |
     |      Returns:
     |          Identifiant de l'embedding.
     |
     |  get(self, id: str) -> Optional[embedding_manager.Embedding]
     |      R�cup�re un embedding par son identifiant.
     |
     |      Args:
     |          id: Identifiant de l'embedding.
     |
     |      Returns:
     |          Embedding correspondant ou None si non trouv�.
     |
     |  remove(self, id: str) -> bool
     |      Supprime un embedding de la collection.
     |
     |      Args:
     |          id: Identifiant de l'embedding.
     |
     |      Returns:
     |          True si l'embedding a �t� supprim�, False sinon.
     |
     |  save_to_file(self, file_path: str) -> None
     |      Sauvegarde la collection dans un fichier JSON.
     |
     |      Args:
     |          file_path: Chemin du fichier de sortie.
     |
     |  search(self, query_vector: embedding_manager.Vector, top_k: int = 5, threshold: float = 0.0, filter_func: Optional[<built-in function callable>] = None) -> List[Tuple[embedding_manager.Embedding, float]]
     |      Recherche les embeddings les plus similaires � un vecteur de requ�te.
     |
     |      Args:
     |          query_vector: Vecteur de requ�te.
     |          top_k: Nombre maximum de r�sultats � retourner.
     |          threshold: Seuil minimal de similarit�.
     |          filter_func: Fonction de filtrage des embeddings.
     |
     |      Returns:
     |          Liste de tuples (embedding, score) tri�s par score d�croissant.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit la collection en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire repr�sentant la collection.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'EmbeddingCollection'
     |      Cr�e une collection � partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire repr�sentant la collection.
     |
     |      Returns:
     |          Collection cr��e.
     |
     |  load_from_file(file_path: str) -> 'EmbeddingCollection'
     |      Charge une collection depuis un fichier JSON.
     |
     |      Args:
     |          file_path: Chemin du fichier d'entr�e.
     |
     |      Returns:
     |          Collection charg�e.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class Vector(builtins.object)
     |  Vector(data: Union[List[float], numpy.ndarray], model_name: str = 'unknown', normalize: bool = True)
     |
     |  Classe repr�sentant un vecteur d'embedding.
     |
     |  Methods defined here:
     |
     |  __getitem__(self, index: int) -> float
     |      Acc�de � un �l�ment du vecteur.
     |
     |      Args:
     |          index: Index de l'�l�ment.
     |
     |      Returns:
     |          Valeur de l'�l�ment.
     |
     |  __init__(self, data: Union[List[float], numpy.ndarray], model_name: str = 'unknown', normalize: bool = True)
     |      Initialise un vecteur d'embedding.
     |
     |      Args:
     |          data: Donn�es du vecteur (liste de flottants ou tableau numpy).
     |          model_name: Nom du mod�le ayant g�n�r� l'embedding.
     |          normalize: Si True, normalise le vecteur � la cr�ation.
     |
     |  __len__(self) -> int
     |      Retourne la dimension du vecteur.
     |
     |      Returns:
     |          Dimension du vecteur.
     |
     |  __repr__(self) -> str
     |      Repr�sentation du vecteur.
     |
     |      Returns:
     |          Repr�sentation sous forme de cha�ne.
     |
     |  cosine_similarity(self, other: 'Vector') -> float
     |      Calcule la similarit� cosinus avec un autre vecteur.
     |
     |      Args:
     |          other: Autre vecteur.
     |
     |      Returns:
     |          Similarit� cosinus (entre -1 et 1).
     |
     |  dot_product(self, other: 'Vector') -> float
     |      Calcule le produit scalaire avec un autre vecteur.
     |
     |      Args:
     |          other: Autre vecteur.
     |
     |      Returns:
     |          Produit scalaire.
     |
     |  euclidean_distance(self, other: 'Vector') -> float
     |      Calcule la distance euclidienne avec un autre vecteur.
     |
     |      Args:
     |          other: Autre vecteur.
     |
     |      Returns:
     |          Distance euclidienne.
     |
     |  normalize(self) -> None
     |      Normalise le vecteur (norme L2 = 1).
     |
     |  to_list(self) -> List[float]
     |      Convertit le vecteur en liste de flottants.
     |
     |      Returns:
     |          Liste de flottants.
     |
     |  to_numpy(self) -> numpy.ndarray
     |      Convertit le vecteur en tableau numpy.
     |
     |      Returns:
     |          Tableau numpy.
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
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\mcp\embedding_manager.py


