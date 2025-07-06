# Package infrastructure

Package infrastructure provides tools for automated infrastructure management
within the AdvancedAutonomyManager ecosystem.

Package infrastructure provides tools for automated infrastructure management
within the AdvancedAutonomyManager ecosystem - Phase 4 Implementation.

Package infrastructure provides tools for automated infrastructure management
within the AdvancedAutonomyManager ecosystem.

Package infrastructure provides tools for automated infrastructure management
within the AdvancedAutonomyManager ecosystem.


## Types

### AuditEvent

AuditEvent - Événement d'audit


### AuditLogger

AuditLogger - Logger pour les événements d'audit


#### Methods

##### AuditLogger.LogEvent

LogEvent - Enregistrer un événement


```go
func (al *AuditLogger) LogEvent(event AuditEvent)
```

##### AuditLogger.Start

Start - Démarrer le logger d'audit


```go
func (al *AuditLogger) Start(ctx context.Context) error
```

##### AuditLogger.Stop

Stop - Arrêter le logger d'audit


```go
func (al *AuditLogger) Stop() error
```

### ContainerManagerClient

ContainerManagerClient defines the interface for communicating with ContainerManager


### HealthCheck

HealthCheck defines a function type for custom health checks


### HealthMonitor

HealthMonitor continuously monitors service health


#### Methods

##### HealthMonitor.AddCustomChecker

AddCustomChecker adds a custom health checker for a service


```go
func (m *HealthMonitor) AddCustomChecker(service string, checker HealthCheck)
```

##### HealthMonitor.AddServiceEndpoint

AddServiceEndpoint adds or updates a service health endpoint


```go
func (m *HealthMonitor) AddServiceEndpoint(service, endpoint string)
```

##### HealthMonitor.CheckServiceHealth

CheckServiceHealth performs a health check for a specific service


```go
func (m *HealthMonitor) CheckServiceHealth(ctx context.Context, service string) (bool, error)
```

##### HealthMonitor.GetAllServiceHealth

GetAllServiceHealth returns health status for all services


```go
func (m *HealthMonitor) GetAllServiceHealth() map[string]ServiceStatus
```

##### HealthMonitor.GetServiceHealth

GetServiceHealth returns the health status for a service


```go
func (m *HealthMonitor) GetServiceHealth(service string) (bool, time.Time, bool)
```

##### HealthMonitor.Start

Start begins periodic health monitoring


```go
func (m *HealthMonitor) Start(ctx context.Context)
```

##### HealthMonitor.Stop

Stop halts the health monitoring


```go
func (m *HealthMonitor) Stop()
```

### HealthMonitorConfig

HealthMonitorConfig defines configuration for the health monitor


### HealthStatus

HealthStatus represents the overall health of the infrastructure stack


### InfrastructureManager

InfrastructureManager defines the interface for managing infrastructure


### InfrastructureOrchestrator

InfrastructureOrchestrator implements the InfrastructureManager interface


#### Methods

##### InfrastructureOrchestrator.MonitorInfrastructureHealth

MonitorInfrastructureHealth implements InfrastructureManager.MonitorInfrastructureHealth


```go
func (io *InfrastructureOrchestrator) MonitorInfrastructureHealth(
	ctx context.Context,
) (*HealthStatus, error)
```

##### InfrastructureOrchestrator.PerformRollingUpdate

PerformRollingUpdate implements InfrastructureManager.PerformRollingUpdate


```go
func (io *InfrastructureOrchestrator) PerformRollingUpdate(
	ctx context.Context,
	updatePlan *UpdatePlan,
) error
```

##### InfrastructureOrchestrator.RecoverFailedServices

RecoverFailedServices implements InfrastructureManager.RecoverFailedServices


```go
func (io *InfrastructureOrchestrator) RecoverFailedServices(
	ctx context.Context,
	services []string,
) (*RecoveryResult, error)
```

##### InfrastructureOrchestrator.StartInfrastructureStack

StartInfrastructureStack implements InfrastructureManager.StartInfrastructureStack


```go
func (io *InfrastructureOrchestrator) StartInfrastructureStack(
	ctx context.Context,
	config *StackConfig,
) (*StartupResult, error)
```

##### InfrastructureOrchestrator.StopInfrastructureStack

StopInfrastructureStack implements InfrastructureManager.StopInfrastructureStack


```go
func (io *InfrastructureOrchestrator) StopInfrastructureStack(
	ctx context.Context,
	graceful bool,
) (*ShutdownResult, error)
```

### InfrastructureOrchestratorInterface

InfrastructureOrchestratorInterface - Interface principale pour l'orchestration infrastructure (Phase 4)


### Logger

Logger provides a structured logging interface


### RecoveryResult

RecoveryResult contains the result of an automatic recovery attempt


### ResourceConfig

ResourceConfig defines resource limits for services


### SecurityConfig

SecurityConfig - Configuration de sécurité pour l'infrastructure


### SecurityIssue

SecurityIssue - Problème de sécurité détecté


### SecurityManagerInterface

SecurityManagerInterface - Interface pour la gestion de la sécurité (Phase 4.2)


### SecurityPolicy

SecurityPolicy - Politique de sécurité


### SecurityRecommendation

SecurityRecommendation - Recommandation de sécurité


### SecurityScanResult

SecurityScanResult - Résultat d'un scan de sécurité


### ServiceDependencyGraph

ServiceDependencyGraph manages service dependencies


