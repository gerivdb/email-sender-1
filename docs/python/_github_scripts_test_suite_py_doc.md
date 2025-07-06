Help on module test_suite:

NAME
    test_suite

DESCRIPTION
    Jules Bot System Test Suite
    Comprehensive testing for the review and approval workflow

CLASSES
    builtins.object
        JulesBotTestSuite

    class JulesBotTestSuite(builtins.object)
     |  JulesBotTestSuite(config_path: str = None)
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: str = None)
     |      Initialize test suite
     |
     |  cleanup(self) -> None
     |      Clean up temporary directories
     |
     |  run_all_tests(self) -> Dict[str, Any]
     |      Run all test suites
     |
     |  test_configuration_validation(self) -> Dict[str, Any]
     |      Test configuration file validation
     |
     |  test_integration_manager(self) -> Dict[str, Any]
     |      Test the integration manager
     |
     |  test_metrics_collector(self) -> Dict[str, Any]
     |      Test the metrics collection system
     |
     |  test_notification_system(self) -> Dict[str, Any]
     |      Test the notification system
     |
     |  test_quality_assessment_script(self) -> Dict[str, Any]
     |      Test the quality assessment script with various scenarios
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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\.github\scripts\test_suite.py


