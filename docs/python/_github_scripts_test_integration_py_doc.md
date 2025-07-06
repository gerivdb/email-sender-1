Help on module test_integration:

NAME
    test_integration

DESCRIPTION
    Jules Bot Integration Test
    End-to-end test of the complete Jules Bot review and approval workflow

CLASSES
    builtins.object
        JulesIntegrationTest

    class JulesIntegrationTest(builtins.object)
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialize integration test
     |
     |  cleanup(self)
     |      Clean up test environment
     |
     |  create_jules_contribution(self, scenario: str) -> str
     |      Create a Jules Bot contribution branch with specified scenario
     |
     |  run_all_scenarios(self) -> Dict[str, Any]
     |      Run all integration test scenarios
     |
     |  run_quality_assessment(self, branch_name: str) -> Dict[str, Any]
     |      Run quality assessment on the contribution
     |
     |  setup_test_environment(self) -> str
     |      Create a test repository with all necessary files
     |
     |  test_scenario(self, scenario: str) -> Dict[str, Any]
     |      Test a complete scenario
     |
     |  validate_scenario_results(self, scenario: str, score: float, review_type: str, issues: List[Dict]) -> Dict[str, Any]
     |      Validate that results match expected outcomes for scenario
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
        Main integration test runner

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\.github\scripts\test_integration.py


