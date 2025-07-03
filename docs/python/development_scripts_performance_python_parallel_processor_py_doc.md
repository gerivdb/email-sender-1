Help on module parallel_processor:

NAME
    parallel_processor - Module de traitement parallèle pour l'architecture hybride PowerShell-Python.

DESCRIPTION
    Ce module fournit des fonctions pour le traitement parallèle intensif en Python,
    qui peuvent être appelées depuis PowerShell.

    Auteur: Augment Agent
    Date: 2025-04-10
    Version: 1.0

CLASSES
    builtins.object
        ParallelProcessor
        SharedCache

    class ParallelProcessor(builtins.object)
     |  ParallelProcessor(cache_path=None, max_workers=None)
     |
     |  Classe pour le traitement parallèle des données.
     |
     |  Methods defined here:
     |
     |  __init__(self, cache_path=None, max_workers=None)
     |      Initialise le processeur parallèle.
     |
     |      Args:
     |          cache_path (str, optional): Chemin vers le répertoire du cache.
     |          max_workers (int, optional): Nombre maximum de processus parallèles.
     |              Si None, utilise le nombre de processeurs disponibles.
     |
     |  monitor_resources(self, interval=1.0, callback=None)
     |      Surveille l'utilisation des ressources système.
     |
     |      Args:
     |          interval (float, optional): Intervalle de surveillance en secondes.
     |          callback (callable, optional): Fonction de callback pour le suivi des ressources.
     |
     |      Returns:
     |          dict: Statistiques d'utilisation des ressources.
     |
     |  process_batch(self, batch_data, process_func, **kwargs)
     |      Traite un lot de données en parallèle.
     |
     |      Args:
     |          batch_data (list): Données à traiter.
     |          process_func (callable): Fonction de traitement à appliquer à chaque élément.
     |          **kwargs: Arguments supplémentaires à passer à la fonction de traitement.
     |
     |      Returns:
     |          list: Résultats du traitement.
     |
     |  process_chunks(self, data, process_func, chunk_size=None, **kwargs)
     |      Divise les données en chunks et les traite en parallèle.
     |
     |      Args:
     |          data (list): Données à traiter.
     |          process_func (callable): Fonction de traitement à appliquer à chaque chunk.
     |          chunk_size (int, optional): Taille des chunks. Si None, divise les données
     |              en fonction du nombre de processeurs.
     |          **kwargs: Arguments supplémentaires à passer à la fonction de traitement.
     |
     |      Returns:
     |          list: Résultats du traitement.
     |
     |  process_with_cache(self, batch_data, process_func, cache_key_func=None, ttl=3600, **kwargs)
     |      Traite un lot de données en parallèle avec mise en cache des résultats.
     |
     |      Args:
     |          batch_data (list): Données à traiter.
     |          process_func (callable): Fonction de traitement à appliquer à chaque élément.
     |          cache_key_func (callable, optional): Fonction pour générer la clé de cache.
     |              Si None, utilise str(item) comme clé.
     |          ttl (int, optional): Durée de vie des éléments du cache en secondes.
     |          **kwargs: Arguments supplémentaires à passer à la fonction de traitement.
     |
     |      Returns:
     |          list: Résultats du traitement.
     |
     |  process_with_progress(self, data, process_func, callback=None, **kwargs)
     |      Traite les données en parallèle avec suivi de la progression.
     |
     |      Args:
     |          data (list): Données à traiter.
     |          process_func (callable): Fonction de traitement à appliquer à chaque élément.
     |          callback (callable, optional): Fonction de callback pour le suivi de la progression.
     |          **kwargs: Arguments supplémentaires à passer à la fonction de traitement.
     |
     |      Returns:
     |          list: Résultats du traitement.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class SharedCache(builtins.object)
     |  SharedCache(cache_path=None)
     |
     |  # Si le module n'est pas trouvé, utiliser un stub
     |
     |  Methods defined here:
     |
     |  __init__(self, cache_path=None)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  clear(self)
     |
     |  get(self, key, default=None)
     |
     |  remove(self, key)
     |
     |  set(self, key, value, ttl=3600)
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
        Fonction principale pour l'exécution en ligne de commande.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\performance\python\parallel_processor.py


