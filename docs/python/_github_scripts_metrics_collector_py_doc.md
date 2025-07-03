Help on module metrics_collector:

NAME
    metrics_collector

DESCRIPTION
    Jules Bot Metrics and Monitoring System
    Tracks performance, quality trends, and system health

CLASSES
    builtins.object
        MetricsCollector

    class MetricsCollector(builtins.object)
     |  MetricsCollector(config_path: str = '.github/jules-config.yml', db_path: str = '.github/jules-metrics.db')
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: str = '.github/jules-config.yml', db_path: str = '.github/jules-metrics.db')
     |      Initialize metrics collector
     |
     |  export_metrics(self, output_file: str, format: str = 'json', days: int = 30) -> None
     |      Export metrics to file
     |
     |  generate_dashboard_data(self, days: int = 30) -> Dict[str, Any]
     |      Generate comprehensive dashboard data
     |
     |  get_integration_metrics(self, days: int = 30) -> Dict[str, Any]
     |      Get integration performance metrics
     |
     |  get_quality_trends(self, days: int = 30) -> Dict[str, Any]
     |      Get quality assessment trends over the specified period
     |
     |  get_review_performance(self, days: int = 30) -> Dict[str, Any]
     |      Get review performance metrics
     |
     |  get_system_health(self) -> Dict[str, Any]
     |      Get current system health metrics
     |
     |  record_integration_event(self, integration_data: Dict[str, Any]) -> None
     |      Record an integration event in the database
     |
     |  record_quality_assessment(self, assessment_data: Dict[str, Any]) -> None
     |      Record a quality assessment in the database
     |
     |  record_review_event(self, event_data: Dict[str, Any]) -> None
     |      Record a review event in the database
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FUNCTIONS
    main()

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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\.github\scripts\metrics_collector.py


