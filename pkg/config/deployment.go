package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

// DeploymentConfig represents the complete deployment configuration
type DeploymentConfig struct {
	Environment string           `yaml:"environment" json:"environment"`
	Server      ServerConfig     `yaml:"server" json:"server"`
	Redis       RedisConfig      `yaml:"redis" json:"redis"`
	Email       EmailConfig      `yaml:"email" json:"email"`
	Monitoring  MonitoringConfig `yaml:"monitoring" json:"monitoring"`
	Security    SecurityConfig   `yaml:"security" json:"security"`
	Logging     LoggingConfig    `yaml:"logging" json:"logging"`
	Cache       CacheConfig      `yaml:"cache" json:"cache"`
	Metadata    MetadataConfig   `yaml:"metadata" json:"metadata"`
}

// ServerConfig contains HTTP server configuration
type ServerConfig struct {
	Host         string        `yaml:"host" json:"host"`
	Port         int           `yaml:"port" json:"port"`
	ReadTimeout  time.Duration `yaml:"read_timeout" json:"read_timeout"`
	WriteTimeout time.Duration `yaml:"write_timeout" json:"write_timeout"`
	IdleTimeout  time.Duration `yaml:"idle_timeout" json:"idle_timeout"`
	MaxBodySize  int64         `yaml:"max_body_size" json:"max_body_size"`
	TLS          TLSConfig     `yaml:"tls" json:"tls"`
}

// TLSConfig for HTTPS configuration
type TLSConfig struct {
	Enabled  bool   `yaml:"enabled" json:"enabled"`
	CertFile string `yaml:"cert_file" json:"cert_file"`
	KeyFile  string `yaml:"key_file" json:"key_file"`
	MinTLS   string `yaml:"min_tls" json:"min_tls"`
}

// RedisConfig for Redis connection
type RedisConfig struct {
	Host          string        `yaml:"host" json:"host"`
	Port          int           `yaml:"port" json:"port"`
	Password      string        `yaml:"password" json:"password"`
	Database      int           `yaml:"database" json:"database"`
	PoolSize      int           `yaml:"pool_size" json:"pool_size"`
	MinIdleConns  int           `yaml:"min_idle_conns" json:"min_idle_conns"`
	DialTimeout   time.Duration `yaml:"dial_timeout" json:"dial_timeout"`
	ReadTimeout   time.Duration `yaml:"read_timeout" json:"read_timeout"`
	WriteTimeout  time.Duration `yaml:"write_timeout" json:"write_timeout"`
	PoolTimeout   time.Duration `yaml:"pool_timeout" json:"pool_timeout"`
	IdleTimeout   time.Duration `yaml:"idle_timeout" json:"idle_timeout"`
	MaxRetries    int           `yaml:"max_retries" json:"max_retries"`
	RetryDelay    time.Duration `yaml:"retry_delay" json:"retry_delay"`
	EnableCluster bool          `yaml:"enable_cluster" json:"enable_cluster"`
	ClusterNodes  []string      `yaml:"cluster_nodes" json:"cluster_nodes"`
}

// EmailConfig for email service settings
type EmailConfig struct {
	SMTP             SMTPConfig    `yaml:"smtp" json:"smtp"`
	DefaultFrom      string        `yaml:"default_from" json:"default_from"`
	DefaultFromName  string        `yaml:"default_from_name" json:"default_from_name"`
	MaxRetries       int           `yaml:"max_retries" json:"max_retries"`
	RetryDelay       time.Duration `yaml:"retry_delay" json:"retry_delay"`
	RateLimitPerHour int           `yaml:"rate_limit_per_hour" json:"rate_limit_per_hour"`
	EnableTracking   bool          `yaml:"enable_tracking" json:"enable_tracking"`
	EnableTemplating bool          `yaml:"enable_templating" json:"enable_templating"`
}

// SMTPConfig for SMTP server settings
type SMTPConfig struct {
	Host     string `yaml:"host" json:"host"`
	Port     int    `yaml:"port" json:"port"`
	Username string `yaml:"username" json:"username"`
	Password string `yaml:"password" json:"password"`
	UseTLS   bool   `yaml:"use_tls" json:"use_tls"`
	UseSSL   bool   `yaml:"use_ssl" json:"use_ssl"`
}

