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

### DocManager

- **Rôle :** Orchestrateur central de la gestion documentaire (création, coordination, cohérence).
- **Interfaces :**
  - `Store(*Document) error`, `Retrieve(string) (*Document, error)`
  - `RegisterPlugin(PluginInterface) error`
- **Utilisation :** Toutes les opérations documentaires passent par DocManager. Extension possible via plugins.
- **Entrée/Sortie :** Documents structurés, résultats d’opérations, logs.

### ConfigurableSyncRuleManager

- **Rôle :** Manager de règles de synchronisation documentaire configurables.
- **Interfaces :** À compléter selon l’implémentation.
- **Utilisation :** Gestion des règles de synchronisation personnalisées.
- **Entrée/Sortie :** Règles, statuts, logs.

### SmartMergeManager

- **Rôle :** Manager de fusion intelligente de documents ou branches.
- **Interfaces :** À compléter selon l’implémentation.
- **Utilisation :** Fusion automatisée avec gestion avancée des conflits.
- **Entrée/Sortie :** Documents fusionnés, rapports de conflits.

### SyncHistoryManager

- **Rôle :** Historique des synchronisations documentaires.
- **Interfaces :** À compléter selon l’implémentation.
- **Utilisation :** Suivi et audit des opérations de synchronisation.
- **Entrée/Sortie :** Logs, historiques, rapports.

### ConflictManager

- **Rôle :** Gestion et résolution des conflits documentaires.
- **Interfaces :** À compléter selon l’implémentation.
- **Utilisation :** Détection et résolution automatique ou assistée des conflits.
- **Entrée/Sortie :** Documents résolus, logs de résolution.

### ExtensibleManagerType

- **Rôle :** Manager extensible via plugins ou stratégies.
- **Interfaces :**
  - `RegisterPlugin(plugin PluginInterface) error`
  - `UnregisterPlugin(name string) error`
  - `ListPlugins() []PluginInfo`
  - `GetPlugin(name string) (PluginInterface, error)`
- **Utilisation :** Ajout dynamique de fonctionnalités ou de stratégies (ex : plugins documentaires, extensions de logique).
- **Entrée/Sortie :** Plugins, stratégies, informations sur les plugins, erreurs éventuelles.

### N8NManager

- **Rôle :** Orchestration des workflows n8n et gestion des exécutions.
- **Interfaces :**
  - `Start(ctx context.Context) error`
  - `Stop() error`
  - `IsHealthy() bool`
  - `GetStatus() ManagerStatus`
  - `ExecuteWorkflow(ctx context.Context, request *WorkflowRequest) (*WorkflowResponse, error)`
  - `ValidateWorkflow(ctx context.Context, workflow *WorkflowDefinition) (*ValidationResult, error)`
  - `GetWorkflowStatus(workflowID string) (*WorkflowStatus, error)`
  - `CancelWorkflow(ctx context.Context, workflowID string) error`
  - `ConvertData(ctx context.Context, data *DataConversionRequest) (*DataConversionResponse, error)`
  - `ValidateSchema(ctx context.Context, schema *SchemaValidationRequest) (*SchemaValidationResponse, error)`
  - `MapParameters(ctx context.Context, params *ParameterMappingRequest) (*ParameterMappingResponse, error)`
  - `ValidateParameters(ctx context.Context, params *ParameterValidationRequest) (*ParameterValidationResponse, error)`
  - `EnqueueJob(ctx context.Context, job *Job) error`
  - `DequeueJob(ctx context.Context, queueName string) (*Job, error)`
  - `GetQueueStatus(queueName string) (*QueueStatus, error)`
  - `GetMetrics() (*ManagerMetrics, error)`
  - `GetLogs(ctx context.Context, filter *LogFilter) ([]*LogEntry, error)`
  - `Subscribe(eventType EventType) (<-chan Event, error)`
- **Utilisation :** Centralisation des appels, exécutions et gestion des erreurs n8n (API, queue, logs, monitoring).
- **Entrée/Sortie :** Workflows, statuts, logs, métriques, jobs, événements.

### ErrorManager

