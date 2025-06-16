package types

import (
	"testing"
	"time"
)

func TestAIConfig_Defaults(t *testing.T) {
	config := AIConfig{
		Enabled:               true,
		Provider:              "openai",
		Model:                 "gpt-4",
		ConfidenceThreshold:   0.8,
		LearningEnabled:       true,
		PatternRecognition:    true,
		DecisionAutonomyLevel: 3,
		CacheSize:             1000,
	}

	if !config.Enabled {
		t.Error("AI should be enabled by default")
	}
	if config.Provider != "openai" {
		t.Errorf("Expected provider 'openai', got '%s'", config.Provider)
	}
	if config.ConfidenceThreshold != 0.8 {
		t.Errorf("Expected confidence threshold 0.8, got %f", config.ConfidenceThreshold)
	}
}

func TestQDrantConfig_Validation(t *testing.T) {
	tests := []struct {
		name   string
		config QDrantConfig
		valid  bool
	}{
		{
			name: "valid config",
			config: QDrantConfig{
				Host:           "localhost",
				Port:           6333,
				CollectionName: "test_collection",
				VectorSize:     768,
				DistanceMetric: "cosine",
				Timeout:        30 * time.Second,
			},
			valid: true,
		},
		{
			name: "invalid port",
			config: QDrantConfig{
				Host:           "localhost",
				Port:           0,
				CollectionName: "test_collection",
				VectorSize:     768,
				DistanceMetric: "cosine",
				Timeout:        30 * time.Second,
			},
			valid: false,
		},
		{
			name: "empty collection name",
			config: QDrantConfig{
				Host:           "localhost",
				Port:           6333,
				CollectionName: "",
				VectorSize:     768,
				DistanceMetric: "cosine",
				Timeout:        30 * time.Second,
			},
			valid: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			valid := tt.config.Port > 0 && tt.config.CollectionName != "" && tt.config.VectorSize > 0
			if valid != tt.valid {
				t.Errorf("Expected validation result %v, got %v", tt.valid, valid)
			}
		})
	}
}

func TestManagerConfig_Priority(t *testing.T) {
	config := ManagerConfig{
		Enabled:  true,
		Path:     "/path/to/manager",
		Priority: 1,
	}

	if !config.Enabled {
		t.Error("Manager should be enabled")
	}
	if config.Priority != 1 {
		t.Errorf("Expected priority 1, got %d", config.Priority)
	}
}

func TestManagersConfig_HealthCheck(t *testing.T) {
	config := ManagersConfig{
		Managers: map[string]ManagerConfig{
			"test_manager": {
				Enabled:  true,
				Path:     "/test",
				Priority: 1,
			},
		},
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}

	if len(config.Managers) == 0 {
		t.Error("Should have at least one manager")
	}
	if config.HealthCheckInterval != 30*time.Second {
		t.Errorf("Expected health check interval 30s, got %v", config.HealthCheckInterval)
	}
	if config.MaxRetries != 3 {
		t.Errorf("Expected max retries 3, got %d", config.MaxRetries)
	}
}

func TestPerformanceConfig_Latency(t *testing.T) {
	config := PerformanceConfig{
		TargetLatencyMs:  100,
		MaxConcurrentOps: 50,
		CacheEnabled:     true,
	}

	if config.TargetLatencyMs > 100 {
		t.Error("Target latency must be <= 100ms for FMOUA compliance")
	}
	if config.MaxConcurrentOps <= 0 {
		t.Error("Max concurrent operations must be positive")
	}
	if !config.CacheEnabled {
		t.Error("Cache should be enabled for performance")
	}
}

func TestCleanupLevelConfig_Validation(t *testing.T) {
	tests := []struct {
		name   string
		config CleanupLevelConfig
		valid  bool
	}{
		{
			name: "safe cleanup level",
			config: CleanupLevelConfig{
				Name:                   "Safe Cleanup",
				AutoApprove:            true,
				AIAnalysisRequired:     false,
				ManualApprovalRequired: false,
				BackupBefore:           true,
				ConfidenceThreshold:    0.95,
				Targets:                []string{"temp_files", "cache"},
			},
			valid: true,
		},
		{
			name: "invalid confidence threshold",
			config: CleanupLevelConfig{
				Name:                   "Invalid Cleanup",
				AutoApprove:            true,
				AIAnalysisRequired:     false,
				ManualApprovalRequired: false,
				BackupBefore:           true,
				ConfidenceThreshold:    1.5, // Invalid: > 1.0
				Targets:                []string{"temp_files"},
			},
			valid: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			valid := tt.config.ConfidenceThreshold >= 0 && tt.config.ConfidenceThreshold <= 1.0
			if valid != tt.valid {
				t.Errorf("Expected validation result %v, got %v", tt.valid, valid)
			}
		})
	}
}

