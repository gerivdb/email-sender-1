Help on module quality_assessment:

NAME
    quality_assessment

DESCRIPTION
    Jules Bot Quality Assessment Script
    Analyzes pull requests from jules-google/* branches for automated quality scoring

CLASSES
    builtins.object
        QualityAssessment

    class QualityAssessment(builtins.object)
     |  QualityAssessment(config_path: str = '.github/jules-config.yml')
     |
     |  Methods defined here:
     |
     |  __init__(self, config_path: str = '.github/jules-config.yml')
     |      Initialize quality assessment with configuration
     |
     |  assess_commit_quality(self) -> float
     |      Assess quality of commit messages and commit count
     |
     |  assess_configuration_safety(self, files: List[str]) -> float
     |      Assess safety of configuration file changes
     |
     |  assess_documentation(self, files: List[str]) -> float
     |      Assess documentation completeness
     |
     |  assess_file_count(self, files: List[str]) -> float
     |      Assess score based on number of changed files
     |
     |  assess_file_sizes(self, files: List[str]) -> float
     |      Assess score based on file sizes
     |
     |  assess_security(self, files: List[str]) -> float
     |      Assess security risks in changed files
     |
     |  calculate_overall_score(self, files: List[str]) -> Tuple[int, str, Dict]
     |      Calculate overall quality score and determine review type
     |
     |  get_changed_files(self, base_ref: str = 'origin/dev') -> List[str]
     |      Get list of changed files in the current branch
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

    Tuple = typing.Tuple
        Deprecated alias to builtins.tuple.

        Tuple[X, Y] is the cross-product type of X and Y.

        Example: Tuple[T1, T2] is a tuple of two elements corresponding
        to type variables T1 and T2.  Tuple[int, float, str] is a tuple
        of an int, a float and a string.

        To specify a variable-length tuple of homogeneous type, use Tuple[T, ...].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\.github\scripts\quality_assessment.py