- **Rôle :** Centralise la gestion, la validation et la journalisation structurée des erreurs dans le système de gestion des dépendances et autres modules.
- **Interfaces :**
  - `ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error`
  - `CatalogError(entry ErrorEntry) error`
  - `ValidateErrorEntry(entry ErrorEntry) error`
- **Utilisation :** Injecté dans GoModManager, ConfigManager, etc. pour uniformiser le traitement des erreurs et assurer la traçabilité.
- **Entrée/Sortie :**
  - Entrées : erreurs Go, entrées structurées (ErrorEntry), contexte d’exécution.
  - Sorties : erreurs Go standard (validation, journalisation, etc.).

### ScriptManager

- **Rôle :** Orchestration complète de l’exécution, du suivi, du rechargement et de la gestion des scripts (PowerShell, etc.) avec intégration ErrorManager.
- **Interfaces :**
  - `ExecuteScript(scriptID string, parameters map[string]interface{}) (*ExecutionResult, error)`
  - `ListScripts() []*ManagedScript`
  - `GetScript(scriptID string) (*ManagedScript, error)`
  - `CreateScriptFromTemplate(templateID, scriptName string, parameters map[string]interface{}) (*ManagedScript, error)`
  - `Shutdown() error`
- **Utilisation :** Centralise l’exécution, la découverte, la création et la gestion des scripts et templates. Utilisé par d’autres modules pour automatiser des tâches via scripts.
- **Entrée/Sortie :**
  - Entrées : identifiants de scripts, paramètres d’exécution, templates, contexte d’exécution.
  - Sorties : résultats d’exécution, erreurs, logs, scripts générés.

### StorageManager

- **Rôle :** Centralise la gestion de la persistance documentaire, du stockage objet, des connexions PostgreSQL/Qdrant et des métadonnées de dépendances.
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `GetPostgreSQLConnection() (interface{}, error)`
  - `GetQdrantConnection() (interface{}, error)`
  - `RunMigrations(ctx context.Context) error`
  - `SaveDependencyMetadata(ctx context.Context, metadata *interfaces.DependencyMetadata) error`
  - `GetDependencyMetadata(ctx context.Context, name string) (*interfaces.DependencyMetadata, error)`
  - `QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*interfaces.DependencyMetadata, error)`
  - `HealthCheck(ctx context.Context) error`
  - `Cleanup() error`
- **Utilisation :** Centralise toutes les opérations de stockage, migration et récupération documentaire. Utilisé par d’autres managers pour la persistance, la migration et la recherche vectorielle.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, métadonnées, requêtes de dépendances, objets à stocker.
  - Sorties : statuts, objets/document récupérés, erreurs, logs.

### SecurityManager

- **Rôle :** Centralise la gestion de la sécurité documentaire, des accès, des secrets, de l’audit et de la détection de vulnérabilités.
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `LoadSecrets(ctx context.Context) error`
  - `GetSecret(key string) (string, error)`
  - `GenerateAPIKey(ctx context.Context, scope string) (string, error)`
  - `ValidateAPIKey(ctx context.Context, key string) (bool, error)`
  - `EncryptData(data []byte) ([]byte, error)`
  - `DecryptData(encryptedData []byte) ([]byte, error)`
  - `ScanForVulnerabilities(ctx context.Context, dependencies []interfaces.DependencyMetadata) (*interfaces.VulnerabilityReport, error)`
  - `HealthCheck(ctx context.Context) error`
  - `Cleanup() error`
- **Utilisation :** Contrôle d’accès, gestion des secrets, audit, chiffrement, génération/validation de clés API, détection de vulnérabilités.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, clés, secrets, dépendances, données à chiffrer.
  - Sorties : statuts, alertes, rapports de vulnérabilité, données chiffrées/déchiffrées, logs.

### MonitoringManager

