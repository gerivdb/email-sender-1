package interfaces

import (
	"context"
	"time"
)

// AutonomyLevel définit le niveau d'autonomie du manager
type AutonomyLevel int

const (
	AutonomyLevelBasic    AutonomyLevel = 1
	AutonomyLevelAdvanced AutonomyLevel = 2
	AutonomyLevelComplete AutonomyLevel = 3
)

// SystemSituation représente l'état du système
type SystemSituation struct {
	Timestamp         time.Time
	OverallHealth     float64
	ManagerStates     map[string]*ManagerState
	DetectedAnomalies []interface{} // TODO: Définir le type d'anomalie
}

// ManagerState représente l'état d'un manager individuel
type ManagerState struct {
	Name               string
	Status             string
	HealthScore        float64
	LastHealthCheck    time.Time
	Metrics            map[string]interface{}
	DependenciesStatus map[string]bool
	ErrorCount         int
}

// EcosystemHealth représente la santé globale de l'écosystème
type EcosystemHealth struct {
	OverallHealth float64
	ManagerHealth map[string]float64
}

// AutonomousDecision représente une décision autonome
type AutonomousDecision struct {
	ID             string
	Description    string
	TargetManagers []string
	Actions        []interface{} // TODO: Définir le type d'action
}

// PredictionResult représente le résultat d'une prédiction
type PredictionResult struct {
	GeneratedAt     time.Time
	TimeHorizon     time.Duration
	Forecast        *MaintenanceForecast
	Confidence      float64
	Recommendations []string
}

// MaintenanceForecast représente une prédiction de maintenance
type MaintenanceForecast struct {
	PredictedIssues []MaintenanceIssue
}

// MaintenanceIssue représente un problème de maintenance prédit
type MaintenanceIssue struct {
	Component         string
	Severity          string
	Likelihood        float64
	PreventiveActions []string
}

// Operation représente une opération en cours
type Operation struct {
	ID        string
	StartTime time.Time
	EndTime   time.Time
	Status    string
	Result    interface{}
}

// AutonomyConfig contient la configuration complète du manager autonome
type AutonomyConfig struct {
	// Niveau d'autonomie
	AutonomyLevel AutonomyLevel `yaml:"autonomy_level" json:"autonomy_level"`
	// Configuration des composants
	DecisionConfig     *DecisionEngineConfig `yaml:"decision_config" json:"decision_config"`
	PredictiveConfig   *PredictiveConfig     `yaml:"predictive_config" json:"predictive_config"`
	MonitoringConfig   *MonitoringConfig     `yaml:"monitoring_config" json:"monitoring_config"`
	HealingConfig      *HealingConfig        `yaml:"healing_config" json:"healing_config"`
	CoordinationConfig *CoordinationConfig   `yaml:"coordination_config" json:"coordination_config"`
}

// DecisionEngineConfig configure le moteur de décision neural
type DecisionEngineConfig struct {
	NeuralTreeLevels    int           `yaml:"neural_tree_levels" json:"neural_tree_levels"`
	ConfidenceThreshold float64       `yaml:"confidence_threshold" json:"confidence_threshold"`
	RiskAssessmentDepth int           `yaml:"risk_assessment_depth" json:"risk_assessment_depth"`
	TrainingDataSize    int           `yaml:"training_data_size" json:"training_data_size"`
	DecisionSpeedTarget time.Duration `yaml:"decision_speed_target" json:"decision_speed_target"`
}

// PredictiveConfig configure le système de maintenance prédictive
type PredictiveConfig struct {
	ForecastHorizon          time.Duration `yaml:"forecast_horizon" json:"forecast_horizon"`
	ModelUpdateInterval      time.Duration `yaml:"model_update_interval" json:"model_update_interval"`
	PredictionAccuracyTarget float64       `yaml:"prediction_accuracy_target" json:"prediction_accuracy_target"`
	DataRetentionPeriod      time.Duration `yaml:"data_retention_period" json:"data_retention_period"`
	ModelTrainingEnabled     bool          `yaml:"model_training_enabled" json:"model_training_enabled"`
}

// MonitoringConfig configure le dashboard de monitoring
type MonitoringConfig struct {
	DashboardUpdateRate    time.Duration      `yaml:"dashboard_update_rate" json:"dashboard_update_rate"`
	MetricsRetentionPeriod time.Duration      `yaml:"metrics_retention_period" json:"metrics_retention_period"`
	AlertThresholds        map[string]float64 `yaml:"alert_thresholds" json:"alert_thresholds"`
	RealTimeEnabled        bool               `yaml:"real_time_enabled" json:"real_time_enabled"`
}

// HealingConfig configure le système d'auto-réparation
type HealingConfig struct {
	AnomalyDetectionSensitivity float64       `yaml:"anomaly_detection_sensitivity" json:"anomaly_detection_sensitivity"`
	AutoCorrectionEnabled       bool          `yaml:"auto_correction_enabled" json:"auto_correction_enabled"`
	LearningPatterns            bool          `yaml:"learning_patterns" json:"learning_patterns"`
	HealingTimeout              time.Duration `yaml:"healing_timeout" json:"healing_timeout"`
	MaxHealingAttempts          int           `yaml:"max_healing_attempts" json:"max_healing_attempts"`
}

// CoordinationConfig configure la couche de coordination maître
type CoordinationConfig struct {
	EventBusBufferSize    int           `yaml:"event_bus_buffer_size" json:"event_bus_buffer_size"`
	StateSyncInterval     time.Duration `yaml:"state_sync_interval" json:"state_sync_interval"`
	EmergencyResponseTime time.Duration `yaml:"emergency_response_time" json:"emergency_response_time"`
	OrchestratorWorkers   int           `yaml:"orchestrator_workers" json:"orchestrator_workers"`
}

// BaseManager is the base interface for all managers
type BaseManager interface {
	Initialize(ctx context.Context) error
	HealthCheck(ctx context.Context) error
	Cleanup() error
}

// Logger is an interface for logging
type Logger interface {
	Info(args ...interface{})
	Warn(args ...interface{})
	Error(args ...interface{})
	Debug(args ...interface{})
	WithError(err error) Logger
}

type SystemSituation struct {
	Timestamp         time.Time
	OverallHealth     float64
	ManagerStates     map[string]*ManagerState
	DetectedAnomalies []interface{} // TODO: Définir le type d'anomalie
}