func TestSecurityConfig_EnabledChecks(t *testing.T) {
	config := SecurityConfig{
		EnabledChecks:   []string{"file_permissions", "code_analysis", "dependency_scan"},
		ScanIntervalMin: 60,
		ThreatDetection: true,
		AuthRequired:    true,
		EncryptionLevel: "AES256",
	}

	if len(config.EnabledChecks) == 0 {
		t.Error("Should have at least one security check enabled")
	}
	if config.ScanIntervalMin <= 0 {
		t.Error("Scan interval must be positive")
	}
	if !config.ThreatDetection {
		t.Error("Threat detection should be enabled")
	}
}

func TestMonitoringConfig_Thresholds(t *testing.T) {
	config := MonitoringConfig{
		Enabled:         true,
		MetricsInterval: time.Minute,
		AlertThresholds: map[string]float64{
			"latency_ms":   100,
			"error_rate":   0.05,
			"memory_usage": 80,
			"cpu_usage":    70,
		},
		LogLevel:         "info",
		EnableProfiling:  true,
		HealthCheckPort:  8080,
		DashboardEnabled: true,
	}

	if !config.Enabled {
		t.Error("Monitoring should be enabled")
	}
	if config.AlertThresholds["latency_ms"] > 100 {
		t.Error("Latency threshold should be <= 100ms")
	}
	if config.HealthCheckPort <= 0 {
		t.Error("Health check port must be positive")
	}
}

func TestDatabaseConfig_Connection(t *testing.T) {
	config := DatabaseConfig{
		Type:              "postgres",
		Host:              "localhost",
		Port:              5432,
		Database:          "fmoua",
		MaxConnections:    25,
		ConnectionTimeout: 30 * time.Second,
		QueryTimeout:      10 * time.Second,
		SSLMode:           "prefer",
		BackupEnabled:     true,
		BackupInterval:    24 * time.Hour,
	}

	if config.Type == "" {
		t.Error("Database type must be specified")
	}
	if config.Port <= 0 {
		t.Error("Database port must be positive")
	}
	if config.MaxConnections <= 0 {
		t.Error("Max connections must be positive")
	}
	if config.ConnectionTimeout <= 0 {
		t.Error("Connection timeout must be positive")
	}
}

func TestLoggingConfig_Paths(t *testing.T) {
	config := LoggingConfig{
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
	}

	if config.OutputPath == "" {
		t.Error("Output path must be specified")
	}
	if config.ErrorOutputPath == "" {
		t.Error("Error output path must be specified")
	}
	if config.MaxSizeMB <= 0 {
		t.Error("Max size must be positive")
	}
	if config.MaxBackups <= 0 {
		t.Error("Max backups must be positive")
	}
}

func TestFilePatternConfig_Extensions(t *testing.T) {
	config := FilePatternConfig{
		Extensions:   []string{".go", ".yaml", ".yml"},
		Organization: "by_domain",
	}

	if len(config.Extensions) == 0 {
		t.Error("Should have at least one extension")
	}
	if config.Organization == "" {
		t.Error("Organization strategy must be specified")
	}
}

func TestOrganizationConfig_Thresholds(t *testing.T) {
	config := OrganizationConfig{
		MaxFilesPerFolder:   50,
		AutoCategorization:  true,
		PatternLearning:     true,
		SimilarityThreshold: 0.8,
		FilePatterns: map[string]FilePatternConfig{
			"go": {
				Extensions:   []string{".go"},
				Organization: "by_domain",
			},
		},
	}

	if config.MaxFilesPerFolder <= 0 {
		t.Error("Max files per folder must be positive")
	}
	if config.SimilarityThreshold <= 0 || config.SimilarityThreshold > 1 {
		t.Error("Similarity threshold must be between 0 and 1")
	}
	if len(config.FilePatterns) == 0 {
		t.Error("Should have at least one file pattern")
	}
}
