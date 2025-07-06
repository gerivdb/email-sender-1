# Package parallel

## Types

### AdaptiveParallelismConfig

AdaptiveParallelismConfig définit la configuration du gestionnaire de parallélisme adaptatif


### AdaptiveParallelismManager

AdaptiveParallelismManager gère l'adaptation dynamique du parallélisme


#### Methods

##### AdaptiveParallelismManager.ApplyBackpressure

ApplyBackpressure applique une contre-pression si nécessaire


```go
func (apm *AdaptiveParallelismManager) ApplyBackpressure(queueLength int) bool
```

##### AdaptiveParallelismManager.GetStatus

GetStatus retourne l'état actuel du gestionnaire de parallélisme


```go
func (apm *AdaptiveParallelismManager) GetStatus() map[string]interface{}
```

##### AdaptiveParallelismManager.RegisterWorkerPool

RegisterWorkerPool enregistre un worker pool pour la gestion adaptative


```go
func (apm *AdaptiveParallelismManager) RegisterWorkerPool(wp *WorkerPool)
```

##### AdaptiveParallelismManager.SetMode

SetMode change le mode de parallélisme


```go
func (apm *AdaptiveParallelismManager) SetMode(mode ParallelismMode)
```

##### AdaptiveParallelismManager.SetWorkers

SetWorkers définit le nombre de workers pour tous les worker pools enregistrés


```go
func (apm *AdaptiveParallelismManager) SetWorkers(workers int)
```

##### AdaptiveParallelismManager.Start

Start démarre le gestionnaire de parallélisme adaptatif


```go
func (apm *AdaptiveParallelismManager) Start()
```

##### AdaptiveParallelismManager.Stop

Stop arrête le gestionnaire de parallélisme adaptatif


```go
func (apm *AdaptiveParallelismManager) Stop()
```

##### AdaptiveParallelismManager.UpdateMetrics

UpdateMetrics met à jour les métriques du système


```go
func (apm *AdaptiveParallelismManager) UpdateMetrics(metrics SystemMetrics)
```

### EmailBatch

EmailBatch représente un lot d'emails à traiter


### EmailBatchProcessor

EmailBatchProcessor traite les lots d'emails


### EmailPipelineStats

EmailPipelineStats contient les statistiques du pipeline d'emails


### EmailProcessingError

EmailProcessingError représente une erreur lors du traitement d'un email


### EmailSenderPipeline

EmailSenderPipeline orchestre le traitement des emails


#### Methods

##### EmailSenderPipeline.GetStats

GetStats retourne les statistiques actuelles du pipeline


```go
func (esp *EmailSenderPipeline) GetStats() EmailPipelineStats
```

##### EmailSenderPipeline.Start

Start démarre le pipeline EMAIL_SENDER


```go
func (esp *EmailSenderPipeline) Start() error
```

##### EmailSenderPipeline.Stop

Stop arrête le pipeline EMAIL_SENDER


```go
func (esp *EmailSenderPipeline) Stop()
```

##### EmailSenderPipeline.SubmitBatch

SubmitBatch soumet un lot d'emails pour traitement


```go
func (esp *EmailSenderPipeline) SubmitBatch(batch EmailBatch) error
```

### EmailSenderPipelineConfig

EmailSenderPipelineConfig configure le pipeline EMAIL_SENDER


### EmailTask

EmailTask représente une tâche de traitement d'email


### GlobalParallelStats

GlobalParallelStats contient les statistiques globales de tous les pipelines


### GmailClient

GmailClient interface for interacting with Gmail


### InterruptAction

InterruptAction définit les actions à prendre lors d'une interruption


### InterruptEvent

InterruptEvent représente un événement d'interruption


### InterruptHandler

InterruptHandler gère les interruptions du pipeline


#### Methods

##### InterruptHandler.AddEventListener

AddEventListener ajoute un écouteur d'événements d'interruption


```go
func (ih *InterruptHandler) AddEventListener(listener func(InterruptEvent))
```

##### InterruptHandler.GetEvents

GetEvents retourne tous les événements d'interruption enregistrés


```go
func (ih *InterruptHandler) GetEvents() []InterruptEvent
```

##### InterruptHandler.HandleInterrupt

HandleInterrupt gère une interruption


```go
func (ih *InterruptHandler) HandleInterrupt(reason InterruptReason, source string, message string) InterruptAction
```

##### InterruptHandler.IsPaused

IsPaused retourne true si le pipeline est actuellement en pause


```go
func (ih *InterruptHandler) IsPaused() bool
```

##### InterruptHandler.SetPause

SetPause met le pipeline en pause ou reprend son exécution


```go
func (ih *InterruptHandler) SetPause(pause bool)
```

##### InterruptHandler.Start

Start démarre le gestionnaire d'interruptions


```go
func (ih *InterruptHandler) Start()
```

##### InterruptHandler.Stop

Stop arrête le gestionnaire d'interruptions


```go
func (ih *InterruptHandler) Stop()
```

### InterruptHandlerConfig

InterruptHandlerConfig définit la configuration du gestionnaire d'interruptions


### InterruptReason

InterruptReason définit les raisons d'interruption possibles


### N8NClient

N8NClient interface for interacting with N8N


### NotionClient

NotionClient interface for interacting with Notion


### ParallelOrchestrationConfig

ParallelOrchestrationConfig définit la configuration pour l'orchestration parallèle


### ParallelOrchestrationConnector

ParallelOrchestrationConnector gère la connexion entre l'orchestrateur principal
et le système de pipeline parallélisé


#### Methods

##### ParallelOrchestrationConnector.CreateEmailPipeline

