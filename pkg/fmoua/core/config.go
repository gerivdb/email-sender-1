// Package core - Configuration FMOUA selon spécifications plan-dev-v53
// Implémente: DRY, KISS, SOLID, AI-First principles
package core

import (
	"fmt"
	"log"
	"time"

	"github.com/spf13/viper"

	"email_sender/pkg/fmoua/types"
)

// FMOUAConfig represents the main configuration structure
// Following KISS principle - simple, clear configuration
type FMOUAConfig struct {
	Performance        types.PerformanceConfig           `yaml:"performance"`
	AIConfig           types.AIConfig                    `yaml:"ai_config"`
	QdrantConfig       types.QDrantConfig                `yaml:"qdrant"`
	ManagersConfig     types.ManagersConfig              `yaml:"managers_config"`
	OrganizationConfig types.OrganizationConfig          `yaml:"organization"`
	CleanupConfig      types.CleanupConfig               `yaml:"cleanup"`
	GoGenConfig        types.GoGenConfig                 `yaml:"gogen"`
	PowerShellConfig   types.PowerShellIntegrationConfig `yaml:"powershell_integration"`
	MonitoringConfig   types.MonitoringConfig            `yaml:"monitoring"`
	DatabaseConfig     types.DatabaseConfig              `yaml:"database"`
	SecurityConfig     types.SecurityConfig              `yaml:"security"`
	LoggingConfig      types.LoggingConfig               `yaml:"logging"`
}

// LoadFMOUAConfig loads configuration from file
func LoadFMOUAConfig(configPath string) (*FMOUAConfig, error) {
	viper.SetConfigFile(configPath)
	viper.SetConfigType("yaml")

	if err := viper.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	log.Printf("DEBUG: Config file loaded successfully from: %s", configPath)
	log.Printf("DEBUG: Viper keys: %v", viper.AllKeys())
	log.Printf("DEBUG: Performance section: %v", viper.Get("performance"))

	var config FMOUAConfig
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}
	// Manual fix for performance config if needed
	if config.Performance.TargetLatencyMs == 0 {
		log.Printf("DEBUG: Manual fix for performance config")
		config.Performance.TargetLatencyMs = viper.GetInt("performance.target_latency_ms")
		config.Performance.MaxConcurrentOps = viper.GetInt("performance.max_concurrent_operations")
		config.Performance.CacheEnabled = viper.GetBool("performance.cache_enabled")
	}	// Manual fix for managers config if needed
	if len(config.ManagersConfig.Managers) == 0 {
		log.Printf("DEBUG: Manual fix for managers config")
		config.ManagersConfig.Managers = make(map[string]types.ManagerConfig)
		// Try to get managers from the saved config
		managersRaw := viper.Get("managers_config.managers")
		if managersMap, ok := managersRaw.(map[string]interface{}); ok {
			for managerName, managerData := range managersMap {
				if _, ok := managerData.(map[string]interface{}); ok {
					config.ManagersConfig.Managers[managerName] = types.ManagerConfig{
						Enabled:  viper.GetBool(fmt.Sprintf("managers_config.managers.%s.enabled", managerName)),
						Path:     viper.GetString(fmt.Sprintf("managers_config.managers.%s.path", managerName)),
						Priority: viper.GetInt(fmt.Sprintf("managers_config.managers.%s.priority", managerName)),
					}
				}
			}
		}

		// If still no managers, try old format
		if len(config.ManagersConfig.Managers) == 0 {
			managersKeys := []string{"error_manager", "storage_manager", "security_manager", "config_manager", "cache_manager", "logging_manager"}
			for _, managerKey := range managersKeys {
				if viper.GetBool("managers_config." + managerKey + ".enabled") {
					config.ManagersConfig.Managers[managerKey] = types.ManagerConfig{
						Enabled:  viper.GetBool("managers_config." + managerKey + ".enabled"),
						Path:     viper.GetString("managers_config." + managerKey + ".path"),
						Priority: viper.GetInt("managers_config." + managerKey + ".priority"),
					}
				}
			}
		}

		// Set default values for missing fields
		if config.ManagersConfig.HealthCheckInterval == 0 {
			config.ManagersConfig.HealthCheckInterval = 30 * time.Second
		}
		if config.ManagersConfig.DefaultTimeout == 0 {
			config.ManagersConfig.DefaultTimeout = 10 * time.Second
		}
		if config.ManagersConfig.MaxRetries == 0 {
			config.ManagersConfig.MaxRetries = 3
		}
	}
	// Manual fix for AI and QDrant config if needed
	if !config.AIConfig.Enabled {
		log.Printf("DEBUG: Manual fix for AI config")
		config.AIConfig.Enabled = viper.GetBool("ai_config.enabled")
		config.AIConfig.Provider = viper.GetString("ai_config.provider")
		config.AIConfig.Model = viper.GetString("ai_config.model")
		config.AIConfig.ConfidenceThreshold = viper.GetFloat64("ai_config.confidence_threshold")
		config.AIConfig.LearningEnabled = viper.GetBool("ai_config.learning_enabled")
		config.AIConfig.PatternRecognition = viper.GetBool("ai_config.pattern_recognition")
		config.AIConfig.DecisionAutonomyLevel = viper.GetInt("ai_config.decision_autonomy_level")
	}

	if config.AIConfig.QDrant == nil {
		log.Printf("DEBUG: Manual fix for QDrant config")
		config.AIConfig.QDrant = &types.QDrantConfig{
			Host:           viper.GetString("qdrant.host"),
			Port:           viper.GetInt("qdrant.port"),
			CollectionName: viper.GetString("qdrant.collection_name"),
			VectorSize:     viper.GetInt("qdrant.vector_size"),
			DistanceMetric: viper.GetString("qdrant.distance_metric"),
		}

		// Set defaults if not configured
		if config.AIConfig.QDrant.Host == "" {
			config.AIConfig.QDrant.Host = "localhost"
		}
		if config.AIConfig.QDrant.Port == 0 {
			config.AIConfig.QDrant.Port = 6333
		}
		if config.AIConfig.QDrant.CollectionName == "" {
			config.AIConfig.QDrant.CollectionName = "fmoua_repository_vectors"
		}
		if config.AIConfig.QDrant.VectorSize == 0 {
			config.AIConfig.QDrant.VectorSize = 1536
		}
		if config.AIConfig.QDrant.DistanceMetric == "" {
			config.AIConfig.QDrant.DistanceMetric = "cosine"
		}
	}

	log.Printf("DEBUG: Config unmarshaled. Performance: %+v", config.Performance)

	// Validate configuration
	if err := ValidateFMOUAConfig(&config); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}

	return &config, nil
}

