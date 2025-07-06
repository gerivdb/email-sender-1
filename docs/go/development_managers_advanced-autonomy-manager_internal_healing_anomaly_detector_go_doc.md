# Package healing

Package healing implements the Neural Auto-Healing System component

Package healing implements the Neural Auto-Healing System component

Package healing implements the Neural Auto-Healing System component

Package healing implements the Neural Auto-Healing System component

Package healing implements the Neural Auto-Healing System component
of the AdvancedAutonomyManager - intelligent anomaly detection and self-repair

Package healing implements the Neural Auto-Healing System component

Package healing implements the Neural Auto-Healing System component


## Types

### ActionExecutor

ActionExecutor exécute les actions de réparation


### ActionResult

### AnomalyContext

### AnomalyDetector

AnomalyDetector détecte les anomalies


#### Methods

##### AnomalyDetector.Cleanup

Cleanup nettoie les ressources du détecteur d'anomalies


```go
func (ad *AnomalyDetector) Cleanup() error
```

##### AnomalyDetector.DetectAnomalies

DetectAnomalies détecte des anomalies dans les données fournies


```go
func (ad *AnomalyDetector) DetectAnomalies(ctx context.Context, data interface{}) ([]*DetectedAnomaly, error)
```

##### AnomalyDetector.HealthCheck

HealthCheck vérifie la santé du détecteur d'anomalies


```go
func (ad *AnomalyDetector) HealthCheck(ctx context.Context) error
```

##### AnomalyDetector.Initialize

Initialize initialise le détecteur d'anomalies


```go
func (ad *AnomalyDetector) Initialize(ctx context.Context) error
```

### AnomalyPattern

AnomalyPattern pattern d'anomalie appris


### AnomalySeverity

### DetectedAnomaly

DetectedAnomaly anomalie détectée


### DetectorConfig

### DiagnosticConfig

### DiagnosticEngine

DiagnosticEngine effectue des diagnostics approfondis


#### Methods

##### DiagnosticEngine.Cleanup

Cleanup nettoie les ressources du moteur de diagnostic


```go
func (de *DiagnosticEngine) Cleanup() error
```

##### DiagnosticEngine.DiagnoseAnomaly

DiagnoseAnomaly diagnostique une anomalie et identifie les causes potentielles et l'impact


```go
func (de *DiagnosticEngine) DiagnoseAnomaly(ctx context.Context, anomaly *DetectedAnomaly) (*DiagnosticResult, error)
```

##### DiagnosticEngine.HealthCheck

HealthCheck vérifie la santé du moteur de diagnostic


```go
func (de *DiagnosticEngine) HealthCheck(ctx context.Context) error
```

##### DiagnosticEngine.Initialize

Initialize initialise le moteur de diagnostic


```go
func (de *DiagnosticEngine) Initialize(ctx context.Context) error
```

### DiagnosticResult

Structures de support pour DiagnosticEngine


### EngineConfig

### HealingAction

HealingAction action de réparation


### HealingConfig

HealingConfig configure le système d'auto-réparation


### HealingEngine

HealingEngine génère et exécute des plans de réparation


#### Methods

##### HealingEngine.Cleanup

Cleanup nettoie les ressources du moteur de réparation


```go
func (he *HealingEngine) Cleanup() error
```

##### HealingEngine.ExecuteHealingPlan

ExecuteHealingPlan exécute un plan de réparation


```go
func (he *HealingEngine) ExecuteHealingPlan(ctx context.Context, plan *HealingPlan) (*HealingExecutionResult, error)
```

##### HealingEngine.GenerateHealingPlan

GenerateHealingPlan génère un plan de réparation pour une anomalie donnée


```go
func (he *HealingEngine) GenerateHealingPlan(ctx context.Context, anomaly *DetectedAnomaly) (*HealingPlan, error)
```

##### HealingEngine.HealthCheck

HealthCheck vérifie la santé du moteur de réparation


```go
func (he *HealingEngine) HealthCheck(ctx context.Context) error
```

##### HealingEngine.Initialize

Initialize initialise le moteur de réparation


```go
func (he *HealingEngine) Initialize(ctx context.Context) error
```

##### HealingEngine.ValidateHealingPlan

ValidateHealingPlan valide la sécurité d'un plan de réparation


```go
func (he *HealingEngine) ValidateHealingPlan(ctx context.Context, plan *HealingPlan) error
```

### HealingExecutionResult

### HealingKnowledgeBase

HealingKnowledgeBase gère la base de connaissances pour l'auto-réparation


#### Methods

##### HealingKnowledgeBase.Cleanup

Cleanup nettoie les ressources de la base de connaissances


```go
func (hkb *HealingKnowledgeBase) Cleanup() error
```

##### HealingKnowledgeBase.HealthCheck

HealthCheck vérifie la santé de la base de connaissances


```go
func (hkb *HealingKnowledgeBase) HealthCheck(ctx context.Context) error
```

##### HealingKnowledgeBase.Initialize

Initialize initialise la base de connaissances


```go
func (hkb *HealingKnowledgeBase) Initialize(ctx context.Context) error
```

### HealingMetrics

HealingMetrics métriques du système de réparation


### HealingPlan

Structures de support pour HealingEngine


### HealingResult

