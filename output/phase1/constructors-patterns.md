# Patterns Constructeurs - Analyse Complète

**Date de scan**: 2025-06-18 20:33:25  
**Branche**: dev  
**Fichiers scannés**: 761  
**Patterns recherchés**: 7  
**Constructeurs trouvés**: 255

## 📋 Résumé par Type de Pattern

### Pattern: `Factory` (181 constructeurs)

#### `NewAdvancedAutonomyManager()`

- **Fichier**: `advanced_autonomy_manager.go`
- **Package**: unknown
- **Ligne**: 129
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *AdvancedAutonomyManagerImpl, error

```go
func NewAdvancedAutonomyManager(config *AutonomyConfig, logger interfaces.Logger) (*AdvancedAutonomyManagerImpl, error) {
```
#### `NewAITemplateManager()`

- **Fichier**: `ai_template_manager.go`
- **Package**: unknown
- **Ligne**: 64
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *AITemplateManager

```go
func NewAITemplateManager(config *Config) *AITemplateManager {
```
#### `NewAlertManager()`

- **Fichier**: `alert-manager.go`
- **Package**: unknown
- **Ligne**: 89
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *AlertManager

```go
func NewAlertManager(config *AlertConfig, logger *log.Logger) *AlertManager {
```
#### `NewAlertManager()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 232
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *AlertManager

```go
func NewAlertManager() *AlertManager {
```
#### `NewAlertManager()`

- **Fichier**: `alert_manager.go`
- **Package**: unknown
- **Ligne**: 53
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: interfaces

```go
func NewAlertManager(logger *zap.Logger) interfaces.AlertManager {
```
#### `NewAlertManager()`

- **Fichier**: `alert-system.go`
- **Package**: unknown
- **Ligne**: 89
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *AlertManager

```go
func NewAlertManager(metrics *VectorizationMetrics) *AlertManager {
```
#### `NewAlertManager()`

- **Fichier**: `cachemetrics.go`
- **Package**: unknown
- **Ligne**: 114
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *AlertManager

```go
func NewAlertManager() *AlertManager {
```
#### `NewAlertManager()`

- **Fichier**: `test-stubs.go`
- **Package**: unknown
- **Ligne**: 345
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *AlertManager

```go
func NewAlertManager(config *AlertConfig, logger *log.Logger) *AlertManager {
```
#### `NewAnimationManager()`

- **Fichier**: `view_renderer.go`
- **Package**: unknown
- **Ligne**: 638
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *AnimationManager

```go
func NewAnimationManager() *AnimationManager {
```
#### `NewAtomicOperationsManager()`

