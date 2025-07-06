# Package monitoring

## Types

### AdvancedAutonomyManager

AdvancedAutonomyManager interface pour l'escalade vers le système d'autonomie


### AdvancedInfrastructureMonitor

AdvancedInfrastructureMonitor étend le monitoring existant


#### Methods

##### AdvancedInfrastructureMonitor.GetHealthStatus

GetHealthStatus retourne le statut de santé de tous les services


```go
func (aim *AdvancedInfrastructureMonitor) GetHealthStatus(ctx context.Context) (map[string]ServiceHealthStatus, error)
```

##### AdvancedInfrastructureMonitor.Start

Start démarre le monitoring avancé


```go
func (aim *AdvancedInfrastructureMonitor) Start(ctx context.Context) error
```

##### AdvancedInfrastructureMonitor.Stop

Stop arrête le monitoring avancé


```go
func (aim *AdvancedInfrastructureMonitor) Stop()
```

### Alert

Alert représente une alerte du système


### AlertData

AlertData représente une alerte


### AlertHandler

AlertHandler interface pour gérer les alertes


### AlertLevel

AlertLevel énumération pour les niveaux d'alerte


### AlertManager

AlertManager gère les alertes du système de vectorisation


#### Methods

##### AlertManager.AddHandler

AddHandler ajoute un gestionnaire d'alertes


```go
func (am *AlertManager) AddHandler(handler AlertHandler)
```

##### AlertManager.AddRule

AddRule ajoute une nouvelle règle d'alerte


```go
func (am *AlertManager) AddRule(rule *AlertRule)
```

##### AlertManager.GetActiveAlerts

GetActiveAlerts retourne toutes les alertes actives


```go
func (am *AlertManager) GetActiveAlerts() []*Alert
```

##### AlertManager.GetAlertHistory

GetAlertHistory retourne l'historique des alertes


```go
func (am *AlertManager) GetAlertHistory(limit int) []*Alert
```

##### AlertManager.RemoveRule

RemoveRule supprime une règle d'alerte


```go
func (am *AlertManager) RemoveRule(ruleID string)
```

##### AlertManager.Start

Start démarre le système d'alertes


```go
func (am *AlertManager) Start(ctx context.Context)
```

### AlertRule

AlertRule définit une règle d'alerte


### AlertSeverity

AlertSeverity définit le niveau de sévérité d'une alerte


#### Methods

##### AlertSeverity.String

```go
func (s AlertSeverity) String() string
```

### AutonomyDecision

AutonomyDecision représente une décision prise par le système d'autonomie


### AutonomyMetric

AutonomyMetric représente les métriques d'autonomie d'un service


### CheckResult

CheckResult représente le résultat d'un health check


### DefaultAdvancedAutonomyManager

DefaultAdvancedAutonomyManager implémentation par défaut de l'AdvancedAutonomyManager


#### Methods

##### DefaultAdvancedAutonomyManager.GetMetrics

GetMetrics retourne les métriques d'autonomie de tous les services


```go
func (daam *DefaultAdvancedAutonomyManager) GetMetrics() (map[string]AutonomyMetric, error)
```

##### DefaultAdvancedAutonomyManager.HandleServiceFailure

HandleServiceFailure gère l'escalade d'un service en échec


```go
func (daam *DefaultAdvancedAutonomyManager) HandleServiceFailure(ctx context.Context, service string, failure *ServiceFailureTracker) error
```

##### DefaultAdvancedAutonomyManager.NotifyEscalation

NotifyEscalation notifie l'escalade


```go
func (daam *DefaultAdvancedAutonomyManager) NotifyEscalation(service string, reason string) error
```

##### DefaultAdvancedAutonomyManager.StartAdvancedMonitoring

StartAdvancedMonitoring démarre le monitoring avancé de l'autonomie


```go
func (daam *DefaultAdvancedAutonomyManager) StartAdvancedMonitoring(ctx context.Context) error
```

##### DefaultAdvancedAutonomyManager.StopAdvancedMonitoring

StopAdvancedMonitoring arrête le monitoring avancé de l'autonomie


```go
func (daam *DefaultAdvancedAutonomyManager) StopAdvancedMonitoring() error
```

### DefaultNotificationSystem

DefaultNotificationSystem implémentation par défaut du système de notifications


#### Methods

##### DefaultNotificationSystem.ClearOldLogs

ClearOldLogs nettoie les anciens logs