HealingResult résultat d'une session de réparation


### HealingSession

HealingSession session de réparation active


### HealingStatus

### HealingStep

HealingStep représente une étape de réparation


### HealingStrategy

HealingStrategy représente une stratégie de réparation


### ImpactAssessment

### KnowledgeBaseConfig

### LearningConfig

### NeuralAutoHealingSystem

NeuralAutoHealingSystem est le système d'auto-réparation basé sur l'IA qui détecte
automatiquement les anomalies, applique des corrections intelligentes, apprend des
patterns de pannes et effectue la récupération autonome avec >90% de précision.


#### Methods

##### NeuralAutoHealingSystem.Cleanup

Cleanup nettoie les ressources du système d'auto-réparation


```go
func (nahs *NeuralAutoHealingSystem) Cleanup() error
```

##### NeuralAutoHealingSystem.DetectAnomalies

DetectAnomalies détecte des anomalies dans les données fournies


```go
func (nahs *NeuralAutoHealingSystem) DetectAnomalies(ctx context.Context, data interface{}) ([]*DetectedAnomaly, error)
```

##### NeuralAutoHealingSystem.GetHealingHistory

GetHealingHistory retourne l'historique des sessions de réparation


```go
func (nahs *NeuralAutoHealingSystem) GetHealingHistory(duration time.Duration) []*HealingSession
```

##### NeuralAutoHealingSystem.GetMetrics

GetMetrics retourne les métriques du système de réparation


```go
func (nahs *NeuralAutoHealingSystem) GetMetrics() *HealingMetrics
```

##### NeuralAutoHealingSystem.HealAnomaly

HealAnomaly applique une réparation automatique pour une anomalie spécifique


```go
func (nahs *NeuralAutoHealingSystem) HealAnomaly(ctx context.Context, anomaly *DetectedAnomaly) (*HealingResult, error)
```

##### NeuralAutoHealingSystem.HealthCheck

HealthCheck vérifie la santé du système d'auto-réparation


```go
func (nahs *NeuralAutoHealingSystem) HealthCheck(ctx context.Context) error
```

##### NeuralAutoHealingSystem.Initialize

Initialize initialise le système d'auto-réparation


```go
func (nahs *NeuralAutoHealingSystem) Initialize(ctx context.Context) error
```

##### NeuralAutoHealingSystem.LearnFromResults

LearnFromResults apprend des résultats de réparation pour améliorer le système


```go
func (nahs *NeuralAutoHealingSystem) LearnFromResults(ctx context.Context, sessions []*HealingSession) error
```

##### NeuralAutoHealingSystem.MonitorAndHealExecution

MonitorAndHealExecution surveille l'exécution et applique l'auto-healing si nécessaire


```go
func (nahs *NeuralAutoHealingSystem) MonitorAndHealExecution(ctx context.Context, executionResults map[string]interface{}) ([]*interfaces.Issue, error)
```

### OrchestratorConfig

### PatternDatabase

PatternDatabase base de données des patterns


### PatternLearningSystem

PatternLearningSystem apprend des patterns d'anomalies et de réparation


#### Methods

##### PatternLearningSystem.Cleanup

Cleanup nettoie les ressources du système d'apprentissage


```go
func (pls *PatternLearningSystem) Cleanup() error
```

##### PatternLearningSystem.HealthCheck

HealthCheck vérifie la santé du système d'apprentissage


```go
func (pls *PatternLearningSystem) HealthCheck(ctx context.Context) error
```

##### PatternLearningSystem.Initialize

Initialize initialise le système d'apprentissage des patterns


```go
func (pls *PatternLearningSystem) Initialize(ctx context.Context) error
```

##### PatternLearningSystem.LearnFromSessions

LearnFromSessions apprend des sessions de réparation


```go
func (pls *PatternLearningSystem) LearnFromSessions(ctx context.Context, sessions []*HealingSession) error
```

### PotentialCause

### RecoveryOrchestrator

RecoveryOrchestrator orchestre les processus de récupération


#### Methods

##### RecoveryOrchestrator.Cleanup

Cleanup nettoie les ressources de l'orchestrateur de récupération


```go
func (ro *RecoveryOrchestrator) Cleanup() error
```

##### RecoveryOrchestrator.EscalateAnomaly

EscalateAnomaly escalade une anomalie vers un système de gestion d'incidents


```go
func (ro *RecoveryOrchestrator) EscalateAnomaly(ctx context.Context, anomaly *DetectedAnomaly) error
```

##### RecoveryOrchestrator.HealthCheck

HealthCheck vérifie la santé de l'orchestrateur de récupération


```go
func (ro *RecoveryOrchestrator) HealthCheck(ctx context.Context) error
```

##### RecoveryOrchestrator.Initialize

Initialize initialise l'orchestrateur de récupération


```go
func (ro *RecoveryOrchestrator) Initialize(ctx context.Context) error
```

### ResourceLimits

### RollbackManager

RollbackManager gère les retours en arrière


### SafetyRule

SafetyRule représente une règle de sécurité


### SafetyValidator

SafetyValidator valide la sécurité des actions


### StrategySelector

StrategySelector sélectionne la stratégie de réparation


### Symptom

### SystemSnapshot

SystemSnapshot représente un instantané du système


