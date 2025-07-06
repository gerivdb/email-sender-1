Help on module shared_cache:

NAME
    shared_cache - Module de gestion du cache partagé pour l'architecture hybride PowerShell-Python.

DESCRIPTION
    Ce module fournit des fonctions pour gérer un cache partagé entre PowerShell et Python.

    Auteur: Augment Agent
    Date: 2025-04-10
    Version: 1.0

CLASSES
    builtins.object
        SharedCache

    class SharedCache(builtins.object)
     |  SharedCache(cache_path=None, cache_type='hybrid', max_memory_size=100, max_disk_size=1000, default_ttl=3600, eviction_policy='lru', partitions=4, preload_factor=0.2)
     |
     |  Classe pour la gestion du cache partagé entre PowerShell et Python.
     |
     |  Methods defined here:
     |
     |  __init__(self, cache_path=None, cache_type='hybrid', max_memory_size=100, max_disk_size=1000, default_ttl=3600, eviction_policy='lru', partitions=4, preload_factor=0.2)
     |      Initialise le cache partagé.
     |
     |      Args:
     |          cache_path (str, optional): Chemin vers le répertoire du cache.
     |              Si None, utilise un répertoire temporaire.
     |          cache_type (str, optional): Type de cache à utiliser.
     |              Valeurs possibles: 'memory', 'disk', 'hybrid'. Par défaut: 'hybrid'.
     |          max_memory_size (int, optional): Taille maximale du cache en mémoire en Mo.
     |              Par défaut: 100.
     |          max_disk_size (int, optional): Taille maximale du cache sur disque en Mo.
     |              Par défaut: 1000.
     |          default_ttl (int, optional): Durée de vie par défaut des éléments du cache en secondes.
     |              Par défaut: 3600 (1 heure).
     |          eviction_policy (str, optional): Politique d'éviction des éléments du cache.
     |              Valeurs possibles: 'lru', 'lfu', 'fifo'. Par défaut: 'lru'.
     |          partitions (int, optional): Nombre de partitions pour le cache distribué.
     |              Par défaut: 4.
     |          preload_factor (float, optional): Facteur de préchargement (0.0 à 1.0).
     |              Par défaut: 0.2 (20%).
     |
     |  clear(self)
     |      Vide le cache.
     |
     |  get(self, key, default=None)
     |      Récupère un élément du cache.
     |
     |      Args:
     |          key (str): Clé de l'élément à récupérer.
     |          default (any, optional): Valeur par défaut à retourner si l'élément n'est pas trouvé.
     |              Par défaut: None.
     |
     |      Returns:
     |          any: La valeur de l'élément du cache ou la valeur par défaut si l'élément n'est pas trouvé.
     |
     |  get_stats(self)
     |      Récupère les statistiques du cache.
     |
     |      Returns:
     |          dict: Les statistiques du cache.
     |
     |  invalidate(self, key)
     |      Invalide un élément du cache et tous les éléments qui en dépendent.
     |
     |      Args:
     |          key (str): Clé de l'élément à invalider.
     |
     |      Returns:
     |          int: Nombre d'éléments invalidés.
     |
     |  remove(self, key)
     |      Supprime un élément du cache.
     |
     |      Args:
     |          key (str): Clé de l'élément à supprimer.
     |
     |  set(self, key, value, ttl=None, dependencies=None)
     |      Stocke un élément dans le cache.
     |
     |      Args:
     |          key (str): Clé de l'élément à stocker.
     |          value (any): Valeur de l'élément à stocker.
     |          ttl (int, optional): Durée de vie de l'élément en secondes.
     |              Si None, utilise la durée de vie par défaut du cache.
     |          dependencies (list, optional): Liste des clés dont dépend cet élément.
     |              Si une de ces clés est invalidée, cet élément sera également invalidé.
     |
     |      Returns:
     |          any: La valeur stockée dans le cache.
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


