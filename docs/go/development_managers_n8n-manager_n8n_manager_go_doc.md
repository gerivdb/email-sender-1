# Package n8nmanager

## Types

### Config

Config holds configuration for N8NManager


### ErrorHooks

ErrorHooks defines hooks for error handling


### ErrorManager

ErrorManager interface for dependency injection


### N8NManager

N8NManager struct — Orchestrateur des workflows n8n et gestion centralisée des exécutions.

Rôle :
  - Gère l’exécution, la surveillance et la gestion des workflows n8n avec gestion centralisée des erreurs.

Interfaces principales :
  - Utilise ErrorManager pour la gestion des erreurs.
  - Expose des méthodes pour lancer, surveiller et arrêter des workflows (voir méthodes ci-dessous).

Utilisation :
  - Centralise les appels API n8n, collecte des métriques, gestion des logs.
  - Permet l’intégration avec d’autres managers via injection de dépendances.

Entrée/Sortie :
  - Workflows, statuts d’exécution, logs, métriques.

Exemple :

	mgr := N8NManager{...}
	err := mgr.LaunchWorkflow(id)

Voir aussi : ErrorManager, N8NMetrics
N8NManager manages n8n workflows and executions with centralized error handling


#### Methods

##### N8NManager.ExecuteWorkflow

ExecuteWorkflow executes a workflow by ID with comprehensive error handling


```go
func (nm *N8NManager) ExecuteWorkflow(ctx context.Context, workflowID string, inputData map[string]interface{}) (*WorkflowExecution, error)
```

##### N8NManager.GetExecutionStatus

GetExecutionStatus gets the status of a workflow execution


```go
func (nm *N8NManager) GetExecutionStatus(ctx context.Context, executionID string) (*WorkflowExecution, error)
```

##### N8NManager.GetMetrics

GetMetrics returns current metrics


```go
func (nm *N8NManager) GetMetrics() N8NMetrics
```

##### N8NManager.GetWorkflows

GetWorkflows retrieves all workflows with error handling


```go
func (nm *N8NManager) GetWorkflows(ctx context.Context) ([]Workflow, error)
```

##### N8NManager.HealthCheck

HealthCheck performs a health check on the n8n instance


```go
func (nm *N8NManager) HealthCheck(ctx context.Context) error
```

##### N8NManager.ProcessError

ProcessError processes errors using the centralized ErrorManager


```go
func (nm *N8NManager) ProcessError(ctx context.Context, err error, operation string, workflowContext map[string]interface{}) error
```

##### N8NManager.StopExecution

StopExecution stops a running workflow execution


```go
func (nm *N8NManager) StopExecution(ctx context.Context, executionID string) error
```

### N8NMetrics

N8NMetrics holds metrics for n8n operations


### Workflow

Workflow represents an n8n workflow


### WorkflowExecution

WorkflowExecution represents an n8n workflow execution


