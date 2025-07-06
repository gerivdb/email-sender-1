Help on module resource_monitor:

NAME
    resource_monitor - Module de surveillance des ressources pour l'architecture hybride PowerShell-Python.

DESCRIPTION
    Ce module fournit des fonctions pour surveiller l'utilisation des ressources syst�me
    pendant l'ex�cution des t�ches parall�les.

    Auteur: Augment Agent
    Date: 2025-04-10
    Version: 1.0

CLASSES
    builtins.object
        ResourceMonitor

    class ResourceMonitor(builtins.object)
     |  ResourceMonitor(output_file=None, interval=1.0, max_samples=0)
     |
     |  Classe pour la surveillance des ressources syst�me.
     |
     |  Methods defined here:
     |
     |  __init__(self, output_file=None, interval=1.0, max_samples=0)
     |      Initialise le moniteur de ressources.
     |
     |      Args:
     |          output_file (str, optional): Fichier de sortie pour les donn�es de surveillance.
     |              Si None, utilise la sortie standard.
     |          interval (float, optional): Intervalle de surveillance en secondes.
     |              Par d�faut: 1.0.
     |          max_samples (int, optional): Nombre maximum d'�chantillons � collecter.
     |              Par d�faut: 0 (illimit�).
     |
     |  get_summary(self)
     |      G�n�re un r�sum� des donn�es de surveillance.
     |
     |      Returns:
     |          dict: R�sum� des donn�es de surveillance.
     |
     |  start(self)
     |      D�marre la surveillance des ressources.
     |
     |  stop(self)
     |      Arr�te la surveillance des ressources.
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
        Fonction principale pour l'ex�cution en ligne de commande.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\performance\python\resource_monitor.py


