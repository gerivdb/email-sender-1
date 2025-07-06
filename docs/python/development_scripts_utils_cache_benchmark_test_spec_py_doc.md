Help on module test_spec:

NAME
    test_spec - Module de sp�cification de test pour le syst�me de cache.

DESCRIPTION
    Ce module d�finit les structures de donn�es et les classes n�cessaires
    pour sp�cifier des tests de performance pour le syst�me de cache.

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

CLASSES
    builtins.object
        CacheTestSpec
    enum.Enum(builtins.object)
        BenchmarkType
        CacheType
        DataDistribution
        OperationType

    class BenchmarkType(enum.Enum)
     |  BenchmarkType(*values)
     |
     |  Types de benchmark.
     |
     |  Method resolution order:
     |      BenchmarkType
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  CONCURRENCY = <BenchmarkType.CONCURRENCY: 'concurrency'>
     |
     |  DURABILITY = <BenchmarkType.DURABILITY: 'durability'>
     |
     |  HIT_RATIO = <BenchmarkType.HIT_RATIO: 'hit_ratio'>
     |
     |  LATENCY = <BenchmarkType.LATENCY: 'latency'>
     |
     |  MEMORY = <BenchmarkType.MEMORY: 'memory'>
     |
     |  MIXED = <BenchmarkType.MIXED: 'mixed'>
     |
     |  RESILIENCE = <BenchmarkType.RESILIENCE: 'resilience'>
     |
     |  THROUGHPUT = <BenchmarkType.THROUGHPUT: 'throughput'>
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from enum.Enum:
     |
     |  name
     |      The name of the Enum member.
     |
     |  value
     |      The value of the Enum member.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class CacheTestSpec(builtins.object)
     |  CacheTestSpec(test_id: str, cache_type: Union[test_spec.CacheType, str], benchmark_type: Union[test_spec.BenchmarkType, str], dataset_size: int, value_size: int, data_distribution: Union[test_spec.DataDistribution, str] = <DataDistribution.UNIFORM: 'uniform'>, operation_mix: Dict[Union[test_spec.OperationType, str], float] = <factory>, concurrency_level: int = 1, duration_seconds: int = 60, expected_hit_ratio: float = 0.7, max_latency_ms: float = 10.0, max_memory_mb: float = 100.0, timeout: int = 300, cache_params: Dict[str, Any] = <factory>, output_dir: str = <factory>) -> None
     |
     |  Sp�cification de test pour le syst�me de cache.
     |
     |  Cette classe d�finit les param�tres d'un test de performance
     |  pour le syst�me de cache.
     |
     |  Methods defined here:
     |
     |  __eq__(self, other)
     |      Return self==value.
     |
     |  __init__(self, test_id: str, cache_type: Union[test_spec.CacheType, str], benchmark_type: Union[test_spec.BenchmarkType, str], dataset_size: int, value_size: int, data_distribution: Union[test_spec.DataDistribution, str] = <DataDistribution.UNIFORM: 'uniform'>, operation_mix: Dict[Union[test_spec.OperationType, str], float] = <factory>, concurrency_level: int = 1, duration_seconds: int = 60, expected_hit_ratio: float = 0.7, max_latency_ms: float = 10.0, max_memory_mb: float = 100.0, timeout: int = 300, cache_params: Dict[str, Any] = <factory>, output_dir: str = <factory>) -> None
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  __post_init__(self)
     |      Initialisation apr�s la cr�ation de l'instance.
     |
     |  __repr__(self)
     |      Return repr(self).
     |
     |  save(self, file_path: Optional[str] = None) -> str
     |      Enregistre la sp�cification de test dans un fichier JSON.
     |
     |      Args:
     |          file_path (str, optional): Chemin du fichier. Si None, utilise le test_id.
     |              Par d�faut: None.
     |
     |      Returns:
     |          str: Chemin du fichier enregistr�.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit la sp�cification de test en dictionnaire.
     |
     |      Returns:
     |          Dict[str, Any]: Dictionnaire repr�sentant la sp�cification de test.
     |
     |  to_json(self) -> str
     |      Convertit la sp�cification de test en cha�ne JSON.
     |
     |      Returns:
     |          str: Cha�ne JSON repr�sentant la sp�cification de test.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'CacheTestSpec'
     |      Cr�e une sp�cification de test � partir d'un dictionnaire.
     |
     |      Args:
     |          data (Dict[str, Any]): Dictionnaire repr�sentant la sp�cification de test.
     |
     |      Returns:
     |          CacheTestSpec: Sp�cification de test.
     |
     |  from_json(json_str: str) -> 'CacheTestSpec'
     |      Cr�e une sp�cification de test � partir d'une cha�ne JSON.
     |
     |      Args:
     |          json_str (str): Cha�ne JSON repr�sentant la sp�cification de test.
     |
     |      Returns:
     |          CacheTestSpec: Sp�cification de test.
     |
     |  load(file_path: str) -> 'CacheTestSpec'
     |      Charge une sp�cification de test � partir d'un fichier JSON.
     |
     |      Args:
     |          file_path (str): Chemin du fichier.
     |
     |      Returns:
     |          CacheTestSpec: Sp�cification de test.
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties defined here:
     |
     |  test_script
     |      G�n�re un script de test bas� sur les param�tres.
     |
     |      Returns:
     |          str: Script de test.
     |
     |  unique_id
     |      G�n�re un identifiant unique pour la sp�cification de test.
     |
     |      Returns:
     |          str: Identifiant unique.
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
     |  __annotations__ = {'benchmark_type': typing.Union[test_spec.BenchmarkT...
     |
     |  __dataclass_fields__ = {'benchmark_type': Field(name='benchmark_type',...
     |
     |  __dataclass_params__ = _DataclassParams(init=True,repr=True,eq=True,or...
     |
     |  __hash__ = None
     |
     |  __match_args__ = ('test_id', 'cache_type', 'benchmark_type', 'dataset_...
     |
     |  concurrency_level = 1
     |
     |  data_distribution = <DataDistribution.UNIFORM: 'uniform'>
     |
     |  duration_seconds = 60
     |
     |  expected_hit_ratio = 0.7
     |
     |  max_latency_ms = 10.0
     |
     |  max_memory_mb = 100.0
     |
     |  timeout = 300

    class CacheType(enum.Enum)
     |  CacheType(*values)
     |
     |  Types de cache support�s.
     |
     |  Method resolution order:
     |      CacheType
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  ARC = <CacheType.ARC: 'arc'>
     |
     |  ASYNC = <CacheType.ASYNC: 'async'>
     |
     |  BATCH = <CacheType.BATCH: 'batch'>
     |
     |  COMPOSITE = <CacheType.COMPOSITE: 'composite'>
     |
     |  FIFO = <CacheType.FIFO: 'fifo'>
     |
     |  LFU = <CacheType.LFU: 'lfu'>
     |
     |  LRU = <CacheType.LRU: 'lru'>
     |
     |  SHARDED = <CacheType.SHARDED: 'sharded'>
     |
     |  THREAD_SAFE = <CacheType.THREAD_SAFE: 'thread_safe'>
     |
     |  TTL = <CacheType.TTL: 'ttl'>
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from enum.Enum:
     |
     |  name
     |      The name of the Enum member.
     |
     |  value
     |      The value of the Enum member.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class DataDistribution(enum.Enum)
     |  DataDistribution(*values)
     |
     |  Distributions de donn�es pour les tests.
     |
     |  Method resolution order:
     |      DataDistribution
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  NORMAL = <DataDistribution.NORMAL: 'normal'>
     |
     |  REAL_WORLD = <DataDistribution.REAL_WORLD: 'real_world'>
     |
     |  SEQUENTIAL = <DataDistribution.SEQUENTIAL: 'sequential'>
     |
     |  UNIFORM = <DataDistribution.UNIFORM: 'uniform'>
     |
     |  ZIPF = <DataDistribution.ZIPF: 'zipf'>
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from enum.Enum:
     |
     |  name
     |      The name of the Enum member.
     |
     |  value
     |      The value of the Enum member.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class OperationType(enum.Enum)
     |  OperationType(*values)
     |
     |  Types d'op�rations de cache.
     |
     |  Method resolution order:
     |      OperationType
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  CLEAR = <OperationType.CLEAR: 'clear'>
     |
     |  DELETE = <OperationType.DELETE: 'delete'>
     |
     |  DELETE_MANY = <OperationType.DELETE_MANY: 'delete_many'>
     |
     |  GET = <OperationType.GET: 'get'>
     |
     |  GET_MANY = <OperationType.GET_MANY: 'get_many'>
     |
     |  SET = <OperationType.SET: 'set'>
     |
     |  SET_MANY = <OperationType.SET_MANY: 'set_many'>
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from enum.Enum:
     |
     |  name
     |      The name of the Enum member.
     |
     |  value
     |      The value of the Enum member.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

FUNCTIONS
    create_standard_test_suite() -> List[test_spec.CacheTestSpec]
        Cr�e une suite de tests standard pour le syst�me de cache.

        Returns:
            List[CacheTestSpec]: Liste de sp�cifications de test.

    create_test_spec(test_id: str, cache_type: Union[test_spec.CacheType, str], benchmark_type: Union[test_spec.BenchmarkType, str], dataset_size: int, value_size: int, **kwargs) -> test_spec.CacheTestSpec
        Cr�e une sp�cification de test pour le syst�me de cache.

        Args:
            test_id (str): Identifiant unique du test.
            cache_type (Union[CacheType, str]): Type de cache � tester.
            benchmark_type (Union[BenchmarkType, str]): Type de benchmark � ex�cuter.
            dataset_size (int): Taille du jeu de donn�es (nombre d'�l�ments).
            value_size (int): Taille moyenne des valeurs en octets.
            **kwargs: Param�tres suppl�mentaires pour la sp�cification de test.

        Returns:
            CacheTestSpec: Sp�cification de test.

DATA
    Callable = typing.Callable
        Deprecated alias to collections.abc.Callable.

        Callable[[int], str] signifies a function that takes a single
        parameter of type int and returns a str.

        The subscription syntax must always be used with exactly two
        values: the argument list and the return type.
        The argument list must be a list of types, a ParamSpec,
        Concatenate or ellipsis. The return type must be a single type.

        There is no syntax to indicate optional or keyword arguments;
        such function types are rarely used as callback types.

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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\utils\cache\benchmark\test_spec.py


