Help on module advanced_attribution:

NAME
    advanced_attribution - Module d'attribution th�matique avanc�e.

DESCRIPTION
    Ce module fournit des fonctionnalit�s avanc�es pour l'attribution automatique
    de th�mes, incluant l'apprentissage continu, l'analyse contextuelle et
    l'adaptation aux pr�f�rences utilisateur.

CLASSES
    builtins.object
        AdvancedThemeAttributor
        ThematicAttributionHistory

    class AdvancedThemeAttributor(builtins.object)
     |  AdvancedThemeAttributor(themes_config_path: Optional[str] = None, history_path: Optional[str] = None, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |
     |  Classe pour l'attribution th�matique avanc�e.
     |
     |  Methods defined here:
     |
     |  __init__(self, themes_config_path: Optional[str] = None, history_path: Optional[str] = None, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |      Initialise l'attributeur de th�mes avanc�.
     |
     |      Args:
     |          themes_config_path: Chemin vers le fichier de configuration des th�mes (optionnel)
     |          history_path: Chemin vers le fichier d'historique (optionnel)
     |          learning_rate: Taux d'apprentissage pour l'adaptation (d�faut: 0.1)
     |          context_weight: Poids du contexte dans l'attribution (d�faut: 0.3)
     |          user_feedback_weight: Poids du retour utilisateur (d�faut: 0.5)
     |
     |  add_user_feedback(self, item_id: str, user_themes: Dict[str, float]) -> None
     |      Ajoute un retour utilisateur sur l'attribution th�matique.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          user_themes: Th�mes attribu�s par l'utilisateur avec leurs scores
     |
     |  attribute_theme(self, content: str, metadata: Optional[Dict[str, Any]] = None, context: Optional[Dict[str, Any]] = None) -> Dict[str, float]
     |      Attribue des th�mes � un contenu avec analyse contextuelle et apprentissage.
     |
     |      Args:
     |          content: Contenu textuel � analyser
     |          metadata: M�tadonn�es associ�es au contenu (optionnel)
     |          context: Contexte d'attribution (optionnel)
     |
     |      Returns:
     |          Dictionnaire des th�mes attribu�s avec leur score de confiance
     |
     |  get_keyword_statistics(self) -> Dict[str, Any]
     |      R�cup�re des statistiques sur les mots-cl�s.
     |
     |      Returns:
     |          Statistiques sur les mots-cl�s
     |
     |  get_theme_statistics(self) -> Dict[str, Any]
     |      R�cup�re des statistiques sur les th�mes.
     |
     |      Returns:
     |          Statistiques sur les th�mes
     |
     |  get_user_feedback_statistics(self) -> Dict[str, Any]
     |      R�cup�re des statistiques sur les retours utilisateur.
     |
     |      Returns:
     |          Statistiques sur les retours utilisateur
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class ThematicAttributionHistory(builtins.object)
     |  ThematicAttributionHistory(history_path: Optional[str] = None)
     |
     |  Classe pour g�rer l'historique des attributions th�matiques.
     |
     |  Methods defined here:
     |
     |  __init__(self, history_path: Optional[str] = None)
     |      Initialise le gestionnaire d'historique d'attributions.
     |
     |      Args:
     |          history_path: Chemin vers le fichier d'historique (optionnel)
     |
     |  add_attribution(self, item_id: str, content: str, themes: Dict[str, float], metadata: Optional[Dict[str, Any]] = None) -> None
     |      Ajoute une attribution � l'historique.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          content: Contenu de l'�l�ment
     |          themes: Th�mes attribu�s avec leurs scores
     |          metadata: M�tadonn�es de l'�l�ment (optionnel)
     |
     |  add_user_feedback(self, item_id: str, user_themes: Dict[str, float]) -> None
     |      Ajoute un retour utilisateur sur l'attribution th�matique.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          user_themes: Th�mes attribu�s par l'utilisateur avec leurs scores
     |
     |  get_keyword_statistics(self) -> Dict[str, Any]
     |      R�cup�re des statistiques sur les mots-cl�s.
     |
     |      Returns:
     |          Statistiques sur les mots-cl�s
     |
     |  get_theme_statistics(self) -> Dict[str, Any]
     |      R�cup�re des statistiques sur les th�mes.
     |
     |      Returns:
     |          Statistiques sur les th�mes
     |
     |  get_user_feedback_statistics(self) -> Dict[str, Any]
     |      R�cup�re des statistiques sur les retours utilisateur.
     |
     |      Returns:
     |          Statistiques sur les retours utilisateur
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

    SKLEARN_AVAILABLE = True
    Set = typing.Set
        A generic version of set.

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

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\advanced_attribution.py


