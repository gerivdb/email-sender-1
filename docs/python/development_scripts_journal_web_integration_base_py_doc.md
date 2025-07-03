Help on module integration_base:

NAME
    integration_base

CLASSES
    abc.ABC(builtins.object)
        IntegrationBase

    class IntegrationBase(abc.ABC)
     |  Classe de base pour toutes les intégrations.
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
     |      Authentifie l'intégration (à implémenter dans les sous-classes).
     |
     |  load_associations(self, filename)
     |      Charge les associations depuis un fichier JSON.
     |
     |  save_associations(self, associations, filename)
     |      Sauvegarde les associations dans un fichier JSON.
     |
     |  save_config(self)
     |      Sauvegarde la configuration de l'intégration.
     |
     |  sync_from_journal(self)
     |      Synchronise les données du journal vers l'intégration.
     |
     |  sync_to_journal(self)
     |      Synchronise les données de l'intégration vers le journal.
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties defined here:
     |
     |  integration_name
     |      Nom de l'intégration (à implémenter dans les sous-classes).
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


