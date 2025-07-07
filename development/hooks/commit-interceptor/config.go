// development/hooks/commit-interceptor/config.go
package commitinterceptor

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// Config represents the configuration for the commit interceptor
type Config struct {
	Server			ServerConfig	`json:"server"`
	Git			GitConfig	`json:"git"`
	Routing			RoutingConfig	`json:"routing"`
	NotificationsEnabled	bool		`json:"notifications_enabled"`
	Webhooks		WebhookConfig	`json:"webhooks"`
	Logging			LoggingConfig	`json:"logging"`
	TestMode		bool		`json:"test_mode"`	// Nouvelle option pour mode test
}

// ServerConfig contains server-specific configuration
type ServerConfig struct {
	Port		int	`json:"port"`
	Host		string	`json:"host"`
	ReadTimeout	int	`json:"read_timeout"`
	WriteTimeout	int	`json:"write_timeout"`
	ShutdownTimeout	int	`json:"shutdown_timeout"`
}

// GitConfig contains Git-specific configuration
type GitConfig struct {
	DefaultBranch		string		`json:"default_branch"`
	ProtectedBranches	[]string	`json:"protected_branches"`
	RemoteName		string		`json:"remote_name"`
	AutoFetch		bool		`json:"auto_fetch"`
}

// RoutingConfig contains routing rules configuration
type RoutingConfig struct {
	Rules			map[string]RoutingRule	`json:"rules"`
	DefaultStrategy		string			`json:"default_strategy"`
	ConflictStrategy	string			`json:"conflict_strategy"`
	AutoMergeEnabled	bool			`json:"auto_merge_enabled"`
	CriticalFilePatterns	[]string		`json:"critical_file_patterns,omitempty"`
}

// RoutingRule defines how specific types of commits should be routed
type RoutingRule struct {
	Patterns	[]string	`json:"patterns"`
	TargetBranch	string		`json:"target_branch"`
	CreateBranch	bool		`json:"create_branch"`
	MergeStrategy	string		`json:"merge_strategy"`
	Priority	string		`json:"priority"`
}

// WebhookConfig contains webhook configuration
type WebhookConfig struct {
	Enabled		bool			`json:"enabled"`
	Endpoints	map[string]string	`json:"endpoints"`
	AuthTokens	map[string]string	`json:"auth_tokens"`
	Timeout		int			`json:"timeout"`
}

// LoggingConfig contains logging configuration
type LoggingConfig struct {
	Level		string	`json:"level"`
	Format		string	`json:"format"`
	OutputFile	string	`json:"output_file"`
}

// LoadConfig loads configuration from file or environment
func LoadConfig() *Config {
	config := getDefaultConfig()

	// Try to load from config file
	configFile := getConfigFilePath()
	if _, err := os.Stat(configFile); err == nil {
		if err := loadConfigFromFile(config, configFile); err != nil {
			fmt.Printf("Warning: Failed to load config from file: %v\n", err)
		}
	}

	// Override with environment variables
	loadConfigFromEnv(config)

	return config
}

// getDefaultConfig returns default configuration values
func getDefaultConfig() *Config {
	return &Config{
		Server: ServerConfig{
			Port:			8080,
			Host:			"0.0.0.0",
			ReadTimeout:		15,
			WriteTimeout:		15,
			ShutdownTimeout:	30,
		},
		Git: GitConfig{
			DefaultBranch:		"main",
			ProtectedBranches:	[]string{"main", "master", "production"},
			RemoteName:		"origin",
			AutoFetch:		true,
		},
		Routing: RoutingConfig{
			Rules: map[string]RoutingRule{
				"feature": {
					Patterns:	[]string{"feat:", "feature:", "add:"},
					TargetBranch:	"feature/*",
					CreateBranch:	true,
					MergeStrategy:	"manual",
					Priority:	"medium",
				},
				"fix": {
					Patterns:	[]string{"fix:", "bug:", "hotfix:"},
					TargetBranch:	"hotfix/*",
					CreateBranch:	true,
					MergeStrategy:	"manual",
					Priority:	"high",
				},
				"refactor": {
					Patterns:	[]string{"refactor:", "clean:", "optimize:"},
					TargetBranch:	"develop",
					CreateBranch:	false,
					MergeStrategy:	"auto",
					Priority:	"medium",
				},
				"docs": {
					Patterns:	[]string{"docs:", "doc:", "documentation:"},
					TargetBranch:	"develop",
					CreateBranch:	false,
					MergeStrategy:	"auto",
					Priority:	"low",
				},
			},
			DefaultStrategy:	"manual",
			ConflictStrategy:	"abort",
			AutoMergeEnabled:	false,
		},
		NotificationsEnabled:	false,
		Webhooks: WebhookConfig{
			Enabled:	false,
			Endpoints:	make(map[string]string),
			AuthTokens:	make(map[string]string),
			Timeout:	30,
		},
		Logging: LoggingConfig{
			Level:		"info",
			Format:		"json",
			OutputFile:	"",
		},
		TestMode:	false,	// Mode test désactivé par défaut
	}
}

