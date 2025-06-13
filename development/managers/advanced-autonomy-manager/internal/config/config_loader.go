// Package config provides configuration loading and management for the AdvancedAutonomyManager
package config

import (
	"fmt"
	"os"
	"time"

	"gopkg.in/yaml.v3"

	"advanced-autonomy-manager/interfaces"
	"advanced-autonomy-manager/internal/discovery"
)

// LoadConfigFromFile charge la configuration depuis un fichier YAML
func LoadConfigFromFile(configPath string) (*AutonomyConfig, error) {
	if configPath == "" {
		return GetDefaultConfig(), nil
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file %s: %w", configPath, err)
	}

	var config AutonomyConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file %s: %w", configPath, err)
	}

	// Valider et compléter la configuration
	if err := validateAndCompleteConfig(&config); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}

	return &config, nil
}

// GetDefaultConfig retourne une configuration par défaut complète
func GetDefaultConfig() *AutonomyConfig {
	return &AutonomyConfig{
		// Niveau d'autonomie
		AutonomyLevel: interfaces.AutonomyLevelComplete,
		
		// Configuration des composants
		DecisionConfig: &DecisionEngineConfig{
			NeuralTreeLevels:    8,
			ConfidenceThreshold: 0.85,
			RiskAssessmentDepth: 5,
			TrainingDataSize:    10000,
			DecisionSpeedTarget: 200 * time.Millisecond,
		},
		
		PredictiveConfig: &PredictiveConfig{
			ForecastHorizon:        24 * time.Hour,
			ModelUpdateInterval:    1 * time.Hour,
			PredictionAccuracyTarget: 0.92,
			DataRetentionPeriod:    30 * 24 * time.Hour,
			ModelTrainingEnabled:   true,
		},
		
		MonitoringConfig: &MonitoringConfig{
			DashboardUpdateRate:    1 * time.Second,
			MetricsRetentionPeriod: 7 * 24 * time.Hour,
			AlertThresholds: map[string]float64{
				"cpu_usage":    0.80,
				"memory_usage": 0.85,
				"error_rate":   0.05,
				"response_time": 2.0,
			},
			RealTimeEnabled: true,
		},
		
		HealingConfig: &HealingConfig{
			AnomalyDetectionSensitivity: 0.75,
			AutoCorrectionEnabled:       true,
			LearningPatterns:           true,
			HealingTimeout:             5 * time.Minute,
			MaxHealingAttempts:         3,
		},
		
		CoordinationConfig: &CoordinationConfig{
			EventBusBufferSize:    10000,
			StateSyncInterval:     30 * time.Second,
			EmergencyResponseTime: 5 * time.Second,
			OrchestratorWorkers:   4,
		},
		
		DiscoveryConfig: &discovery.DiscoveryConfig{
			EnableFileSystemDiscovery: true,
			EnableNetworkDiscovery:    true,
			EnableRegistryDiscovery:   false,
			SearchPaths: []string{
				"../",
				"../../",
				"./development/managers/",
				"./managers/",
			},
			NetworkScanRange:  "127.0.0.1/32",
			DiscoveryTimeout:  30 * time.Second,
			ManagerPorts:      []int{8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089, 8090, 8091, 8092, 8093, 8094, 8095, 8096, 8097, 8098, 8099},
			ConnectionTimeout: 10 * time.Second,
			RetryAttempts:     3,
			RetryDelay:        2 * time.Second,
			ExpectedManagers:  discovery.ExpectedEcosystemManagers,
		},
		
		// Intervalles et timing
		HealthCheckInterval: 30 * time.Second,
		
		// Seuils et limites
		SafetyThreshold:   0.95,
		RiskTolerance:     0.10,
		PerformanceTarget: 0.90,
		
		// Apprentissage et adaptation
		LearningEnabled:  true,
		AdaptationRate:   0.05,
		HistoryRetention: 7 * 24 * time.Hour,
	}
}

// validateAndCompleteConfig valide et complète une configuration
func validateAndCompleteConfig(config *AutonomyConfig) error {
	// Valider le niveau d'autonomie
	if config.AutonomyLevel < interfaces.AutonomyLevelBasic || config.AutonomyLevel > interfaces.AutonomyLevelComplete {
		return fmt.Errorf("invalid autonomy level: %d", config.AutonomyLevel)
	}

	// Compléter les configurations manquantes avec les valeurs par défaut
	defaultConfig := GetDefaultConfig()
	
	if config.DecisionConfig == nil {
		config.DecisionConfig = defaultConfig.DecisionConfig
	}
	
	if config.PredictiveConfig == nil {
		config.PredictiveConfig = defaultConfig.PredictiveConfig
	}
	
	if config.MonitoringConfig == nil {
		config.MonitoringConfig = defaultConfig.MonitoringConfig
	}
	
	if config.HealingConfig == nil {
		config.HealingConfig = defaultConfig.HealingConfig
	}
	
	if config.CoordinationConfig == nil {
		config.CoordinationConfig = defaultConfig.CoordinationConfig
	}
	
	if config.DiscoveryConfig == nil {
		config.DiscoveryConfig = defaultConfig.DiscoveryConfig
	}

	// Valider les seuils
	if config.SafetyThreshold < 0.5 || config.SafetyThreshold > 1.0 {
		return fmt.Errorf("invalid safety threshold: %f (must be between 0.5 and 1.0)", config.SafetyThreshold)
	}
	
	if config.RiskTolerance < 0.0 || config.RiskTolerance > 0.5 {
		return fmt.Errorf("invalid risk tolerance: %f (must be between 0.0 and 0.5)", config.RiskTolerance)
	}
	
	if config.PerformanceTarget < 0.5 || config.PerformanceTarget > 1.0 {
		return fmt.Errorf("invalid performance target: %f (must be between 0.5 and 1.0)", config.PerformanceTarget)
	}

	return nil
}

