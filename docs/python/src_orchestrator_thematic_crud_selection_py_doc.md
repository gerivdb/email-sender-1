Help on module selection:

NAME
    selection - Module de sélection pour le système CRUD thématique.

DESCRIPTION
    Ce module fournit des fonctionnalités pour sélectionner des éléments
    selon différents critères pour les opérations d'archivage et de suppression.

CLASSES
    builtins.object
        ThematicSelector

    class ThematicSelector(builtins.object)
     |  ThematicSelector(storage_path: str)
     |
     |  Classe pour la sélection d'éléments selon différents critères.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str)
     |      Initialise le sélecteur thématique.
     |
     |      Args:
     |          storage_path: Chemin vers le répertoire de stockage des données
     |
     |  combine_selections(self, selections: List[List[str]], mode: str = 'union') -> List[str]
     |      Combine plusieurs sélections selon un mode spécifié.
     |
     |      Args:
     |          selections: Liste de listes d'identifiants d'éléments
     |          mode: Mode de combinaison ("union", "intersection", "difference")
     |
     |      Returns:
     |          Liste des identifiants des éléments résultant de la combinaison
     |
     |  select_by_content(self, content_filter: str, case_sensitive: bool = False) -> List[str]
     |      Sélectionne les éléments selon leur contenu.
     |
     |      Args:
     |          content_filter: Texte à rechercher dans le contenu
     |          case_sensitive: Si True, la recherche est sensible à la casse
     |
     |      Returns:
     |          Liste des identifiants des éléments correspondant aux critères
     |
     |  select_by_custom_filter(self, filter_func: Callable[[Dict[str, Any]], bool]) -> List[str]
     |      Sélectionne les éléments selon une fonction de filtrage personnalisée.
     |
     |      Args:
     |          filter_func: Fonction qui prend un élément et retourne True si l'élément doit être sélectionné
     |
     |      Returns:
     |          Liste des identifiants des éléments correspondant aux critères
     |
     |  select_by_date_range(self, start_date: Optional[datetime.datetime] = None, end_date: Optional[datetime.datetime] = None, date_field: str = 'created_at') -> List[str]
     |      Sélectionne les éléments selon une plage de dates.
     |
     |      Args:
     |          start_date: Date de début de la plage (optionnel)
     |          end_date: Date de fin de la plage (optionnel)
     |          date_field: Champ de date à utiliser pour la sélection
     |
     |      Returns:
     |          Liste des identifiants des éléments correspondant aux critères
     |
     |  select_by_id(self, item_id: str) -> List[str]
     |      Sélectionne un élément par son identifiant.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à sélectionner
     |
     |      Returns:
     |          Liste contenant l'identifiant de l'élément s'il existe, sinon liste vide
     |
     |  select_by_ids(self, item_ids: List[str]) -> List[str]
     |      Sélectionne des éléments par leurs identifiants.
     |
     |      Args:
     |          item_ids: Liste d'identifiants des éléments à sélectionner
     |
     |      Returns:
     |          Liste des identifiants des éléments qui existent
     |
     |  select_by_metadata(self, metadata_filter: Dict[str, Any]) -> List[str]
     |      Sélectionne les éléments selon des critères de métadonnées.
     |
     |      Args:
     |          metadata_filter: Dictionnaire de filtres de métadonnées
     |
     |      Returns:
     |          Liste des identifiants des éléments correspondant aux critères
     |
     |  select_by_regex(self, pattern: str, field: str = 'content') -> List[str]
     |      Sélectionne les éléments selon une expression régulière.
     |
     |      Args:
     |          pattern: Expression régulière à appliquer
     |          field: Champ sur lequel appliquer l'expression régulière
     |
     |      Returns:
     |          Liste des identifiants des éléments correspondant aux critères
     |
     |  select_by_theme(self, theme: str) -> List[str]
     |      Sélectionne tous les éléments d'un thème.
     |
     |      Args:
     |          theme: Thème des éléments à sélectionner
     |
     |      Returns:
     |          Liste des identifiants des éléments du thème
     |
     |  select_by_theme_exclusivity(self, theme: str, exclusivity_threshold: float = 0.8) -> List[str]
     |      Sélectionne les éléments qui appartiennent principalement au thème spécifié.
     |
     |      Args:
     |          theme: Thème principal
     |          exclusivity_threshold: Seuil d'exclusivité (0.0 à 1.0)
     |
     |      Returns:
     |          Liste des identifiants des éléments sélectionnés
     |
     |  select_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True) -> List[str]
     |      Sélectionne les éléments d'un thème et optionnellement de ses sous-thèmes.
     |
     |      Args:
     |          theme: Thème principal
     |          include_subthemes: Si True, inclut les sous-thèmes
     |
     |      Returns:
     |          Liste des identifiants des éléments sélectionnés
     |
     |  select_by_theme_overlap(self, themes: List[str], min_overlap: int = 2) -> List[str]
     |      Sélectionne les éléments qui appartiennent à plusieurs thèmes spécifiés.
     |
     |      Args:
     |          themes: Liste des thèmes à rechercher
     |          min_overlap: Nombre minimum de thèmes auxquels un élément doit appartenir
     |
     |      Returns:
     |          Liste des identifiants des éléments sélectionnés
     |
     |  select_by_theme_weight(self, theme: str, min_weight: float = 0.5) -> List[str]
     |      Sélectionne les éléments d'un thème avec un poids minimum.
     |
     |      Args:
     |          theme: Thème à rechercher
     |          min_weight: Poids minimum du thème (0.0 à 1.0)
     |
     |      Returns:
     |          Liste des identifiants des éléments sélectionnés
     |
     |  select_by_themes(self, themes: List[str]) -> List[str]
     |      Sélectionne tous les éléments de plusieurs thèmes.
     |
     |      Args:
     |          themes: Liste des thèmes des éléments à sélectionner
     |
     |      Returns:
     |          Liste des identifiants des éléments des thèmes
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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\selection.py


