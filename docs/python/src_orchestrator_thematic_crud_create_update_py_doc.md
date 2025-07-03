Help on module create_update:

NAME
    create_update - Module de cr�ation et mise � jour th�matique.

DESCRIPTION
    Ce module fournit des fonctionnalit�s pour cr�er et mettre � jour des �l�ments
    de roadmap avec attribution th�matique automatique.

CLASSES
    builtins.object
        ThematicCreateUpdate

    class ThematicCreateUpdate(builtins.object)
     |  ThematicCreateUpdate(storage_path: str, themes_config_path: Optional[str] = None, use_advanced_attribution: bool = True, history_path: Optional[str] = None, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |
     |  Classe pour la cr�ation et mise � jour th�matique.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, themes_config_path: Optional[str] = None, use_advanced_attribution: bool = True, history_path: Optional[str] = None, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |      Initialise le gestionnaire de cr�ation et mise � jour th�matique.
     |
     |      Args:
     |          storage_path: Chemin vers le r�pertoire de stockage des donn�es
     |          themes_config_path: Chemin vers le fichier de configuration des th�mes (optionnel)
     |          use_advanced_attribution: Utiliser l'attribution th�matique avanc�e (d�faut: True)
     |          history_path: Chemin vers le fichier d'historique (optionnel)
     |          learning_rate: Taux d'apprentissage pour l'adaptation (d�faut: 0.1)
     |          context_weight: Poids du contexte dans l'attribution (d�faut: 0.3)
     |          user_feedback_weight: Poids du retour utilisateur (d�faut: 0.5)
     |
     |  add_user_feedback(self, item_id: str, user_themes: Dict[str, float]) -> Optional[Dict[str, Any]]
     |      Ajoute un retour utilisateur sur l'attribution th�matique.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          user_themes: Th�mes attribu�s par l'utilisateur avec leurs scores
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
     |
     |  analyze_theme_evolution(self, item_id: str) -> Optional[Dict[str, Any]]
     |      Analyse l'�volution des th�mes d'un �l�ment au fil du temps.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |
     |      Returns:
     |          Analyse de l'�volution th�matique ou None si l'�l�ment n'existe pas
     |
     |  create_item(self, content: str, metadata: Dict[str, Any], context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
     |      Cr�e un nouvel �l�ment avec attribution th�matique automatique.
     |
     |      Args:
     |          content: Contenu de l'�l�ment
     |          metadata: M�tadonn�es de l'�l�ment
     |          context: Contexte d'attribution (optionnel)
     |
     |      Returns:
     |          �l�ment cr�� avec ses m�tadonn�es enrichies
     |
     |  extract_and_update_theme(self, source_item_id: str, target_item_id: str, theme: str) -> Optional[Dict[str, Any]]
     |      Extrait les sections d'un th�me d'un �l�ment source et les applique � un �l�ment cible.
     |
     |      Args:
     |          source_item_id: Identifiant de l'�l�ment source
     |          target_item_id: Identifiant de l'�l�ment cible
     |          theme: Th�me � extraire et appliquer
     |
     |      Returns:
     |          �l�ment cible mis � jour ou None si l'un des �l�ments n'existe pas
     |
     |  merge_theme_content(self, item_id: str, theme: str, content_to_merge: str) -> Optional[Dict[str, Any]]
     |      Fusionne du contenu dans les sections d'un �l�ment correspondant � un th�me.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � mettre � jour
     |          theme: Th�me des sections � mettre � jour
     |          content_to_merge: Contenu � fusionner
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
     |
     |  suggest_theme_corrections(self, item_id: str, expected_themes: Optional[List[str]] = None) -> Optional[Dict[str, Any]]
     |      Sugg�re des corrections th�matiques pour un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          expected_themes: Th�mes attendus (optionnel)
     |
     |      Returns:
     |          Suggestions de corrections th�matiques ou None si l'�l�ment n'existe pas
     |
     |  update_item(self, item_id: str, content: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, context: Optional[Dict[str, Any]] = None, reattribute_themes: bool = True, detect_changes: bool = True) -> Optional[Dict[str, Any]]
     |      Met � jour un �l�ment existant avec d�tection des changements th�matiques.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � mettre � jour
     |          content: Nouveau contenu (optionnel)
     |          metadata: Nouvelles m�tadonn�es (optionnel)
     |          context: Contexte d'attribution (optionnel)
     |          reattribute_themes: R�attribuer les th�mes si le contenu a chang� (d�faut: True)
     |          detect_changes: D�tecter les changements th�matiques (d�faut: True)
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
     |
     |  update_multiple_themes(self, item_id: str, theme_updates: Dict[str, str]) -> Optional[Dict[str, Any]]
     |      Met � jour plusieurs th�mes d'un �l�ment en une seule op�ration.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � mettre � jour
     |          theme_updates: Dictionnaire des th�mes � mettre � jour avec leur nouveau contenu
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
     |
     |  update_theme_sections(self, item_id: str, theme: str, new_content: str) -> Optional[Dict[str, Any]]
     |      Met � jour les sections d'un �l�ment correspondant � un th�me sp�cifique.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � mettre � jour
     |          theme: Th�me des sections � mettre � jour
     |          new_content: Nouveau contenu pour les sections
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
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

    Set = typing.Set
        A generic version of set.

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
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\create_update.py


