# Inventaire du manager de dépendances (dependency-manager)

## Fichiers et packages

- **dependency_manager.go** (package: dependency)
  - Imports: sync, time, github.com/google/uuid, github.com/Masterminds/semver/v3, go.uber.org/zap, d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/interfaces
  - Types: DependencyManagerImpl, DependencyConfig, PackageManagerConfig, RegistryConfig, AuthConfig, SecurityConfig, ResolutionConfig, CacheConfig, DependencyGraph, DependencyNode, RegistryClient, PackageInfo, NPMRegistryClient
  - Méthodes: AddNode, HealthCheck, GetPackageInfo, SearchPackages, NewDependencyManager, initializeDependencyGraph, loadExistingMetadata, saveCache, checkRegistryHealth, DetectConflicts, hasConflict

- **base_methods.go** (package: dependency)
  - Imports: context, fmt, github.com/email-sender-manager/interfaces
  - Types: (aucun exporté)
  - Méthodes: GetID, GetName, GetVersion, GetStatus, Initialize, Start, Stop, Health, HealthCheck, Cleanup

- **config.go** (package: dependency)
  - Imports: os, strconv, time
  - Types: (aucun exporté)
  - Méthodes: loadDependencyConfig, getEnv, getEnvInt, getEnvBool, getDuration

- **helpers.go** (package: dependency)
  - Imports: context, encoding/json, fmt, os, strings, d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/interfaces
  - Types: ConfigFile
  - Méthodes: detectConfigFiles, analyzeConfigFile, analyzeGoMod, analyzePackageJson, analyzeCargoToml, analyzeRequirements, detectDependencyConflicts, detectResolutionConflicts, analyzeVulnerabilities, determineUpdateType

- **operations.go** (package: dependency)
  - Imports: context, fmt, path/filepath, time, github.com/email-sender-manager/interfaces
  - Types: (aucun exporté)
  - Méthodes: AnalyzeDependencies, ResolveDependencies, UpdateDependency, CheckForUpdates

- **package_resolver.go** (package: dependency)
  - Imports: context, fmt, time, github.com/email-sender-manager/interfaces
  - Types: PackageResolverImpl
  - Méthodes: NewPackageResolver, Resolve, GetVersions, FindCompatibleVersion, detectPackageManager, resolveGoPackage, resolveNpmPackage, getGoVersions, getNpmVersions

- **version_manager.go** (package: dependency)
  - Imports: context, fmt, strings, github.com/Masterminds/semver/v3, github.com/email-sender-manager/interfaces
  - Types: VersionManagerImpl
  - Méthodes: NewVersionManager, CompareVersions, IsCompatible, GetLatestVersion, GetLatestStableVersion, normalizeVersion, FindBestVersion

- **modules/deployment_integration.go** (package: deployment)
  - Imports: context, fmt, time
  - Types: (aucun exporté)
  - Méthodes: initializeDeploymentIntegration, checkDependencyDeploymentCompatibility, generateDeploymentMetadata, verifyDeploymentReadiness, exportDependencyLockfileForDeployment

- **modules/import_manager.go** (package: importmanager)
  - Imports: context, fmt, go/ast, go/parser, go/token, os, path/filepath, regexp, sort, strconv, strings, time, github.com/gerivdb/email-sender-1/development/managers/interfaces, go.uber.org/zap
  - Types: ImportManager
  - Méthodes: NewImportManager, ValidateImportPaths, validateFileImports, isValidImportPath, isAbsoluteLocalPath, isImportUnused, detectImportConflicts, calculateSummary, FixRelativeImports, getModuleName, fixRelativeImportsInFile, convertRelativeToAbsolute, NormalizeModulePaths, normalizeImportsInFile, normalizeLocalPath, DetectImportConflicts, ScanInvalidImports, AutoFixImports, createProjectBackup, removeUnusedImports, removeUnusedImportsFromFile, removeImportFromContent, ValidateModuleStructure, isValidModulePath, validateDependencies, GenerateImportReport, generateStatistics, generateRecommendations

