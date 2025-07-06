# Package interfaces

## Types

### Action

Action représente une action à exécuter dans le cadre d'une décision


### AdvancedAutonomyManager

AdvancedAutonomyManager est l'interface principale pour le 21ème manager du FMOUA
qui fournit une autonomie complète pour la maintenance et l'organisation
Ce manager orchestre tous les 20 managers précédents et fournit une intelligence
décisionnelle avancée pour l'ensemble de l'écosystème.


### Alert

Alert représente une alerte active dans le système


### Anomaly

Anomaly représente une anomalie détectée dans le système


### AutonomousDecision

AutonomousDecision représente une décision prise par le système d'IA
qui peut être exécutée de manière autonome


### AutonomyLevel

AutonomyLevel represents the level of autonomy for the manager


### AutonomyResult

AutonomyResult représente le résultat d'une opération autonome


### BaseManager

BaseManager interface that all managers must implement


### Condition

Condition représente une condition


### CoordinationConfig

CoordinationConfig configure la couche de coordination maître


### CrossManagerWorkflow

CrossManagerWorkflow représente un workflow qui traverse plusieurs managers


### DecisionEngineConfig

DecisionEngineConfig configure le moteur de décision neural


### DecisionPathDetails

DecisionPathDetails contient les détails du chemin de décision


### DecisionPoint

DecisionPoint représente un point de décision


### DetectorConfig

DetectorConfig configure le détecteur d'anomalies
Harmonisé pour tous les sous-packages


### DiagnosticConfig

DiagnosticConfig configure le moteur de diagnostic
Harmonisé pour tous les sous-packages


### EcosystemHealth

EcosystemHealth représente l'état de santé de l'écosystème


### EmergencyResponse

EmergencyResponse représente la réponse à une situation d'urgence


### EmergencySeverity

EmergencySeverity représente la gravité d'une situation d'urgence


### EngineConfig

EngineConfig configure le moteur de réparation
Harmonisé pour tous les sous-packages


### Event

Event représente un événement dans le système


### HealingConfig

HealingConfig configure le système d'auto-réparation


### HealthStatus

HealthStatus represents the health status of a manager


### HistoricalHealth

HistoricalHealth représente un point de données historique de santé


### Issue

Issue représente un problème rencontré


### LearningConfig

LearningConfig configure le système d'apprentissage
Harmonisé pour tous les sous-packages


### LogEntry

LogEntry représente une entrée de journal


### Logger

Logger interface for structured logging


### MaintenanceForecast

MaintenanceForecast représente une prédiction des besoins de maintenance
basée sur l'analyse de ML des patterns de dégradation


### MaintenanceWindow

MaintenanceWindow représente une fenêtre de temps optimale pour la maintenance


### ManagerHealth

ManagerHealth représente l'état de santé d'un manager


### ManagerState

ManagerState représente l'état actuel d'un manager spécifique


### MonitoringConfig

MonitoringConfig configure le dashboard temps réel


### MonitoringDashboard

MonitoringDashboard représente un tableau de bord de surveillance en temps réel


### Operation

Operation représente une opération en cours d'exécution


### Optimization

Optimization représente une optimisation appliquée


### OrchestratorConfig

OrchestratorConfig configure l'orchestrateur de récupération
Harmonisé pour tous les sous-packages


### PerformanceMetrics

PerformanceMetrics représente les métriques de performance d'un manager


### PredictedIssue

PredictedIssue représente un problème prédit qui nécessitera une maintenance


### PredictionResult

PredictionResult représente le résultat d'une prédiction


### PredictiveConfig

PredictiveConfig configure la maintenance prédictive


### PredictiveInsight

PredictiveInsight représente un insight prédictif basé sur l'analyse des données


### ResourceOptimizationResult

ResourceOptimizationResult représente le résultat d'une optimisation de ressources


### ResourceRequirements

ResourceRequirements représente les ressources nécessaires pour la maintenance


### ResourceUtilization

ResourceUtilization représente l'utilisation actuelle des ressources


### RetryPolicy

RetryPolicy représente une politique de réessai


### Risk

Risk représente un risque spécifique identifié


### RiskAssessment

RiskAssessment représente l'évaluation des risques associés à une décision


### RollbackStrategy

RollbackStrategy définit comment annuler une décision en cas d'échec


### SelfHealingConfig

SelfHealingConfig représente la configuration du système d'auto-réparation


### StepResult

StepResult représente le résultat d'une étape de workflow


### SystemSituation

SystemSituation représente l'état actuel de l'écosystème complet du FMOUA
avec l'état détaillé des 20 managers existants


### TimeFrame

TimeFrame représente une période temporelle


### TimeSeriesDataPoint

TimeSeriesDataPoint représente un point de données dans une série temporelle


### TriggerCondition

TriggerCondition représente une condition de déclenchement pour un workflow


### WorkflowExecution

WorkflowExecution représente une exécution de workflow


### WorkflowStep

WorkflowStep représente une étape dans un workflow


