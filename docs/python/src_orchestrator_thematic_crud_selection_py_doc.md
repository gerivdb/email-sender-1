Help on module selection:

NAME
    selection - Module de s�lection pour le syst�me CRUD th�matique.

DESCRIPTION
    Ce module fournit des fonctionnalit�s pour s�lectionner des �l�ments
    selon diff�rents crit�res pour les op�rations d'archivage et de suppression.

CLASSES
    builtins.object
        ThematicSelector

    class ThematicSelector(builtins.object)
     |  ThematicSelector(storage_path: str)
     |
     |  Classe pour la s�lection d'�l�ments selon diff�rents crit�res.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str)
     |      Initialise le s�lecteur th�matique.
     |
     |      Args:
     |          storage_path: Chemin vers le r�pertoire de stockage des donn�es
     |
     |  combine_selections(self, selections: List[List[str]], mode: str = 'union') -> List[str]
     |      Combine plusieurs s�lections selon un mode sp�cifi�.
     |
     |      Args:
     |          selections: Liste de listes d'identifiants d'�l�ments
     |          mode: Mode de combinaison ("union", "intersection", "difference")
     |
     |      Returns:
     |          Liste des identifiants des �l�ments r�sultant de la combinaison
     |
     |  select_by_content(self, content_filter: str, case_sensitive: bool = False) -> List[str]
     |      S�lectionne les �l�ments selon leur contenu.
     |
     |      Args:
     |          content_filter: Texte � rechercher dans le contenu
     |          case_sensitive: Si True, la recherche est sensible � la casse
     |
     |      Returns:
     |          Liste des identifiants des �l�ments correspondant aux crit�res
     |
     |  select_by_custom_filter(self, filter_func: Callable[[Dict[str, Any]], bool]) -> List[str]
     |      S�lectionne les �l�ments selon une fonction de filtrage personnalis�e.
     |
     |      Args:
     |          filter_func: Fonction qui prend un �l�ment et retourne True si l'�l�ment doit �tre s�lectionn�
     |
     |      Returns:
     |          Liste des identifiants des �l�ments correspondant aux crit�res
     |
     |  select_by_date_range(self, start_date: Optional[datetime.datetime] = None, end_date: Optional[datetime.datetime] = None, date_field: str = 'created_at') -> List[str]
     |      S�lectionne les �l�ments selon une plage de dates.
     |
     |      Args:
     |          start_date: Date de d�but de la plage (optionnel)
     |          end_date: Date de fin de la plage (optionnel)
     |          date_field: Champ de date � utiliser pour la s�lection
     |
     |      Returns:
     |          Liste des identifiants des �l�ments correspondant aux crit�res
     |
     |  select_by_id(self, item_id: str) -> List[str]
     |      S�lectionne un �l�ment par son identifiant.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � s�lectionner
     |
     |      Returns:
     |          Liste contenant l'identifiant de l'�l�ment s'il existe, sinon liste vide
     |
     |  select_by_ids(self, item_ids: List[str]) -> List[str]
     |      S�lectionne des �l�ments par leurs identifiants.
     |
     |      Args:
     |          item_ids: Liste d'identifiants des �l�ments � s�lectionner
     |
     |      Returns:
     |          Liste des identifiants des �l�ments qui existent
     |
     |  select_by_metadata(self, metadata_filter: Dict[str, Any]) -> List[str]
     |      S�lectionne les �l�ments selon des crit�res de m�tadonn�es.
     |
     |      Args:
     |          metadata_filter: Dictionnaire de filtres de m�tadonn�es
     |
     |      Returns:
     |          Liste des identifiants des �l�ments correspondant aux crit�res
     |
     |  select_by_regex(self, pattern: str, field: str = 'content') -> List[str]
     |      S�lectionne les �l�ments selon une expression r�guli�re.
     |
     |      Args:
     |          pattern: Expression r�guli�re � appliquer
     |          field: Champ sur lequel appliquer l'expression r�guli�re
     |
     |      Returns:
     |          Liste des identifiants des �l�ments correspondant aux crit�res
     |
     |  select_by_theme(self, theme: str) -> List[str]
     |      S�lectionne tous les �l�ments d'un th�me.
     |
     |      Args:
     |          theme: Th�me des �l�ments � s�lectionner
     |
     |      Returns:
     |          Liste des identifiants des �l�ments du th�me
     |
     |  select_by_theme_exclusivity(self, theme: str, exclusivity_threshold: float = 0.8) -> List[str]
     |      S�lectionne les �l�ments qui appartiennent principalement au th�me sp�cifi�.
     |
     |      Args:
     |          theme: Th�me principal
     |          exclusivity_threshold: Seuil d'exclusivit� (0.0 � 1.0)
     |
     |      Returns:
     |          Liste des identifiants des �l�ments s�lectionn�s
     |
     |  select_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True) -> List[str]
     |      S�lectionne les �l�ments d'un th�me et optionnellement de ses sous-th�mes.
     |
     |      Args:
     |          theme: Th�me principal
     |          include_subthemes: Si True, inclut les sous-th�mes
     |
     |      Returns:
     |          Liste des identifiants des �l�ments s�lectionn�s
     |
     |  select_by_theme_overlap(self, themes: List[str], min_overlap: int = 2) -> List[str]
     |      S�lectionne les �l�ments qui appartiennent � plusieurs th�mes sp�cifi�s.
     |
     |      Args:
     |          themes: Liste des th�mes � rechercher
     |          min_overlap: Nombre minimum de th�mes auxquels un �l�ment doit appartenir
     |
     |      Returns:
     |          Liste des identifiants des �l�ments s�lectionn�s
     |
     |  select_by_theme_weight(self, theme: str, min_weight: float = 0.5) -> List[str]
     |      S�lectionne les �l�ments d'un th�me avec un poids minimum.
     |
     |      Args:
     |          theme: Th�me � rechercher
     |          min_weight: Poids minimum du th�me (0.0 � 1.0)
     |
     |      Returns:
     |          Liste des identifiants des �l�ments s�lectionn�s
     |
     |  select_by_themes(self, themes: List[str]) -> List[str]
     |      S�lectionne tous les �l�ments de plusieurs th�mes.
     |
     |      Args:
     |          themes: Liste des th�mes des �l�ments � s�lectionner
     |
     |      Returns:
     |          Liste des identifiants des �l�ments des th�mes
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