// SaveConfigToFile sauvegarde la configuration dans un fichier YAML
func SaveConfigToFile(config *AutonomyConfig, filePath string) error {
	data, err := yaml.Marshal(config)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	if err := os.WriteFile(filePath, data, 0644); err != nil {
		return fmt.Errorf("failed to write config file %s: %w", filePath, err)
	}

	return nil
}

// Config type definitions (repeated from main file for package independence)

// AutonomyConfig contient la configuration complète du manager autonome
type AutonomyConfig struct {
	// Niveau d'autonomie
	AutonomyLevel interfaces.AutonomyLevel `yaml:"autonomy_level" json:"autonomy_level"`
	
	// Configuration des composants
	DecisionConfig     *DecisionEngineConfig     `yaml:"decision_config" json:"decision_config"`
	PredictiveConfig   *PredictiveConfig         `yaml:"predictive_config" json:"predictive_config"`
	MonitoringConfig   *MonitoringConfig         `yaml:"monitoring_config" json:"monitoring_config"`
	HealingConfig      *HealingConfig            `yaml:"healing_config" json:"healing_config"`
	CoordinationConfig *CoordinationConfig       `yaml:"coordination_config" json:"coordination_config"`
	DiscoveryConfig    *discovery.DiscoveryConfig `yaml:"discovery_config" json:"discovery_config"`
	
	// Intervalles et timing
	HealthCheckInterval time.Duration `yaml:"health_check_interval" json:"health_check_interval"`
	
	// Seuils et limites
	SafetyThreshold   float64 `yaml:"safety_threshold" json:"safety_threshold"`
	RiskTolerance     float64 `yaml:"risk_tolerance" json:"risk_tolerance"`
	PerformanceTarget float64 `yaml:"performance_target" json:"performance_target"`
	
	// Apprentissage et adaptation
	LearningEnabled   bool `yaml:"learning_enabled" json:"learning_enabled"`
	AdaptationRate    float64 `yaml:"adaptation_rate" json:"adaptation_rate"`
	HistoryRetention  time.Duration `yaml:"history_retention" json:"history_retention"`
}

// DecisionEngineConfig configure le moteur de décision neural
type DecisionEngineConfig struct {
	NeuralTreeLevels     int     `yaml:"neural_tree_levels" json:"neural_tree_levels"`
	ConfidenceThreshold  float64 `yaml:"confidence_threshold" json:"confidence_threshold"`
	RiskAssessmentDepth  int     `yaml:"risk_assessment_depth" json:"risk_assessment_depth"`
	TrainingDataSize     int     `yaml:"training_data_size" json:"training_data_size"`
	DecisionSpeedTarget  time.Duration `yaml:"decision_speed_target" json:"decision_speed_target"`
}

// PredictiveConfig configure le système de maintenance prédictive
type PredictiveConfig struct {
	ForecastHorizon        time.Duration `yaml:"forecast_horizon" json:"forecast_horizon"`
	ModelUpdateInterval    time.Duration `yaml:"model_update_interval" json:"model_update_interval"`
	PredictionAccuracyTarget float64     `yaml:"prediction_accuracy_target" json:"prediction_accuracy_target"`
	DataRetentionPeriod    time.Duration `yaml:"data_retention_period" json:"data_retention_period"`
	ModelTrainingEnabled   bool          `yaml:"model_training_enabled" json:"model_training_enabled"`
}

// MonitoringConfig configure le dashboard de monitoring
type MonitoringConfig struct {
	DashboardUpdateRate    time.Duration         `yaml:"dashboard_update_rate" json:"dashboard_update_rate"`
	MetricsRetentionPeriod time.Duration         `yaml:"metrics_retention_period" json:"metrics_retention_period"`
	AlertThresholds        map[string]float64    `yaml:"alert_thresholds" json:"alert_thresholds"`
	RealTimeEnabled        bool                  `yaml:"real_time_enabled" json:"real_time_enabled"`
}

// HealingConfig configure le système d'auto-réparation
type HealingConfig struct {
	AnomalyDetectionSensitivity float64       `yaml:"anomaly_detection_sensitivity" json:"anomaly_detection_sensitivity"`
	AutoCorrectionEnabled       bool          `yaml:"auto_correction_enabled" json:"auto_correction_enabled"`
	LearningPatterns           bool          `yaml:"learning_patterns" json:"learning_patterns"`
	HealingTimeout             time.Duration `yaml:"healing_timeout" json:"healing_timeout"`
	MaxHealingAttempts         int           `yaml:"max_healing_attempts" json:"max_healing_attempts"`
}

// CoordinationConfig configure la couche de coordination maître
type CoordinationConfig struct {
	EventBusBufferSize   int           `yaml:"event_bus_buffer_size" json:"event_bus_buffer_size"`
	StateSyncInterval    time.Duration `yaml:"state_sync_interval" json:"state_sync_interval"`
	EmergencyResponseTime time.Duration `yaml:"emergency_response_time" json:"emergency_response_time"`
	OrchestratorWorkers  int           `yaml:"orchestrator_workers" json:"orchestrator_workers"`
}
