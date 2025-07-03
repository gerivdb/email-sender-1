Help on module test_runner:

NAME
    test_runner

DESCRIPTION
    Jules Bot System Test Runner
    Simplified test runner to validate the system components

CLASSES
    builtins.object
        JulesTestRunner

    class JulesTestRunner(builtins.object)
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialize test runner
     |
     |  run_all_tests(self) -> Dict[str, Any]
     |      Run all tests and return summary
     |
     |  test_config_validation(self) -> Dict[str, Any]
     |      Test configuration file validation
     |
     |  test_documentation(self) -> Dict[str, Any]
     |      Test documentation files
     |
     |  test_pr_templates(self) -> Dict[str, Any]
     |      Test PR template files
     |
     |  test_quality_assessment_basic(self) -> Dict[str, Any]
     |      Basic test of quality assessment script
     |
     |  test_script_imports(self) -> Dict[str, Any]
     |      Test that all Python scripts can be imported/parsed
     |
     |  test_workflow_files(self) -> Dict[str, Any]
     |      Test GitHub Actions workflow files
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
        Main test runner

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\.github\scripts\test_runner.py