- **Fichier**: `atomic-operations.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *AtomicOperationsManager

```go
func NewAtomicOperationsManager() *AtomicOperationsManager {
```
#### `NewAuthenticationManager()`

- **Fichier**: `auth_security.go`
- **Package**: unknown
- **Ligne**: 91
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *AuthenticationManager

```go
func NewAuthenticationManager(config *ConnectorConfig) *AuthenticationManager {
```
#### `NewAutoBranchCreationManager()`

- **Fichier**: `auto-branch-creation.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *AutoBranchCreationManager

```go
func NewAutoBranchCreationManager() *AutoBranchCreationManager {
```
#### `NewAutoClient()`

- **Fichier**: `factory.go`
- **Package**: unknown
- **Ligne**: 219
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: QdrantInterface, error

```go
func NewAutoClient() (QdrantInterface, error) {
```
#### `NewAutomatedWorkflowsManager()`

- **Fichier**: `automated-workflows.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *AutomatedWorkflowsManager

```go
func NewAutomatedWorkflowsManager() *AutomatedWorkflowsManager {
```
#### `NewBranchingManager()`

- **Fichier**: `branching_manager.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *BranchingManager

```go
func NewBranchingManager(config *Config) *BranchingManager {
```
#### `NewBranchingManager()`

- **Fichier**: `branching_manager.go`
- **Package**: unknown
- **Ligne**: 117
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *BranchingManagerImpl, error

```go
func NewBranchingManager(configPath string) (*BranchingManagerImpl, error) {
```
#### `NewBranchingManagerImpl()`

- **Fichier**: `branching_manager.go`
- **Package**: unknown
- **Ligne**: 143
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *BranchingManagerImpl

```go
func NewBranchingManagerImpl(config *BranchingConfig) *BranchingManagerImpl {
```
#### `NewChannelManager()`

- **Fichier**: `channel_manager.go`
- **Package**: unknown
- **Ligne**: 30
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: interfaces

```go
func NewChannelManager(logger *zap.Logger) interfaces.ChannelManager {
```
#### `NewCleanupManager()`

- **Fichier**: `cleanup_manager.go`
- **Package**: unknown
- **Ligne**: 122
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *CleanupManager

```go
func NewCleanupManager(config *core.CleanupConfig, aiAnalyzer *ai.AIAnalyzer) *CleanupManager {
```
#### `NewClient()`

- **Fichier**: `client.go`
- **Package**: unknown
- **Ligne**: 20
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *Client

```go
func NewClient(cfg *config.OpenAIConfig) *Client {
```
#### `NewClient()`

- **Fichier**: `qdrant.go`
- **Package**: unknown
- **Ligne**: 64
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *Client

```go
func NewClient(baseURL string) *Client {
```
#### `NewClientFactory()`

- **Fichier**: `factory.go`
- **Package**: unknown
- **Ligne**: 44
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *ClientFactory

```go
func NewClientFactory() *ClientFactory {
```
#### `NewCodeGenerationManager()`

- **Fichier**: `code-generation.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *CodeGenerationManager

```go
func NewCodeGenerationManager() *CodeGenerationManager {
```
#### `NewCollectionManager()`

- **Fichier**: `collection_manager.go`
- **Package**: unknown
- **Ligne**: 19
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *CollectionManager

```go
func NewCollectionManager() *CollectionManager {
```
#### `NewConfigManager()`

- **Fichier**: `deployment.go`
- **Package**: unknown
- **Ligne**: 160
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ConfigManager

```go
func NewConfigManager(configPath string) *ConfigManager {
```
#### `NewConformityManager()`

- **Fichier**: `conformity_manager.go`
- **Package**: unknown
- **Ligne**: 419
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *ConformityManager

```go
func NewConformityManager(errorManager ErrorManager, logger *zap.Logger, config *ConformityConfig) *ConformityManager {
```
#### `NewContainerManager()`

- **Fichier**: `container_manager.go`
- **Package**: unknown
- **Ligne**: 107
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: ContainerManager

```go
func NewContainerManager(logger *zap.Logger, dockerHost, composeFile string) ContainerManager {
```
#### `NewContextManager()`

- **Fichier**: `context.go`
- **Package**: unknown
- **Ligne**: 74
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ContextManager

```go
func NewContextManager(baseDir string) *ContextManager {
```
#### `NewContextPreservationManager()`

- **Fichier**: `context-preservation.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *ContextPreservationManager

```go
func NewContextPreservationManager() *ContextPreservationManager {
```
#### `NewContextSwitchingManager()`

- **Fichier**: `context-switching.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *ContextSwitchingManager

```go
func NewContextSwitchingManager() *ContextSwitchingManager {
```
#### `NewContextualMemoryManager()`

- **Fichier**: `contextual_memory_manager.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *ContextualMemoryManagerImpl

```go
func NewContextualMemoryManager() *ContextualMemoryManagerImpl {
```
#### `NewContextualMemoryManager()`

- **Fichier**: `contextual_memory_manager.go`
- **Package**: unknown
- **Ligne**: 30
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func NewContextualMemoryManager(
```
#### `NewContextualShortcutManager()`

- **Fichier**: `contextual_shortcuts.go`
- **Package**: unknown
- **Ligne**: 44
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ContextualShortcutManager

```go
func NewContextualShortcutManager(pm *PanelManager) *ContextualShortcutManager {
```
#### `NewCrossManagerEventBus()`

- **Fichier**: `cross_manager_event_bus.go`
- **Package**: unknown
- **Ligne**: 200
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *CrossManagerEventBus, error

```go
func NewCrossManagerEventBus(config *EventBusConfig, logger interfaces.Logger) (*CrossManagerEventBus, error) {
```
#### `NewDefaultAdvancedAutonomyManager()`

- **Fichier**: `advanced-autonomy-manager.go`
- **Package**: unknown
- **Ligne**: 35
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *DefaultAdvancedAutonomyManager

```go
func NewDefaultAdvancedAutonomyManager(notifications NotificationSystem) *DefaultAdvancedAutonomyManager {
```
#### `NewDefaultManagerCoordinator()`

- **Fichier**: `manager_coordinator.go`
- **Package**: unknown
- **Ligne**: 32
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *DefaultManagerCoordinator

```go
func NewDefaultManagerCoordinator(name string, manager interfaces.BaseManager, logger *logrus.Logger) *DefaultManagerCoordinator {
```
#### `NewDepConfigManager()`

- **Fichier**: `dependency_manager.go`
- **Package**: unknown
- **Ligne**: 1010
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: ConfigManager

```go
func NewDepConfigManager(config *Config, logger *zap.Logger, errorManager ErrorManager) ConfigManager {
```
#### `NewDepConfigManager()`

- **Fichier**: `dependency_manager.go`
- **Package**: unknown
- **Ligne**: 855
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: ConfigManager

```go
func NewDepConfigManager(config *Config, logger *zap.Logger, errorManager ErrorManager) ConfigManager {
```
#### `NewDependencyManager()`

- **Fichier**: `dependency_manager.go`
- **Package**: unknown
- **Ligne**: 163
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: interfaces

```go
func NewDependencyManager() interfaces.DependencyManager {
```
#### `NewDeploymentManager()`

- **Fichier**: `deployment_manager.go`
- **Package**: unknown
- **Ligne**: 89
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: DeploymentManager

```go
func NewDeploymentManager(logger *zap.Logger, buildConfig string) DeploymentManager {
```
#### `NewDimensionMergeManager()`

- **Fichier**: `dimension-merge.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *DimensionMergeManager

```go
func NewDimensionMergeManager() *DimensionMergeManager {
```
#### `NewDisasterRecoveryManager()`

- **Fichier**: `emergency_response_system.go`
- **Package**: unknown
- **Ligne**: 1071
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *DisasterRecoveryManager, error

```go
func NewDisasterRecoveryManager(config *DisasterConfig, logger interfaces.Logger) (*DisasterRecoveryManager, error) {
```
#### `NewDuplicationErrorHandler()`

- **Fichier**: `duplication_handler.go`
- **Package**: unknown
- **Ligne**: 45
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *DuplicationErrorHandler

```go
func NewDuplicationErrorHandler(reportsPath string, watchInterval time.Duration) *DuplicationErrorHandler {
```
#### `NewDynamicBranchingManager()`

- **Fichier**: `dynamic-branching.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *DynamicBranchingManager

```go
func NewDynamicBranchingManager() *DynamicBranchingManager {
```
#### `NewEmailManager()`

- **Fichier**: `email_manager.go`
- **Package**: unknown
- **Ligne**: 76
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: interfaces.EmailManager, error

```go
func NewEmailManager() (interfaces.EmailManager, error) {
```
#### `NewEmailService()`

- **Fichier**: `service.go`
- **Package**: unknown
- **Ligne**: 68
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *EmailService

```go
func NewEmailService(redisClient *redis.Client) *EmailService {
```
#### `NewEmbeddedClient()`

- **Fichier**: `embedded_client.go`
- **Package**: unknown
- **Ligne**: 32
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *EmbeddedClient

```go
func NewEmbeddedClient(config *EmbeddedConfig) *EmbeddedClient {
```
#### `NewEmbeddedClientSimple()`

- **Fichier**: `factory.go`
- **Package**: unknown
- **Ligne**: 225
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: QdrantInterface, error

```go
func NewEmbeddedClientSimple() (QdrantInterface, error) {
```
#### `NewEmbeddingManager()`

- **Fichier**: `embeddings.go`
- **Package**: unknown
- **Ligne**: 29
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *EmbeddingManager

```go
func NewEmbeddingManager(provider EmbeddingProvider, config *IndexingConfig) *EmbeddingManager {
```
#### `NewEntanglementManager()`

- **Fichier**: `entanglement.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *EntanglementManager

```go
func NewEntanglementManager() *EntanglementManager {
```
#### `NewErrorHandler()`

- **Fichier**: `error_handler.go`
- **Package**: unknown
- **Ligne**: 93
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *ErrorHandler

```go
func NewErrorHandler(config RetryConfig, logger *zap.Logger) *ErrorHandler {
```
#### `NewErrorHandler()`

- **Fichier**: `error_handler.go`
- **Package**: unknown
- **Ligne**: 47
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ErrorHandler

```go
func NewErrorHandler(logger *log.Logger) *ErrorHandler {
```
#### `NewErrorManagerService()`

- **Fichier**: `bridge_server.go`
- **Package**: unknown
- **Ligne**: 97
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ErrorManagerService

```go
func NewErrorManagerService(logger *zap.Logger) *ErrorManagerService {
```
#### `NewErrorManagerService()`

- **Fichier**: `bridge_server.go`
- **Package**: unknown
- **Ligne**: 97
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ErrorManagerService

```go
func NewErrorManagerService(logger *zap.Logger) *ErrorManagerService {
```
#### `NewEscalationManager()`

- **Fichier**: `emergency_response_system.go`
- **Package**: unknown
- **Ligne**: 1102
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *EscalationManager, error

```go
func NewEscalationManager(config *EscalationConfig, logger interfaces.Logger) (*EscalationManager, error) {
```
#### `NewEventListenersManager()`

- **Fichier**: `event-listeners.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *EventListenersManager

```go
func NewEventListenersManager() *EventListenersManager {
```
#### `NewEvolutionManager()`

- **Fichier**: `manager.go`
- **Package**: unknown
- **Ligne**: 120
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *EvolutionManager

```go
func NewEvolutionManager() *EvolutionManager {
```
#### `NewExternalClientSimple()`

- **Fichier**: `factory.go`
- **Package**: unknown
- **Ligne**: 231
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: QdrantInterface, error

```go
func NewExternalClientSimple(baseURL string) (QdrantInterface, error) {
```
#### `NewExternalToolsManager()`

- **Fichier**: `external_tools.go`
- **Package**: unknown
- **Ligne**: 125
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *ExternalToolsManager

```go
func NewExternalToolsManager(projectPath, outputDir string) *ExternalToolsManager {
```
#### `NewFailoverManager()`

- **Fichier**: `emergency_response_system.go`
- **Package**: unknown
- **Ligne**: 1007
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *FailoverManager, error

```go
func NewFailoverManager(config *FailoverConfig, logger interfaces.Logger) (*FailoverManager, error) {
```
#### `NewFloatingManager()`

- **Fichier**: `floating.go`
- **Package**: unknown
- **Ligne**: 35
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *FloatingManager

```go
func NewFloatingManager() *FloatingManager {
```
#### `NewGitOperationsManager()`

- **Fichier**: `git_operations.go`
- **Package**: unknown
- **Ligne**: 44
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *GitOperationsManager, error

```go
func NewGitOperationsManager(config *GitConfig) (*GitOperationsManager, error) {
```
#### `NewGitWorkflowManager()`

- **Fichier**: `git_workflow_manager.go`
- **Package**: unknown
- **Ligne**: 46
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func NewGitWorkflowManager(
```
#### `NewGitWorkflowManagerFactory()`

- **Fichier**: `git_workflow_manager.go`
- **Package**: unknown
- **Ligne**: 449
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *GitWorkflowManagerFactory

```go
func NewGitWorkflowManagerFactory() *GitWorkflowManagerFactory {
```
#### `NewGlobalStateManager()`

- **Fichier**: `global_state_manager.go`
- **Package**: unknown
- **Ligne**: 213
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *GlobalStateManager, error

```go
func NewGlobalStateManager(config *StateManagerConfig, logger interfaces.Logger) (*GlobalStateManager, error) {
```
#### `NewGoModManager()`

- **Fichier**: `dependency_manager.go`
- **Package**: unknown
- **Ligne**: 112
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *GoModManager

```go
func NewGoModManager(modFilePath string, config *Config) *GoModManager {
```
#### `NewGoModManager()`

- **Fichier**: `dependency_manager.go`
- **Package**: unknown
- **Ligne**: 127
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *GoModManager

```go
func NewGoModManager(modFilePath string, config *Config) *GoModManager {
```
#### `NewHandler()`

- **Fichier**: `auth.go`
- **Package**: unknown
- **Ligne**: 28
- **Exportée**: True
- **Paramètres**: 4
- **Type retourné**: *Handler

```go
func NewHandler(db database.Database, jwtService *jwt.Service, cfg *config.MCPGatewayConfig, logger *zap.Logger) *Handler {
```
#### `NewHybridRedisClient()`

- **Fichier**: `fallback_cache.go`
- **Package**: unknown
- **Ligne**: 154
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *HybridRedisClient, error

```go
func NewHybridRedisClient(config *RedisConfig) (*HybridRedisClient, error) {
```
#### `NewImportManager()`

- **Fichier**: `import_manager.go`
- **Package**: unknown
- **Ligne**: 29
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *ImportManager

```go
func NewImportManager(logger *zap.Logger, projectRoot string) *ImportManager {
```
#### `NewIndexManager()`

- **Fichier**: `index_manager.go`
- **Package**: unknown
- **Ligne**: 34
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func NewIndexManager(
```
#### `NewInfrastructureAPIHandler()`

- **Fichier**: `infrastructure_endpoints.go`
- **Package**: unknown
- **Ligne**: 21
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *InfrastructureAPIHandler

```go
func NewInfrastructureAPIHandler(orchestrator infrastructure.InfrastructureOrchestrator) *InfrastructureAPIHandler {
```
#### `NewInfrastructureDiscoveryService()`

- **Fichier**: `infrastructure_discovery.go`
- **Package**: unknown
- **Ligne**: 67
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *InfrastructureDiscoveryService, error

```go
func NewInfrastructureDiscoveryService(cfg *config.Config, logger *logging.Logger) (*InfrastructureDiscoveryService, error) {
```
#### `NewIntegratedConfigManager()`

- **Fichier**: `integration.go`
- **Package**: unknown
- **Ligne**: 75
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *IntegratedConfigManager, error

```go
func NewIntegratedConfigManager(integrationMgr IntegrationManager) (*IntegratedConfigManager, error) {
```
#### `NewIntegrationManager()`

- **Fichier**: `integration_manager.go`
- **Package**: unknown
- **Ligne**: 32
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func NewIntegrationManager(
```
#### `NewIntegrationManager()`

- **Fichier**: `integration_manager.go`
- **Package**: unknown
- **Ligne**: 83
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *IntegrationManagerImpl

```go
func NewIntegrationManager(config *IntegrationConfig, logger *logrus.Logger) *IntegrationManagerImpl {
```
#### `NewIntelligentRecallManager()`

- **Fichier**: `intelligent-recall.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *IntelligentRecallManager

```go
func NewIntelligentRecallManager() *IntelligentRecallManager {
```
#### `NewInvalidationManager()`

- **Fichier**: `invalidationmanager.go`
- **Package**: unknown
- **Ligne**: 24
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *InvalidationManager

```go
func NewInvalidationManager(redisClient *redis.Client, ttlManager TTLCacheManager) *InvalidationManager {
```
#### `NewKeyConfigManager()`

- **Fichier**: `config_manager.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *KeyConfigManager

```go
func NewKeyConfigManager(configDir string) *KeyConfigManager {
```
#### `NewLayoutManager()`

- **Fichier**: `view_renderer.go`
- **Package**: unknown
- **Ligne**: 654
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *LayoutManager

```go
func NewLayoutManager() *LayoutManager {
```
#### `NewMaintenanceManager()`

- **Fichier**: `maintenance_manager.go`
- **Package**: unknown
- **Ligne**: 140
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *MaintenanceManager, error

```go
func NewMaintenanceManager(configPath string) (*MaintenanceManager, error) {
```
#### `NewMaintenanceManager()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 42
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *MaintenanceManager, error

```go
func NewMaintenanceManager() (*MaintenanceManager, error) {
```
#### `NewManager()`

- **Fichier**: `manager.go`
- **Package**: unknown
- **Ligne**: 24
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *Manager, error

```go
func NewManager(githubToken string, errorManager interfaces.ErrorManager) (*Manager, error) {
```
#### `NewManager()`

- **Fichier**: `manager.go`
- **Package**: unknown
- **Ligne**: 28
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *Manager, error

```go
func NewManager(repoPath string, errorManager interfaces.ErrorManager) (*Manager, error) {
```
#### `NewManager()`

- **Fichier**: `manager.go`
- **Package**: unknown
- **Ligne**: 23
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *Manager, error

```go
func NewManager(repoPath string, errorManager interfaces.ErrorManager) (*Manager, error) {
```
#### `NewManager()`

- **Fichier**: `manager.go`
- **Package**: unknown
- **Ligne**: 40
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *Manager, error

```go
func NewManager(config map[string]interface{}, errorManager interfaces.ErrorManager) (*Manager, error) {
```
#### `NewManagerDiscovery()`

- **Fichier**: `discovery.go`
- **Package**: unknown
- **Ligne**: 53
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ManagerDiscovery

```go
func NewManagerDiscovery(logger *zap.Logger) *ManagerDiscovery {
```
#### `NewManagerDiscoveryService()`

- **Fichier**: `manager_discovery.go`
- **Package**: unknown
- **Ligne**: 103
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *ManagerDiscoveryService, error

```go
func NewManagerDiscoveryService(config *DiscoveryConfig, logger interfaces.Logger) (*ManagerDiscoveryService, error) {
```
#### `NewManagerDiscoveryService()`

- **Fichier**: `manager_discovery.go`
- **Package**: unknown
- **Ligne**: 103
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *ManagerDiscoveryService, error

```go
func NewManagerDiscoveryService(config *DiscoveryConfig, logger interfaces.Logger) (*ManagerDiscoveryService, error) {
```
#### `NewManagerIntegrator()`

- **Fichier**: `manager_integration.go`
- **Package**: unknown
- **Ligne**: 54
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *ManagerIntegrator

```go
func NewManagerIntegrator(logger *zap.Logger, errorManager ErrorManager) *ManagerIntegrator {
```
#### `NewManagerToolkit()`

- **Fichier**: `toolkit.go`
- **Package**: unknown
- **Ligne**: 28
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *ManagerToolkit, error

```go
func NewManagerToolkit(baseDir, configPath string, dryRun bool) (*ManagerToolkit, error) {
```
#### `NewManagerToolkit()`

- **Fichier**: `toolkit.go`
- **Package**: unknown
- **Ligne**: 28
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *ManagerToolkit, error

```go
func NewManagerToolkit(baseDir, configPath string, dryRun bool) (*ManagerToolkit, error) {
```
#### `NewManagerToolkit()`

- **Fichier**: `manager_toolkit.go`
- **Package**: unknown
- **Ligne**: 507
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *ManagerToolkit, error

```go
func NewManagerToolkit(baseDir, configPath string, verbose bool) (*ManagerToolkit, error) {
```
#### `NewManagerToolkit()`

- **Fichier**: `manager.go`
- **Package**: unknown
- **Ligne**: 13
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *ManagerToolkit

```go
func NewManagerToolkit() *ManagerToolkit {
```
#### `NewManagerToolkitLib()`

- **Fichier**: `manager_toolkit_lib.go`
- **Package**: unknown
- **Ligne**: 28
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *ManagerToolkitLib, error

```go
func NewManagerToolkitLib(baseDir, configPath string, dryRun bool) (*ManagerToolkitLib, error) {
```
#### `NewManagerToolkitStub()`

- **Fichier**: `toolkit_stubs.go`
- **Package**: unknown
- **Ligne**: 31
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *ManagerToolkit

```go
func NewManagerToolkitStub(rootDir, configPath string, debug bool) *ManagerToolkit {
```
#### `NewMemoryOptimizationManager()`

- **Fichier**: `memory-optimization.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *MemoryOptimizationManager

```go
func NewMemoryOptimizationManager() *MemoryOptimizationManager {
```
#### `NewMigrationManager()`

- **Fichier**: `migrations.go`
- **Package**: unknown
- **Ligne**: 20
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *MigrationManager

```go
func NewMigrationManager(storageDir string) *MigrationManager {
```
#### `NewMockAdvancedAutonomyManager()`

- **Fichier**: `semantic_embeddings.go`
- **Package**: unknown
- **Ligne**: 79
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *MockAdvancedAutonomyManager

```go
func NewMockAdvancedAutonomyManager() *MockAdvancedAutonomyManager {
```
#### `NewMockEmailService()`

- **Fichier**: `email_service.go`
- **Package**: unknown
- **Ligne**: 27
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *MockEmailService

```go
func NewMockEmailService() *MockEmailService {
```
#### `NewMockErrorManager()`

- **Fichier**: `integration_demo.go`
- **Package**: unknown
- **Ligne**: 28
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *MockErrorManager

```go
func NewMockErrorManager() *MockErrorManager {
```
#### `NewMockQDrantClient()`

- **Fichier**: `qdrant_client.go`
- **Package**: unknown
- **Ligne**: 70
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *MockQDrantClient

```go
func NewMockQDrantClient() *MockQDrantClient {
```
#### `NewMockStorageManager()`

- **Fichier**: `branching_manager.go`
- **Package**: unknown
- **Ligne**: 2624
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *MockStorageManager

```go
func NewMockStorageManager() *MockStorageManager {
```
#### `NewModeManager()`

- **Fichier**: `mode_manager.go`
- **Package**: unknown
- **Ligne**: 290
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *ModeManager

```go
func NewModeManager() *ModeManager {
```
#### `NewModeSpecificKeyManager()`

- **Fichier**: `mode_key_adaptation.go`
- **Package**: unknown
- **Ligne**: 49
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *ModeSpecificKeyManager

```go
func NewModeSpecificKeyManager(pm *PanelManager, csm *ContextualShortcutManager) *ModeSpecificKeyManager {
```
#### `NewMonitoringManager()`

- **Fichier**: `monitoring_manager.go`
- **Package**: unknown
- **Ligne**: 49
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func NewMonitoringManager(
```
#### `NewMonitoringManager()`

- **Fichier**: `monitoring_manager.go`
- **Package**: unknown
- **Ligne**: 145
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: MonitoringManager

```go
func NewMonitoringManager(logger *zap.Logger) MonitoringManager {
```
#### `NewN8NManager()`

- **Fichier**: `n8n_manager.go`
- **Package**: unknown
- **Ligne**: 87
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *N8NManager

```go
func NewN8NManager(config Config, logger *zap.Logger, errorManager *ErrorManager) *N8NManager {
```
#### `NewNavigationManager()`

- **Fichier**: `manager.go`
- **Package**: unknown
- **Ligne**: 46
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *NavigationManager

```go
func NewNavigationManager(configDir string) *NavigationManager {
```
#### `NewNeuralNetworksManager()`

- **Fichier**: `neural-networks.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *NeuralNetworksManager

```go
func NewNeuralNetworksManager() *NeuralNetworksManager {
```
#### `NewNotificationManager()`

- **Fichier**: `notification_manager.go`
- **Package**: unknown
- **Ligne**: 90
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: interfaces

```go
func NewNotificationManager(config *NotificationConfig, logger *zap.Logger) interfaces.NotificationManager {
```
#### `NewPanelManager()`

- **Fichier**: `types.go`
- **Package**: unknown
- **Ligne**: 84
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *PanelManager

```go
func NewPanelManager(width, height int, layout LayoutConfig) *PanelManager {
```
#### `NewParallelDimensionsManager()`

- **Fichier**: `parallel-dimensions.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *ParallelDimensionsManager

```go
func NewParallelDimensionsManager() *ParallelDimensionsManager {
```
#### `NewPatternAnalysisManager()`

- **Fichier**: `pattern-analysis.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *PatternAnalysisManager

```go
func NewPatternAnalysisManager() *PatternAnalysisManager {
```
#### `NewPIDManager()`

- **Fichier**: `pid.go`
- **Package**: unknown
- **Ligne**: 15
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *PIDManager

```go
func NewPIDManager(pidFile string) *PIDManager {
```
#### `NewPIDManagerFromConfig()`

- **Fichier**: `pid.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *PIDManager

```go
func NewPIDManagerFromConfig(pidFile string) *PIDManager {
```
#### `NewPostgreSQLStorageManager()`

- **Fichier**: `postgresql_storage.go`
- **Package**: unknown
- **Ligne**: 32
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *PostgreSQLStorageManager, error

```go
func NewPostgreSQLStorageManager(config *PostgreSQLConfig) (*PostgreSQLStorageManager, error) {
```
#### `NewPredictiveModelingManager()`

- **Fichier**: `predictive-modeling.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *PredictiveModelingManager

```go
func NewPredictiveModelingManager() *PredictiveModelingManager {
```
#### `NewProcessManager()`

- **Fichier**: `process_manager.go`
- **Package**: unknown
- **Ligne**: 134
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ProcessManager

```go
func NewProcessManager(config *Config) *ProcessManager {
```
#### `NewQdrantClient()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 371
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: QdrantClient

```go
func NewQdrantClient(url string) QdrantClient {
```
#### `NewQdrantClient()`

- **Fichier**: `qdrant_retrieval_manager.go`
- **Package**: unknown
- **Ligne**: 77
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *QdrantClient, error

```go
func NewQdrantClient(endpoint, apiKey, collection string) (*QdrantClient, error) {
```
#### `NewQdrantClient()`

- **Fichier**: `client.go`
- **Package**: unknown
- **Ligne**: 64
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *QdrantClient, error

```go
func NewQdrantClient(baseURL string, options ...Option) (*QdrantClient, error) {
```
#### `NewQdrantClient()`

- **Fichier**: `qdrant.go`
- **Package**: unknown
- **Ligne**: 54
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *QdrantClient

```go
func NewQdrantClient(baseURL string) *QdrantClient {
```
#### `NewQdrantClient()`

- **Fichier**: `qdrant.go`
- **Package**: unknown
- **Ligne**: 40
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *QdrantClient

```go
func NewQdrantClient(baseURL string) *QdrantClient {
```
#### `NewQdrantManager()`

- **Fichier**: `qdrant_manager.go`
- **Package**: unknown
- **Ligne**: 61
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *QdrantManager, error

```go
func NewQdrantManager(logger *zap.Logger, config core.VectorDBConfig) (*QdrantManager, error) {
```
#### `NewQdrantRetrievalManager()`

- **Fichier**: `qdrant_retrieval_manager.go`
- **Package**: unknown
- **Ligne**: 45
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *QdrantRetrievalManager, error

```go
func NewQdrantRetrievalManager(vectorConfig interfaces.VectorDBConfig, embeddingConfig interfaces.EmbeddingConfig) (*QdrantRetrievalManager, error) {
```
#### `NewQdrantVectorManager()`

- **Fichier**: `qdrant_vector.go`
- **Package**: unknown
- **Ligne**: 60
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *QdrantVectorManager, error

```go
func NewQdrantVectorManager(config *QdrantConfig) (*QdrantVectorManager, error) {
```
#### `NewQuantumCollapseManager()`

- **Fichier**: `quantum-collapse.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *QuantumCollapseManager

```go
func NewQuantumCollapseManager() *QuantumCollapseManager {
```
#### `NewQuantumSuperpositionManager()`

- **Fichier**: `quantum-superposition.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *QuantumSuperpositionManager

```go
func NewQuantumSuperpositionManager() *QuantumSuperpositionManager {
```
#### `NewQueueManager()`

- **Fichier**: `queue_manager.go`
- **Package**: unknown
- **Ligne**: 50
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: interfaces

```go
func NewQueueManager(logger *zap.Logger, queueSize int) interfaces.QueueManager {
```
#### `NewRAGClient()`

- **Fichier**: `rag_client.go`
- **Package**: unknown
- **Ligne**: 68
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *RAGClient, error

```go
func NewRAGClient(baseURL string, logger *zap.Logger) (*RAGClient, error) {
```
#### `NewRAGClient()`

- **Fichier**: `client.go`
- **Package**: unknown
- **Ligne**: 54
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *RAGClient

```go
func NewRAGClient(qdrantURL, openaiURL, apiKey string) *RAGClient {
```
#### `NewRealContainerManagerConnector()`

- **Fichier**: `real_manager_integration.go`
- **Package**: unknown
- **Ligne**: 145
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *RealContainerManagerConnector

```go
func NewRealContainerManagerConnector(logger *zap.Logger, errorManager ErrorManager) *RealContainerManagerConnector {
```
#### `NewRealDeploymentManagerConnector()`

- **Fichier**: `real_manager_integration.go`
- **Package**: unknown
- **Ligne**: 159
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *RealDeploymentManagerConnector

```go
func NewRealDeploymentManagerConnector(logger *zap.Logger, errorManager ErrorManager) *RealDeploymentManagerConnector {
```
#### `NewRealIntegratedManagerAdapter()`

- **Fichier**: `integration.go`
- **Package**: unknown
- **Ligne**: 34
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *RealIntegratedManagerAdapter

```go
func NewRealIntegratedManagerAdapter(errorMgr IntegratedErrorManagerInterface) *RealIntegratedManagerAdapter {
```
#### `NewRealIntegratedManagerConnector()`

- **Fichier**: `real_integration.go`
- **Package**: unknown
- **Ligne**: 23
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *RealIntegratedManagerConnector

```go
func NewRealIntegratedManagerConnector(errorMgr RealIntegratedErrorManager) *RealIntegratedManagerConnector {
```
#### `NewRealManagerConnector()`

- **Fichier**: `real_manager_integration.go`
- **Package**: unknown
- **Ligne**: 26
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *RealManagerConnector

```go
func NewRealManagerConnector(logger *zap.Logger, errorManager ErrorManager) *RealManagerConnector {
```
#### `NewRealMonitoringManagerConnector()`

- **Fichier**: `real_manager_integration.go`
- **Package**: unknown
- **Ligne**: 91
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *RealMonitoringManagerConnector

```go
func NewRealMonitoringManagerConnector(logger *zap.Logger, errorManager ErrorManager) *RealMonitoringManagerConnector {
```
#### `NewRealSecurityManagerConnector()`

- **Fichier**: `real_manager_integration.go`
- **Package**: unknown
- **Ligne**: 73
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *RealSecurityManagerConnector

```go
func NewRealSecurityManagerConnector(logger *zap.Logger, errorManager ErrorManager) *RealSecurityManagerConnector {
```
#### `NewRealStorageManagerConnector()`

- **Fichier**: `real_manager_integration.go`
- **Package**: unknown
- **Ligne**: 126
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *RealStorageManagerConnector

```go
func NewRealStorageManagerConnector(logger *zap.Logger, errorManager ErrorManager) *RealStorageManagerConnector {
```
#### `NewReconnectionManager()`

- **Fichier**: `reconnection_manager.go`
- **Package**: unknown
- **Ligne**: 67
- **Exportée**: True
- **Paramètres**: 5
- **Type retourné**: *ReconnectionManager

```go
func NewReconnectionManager(client *redis.Client, config *ReconnectionConfig, errorHandler *ErrorHandler, circuitBreaker *CircuitBreaker, logger *log.Logger) *ReconnectionManager {
```
#### `NewRedisClient()`

- **Fichier**: `redis_client.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *RedisClient, error

```go
func NewRedisClient(config *redisconfig.RedisConfig) (*RedisClient, error) {
```
#### `NewRedisClientFromDefaults()`

- **Fichier**: `redis_client.go`
- **Package**: unknown
- **Ligne**: 63
- **Exportée**: True
- **Paramètres**: 4
- **Type retourné**: *RedisClient, error

```go
func NewRedisClientFromDefaults(host string, port int, password string, db int) (*RedisClient, error) {
```
#### `NewResourceManager()`

- **Fichier**: `performance.go`
- **Package**: unknown
- **Ligne**: 267
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: *ResourceManager

```go
func NewResourceManager(maxWorkers int, maxMemoryMB uint64, monitor *PerformanceMonitor) *ResourceManager {
```
#### `NewRetrievalManager()`

- **Fichier**: `retrieval_manager.go`
- **Package**: unknown
- **Ligne**: 24
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func NewRetrievalManager(
```
#### `NewRoadmapManagerConnector()`

- **Fichier**: `roadmap_manager_connector.go`
- **Package**: unknown
- **Ligne**: 118
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *RoadmapManagerConnector

```go
func NewRoadmapManagerConnector(config *ConnectorConfig) *RoadmapManagerConnector {
```
#### `NewScriptManager()`

- **Fichier**: `script_manager.go`
- **Package**: unknown
- **Ligne**: 189
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ScriptManager

```go
func NewScriptManager(config *Config) *ScriptManager {
```
#### `NewSearchService()`

- **Fichier**: `searchservice.go`
- **Package**: unknown
- **Ligne**: 82
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *SearchService

```go
func NewSearchService(qdrant QDrantClient, embedder EmbeddingService) *SearchService {
```
#### `NewSearchService()`

- **Fichier**: `searchservice.go`
- **Package**: unknown
- **Ligne**: 93
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *SearchService

```go
func NewSearchService(qdrant QDrantClient, embedder EmbeddingService) *SearchService {
```
#### `NewSecurityManager()`

- **Fichier**: `security_manager.go`
- **Package**: unknown
- **Ligne**: 72
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: SecurityManager

```go
func NewSecurityManager(logger *zap.Logger) SecurityManager {
```
#### `NewSecurityManager()`

- **Fichier**: `security_manager.go`
- **Package**: unknown
- **Ligne**: 70
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *SecurityManagerImpl, error

```go
func NewSecurityManager(config *Config) (*SecurityManagerImpl, error) {
```
#### `NewSemanticEmbeddingManager()`

- **Fichier**: `semantic_embeddings.go`
- **Package**: unknown
- **Ligne**: 275
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *SemanticEmbeddingManager

```go
func NewSemanticEmbeddingManager(config *Config) *SemanticEmbeddingManager {
```
#### `NewService()`

- **Fichier**: `jwt.go`
- **Package**: unknown
- **Ligne**: 35
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *Service

```go
func NewService(config Config) *Service {
```
#### `NewServiceDependencyGraph()`

- **Fichier**: `service_dependency_graph.go`
- **Package**: unknown
- **Ligne**: 18
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *ServiceDependencyGraph, error

```go
func NewServiceDependencyGraph(config *ServiceDependencyGraphConfig) (*ServiceDependencyGraph, error) {
```
#### `NewSessionManagementManager()`

- **Fichier**: `session-management.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *SessionManagementManager

```go
func NewSessionManagementManager() *SessionManagementManager {
```
#### `NewSimpleAdvancedAutonomyManager()`

- **Fichier**: `simple_freeze_fix.go`
- **Package**: unknown
- **Ligne**: 39
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *SimpleAdvancedAutonomyManager

```go
func NewSimpleAdvancedAutonomyManager(logger Logger) *SimpleAdvancedAutonomyManager {
```
#### `NewSmartInfrastructureManager()`

- **Fichier**: `smart_orchestrator.go`
- **Package**: unknown
- **Ligne**: 91
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *SmartInfrastructureManager, error

```go
func NewSmartInfrastructureManager() (*SmartInfrastructureManager, error) {
```
#### `NewSmartSecurityManager()`

- **Fichier**: `security_manager.go`
- **Package**: unknown
- **Ligne**: 122
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *SmartSecurityManager

```go
func NewSmartSecurityManager(config *SecurityConfig) *SmartSecurityManager {
```
#### `NewSmartVariableSuggestionManager()`

- **Fichier**: `smart_variable_manager.go`
- **Package**: unknown
- **Ligne**: 136
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *SmartVariableSuggestionManager

```go
func NewSmartVariableSuggestionManager(config *Config) *SmartVariableSuggestionManager {
```
#### `NewSQLiteIndexManager()`

- **Fichier**: `sqlite_index_manager.go`
- **Package**: unknown
- **Ligne**: 32
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *SQLiteIndexManager, error

```go
func NewSQLiteIndexManager(databasePath string) (*SQLiteIndexManager, error) {
```
#### `NewStateBackupManager()`

- **Fichier**: `global_state_manager.go`
- **Package**: unknown
- **Ligne**: 789
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *StateBackupManager, error

```go
func NewStateBackupManager(config *BackupConfig, logger interfaces.Logger) (*StateBackupManager, error) {
```
#### `NewStateIsolationManager()`

- **Fichier**: `state-isolation.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *StateIsolationManager

```go
func NewStateIsolationManager() *StateIsolationManager {
```
#### `NewStateRecreationManager()`

- **Fichier**: `state-recreation.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *StateRecreationManager

```go
func NewStateRecreationManager() *StateRecreationManager {
```
#### `NewStorageManager()`

- **Fichier**: `manager.go`
- **Package**: unknown
- **Ligne**: 19
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *StorageManager

```go
func NewStorageManager() *StorageManager {
```
#### `NewStorageManager()`

- **Fichier**: `storage_manager.go`
- **Package**: unknown
- **Ligne**: 111
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: interfaces

```go
func NewStorageManager() interfaces.StorageManager {
```
#### `NewStorageManager()`

- **Fichier**: `storage_manager.go`
- **Package**: unknown
- **Ligne**: 82
- **Exportée**: True
- **Paramètres**: 3
- **Type retourné**: StorageManager

```go
func NewStorageManager(logger *zap.Logger, pgConnString, qdrantURL string) StorageManager {
```
#### `NewSyncClient()`

- **Fichier**: `qdrant.go`
- **Package**: unknown
- **Ligne**: 71
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *SyncClient, error

```go
func NewSyncClient(baseURL string, logger *zap.Logger) (*SyncClient, error) {
```
#### `NewSyncClient()`

- **Fichier**: `qdrant_legacy.go`
- **Package**: unknown
- **Ligne**: 158
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *SyncClient, error

```go
func NewSyncClient(baseURL string, logger *zap.Logger) (*SyncClient, error) {
```
#### `NewSyncClient()`

- **Fichier**: `qdrant_legacy.go`
- **Package**: unknown
- **Ligne**: 88
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *SyncClient, error

```go
func NewSyncClient(baseURL string, logger *zap.Logger) (*SyncClient, error) {
```
#### `NewTemplateManager()`

- **Fichier**: `template_manager.go`
- **Package**: unknown
- **Ligne**: 33
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: interfaces

```go
func NewTemplateManager(logger *zap.Logger) interfaces.TemplateManager {
```
#### `NewTemporalNavigationManager()`

- **Fichier**: `temporal-navigation.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *TemporalNavigationManager

```go
func NewTemporalNavigationManager() *TemporalNavigationManager {
```
#### `NewTimeTravelManager()`

- **Fichier**: `time-travel.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *TimeTravelManager

```go
func NewTimeTravelManager() *TimeTravelManager {
```
#### `NewTriggerSystemManager()`

- **Fichier**: `trigger-system.go`
- **Package**: unknown
- **Ligne**: 17
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: *TriggerSystemManager

```go
func NewTriggerSystemManager() *TriggerSystemManager {
```
#### `NewTTLManager()`

- **Fichier**: `manager.go`
- **Package**: unknown
- **Ligne**: 62
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *TTLManager

```go
func NewTTLManager(redisClient *redis.Client, config *TTLConfig) *TTLManager {
```
#### `NewUnifiedClient()`

- **Fichier**: `client.go`
- **Package**: unknown
- **Ligne**: 110
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *UnifiedClient, error

```go
func NewUnifiedClient(baseURL string, logger *zap.Logger) (*UnifiedClient, error) {
```
#### `NewUnifiedQdrantClient()`

- **Fichier**: `unified_client.go`
- **Package**: unknown
- **Ligne**: 86
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *UnifiedQdrantClient

```go
func NewUnifiedQdrantClient(config UnifiedClientConfig) *UnifiedQdrantClient {
```
#### `NewVectorClient()`

- **Fichier**: `client.go`
- **Package**: unknown
- **Ligne**: 35
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *VectorClient, error

```go
func NewVectorClient(config *ClientConfig) (*VectorClient, error) {
```
#### `NewVectorClient()`

- **Fichier**: `phase_4_performance_validation.go`
- **Package**: unknown
- **Ligne**: 83
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *VectorClient

```go
func NewVectorClient(logger *zap.Logger) *VectorClient {
```
#### `NewVectorClient()`

- **Fichier**: `vector_client.go`
- **Package**: unknown
- **Ligne**: 54
- **Exportée**: True
- **Paramètres**: 2
- **Type retourné**: *VectorClient, error

```go
func NewVectorClient(config VectorConfig, logger *zap.Logger) (*VectorClient, error) {
```
#### `NewVersionManager()`

- **Fichier**: `version_manager.go`
- **Package**: unknown
- **Ligne**: 16
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: interfaces

```go
func NewVersionManager() interfaces.VersionManager {
```
#### `NewWebhookIntegrationManager()`

- **Fichier**: `webhook_integration_manager.go`
- **Package**: unknown
- **Ligne**: 54
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: *WebhookIntegrationManager, error

```go
func NewWebhookIntegrationManager(config map[string]interface{}) (*WebhookIntegrationManager, error) {
```

### Pattern: `Initializer` (71 constructeurs)

#### `init()`

- **Fichier**: `serve.go`
- **Package**: unknown
- **Ligne**: 21
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `metrics.go`
- **Package**: unknown
- **Ligne**: 20
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `root.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `search.go`
- **Package**: unknown
- **Ligne**: 24
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `serve.go`
- **Package**: unknown
- **Ligne**: 21
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `index.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `metrics.go`
- **Package**: unknown
- **Ligne**: 20
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `root.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `search.go`
- **Package**: unknown
- **Ligne**: 24
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `serve.go`
- **Package**: unknown
- **Ligne**: 21
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `index.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `generator.go`
- **Package**: unknown
- **Ligne**: 445
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `generator.go`
- **Package**: unknown
- **Ligne**: 503
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `generator.go`
- **Package**: unknown
- **Ligne**: 531
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `generator.go`
- **Package**: unknown
- **Ligne**: 559
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `index.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 90
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 50
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 24
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `mcp-server.go`
- **Package**: unknown
- **Ligne**: 39
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 118
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `generator.go`
- **Package**: unknown
- **Ligne**: 475
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `type_def_generator.go`
- **Package**: unknown
- **Ligne**: 477
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `struct_validator.go`
- **Package**: unknown
- **Ligne**: 815
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `import_conflict_resolver.go`
- **Package**: unknown
- **Ligne**: 512
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `example_usage.go`
- **Package**: unknown
- **Ligne**: 244
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `search.go`
- **Package**: unknown
- **Ligne**: 24
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `root.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `metrics.go`
- **Package**: unknown
- **Ligne**: 20
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `index.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `serve.go`
- **Package**: unknown
- **Ligne**: 21
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 376
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `advanced_ingest.go`
- **Package**: unknown
- **Ligne**: 44
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `hierarchy.go`
- **Package**: unknown
- **Ligne**: 42
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `naming_normalizer.go`
- **Package**: unknown
- **Ligne**: 630
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `intelligence.go`
- **Package**: unknown
- **Ligne**: 318
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `ingest.go`
- **Package**: unknown
- **Ligne**: 57
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `migrate.go`
- **Package**: unknown
- **Ligne**: 34
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `validate.go`
- **Package**: unknown
- **Ligne**: 53
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `validate.go`
- **Package**: unknown
- **Ligne**: 69
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `search.go`
- **Package**: unknown
- **Ligne**: 24
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `root.go`
- **Package**: unknown
- **Ligne**: 22
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `metrics.go`
- **Package**: unknown
- **Ligne**: 20
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `dependency_analyzer.go`
- **Package**: unknown
- **Ligne**: 512
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `duplicate_type_detector.go`
- **Package**: unknown
- **Ligne**: 433
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `syntax_checker.go`
- **Package**: unknown
- **Ligne**: 456
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `init()`

- **Fichier**: `markdown_sync.go`
- **Package**: unknown
- **Ligne**: 57
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func init() {
```
#### `initConfig()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 65
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: *config

```go
func initConfig() *config.APIServerConfig {
```
#### `initDatabase()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 91
- **Exportée**: False
- **Paramètres**: 2
- **Type retourné**: database

```go
func initDatabase(logger *zap.Logger, cfg *config.DatabaseConfig) database.Database {
```
#### `InitDefaultTenant()`

- **Fichier**: `util.go`
- **Package**: unknown
- **Ligne**: 12
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: error

```go
func InitDefaultTenant(db *gorm.DB) error {
```
#### `initI18n()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 245
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: unknown

```go
func initI18n(cfg *config.I18nConfig) {
```
#### `initializeBuild()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 85
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: error

```go
func initializeBuild(config *BuildConfig) error {
```
#### `initializeLevelNames()`

- **Fichier**: `advanced_parser.go`
- **Package**: unknown
- **Ligne**: 876
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: map

```go
func initializeLevelNames(maxDepth int) map[int]string {
```
#### `InitializeLogger()`

- **Fichier**: `logger.go`
- **Package**: unknown
- **Ligne**: 10
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: error

```go
func InitializeLogger() error {
```
#### `InitializeManagerHooks()`

- **Fichier**: `manager_hooks.go`
- **Package**: unknown
- **Ligne**: 11
- **Exportée**: True
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func InitializeManagerHooks() {
```
#### `InitializePostgres()`

- **Fichier**: `postgres.go`
- **Package**: unknown
- **Ligne**: 15
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: error

```go
func InitializePostgres(connStr string) error {
```
#### `InitializeQdrant()`

- **Fichier**: `qdrant.go`
- **Package**: unknown
- **Ligne**: 26
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: error

```go
func InitializeQdrant(endpoint string) error {
```
#### `initializeValidationRules()`

- **Fichier**: `smart_variable_manager.go`
- **Package**: unknown
- **Ligne**: 801
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: unknown

```go
func initializeValidationRules() []ValidationRule {
```
#### `initializeVulnerabilityDB()`

- **Fichier**: `security_manager.go`
- **Package**: unknown
- **Ligne**: 238
- **Exportée**: False
- **Paramètres**: 0
- **Type retourné**: map

```go
func initializeVulnerabilityDB() map[string]*interfaces.Vulnerability { // Changed to store *interfaces.Vulnerability
```
#### `initLogger()`

- **Fichier**: `templates.go`
- **Package**: unknown
- **Ligne**: 536
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: *zap.Logger, error

```go
func initLogger(level string) (*zap.Logger, error) {
```
#### `initLogger()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 233
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: *zap.Logger, error

```go
func initLogger(level string) (*zap.Logger, error) {
```
#### `initLogger()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 141
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: *zap

```go
func initLogger(verbose bool) *zap.Logger {
```
#### `initLogger()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 692
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: *zap

```go
func initLogger(verbose bool) *zap.Logger {
```
#### `initLogger()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 56
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: *zap

```go
func initLogger(cfg *config.APIServerConfig) *zap.Logger {
```
#### `initLogger()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 553
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: *zap

```go
func initLogger(verbose bool) *zap.Logger {
```
#### `initNotifier()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 74
- **Exportée**: False
- **Paramètres**: 3
- **Type retourné**: notifier

```go
func initNotifier(ctx context.Context, logger *zap.Logger, cfg *config.NotifierConfig) notifier.Notifier {
```
#### `initOpenAI()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 86
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: *openai

```go
func initOpenAI(cfg *config.OpenAIConfig) *openai.Client {
```
#### `initRouter()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 142
- **Exportée**: False
- **Paramètres**: 6
- **Type retourné**: *gin

```go
func initRouter(db database.Database, store storage.Store, ntf notifier.Notifier, openaiClient *openai.Client, cfg *config.APIServerConfig, logger *zap.Logger) *gin.Engine {
```
#### `initStore()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 102
- **Exportée**: False
- **Paramètres**: 2
- **Type retourné**: storage

```go
func initStore(logger *zap.Logger, cfg *config.StorageConfig) storage.Store {
```
#### `initSuperAdmin()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 111
- **Exportée**: False
- **Paramètres**: 3
- **Type retourné**: error

```go
func initSuperAdmin(ctx context.Context, db database.Database, cfg *config.APIServerConfig) error {
```
#### `InitTranslator()`

- **Fichier**: `core.go`
- **Package**: unknown
- **Ligne**: 30
- **Exportée**: True
- **Paramètres**: 1
- **Type retourné**: error

```go
func InitTranslator(translationsPath string) error {
```

### Pattern: `Setup` (3 constructeurs)

#### `setupCallbacks()`

- **Fichier**: `complete_demo.go`
- **Package**: unknown
- **Ligne**: 55
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: unknown

```go
func setupCallbacks(mgr *manager.Manager) {
```
#### `setupLogger()`

- **Fichier**: `main.go`
- **Package**: unknown
- **Ligne**: 115
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: *log

```go
func setupLogger(logPath string) *log.Logger {
```
#### `setupTestEcosystem()`

- **Fichier**: `complete_ecosystem_integration.go`
- **Package**: unknown
- **Ligne**: 142
- **Exportée**: False
- **Paramètres**: 1
- **Type retourné**: *EcosystemTestSuite

```go
func setupTestEcosystem(logger *zap.Logger) *EcosystemTestSuite {
```

## 📦 Résumé par Package

- **unknown**: 255 constructeurs [Factory(181), Initializer(71), Setup(3)]
## 🔄 Analyse et Recommandations

### Répartition par Pattern
- **Factory**: 181 constructeurs (71%)
- **Initializer**: 71 constructeurs (27.8%)
- **Setup**: 3 constructeurs (1.2%)
### Constructeurs avec Beaucoup de Paramètres (>3)
- initRouter (6 paramètres) dans main.go
- NewReconnectionManager (5 paramètres) dans reconnection_manager.go
- NewRedisClientFromDefaults (4 paramètres) dans redis_client.go
- NewHandler (4 paramètres) dans auth.go
### Constructeurs Non-Exportés
- initLogger dans main.go (unknown)
- init dans example_usage.go (unknown)
- initLogger dans templates.go (unknown)
- init dans main.go (unknown)
- init dans advanced_ingest.go (unknown)
- init dans hierarchy.go (unknown)
- init dans ingest.go (unknown)
- init dans intelligence.go (unknown)
- init dans markdown_sync.go (unknown)
- init dans migrate.go (unknown)
- init dans validate.go (unknown)
- init dans validate.go (unknown)
- initializeLevelNames dans advanced_parser.go (unknown)
- initializeVulnerabilityDB dans security_manager.go (unknown)
- initializeValidationRules dans smart_variable_manager.go (unknown)
- init dans dependency_analyzer.go (unknown)
- init dans duplicate_type_detector.go (unknown)
- init dans syntax_checker.go (unknown)
- init dans import_conflict_resolver.go (unknown)
- init dans naming_normalizer.go (unknown)
- init dans type_def_generator.go (unknown)
- init dans struct_validator.go (unknown)
- init dans index.go (unknown)
- init dans metrics.go (unknown)
- init dans root.go (unknown)
- init dans search.go (unknown)
- init dans serve.go (unknown)
- init dans index.go (unknown)
- init dans metrics.go (unknown)
- init dans root.go (unknown)
- init dans search.go (unknown)
- init dans serve.go (unknown)
- init dans generator.go (unknown)
- init dans generator.go (unknown)
- init dans generator.go (unknown)
- init dans generator.go (unknown)
- init dans generator.go (unknown)
- initLogger dans main.go (unknown)
- initLogger dans main.go (unknown)
- initLogger dans main.go (unknown)
- init dans main.go (unknown)
- initLogger dans main.go (unknown)
- initConfig dans main.go (unknown)
- initNotifier dans main.go (unknown)
- initOpenAI dans main.go (unknown)
- initDatabase dans main.go (unknown)
- initStore dans main.go (unknown)
- initSuperAdmin dans main.go (unknown)
- initRouter dans main.go (unknown)
- initI18n dans main.go (unknown)
- init dans main.go (unknown)
- init dans mcp-server.go (unknown)
- init dans main.go (unknown)
- init dans main.go (unknown)
- init dans index.go (unknown)
- init dans metrics.go (unknown)
- init dans root.go (unknown)
- init dans search.go (unknown)
- init dans serve.go (unknown)
- init dans index.go (unknown)
- init dans metrics.go (unknown)
- init dans root.go (unknown)
- init dans search.go (unknown)
- init dans serve.go (unknown)
- initializeBuild dans main.go (unknown)
- setupLogger dans main.go (unknown)
- setupTestEcosystem dans complete_ecosystem_integration.go (unknown)
- setupCallbacks dans complete_demo.go (unknown)
---
*Généré par Tâche Atomique 003 - 2025-06-18 20:33:27*
