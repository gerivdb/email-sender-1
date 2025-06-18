package config

import (
	"time"
)

// Config structure de configuration principale
type Config struct {
	Performance PerformanceConfig `json:"performance"`
	Diagnostic  DiagnosticConfig  `json:"diagnostic"`
	Monitoring  MonitoringConfig  `json:"monitoring"`
	API         APIConfig         `json:"api"`
}

// PerformanceConfig paramètres de performance
type PerformanceConfig struct {
	MaxConcurrency   int           `json:"max_concurrency"`    // 4
	RequestTimeout   time.Duration `json:"request_timeout"`    // 2s
	DiagnosticTarget time.Duration `json:"diagnostic_target"`  // 200ms
	QuickCheckTarget time.Duration `json:"quick_check_target"` // 50ms
	HealthTarget     time.Duration `json:"health_target"`      // 10ms
}

// DiagnosticConfig configuration du diagnostic
type DiagnosticConfig struct {
	EnableAPICheck      bool `json:"enable_api_check"`      // true
	EnableSystemCheck   bool `json:"enable_system_check"`   // true
	EnableProcessCheck  bool `json:"enable_process_check"`  // true
	EnableDockerCheck   bool `json:"enable_docker_check"`   // true
	EnableResourceCheck bool `json:"enable_resource_check"` // true
}

// MonitoringConfig configuration du monitoring
type MonitoringConfig struct {
	UpdateInterval time.Duration `json:"update_interval"` // 5s
	MetricsBuffer  int           `json:"metrics_buffer"`  // 100
	EnableMetrics  bool          `json:"enable_metrics"`  // true
}

// APIConfig configuration API
type APIConfig struct {
	BaseURL     string        `json:"base_url"`     // http://localhost:8080
	HealthPath  string        `json:"health_path"`  // /health
	StatusPath  string        `json:"status_path"`  // /status
	Timeout     time.Duration `json:"timeout"`      // 2s
	EnableHTTPS bool          `json:"enable_https"` // false
}

// LoadConfig charge la configuration par défaut
func LoadConfig() *Config {
	return &Config{
		Performance: PerformanceConfig{
			MaxConcurrency:   4,
			RequestTimeout:   2 * time.Second,
			DiagnosticTarget: 200 * time.Millisecond,
			QuickCheckTarget: 50 * time.Millisecond,
			HealthTarget:     10 * time.Millisecond,
		},
		Diagnostic: DiagnosticConfig{
			EnableAPICheck:      true,
			EnableSystemCheck:   true,
			EnableProcessCheck:  true,
			EnableDockerCheck:   true,
			EnableResourceCheck: true,
		},
		Monitoring: MonitoringConfig{
			UpdateInterval: 5 * time.Second,
			MetricsBuffer:  100,
			EnableMetrics:  true,
		},
		API: APIConfig{
			BaseURL:     "http://localhost:8080",
			HealthPath:  "/health",
			StatusPath:  "/status",
			Timeout:     2 * time.Second,
			EnableHTTPS: false,
		},
	}
}