```go
func (dns *DefaultNotificationSystem) ClearOldLogs(olderThan time.Duration) error
```

##### DefaultNotificationSystem.GetRecentAlerts

GetRecentAlerts récupère les alertes récentes du fichier de log


```go
func (dns *DefaultNotificationSystem) GetRecentAlerts(since time.Time) ([]AlertData, error)
```

##### DefaultNotificationSystem.GetRecentEvents

GetRecentEvents récupère les événements récents du fichier de log


```go
func (dns *DefaultNotificationSystem) GetRecentEvents(since time.Time) ([]LogEventData, error)
```

##### DefaultNotificationSystem.LogEvent

LogEvent enregistre un événement


```go
func (dns *DefaultNotificationSystem) LogEvent(event string, details map[string]interface{}) error
```

##### DefaultNotificationSystem.SendAlert

SendAlert envoie une alerte


```go
func (dns *DefaultNotificationSystem) SendAlert(level string, service string, message string) error
```

##### DefaultNotificationSystem.SendNotification

SendNotification envoie une notification générale


```go
func (dns *DefaultNotificationSystem) SendNotification(notification NotificationInfo) error
```

##### DefaultNotificationSystem.SetConsoleLogging

SetConsoleLogging active/désactive le logging vers console


```go
func (dns *DefaultNotificationSystem) SetConsoleLogging(enabled bool)
```

##### DefaultNotificationSystem.SetFileLogging

SetFileLogging active/désactive le logging vers fichier


```go
func (dns *DefaultNotificationSystem) SetFileLogging(enabled bool)
```

### DependencyStatus

DependencyStatus représente l'état d'une dépendance


### EmailAlertHandler

EmailAlertHandler gestionnaire d'alertes qui envoie des emails


#### Methods

##### EmailAlertHandler.HandleAlert

```go
func (h *EmailAlertHandler) HandleAlert(ctx context.Context, alert *Alert) error
```

### EscalationAction

EscalationAction définit une action d'escalade


### EscalationCondition

EscalationCondition définit une condition d'escalade


### EscalationStrategy

EscalationStrategy représente une stratégie d'escalade


### LogAlertHandler

LogAlertHandler gestionnaire d'alertes qui log dans les logs


#### Methods

##### LogAlertHandler.HandleAlert

```go
func (h *LogAlertHandler) HandleAlert(ctx context.Context, alert *Alert) error
```

### LogEventData

LogEvent représente un événement à logger


### MetricsCollector

MetricsCollector interface pour collecter des métriques personnalisées


### MonitoringStatus

MonitoringStatus représente l'état du système de monitoring


### NeuralAutoHealingSystem

NeuralAutoHealingSystem système d'auto-guérison intelligent


#### Methods

##### NeuralAutoHealingSystem.DetectAndHeal

DetectAndHeal détecte les pannes et lance le processus d'auto-healing


```go
func (nahs *NeuralAutoHealingSystem) DetectAndHeal(ctx context.Context, healthStatuses map[string]ServiceHealthStatus) error
```

##### NeuralAutoHealingSystem.GetAllFailureStatuses

GetAllFailureStatuses retourne tous les statuts de failure


```go
func (nahs *NeuralAutoHealingSystem) GetAllFailureStatuses() map[string]*ServiceFailureTracker
```

##### NeuralAutoHealingSystem.GetServiceFailureStatus

GetServiceFailureStatus retourne le statut de failure d'un service


```go
func (nahs *NeuralAutoHealingSystem) GetServiceFailureStatus(serviceName string) (*ServiceFailureTracker, bool)
```

##### NeuralAutoHealingSystem.Start

Start démarre le système d'auto-healing


```go
func (nahs *NeuralAutoHealingSystem) Start(ctx context.Context) error
```

##### NeuralAutoHealingSystem.Stop

Stop arrête le système d'auto-healing


```go
func (nahs *NeuralAutoHealingSystem) Stop() error
```

### NotificationInfo

NotificationInfo représente les informations d'une notification


### NotificationSystem

NotificationSystem interface pour les notifications


### RecoveryAction

RecoveryAction définit une action de récupération


### RecoveryAttempt

RecoveryAttempt représente une tentative de récupération


### RecoveryCondition

RecoveryCondition définit une condition pour appliquer une stratégie


### RecoveryStrategy

RecoveryStrategy représente une stratégie de récupération


### ServiceFailureTracker

ServiceFailureTracker suit les échecs d'un service


