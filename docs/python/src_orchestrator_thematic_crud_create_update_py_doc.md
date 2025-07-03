Help on module create_update:

NAME
    create_update - Module de création et mise à jour thématique.

DESCRIPTION
    Ce module fournit des fonctionnalités pour créer et mettre à jour des éléments
    de roadmap avec attribution thématique automatique.

CLASSES
    builtins.object
        ThematicCreateUpdate

    class ThematicCreateUpdate(builtins.object)
     |  ThematicCreateUpdate(storage_path: str, themes_config_path: Optional[str] = None, use_advanced_attribution: bool = True, history_path: Optional[str] = None, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |
     |  Classe pour la création et mise à jour thématique.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, themes_config_path: Optional[str] = None, use_advanced_attribution: bool = True, history_path: Optional[str] = None, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |      Initialise le gestionnaire de création et mise à jour thématique.
     |
     |      Args:
     |          storage_path: Chemin vers le répertoire de stockage des données
     |          themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
     |          use_advanced_attribution: Utiliser l'attribution thématique avancée (défaut: True)
     |          history_path: Chemin vers le fichier d'historique (optionnel)
     |          learning_rate: Taux d'apprentissage pour l'adaptation (défaut: 0.1)
     |          context_weight: Poids du contexte dans l'attribution (défaut: 0.3)
     |          user_feedback_weight: Poids du retour utilisateur (défaut: 0.5)
     |
     |  add_user_feedback(self, item_id: str, user_themes: Dict[str, float]) -> Optional[Dict[str, Any]]
     |      Ajoute un retour utilisateur sur l'attribution thématique.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          user_themes: Thèmes attribués par l'utilisateur avec leurs scores
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  analyze_theme_evolution(self, item_id: str) -> Optional[Dict[str, Any]]
     |      Analyse l'évolution des thèmes d'un élément au fil du temps.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |
     |      Returns:
     |          Analyse de l'évolution thématique ou None si l'élément n'existe pas
     |
     |  create_item(self, content: str, metadata: Dict[str, Any], context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
     |      Crée un nouvel élément avec attribution thématique automatique.
     |
     |      Args:
     |          content: Contenu de l'élément
     |          metadata: Métadonnées de l'élément
     |          context: Contexte d'attribution (optionnel)
     |
     |      Returns:
     |          Élément créé avec ses métadonnées enrichies
     |
     |  extract_and_update_theme(self, source_item_id: str, target_item_id: str, theme: str) -> Optional[Dict[str, Any]]
     |      Extrait les sections d'un thème d'un élément source et les applique à un élément cible.
     |
     |      Args:
     |          source_item_id: Identifiant de l'élément source
     |          target_item_id: Identifiant de l'élément cible
     |          theme: Thème à extraire et appliquer
     |
     |      Returns:
     |          Élément cible mis à jour ou None si l'un des éléments n'existe pas
     |
     |  merge_theme_content(self, item_id: str, theme: str, content_to_merge: str) -> Optional[Dict[str, Any]]
     |      Fusionne du contenu dans les sections d'un élément correspondant à un thème.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          theme: Thème des sections à mettre à jour
     |          content_to_merge: Contenu à fusionner
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  suggest_theme_corrections(self, item_id: str, expected_themes: Optional[List[str]] = None) -> Optional[Dict[str, Any]]
     |      Suggère des corrections thématiques pour un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          expected_themes: Thèmes attendus (optionnel)
     |
     |      Returns:
     |          Suggestions de corrections thématiques ou None si l'élément n'existe pas
     |
     |  update_item(self, item_id: str, content: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, context: Optional[Dict[str, Any]] = None, reattribute_themes: bool = True, detect_changes: bool = True) -> Optional[Dict[str, Any]]
     |      Met à jour un élément existant avec détection des changements thématiques.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          content: Nouveau contenu (optionnel)
     |          metadata: Nouvelles métadonnées (optionnel)
     |          context: Contexte d'attribution (optionnel)
     |          reattribute_themes: Réattribuer les thèmes si le contenu a changé (défaut: True)
     |          detect_changes: Détecter les changements thématiques (défaut: True)
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  update_multiple_themes(self, item_id: str, theme_updates: Dict[str, str]) -> Optional[Dict[str, Any]]
     |      Met à jour plusieurs thèmes d'un élément en une seule opération.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          theme_updates: Dictionnaire des thèmes à mettre à jour avec leur nouveau contenu
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  update_theme_sections(self, item_id: str, theme: str, new_content: str) -> Optional[Dict[str, Any]]
     |      Met à jour les sections d'un élément correspondant à un thème spécifique.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          theme: Thème des sections à mettre à jour
     |          new_content: Nouveau contenu pour les sections
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
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


