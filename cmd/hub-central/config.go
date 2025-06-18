package main

import (
	"os"
	"time"

	"gopkg.in/yaml.v3"
)

// Configuration structs for each manager
type EmailConfig struct {
	SMTPHost        string        `yaml:"smtp_host"`
	SMTPPort        int           `yaml:"smtp_port"`
	Username        string        `yaml:"username"`
	Password        string        `yaml:"password"`
	MaxConcurrency  int           `yaml:"max_concurrency"`
	QueueSize       int           `yaml:"queue_size"`
	RetryAttempts   int           `yaml:"retry_attempts"`
	RetryDelay      time.Duration `yaml:"retry_delay"`
	TemplateDir     string        `yaml:"template_dir"`
	EnableAnalytics bool          `yaml:"enable_analytics"`
}

type DatabaseConfig struct {
	Driver          string          `yaml:"driver"`
	ConnectionURL   string          `yaml:"connection_url"`
	MaxConnections  int             `yaml:"max_connections"`
	MaxIdleConns    int             `yaml:"max_idle_conns"`
	ConnMaxLifetime time.Duration   `yaml:"conn_max_lifetime"`
	MigrationsDir   string          `yaml:"migrations_dir"`
	BackupConfig    *BackupConfig   `yaml:"backup"`
	ReadReplicas    []string        `yaml:"read_replicas"`
	Sharding        *ShardingConfig `yaml:"sharding"`
}

type BackupConfig struct {
	Enabled       bool   `yaml:"enabled"`
	Schedule      string `yaml:"schedule"`
	RetentionDays int    `yaml:"retention_days"`
	S3Bucket      string `yaml:"s3_bucket"`
	S3Region      string `yaml:"s3_region"`
}

type ShardingConfig struct {
	Enabled    bool     `yaml:"enabled"`
	ShardCount int      `yaml:"shard_count"`
	ShardKey   string   `yaml:"shard_key"`
	Nodes      []string `yaml:"nodes"`
}

type CacheConfig struct {
	Type         string        `yaml:"type"` // redis, memory, hybrid
	RedisURL     string        `yaml:"redis_url"`
	Password     string        `yaml:"password"`
	DB           int           `yaml:"db"`
	PoolSize     int           `yaml:"pool_size"`
	MemorySize   int64         `yaml:"memory_size"`
	TTL          time.Duration `yaml:"ttl"`
	ClusterNodes []string      `yaml:"cluster_nodes"`
	Strategy     string        `yaml:"strategy"` // write-through, write-back, write-around
}

type VectorConfig struct {
	QdrantURL      string        `yaml:"qdrant_url"`
	Collection     string        `yaml:"collection"`
	VectorSize     int           `yaml:"vector_size"`
	Distance       string        `yaml:"distance"`
	BatchSize      int           `yaml:"batch_size"`
	SearchLimit    int           `yaml:"search_limit"`
	Threshold      float64       `yaml:"threshold"`
	EmbeddingModel string        `yaml:"embedding_model"`
	APIKey         string        `yaml:"api_key"`
	Timeout        time.Duration `yaml:"timeout"`
}

type ProcessConfig struct {
	MaxProcesses   int             `yaml:"max_processes"`
	WorkerPoolSize int             `yaml:"worker_pool_size"`
	TaskTimeout    time.Duration   `yaml:"task_timeout"`
	QueueSize      int             `yaml:"queue_size"`
	Priority       string          `yaml:"priority"`
	ResourceLimits *ResourceLimits `yaml:"resource_limits"`
}

type ResourceLimits struct {
	CPULimit    string `yaml:"cpu_limit"`
	MemoryLimit string `yaml:"memory_limit"`
	DiskLimit   string `yaml:"disk_limit"`
}

type ContainerConfig struct {
	Runtime     string            `yaml:"runtime"` // docker, podman, containerd
	Registry    string            `yaml:"registry"`
	Namespace   string            `yaml:"namespace"`
	PullPolicy  string            `yaml:"pull_policy"`
	Networks    []string          `yaml:"networks"`
	Volumes     []VolumeConfig    `yaml:"volumes"`
	Environment map[string]string `yaml:"environment"`
	Resources   *ResourceLimits   `yaml:"resources"`
}

type VolumeConfig struct {
	Name     string `yaml:"name"`
	Type     string `yaml:"type"`
	Source   string `yaml:"source"`
	Target   string `yaml:"target"`
	ReadOnly bool   `yaml:"read_only"`
}

type DependencyConfig struct {
	RepositoryURL   string   `yaml:"repository_url"`
	UpdateSchedule  string   `yaml:"update_schedule"`
	AutoUpdate      bool     `yaml:"auto_update"`
	PackageManagers []string `yaml:"package_managers"`
	SecurityScan    bool     `yaml:"security_scan"`
	PrivateRepos    []string `yaml:"private_repos"`
}

type MCPConfig struct {
	ServerPort     int                `yaml:"server_port"`
	ClientTimeout  time.Duration      `yaml:"client_timeout"`
	MaxConnections int                `yaml:"max_connections"`
	Middleware     []string           `yaml:"middleware"`
	Tools          map[string]string  `yaml:"tools"`
	Security       *MCPSecurityConfig `yaml:"security"`
}

type MCPSecurityConfig struct {
	EnableAuth bool     `yaml:"enable_auth"`
	APIKeys    []string `yaml:"api_keys"`
	TLSCert    string   `yaml:"tls_cert"`
	TLSKey     string   `yaml:"tls_key"`
}