- **Rôle :** Supervise et monitor l’écosystème documentaire, collecte des métriques système et applicatives, génère des rapports et gère les alertes.
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `StartMonitoring(ctx context.Context) error`
  - `StopMonitoring(ctx context.Context) error`
  - `CollectMetrics(ctx context.Context) (*SystemMetrics, error)`
  - `CheckSystemHealth(ctx context.Context) (*HealthStatus, error)`
  - `ConfigureAlerts(ctx context.Context, config *AlertConfig) error`
  - `GenerateReport(ctx context.Context, duration time.Duration) (*PerformanceReport, error)`
  - `StartOperationMonitoring(ctx context.Context, operation string) (*OperationMetrics, error)`
  - `StopOperationMonitoring(ctx context.Context, metrics *OperationMetrics) error`
  - `GetMetricsHistory(ctx context.Context, duration time.Duration) ([]*SystemMetrics, error)`
  - `HealthCheck(ctx context.Context) error`
  - `Cleanup() error`
- **Utilisation :** Collecte de métriques, surveillance continue, génération de rapports de performance, gestion des alertes, suivi d’opérations critiques.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, configurations d’alertes, opérations à monitorer.
  - Sorties : métriques, rapports, statuts de santé, alertes, logs.

### MaintenanceManager

- **Rôle :** Orchestration centrale de la maintenance documentaire : nettoyage intelligent, optimisation, analyse de santé, historique des opérations, intégration IA.
- **Interfaces :**
  - `Start() error`
  - `Stop() error`
  - `PerformCleanup(level int) (*CleanupResult, error)`
  - `GetHealthScore() *OrganizationHealth`
  - `GetOperationHistory(limit int) []MaintenanceOperation`
- **Utilisation :** Démarrage/arrêt du framework, nettoyage intelligent, suivi de la santé documentaire, historique des opérations, intégration avec d’autres managers et IA.
- **Entrée/Sortie :**
  - Entrées : niveaux de nettoyage, configurations, contexte d’exécution.
  - Sorties : rapports, logs, résultats de nettoyage, score de santé, historique d’opérations.

### MigrationManager

- **Rôle :** Gère l’import/export et la migration de données (jobs, configs, tenants, etc.) entre versions ou environnements.
- **Interfaces :**
  - `ExportData(ctx context.Context, name string, data interface{}) (string, error)`
  - `ImportData(ctx context.Context, filename string, target interface{}) error`
  - `ListExports() ([]string, error)`
- **Utilisation :** Sauvegarde/export de données structurées, import/restauration, gestion des migrations lors des évolutions de schéma ou de version.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, noms/logiques d’export, données à migrer, fichiers d’export.
  - Sorties : chemins de fichiers exportés, erreurs, logs, données importées.

### NotificationManagerImpl

- **Rôle :** Gestion centralisée des notifications et alertes documentaires : envoi, planification, suivi, gestion des canaux et intégration alertes.
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `SendNotification(ctx context.Context, notification *interfaces.Notification) error`
  - `SendBulkNotifications(ctx context.Context, notifications []*interfaces.Notification) error`
  - `ScheduleNotification(ctx context.Context, notification *interfaces.Notification, sendTime time.Time) error`
  - `CancelNotification(ctx context.Context, notificationID string) error`
  - `ListChannels(ctx context.Context) ([]*interfaces.NotificationChannel, error)`
  - `TestChannel(ctx context.Context, channelID string) error`
  - `CreateAlert(ctx context.Context, alert *interfaces.Alert) error`
  - `UpdateAlert(ctx context.Context, alertID string, alert *interfaces.Alert) error`
  - `DeleteAlert(ctx context.Context, alertID string) error`
  - `TriggerAlert(ctx context.Context, alertID string, data map[string]interface{}) error`
  - `GetAlertHistory(ctx context.Context, alertID string) ([]*interfaces.AlertEvent, error)`
- **Utilisation :** Envoi et planification de notifications, gestion multi-canaux (Slack, Discord, Webhook, Email), intégration et gestion d’alertes, statistiques par canal.
- **Entrée/Sortie :**
  - Entrées : notifications, canaux, alertes, contextes d’exécution, paramètres de planification.
  - Sorties : statuts, logs, historiques d’alertes, statistiques, erreurs.

### ChannelManagerImpl