// MonitoringConfig for monitoring and metrics
type MonitoringConfig struct {
	Enabled            bool          `yaml:"enabled" json:"enabled"`
	MetricsPath        string        `yaml:"metrics_path" json:"metrics_path"`
	MetricsPort        int           `yaml:"metrics_port" json:"metrics_port"`
	HealthCheckPath    string        `yaml:"health_check_path" json:"health_check_path"`
	CollectionInterval time.Duration `yaml:"collection_interval" json:"collection_interval"`
	AlertsEnabled      bool          `yaml:"alerts_enabled" json:"alerts_enabled"`
	AlertsWebhook      string        `yaml:"alerts_webhook" json:"alerts_webhook"`
	AlertsEmail        []string      `yaml:"alerts_email" json:"alerts_email"`
	Thresholds         Thresholds    `yaml:"thresholds" json:"thresholds"`
}

// Thresholds for monitoring alerts
type Thresholds struct {
	CPUUsage     float64       `yaml:"cpu_usage" json:"cpu_usage"`
	MemoryUsage  float64       `yaml:"memory_usage" json:"memory_usage"`
	DiskUsage    float64       `yaml:"disk_usage" json:"disk_usage"`
	ResponseTime time.Duration `yaml:"response_time" json:"response_time"`
	ErrorRate    float64       `yaml:"error_rate" json:"error_rate"`
	CacheHitRate float64       `yaml:"cache_hit_rate" json:"cache_hit_rate"`
}

// SecurityConfig for security settings
type SecurityConfig struct {
	EnableCORS      bool          `yaml:"enable_cors" json:"enable_cors"`
	AllowedOrigins  []string      `yaml:"allowed_origins" json:"allowed_origins"`
	EnableRateLimit bool          `yaml:"enable_rate_limit" json:"enable_rate_limit"`
	RateLimitRPS    int           `yaml:"rate_limit_rps" json:"rate_limit_rps"`
	EnableAuth      bool          `yaml:"enable_auth" json:"enable_auth"`
	JWTSecret       string        `yaml:"jwt_secret" json:"jwt_secret"`
	JWTExpiry       time.Duration `yaml:"jwt_expiry" json:"jwt_expiry"`
	APIKeys         []string      `yaml:"api_keys" json:"api_keys"`
}

// LoggingConfig for logging settings
type LoggingConfig struct {
	Level      string `yaml:"level" json:"level"`
	Format     string `yaml:"format" json:"format"`
	Output     string `yaml:"output" json:"output"`
	File       string `yaml:"file" json:"file"`
	MaxSize    int    `yaml:"max_size" json:"max_size"`
	MaxBackups int    `yaml:"max_backups" json:"max_backups"`
	MaxAge     int    `yaml:"max_age" json:"max_age"`
	Compress   bool   `yaml:"compress" json:"compress"`
}

// CacheConfig for caching settings
type CacheConfig struct {
	DefaultTTL     time.Duration            `yaml:"default_ttl" json:"default_ttl"`
	TypeTTLs       map[string]time.Duration `yaml:"type_ttls" json:"type_ttls"`
	MaxMemory      string                   `yaml:"max_memory" json:"max_memory"`
	EvictionPolicy string                   `yaml:"eviction_policy" json:"eviction_policy"`
	EnableMetrics  bool                     `yaml:"enable_metrics" json:"enable_metrics"`
}

// MetadataConfig for deployment metadata
type MetadataConfig struct {
	Version     string    `yaml:"version" json:"version"`
	BuildDate   time.Time `yaml:"build_date" json:"build_date"`
	GitCommit   string    `yaml:"git_commit" json:"git_commit"`
	DeployedBy  string    `yaml:"deployed_by" json:"deployed_by"`
	DeployedAt  time.Time `yaml:"deployed_at" json:"deployed_at"`
	Environment string    `yaml:"environment" json:"environment"`
}

// ConfigManager handles configuration loading and validation
type ConfigManager struct {
	config *DeploymentConfig
	path   string
}

// NewConfigManager creates a new configuration manager
func NewConfigManager(configPath string) *ConfigManager {
	return &ConfigManager{
		path: configPath,
	}
}