type ConfigMgrConfig struct {
	ConfigDir      string        `yaml:"config_dir"`
	WatchInterval  time.Duration `yaml:"watch_interval"`
	BackupEnabled  bool          `yaml:"backup_enabled"`
	VersionControl bool          `yaml:"version_control"`
	EncryptSecrets bool          `yaml:"encrypt_secrets"`
	ValidationMode string        `yaml:"validation_mode"`
}

type WatchConfig struct {
	WatchPaths     []string      `yaml:"watch_paths"`
	IgnorePatterns []string      `yaml:"ignore_patterns"`
	PollInterval   time.Duration `yaml:"poll_interval"`
	BufferSize     int           `yaml:"buffer_size"`
	Actions        []WatchAction `yaml:"actions"`
}

type WatchAction struct {
	Type    string            `yaml:"type"`
	Command string            `yaml:"command"`
	Args    []string          `yaml:"args"`
	Env     map[string]string `yaml:"env"`
}

// LoadHubConfig loads the hub configuration from file
func LoadHubConfig() (*HubConfig, error) {
	configPath := os.Getenv("HUB_CONFIG_PATH")
	if configPath == "" {
		configPath = "config/hub.yaml"
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		// Return default configuration if file doesn't exist
		return getDefaultConfig(), nil
	}

	var config HubConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	// Merge with defaults for missing values
	mergeWithDefaults(&config)

	return &config, nil
}

// getDefaultConfig returns a default configuration
func getDefaultConfig() *HubConfig {
	return &HubConfig{
		Email: &EmailConfig{
			SMTPHost:        "localhost",
			SMTPPort:        587,
			MaxConcurrency:  10,
			QueueSize:       1000,
			RetryAttempts:   3,
			RetryDelay:      time.Second * 5,
			TemplateDir:     "templates",
			EnableAnalytics: true,
		},
		Database: &DatabaseConfig{
			Driver:          "sqlite",
			ConnectionURL:   "data/hub.db",
			MaxConnections:  25,
			MaxIdleConns:    5,
			ConnMaxLifetime: time.Hour,
			MigrationsDir:   "migrations",
		},
		Cache: &CacheConfig{
			Type:       "memory",
			MemorySize: 1024 * 1024 * 100, // 100MB
			TTL:        time.Hour,
			Strategy:   "write-through",
		},
		Vector: &VectorConfig{
			QdrantURL:      "http://localhost:6333",
			Collection:     "hub_vectors",
			VectorSize:     1536,
			Distance:       "cosine",
			BatchSize:      100,
			SearchLimit:    10,
			Threshold:      0.7,
			EmbeddingModel: "text-embedding-ada-002",
			Timeout:        time.Second * 30,
		},
		Process: &ProcessConfig{
			MaxProcesses:   50,
			WorkerPoolSize: 10,
			TaskTimeout:    time.Minute * 5,
			QueueSize:      500,
			Priority:       "normal",
		},
		Container: &ContainerConfig{
			Runtime:    "docker",
			Registry:   "docker.io",
			Namespace:  "hub",
			PullPolicy: "IfNotPresent",
		},
		Dependency: &DependencyConfig{
			RepositoryURL:   "https://github.com/company/dependencies",
			UpdateSchedule:  "0 2 * * *", // Daily at 2 AM
			AutoUpdate:      false,
			PackageManagers: []string{"npm", "pip", "go"},
			SecurityScan:    true,
		},
		MCP: &MCPConfig{
			ServerPort:     8080,
			ClientTimeout:  time.Second * 30,
			MaxConnections: 100,
			Middleware:     []string{"logging", "metrics"},
		},
		ConfigMgr: &ConfigMgrConfig{
			ConfigDir:      "config",
			WatchInterval:  time.Second * 5,
			BackupEnabled:  true,
			VersionControl: true,
			EncryptSecrets: true,
			ValidationMode: "strict",
		},
		Watch: &WatchConfig{
			WatchPaths:     []string{"./config", "./templates"},
			IgnorePatterns: []string{"*.tmp", "*.swp", ".git"},
			PollInterval:   time.Second,
			BufferSize:     1000,
		},
		Hub: &HubSettings{
			Port:            8090,
			HealthCheckPort: 8091,
			ShutdownTimeout: time.Second * 30,
			StartupTimeout:  time.Minute * 2,
			LogLevel:        "info",
		},
	}
}

// mergeWithDefaults fills in missing configuration values with defaults
func mergeWithDefaults(config *HubConfig) {
	defaults := getDefaultConfig()

	if config.Hub == nil {
		config.Hub = defaults.Hub
	}
	if config.Email == nil {
		config.Email = defaults.Email
	}
	if config.Database == nil {
		config.Database = defaults.Database
	}
	if config.Cache == nil {
		config.Cache = defaults.Cache
	}
	if config.Vector == nil {
		config.Vector = defaults.Vector
	}
	if config.Process == nil {
		config.Process = defaults.Process
	}
	if config.Container == nil {
		config.Container = defaults.Container
	}
	if config.Dependency == nil {
		config.Dependency = defaults.Dependency
	}
	if config.MCP == nil {
		config.MCP = defaults.MCP
	}
	if config.ConfigMgr == nil {
		config.ConfigMgr = defaults.ConfigMgr
	}
	if config.Watch == nil {
		config.Watch = defaults.Watch
	}
}
