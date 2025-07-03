# Package main

## Types

### Algorithm

Algorithm interface that all algorithms must implement


### AlgorithmConfig

AlgorithmConfig represents configuration for a single algorithm


### AlgorithmResult

AlgorithmResult represents the result of algorithm execution


### DebugSession

DebugSession représente une session de débogage complète


### EmailSenderOrchestrator

EmailSenderOrchestrator manages the execution of all EMAIL_SENDER_1 algorithms


#### Methods

##### EmailSenderOrchestrator.Cleanup

Cleanup performs cleanup operations


```go
func (eso *EmailSenderOrchestrator) Cleanup()
```

##### EmailSenderOrchestrator.Execute

Execute runs the complete EMAIL_SENDER_1 algorithm orchestration


```go
func (eso *EmailSenderOrchestrator) Execute() (*OrchestratorResult, error)
```

##### EmailSenderOrchestrator.RegisterAlgorithms

RegisterAlgorithms registers all EMAIL_SENDER_1 algorithms


```go
func (eso *EmailSenderOrchestrator) RegisterAlgorithms() map[string]Algorithm
```

### ErrorAnalysisResult

ErrorAnalysisResult représente le résultat de l'analyse des erreurs


### OrchestratorConfig

OrchestratorConfig represents the unified orchestrator configuration


### OrchestratorResult

OrchestratorResult represents the overall orchestration result