// LoadConfig loads configuration from file with environment variable override
func (cm *ConfigManager) LoadConfig() (*DeploymentConfig, error) {
	// Load base configuration
	config, err := cm.loadFromFile()
	if err != nil {
		return nil, fmt.Errorf("failed to load config file: %w", err)
	}

	// Override with environment variables
	cm.overrideWithEnvVars(config)

	// Validate configuration
	if err := cm.validateConfig(config); err != nil {
		return nil, fmt.Errorf("configuration validation failed: %w", err)
	}

	cm.config = config
	return config, nil
}

// loadFromFile loads configuration from YAML or JSON file
func (cm *ConfigManager) loadFromFile() (*DeploymentConfig, error) {
	if cm.path == "" {
		return cm.getDefaultConfig(), nil
	}

	data, err := os.ReadFile(cm.path)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	config := &DeploymentConfig{}
	ext := strings.ToLower(filepath.Ext(cm.path))

	switch ext {
	case ".yaml", ".yml":
		if err := yaml.Unmarshal(data, config); err != nil {
			return nil, fmt.Errorf("failed to parse YAML config: %w", err)
		}
	case ".json":
		if err := json.Unmarshal(data, config); err != nil {
			return nil, fmt.Errorf("failed to parse JSON config: %w", err)
		}
	default:
		return nil, fmt.Errorf("unsupported config file format: %s", ext)
	}

	return config, nil
}

// overrideWithEnvVars overrides configuration with environment variables
func (cm *ConfigManager) overrideWithEnvVars(config *DeploymentConfig) {
	// Server overrides
	if host := os.Getenv("EMAIL_SENDER_HOST"); host != "" {
		config.Server.Host = host
	}
	if port := os.Getenv("EMAIL_SENDER_PORT"); port != "" {
		if p, err := parseIntEnv("EMAIL_SENDER_PORT"); err == nil {
			config.Server.Port = p
		}
	}

	// Redis overrides
	if host := os.Getenv("REDIS_HOST"); host != "" {
		config.Redis.Host = host
	}
	if port := os.Getenv("REDIS_PORT"); port != "" {
		if p, err := parseIntEnv("REDIS_PORT"); err == nil {
			config.Redis.Port = p
		}
	}
	if password := os.Getenv("REDIS_PASSWORD"); password != "" {
		config.Redis.Password = password
	}
	if db := os.Getenv("REDIS_DB"); db != "" {
		if d, err := parseIntEnv("REDIS_DB"); err == nil {
			config.Redis.Database = d
		}
	}

	// Email/SMTP overrides
	if host := os.Getenv("SMTP_HOST"); host != "" {
		config.Email.SMTP.Host = host
	}
	if port := os.Getenv("SMTP_PORT"); port != "" {
		if p, err := parseIntEnv("SMTP_PORT"); err == nil {
			config.Email.SMTP.Port = p
		}
	}
	if username := os.Getenv("SMTP_USERNAME"); username != "" {
		config.Email.SMTP.Username = username
	}
	if password := os.Getenv("SMTP_PASSWORD"); password != "" {
		config.Email.SMTP.Password = password
	}

	// Environment override
	if env := os.Getenv("ENVIRONMENT"); env != "" {
		config.Environment = env
	}
}

// validateConfig validates the configuration
func (cm *ConfigManager) validateConfig(config *DeploymentConfig) error {
	// Validate server configuration
	if config.Server.Port <= 0 || config.Server.Port > 65535 {
		return fmt.Errorf("invalid server port: %d", config.Server.Port)
	}

	// Validate Redis configuration
	if config.Redis.Host == "" {
		return fmt.Errorf("redis host is required")
	}
	if config.Redis.Port <= 0 || config.Redis.Port > 65535 {
		return fmt.Errorf("invalid redis port: %d", config.Redis.Port)
	}

	// Validate SMTP configuration if email is enabled
	if config.Email.SMTP.Host != "" {
		if config.Email.SMTP.Port <= 0 || config.Email.SMTP.Port > 65535 {
			return fmt.Errorf("invalid SMTP port: %d", config.Email.SMTP.Port)
		}
	}

	// Validate environment
	validEnvs := []string{"development", "staging", "production"}
	isValidEnv := false
	for _, env := range validEnvs {
		if config.Environment == env {
			isValidEnv = true
			break
		}
	}
	if !isValidEnv {
		return fmt.Errorf("invalid environment: %s (must be one of: %v)", config.Environment, validEnvs)
	}

	return nil
}

