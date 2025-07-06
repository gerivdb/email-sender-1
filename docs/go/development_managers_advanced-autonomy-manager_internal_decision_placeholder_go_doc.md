# Package decision

Package decision implements the Autonomous Decision Engine component
of the AdvancedAutonomyManager - the neural decision-making system

Package decision implements the Autonomous Decision Engine component


## Types

### AnalyzerConfig

### AnalyzerMetrics

### AutonomousDecisionEngine

AutonomousDecisionEngine est le moteur de décision neural qui analyse le contexte,
génère des options de décision, évalue les risques et prend des décisions autonomes
en moins de 200ms avec une confiance élevée.


#### Methods

##### AutonomousDecisionEngine.Cleanup

Cleanup nettoie les ressources du moteur de décision


```go
func (ade *AutonomousDecisionEngine) Cleanup() error
```

##### AutonomousDecisionEngine.FilterSafeDecisions

FilterSafeDecisions filtre les décisions pour ne garder que celles qui respectent la tolérance aux risques


```go
func (ade *AutonomousDecisionEngine) FilterSafeDecisions(ctx context.Context, decisions []interfaces.AutonomousDecision, riskTolerance float64) ([]interfaces.AutonomousDecision, error)
```

##### AutonomousDecisionEngine.GenerateMaintenanceDecisions

GenerateMaintenanceDecisions génère des décisions de maintenance autonomes


```go
func (ade *AutonomousDecisionEngine) GenerateMaintenanceDecisions(ctx context.Context, situation *interfaces.SystemSituation) ([]interfaces.AutonomousDecision, error)
```

##### AutonomousDecisionEngine.HealthCheck

HealthCheck vérifie la santé du moteur de décision


```go
func (ade *AutonomousDecisionEngine) HealthCheck(ctx context.Context) error
```

##### AutonomousDecisionEngine.Initialize

Initialize initialise le moteur de décision et tous ses composants


```go
func (ade *AutonomousDecisionEngine) Initialize(ctx context.Context) error
```

##### AutonomousDecisionEngine.ValidateDecision

ValidateDecision valide une décision avant son exécution


```go
func (ade *AutonomousDecisionEngine) ValidateDecision(ctx context.Context, decision *interfaces.AutonomousDecision) error
```

### CachedDecision

CachedDecision décision mise en cache pour améliorer les performances


### ContextAnalyzer

ContextAnalyzer analyse l'état du système et fournit une analyse contextuelle


#### Methods

##### ContextAnalyzer.AnalyzeContext

AnalyzeContext analyse l'état du système et fournit une analyse contextuelle


```go
func (ca *ContextAnalyzer) AnalyzeContext(ctx context.Context, situation *interfaces.SystemSituation) (*ContextualAnalysis, error)
```

##### ContextAnalyzer.Cleanup

Cleanup nettoie les ressources de l'analyseur de contexte


```go
func (ca *ContextAnalyzer) Cleanup() error
```

##### ContextAnalyzer.HealthCheck

HealthCheck vérifie la santé de l'analyseur de contexte


```go
func (ca *ContextAnalyzer) HealthCheck(ctx context.Context) error
```

##### ContextAnalyzer.Initialize

Initialize initialise l'analyseur de contexte


```go
func (ca *ContextAnalyzer) Initialize(ctx context.Context) error
```

### ContextualAnalysis

Structures de support


### DecisionMetrics

DecisionMetrics métriques de performance du moteur de décision


### DecisionRecord

DecisionRecord enregistre une décision et ses résultats pour l'apprentissage


### DecisionTemplate

DecisionTemplate représente un modèle de décision


### ExecutionPlanner

ExecutionPlanner planifie l'exécution des actions associées à une décision


### ExecutionResult

### GeneratorConfig

### LearningConfig

### LearningSystem

LearningSystem système d'apprentissage pour améliorer les décisions futures


### NeuralConfig

### NeuralDecisionMaker

NeuralDecisionMaker sélectionne la meilleure décision en utilisant des réseaux de neurones


### OptionGenerator

OptionGenerator génère des options de décision basées sur l'analyse contextuelle


### PerformanceMetrics

### PlannerConfig

### RiskConfig

### RiskEvaluator

RiskEvaluator évalue les risques associés à chaque option de décision


### TrainingExample

