# Package main

## Types

### ConflictInfo

ConflictInfo - Information sur un conflit détecté


### FileOperationSimulator

FileOperationSimulator - Simulateur d'opérations de fichiers


#### Methods

##### FileOperationSimulator.GetActionType

Interface methods


```go
func (f *FileOperationSimulator) GetActionType() string
```

##### FileOperationSimulator.GetDestinationPath

```go
func (f *FileOperationSimulator) GetDestinationPath() string
```

##### FileOperationSimulator.GetTargetPath

```go
func (f *FileOperationSimulator) GetTargetPath() string
```

##### FileOperationSimulator.SimulateAction

SimulateAction - Simule une opération de fichier sans l'exécuter


```go
func (f *FileOperationSimulator) SimulateAction() (*SimulationResult, error)
```

### ISimulatable

ISimulatable - Interface pour les opérations simulables


### ImpactAnalysis

ImpactAnalysis - Analyse d'impact d'une opération


### SimulationEngine

SimulationEngine - Moteur principal de simulation


#### Methods

##### SimulationEngine.AddOperation

AddOperation - Ajoute une opération à simuler


```go
func (e *SimulationEngine) AddOperation(op ISimulatable)
```

##### SimulationEngine.GenerateReport

GenerateReport - Génère un rapport de simulation


```go
func (e *SimulationEngine) GenerateReport() (string, error)
```

##### SimulationEngine.GetResults

GetResults - Retourne les résultats de simulation


```go
func (e *SimulationEngine) GetResults() []*SimulationResult
```

##### SimulationEngine.RunSimulation

RunSimulation - Exécute toutes les simulations


```go
func (e *SimulationEngine) RunSimulation() error
```

### SimulationResult

SimulationResult - Résultat d'une simulation