### ServiceHealthStatus

ServiceHealthStatus représente l'état de santé d'un service


### ServiceStatus

ServiceStatus énumération pour l'état du service


### VectorizationMetrics

VectorizationMetrics contient toutes les métriques de vectorisation


#### Methods

##### VectorizationMetrics.RecordEmbeddingDuration

RecordEmbeddingDuration enregistre la durée de génération d'embeddings


```go
func (m *VectorizationMetrics) RecordEmbeddingDuration(model, textLengthBucket string, duration time.Duration)
```

##### VectorizationMetrics.RecordQdrantError

RecordQdrantError enregistre une erreur Qdrant


```go
func (m *VectorizationMetrics) RecordQdrantError(operation, collection, errorType string)
```

##### VectorizationMetrics.RecordQdrantOperation

RecordQdrantOperation enregistre une opération Qdrant


```go
func (m *VectorizationMetrics) RecordQdrantOperation(operation, collection, status string)
```

##### VectorizationMetrics.RecordQdrantQueryDuration

RecordQdrantQueryDuration enregistre la durée d'une requête Qdrant


```go
func (m *VectorizationMetrics) RecordQdrantQueryDuration(operation, collection string, duration time.Duration)
```

##### VectorizationMetrics.RecordSimilarityScore

RecordSimilarityScore enregistre un score de similarité


```go
func (m *VectorizationMetrics) RecordSimilarityScore(operation, threshold string, score float64)
```

##### VectorizationMetrics.RecordSuccessfulOperation

RecordSuccessfulOperation enregistre une opération réussie


```go
func (m *VectorizationMetrics) RecordSuccessfulOperation()
```

##### VectorizationMetrics.RecordVectorizationDuration

RecordVectorizationDuration enregistre la durée d'une opération de vectorisation


```go
func (m *VectorizationMetrics) RecordVectorizationDuration(operation, manager string, duration time.Duration)
```

##### VectorizationMetrics.RecordVectorizationError

RecordVectorizationError enregistre une erreur de vectorisation


```go
func (m *VectorizationMetrics) RecordVectorizationError(operation, manager, errorType string)
```

##### VectorizationMetrics.RecordVectorizationRequest

RecordVectorizationRequest enregistre une requête de vectorisation


```go
func (m *VectorizationMetrics) RecordVectorizationRequest(operation, manager, status string)
```

##### VectorizationMetrics.StartMetricsCollection

StartMetricsCollection démarre la collecte périodique de métriques


```go
func (m *VectorizationMetrics) StartMetricsCollection(ctx context.Context, collectors []MetricsCollector, interval time.Duration)
```

##### VectorizationMetrics.UpdateActiveWorkers

UpdateActiveWorkers met à jour le nombre de workers actifs


```go
func (m *VectorizationMetrics) UpdateActiveWorkers(count int)
```

##### VectorizationMetrics.UpdateEmbeddingQuality

UpdateEmbeddingQuality met à jour le score de qualité des embeddings


```go
func (m *VectorizationMetrics) UpdateEmbeddingQuality(model, validationType string, score float64)
```

##### VectorizationMetrics.UpdateHealthStatus

UpdateHealthStatus met à jour le statut de santé d'un composant


```go
func (m *VectorizationMetrics) UpdateHealthStatus(component, instance string, healthy bool)
```

##### VectorizationMetrics.UpdateMemoryUsage

UpdateMemoryUsage met à jour l'utilisation mémoire


```go
func (m *VectorizationMetrics) UpdateMemoryUsage(bytes int64)
```

##### VectorizationMetrics.UpdateQdrantConnections

UpdateQdrantConnections met à jour le nombre de connexions Qdrant


```go
func (m *VectorizationMetrics) UpdateQdrantConnections(count int)
```

##### VectorizationMetrics.UpdateQueueSize

UpdateQueueSize met à jour la taille de la queue


```go
func (m *VectorizationMetrics) UpdateQueueSize(size int)
```

### WebhookAlertHandler

WebhookAlertHandler gestionnaire d'alertes qui envoie vers un webhook


#### Methods

##### WebhookAlertHandler.HandleAlert

```go
func (h *WebhookAlertHandler) HandleAlert(ctx context.Context, alert *Alert) error
```

## Functions

### GetTextLengthBucket

GetTextLengthBucket retourne le bucket de longueur de texte approprié


```go
func GetTextLengthBucket(textLength int) string
```