- **modules/manager_interfaces.go** (package: interfaces)
  - Imports: context, time, go.uber.org/zap
  - Types: SecurityManagerInterface, MonitoringManagerInterface, StorageManagerInterface, ContainerManagerInterface, DeploymentManagerInterface, AlertConfig, HealthStatus, DependencyQuery, ContainerValidationResult, ContainerOptimization, ContainerDependency, DeploymentPlan, DeploymentStep, VulnerabilityReport, Vulnerability, OperationMetrics, SystemMetrics, IntegrationHealthStatus, DeploymentReadiness, ArtifactMetadata, ErrorManager, ErrorEntry, Dependency

- **modules/monitoring_integration.go** (package: monitoring)
  - Imports: context, fmt, github.com/gerivdb/email-sender-1/development/managers/interfaces
  - Types: (aucun exporté)
  - Méthodes: initializeMonitoringIntegration, monitorDependencyOperation, configureOperationAlerts, monitorSecurityAudit

- **modules/real_manager_integration.go** (package: realmanager)
  - Imports: context, fmt, time, github.com/gerivdb/email-sender-1/development/managers/interfaces, go.uber.org/zap
  - Types: RealManagerConnector, RealSecurityManagerConnector, RealMonitoringManagerConnector, RealStorageManagerConnector, RealContainerManagerConnector, RealDeploymentManagerConnector
  - Méthodes: NewRealManagerConnector, InitializeManagers, GetSecurityManager, GetMonitoringManager, GetStorageManager, GetContainerManager, GetDeploymentManager, NewRealSecurityManagerConnector, Initialize, ScanDependenciesForVulnerabilities, ValidateAPIKeyAccess, HealthCheck, NewRealMonitoringManagerConnector, StartOperationMonitoring, StopOperationMonitoring, CheckSystemHealth, ConfigureAlerts, CollectMetrics, NewRealStorageManagerConnector, SaveDependencyMetadata, GetDependencyMetadata, QueryDependencies, StoreObject, GetObject, DeleteObject, ListObjects, NewRealContainerManagerConnector, ValidateForContainerization, OptimizeForContainer, NewRealDeploymentManagerConnector, CheckDeploymentReadiness, GenerateDeploymentPlan, CheckDependencyCompatibility, GenerateArtifactMetadata

- **modules/security_integration.go** (package: security)
  - Imports: context, encoding/json, fmt, strings, time, github.com/gerivdb/email-sender-1/development/managers/interfaces
  - Types: VulnerabilityReport, VulnerabilityInfo, SecurityConfig, RegistryCredentials
  - Méthodes: initializeSecurityIntegration, loadRegistryCredentials, configureAuthForPrivateModules, scanDependenciesForVulnerabilities, generateVulnerabilityReport

- **modules/storage_integration.go** (package: storage)
  - Imports: context, fmt, time, github.com/gerivdb/email-sender-1/development/managers/interfaces
  - Types: (aucun exporté)
  - Méthodes: initializeStorageIntegration, persistDependencyMetadata, getDependencyMetadata, updateDependencyAuditStatus, listDependencyMetadata, syncDependenciesToStorage

- **tests/container_integration.go** (package: tests)
  - Imports: context, fmt, github.com/gerivdb/email-sender-1/development/managers/dependencymanager, github.com/gerivdb/email-sender-1/development/managers/interfaces
  - Types: (aucun exporté)
  - Méthodes: initializeContainerIntegration, validateDependenciesForContainer, optimizeDependenciesForContainer, generateDockerfileFromDependencies, getDependencyContainerStatus

- **tests/dependency_manager_config_test.go** (package: tests)
  - Imports: fmt, os, path/filepath, testing, time, go.uber.org/zap, go.uber.org/zap/zaptest, github.com/gerivdb/email-sender-1/development/managers/dependencymanager, github.com/gerivdb/email-sender-1/development/managers/interfaces
  - Types: MockStorageManager, MockSecurityManagerFull, MockMonitoringManagerFull
  - Méthodes: TestConfigManagerIntegration, TestConfigDefaultFallback, TestErrorManagerIntegration, NewMockStorageManager

- **tests/dependency_manager_integration_test.go** (package: tests)
  - Imports: context, testing, time, go.uber.org/zap/zaptest, github.com/gerivdb/email-sender-1/development/managers/dependencymanager, github.com/gerivdb/email-sender-1/development/managers/interfaces
  - Types: (aucun exporté)
  - Méthodes: TestDependencyManagerWithSecurityManager, TestDependencyManagerWithMonitoringManager, TestDependencyManagerCrossManagerIntegration