- **Rôle :** Gestion centralisée des canaux de notification/documentation : enregistrement, configuration, activation/désactivation, test et suivi des canaux (Slack, Discord, Webhook, Email, etc.).
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `RegisterChannel(ctx context.Context, channel *interfaces.NotificationChannel) error`
  - `UpdateChannel(ctx context.Context, channelID string, channel *interfaces.NotificationChannel) error`
  - `DeactivateChannel(ctx context.Context, channelID string) error`
  - `GetChannel(ctx context.Context, channelID string) (*interfaces.NotificationChannel, error)`
  - `ListChannels(ctx context.Context) ([]*interfaces.NotificationChannel, error)`
  - `TestChannel(ctx context.Context, channelID string) error`
  - `ValidateChannelConfig(ctx context.Context, channelType string, config map[string]interface{}) error`
- **Utilisation :** Configuration, gestion du cycle de vie et validation des canaux de notification/documentation, intégration avec NotificationManagerImpl.
- **Entrée/Sortie :**
  - Entrées : canaux, configurations, contextes d’exécution, identifiants de canaux.
  - Sorties : statuts, logs, listes de canaux, erreurs.

### AlertManagerImpl

- **Rôle :** Gestion centralisée des alertes documentaires : création, mise à jour, suppression, déclenchement, historique, évaluation automatique des conditions.
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `Shutdown(ctx context.Context) error`
  - `GetID() string`
  - `GetName() string`
  - `GetVersion() string`
  - `GetStatus() interfaces.ManagerStatus`
  - `IsHealthy(ctx context.Context) bool`
  - `GetMetrics() map[string]interface{}`
  - `CreateAlert(ctx context.Context, alert *interfaces.Alert) error`
  - `UpdateAlert(ctx context.Context, alertID string, alert *interfaces.Alert) error`
  - `DeleteAlert(ctx context.Context, alertID string) error`
  - `GetAlert(ctx context.Context, alertID string) (*interfaces.Alert, error)`
  - `ListAlerts(ctx context.Context) ([]*interfaces.Alert, error)`
  - `TriggerAlert(ctx context.Context, alertID string, data map[string]interface{}) error`
  - `GetAlertHistory(ctx context.Context, alertID string) ([]*interfaces.AlertEvent, error)`
  - `EvaluateAlertConditions(ctx context.Context) error`
- **Utilisation :** Détection, gestion, suivi et déclenchement d’alertes documentaires, intégration avec NotificationManagerImpl, évaluation automatique des conditions, gestion de l’historique et des événements d’alerte.
- **Entrée/Sortie :**
  - Entrées : alertes, contextes d’exécution, conditions, actions, données d’évaluation, événements.
  - Sorties : statuts, logs, historiques d’alertes, erreurs, métriques.

### SmartVariableSuggestionManager

- **Rôle :** Suggestion intelligente de variables pour les documents et scripts, basée sur l’analyse contextuelle, l’apprentissage d’usage et la validation automatique.
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `Shutdown(ctx context.Context) error`
  - `GetID() string`
  - `GetName() string`
  - `GetVersion() string`
  - `GetStatus() interfaces.ManagerStatus`
  - `IsHealthy(ctx context.Context) bool`
  - `GetMetrics() map[string]interface{}`
  - `AnalyzeContext(ctx context.Context, projectPath string) (*ContextAnalysis, error)`
  - `SuggestVariables(ctx context.Context, context *ContextAnalysis, template string) (*VariableSuggestions, error)`
  - `LearnFromUsage(ctx context.Context, variables map[string]interface{}, outcome *UsageOutcome) error`
  - `GetVariablePatterns(ctx context.Context, filters *PatternFilters) (*VariablePatterns, error)`
  - `ValidateVariableUsage(ctx context.Context, variables map[string]interface{}) (*ValidationReport, error)`
- **Utilisation :** Analyse de contexte projet, suggestion dynamique de variables adaptées, apprentissage à partir des usages, validation et extraction de patterns, intégration dans les assistants de complétion documentaire.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, chemins de projet, templates, variables, historiques d’usage, filtres de patterns.
  - Sorties : suggestions de variables, rapports d’analyse, patterns, rapports de validation, logs, métriques.

### ProcessManager

