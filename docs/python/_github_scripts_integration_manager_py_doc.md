Help on module integration_manager:

NAME
    integration_manager

DESCRIPTION
    Jules Bot Integration Manager
    Handles the actual merging of approved Jules Bot contributions to dev branch

CLASSES
    builtins.object
        IntegrationManager

    class IntegrationManager(builtins.object)
     |  IntegrationManager(config_path: str = '.github/jules-config.yml')
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: str = '.github/jules-config.yml')
     |      Initialize integration manager with configuration
     |
     |  cleanup_branches(self, integration_branch: str, source_branch: str) -> None
     |      Clean up temporary branches after successful merge
     |
     |  create_integration_branch(self, source_branch: str, target_branch: str = 'dev') -> str
     |      Create an integration branch for safe merging
     |
     |  finalize_merge(self, integration_branch: str, target_branch: str = 'dev') -> bool
     |      Finalize the merge by pushing to target branch
     |
     |  integrate_contribution(self, source_branch: str, target_branch: str = 'dev', strategy: str = 'squash') -> Dict[str, Any]
     |      Main integration workflow
     |
     |  merge_with_strategy(self, source_branch: str, integration_branch: str, strategy: str = 'squash') -> bool
     |      Merge source branch into integration branch with specified strategy
     |
     |  run_integration_tests(self, integration_branch: str) -> bool
     |      Run integration tests on the merged code
     |
     |  update_contextual_memory(self, source_branch: str, merge_result: Dict[str, Any]) -> None
     |      Update Jules Bot's contextual memory with merge results
     |
     |  validate_branch_state(self, source_branch: str, target_branch: str = 'dev') -> bool
     |      Validate that branches are in a good state for merging
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

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\.github\scripts\integration_manager.py