- **tests/dependency_manager_test.go** (package: tests)
  - Imports: encoding/json, os, path/filepath, testing, time, github.com/gerivdb/email-sender-1/development/managers/interfaces, golang.org/x/mod/modfile
  - Types: MockDepManager
  - Méthodes: List, Add, Remove, Update, Audit, Cleanup, createTestGoMod, createTestConfig, TestMockDepManager_List, TestMockDepManager_Add, TestMockDepManager_Remove, TestMockDepManager_Update, TestGoModParsing, TestConfigLoading, TestBackupFunctionality, TestLogging, BenchmarkListDependencies, BenchmarkAddDependency

- **tests/full_integration_test.go** (package: tests)
  - Imports: context, fmt, testing, time, go.uber.org/zap, go.uber.org/zap/zaptest, github.com/gerivdb/email-sender-1/development/managers/dependencymanager, github.com/gerivdb/email-sender-1/development/managers/interfaces
  - Types: (aucun exporté)
  - Méthodes: TestFullManagerIntegrationScenario, TestRemoteDependencyResolution, TestErrorPropagation

- **tests/integration_manager_test.go** (package: tests)
  - Imports: context, testing, time, github.com/stretchr/testify/assert, github.com/stretchr/testify/mock, go.uber.org/zap, github.com/gerivdb/email-sender-1/development/managers/dependencymanager, github.com/gerivdb/email-sender-1/development/managers/interfaces
  - Types: TestifyMockSecurityManager, TestifyMockMonitoringManager, TestifyMockStorageManager, TestifyMockContainerManager, TestifyMockDeploymentManager
  - Méthodes: GetSecret, ValidateAPIKey, EncryptData, DecryptData, ScanForVulnerabilities, HealthCheck, StartOperationMonitoring, StopOperationMonitoring, ConfigureAlerts, CollectMetrics, CheckSystemHealth, StoreObject, GetObject, DeleteObject, ListObjects, GetDependencyMetadata, SaveDependencyMetadata, QueryDependencies, ValidateForContainerization, OptimizeForContainer, GetContainerDependencies, ValidateContainerCompatibility, BuildDependencyImage, CheckDependencyCompatibility, GenerateArtifactMetadata, ValidateDeploymentDependencies, UpdateDeploymentConfig, GetEnvironmentDependencies, TestSecurityIntegration, TestStorageIntegration, TestContainerIntegration

- **tests/integration_test.go** (package: tests)
  - Imports: testing
  - Types: (aucun exporté)
  - Méthodes: TestPlaceholder

- **tests/mocks_common_test.go** (package: tests)
  - Imports: context, encoding/json, time, go.uber.org/zap, github.com/gerivdb/email-sender-1/development/managers/interfaces
  - Types: MockSecurityManagerFull, MockMonitoringManagerFull, MockStorageManager
  - Méthodes: GetSecret, ValidateAPIKey, HealthCheck, EncryptData, DecryptData, ScanForVulnerabilities, CollectMetrics, CheckSystemHealth, StartOperationMonitoring, StopOperationMonitoring, ConfigureAlerts, NewMockStorageManager, StoreObject, GetObject, DeleteObject, ListObjects

## Synthèse

- **Packages principaux** : dependency, deployment, importmanager, interfaces, monitoring, realmanager, security, storage, tests
- **Types centraux** : DependencyManagerImpl, ImportManager, RealManagerConnector, MockDepManager, TestifyMockSecurityManager, TestifyMockMonitoringManager, TestifyMockStorageManager, TestifyMockContainerManager, TestifyMockDeploymentManager, MockSecurityManagerFull, MockMonitoringManagerFull, MockStorageManager, interfaces (tous les contrats d’intégration)
- **Méthodes clés** : gestion des dépendances, intégration monitoring, sécurité, import management, centralisation des interfaces, connecteurs réels managers, méthodes de test et de mock

---

*Inventaire généré automatiquement pour la phase 1 du plan v73 (refactoring & remise à plat architecturale Go).*