- **Rôle :** Orchestration et gestion du cycle de vie des processus documentaires et des autres managers, avec intégration avancée de la gestion d’erreur (ErrorManager) et du circuit breaker.
- **Interfaces :**
  - `StartProcess(name, command string, args []string, env map[string]string) (*ManagedProcess, error)`
  - `StopProcess(name string) error`
  - `GetProcessStatus(name string) (*ManagedProcess, error)`
  - `ListProcesses() map[string]*ManagedProcess`
  - `LoadManifests() error`
  - `ExecuteTask(managerName, taskName string, params map[string]interface{}) error`
  - `HealthCheck() map[string]bool`
  - `Shutdown() error`
- **Utilisation :** Lancement, arrêt, supervision, monitoring et gestion des processus externes ou internes ; exécution de tâches, gestion des erreurs, contrôle de la résilience via circuit breaker, intégration avec ErrorManager.
- **Entrée/Sortie :**
  - Entrées : noms de processus, commandes, arguments, variables d’environnement, paramètres de tâches, contextes d’exécution.
  - Sorties : statuts, logs, objets ManagedProcess, résultats de tâches, rapports de santé, erreurs.

### ContextManager

- **Rôle :** Gestion centralisée du contexte documentaire ou applicatif : persistance, restauration, sauvegarde automatique, gestion des snapshots et de l’état des panels/UI.
- **Interfaces :**
  - `SaveState(pm *PanelManager, fm *FloatingManager, minimizer *PanelMinimizer) error`
  - `LoadLatestState() (*ContextState, error)`
  - `LoadStateByTime(timestamp time.Time) (*ContextState, error)`
  - `RestoreState(state *ContextState, pm *PanelManager, fm *FloatingManager, minimizer *PanelMinimizer) error`
  - `ListSavedStates() ([]time.Time, error)`
  - `SetMaxSnapshots(max int)`
  - `SetAutoSaveInterval(interval time.Duration)`
  - `MarkDirty()`
  - `ShouldAutoSave() bool`
  - `DeleteState(timestamp time.Time) error`
  - `GetStateInfo(timestamp time.Time) (*ContextState, error)`
- **Utilisation :** Centralisation et gestion du contexte d’exécution, sauvegarde/restauration d’état, gestion de l’historique et des snapshots, intégration UI (panels, fenêtres, navigation), gestion de la persistance et de la sécurité (compression, chiffrement).
- **Entrée/Sortie :**
  - Entrées : panels, managers, états UI, timestamps, configurations de sauvegarde.
  - Sorties : contextes restaurés, listes de snapshots, statuts, logs, erreurs.

### ModeManager

- **Rôle :** Gestion centralisée des modes d’exécution ou de configuration documentaire : changement de mode, gestion de l’état, préférences, transitions, événements et historique.
- **Interfaces :**
  - `SwitchMode(targetMode NavigationMode) tea.Cmd`
  - `SwitchModeAdvanced(targetMode NavigationMode, options *TransitionOptions) tea.Cmd`
  - `GetCurrentMode() NavigationMode`
  - `GetModeConfig(mode NavigationMode) (*ModeConfig, error)`
  - `UpdateModeConfig(mode NavigationMode, config *ModeConfig) error`
  - `GetModeState(mode NavigationMode) (*ModeState, error)`
  - `RestoreState(state *ModeState) tea.Cmd`
  - `AddEventHandler(mode NavigationMode, handler ModeEventHandler) error`
  - `TriggerEvent(eventType ModeEventType, data map[string]interface{}) []tea.Cmd`
  - `GetAvailableModes() []NavigationMode`
  - `GetTransitionHistory() []ModeTransition`
  - `SetPreferences(prefs *ModePreferences)`
  - `GetPreferences() *ModePreferences`
- **Utilisation :** Changement et suivi des modes, gestion avancée des transitions, gestion de l’état et de l’historique, intégration UI, gestion des préférences utilisateur, gestion des événements et de la résilience (circuit breaker, ErrorManager).
- **Entrée/Sortie :**
  - Entrées : modes, configurations, options de transition, événements, préférences, états, contextes d’exécution.
  - Sorties : statuts, logs, historiques de transitions, états de mode, commandes UI, erreurs.

### RoadmapManager

- **Rôle :** Gestion de la feuille de route documentaire : synchronisation, planification, suivi, reporting, intégration avec Roadmap Manager externe (API/HTTP).
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `SyncPlanToRoadmapManager(ctx context.Context, dynamicPlan interface{}) (*SyncResponse, error)`
  - `SyncFromRoadmapManager(ctx context.Context, planID string) (*RoadmapPlan, error)`
  - `GetStats() *ConnectorStats`
  - `Close() error`
