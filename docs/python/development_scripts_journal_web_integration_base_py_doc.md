Help on module integration_base:

NAME
    integration_base

CLASSES
    abc.ABC(builtins.object)
        IntegrationBase

    class IntegrationBase(abc.ABC)
     |  Classe de base pour toutes les int�grations.
     |
     |  Method resolution order:
     |      IntegrationBase
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  authenticate(self)
     |      Authentifie l'int�gration (� impl�menter dans les sous-classes).
     |
     |  load_associations(self, filename)
     |      Charge les associations depuis un fichier JSON.
     |
     |  save_associations(self, associations, filename)
     |      Sauvegarde les associations dans un fichier JSON.
     |
     |  save_config(self)
     |      Sauvegarde la configuration de l'int�gration.
     |
     |  sync_from_journal(self)
     |      Synchronise les donn�es du journal vers l'int�gration.
     |
     |  sync_to_journal(self)
     |      Synchronise les donn�es de l'int�gration vers le journal.
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties defined here:
     |
     |  integration_name
     |      Nom de l'int�gration (� impl�menter dans les sous-classes).
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset({'authenticate', 'integration_name', '...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\integration_base.py


