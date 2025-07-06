Help on module manager:

NAME
    manager - Module de gestion CRUD modulaire thématique.

DESCRIPTION
    Ce module intègre tous les composants du système CRUD modulaire thématique
    pour fournir une interface unifiée.

CLASSES
    builtins.object
        ThematicCRUDManager

    class ThematicCRUDManager(builtins.object)
     |  ThematicCRUDManager(storage_path: str, archive_path: Optional[str] = None, versions_path: Optional[str] = None, views_path: Optional[str] = None, embeddings_path: Optional[str] = None, themes_config_path: Optional[str] = None, history_path: Optional[str] = None, embedding_model: str = 'openrouter/qwen/qwen3-235b-a22b', api_key: Optional[str] = None, api_url: Optional[str] = None, use_advanced_attribution: bool = True, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |
     |  Gestionnaire CRUD modulaire thématique.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, archive_path: Optional[str] = None, versions_path: Optional[str] = None, views_path: Optional[str] = None, embeddings_path: Optional[str] = None, themes_config_path: Optional[str] = None, history_path: Optional[str] = None, embedding_model: str = 'openrouter/qwen/qwen3-235b-a22b', api_key: Optional[str] = None, api_url: Optional[str] = None, use_advanced_attribution: bool = True, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |      Initialise le gestionnaire CRUD modulaire thématique.
     |
     |      Args:
     |          storage_path: Chemin vers le répertoire de stockage des données
     |          archive_path: Chemin vers le répertoire d'archivage (optionnel)
     |          versions_path: Chemin vers le répertoire de versions (optionnel)
     |          views_path: Chemin vers le répertoire de vues thématiques (optionnel)
     |          embeddings_path: Chemin vers le répertoire d'embeddings (optionnel)
     |          themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
     |          history_path: Chemin vers le fichier d'historique d'attribution (optionnel)
     |          embedding_model: Modèle d'embedding à utiliser (défaut: "openrouter/qwen/qwen3-235b-a22b")
     |          api_key: Clé API pour le service d'embedding (optionnel)
     |          api_url: URL de l'API pour le service d'embedding (optionnel)
     |          use_advanced_attribution: Utiliser l'attribution thématique avancée (défaut: True)
     |          learning_rate: Taux d'apprentissage pour l'adaptation (défaut: 0.1)
     |          context_weight: Poids du contexte dans l'attribution (défaut: 0.3)
     |          user_feedback_weight: Poids du retour utilisateur (défaut: 0.5)
     |
     |  add_user_feedback(self, item_id: str, user_themes: Dict[str, float]) -> Optional[Dict[str, Any]]
     |      Ajoute un retour utilisateur sur l'attribution thématique.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          user_themes: Thèmes attribués par l'utilisateur avec leurs scores
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  analyze_theme_evolution(self, item_id: str) -> Optional[Dict[str, Any]]
     |      Analyse l'évolution des thèmes d'un élément au fil du temps.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |
     |      Returns:
     |          Analyse de l'évolution thématique ou None si l'élément n'existe pas
     |
     |  archive_item(self, item_id: str, reason: Optional[str] = None) -> bool
     |      Archive un élément sans le supprimer.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à archiver
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          True si l'élément a été archivé, False sinon
     |
     |  archive_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any], reason: Optional[str] = None) -> Dict[str, Any]
     |      Archive des éléments selon une méthode de sélection spécifiée.
     |
     |      Args:
     |          selection_method: Méthode de sélection à utiliser
     |          selection_params: Paramètres pour la méthode de sélection
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments archivés, etc.)
     |
     |  archive_items_by_theme(self, theme: str, reason: Optional[str] = None) -> int
     |      Archive tous les éléments d'un thème sans les supprimer.
     |
     |      Args:
     |          theme: Thème des éléments à archiver
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          Nombre d'éléments archivés
     |
     |  attribute_theme(self, content: str, metadata: Optional[Dict[str, Any]] = None, context: Optional[Dict[str, Any]] = None) -> Dict[str, float]
     |      Attribue des thèmes à un contenu en fonction de sa similarité avec les thèmes connus.
     |
     |      Args:
     |          content: Contenu textuel à analyser
     |          metadata: Métadonnées associées au contenu (optionnel)
     |          context: Contexte d'attribution (optionnel)
     |
     |      Returns:
     |          Dictionnaire des thèmes attribués avec leur score de confiance
     |
     |  clone_view(self, view_id: str, new_name: Optional[str] = None) -> Optional[Dict[str, Any]]
     |      Clone une vue thématique existante.
     |
     |      Args:
     |          view_id: Identifiant de la vue à cloner
     |          new_name: Nouveau nom pour la vue clonée (optionnel)
     |
     |      Returns:
     |          Vue thématique clonée ou None si la vue source n'existe pas
     |
     |  compare_versions(self, item_id: str, version1: int, version2: int) -> Dict[str, Any]
     |      Compare deux versions d'un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          version1: Numéro de la première version
     |          version2: Numéro de la deuxième version
     |
     |      Returns:
     |          Dictionnaire des différences entre les versions
     |
     |  create_item(self, content: str, metadata: Dict[str, Any], create_version: bool = True, version_tag: Optional[str] = None, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
     |      Crée un nouvel élément avec attribution thématique automatique.
     |
     |      Args:
     |          content: Contenu de l'élément
     |          metadata: Métadonnées de l'élément
     |          create_version: Si True, crée une version initiale de l'élément
     |          version_tag: Tag de version (optionnel)
     |          context: Contexte d'attribution thématique (optionnel)
     |
     |      Returns:
     |          Élément créé avec ses métadonnées enrichies
     |
     |  create_version(self, item_id: str, version_tag: Optional[str] = None, version_message: Optional[str] = None) -> Optional[Dict[str, Any]]
     |      Crée une nouvelle version d'un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          version_tag: Tag de version (optionnel)
     |          version_message: Message de version (optionnel)
     |
     |      Returns:
     |          Métadonnées de la version créée ou None si l'élément n'existe pas
     |
     |  create_view(self, name: str, description: str = '', search_criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
     |      Crée une nouvelle vue thématique personnalisée.
     |
     |      Args:
     |          name: Nom de la vue
     |          description: Description de la vue (optionnel)
     |          search_criteria: Critères de recherche pour la vue (optionnel)
     |
     |      Returns:
     |          Vue thématique créée
     |
     |  delete_item(self, item_id: str, permanent: bool = False, reason: Optional[str] = None) -> bool
     |      Supprime un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à supprimer
     |          permanent: Si True, supprime définitivement l'élément sans l'archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          True si l'élément a été supprimé, False sinon
     |
     |  delete_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any], permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des éléments selon une méthode de sélection spécifiée.
     |
     |      Args:
     |          selection_method: Méthode de sélection à utiliser
     |          selection_params: Paramètres pour la méthode de sélection
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
     |
     |  delete_items_by_theme(self, theme: str, permanent: bool = False, reason: Optional[str] = None) -> int
     |      Supprime tous les éléments d'un thème.
     |
     |      Args:
     |          theme: Thème des éléments à supprimer
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Nombre d'éléments supprimés
     |
     |  delete_items_by_theme_exclusivity(self, theme: str, exclusivity_threshold: float = 0.8, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des éléments selon l'exclusivité d'un thème.
     |
     |      Args:
     |          theme: Thème principal
     |          exclusivity_threshold: Seuil d'exclusivité (0.0 à 1.0)
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
     |
     |  delete_items_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des éléments selon une hiérarchie thématique.
     |
     |      Args:
     |          theme: Thème principal
     |          include_subthemes: Si True, inclut les sous-thèmes
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
     |
     |  delete_items_by_theme_weight(self, theme: str, min_weight: float = 0.5, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des éléments selon le poids d'un thème.
     |
     |      Args:
     |          theme: Thème à rechercher
     |          min_weight: Poids minimum du thème (0.0 à 1.0)
     |          permanent: Si True, supprime définitivement les éléments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
     |
     |  delete_view(self, view_id: str) -> bool
     |      Supprime une vue thématique.
     |
     |      Args:
     |          view_id: Identifiant de la vue à supprimer
     |
     |      Returns:
     |          True si la vue a été supprimée, False sinon
     |
     |  execute_view(self, view_id: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Exécute une vue thématique pour récupérer les éléments correspondants.
     |
     |      Args:
     |          view_id: Identifiant de la vue à exécuter
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments correspondant aux critères de la vue
     |
     |  extract_and_update_theme(self, source_item_id: str, target_item_id: str, theme: str) -> Optional[Dict[str, Any]]
     |      Extrait les sections d'un thème d'un élément source et les applique à un élément cible.
     |
     |      Args:
     |          source_item_id: Identifiant de l'élément source
     |          target_item_id: Identifiant de l'élément cible
     |          theme: Thème à extraire et appliquer
     |
     |      Returns:
     |          Élément cible mis à jour ou None si l'un des éléments n'existe pas
     |
     |  find_theme_clusters(self, min_similarity: float = 0.8, min_cluster_size: int = 3) -> List[Dict[str, Any]]
     |      Identifie des clusters thématiques basés sur la similarité vectorielle.
     |
     |      Args:
     |          min_similarity: Similarité minimum pour considérer deux éléments comme similaires
     |          min_cluster_size: Taille minimum d'un cluster
     |
     |      Returns:
     |          Liste des clusters identifiés
     |
     |  get_all_views(self) -> List[Dict[str, Any]]
     |      Récupère toutes les vues thématiques.
     |
     |      Returns:
     |          Liste des vues thématiques
     |
     |  get_archive_statistics(self) -> Dict[str, Any]
     |      Récupère des statistiques sur les archives.
     |
     |      Returns:
     |          Statistiques sur les archives (nombre d'éléments, taille, etc.)
     |
     |  get_archived_items(self, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Récupère les éléments archivés.
     |
     |      Args:
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments archivés
     |
     |  get_archived_items_by_theme(self, theme: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Récupère les éléments archivés par thème.
     |
     |      Args:
     |          theme: Thème des éléments à récupérer
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments archivés pour le thème spécifié
     |
     |  get_item(self, item_id: str) -> Optional[Dict[str, Any]]
     |      Récupère un élément par son identifiant.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à récupérer
     |
     |      Returns:
     |          Élément récupéré ou None si l'élément n'existe pas
     |
     |  get_items_by_theme(self, theme: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Récupère les éléments par thème.
     |
     |      Args:
     |          theme: Thème à rechercher
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments correspondant au thème
     |
     |  get_theme_statistics(self) -> Dict[str, Dict[str, Any]]
     |      Récupère des statistiques sur les thèmes.
     |
     |      Returns:
     |          Dictionnaire des statistiques par thème
     |
     |  get_version(self, item_id: str, version_number: int) -> Optional[Dict[str, Any]]
     |      Récupère une version spécifique d'un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          version_number: Numéro de version
     |
     |      Returns:
     |          Élément à la version spécifiée, ou None si la version n'existe pas
     |
     |  get_versions(self, item_id: str) -> List[Dict[str, Any]]
     |      Récupère toutes les versions d'un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |
     |      Returns:
     |          Liste des métadonnées de versions, triées par numéro de version décroissant
     |
     |  get_versions_by_theme(self, theme: str, item_id: Optional[str] = None) -> Dict[str, List[Dict[str, Any]]]
     |      Récupère les versions des éléments d'un thème.
     |
     |      Args:
     |          theme: Thème des éléments
     |          item_id: Identifiant de l'élément (optionnel)
     |
     |      Returns:
     |          Dictionnaire des versions par élément
     |
     |  get_view(self, view_id: str) -> Optional[Dict[str, Any]]
     |      Récupère une vue thématique par son identifiant.
     |
     |      Args:
     |          view_id: Identifiant de la vue à récupérer
     |
     |      Returns:
     |          Vue thématique ou None si la vue n'existe pas
     |
     |  index_item_for_vector_search(self, item_id: str) -> bool
     |      Indexe un élément pour la recherche vectorielle.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à indexer
     |
     |      Returns:
     |          True si l'indexation a réussi, False sinon
     |
     |  index_items_by_theme_for_vector_search(self, theme: str) -> Dict[str, Any]
     |      Indexe tous les éléments d'un thème pour la recherche vectorielle.
     |
     |      Args:
     |          theme: Thème des éléments à indexer
     |
     |      Returns:
     |          Statistiques sur l'indexation
     |
     |  merge_theme_content(self, item_id: str, theme: str, content_to_merge: str) -> Optional[Dict[str, Any]]
     |      Fusionne du contenu dans les sections d'un élément correspondant à un thème.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          theme: Thème des sections à mettre à jour
     |          content_to_merge: Contenu à fusionner
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  restore_archived_item(self, item_id: str) -> bool
     |      Restaure un élément archivé.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à restaurer
     |
     |      Returns:
     |          True si l'élément a été restauré, False sinon
     |
     |  restore_version(self, item_id: str, version_number: int) -> Optional[Dict[str, Any]]
     |      Restaure une version spécifique d'un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          version_number: Numéro de version
     |
     |      Returns:
     |          Élément restauré, ou None si la restauration a échoué
     |
     |  rotate_archives(self, max_age_days: int = 90, max_items: int = 1000, backup_dir: Optional[str] = None) -> Dict[str, Any]
     |      Effectue une rotation des archives en déplaçant les archives anciennes vers un répertoire de sauvegarde
     |      ou en les supprimant.
     |
     |      Args:
     |          max_age_days: Âge maximum des archives en jours (défaut: 90)
     |          max_items: Nombre maximum d'éléments à conserver (défaut: 1000)
     |          backup_dir: Répertoire de sauvegarde (optionnel, si None les archives sont supprimées)
     |
     |      Returns:
     |          Statistiques sur la rotation (nombre d'éléments déplacés/supprimés, etc.)
     |
     |  search_archived_items(self, query: str, themes: Optional[List[str]] = None, metadata_filters: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des éléments dans les archives.
     |
     |      Args:
     |          query: Requête textuelle à rechercher dans le contenu
     |          themes: Liste des thèmes à inclure dans la recherche (optionnel)
     |          metadata_filters: Filtres de métadonnées (optionnel)
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments archivés correspondant aux critères de recherche
     |
     |  search_by_multi_criteria(self, themes: Optional[List[str]] = None, content_query: Optional[str] = None, metadata_filters: Optional[Dict[str, Any]] = None, date_range: Optional[Dict[str, str]] = None, theme_weights: Optional[Dict[str, float]] = None, sort_by: str = 'relevance', limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des éléments selon plusieurs critères combinés.
     |
     |      Args:
     |          themes: Liste des thèmes à inclure dans la recherche (optionnel)
     |          content_query: Requête textuelle à rechercher dans le contenu (optionnel)
     |          metadata_filters: Filtres sur les métadonnées (optionnel)
     |          date_range: Plage de dates pour la recherche (optionnel)
     |          theme_weights: Poids minimum pour chaque thème (optionnel)
     |          sort_by: Critère de tri ("relevance", "date", "title", "theme_weight")
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments correspondant aux critères de recherche
     |
     |  search_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True, include_parent_themes: bool = False, max_depth: int = 3, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des éléments selon une hiérarchie thématique.
     |
     |      Args:
     |          theme: Thème principal
     |          include_subthemes: Inclure les sous-thèmes
     |          include_parent_themes: Inclure les thèmes parents
     |          max_depth: Profondeur maximale de la hiérarchie
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments correspondant aux critères de recherche
     |
     |  search_by_theme_relationships(self, primary_theme: str, related_themes: Optional[List[str]] = None, relationship_type: str = 'any', min_overlap: int = 1, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des éléments selon les relations entre thèmes.
     |
     |      Args:
     |          primary_theme: Thème principal
     |          related_themes: Thèmes liés (optionnel)
     |          relationship_type: Type de relation ("any", "all", "only")
     |          min_overlap: Nombre minimum de thèmes liés requis
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments correspondant aux critères de recherche
     |
     |  search_items(self, query: str, themes: Optional[List[str]] = None, metadata_filters: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des éléments par requête textuelle et filtres.
     |
     |      Args:
     |          query: Requête textuelle à rechercher
     |          themes: Liste des thèmes à inclure dans la recherche (optionnel)
     |          metadata_filters: Filtres sur les métadonnées (optionnel)
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments correspondant aux critères de recherche
     |
     |  search_similar_items(self, query: str, themes: Optional[List[str]] = None, top_k: int = 10, similarity_threshold: float = 0.7) -> List[Dict[str, Any]]
     |      Recherche des éléments similaires à une requête textuelle.
     |
     |      Args:
     |          query: Requête textuelle
     |          themes: Liste des thèmes à inclure dans la recherche (optionnel)
     |          top_k: Nombre maximum d'éléments à récupérer (défaut: 10)
     |          similarity_threshold: Seuil de similarité minimum (défaut: 0.7)
     |
     |      Returns:
     |          Liste des éléments similaires avec leur score de similarité
     |
     |  suggest_theme_corrections(self, item_id: str, expected_themes: Optional[List[str]] = None) -> Optional[Dict[str, Any]]
     |      Suggère des corrections thématiques pour un élément.
     |
     |      Args:
     |          item_id: Identifiant de l'élément
     |          expected_themes: Thèmes attendus (optionnel)
     |
     |      Returns:
     |          Suggestions de corrections thématiques ou None si l'élément n'existe pas
     |
     |  update_item(self, item_id: str, content: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, create_version: bool = True, version_tag: Optional[str] = None, version_message: Optional[str] = None, context: Optional[Dict[str, Any]] = None, reattribute_themes: bool = True, detect_changes: bool = True) -> Optional[Dict[str, Any]]
     |      Met à jour un élément existant avec détection des changements thématiques.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          content: Nouveau contenu (optionnel)
     |          metadata: Nouvelles métadonnées (optionnel)
     |          create_version: Si True, crée une nouvelle version après la mise à jour
     |          version_tag: Tag de version (optionnel)
     |          version_message: Message de version (optionnel)
     |          context: Contexte d'attribution thématique (optionnel)
     |          reattribute_themes: Réattribuer les thèmes si le contenu a changé (défaut: True)
     |          detect_changes: Détecter les changements thématiques (défaut: True)
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  update_multiple_themes(self, item_id: str, theme_updates: Dict[str, str]) -> Optional[Dict[str, Any]]
     |      Met à jour plusieurs thèmes d'un élément en une seule opération.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          theme_updates: Dictionnaire des thèmes à mettre à jour avec leur nouveau contenu
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  update_theme_sections(self, item_id: str, theme: str, new_content: str) -> Optional[Dict[str, Any]]
     |      Met à jour les sections d'un élément correspondant à un thème spécifique.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à mettre à jour
     |          theme: Thème des sections à mettre à jour
     |          new_content: Nouveau contenu pour les sections
     |
     |      Returns:
     |          Élément mis à jour ou None si l'élément n'existe pas
     |
     |  update_view(self, view_id: str, name: Optional[str] = None, description: Optional[str] = None, search_criteria: Optional[Dict[str, Any]] = None) -> Optional[Dict[str, Any]]
     |      Met à jour une vue thématique existante.
     |
     |      Args:
     |          view_id: Identifiant de la vue à mettre à jour
     |          name: Nouveau nom de la vue (optionnel)
     |          description: Nouvelle description de la vue (optionnel)
     |          search_criteria: Nouveaux critères de recherche pour la vue (optionnel)
     |
     |      Returns:
     |          Vue thématique mise à jour ou None si la vue n'existe pas
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

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\manager.py


