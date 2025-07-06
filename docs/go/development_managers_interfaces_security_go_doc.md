# Package interfaces

## Types

### APIAuth

APIAuth représente l'authentification d'API


### APIConfig

APIConfig représente la configuration d'une API


### APIEndpoint

APIEndpoint représente un endpoint d'API


### APIManager

APIManager interface pour la gestion des APIs


### APIRequest

APIRequest représente une requête d'API


### APIResponse

APIResponse représente une réponse d'API


### APIStatus

APIStatus représente le statut d'une API


### Alert

Alert représente une alerte


### AlertAction

AlertAction représente une action d'alerte


### AlertCondition

AlertCondition représente une condition d'alerte


### AlertEvent

AlertEvent représente un événement d'alerte


### AlertEventType

AlertEventType représente le type d'événement d'alerte


### AlertManager

AlertManager interface pour la gestion des alertes


### AlertSeverity

AlertSeverity représente la sévérité d'une alerte


### ArtifactMetadata

ArtifactMetadata defines metadata for a build artifact.


### Attachment

Attachment représente une pièce jointe


### BaseManager

BaseManager définit les méthodes de base communes à tous les managers


### BranchingManager

BranchingManager defines the interface for the ultra-advanced 8-level branching framework


### ChannelManager

ChannelManager interface pour la gestion des canaux


### ChannelPerformance

ChannelPerformance représente les performances d'un canal


### ChannelType

ChannelType représente le type de canal


### Cleaner

Cleaner définit l'interface de nettoyage


### CommitInfo

CommitInfo represents information about a Git commit


### ConfigManager

ConfigManager interface pour la gestion de configuration


### ContainerManager

ContainerManager interface pour la gestion des conteneurs


### Coordinator

Coordinator interface pour la coordination des managers


### DataTransformation

DataTransformation représente une transformation de données


### DateRange

DateRange représente une plage de dates


### DeliveryReport

DeliveryReport représente un rapport de livraison


### DependencyAnalysis

DependencyAnalysis résultat de l'analyse des dépendances


### DependencyConflict

DependencyConflict represents a conflict between dependencies.


### DependencyManager

DependencyManager interface pour la gestion des dépendances


### DependencyMetadata

DependencyMetadata représente les métadonnées d'une dépendance


### DependencyUpdate

DependencyUpdate mise à jour de dépendance disponible


### DependencyUsage

DependencyUsage statistique d'usage d'une dépendance


### DeploymentManager

DeploymentManager interface pour la gestion des déploiements


### DeploymentReadiness

DeploymentReadiness defines the readiness status for a deployment.


### Email

Email représente un email à envoyer


### EmailEvent

EmailEvent représente un événement d'email


### EmailEventType

EmailEventType représente le type d'événement d'email


### EmailManager

EmailManager interface pour la gestion complète des emails


### EmailPriority

EmailPriority représente la priorité d'un email


### EmailStats

EmailStats représente les statistiques d'emails


### EmailStatus

EmailStatus représente le statut d'un email


### EmailTemplate

EmailTemplate représente un template d'email


### ErrorManager

ErrorManager interface pour la gestion des erreurs


### EventBus

EventBus interface pour la communication inter-managers


### EventHandler

EventHandler définit le type de fonction pour gérer les événements


### GitWorkflowManager

GitWorkflowManager defines the interface for Git workflow management operations


### GitWorkflowManagerFactory

GitWorkflowManagerFactory defines the factory interface for creating GitWorkflowManager instances


### HealthChecker

HealthChecker définit l'interface de vérification de santé


### ImportConflict

ImportConflict représente un conflit entre imports


### ImportFixOptions

ImportFixOptions configure les options de correction automatique


### ImportFixResult

ImportFixResult contient les résultats des corrections appliquées


### ImportIssue

ImportIssue représente un problème d'import détecté


### ImportIssueType

ImportIssueType énumère les types de problèmes d'imports


### ImportReport

ImportReport génère un rapport complet des imports du projet


### ImportStatistics

ImportStatistics contient des statistiques sur les imports


### ImportValidationResult