- **Utilisation :** Planification, synchronisation bidirectionnelle des roadmaps, suivi d’avancement, gestion des conflits, intégration API, collecte de métriques, gestion de la connexion et du cache.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, plans dynamiques, identifiants de plans, configurations de connexion.
  - Sorties : roadmaps, réponses de synchronisation, statistiques, logs, erreurs.

### RollbackManager

- **Rôle :** Gestion des rollbacks et restaurations documentaires.
- **Interfaces :**
  - `RollbackLast() error`
- **Utilisation :** Permet d’annuler la dernière résolution de conflit enregistrée dans l’historique (ConflictHistory). Utilisé pour restaurer un état antérieur en cas d’erreur ou de besoin de révision.
- **Entrée/Sortie :**
  - Entrée : aucune (opère sur l’historique interne)
  - Sortie : erreur éventuelle si le rollback échoue.

### CleanupManager

- **Rôle :** Nettoyage, organisation intelligente, suppression, détection de doublons, analyse de structure, reporting.
- **Interfaces :**
  - `ScanForCleanup(ctx context.Context, directories []string) ([]CleanupTask, error)`
  - `ExecuteTasks(ctx context.Context, tasks []CleanupTask, dryRun bool) error`
  - `GetStats() CleanupStats`
  - `GetHealthStatus(ctx context.Context) core.HealthStatus`
- **Utilisation :** Analyse et nettoyage de répertoires, suppression de fichiers temporaires ou obsolètes, détection de doublons, organisation automatique, reporting, intégration IA. Utilisé par MaintenanceManager et d’autres modules pour la maintenance documentaire.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, configurations, listes de répertoires, tâches de nettoyage.
  - Sorties : rapports, logs, statistiques, statuts de santé, erreurs éventuelles.

### QdrantManager

- **Rôle :** Gestion centralisée de la vectorisation documentaire et du stockage Qdrant (création, indexation, recherche, suppression, statistiques).
- **Interfaces :**
  - `Initialize(ctx context.Context) error`
  - `StoreVector(ctx context.Context, collectionName string, point VectorPoint) error`
  - `StoreBatch(ctx context.Context, collectionName string, points []VectorPoint) error`
  - `Search(ctx context.Context, collectionName string, queryVector []float32, limit int, filter map[string]interface{}) ([]SearchResult, error)`
  - `Delete(ctx context.Context, collectionName string, ids []string) error`
  - `GetStats(ctx context.Context) (*VectorStats, error)`
  - `GetCollections() map[string]*Collection`
  - `CreateCollection(ctx context.Context, name string, vectorSize int, distance string) error`
  - `GetHealth() core.HealthStatus`
  - `GetMetrics() map[string]interface{}`
- **Utilisation :** Indexation, recherche vectorielle, gestion des collections Qdrant, statistiques, intégration avec d’autres managers pour la vectorisation documentaire.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, noms de collections, vecteurs, requêtes de recherche, configurations.
  - Sorties : résultats de recherche, statuts, logs, statistiques, erreurs éventuelles.

### SimpleAdvancedAutonomyManager

- **Rôle :** Orchestration autonome avancée : coordination intelligente, maintenance prédictive, auto-réparation, optimisation et gestion d’urgence documentaire.
- **Interfaces :**
  - `OrchestrateAutonomousMaintenance(ctx context.Context) (*AutonomyResult, error)`
  - `PredictMaintenanceNeeds(ctx context.Context, timeHorizon time.Duration) (*PredictionResult, error)`
  - `ExecuteAutonomousDecisions(ctx context.Context, decisions []AutonomousDecision) error`
  - `MonitorEcosystemHealth(ctx context.Context) (*EcosystemHealth, error)`
  - `SetupSelfHealing(ctx context.Context, config *SelfHealingConfig) error`
  - `OptimizeResourceAllocation(ctx context.Context) (*ResourceOptimizationResult, error)`
  - `EstablishCrossManagerWorkflows(ctx context.Context, workflows []*CrossManagerWorkflow) error`
  - `HandleEmergencySituations(ctx context.Context, severity EmergencySeverity) (*EmergencyResponse, error)`
