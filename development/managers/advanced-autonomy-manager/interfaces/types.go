package interfaces

import (
	"context"
	"time"
)

// Logger interface for structured logging
type Logger interface {
	Debug(msg string, fields ...interface{})
	Info(msg string, fields ...interface{})
	Warn(msg string, fields ...interface{})
	Error(msg string, fields ...interface{})
	Fatal(msg string, fields ...interface{})
	With(fields ...interface{}) Logger
	WithError(err error) Logger
}

// DecisionEngineConfig configure le moteur de décision neural
type DecisionEngineConfig struct {
	NeuralTreeLevels    int           `yaml:"neural_tree_levels" json:"neural_tree_levels"`
	ConfidenceThreshold float64       `yaml:"confidence_threshold" json:"confidence_threshold"`
	RiskAssessmentDepth int           `yaml:"risk_assessment_depth" json:"risk_assessment_depth"`
	TrainingDataSize    int           `yaml:"training_data_size" json:"training_data_size"`
	DecisionSpeedTarget time.Duration `yaml:"decision_speed_target" json:"decision_speed_target"`

	// Nouveaux champs pour AutonomousDecisionEngine
	LearningEnabled      bool          `yaml:"learning_enabled" json:"learning_enabled"`
	MaxDecisionTime      time.Duration `yaml:"max_decision_time" json:"max_decision_time"`
	CacheEnabled         bool          `yaml:"cache_enabled" json:"cache_enabled"`
	CacheExpirationTime  time.Duration `yaml:"cache_expiration_time" json:"cache_expiration_time"`
	RollbackPlanRequired bool          `yaml:"rollback_plan_required" json:"rollback_plan_required"`
	RiskTolerance        float64       `yaml:"risk_tolerance" json:"risk_tolerance"`
}

// PredictiveConfig configure la maintenance prédictive
type PredictiveConfig struct {
	PredictionHorizon time.Duration `yaml:"prediction_horizon" json:"prediction_horizon"`
	AnalysisDepth     int           `yaml:"analysis_depth" json:"analysis_depth"`
	MLModelPath       string        `yaml:"ml_model_path" json:"ml_model_path"`
	AccuracyThreshold float64       `yaml:"accuracy_threshold" json:"accuracy_threshold"`
	UpdateFrequency   time.Duration `yaml:"update_frequency" json:"update_frequency"`

	// Nouveaux champs pour PredictiveMaintenanceCore
	CacheEnabled         bool          `yaml:"cache_enabled" json:"cache_enabled"`
	CacheExpirationTime  time.Duration `yaml:"cache_expiration_time" json:"cache_expiration_time"`
	ProactiveScheduling  bool          `yaml:"proactive_scheduling" json:"proactive_scheduling"`
	ResourceOptimization bool          `yaml:"resource_optimization" json:"resource_optimization"`
	DataSamplingRate     time.Duration `yaml:"data_sampling_rate" json:"data_sampling_rate"`
}