// ValidateFMOUAConfig validates FMOUA configuration
func ValidateFMOUAConfig(config *FMOUAConfig) error {
	if config == nil {
		return fmt.Errorf("config cannot be nil")
	}
	// Validate performance targets (< 100ms requirement)
	log.Printf("DEBUG: TargetLatencyMs = %d", config.Performance.TargetLatencyMs)
	if config.Performance.TargetLatencyMs <= 0 || config.Performance.TargetLatencyMs > 100 {
		return fmt.Errorf("target latency must be between 1-100ms for FMOUA compliance")
	}

	// Validate AI configuration (AI-First principle)
	if config.AIConfig.Enabled && config.AIConfig.ConfidenceThreshold <= 0 {
		return fmt.Errorf("AI confidence threshold must be greater than 0 when AI is enabled")
	}

	// Validate QDrant configuration for vectorization
	if config.AIConfig.Enabled && config.AIConfig.QDrant == nil {
		return fmt.Errorf("QDrant configuration required when AI is enabled")
	}
	// Validate managers configuration (17 managers integration)
	log.Printf("DEBUG: ManagersConfig: %+v", config.ManagersConfig)
	if len(config.ManagersConfig.Managers) == 0 {
		return fmt.Errorf("at least one manager must be configured for FMOUA integration")
	}

	return nil
}