// getConfigFilePath returns the path to the configuration file
func getConfigFilePath() string {
	// Check for config file in current directory first
	configPaths := []string{
		"config/branching-auto.json",
		"branching-auto.json",
		"/etc/branching-auto/config.json",
	}

	for _, path := range configPaths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}

	// Default to current directory
	return "branching-auto.json"
}

// loadConfigFromFile loads configuration from a JSON file
func loadConfigFromFile(config *Config, filename string) error {
	file, err := os.Open(filename)
	if err != nil {
		return fmt.Errorf("failed to open config file: %w", err)
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	if err := decoder.Decode(config); err != nil {
		return fmt.Errorf("failed to decode config JSON: %w", err)
	}

	return nil
}

// loadConfigFromEnv loads configuration from environment variables
func loadConfigFromEnv(config *Config) {
	// Server configuration
	if port := os.Getenv("COMMIT_INTERCEPTOR_PORT"); port != "" {
		// Convert string to int if needed
		config.Server.Port = 8080	// Default fallback
	}

	if host := os.Getenv("COMMIT_INTERCEPTOR_HOST"); host != "" {
		config.Server.Host = host
	}

	// Git configuration
	if defaultBranch := os.Getenv("GIT_DEFAULT_BRANCH"); defaultBranch != "" {
		config.Git.DefaultBranch = defaultBranch
	}

	if remoteName := os.Getenv("GIT_REMOTE_NAME"); remoteName != "" {
		config.Git.RemoteName = remoteName
	}

	// Webhook configuration
	if webhookUrl := os.Getenv("WEBHOOK_URL"); webhookUrl != "" {
		config.Webhooks.Enabled = true
		config.Webhooks.Endpoints["default"] = webhookUrl
	}

	if authToken := os.Getenv("WEBHOOK_AUTH_TOKEN"); authToken != "" {
		config.Webhooks.AuthTokens["default"] = authToken
	}

	// Logging configuration
	if logLevel := os.Getenv("LOG_LEVEL"); logLevel != "" {
		config.Logging.Level = logLevel
	}

	if logFile := os.Getenv("LOG_FILE"); logFile != "" {
		config.Logging.OutputFile = logFile
	}

	// Mode test
	if testMode := os.Getenv("TEST_MODE"); testMode == "true" {
		config.TestMode = true
	}
}

// SaveConfig saves the current configuration to file
func (c *Config) SaveConfig(filename string) error {
	// Create directory if it doesn't exist
	dir := filepath.Dir(filename)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("failed to create config file: %w", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(c); err != nil {
		return fmt.Errorf("failed to encode config JSON: %w", err)
	}

	return nil
}

// ValidateConfig validates the configuration
func (c *Config) ValidateConfig() error {
	if c.Server.Port <= 0 || c.Server.Port > 65535 {
		return fmt.Errorf("invalid server port: %d", c.Server.Port)
	}

	if c.Git.DefaultBranch == "" {
		return fmt.Errorf("default branch cannot be empty")
	}

	if c.Git.RemoteName == "" {
		return fmt.Errorf("remote name cannot be empty")
	}

	validLogLevels := map[string]bool{
		"debug":	true, "info": true, "warn": true, "error": true,
	}
	if !validLogLevels[c.Logging.Level] {
		return fmt.Errorf("invalid log level: %s", c.Logging.Level)
	}

	return nil
}

// GetRoutingRule returns the routing rule for a given change type
func (c *Config) GetRoutingRule(changeType string) (RoutingRule, bool) {
	rule, exists := c.Routing.Rules[changeType]
	return rule, exists
}