// MonitoringConfig configure le dashboard temps réel
type MonitoringConfig struct {
	DashboardPort    int                `yaml:"dashboard_port" json:"dashboard_port"`
	UpdateInterval   time.Duration      `yaml:"update_interval" json:"update_interval"`
	MetricsRetention time.Duration      `yaml:"metrics_retention" json:"metrics_retention"`
	AlertThresholds  map[string]float64 `yaml:"alert_thresholds" json:"alert_thresholds"`
	WebSocketEnabled bool               `yaml:"websocket_enabled" json:"websocket_enabled"`
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

// AutonomyLevel represents the level of autonomy for the manager
type AutonomyLevel int

const (
	AutonomyLevelBasic    AutonomyLevel = 1
	AutonomyLevelMedium   AutonomyLevel = 2
	AutonomyLevelAdvanced AutonomyLevel = 3
	AutonomyLevelComplete AutonomyLevel = 4
)

// BaseManager interface that all managers must implement
type BaseManager interface {
	// Core functionality
	Initialize(ctx context.Context) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	GetHealth() HealthStatus
	GetMetrics() map[string]interface{}
	GetDependencies() []string

	// Health and lifecycle
	HealthCheck(ctx context.Context) error
	Cleanup() error

	// Operational methods
	ProcessOperation(operation *Operation) error
	ValidateConfiguration() error
	GetConfiguration() interface{}
	UpdateConfiguration(config interface{}) error
}

// HealthStatus represents the health status of a manager
type HealthStatus struct {
	IsHealthy bool                   `json:"is_healthy"`
	Score     float64                `json:"score"`
	Message   string                 `json:"message"`
	LastCheck time.Time              `json:"last_check"`
	Details   map[string]interface{} `json:"details"`
}

// SystemSituation représente l'état actuel de l'écosystème complet du FMOUA
// avec l'état détaillé des 20 managers existants
type SystemSituation struct {
	// Timestamp est le moment où la situation a été capturée
	Timestamp time.Time `json:"timestamp"`

	// ManagerStates contient l'état de chaque manager dans l'écosystème
	// La clé est le nom du manager, la valeur est son état actuel
	ManagerStates map[string]*ManagerState `json:"manager_states"`

	// OverallHealth représente la santé globale de l'écosystème (0.0-1.0)
	OverallHealth float64 `json:"overall_health"`

	// ActiveOperations sont les opérations en cours d'exécution
	ActiveOperations []*Operation `json:"active_operations"`

	// ResourceUtilization représente l'utilisation des ressources
	ResourceUtilization *ResourceUtilization `json:"resource_utilization"`

	// DetectedAnomalies contient les anomalies détectées dans l'écosystème
	DetectedAnomalies []*Anomaly `json:"detected_anomalies"`

	// PendingDecisions contient les décisions qui sont en attente d'exécution
	PendingDecisions []*AutonomousDecision `json:"pending_decisions"`
}

// ManagerState représente l'état actuel d'un manager spécifique
type ManagerState struct {
	// Name est le nom du manager
	Name string `json:"name"`

	// Version est la version du manager
	Version string `json:"version"`

	// Status est le statut actuel du manager (running, stopped, degraded, etc.)
	Status string `json:"status"`

	// HealthScore est le score de santé du manager (0.0-1.0)
	HealthScore float64 `json:"health_score"`

	// LastHealthCheck est le timestamp du dernier contrôle de santé
	LastHealthCheck time.Time `json:"last_health_check"`

	// Metrics contient les métriques spécifiques à ce manager
	Metrics map[string]interface{} `json:"metrics"`

	// ActiveTasks est le nombre de tâches actuellement traitées
	ActiveTasks int `json:"active_tasks"`

	// ErrorCount est le nombre d'erreurs enregistrées depuis le démarrage
	ErrorCount int `json:"error_count"`

	// DependenciesStatus indique l'état des dépendances du manager
	DependenciesStatus map[string]bool `json:"dependencies_status"`
}

// AutonomousDecision représente une décision prise par le système d'IA
// qui peut être exécutée de manière autonome
type AutonomousDecision struct {
	// ID est l'identifiant unique de la décision
	ID string `json:"id"`

	// CreatedAt est le moment où la décision a été créée
	CreatedAt time.Time `json:"created_at"`

	// Type est le type de décision (maintenance, optimisation, réparation, etc.)
	Type string `json:"type"`

	// Description est une description détaillée de la décision
	Description string `json:"description"`

	// TargetManagers sont les managers concernés par cette décision
	TargetManagers []string `json:"target_managers"`

	// Actions sont les actions à exécuter dans le cadre de cette décision
	Actions []*Action `json:"actions"`

	// RiskAssessment contient l'évaluation des risques associés à cette décision
	RiskAssessment *RiskAssessment `json:"risk_assessment"`

	// RollbackStrategy définit la stratégie de retour en arrière en cas d'échec
	RollbackStrategy *RollbackStrategy `json:"rollback_strategy"`

	// Priority définit la priorité de la décision (0-100)
	Priority int `json:"priority"`

	// EstimatedDuration est la durée estimée d'exécution de la décision
	EstimatedDuration time.Duration `json:"estimated_duration"`

	// RequiresApproval indique si cette décision nécessite une approbation manuelle
	RequiresApproval bool `json:"requires_approval"`

	// ApprovedBy contient l'information sur qui a approuvé cette décision
	ApprovedBy string `json:"approved_by,omitempty"`
}

// Action représente une action à exécuter dans le cadre d'une décision
type Action struct {
	// ID est l'identifiant unique de l'action
	ID string `json:"id"`

	// Type est le type d'action
	Type string `json:"type"`

	// TargetManager est le manager cible de cette action
	TargetManager string `json:"target_manager"`

	// Parameters contient les paramètres de l'action
	Parameters map[string]interface{} `json:"parameters"`

	// Dependencies sont les IDs des actions qui doivent être terminées avant celle-ci
	Dependencies []string `json:"dependencies"`

	// Status est le statut actuel de l'action (pending, running, completed, failed)
	Status string `json:"status"`

	// Result contient le résultat de l'action une fois terminée
	Result map[string]interface{} `json:"result,omitempty"`
}

// RiskAssessment représente l'évaluation des risques associés à une décision
type RiskAssessment struct {
	// RiskLevel est le niveau de risque global (0-100)
	RiskLevel int `json:"risk_level"`

	// PotentialImpacts décrit les impacts potentiels de la décision
	PotentialImpacts []string `json:"potential_impacts"`

	// MitigationStrategies décrit les stratégies pour atténuer les risques
	MitigationStrategies []string `json:"mitigation_strategies"`

	// DetailedRisks contient une liste détaillée des risques spécifiques
	DetailedRisks []*Risk `json:"detailed_risks"`
}

// Risk représente un risque spécifique identifié
type Risk struct {
	// Description est une description du risque
	Description string `json:"description"`

	// Probability est la probabilité du risque (0.0-1.0)
	Probability float64 `json:"probability"`

	// Impact est l'impact potentiel du risque (0-100)
	Impact int `json:"impact"`

	// AffectedSystems sont les systèmes affectés par ce risque
	AffectedSystems []string `json:"affected_systems"`
}

// RollbackStrategy définit comment annuler une décision en cas d'échec
type RollbackStrategy struct {
	// RollbackActions sont les actions à exécuter pour revenir en arrière
	RollbackActions []*Action `json:"rollback_actions"`

	// CheckpointBeforeExecution indique s'il faut créer un point de sauvegarde avant l'exécution
	CheckpointBeforeExecution bool `json:"checkpoint_before_execution"`

	// AutomaticRollbackConditions définit les conditions pour un rollback automatique
	AutomaticRollbackConditions []string `json:"automatic_rollback_conditions"`
}

// MaintenanceForecast représente une prédiction des besoins de maintenance
// basée sur l'analyse de ML des patterns de dégradation
type MaintenanceForecast struct {
	// GeneratedAt est le moment où la prédiction a été générée
	GeneratedAt time.Time `json:"generated_at"`

	// TimeHorizon est l'horizon temporel couvert par cette prédiction
	TimeHorizon time.Duration `json:"time_horizon"`

	// PredictedIssues contient les problèmes prédits
	PredictedIssues []*PredictedIssue `json:"predicted_issues"`

	// MaintenanceWindows suggère des fenêtres de maintenance optimales
	MaintenanceWindows []*MaintenanceWindow `json:"maintenance_windows"`

	// ResourceRequirements estime les ressources nécessaires pour la maintenance
	ResourceRequirements *ResourceRequirements `json:"resource_requirements"`

	// Confidence est le niveau de confiance global de cette prédiction (0.0-1.0)
	Confidence float64 `json:"confidence"`

	// DataSources sont les sources de données utilisées pour cette prédiction
	DataSources []string `json:"data_sources"`

	// AlgorithmDetails contient des détails sur l'algorithme de prédiction utilisé
	AlgorithmDetails map[string]interface{} `json:"algorithm_details"`
}

// PredictedIssue représente un problème prédit qui nécessitera une maintenance
type PredictedIssue struct {
	// Type est le type de problème prédit
	Type string `json:"type"`

	// Description est une description détaillée du problème
	Description string `json:"description"`

	// AffectedComponents sont les composants affectés par ce problème
	AffectedComponents []string `json:"affected_components"`

	// ExpectedTimeFrame est la période pendant laquelle le problème est susceptible d'apparaître
	ExpectedTimeFrame *TimeFrame `json:"expected_time_frame"`

	// Severity est la gravité du problème (0-100)
	Severity int `json:"severity"`

	// Confidence est le niveau de confiance de cette prédiction (0.0-1.0)
	Confidence float64 `json:"confidence"`

	// PreventiveActions sont les actions recommandées pour prévenir ce problème
	PreventiveActions []string `json:"preventive_actions"`

	// EstimatedResolutionTime est le temps estimé pour résoudre ce problème
	EstimatedResolutionTime time.Duration `json:"estimated_resolution_time"`
}

// TimeFrame représente une période temporelle
type TimeFrame struct {
	// Start est le début de la période
	Start time.Time `json:"start"`

	// End est la fin de la période
	End time.Time `json:"end"`
}

// MaintenanceWindow représente une fenêtre de temps optimale pour la maintenance
type MaintenanceWindow struct {
	// Start est le début de la fenêtre de maintenance
	Start time.Time `json:"start"`

	// Duration est la durée de la fenêtre de maintenance
	Duration time.Duration `json:"duration"`

	// Priority est la priorité de cette fenêtre (0-100)
	Priority int `json:"priority"`

	// RecommendedIssues sont les IDs des problèmes qu'il est recommandé de traiter
	// pendant cette fenêtre de maintenance
	RecommendedIssues []string `json:"recommended_issues"`

	// ExpectedDowntime est le temps d'arrêt attendu pendant cette maintenance
	ExpectedDowntime time.Duration `json:"expected_downtime"`

	// ImpactLevel est le niveau d'impact de cette fenêtre de maintenance (0-100)
	ImpactLevel int `json:"impact_level"`
}

// ResourceRequirements représente les ressources nécessaires pour la maintenance
type ResourceRequirements struct {
	// CPUCores est le nombre de cœurs CPU requis
	CPUCores int `json:"cpu_cores"`

	// MemoryMB est la quantité de mémoire requise en MB
	MemoryMB int `json:"memory_mb"`

	// DiskSpaceGB est l'espace disque requis en GB
	DiskSpaceGB float64 `json:"disk_space_gb"`

	// NetworkBandwidthMbps est la bande passante réseau requise en Mbps
	NetworkBandwidthMbps int `json:"network_bandwidth_mbps"`

	// HumanResources est le nombre de personnes nécessaires
	HumanResources int `json:"human_resources"`

	// EstimatedCost est le coût estimé de ces ressources
	EstimatedCost float64 `json:"estimated_cost"`
}

// MonitoringDashboard représente un tableau de bord de surveillance en temps réel
type MonitoringDashboard struct {
	// GeneratedAt est le moment où le tableau de bord a été généré
	GeneratedAt time.Time `json:"generated_at"`

	// SystemSituation est la situation actuelle du système
	SystemSituation *SystemSituation `json:"system_situation"`

	// PerformanceMetrics contient les métriques de performance
	PerformanceMetrics map[string]float64 `json:"performance_metrics"`

	// ActiveAlerts contient les alertes actives
	ActiveAlerts []*Alert `json:"active_alerts"`

	// RecentEvents contient les événements récents
	RecentEvents []*Event `json:"recent_events"`

	// HistoricalData contient les données historiques pour les graphiques
	HistoricalData map[string][]*TimeSeriesDataPoint `json:"historical_data"`

	// PredictiveInsights contient les insights prédictifs
	PredictiveInsights []*PredictiveInsight `json:"predictive_insights"`

	// SystemStatus est le statut global du système
	SystemStatus string `json:"system_status"`
}

// Alert représente une alerte active dans le système
type Alert struct {
	// ID est l'identifiant unique de l'alerte
	ID string `json:"id"`

	// Severity est la gravité de l'alerte (info, warning, error, critical)
	Severity string `json:"severity"`

	// Message est le message de l'alerte
	Message string `json:"message"`

	// Source est la source de l'alerte
	Source string `json:"source"`

	// CreatedAt est le moment où l'alerte a été créée
	CreatedAt time.Time `json:"created_at"`

	// AcknowledgedAt est le moment où l'alerte a été reconnue
	AcknowledgedAt *time.Time `json:"acknowledged_at,omitempty"`

	// AcknowledgedBy est la personne qui a reconnu l'alerte
	AcknowledgedBy string `json:"acknowledged_by,omitempty"`

	// RecommendedActions sont les actions recommandées pour résoudre cette alerte
	RecommendedActions []string `json:"recommended_actions"`
}

// Event représente un événement dans le système
type Event struct {
	// ID est l'identifiant unique de l'événement
	ID string `json:"id"`

	// Type est le type d'événement
	Type string `json:"type"`

	// Source est la source de l'événement
	Source string `json:"source"`

	// Message est le message de l'événement
	Message string `json:"message"`

	// Timestamp est le moment où l'événement s'est produit
	Timestamp time.Time `json:"timestamp"`

	// Metadata contient des métadonnées supplémentaires sur l'événement
	Metadata map[string]interface{} `json:"metadata"`
}

// TimeSeriesDataPoint représente un point de données dans une série temporelle
type TimeSeriesDataPoint struct {
	// Timestamp est le moment où le point de données a été collecté
	Timestamp time.Time `json:"timestamp"`

	// Value est la valeur du point de données
	Value float64 `json:"value"`
}

// PredictiveInsight représente un insight prédictif basé sur l'analyse des données
type PredictiveInsight struct {
	// Description est une description de l'insight
	Description string `json:"description"`

	// Confidence est le niveau de confiance de cet insight (0.0-1.0)
	Confidence float64 `json:"confidence"`

	// RelevantMetrics sont les métriques pertinentes pour cet insight
	RelevantMetrics []string `json:"relevant_metrics"`

	// RecommendedActions sont les actions recommandées basées sur cet insight
	RecommendedActions []string `json:"recommended_actions"`

	// PredictionHorizon est l'horizon temporel de la prédiction
	PredictionHorizon time.Duration `json:"prediction_horizon"`
}

// ResourceUtilization représente l'utilisation actuelle des ressources
type ResourceUtilization struct {
	// CPUUtilization est l'utilisation CPU en pourcentage
	CPUUtilization float64 `json:"cpu_utilization"`

	// MemoryUtilization est l'utilisation mémoire en pourcentage
	MemoryUtilization float64 `json:"memory_utilization"`

	// DiskUtilization est l'utilisation disque en pourcentage
	DiskUtilization float64 `json:"disk_utilization"`

	// NetworkUtilization est l'utilisation réseau en pourcentage
	NetworkUtilization float64 `json:"network_utilization"`

	// ActiveConnections est le nombre de connexions actives
	ActiveConnections int `json:"active_connections"`

	// ActiveThreads est le nombre de threads actifs
	ActiveThreads int `json:"active_threads"`

	// ActiveOperations est le nombre d'opérations actives
	ActiveOperations int `json:"active_operations"`
}

// Operation représente une opération en cours d'exécution
type Operation struct {
	// ID est l'identifiant unique de l'opération
	ID string `json:"id"`

	// Type est le type d'opération
	Type string `json:"type"`

	// Status est le statut actuel de l'opération
	Status string `json:"status"`

	// Progress est la progression de l'opération (0.0-1.0)
	Progress float64 `json:"progress"`

	// StartTime est le moment où l'opération a démarré
	StartTime time.Time `json:"start_time"`

	// EstimatedEndTime est le moment estimé de fin de l'opération
	EstimatedEndTime time.Time `json:"estimated_end_time"`

	// Initiator est l'initiateur de l'opération
	Initiator string `json:"initiator"`

	// AffectedComponents sont les composants affectés par cette opération
	AffectedComponents []string `json:"affected_components"`

	// LogEntries sont les entrées de journal de cette opération
	LogEntries []*LogEntry `json:"log_entries"`
}

// LogEntry représente une entrée de journal
type LogEntry struct {
	// Timestamp est le moment où l'entrée a été créée
	Timestamp time.Time `json:"timestamp"`

	// Level est le niveau de l'entrée (debug, info, warning, error)
	Level string `json:"level"`

	// Message est le message de l'entrée
	Message string `json:"message"`

	// Context contient le contexte supplémentaire de l'entrée
	Context map[string]interface{} `json:"context"`
}

// Anomaly représente une anomalie détectée dans le système
type Anomaly struct {
	// ID est l'identifiant unique de l'anomalie
	ID string `json:"id"`

	// Type est le type d'anomalie
	Type string `json:"type"`

	// Description est une description détaillée de l'anomalie
	Description string `json:"description"`

	// DetectedAt est le moment où l'anomalie a été détectée
	DetectedAt time.Time `json:"detected_at"`

	// Source est la source de l'anomalie
	Source string `json:"source"`

	// AffectedComponents sont les composants affectés par cette anomalie
	AffectedComponents []string `json:"affected_components"`

	// Severity est la gravité de l'anomalie (0-100)
	Severity int `json:"severity"`

	// RecommendedActions sont les actions recommandées pour résoudre cette anomalie
	RecommendedActions []*Action `json:"recommended_actions"`

	// SimilarPastAnomalies sont les anomalies similaires détectées dans le passé
	SimilarPastAnomalies []string `json:"similar_past_anomalies"`

	// AutoHealingStatus est le statut de l'auto-réparation pour cette anomalie
	AutoHealingStatus string `json:"auto_healing_status"`
}

// SelfHealingConfig représente la configuration du système d'auto-réparation
type SelfHealingConfig struct {
	// Enabled indique si l'auto-réparation est activée
	Enabled bool `json:"enabled"`

	// MaxConcurrentHealingOperations est le nombre maximum d'opérations de réparation simultanées
	MaxConcurrentHealingOperations int `json:"max_concurrent_healing_operations"`

	// MinSeverityForAutoHealing est la gravité minimale pour déclencher l'auto-réparation
	MinSeverityForAutoHealing int `json:"min_severity_for_auto_healing"`

	// MaxResourceUtilizationPercent est le pourcentage maximum d'utilisation des ressources pour l'auto-réparation
	MaxResourceUtilizationPercent int `json:"max_resource_utilization_percent"`

	// BlackoutPeriods sont les périodes pendant lesquelles l'auto-réparation est désactivée
	BlackoutPeriods []*TimeFrame `json:"blackout_periods"`

	// RequireApprovalForComponents sont les composants qui nécessitent une approbation pour l'auto-réparation
	RequireApprovalForComponents []string `json:"require_approval_for_components"`

	// NotificationEmails sont les emails à notifier lors d'opérations d'auto-réparation
	NotificationEmails []string `json:"notification_emails"`

	// HealingStrategies définit les stratégies de réparation pour différents types d'anomalies
	HealingStrategies map[string]string `json:"healing_strategies"`
}

// ResourceOptimizationResult représente le résultat d'une optimisation de ressources
type ResourceOptimizationResult struct {
	// OptimizedAt est le moment où l'optimisation a été effectuée
	OptimizedAt time.Time `json:"optimized_at"`

	// PreviousUtilization est l'utilisation des ressources avant l'optimisation
	PreviousUtilization *ResourceUtilization `json:"previous_utilization"`

	// OptimizedUtilization est l'utilisation des ressources après l'optimisation
	OptimizedUtilization *ResourceUtilization `json:"optimized_utilization"`

	// ImprovementPercentage est le pourcentage d'amélioration
	ImprovementPercentage float64 `json:"improvement_percentage"`

	// AppliedOptimizations sont les optimisations appliquées
	AppliedOptimizations []*Optimization `json:"applied_optimizations"`

	// ProjectedSavings sont les économies projetées
	ProjectedSavings map[string]float64 `json:"projected_savings"`

	// NextRecommendedOptimizationTime est le moment recommandé pour la prochaine optimisation
	NextRecommendedOptimizationTime time.Time `json:"next_recommended_optimization_time"`
}

// Optimization représente une optimisation appliquée
type Optimization struct {
	// Type est le type d'optimisation
	Type string `json:"type"`

	// Description est une description détaillée de l'optimisation
	Description string `json:"description"`

	// AffectedComponents sont les composants affectés par cette optimisation
	AffectedComponents []string `json:"affected_components"`

	// BeforeState est l'état avant l'optimisation
	BeforeState map[string]interface{} `json:"before_state"`

	// AfterState est l'état après l'optimisation
	AfterState map[string]interface{} `json:"after_state"`

	// ImprovementMetrics sont les métriques d'amélioration
	ImprovementMetrics map[string]float64 `json:"improvement_metrics"`
}

// CrossManagerWorkflow représente un workflow qui traverse plusieurs managers
type CrossManagerWorkflow struct {
	// ID est l'identifiant unique du workflow
	ID string `json:"id"`

	// Name est le nom du workflow
	Name string `json:"name"`

	// Description est une description détaillée du workflow
	Description string `json:"description"`

	// InvolvedManagers sont les managers impliqués dans ce workflow
	InvolvedManagers []string `json:"involved_managers"`

	// WorkflowSteps sont les étapes du workflow
	WorkflowSteps []*WorkflowStep `json:"workflow_steps"`

	// TriggerConditions sont les conditions de déclenchement du workflow
	TriggerConditions []*TriggerCondition `json:"trigger_conditions"`

	// Status est le statut actuel du workflow
	Status string `json:"status"`

	// CreatedAt est le moment où le workflow a été créé
	CreatedAt time.Time `json:"created_at"`

	// LastExecutedAt est le moment où le workflow a été exécuté pour la dernière fois
	LastExecutedAt *time.Time `json:"last_executed_at,omitempty"`

	// ExecutionHistory contient l'historique d'exécution du workflow
	ExecutionHistory []*WorkflowExecution `json:"execution_history"`
}

// WorkflowStep représente une étape dans un workflow
type WorkflowStep struct {
	// ID est l'identifiant unique de l'étape
	ID string `json:"id"`

	// Name est le nom de l'étape
	Name string `json:"name"`

	// TargetManager est le manager cible de cette étape
	TargetManager string `json:"target_manager"`

	// Action est l'action à exécuter
	Action *Action `json:"action"`

	// Dependencies sont les IDs des étapes qui doivent être terminées avant celle-ci
	Dependencies []string `json:"dependencies"`

	// TimeoutSeconds est le timeout en secondes pour cette étape
	TimeoutSeconds int `json:"timeout_seconds"`

	// RetryPolicy définit la politique de réessai pour cette étape
	RetryPolicy *RetryPolicy `json:"retry_policy"`

	// SuccessConditions sont les conditions de succès pour cette étape
	SuccessConditions []*Condition `json:"success_conditions"`

	// FailureHandling définit comment gérer les échecs pour cette étape
	FailureHandling string `json:"failure_handling"`

	// NotifyOnCompletion indique s'il faut notifier lors de la complétion de cette étape
	NotifyOnCompletion bool `json:"notify_on_completion"`
}

// TriggerCondition représente une condition de déclenchement pour un workflow
type TriggerCondition struct {
	// Type est le type de condition
	Type string `json:"type"`

	// Parameters sont les paramètres de la condition
	Parameters map[string]interface{} `json:"parameters"`

	// Description est une description détaillée de la condition
	Description string `json:"description"`
}

// WorkflowExecution représente une exécution de workflow
type WorkflowExecution struct {
	// ExecutionID est l'identifiant unique de l'exécution
	ExecutionID string `json:"execution_id"`

	// StartTime est le moment où l'exécution a démarré
	StartTime time.Time `json:"start_time"`

	// EndTime est le moment où l'exécution s'est terminée
	EndTime *time.Time `json:"end_time,omitempty"`

	// Status est le statut de l'exécution
	Status string `json:"status"`

	// TriggerSource est la source qui a déclenché l'exécution
	TriggerSource string `json:"trigger_source"`

	// StepResults contient les résultats de chaque étape
	StepResults map[string]*StepResult `json:"step_results"`

	// OverallSuccess indique si l'exécution a été un succès global
	OverallSuccess bool `json:"overall_success"`

	// ErrorDetails contient les détails des erreurs en cas d'échec
	ErrorDetails map[string]interface{} `json:"error_details,omitempty"`

	// ExecutionMetrics contient les métriques d'exécution
	ExecutionMetrics map[string]float64 `json:"execution_metrics"`
}

// StepResult représente le résultat d'une étape de workflow
type StepResult struct {
	// Status est le statut de l'étape
	Status string `json:"status"`

	// StartTime est le moment où l'étape a démarré
	StartTime time.Time `json:"start_time"`

	// EndTime est le moment où l'étape s'est terminée
	EndTime *time.Time `json:"end_time,omitempty"`

	// Output est la sortie de l'étape
	Output map[string]interface{} `json:"output"`

	// ErrorMessage est le message d'erreur en cas d'échec
	ErrorMessage string `json:"error_message,omitempty"`

	// RetryCount est le nombre de tentatives effectuées
	RetryCount int `json:"retry_count"`
}

// RetryPolicy représente une politique de réessai
type RetryPolicy struct {
	// MaxRetries est le nombre maximum de tentatives
	MaxRetries int `json:"max_retries"`

	// DelaySeconds est le délai en secondes entre les tentatives
	DelaySeconds int `json:"delay_seconds"`

	// ExponentialBackoff indique s'il faut utiliser un backoff exponentiel
	ExponentialBackoff bool `json:"exponential_backoff"`

	// MaxDelaySeconds est le délai maximum en secondes entre les tentatives
	MaxDelaySeconds int `json:"max_delay_seconds"`
}

// Condition représente une condition
type Condition struct {
	// Type est le type de condition
	Type string `json:"type"`

	// Parameters sont les paramètres de la condition
	Parameters map[string]interface{} `json:"parameters"`

	// Description est une description détaillée de la condition
	Description string `json:"description"`
}

// EmergencySeverity représente la gravité d'une situation d'urgence
type EmergencySeverity string

const (
	// EmergencySeverityLow représente une situation d'urgence de faible gravité
	EmergencySeverityLow EmergencySeverity = "low"

	// EmergencySeverityMedium représente une situation d'urgence de gravité moyenne
	EmergencySeverityMedium EmergencySeverity = "medium"

	// EmergencySeverityHigh représente une situation d'urgence de haute gravité
	EmergencySeverityHigh EmergencySeverity = "high"

	// EmergencySeverityCritical représente une situation d'urgence critique
	EmergencySeverityCritical EmergencySeverity = "critical"
)

// EmergencyResponse représente la réponse à une situation d'urgence
type EmergencyResponse struct {
	// ID est l'identifiant unique de la réponse
	ID string `json:"id"`

	// DetectedAt est le moment où l'urgence a été détectée
	DetectedAt time.Time `json:"detected_at"`

	// RespondedAt est le moment où la réponse a été initiée
	RespondedAt time.Time `json:"responded_at"`

	// Severity est la gravité de la situation d'urgence
	Severity EmergencySeverity `json:"severity"`

	// Description est une description détaillée de la situation d'urgence
	Description string `json:"description"`

	// AffectedComponents sont les composants affectés par cette urgence
	AffectedComponents []string `json:"affected_components"`

	// Actions sont les actions entreprises pour répondre à l'urgence
	Actions []*Action `json:"actions"`

	// Status est le statut actuel de la réponse
	Status string `json:"status"`

	// ResolutionTime est le temps de résolution de l'urgence
	ResolutionTime *time.Duration `json:"resolution_time,omitempty"`

	// RootCause est la cause racine de l'urgence
	RootCause string `json:"root_cause,omitempty"`

	// BusinessImpact est l'impact business de l'urgence
	BusinessImpact string `json:"business_impact"`

	// PreventiveMeasures sont les mesures préventives recommandées
	PreventiveMeasures []string `json:"preventive_measures"`
}

// AutonomyResult représente le résultat d'une opération autonome
type AutonomyResult struct {
	// ID est l'identifiant unique du résultat
	ID string `json:"id"`

	// StartTime est le moment où l'opération a démarré
	StartTime time.Time `json:"start_time"`

	// EndTime est le moment où l'opération s'est terminée
	EndTime time.Time `json:"end_time"`

	// Success indique si l'opération a été un succès
	Success bool `json:"success"`

	// ExecutedActions sont les actions exécutées
	ExecutedActions []*Action `json:"executed_actions"`

	// Issues sont les problèmes rencontrés
	Issues []*Issue `json:"issues"`

	// ImprovementMetrics sont les métriques d'amélioration
	ImprovementMetrics map[string]float64 `json:"improvement_metrics"`

	// ResourcesUsed sont les ressources utilisées
	ResourcesUsed *ResourceUtilization `json:"resources_used"`

	// SystemStateAfter est l'état du système après l'opération
	SystemStateAfter *SystemSituation `json:"system_state_after"`

	// DecisionPathDetails contient les détails du chemin de décision
	DecisionPathDetails *DecisionPathDetails `json:"decision_path_details"`

	// RecommendedFollowUpActions sont les actions de suivi recommandées
	RecommendedFollowUpActions []*Action `json:"recommended_follow_up_actions"`
}

// Issue représente un problème rencontré
type Issue struct {
	// Type est le type de problème
	Type string `json:"type"`

	// Description est une description détaillée du problème
	Description string `json:"description"`

	// Severity est la gravité du problème (0-100)
	Severity int `json:"severity"`

	// AffectedComponents sont les composants affectés par ce problème
	AffectedComponents []string `json:"affected_components"`

	// ResolutionStatus est le statut de résolution du problème
	ResolutionStatus string `json:"resolution_status"`

	// ResolutionActions sont les actions entreprises pour résoudre le problème
	ResolutionActions []*Action `json:"resolution_actions"`

	// ReportedAt est le moment où le problème a été signalé
	ReportedAt time.Time `json:"reported_at"`

	// ResolvedAt est le moment où le problème a été résolu
	ResolvedAt *time.Time `json:"resolved_at,omitempty"`
}

// DecisionPathDetails contient les détails du chemin de décision
type DecisionPathDetails struct {
	// NodeCount est le nombre de nœuds de décision
	NodeCount int `json:"node_count"`

	// MaxDepth est la profondeur maximale de l'arbre de décision
	MaxDepth int `json:"max_depth"`

	// KeyDecisionPoints sont les points de décision clés
	KeyDecisionPoints []*DecisionPoint `json:"key_decision_points"`

	// AlternativePathsConsidered sont les chemins alternatifs considérés
	AlternativePathsConsidered int `json:"alternative_paths_considered"`

	// DecisionMetrics sont les métriques de décision
	DecisionMetrics map[string]float64 `json:"decision_metrics"`

	// AIConfidenceScore est le score de confiance de l'IA pour ce chemin de décision
	AIConfidenceScore float64 `json:"ai_confidence_score"`
}

// DecisionPoint représente un point de décision
type DecisionPoint struct {
	// ID est l'identifiant unique du point de décision
	ID string `json:"id"`

	// Description est une description détaillée du point de décision
	Description string `json:"description"`

	// Options sont les options considérées à ce point de décision
	Options []string `json:"options"`

	// SelectedOption est l'option sélectionnée
	SelectedOption string `json:"selected_option"`

	// ReasoningDetails contient les détails du raisonnement pour ce choix
	ReasoningDetails map[string]interface{} `json:"reasoning_details"`

	// ConfidenceScore est le score de confiance pour ce choix (0.0-1.0)
	ConfidenceScore float64 `json:"confidence_score"`
}

// PredictionResult représente le résultat d'une prédiction
type PredictionResult struct {
	// GeneratedAt est le moment où la prédiction a été générée
	GeneratedAt time.Time `json:"generated_at"`

	// TimeHorizon est l'horizon temporel de la prédiction
	TimeHorizon time.Duration `json:"time_horizon"`

	// MaintenanceForecast est la prédiction des besoins de maintenance
	MaintenanceForecast *MaintenanceForecast `json:"maintenance_forecast"`

	// PerformancePredictions sont les prédictions de performance
	PerformancePredictions map[string][]*TimeSeriesDataPoint `json:"performance_predictions"`

	// ResourceUtilizationForecast est la prévision d'utilisation des ressources
	ResourceUtilizationForecast map[string][]*TimeSeriesDataPoint `json:"resource_utilization_forecast"`

	// PotentialIssues sont les problèmes potentiels prédits
	PotentialIssues []*PredictedIssue `json:"potential_issues"`

	// RecommendedActions sont les actions recommandées
	RecommendedActions []*Action `json:"recommended_actions"`

	// OptimalMaintenanceSchedule est le calendrier de maintenance optimal
	OptimalMaintenanceSchedule []*MaintenanceWindow `json:"optimal_maintenance_schedule"`

	// PredictionConfidence est le niveau de confiance global de la prédiction (0.0-1.0)
	PredictionConfidence float64 `json:"prediction_confidence"`

	// DataSourcesUsed sont les sources de données utilisées pour cette prédiction
	DataSourcesUsed []string `json:"data_sources_used"`
}

// EcosystemHealth représente l'état de santé de l'écosystème
type EcosystemHealth struct {
	// CollectedAt est le moment où les données de santé ont été collectées
	CollectedAt time.Time `json:"collected_at"`

	// OverallHealth est la santé globale de l'écosystème (0.0-1.0)
	OverallHealth float64 `json:"overall_health"`

	// ManagerHealthStatus contient l'état de santé de chaque manager
	ManagerHealthStatus map[string]*ManagerHealth `json:"manager_health_status"`

	// SystemMetrics contient les métriques système
	SystemMetrics map[string]float64 `json:"system_metrics"`

	// ActiveIssues sont les problèmes actifs
	ActiveIssues []*Issue `json:"active_issues"`

	// RecentEvents sont les événements récents
	RecentEvents []*Event `json:"recent_events"`

	// ResourceUtilization est l'utilisation actuelle des ressources
	ResourceUtilization *ResourceUtilization `json:"resource_utilization"`

	// HealthTrend indique la tendance de santé (improving, stable, degrading)
	HealthTrend string `json:"health_trend"`

	// RecommendedActions sont les actions recommandées pour améliorer la santé
	RecommendedActions []*Action `json:"recommended_actions"`

	// HealthHistory contient l'historique de santé
	HealthHistory []*HistoricalHealth `json:"health_history"`

	// Nouveaux champs à ajouter pour correspondre à l'utilisation dans master_coordination_layer.go
	ManagerStates       map[string]*ManagerState `json:"manager_states"`
	CriticalIssues      []string                 `json:"critical_issues"`
	Warnings            []string                 `json:"warnings"`
	Performance         map[string]interface{}   `json:"performance"`
	LastUpdate          time.Time                `json:"last_update"`
	CoordinationMetrics interface{}              `json:"coordination_metrics"`
	EmergencyStatus     string                   `json:"emergency_status"`
}

// ManagerHealth représente l'état de santé d'un manager
type ManagerHealth struct {
	// Name est le nom du manager
	Name string `json:"name"`

	// Version est la version du manager
	Version string `json:"version"`

	// HealthScore est le score de santé (0.0-1.0)
	HealthScore float64 `json:"health_score"`

	// Status est le statut actuel du manager
	Status string `json:"status"`

	// ActiveIssues sont les problèmes actifs pour ce manager
	ActiveIssues []*Issue `json:"active_issues"`

	// Metrics contient les métriques spécifiques à ce manager
	Metrics map[string]float64 `json:"metrics"`

	// LastHealthCheck est le moment du dernier contrôle de santé
	LastHealthCheck time.Time `json:"last_health_check"`

	// DependenciesHealth contient l'état de santé des dépendances
	DependenciesHealth map[string]float64 `json:"dependencies_health"`

	// PerformanceMetrics contient les métriques de performance
	PerformanceMetrics *PerformanceMetrics `json:"performance_metrics"`

	// HealthTrend indique la tendance de santé (improving, stable, degrading)
	HealthTrend string `json:"health_trend"`
}

// PerformanceMetrics représente les métriques de performance d'un manager
type PerformanceMetrics struct {
	// ResponseTime est le temps de réponse moyen en ms
	ResponseTime float64 `json:"response_time"`

	// Throughput est le débit en opérations par seconde
	Throughput float64 `json:"throughput"`

	// ErrorRate est le taux d'erreur en pourcentage
	ErrorRate float64 `json:"error_rate"`

	// CPUUsage est l'utilisation CPU en pourcentage
	CPUUsage float64 `json:"cpu_usage"`

	// MemoryUsage est l'utilisation mémoire en pourcentage
	MemoryUsage float64 `json:"memory_usage"`

	// DiskIO est l'utilisation d'E/S disque
	DiskIO float64 `json:"disk_io"`

	// NetworkIO est l'utilisation d'E/S réseau
	NetworkIO float64 `json:"network_io"`
}

// HistoricalHealth représente un point de données historique de santé
type HistoricalHealth struct {
	// Timestamp est le moment où les données de santé ont été collectées
	Timestamp time.Time `json:"timestamp"`

	// OverallHealth est la santé globale de l'écosystème à ce moment (0.0-1.0)
	OverallHealth float64 `json:"overall_health"`

	// ManagerHealthScores contient les scores de santé de chaque manager
	ManagerHealthScores map[string]float64 `json:"manager_health_scores"`

	// ActiveIssueCount est le nombre de problèmes actifs à ce moment
	ActiveIssueCount int `json:"active_issue_count"`

	// ResourceUtilization est l'utilisation des ressources à ce moment
	ResourceUtilization *ResourceUtilization `json:"resource_utilization"`
}

// DiagnosticConfig configure le moteur de diagnostic
// Harmonisé pour tous les sous-packages
type DiagnosticConfig struct {
	RuleEngine      string `yaml:"rule_engine" json:"rule_engine"`
	AnalysisDepth   int    `yaml:"analysis_depth" json:"analysis_depth"`
	CausalInference bool   `yaml:"causal_inference" json:"causal_inference"`
}

// LearningConfig configure le système d'apprentissage
// Harmonisé pour tous les sous-packages
type LearningConfig struct {
	Algorithm    string  `yaml:"algorithm" json:"algorithm"`
	LearningRate float64 `yaml:"learning_rate" json:"learning_rate"`
	BatchSize    int     `yaml:"batch_size" json:"batch_size"`
}

// DetectorConfig configure le détecteur d'anomalies
// Harmonisé pour tous les sous-packages
type DetectorConfig struct {
	ModelPath   string  `yaml:"model_path" json:"model_path"`
	Sensitivity float64 `yaml:"sensitivity" json:"sensitivity"`
	WindowSize  int     `yaml:"window_size" json:"window_size"`
}

// EngineConfig configure le moteur de réparation
// Harmonisé pour tous les sous-packages
type EngineConfig struct {
	StrategyPath    string `yaml:"strategy_path" json:"strategy_path"`
	SafetyChecks    bool   `yaml:"safety_checks" json:"safety_checks"`
	RollbackEnabled bool   `yaml:"rollback_enabled" json:"rollback_enabled"`
}

// OrchestratorConfig configure l'orchestrateur de récupération
// Harmonisé pour tous les sous-packages
type OrchestratorConfig struct {
	MaxConcurrency  int           `yaml:"max_concurrency" json:"max_concurrency"`
	Timeout         time.Duration `yaml:"timeout" json:"timeout"`
	EscalationRules []string      `yaml:"escalation_rules" json:"escalation_rules"`
}