// GetDefaultFMOUAConfig returns default configuration following FMOUA specifications
func GetDefaultFMOUAConfig() *FMOUAConfig {
	return &FMOUAConfig{
		Performance: types.PerformanceConfig{
			TargetLatencyMs:  100, // FMOUA requirement: < 100ms
			MaxConcurrentOps: 50,
			CacheEnabled:     true,
		},
		AIConfig: types.AIConfig{
			Enabled:               true, // AI-First principle
			Provider:              "openai",
			Model:                 "gpt-4",
			ConfidenceThreshold:   0.8,
			LearningEnabled:       true,
			PatternRecognition:    true,
			DecisionAutonomyLevel: 3,
			CacheSize:             1000,
			QDrant: &types.QDrantConfig{
				Host:           "localhost",
				Port:           6333,
				CollectionName: "fmoua_vectors",
				VectorSize:     768,
				DistanceMetric: "cosine",
				Timeout:        time.Second * 30,
			},
		},
		ManagersConfig: types.ManagersConfig{
			HealthCheckInterval: time.Minute * 5,
			DefaultTimeout:      time.Second * 30,
			MaxRetries:          3,
			Managers: map[string]types.ManagerConfig{
				"ErrorManager":      {Enabled: true, Priority: 1},
				"StorageManager":    {Enabled: true, Priority: 2},
				"SecurityManager":   {Enabled: true, Priority: 3},
				"MonitoringManager": {Enabled: true, Priority: 4},
				"CacheManager":      {Enabled: true, Priority: 5},
				"ConfigManager":     {Enabled: true, Priority: 6},
				"LogManager":        {Enabled: true, Priority: 7},
				"MetricsManager":    {Enabled: true, Priority: 8},
				"HealthManager":     {Enabled: true, Priority: 9},
				"BackupManager":     {Enabled: true, Priority: 10},
				"ValidationManager": {Enabled: true, Priority: 11},
				"TestManager":       {Enabled: true, Priority: 12},
				"DeploymentManager": {Enabled: true, Priority: 13},
				"NetworkManager":    {Enabled: true, Priority: 14},
				"DatabaseManager":   {Enabled: true, Priority: 15},
				"AuthManager":       {Enabled: true, Priority: 16},
				"APIManager":        {Enabled: true, Priority: 17},
			},
		},
		OrganizationConfig: types.OrganizationConfig{
			MaxFilesPerFolder:   50,
			AutoCategorization:  true,
			PatternLearning:     true,
			SimilarityThreshold: 0.8,
			FilePatterns: map[string]types.FilePatternConfig{
				"go":         {Extensions: []string{".go"}, Organization: "by_domain"},
				"yaml":       {Extensions: []string{".yaml", ".yml"}, Organization: "by_function"},
				"powershell": {Extensions: []string{".ps1"}, Organization: "by_purpose"},
				"markdown":   {Extensions: []string{".md"}, Organization: "by_topic"},
			},
		},
		CleanupConfig: types.CleanupConfig{
			Levels: map[int]types.CleanupLevelConfig{
				1: {
					Name:                   "Safe Cleanup",
					AutoApprove:            true,
					AIAnalysisRequired:     false,
					ManualApprovalRequired: false,
					BackupBefore:           true,
					ConfidenceThreshold:    0.95,
					Targets:                []string{"temp_files", "cache", "logs"},
				},
				2: {
					Name:                   "Standard Cleanup",
					AutoApprove:            false,
					AIAnalysisRequired:     true,
					ManualApprovalRequired: false,
					BackupBefore:           true,
					ConfidenceThreshold:    0.85,
					Targets:                []string{"duplicate_files", "unused_imports", "old_versions"},
				},
				3: {
					Name:                   "Deep Cleanup",
					AutoApprove:            false,
					AIAnalysisRequired:     true,
					ManualApprovalRequired: true,
					BackupBefore:           true,
					ConfidenceThreshold:    0.90,
					Targets:                []string{"dead_code", "obsolete_files", "restructure"},
				},
			},
		},
		GoGenConfig: types.GoGenConfig{
			TemplatesPath: "./templates",
			OutputPath:    "./generated",
			Templates: map[string]types.TemplateConfig{
				"manager": {
					Description: "Generate a new manager",
					Files: []types.FileTemplate{
						{Path: "{{.Name}}_manager.go", Template: "manager.tmpl"},
					},
					Variables: map[string]string{
						"package": "managers",
					},
				},
			},
		},
		PowerShellConfig: types.PowerShellIntegrationConfig{
			Enabled:         true,
			ScriptsPath:     "./scripts",
			ExecutionPolicy: "RemoteSigned",
			Timeout:         time.Minute * 5,
			AllowedScripts: []string{
				"cleanup.ps1",
				"optimization.ps1",
				"dashboard.ps1",
			},
			Environment: map[string]string{
				"FMOUA_MODE": "production",
			},
		},
		MonitoringConfig: types.MonitoringConfig{
			Enabled:          true,
			MetricsInterval:  time.Minute,
			LogLevel:         "info",
			EnableProfiling:  true,
			HealthCheckPort:  8080,
			DashboardEnabled: true,
			AlertThresholds: map[string]float64{
				"latency_ms":   100,
				"error_rate":   0.05,
				"memory_usage": 80,
				"cpu_usage":    70,
			},
		},
		DatabaseConfig: types.DatabaseConfig{
			Type:              "postgres",
			Host:              "localhost",
			Port:              5432,
			Database:          "fmoua",
			MaxConnections:    25,
			ConnectionTimeout: time.Second * 30,
			QueryTimeout:      time.Second * 10,
			SSLMode:           "prefer",
			BackupEnabled:     true,
			BackupInterval:    time.Hour * 24,
		},
		SecurityConfig: types.SecurityConfig{
			EnabledChecks:   []string{"file_permissions", "code_analysis", "dependency_scan"},
			ScanIntervalMin: 60,
			ThreatDetection: true,
			AuthRequired:    true,
			EncryptionLevel: "AES256",
		},
		LoggingConfig: types.LoggingConfig{
			Level:           "info",
			Format:          "json",
			OutputPath:      "./logs/fmoua.log",
			ErrorOutputPath: "./logs/fmoua_error.log",
			EnableConsole:   true,
			EnableFile:      true,
			MaxSizeMB:       100,
			MaxBackups:      5,
			MaxAgeDays:      30,
			Compress:        true,
		},
	}
}