- **Utilisation :** Orchestration autonome de la maintenance, coordination des managers, prédiction des besoins, auto-réparation, optimisation des ressources, gestion d’urgence, workflows transverses.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, décisions autonomes, configurations, workflows, niveaux de sévérité.
  - Sorties : résultats d’autonomie, prédictions, réponses d’urgence, tableaux de bord, logs, erreurs éventuelles.

### VersionManagerImpl

- **Rôle :** Gestion centralisée des versions documentaires ou applicatives : comparaison, compatibilité, récupération de versions, sélection optimale.
- **Interfaces :**
  - `CompareVersions(v1, v2 string) int`
  - `IsCompatible(version string, constraints []string) bool`
  - `GetLatestVersion(ctx context.Context, packageName string) (string, error)`
  - `GetLatestStableVersion(ctx context.Context, packageName string) (string, error)`
  - `FindBestVersion(versions []string, constraints []string) (string, error)`
- **Utilisation :** Suivi, comparaison, validation et sélection de versions pour les dépendances ou documents ; utilisé par les managers de dépendances, migration, etc.
- **Entrée/Sortie :**
  - Entrées : versions, contraintes, contextes d’exécution, noms de packages.
  - Sorties : résultats de comparaison, versions compatibles, erreurs éventuelles.

### VectorOperationsManager

- **Rôle :** Orchestration des opérations de vectorisation documentaire : insertion, mise à jour, suppression, recherche, statistiques, gestion concurrente.
- **Interfaces :**
  - `BatchUpsertVectors(ctx context.Context, vectors []Vector) error`
  - `UpdateVector(ctx context.Context, vector Vector) error`
  - `DeleteVector(ctx context.Context, vectorID string) error`
  - `GetVector(ctx context.Context, vectorID string) (*Vector, error)`
  - `SearchVectorsParallel(ctx context.Context, queries []Vector, topK int) ([][]SearchResult, error)`
  - `BulkDelete(ctx context.Context, vectorIDs []string) error`
  - `GetStats(ctx context.Context) (map[string]interface{}, error)`
- **Utilisation :** Calcul, gestion, suivi et recherche de vecteurs, opérations concurrentes, intégration avec Qdrant ou autres backends, reporting statistique.
- **Entrée/Sortie détaillées :**
  - `BatchUpsertVectors`
    - Entrées :
      - `ctx context.Context` : contexte d’exécution
      - `vectors []Vector` : liste de vecteurs à insérer
    - Sortie :
      - `error` : erreur éventuelle
  - `UpdateVector`
    - Entrées :
      - `ctx context.Context` : contexte d’exécution
      - `vector Vector` : vecteur à mettre à jour
    - Sortie :
      - `error` : erreur éventuelle
  - `DeleteVector`
    - Entrées :
      - `ctx context.Context` : contexte d’exécution
      - `vectorID string` : identifiant du vecteur à supprimer
    - Sortie :
      - `error` : erreur éventuelle
  - `GetVector`
    - Entrées :
      - `ctx context.Context` : contexte d’exécution
      - `vectorID string` : identifiant du vecteur à récupérer
    - Sorties :
      - `*Vector` : vecteur récupéré (ou nil)
      - `error` : erreur éventuelle
  - `SearchVectorsParallel`
    - Entrées :
      - `ctx context.Context` : contexte d’exécution
      - `queries []Vector` : requêtes de recherche
      - `topK int` : nombre de résultats par requête
    - Sorties :
      - `[][]SearchResult` : résultats de recherche pour chaque requête
      - `error` : erreur éventuelle
  - `BulkDelete`
    - Entrées :
      - `ctx context.Context` : contexte d’exécution
      - `vectorIDs []string` : identifiants des vecteurs à supprimer
    - Sortie :
      - `error` : erreur éventuelle
  - `GetStats`
    - Entrées :
      - `ctx context.Context` : contexte d’exécution
    - Sorties :
      - `map[string]interface{}` : statistiques diverses
      - `error` : erreur éventuelle

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