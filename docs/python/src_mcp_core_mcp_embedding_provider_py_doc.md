Help on module embedding_provider:

NAME
    embedding_provider - Module pour les fournisseurs d'embeddings.

DESCRIPTION
    Ce module contient les interfaces et implémentations pour les fournisseurs d'embeddings.

CLASSES
    builtins.object
        CachedEmbeddingProvider
        DummyEmbeddingProvider
    typing.Protocol(typing.Generic)
        EmbeddingProvider

    class CachedEmbeddingProvider(builtins.object)
     |  CachedEmbeddingProvider(provider: embedding_provider.EmbeddingProvider, cache_dir: Optional[str] = None)
     |
     |  Fournisseur d'embeddings avec cache.
     |
     |  Ce fournisseur utilise un autre fournisseur d'embeddings et met en cache les résultats.
     |
     |  Methods defined here:
     |
     |  __init__(self, provider: embedding_provider.EmbeddingProvider, cache_dir: Optional[str] = None)
     |      Initialise le fournisseur d'embeddings avec cache.
     |
     |      Args:
     |          provider (EmbeddingProvider): Fournisseur d'embeddings sous-jacent
     |          cache_dir (Optional[str], optional): Répertoire de cache. Par défaut None (cache en mémoire).
     |
     |  get_embedding(self, text: str) -> List[float]
     |      Génère un embedding pour un texte, en utilisant le cache si disponible.
     |
     |      Args:
     |          text (str): Texte à encoder
     |
     |      Returns:
     |          List[float]: Embedding vectoriel
     |
     |  get_embeddings(self, texts: List[str]) -> List[List[float]]
     |      Génère des embeddings pour une liste de textes, en utilisant le cache si disponible.
     |
     |      Args:
     |          texts (List[str]): Liste de textes à encoder
     |
     |      Returns:
     |          List[List[float]]: Liste d'embeddings vectoriels
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class DummyEmbeddingProvider(builtins.object)
     |  DummyEmbeddingProvider(dimension: int = 128)
     |
     |  Fournisseur d'embeddings factice pour les tests.
     |
     |  Ce fournisseur génère des embeddings déterministes basés sur le hachage du texte.
     |
     |  Methods defined here:
     |
     |  __init__(self, dimension: int = 128)
     |      Initialise le fournisseur d'embeddings.
     |
     |      Args:
     |          dimension (int, optional): Dimension des embeddings. Par défaut 128.
     |
     |  get_embedding(self, text: str) -> List[float]
     |      Génère un embedding déterministe pour un texte.
     |
     |      Args:
     |          text (str): Texte à encoder
     |
     |      Returns:
     |          List[float]: Embedding vectoriel
     |
     |  get_embeddings(self, texts: List[str]) -> List[List[float]]
     |      Génère des embeddings pour une liste de textes.
     |
     |      Args:
     |          texts (List[str]): Liste de textes à encoder
     |
     |      Returns:
     |          List[List[float]]: Liste d'embeddings vectoriels
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class EmbeddingProvider(typing.Protocol)
     |  EmbeddingProvider(*args, **kwargs)
     |
     |  Interface pour les fournisseurs d'embeddings.
     |
     |  Method resolution order:
     |      EmbeddingProvider
     |      typing.Protocol
     |      typing.Generic
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__ = _no_init_or_replace_init(self, *args, **kwargs) from typing
     |
     |  get_embedding(self, text: str) -> List[float]
     |      Génère un embedding pour un texte.
     |
     |      Args:
     |          text (str): Texte à encoder
     |
     |      Returns:
     |          List[float]: Embedding vectoriel
     |
     |  get_embeddings(self, texts: List[str]) -> List[List[float]]
     |      Génère des embeddings pour une liste de textes.
     |
     |      Args:
     |          texts (List[str]): Liste de textes à encoder
     |
     |      Returns:
     |          List[List[float]]: Liste d'embeddings vectoriels
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  __subclasshook__ = _proto_hook(other) from typing
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset()
     |
     |  __annotations__ = {}
     |
     |  __non_callable_proto_members__ = set()
     |
     |  __parameters__ = ()
     |
     |  __protocol_attrs__ = {'get_embedding', 'get_embeddings'}
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from typing.Protocol:
     |
     |  __init_subclass__(*args, **kwargs)
     |      Function to initialize subclasses.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from typing.Generic:
     |
     |  __class_getitem__(...)
     |      Parameterizes a generic class.
     |
     |      At least, parameterizing a generic class is the *main* thing this
     |      method does. For example, for some generic class `Foo`, this is called
     |      when we do `Foo[int]` - there, with `cls=Foo` and `params=int`.
     |
     |      However, note that this method is also called when defining generic
     |      classes in the first place with `class Foo[T]: ...`.

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    logger = <Logger mcp.core.embedding_provider (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\mcp\embedding_provider.py


