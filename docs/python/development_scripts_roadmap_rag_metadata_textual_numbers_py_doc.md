Help on module textual_numbers:

NAME
    textual_numbers

DESCRIPTION
    Script pour détecter les nombres écrits en toutes lettres
    Version: 1.0
    Date: 2025-05-15

CLASSES
    builtins.object
        TextualNumber

    class TextualNumber(builtins.object)
     |  TextualNumber(textual_number: str, numeric_value: int, start_index: int, length: int)
     |
     |  Classe pour représenter un nombre écrit en toutes lettres
     |
     |  Methods defined here:
     |
     |  __init__(self, textual_number: str, numeric_value: int, start_index: int, length: int)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  __str__(self) -> str
     |      Représentation sous forme de chaîne
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertir l'objet en dictionnaire
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
    get_textual_numbers(text: str, language: str = 'Auto') -> List[textual_numbers.TextualNumber]
        Détecter les nombres écrits en toutes lettres dans un texte

        Args:
            text: Le texte à analyser
            language: La langue du texte ("Auto", "French", "English")

        Returns:
            Une liste d'objets TextualNumber

    main()
        Fonction principale

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

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

    english_numbers = {'billion': 1000000000, 'eight': 8, 'eighteen': 18, ...
    french_numbers = {'cent': 100, 'cinq': 5, 'cinquante': 50, 'deux': 2, ...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\rag\metadata\textual_numbers.py