CreateEmailPipeline crée un nouveau pipeline EMAIL_SENDER avec les configurations nécessaires


```go
func (poc *ParallelOrchestrationConnector) CreateEmailPipeline(pipelineID string) (*EmailSenderPipeline, error)
```

##### ParallelOrchestrationConnector.GetGlobalStats

GetGlobalStats retourne les statistiques globales de tous les pipelines


```go
func (poc *ParallelOrchestrationConnector) GetGlobalStats() GlobalParallelStats
```

##### ParallelOrchestrationConnector.StartPipelineWithBatches

StartPipelineWithBatches démarre un pipeline avec un ensemble de lots d'emails


```go
func (poc *ParallelOrchestrationConnector) StartPipelineWithBatches(pipelineID string, batches []EmailBatch) error
```

##### ParallelOrchestrationConnector.Stop

Stop arrête tous les pipelines en cours d'exécution


```go
func (poc *ParallelOrchestrationConnector) Stop()
```

##### ParallelOrchestrationConnector.Wait

Wait attend que tous les pipelines soient terminés


```go
func (poc *ParallelOrchestrationConnector) Wait()
```

### ParallelismMode

ParallelismMode définit le mode de parallélisation


### PipelineOrchestrator

PipelineOrchestrator gère l'exécution du pipeline de traitement EMAIL_SENDER_1


#### Methods

##### PipelineOrchestrator.GetAllResults

GetAllResults récupère tous les résultats des étapes


```go
func (po *PipelineOrchestrator) GetAllResults() map[string]*PipelineResult
```

##### PipelineOrchestrator.GetPipelineProgress

GetPipelineProgress retourne la progression du pipeline (0-100%)


```go
func (po *PipelineOrchestrator) GetPipelineProgress() float64
```

##### PipelineOrchestrator.GetPipelineStats

GetPipelineStats retourne les statistiques du pipeline


```go
func (po *PipelineOrchestrator) GetPipelineStats() map[string]interface{}
```

##### PipelineOrchestrator.GetStageResult

GetStageResult récupère le résultat d'une étape


```go
func (po *PipelineOrchestrator) GetStageResult(stageID string) (*PipelineResult, error)
```

##### PipelineOrchestrator.RegisterStage

RegisterStage ajoute une étape au pipeline


```go
func (po *PipelineOrchestrator) RegisterStage(stage PipelineStage) error
```

##### PipelineOrchestrator.Start

Start démarre le pipeline orchestrator avec les données d'entrée


```go
func (po *PipelineOrchestrator) Start(initialInput interface{}) error
```

##### PipelineOrchestrator.Stop

Stop arrête le pipeline


```go
func (po *PipelineOrchestrator) Stop()
```

##### PipelineOrchestrator.Wait

Wait attend que l'exécution du pipeline soit terminée


```go
func (po *PipelineOrchestrator) Wait()
```

### PipelineOrchestratorConfig

PipelineOrchestratorConfig contient la configuration pour le PipelineOrchestrator


### PipelineResult

PipelineResult contient le résultat d'une étape du pipeline


### PipelineStage

PipelineStage représente une étape du pipeline


### PipelineStageStatus

PipelineStageStatus représente le statut d'une étape du pipeline


### RAGClient

RAGClient interface for interacting with the RAG system


### RecoveryStrategy

RecoveryStrategy définit la stratégie de récupération en cas d'échec d'une étape


### Result

Result contient le résultat de l'exécution d'une tâche


### SystemMetrics

SystemMetrics contient les métriques système utilisées pour l'adaptation


### Task

Task représente une tâche à exécuter par le worker pool


### WorkerMetrics

WorkerMetrics contient les métriques d'un point dans le temps


### WorkerMonitor

WorkerMonitor surveille et collecte des métriques sur les workers


#### Methods

##### WorkerMonitor.GetLatestMetrics

GetLatestMetrics retourne les dernières métriques collectées


```go
func (wm *WorkerMonitor) GetLatestMetrics() *WorkerMetrics
```

##### WorkerMonitor.GetMetricsHistory

GetMetricsHistory retourne l'historique des métriques


```go
func (wm *WorkerMonitor) GetMetricsHistory() []WorkerMetrics
```

##### WorkerMonitor.RegisterWorkerPool

RegisterWorkerPool enregistre un worker pool à surveiller


```go
func (wm *WorkerMonitor) RegisterWorkerPool(pool *WorkerPool)
```

##### WorkerMonitor.Start

Start démarre la surveillance


```go
func (wm *WorkerMonitor) Start()
```

##### WorkerMonitor.Stop

Stop arrête la surveillance


```go
func (wm *WorkerMonitor) Stop()
```

### WorkerMonitorConfig

WorkerMonitorConfig définit la configuration du moniteur de workers


### WorkerPool

WorkerPool implémente un pool de workers avec gestion de priorité et timeouts


#### Methods

##### WorkerPool.GetResults

GetResults retourne un canal pour récupérer les résultats


```go
func (wp *WorkerPool) GetResults() <-chan Result
```

##### WorkerPool.GetStats

GetStats retourne les statistiques courantes


```go
func (wp *WorkerPool) GetStats() WorkerPoolStats
```

##### WorkerPool.Start

Start démarre les workers


```go
func (wp *WorkerPool) Start()
```

##### WorkerPool.Stop

Stop arrête le worker pool


```go
func (wp *WorkerPool) Stop()
```

##### WorkerPool.SubmitTask

SubmitTask ajoute une tâche au worker pool


```go
func (wp *WorkerPool) SubmitTask(task Task) (bool, error)
```

### WorkerPoolStats

WorkerPoolStats contient les statistiques d'un worker pool


