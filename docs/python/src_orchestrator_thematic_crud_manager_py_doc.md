Help on module manager:

NAME
    manager - Module de gestion CRUD modulaire th�matique.

DESCRIPTION
    Ce module int�gre tous les composants du syst�me CRUD modulaire th�matique
    pour fournir une interface unifi�e.

CLASSES
    builtins.object
        ThematicCRUDManager

    class ThematicCRUDManager(builtins.object)
     |  ThematicCRUDManager(storage_path: str, archive_path: Optional[str] = None, versions_path: Optional[str] = None, views_path: Optional[str] = None, embeddings_path: Optional[str] = None, themes_config_path: Optional[str] = None, history_path: Optional[str] = None, embedding_model: str = 'openrouter/qwen/qwen3-235b-a22b', api_key: Optional[str] = None, api_url: Optional[str] = None, use_advanced_attribution: bool = True, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |
     |  Gestionnaire CRUD modulaire th�matique.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, archive_path: Optional[str] = None, versions_path: Optional[str] = None, views_path: Optional[str] = None, embeddings_path: Optional[str] = None, themes_config_path: Optional[str] = None, history_path: Optional[str] = None, embedding_model: str = 'openrouter/qwen/qwen3-235b-a22b', api_key: Optional[str] = None, api_url: Optional[str] = None, use_advanced_attribution: bool = True, learning_rate: float = 0.1, context_weight: float = 0.3, user_feedback_weight: float = 0.5)
     |      Initialise le gestionnaire CRUD modulaire th�matique.
     |
     |      Args:
     |          storage_path: Chemin vers le r�pertoire de stockage des donn�es
     |          archive_path: Chemin vers le r�pertoire d'archivage (optionnel)
     |          versions_path: Chemin vers le r�pertoire de versions (optionnel)
     |          views_path: Chemin vers le r�pertoire de vues th�matiques (optionnel)
     |          embeddings_path: Chemin vers le r�pertoire d'embeddings (optionnel)
     |          themes_config_path: Chemin vers le fichier de configuration des th�mes (optionnel)
     |          history_path: Chemin vers le fichier d'historique d'attribution (optionnel)
     |          embedding_model: Mod�le d'embedding � utiliser (d�faut: "openrouter/qwen/qwen3-235b-a22b")
     |          api_key: Cl� API pour le service d'embedding (optionnel)
     |          api_url: URL de l'API pour le service d'embedding (optionnel)
     |          use_advanced_attribution: Utiliser l'attribution th�matique avanc�e (d�faut: True)
     |          learning_rate: Taux d'apprentissage pour l'adaptation (d�faut: 0.1)
     |          context_weight: Poids du contexte dans l'attribution (d�faut: 0.3)
     |          user_feedback_weight: Poids du retour utilisateur (d�faut: 0.5)
     |
     |  add_user_feedback(self, item_id: str, user_themes: Dict[str, float]) -> Optional[Dict[str, Any]]
     |      Ajoute un retour utilisateur sur l'attribution th�matique.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          user_themes: Th�mes attribu�s par l'utilisateur avec leurs scores
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
     |
     |  analyze_theme_evolution(self, item_id: str) -> Optional[Dict[str, Any]]
     |      Analyse l'�volution des th�mes d'un �l�ment au fil du temps.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |
     |      Returns:
     |          Analyse de l'�volution th�matique ou None si l'�l�ment n'existe pas
     |
     |  archive_item(self, item_id: str, reason: Optional[str] = None) -> bool
     |      Archive un �l�ment sans le supprimer.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � archiver
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          True si l'�l�ment a �t� archiv�, False sinon
     |
     |  archive_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any], reason: Optional[str] = None) -> Dict[str, Any]
     |      Archive des �l�ments selon une m�thode de s�lection sp�cifi�e.
     |
     |      Args:
     |          selection_method: M�thode de s�lection � utiliser
     |          selection_params: Param�tres pour la m�thode de s�lection
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments archiv�s, etc.)
     |
     |  archive_items_by_theme(self, theme: str, reason: Optional[str] = None) -> int
     |      Archive tous les �l�ments d'un th�me sans les supprimer.
     |
     |      Args:
     |          theme: Th�me des �l�ments � archiver
     |          reason: Raison de l'archivage (optionnel)
     |
     |      Returns:
     |          Nombre d'�l�ments archiv�s
     |
     |  attribute_theme(self, content: str, metadata: Optional[Dict[str, Any]] = None, context: Optional[Dict[str, Any]] = None) -> Dict[str, float]
     |      Attribue des th�mes � un contenu en fonction de sa similarit� avec les th�mes connus.
     |
     |      Args:
     |          content: Contenu textuel � analyser
     |          metadata: M�tadonn�es associ�es au contenu (optionnel)
     |          context: Contexte d'attribution (optionnel)
     |
     |      Returns:
     |          Dictionnaire des th�mes attribu�s avec leur score de confiance
     |
     |  clone_view(self, view_id: str, new_name: Optional[str] = None) -> Optional[Dict[str, Any]]
     |      Clone une vue th�matique existante.
     |
     |      Args:
     |          view_id: Identifiant de la vue � cloner
     |          new_name: Nouveau nom pour la vue clon�e (optionnel)
     |
     |      Returns:
     |          Vue th�matique clon�e ou None si la vue source n'existe pas
     |
     |  compare_versions(self, item_id: str, version1: int, version2: int) -> Dict[str, Any]
     |      Compare deux versions d'un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          version1: Num�ro de la premi�re version
     |          version2: Num�ro de la deuxi�me version
     |
     |      Returns:
     |          Dictionnaire des diff�rences entre les versions
     |
     |  create_item(self, content: str, metadata: Dict[str, Any], create_version: bool = True, version_tag: Optional[str] = None, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
     |      Cr�e un nouvel �l�ment avec attribution th�matique automatique.
     |
     |      Args:
     |          content: Contenu de l'�l�ment
     |          metadata: M�tadonn�es de l'�l�ment
     |          create_version: Si True, cr�e une version initiale de l'�l�ment
     |          version_tag: Tag de version (optionnel)
     |          context: Contexte d'attribution th�matique (optionnel)
     |
     |      Returns:
     |          �l�ment cr�� avec ses m�tadonn�es enrichies
     |
     |  create_version(self, item_id: str, version_tag: Optional[str] = None, version_message: Optional[str] = None) -> Optional[Dict[str, Any]]
     |      Cr�e une nouvelle version d'un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          version_tag: Tag de version (optionnel)
     |          version_message: Message de version (optionnel)
     |
     |      Returns:
     |          M�tadonn�es de la version cr��e ou None si l'�l�ment n'existe pas
     |
     |  create_view(self, name: str, description: str = '', search_criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]
     |      Cr�e une nouvelle vue th�matique personnalis�e.
     |
     |      Args:
     |          name: Nom de la vue
     |          description: Description de la vue (optionnel)
     |          search_criteria: Crit�res de recherche pour la vue (optionnel)
     |
     |      Returns:
     |          Vue th�matique cr��e
     |
     |  delete_item(self, item_id: str, permanent: bool = False, reason: Optional[str] = None) -> bool
     |      Supprime un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � supprimer
     |          permanent: Si True, supprime d�finitivement l'�l�ment sans l'archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          True si l'�l�ment a �t� supprim�, False sinon
     |
     |  delete_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any], permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des �l�ments selon une m�thode de s�lection sp�cifi�e.
     |
     |      Args:
     |          selection_method: M�thode de s�lection � utiliser
     |          selection_params: Param�tres pour la m�thode de s�lection
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments supprim�s, etc.)
     |
     |  delete_items_by_theme(self, theme: str, permanent: bool = False, reason: Optional[str] = None) -> int
     |      Supprime tous les �l�ments d'un th�me.
     |
     |      Args:
     |          theme: Th�me des �l�ments � supprimer
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Nombre d'�l�ments supprim�s
     |
     |  delete_items_by_theme_exclusivity(self, theme: str, exclusivity_threshold: float = 0.8, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des �l�ments selon l'exclusivit� d'un th�me.
     |
     |      Args:
     |          theme: Th�me principal
     |          exclusivity_threshold: Seuil d'exclusivit� (0.0 � 1.0)
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments supprim�s, etc.)
     |
     |  delete_items_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des �l�ments selon une hi�rarchie th�matique.
     |
     |      Args:
     |          theme: Th�me principal
     |          include_subthemes: Si True, inclut les sous-th�mes
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments supprim�s, etc.)
     |
     |  delete_items_by_theme_weight(self, theme: str, min_weight: float = 0.5, permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]
     |      Supprime des �l�ments selon le poids d'un th�me.
     |
     |      Args:
     |          theme: Th�me � rechercher
     |          min_weight: Poids minimum du th�me (0.0 � 1.0)
     |          permanent: Si True, supprime d�finitivement les �l�ments sans les archiver
     |          reason: Raison de la suppression/archivage (optionnel)
     |
     |      Returns:
     |          Statistiques sur l'op�ration (nombre d'�l�ments supprim�s, etc.)
     |
     |  delete_view(self, view_id: str) -> bool
     |      Supprime une vue th�matique.
     |
     |      Args:
     |          view_id: Identifiant de la vue � supprimer
     |
     |      Returns:
     |          True si la vue a �t� supprim�e, False sinon
     |
     |  execute_view(self, view_id: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Ex�cute une vue th�matique pour r�cup�rer les �l�ments correspondants.
     |
     |      Args:
     |          view_id: Identifiant de la vue � ex�cuter
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant aux crit�res de la vue
     |
     |  extract_and_update_theme(self, source_item_id: str, target_item_id: str, theme: str) -> Optional[Dict[str, Any]]
     |      Extrait les sections d'un th�me d'un �l�ment source et les applique � un �l�ment cible.
     |
     |      Args:
     |          source_item_id: Identifiant de l'�l�ment source
     |          target_item_id: Identifiant de l'�l�ment cible
     |          theme: Th�me � extraire et appliquer
     |
     |      Returns:
     |          �l�ment cible mis � jour ou None si l'un des �l�ments n'existe pas
     |
     |  find_theme_clusters(self, min_similarity: float = 0.8, min_cluster_size: int = 3) -> List[Dict[str, Any]]
     |      Identifie des clusters th�matiques bas�s sur la similarit� vectorielle.
     |
     |      Args:
     |          min_similarity: Similarit� minimum pour consid�rer deux �l�ments comme similaires
     |          min_cluster_size: Taille minimum d'un cluster
     |
     |      Returns:
     |          Liste des clusters identifi�s
     |
     |  get_all_views(self) -> List[Dict[str, Any]]
     |      R�cup�re toutes les vues th�matiques.
     |
     |      Returns:
     |          Liste des vues th�matiques
     |
     |  get_archive_statistics(self) -> Dict[str, Any]
     |      R�cup�re des statistiques sur les archives.
     |
     |      Returns:
     |          Statistiques sur les archives (nombre d'�l�ments, taille, etc.)
     |
     |  get_archived_items(self, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      R�cup�re les �l�ments archiv�s.
     |
     |      Args:
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments archiv�s
     |
     |  get_archived_items_by_theme(self, theme: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      R�cup�re les �l�ments archiv�s par th�me.
     |
     |      Args:
     |          theme: Th�me des �l�ments � r�cup�rer
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments archiv�s pour le th�me sp�cifi�
     |
     |  get_item(self, item_id: str) -> Optional[Dict[str, Any]]
     |      R�cup�re un �l�ment par son identifiant.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � r�cup�rer
     |
     |      Returns:
     |          �l�ment r�cup�r� ou None si l'�l�ment n'existe pas
     |
     |  get_items_by_theme(self, theme: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      R�cup�re les �l�ments par th�me.
     |
     |      Args:
     |          theme: Th�me � rechercher
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant au th�me
     |
     |  get_theme_statistics(self) -> Dict[str, Dict[str, Any]]
     |      R�cup�re des statistiques sur les th�mes.
     |
     |      Returns:
     |          Dictionnaire des statistiques par th�me
     |
     |  get_version(self, item_id: str, version_number: int) -> Optional[Dict[str, Any]]
     |      R�cup�re une version sp�cifique d'un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          version_number: Num�ro de version
     |
     |      Returns:
     |          �l�ment � la version sp�cifi�e, ou None si la version n'existe pas
     |
     |  get_versions(self, item_id: str) -> List[Dict[str, Any]]
     |      R�cup�re toutes les versions d'un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |
     |      Returns:
     |          Liste des m�tadonn�es de versions, tri�es par num�ro de version d�croissant
     |
     |  get_versions_by_theme(self, theme: str, item_id: Optional[str] = None) -> Dict[str, List[Dict[str, Any]]]
     |      R�cup�re les versions des �l�ments d'un th�me.
     |
     |      Args:
     |          theme: Th�me des �l�ments
     |          item_id: Identifiant de l'�l�ment (optionnel)
     |
     |      Returns:
     |          Dictionnaire des versions par �l�ment
     |
     |  get_view(self, view_id: str) -> Optional[Dict[str, Any]]
     |      R�cup�re une vue th�matique par son identifiant.
     |
     |      Args:
     |          view_id: Identifiant de la vue � r�cup�rer
     |
     |      Returns:
     |          Vue th�matique ou None si la vue n'existe pas
     |
     |  index_item_for_vector_search(self, item_id: str) -> bool
     |      Indexe un �l�ment pour la recherche vectorielle.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � indexer
     |
     |      Returns:
     |          True si l'indexation a r�ussi, False sinon
     |
     |  index_items_by_theme_for_vector_search(self, theme: str) -> Dict[str, Any]
     |      Indexe tous les �l�ments d'un th�me pour la recherche vectorielle.
     |
     |      Args:
     |          theme: Th�me des �l�ments � indexer
     |
     |      Returns:
     |          Statistiques sur l'indexation
     |
     |  merge_theme_content(self, item_id: str, theme: str, content_to_merge: str) -> Optional[Dict[str, Any]]
     |      Fusionne du contenu dans les sections d'un �l�ment correspondant � un th�me.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � mettre � jour
     |          theme: Th�me des sections � mettre � jour
     |          content_to_merge: Contenu � fusionner
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
     |
     |  restore_archived_item(self, item_id: str) -> bool
     |      Restaure un �l�ment archiv�.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � restaurer
     |
     |      Returns:
     |          True si l'�l�ment a �t� restaur�, False sinon
     |
     |  restore_version(self, item_id: str, version_number: int) -> Optional[Dict[str, Any]]
     |      Restaure une version sp�cifique d'un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          version_number: Num�ro de version
     |
     |      Returns:
     |          �l�ment restaur�, ou None si la restauration a �chou�
     |
     |  rotate_archives(self, max_age_days: int = 90, max_items: int = 1000, backup_dir: Optional[str] = None) -> Dict[str, Any]
     |      Effectue une rotation des archives en d�pla�ant les archives anciennes vers un r�pertoire de sauvegarde
     |      ou en les supprimant.
     |
     |      Args:
     |          max_age_days: �ge maximum des archives en jours (d�faut: 90)
     |          max_items: Nombre maximum d'�l�ments � conserver (d�faut: 1000)
     |          backup_dir: R�pertoire de sauvegarde (optionnel, si None les archives sont supprim�es)
     |
     |      Returns:
     |          Statistiques sur la rotation (nombre d'�l�ments d�plac�s/supprim�s, etc.)
     |
     |  search_archived_items(self, query: str, themes: Optional[List[str]] = None, metadata_filters: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des �l�ments dans les archives.
     |
     |      Args:
     |          query: Requ�te textuelle � rechercher dans le contenu
     |          themes: Liste des th�mes � inclure dans la recherche (optionnel)
     |          metadata_filters: Filtres de m�tadonn�es (optionnel)
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments archiv�s correspondant aux crit�res de recherche
     |
     |  search_by_multi_criteria(self, themes: Optional[List[str]] = None, content_query: Optional[str] = None, metadata_filters: Optional[Dict[str, Any]] = None, date_range: Optional[Dict[str, str]] = None, theme_weights: Optional[Dict[str, float]] = None, sort_by: str = 'relevance', limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des �l�ments selon plusieurs crit�res combin�s.
     |
     |      Args:
     |          themes: Liste des th�mes � inclure dans la recherche (optionnel)
     |          content_query: Requ�te textuelle � rechercher dans le contenu (optionnel)
     |          metadata_filters: Filtres sur les m�tadonn�es (optionnel)
     |          date_range: Plage de dates pour la recherche (optionnel)
     |          theme_weights: Poids minimum pour chaque th�me (optionnel)
     |          sort_by: Crit�re de tri ("relevance", "date", "title", "theme_weight")
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant aux crit�res de recherche
     |
     |  search_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True, include_parent_themes: bool = False, max_depth: int = 3, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des �l�ments selon une hi�rarchie th�matique.
     |
     |      Args:
     |          theme: Th�me principal
     |          include_subthemes: Inclure les sous-th�mes
     |          include_parent_themes: Inclure les th�mes parents
     |          max_depth: Profondeur maximale de la hi�rarchie
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant aux crit�res de recherche
     |
     |  search_by_theme_relationships(self, primary_theme: str, related_themes: Optional[List[str]] = None, relationship_type: str = 'any', min_overlap: int = 1, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des �l�ments selon les relations entre th�mes.
     |
     |      Args:
     |          primary_theme: Th�me principal
     |          related_themes: Th�mes li�s (optionnel)
     |          relationship_type: Type de relation ("any", "all", "only")
     |          min_overlap: Nombre minimum de th�mes li�s requis
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant aux crit�res de recherche
     |
     |  search_items(self, query: str, themes: Optional[List[str]] = None, metadata_filters: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des �l�ments par requ�te textuelle et filtres.
     |
     |      Args:
     |          query: Requ�te textuelle � rechercher
     |          themes: Liste des th�mes � inclure dans la recherche (optionnel)
     |          metadata_filters: Filtres sur les m�tadonn�es (optionnel)
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant aux crit�res de recherche
     |
     |  search_similar_items(self, query: str, themes: Optional[List[str]] = None, top_k: int = 10, similarity_threshold: float = 0.7) -> List[Dict[str, Any]]
     |      Recherche des �l�ments similaires � une requ�te textuelle.
     |
     |      Args:
     |          query: Requ�te textuelle
     |          themes: Liste des th�mes � inclure dans la recherche (optionnel)
     |          top_k: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 10)
     |          similarity_threshold: Seuil de similarit� minimum (d�faut: 0.7)
     |
     |      Returns:
     |          Liste des �l�ments similaires avec leur score de similarit�
     |
     |  suggest_theme_corrections(self, item_id: str, expected_themes: Optional[List[str]] = None) -> Optional[Dict[str, Any]]
     |      Sugg�re des corrections th�matiques pour un �l�ment.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment
     |          expected_themes: Th�mes attendus (optionnel)
     |
     |      Returns:
     |          Suggestions de corrections th�matiques ou None si l'�l�ment n'existe pas
     |
     |  update_item(self, item_id: str, content: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None, create_version: bool = True, version_tag: Optional[str] = None, version_message: Optional[str] = None, context: Optional[Dict[str, Any]] = None, reattribute_themes: bool = True, detect_changes: bool = True) -> Optional[Dict[str, Any]]
     |      Met � jour un �l�ment existant avec d�tection des changements th�matiques.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � mettre � jour
     |          content: Nouveau contenu (optionnel)
     |          metadata: Nouvelles m�tadonn�es (optionnel)
     |          create_version: Si True, cr�e une nouvelle version apr�s la mise � jour
     |          version_tag: Tag de version (optionnel)
     |          version_message: Message de version (optionnel)
     |          context: Contexte d'attribution th�matique (optionnel)
     |          reattribute_themes: R�attribuer les th�mes si le contenu a chang� (d�faut: True)
     |          detect_changes: D�tecter les changements th�matiques (d�faut: True)
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
     |
     |  update_multiple_themes(self, item_id: str, theme_updates: Dict[str, str]) -> Optional[Dict[str, Any]]
     |      Met � jour plusieurs th�mes d'un �l�ment en une seule op�ration.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � mettre � jour
     |          theme_updates: Dictionnaire des th�mes � mettre � jour avec leur nouveau contenu
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
     |
     |  update_theme_sections(self, item_id: str, theme: str, new_content: str) -> Optional[Dict[str, Any]]
     |      Met � jour les sections d'un �l�ment correspondant � un th�me sp�cifique.
     |
     |      Args:
     |          item_id: Identifiant de l'�l�ment � mettre � jour
     |          theme: Th�me des sections � mettre � jour
     |          new_content: Nouveau contenu pour les sections
     |
     |      Returns:
     |          �l�ment mis � jour ou None si l'�l�ment n'existe pas
     |
     |  update_view(self, view_id: str, name: Optional[str] = None, description: Optional[str] = None, search_criteria: Optional[Dict[str, Any]] = None) -> Optional[Dict[str, Any]]
     |      Met � jour une vue th�matique existante.
     |
     |      Args:
     |          view_id: Identifiant de la vue � mettre � jour
     |          name: Nouveau nom de la vue (optionnel)
     |          description: Nouvelle description de la vue (optionnel)
     |          search_criteria: Nouveaux crit�res de recherche pour la vue (optionnel)
     |
     |      Returns:
     |          Vue th�matique mise � jour ou None si la vue n'existe pas
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


