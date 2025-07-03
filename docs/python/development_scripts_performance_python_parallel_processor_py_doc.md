Help on module parallel_processor:

NAME
    parallel_processor - Module de traitement parall�le pour l'architecture hybride PowerShell-Python.

DESCRIPTION
    Ce module fournit des fonctions pour le traitement parall�le intensif en Python,
    qui peuvent �tre appel�es depuis PowerShell.

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
     |  Classe pour le traitement parall�le des donn�es.
     |
     |  Methods defined here:
     |
     |  __init__(self, cache_path=None, max_workers=None)
     |      Initialise le processeur parall�le.
     |
     |      Args:
     |          cache_path (str, optional): Chemin vers le r�pertoire du cache.
     |          max_workers (int, optional): Nombre maximum de processus parall�les.
     |              Si None, utilise le nombre de processeurs disponibles.
     |
     |  monitor_resources(self, interval=1.0, callback=None)
     |      Surveille l'utilisation des ressources syst�me.
     |
     |      Args:
     |          interval (float, optional): Intervalle de surveillance en secondes.
     |          callback (callable, optional): Fonction de callback pour le suivi des ressources.
     |
     |      Returns:
     |          dict: Statistiques d'utilisation des ressources.
     |
     |  process_batch(self, batch_data, process_func, **kwargs)
     |      Traite un lot de donn�es en parall�le.
     |
     |      Args:
     |          batch_data (list): Donn�es � traiter.
     |          process_func (callable): Fonction de traitement � appliquer � chaque �l�ment.
     |          **kwargs: Arguments suppl�mentaires � passer � la fonction de traitement.
     |
     |      Returns:
     |          list: R�sultats du traitement.
     |
     |  process_chunks(self, data, process_func, chunk_size=None, **kwargs)
     |      Divise les donn�es en chunks et les traite en parall�le.
     |
     |      Args:
     |          data (list): Donn�es � traiter.
     |          process_func (callable): Fonction de traitement � appliquer � chaque chunk.
     |          chunk_size (int, optional): Taille des chunks. Si None, divise les donn�es
     |              en fonction du nombre de processeurs.
     |          **kwargs: Arguments suppl�mentaires � passer � la fonction de traitement.
     |
     |      Returns:
     |          list: R�sultats du traitement.
     |
     |  process_with_cache(self, batch_data, process_func, cache_key_func=None, ttl=3600, **kwargs)
     |      Traite un lot de donn�es en parall�le avec mise en cache des r�sultats.
     |
     |      Args:
     |          batch_data (list): Donn�es � traiter.
     |          process_func (callable): Fonction de traitement � appliquer � chaque �l�ment.
     |          cache_key_func (callable, optional): Fonction pour g�n�rer la cl� de cache.
     |              Si None, utilise str(item) comme cl�.
     |          ttl (int, optional): Dur�e de vie des �l�ments du cache en secondes.
     |          **kwargs: Arguments suppl�mentaires � passer � la fonction de traitement.
     |
     |      Returns:
     |          list: R�sultats du traitement.
     |
     |  process_with_progress(self, data, process_func, callback=None, **kwargs)
     |      Traite les donn�es en parall�le avec suivi de la progression.
     |
     |      Args:
     |          data (list): Donn�es � traiter.
     |          process_func (callable): Fonction de traitement � appliquer � chaque �l�ment.
     |          callback (callable, optional): Fonction de callback pour le suivi de la progression.
     |          **kwargs: Arguments suppl�mentaires � passer � la fonction de traitement.
     |
     |      Returns:
     |          list: R�sultats du traitement.
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
     |  # Si le module n'est pas trouv�, utiliser un stub
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
        Fonction principale pour l'ex�cution en ligne de commande.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\performance\python\parallel_processor.py


