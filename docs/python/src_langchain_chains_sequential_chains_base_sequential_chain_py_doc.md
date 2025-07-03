Help on module base_sequential_chain:

NAME
    base_sequential_chain - Module contenant la classe de base pour les cha�nes s�quentielles.

DESCRIPTION
    Ce module fournit une classe de base pour les cha�nes s�quentielles qui peuvent �tre utilis�es
    dans diff�rents contextes du projet EMAIL_SENDER_1.

CLASSES
    builtins.object
        BaseSequentialChain

    class BaseSequentialChain(builtins.object)
     |  BaseSequentialChain(chains: Sequence[langchain.chains.base.Chain], verbose: bool = False, return_intermediate_steps: bool = False)
     |
     |  Classe de base pour les cha�nes s�quentielles du projet EMAIL_SENDER_1.
     |
     |  Cette classe fournit une interface commune et des fonctionnalit�s partag�es
     |  pour toutes les cha�nes s�quentielles utilis�es dans le projet.
     |
     |  Methods defined here:
     |
     |  __init__(self, chains: Sequence[langchain.chains.base.Chain], verbose: bool = False, return_intermediate_steps: bool = False)
     |      Initialise une nouvelle instance de BaseSequentialChain.
     |
     |      Args:
     |          chains: S�quence de cha�nes � ex�cuter en s�quence
     |          verbose: Afficher les �tapes interm�diaires (d�faut: False)
     |          return_intermediate_steps: Retourner les r�sultats interm�diaires (d�faut: False)
     |
     |  execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]
     |      Ex�cute la cha�ne s�quentielle avec les entr�es fournies.
     |
     |      Args:
     |          inputs: Dictionnaire des variables d'entr�e
     |
     |      Returns:
     |          Dictionnaire des variables de sortie
     |
     |  get_input_keys(self) -> List[str]
     |      Retourne les cl�s d'entr�e de la cha�ne.
     |
     |      Returns:
     |          Liste des cl�s d'entr�e
     |
     |  get_output_keys(self) -> List[str]
     |      Retourne les cl�s de sortie de la cha�ne.
     |
     |      Returns:
     |          Liste des cl�s de sortie
     |
     |  run(self, input_text: str) -> str
     |      Ex�cute la cha�ne s�quentielle avec le texte d'entr�e fourni.
     |
     |      Args:
     |          input_text: Texte d'entr�e pour la premi�re cha�ne
     |
     |      Returns:
     |          La sortie g�n�r�e par la derni�re cha�ne
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

    Sequence = typing.Sequence
        A generic version of collections.abc.Sequence.

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\langchain\chains\sequential_chains\base_sequential_chain.py