#### Methods

##### ServiceDependencyGraph.AddService

AddService adds a service to the dependency graph


```go
func (g *ServiceDependencyGraph) AddService(service string, dependencies []string)
```

##### ServiceDependencyGraph.GetAllServices

GetAllServices returns all services in the graph


```go
func (g *ServiceDependencyGraph) GetAllServices() []string
```

##### ServiceDependencyGraph.GetDependencies

GetDependencies returns the dependencies for a service


```go
func (g *ServiceDependencyGraph) GetDependencies(service string) ([]string, bool)
```

##### ServiceDependencyGraph.GetDependents

GetDependents returns the services that depend on the given service


```go
func (g *ServiceDependencyGraph) GetDependents(service string) []string
```

##### ServiceDependencyGraph.GetShutdownOrder

GetShutdownOrder returns the services in reverse dependency order for shutdown


```go
func (g *ServiceDependencyGraph) GetShutdownOrder(services []string) ([]string, error)
```

##### ServiceDependencyGraph.GetStartOrder

GetStartOrder returns the services in dependency order for startup


```go
func (g *ServiceDependencyGraph) GetStartOrder(services []string) ([]string, error)
```

##### ServiceDependencyGraph.HasCycles

HasCycles checks if the dependency graph has cycles


```go
func (g *ServiceDependencyGraph) HasCycles() bool
```

### ServiceDependencyGraphConfig

ServiceDependencyGraphConfig defines the configuration for the service dependency graph


### ServiceStartupResult

ServiceStartupResult contains the result of starting a single service


### ServiceStatus

ServiceStatus represents the current status of an infrastructure service


### ShutdownResult

ShutdownResult contains the results of shutting down the infrastructure stack


### SmartSecurityManager

SmartSecurityManager - Implémentation du gestionnaire de sécurité intelligent


#### Methods

##### SmartSecurityManager.LogAuditEvent

LogAuditEvent - Enregistrer un événement d'audit


```go
func (ssm *SmartSecurityManager) LogAuditEvent(event AuditEvent)
```

##### SmartSecurityManager.PerformSecurityScan

PerformSecurityScan - Effectuer un scan de sécurité complet


```go
func (ssm *SmartSecurityManager) PerformSecurityScan(ctx context.Context) (*SecurityScanResult, error)
```

##### SmartSecurityManager.RotateEncryptionKeys

RotateEncryptionKeys - Effectuer la rotation des clés de chiffrement


```go
func (ssm *SmartSecurityManager) RotateEncryptionKeys(ctx context.Context) error
```

##### SmartSecurityManager.SetupSecureCommunication

SetupSecureCommunication - Configurer les communications sécurisées


```go
func (ssm *SmartSecurityManager) SetupSecureCommunication(ctx context.Context, services []string) error
```

##### SmartSecurityManager.StartAuditLogging

StartAuditLogging - Démarrer la journalisation d'audit


```go
func (ssm *SmartSecurityManager) StartAuditLogging(ctx context.Context) error
```

##### SmartSecurityManager.StopAuditLogging

StopAuditLogging - Arrêter la journalisation d'audit


```go
func (ssm *SmartSecurityManager) StopAuditLogging(ctx context.Context) error
```

##### SmartSecurityManager.ValidateConfiguration

ValidateConfiguration - Valider la configuration de sécurité


```go
func (ssm *SmartSecurityManager) ValidateConfiguration(ctx context.Context) error
```

##### SmartSecurityManager.ValidateServiceAuthentication

ValidateServiceAuthentication - Valider l'authentification d'un service


```go
func (ssm *SmartSecurityManager) ValidateServiceAuthentication(ctx context.Context, serviceName string) error
```

### StackConfig

StackConfig defines configuration for starting the infrastructure stack


### StartupResult

StartupResult contains the results of starting up the infrastructure stack


### StartupSequenceResult

StartupSequenceResult contains the results of a startup sequence


### StartupSequencer

StartupSequencer handles the ordered startup of infrastructure services


#### Methods

##### StartupSequencer.StartServices

StartServices starts services in the correct dependency order


```go
func (s *StartupSequencer) StartServices(
	ctx context.Context,
	services []string,
	config *StartupSequencerConfig,
) (*StartupSequenceResult, error)
```

### StartupSequencerConfig

StartupSequencerConfig defines configuration for the startup sequencer


### UpdatePlan

UpdatePlan defines a plan for performing rolling updates


## Variables

### ErrServiceNotFound, ErrServiceAlreadyRunning, ErrServiceNotRunning, ErrInfrastructureUnavailable, ErrInvalidConfiguration, ErrStartupTimeout, ErrShutdownTimeout, ErrInsufficientResources, ErrSecurityValidationFailed

Common errors


```go
var (
	ErrServiceNotFound		= errors.New("service not found in infrastructure configuration")
	ErrServiceAlreadyRunning	= errors.New("service is already running")
	ErrServiceNotRunning		= errors.New("service is not running")
	ErrInfrastructureUnavailable	= errors.New("infrastructure components are unavailable")
	ErrInvalidConfiguration		= errors.New("invalid infrastructure configuration")
	ErrStartupTimeout		= errors.New("service startup timed out")
	ErrShutdownTimeout		= errors.New("service shutdown timed out")
	ErrInsufficientResources	= errors.New("insufficient system resources")
	ErrSecurityValidationFailed	= errors.New("security validation failed")
)
```

