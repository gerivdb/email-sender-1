Help on module shared_cache:

NAME
    shared_cache - Module de gestion du cache partag� pour l'architecture hybride PowerShell-Python.

DESCRIPTION
    Ce module fournit des fonctions pour g�rer un cache partag� entre PowerShell et Python.

    Auteur: Augment Agent
    Date: 2025-04-10
    Version: 1.0

CLASSES
    builtins.object
        SharedCache

    class SharedCache(builtins.object)
     |  SharedCache(cache_path=None, cache_type='hybrid', max_memory_size=100, max_disk_size=1000, default_ttl=3600, eviction_policy='lru', partitions=4, preload_factor=0.2)
     |
     |  Classe pour la gestion du cache partag� entre PowerShell et Python.
     |
     |  Methods defined here:
     |
     |  __init__(self, cache_path=None, cache_type='hybrid', max_memory_size=100, max_disk_size=1000, default_ttl=3600, eviction_policy='lru', partitions=4, preload_factor=0.2)
     |      Initialise le cache partag�.
     |
     |      Args:
     |          cache_path (str, optional): Chemin vers le r�pertoire du cache.
     |              Si None, utilise un r�pertoire temporaire.
     |          cache_type (str, optional): Type de cache � utiliser.
     |              Valeurs possibles: 'memory', 'disk', 'hybrid'. Par d�faut: 'hybrid'.
     |          max_memory_size (int, optional): Taille maximale du cache en m�moire en Mo.
     |              Par d�faut: 100.
     |          max_disk_size (int, optional): Taille maximale du cache sur disque en Mo.
     |              Par d�faut: 1000.
     |          default_ttl (int, optional): Dur�e de vie par d�faut des �l�ments du cache en secondes.
     |              Par d�faut: 3600 (1 heure).
     |          eviction_policy (str, optional): Politique d'�viction des �l�ments du cache.
     |              Valeurs possibles: 'lru', 'lfu', 'fifo'. Par d�faut: 'lru'.
     |          partitions (int, optional): Nombre de partitions pour le cache distribu�.
     |              Par d�faut: 4.
     |          preload_factor (float, optional): Facteur de pr�chargement (0.0 � 1.0).
     |              Par d�faut: 0.2 (20%).
     |
     |  clear(self)
     |      Vide le cache.
     |
     |  get(self, key, default=None)
     |      R�cup�re un �l�ment du cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � r�cup�rer.
     |          default (any, optional): Valeur par d�faut � retourner si l'�l�ment n'est pas trouv�.
     |              Par d�faut: None.
     |
     |      Returns:
     |          any: La valeur de l'�l�ment du cache ou la valeur par d�faut si l'�l�ment n'est pas trouv�.
     |
     |  get_stats(self)
     |      R�cup�re les statistiques du cache.
     |
     |      Returns:
     |          dict: Les statistiques du cache.
     |
     |  invalidate(self, key)
     |      Invalide un �l�ment du cache et tous les �l�ments qui en d�pendent.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � invalider.
     |
     |      Returns:
     |          int: Nombre d'�l�ments invalid�s.
     |
     |  remove(self, key)
     |      Supprime un �l�ment du cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � supprimer.
     |
     |  set(self, key, value, ttl=None, dependencies=None)
     |      Stocke un �l�ment dans le cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � stocker.
     |          value (any): Valeur de l'�l�ment � stocker.
     |          ttl (int, optional): Dur�e de vie de l'�l�ment en secondes.
     |              Si None, utilise la dur�e de vie par d�faut du cache.
     |          dependencies (list, optional): Liste des cl�s dont d�pend cet �l�ment.
     |              Si une de ces cl�s est invalid�e, cet �l�ment sera �galement invalid�.
     |
     |      Returns:
     |          any: La valeur stock�e dans le cache.
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
        Fonction principale pour les tests.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\performance\python\shared_cache.py


