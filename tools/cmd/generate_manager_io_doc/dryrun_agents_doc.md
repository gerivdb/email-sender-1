# AGENTS.md

## Purpose

Ce fichier documente les agents et managers principaux de l’architecture documentaire hybride du projet. Il décrit leurs rôles, interfaces, conventions d’utilisation et points d’extension. Jules et les collaborateurs s’appuient sur ce fichier pour comprendre et exploiter efficacement l’écosystème documentaire.

---

## Liste brute des managers détectés

- DocManager
- ConfigurableSyncRuleManager
- SmartMergeManager
- SyncHistoryManager
- ConflictManager
- ExtensibleManagerType
- N8NManager
- ErrorManager
- ScriptManager
- StorageManager
- SecurityManager
- MonitoringManager
- MaintenanceManager
- MigrationManager
- NotificationManagerImpl
- ChannelManagerImpl
- AlertManagerImpl
- SmartVariableSuggestionManager
- ProcessManager
- ContextManager
- ModeManager
- RoadmapManager
- RollbackManager
- CleanupManager
- QdrantManager
- SimpleAdvancedAutonomyManager
- VersionManagerImpl
- VectorOperationsManager

---

## Détail des managers

---

## Points d’extension & Plugins

- **PluginInterface :** Permet d’ajouter dynamiquement de nouveaux managers, stratégies de cache, vectorisation, etc.
- **CacheStrategy, VectorizationStrategy :** Systèmes ouverts pour personnaliser la gestion du cache et la vectorisation documentaire.

---

## Conventions générales

- **Entrée :** Documents, chemins, branches, requêtes API, plugins.
- **Sortie :** Documents, statuts, rapports, logs, suggestions.
- **Maintenance :** Mettre à jour ce fichier à chaque ajout ou modification d’agent, manager ou plugin.

---

_Tip : Un AGENTS.md à jour permet à Jules et à l’équipe de générer des plans et des complétions plus pertinents._