// getDefaultConfig returns default configuration
func (cm *ConfigManager) getDefaultConfig() *DeploymentConfig {
	return &DeploymentConfig{
		Environment: "development",
		Server: ServerConfig{
			Host:         "0.0.0.0",
			Port:         8080,
			ReadTimeout:  15 * time.Second,
			WriteTimeout: 15 * time.Second,
			IdleTimeout:  60 * time.Second,
			MaxBodySize:  10 * 1024 * 1024, // 10MB
		},
		Redis: RedisConfig{
			Host:         "localhost",
			Port:         6379,
			Database:     0,
			PoolSize:     10,
			MinIdleConns: 5,
			DialTimeout:  5 * time.Second,
			ReadTimeout:  3 * time.Second,
			WriteTimeout: 3 * time.Second,
			PoolTimeout:  4 * time.Second,
			IdleTimeout:  5 * time.Minute,
			MaxRetries:   3,
			RetryDelay:   time.Second,
		},
		Email: EmailConfig{
			SMTP: SMTPConfig{
				Host: "localhost",
				Port: 587,
			},
			MaxRetries:       3,
			RetryDelay:       time.Second,
			RateLimitPerHour: 1000,
			EnableTracking:   true,
			EnableTemplating: true,
		},
		Monitoring: MonitoringConfig{
			Enabled:            true,
			MetricsPath:        "/metrics",
			MetricsPort:        9090,
			HealthCheckPath:    "/health",
			CollectionInterval: 30 * time.Second,
			AlertsEnabled:      false,
			Thresholds: Thresholds{
				CPUUsage:     80.0,
				MemoryUsage:  85.0,
				DiskUsage:    90.0,
				ResponseTime: 500 * time.Millisecond,
				ErrorRate:    5.0,
				CacheHitRate: 70.0,
			},
		},
		Security: SecurityConfig{
			EnableCORS:      true,
			AllowedOrigins:  []string{"*"},
			EnableRateLimit: true,
			RateLimitRPS:    100,
			EnableAuth:      false,
			JWTExpiry:       24 * time.Hour,
		},
		Logging: LoggingConfig{
			Level:      "info",
			Format:     "json",
			Output:     "stdout",
			MaxSize:    100, // MB
			MaxBackups: 3,
			MaxAge:     7, // days
			Compress:   true,
		},
		Cache: CacheConfig{
			DefaultTTL: time.Hour,
			TypeTTLs: map[string]time.Duration{
				"default_values": time.Hour,
				"statistics":     24 * time.Hour,
				"ml_models":      time.Hour,
				"configuration":  30 * time.Minute,
				"user_sessions":  2 * time.Hour,
			},
			MaxMemory:      "256mb",
			EvictionPolicy: "allkeys-lru",
			EnableMetrics:  true,
		},
	}
}

// GetConfig returns the loaded configuration
func (cm *ConfigManager) GetConfig() *DeploymentConfig {
	return cm.config
}

// SaveConfig saves configuration to file
func (cm *ConfigManager) SaveConfig(config *DeploymentConfig, outputPath string) error {
	ext := strings.ToLower(filepath.Ext(outputPath))

	var data []byte
	var err error

	switch ext {
	case ".yaml", ".yml":
		data, err = yaml.Marshal(config)
	case ".json":
		data, err = json.MarshalIndent(config, "", "  ")
	default:
		return fmt.Errorf("unsupported output format: %s", ext)
	}

	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	return os.WriteFile(outputPath, data, 0644)
}

// Helper functions
func parseIntEnv(envVar string) (int, error) {
	value := os.Getenv(envVar)
	if value == "" {
		return 0, fmt.Errorf("environment variable %s is empty", envVar)
	}

	var result int
	_, err := fmt.Sscanf(value, "%d", &result)
	return result, err
}