// SaveFMOUAConfig saves configuration to file
func SaveFMOUAConfig(config *FMOUAConfig, configPath string) error {
	if err := ValidateFMOUAConfig(config); err != nil {
		return fmt.Errorf("invalid configuration: %w", err)
	}

	viper.SetConfigFile(configPath)
	viper.SetConfigType("yaml")

	// Set all config values
	viper.Set("performance", config.Performance)
	viper.Set("ai_config", config.AIConfig)
	viper.Set("qdrant", config.QdrantConfig)
	viper.Set("managers_config", config.ManagersConfig)
	viper.Set("organization", config.OrganizationConfig)
	viper.Set("cleanup", config.CleanupConfig)
	viper.Set("gogen", config.GoGenConfig)
	viper.Set("powershell_integration", config.PowerShellConfig)
	viper.Set("monitoring", config.MonitoringConfig)
	viper.Set("database", config.DatabaseConfig)
	viper.Set("security", config.SecurityConfig)
	viper.Set("logging", config.LoggingConfig)

	if err := viper.WriteConfig(); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

// Helper functions for configuration management

// GetPerformanceTargets returns performance targets for monitoring
func (c *FMOUAConfig) GetPerformanceTargets() map[string]interface{} {
	return map[string]interface{}{
		"target_latency_ms":       c.Performance.TargetLatencyMs,
		"max_concurrent_ops":      c.Performance.MaxConcurrentOps,
		"cache_enabled":           c.Performance.CacheEnabled,
		"ai_confidence_threshold": c.AIConfig.ConfidenceThreshold,
	}
}

// IsAIEnabled returns true if AI functionality is enabled
func (c *FMOUAConfig) IsAIEnabled() bool {
	return c.AIConfig.Enabled
}

// GetEnabledManagers returns list of enabled managers
func (c *FMOUAConfig) GetEnabledManagers() []string {
	var enabled []string
	for name, config := range c.ManagersConfig.Managers {
		if config.Enabled {
			enabled = append(enabled, name)
		}
	}
	return enabled
}

// GetCleanupLevelConfig returns configuration for a specific cleanup level
func (c *FMOUAConfig) GetCleanupLevelConfig(level int) (*types.CleanupLevelConfig, error) {
	config, exists := c.CleanupConfig.Levels[level]
	if !exists {
		return nil, fmt.Errorf("cleanup level %d not configured", level)
	}
	return &config, nil
}