ImportValidationResult contient les résultats de validation des imports


### Initializer

Initializer définit l'interface d'initialisation


### Integration

Integration représente une intégration externe


### IntegrationHealthStatus

IntegrationHealthStatus defines the health status of an integrated manager or system.


### IntegrationManager

IntegrationManager interface pour les intégrations externes


### IntegrationStatus

IntegrationStatus représente le statut d'intégration


### IntegrationType

IntegrationType représente le type d'intégration


### ManagerConfig

ManagerConfig représente la configuration de base d'un manager


### ManagerEvent

ManagerEvent représente un événement du système


### ManagerInterface

ManagerInterface définit l'interface commune pour tous les managers de l'écosystème


### ManagerMetrics

ManagerMetrics représente les métriques d'un manager


### ManagerRegistry

ManagerRegistry interface pour la découverte automatique de managers


### ManagerStatus

ManagerStatus defines the operational status of a manager.


### ModuleStructureValidation

ModuleStructureValidation valide la structure globale des modules


### ModuleUsage

ModuleUsage statistique d'usage d'un module interne


### MonitoringManager

MonitoringManager interface pour la surveillance


### Notification

Notification représente une notification


### NotificationChannel

NotificationChannel représente un canal de notification


### NotificationManager

NotificationManager interface pour les notifications multi-canaux


### NotificationPriority

NotificationPriority représente la priorité d'une notification


### NotificationStats

NotificationStats représente les statistiques de notifications


### NotificationStatus

NotificationStatus représente le statut d'une notification


### NotificationType

NotificationType représente le type de notification


### OperationMetrics

OperationMetrics for monitoring (updated as per plan)


### PackageResolver

PackageResolver interface pour la résolution de packages


### PullRequestInfo

PullRequestInfo represents information about a pull request


### QueueManager

QueueManager interface pour la gestion des files d'attente


### QueueState

QueueState représente l'état de la file d'attente


### QueueStats

QueueStats représente les statistiques de la file


### QueueStatus

QueueStatus représente le statut de la file d'attente


### RateLimit

RateLimit représente les limites de taux


### ResolutionResult

ResolutionResult résultat de la résolution de dépendances


### ResolvedPackage

ResolvedPackage package résolu


### SecurityManager

SecurityManager interface pour la gestion de la sécurité


### StorageManager

StorageManager interface pour la gestion du stockage


### SubBranchInfo

SubBranchInfo represents information about a sub-branch


### SyncEvent

SyncEvent représente un événement de synchronisation


### SyncEventType

SyncEventType représente le type d'événement de synchronisation


### SyncJob

SyncJob représente un travail de synchronisation


### SyncManager

SyncManager interface pour la synchronisation


### SyncState

SyncState représente l'état de synchronisation


### SyncStatus

SyncStatus représente le statut de synchronisation


### SyncType

SyncType représente le type de synchronisation


### SystemMetrics

SystemMetrics for monitoring (updated as per plan)


### TemplateManager

TemplateManager interface pour la gestion des templates


### TransformationType

TransformationType représente le type de transformation


### ValidationResult

ValidationResult résultat de validation des dépendances


### ValidationSummary

ValidationSummary résume les problèmes trouvés


### VersionManager

VersionManager interface pour la gestion des versions


### Vulnerability

Vulnerability représente une vulnérabilité de sécurité


### VulnerabilityInfo

VulnerabilityInfo details d'une vulnérabilité - This might be redundant if Vulnerability struct is comprehensive


### VulnerabilityReport

VulnerabilityReport pour les analyses de sécurité


### Webhook

Webhook représente un webhook


### WebhookLog

WebhookLog représente un log de webhook


### WebhookPayload

WebhookPayload represents the payload sent to webhooks


### WorkflowType

WorkflowType represents different types of Git workflows


## Constants

### StatusStarting, StatusError, StatusRunning, StatusStopping, StatusStopped

Status constants pour les managers


```go
const (
	StatusStarting	= "starting"
	StatusError	= "error"
	StatusRunning	= "running"
	StatusStopping	= "stopping"
	StatusStopped	= "stopped"
)
```

