// Package generator - Template definitions for the GoGenEngine
package generator

// goServiceTemplate is the template for generating Go services
const goServiceTemplate = `// Package {{.Package}} - Auto-generated service
// Generated at: {{.Timestamp}}
// Author: {{.Author}}
package {{.Package}}

import (
{{range .Imports}}	"{{.}}"
{{end}}
	"go.uber.org/zap"
)

// {{.Name}} provides {{.Description}}
type {{.Name}} struct {
	logger *zap.Logger
	config *{{.Name}}Config
	ctx    context.Context
}

// {{.Name}}Config holds configuration for {{.Name}}
type {{.Name}}Config struct {
	Name     string ` + "`json:\"name\"`" + `
	Version  string ` + "`json:\"version\"`" + `
	Enabled  bool   ` + "`json:\"enabled\"`" + `
	Settings map[string]interface{} ` + "`json:\"settings\"`" + `
}

// New{{.Name}} creates a new {{.Name}} instance
func New{{.Name}}(logger *zap.Logger, config *{{.Name}}Config) (*{{.Name}}, error) {
	if logger == nil {
		return nil, fmt.Errorf("logger is required")
	}
	if config == nil {
		return nil, fmt.Errorf("config is required")
	}

	service := &{{.Name}}{
		logger: logger,
		config: config,
		ctx:    context.Background(),
	}

	logger.Info("{{.Name}} service initialized", 
		zap.String("name", config.Name),
		zap.String("version", config.Version))

	return service, nil
}

// Start starts the {{.Name}} service
func (s *{{.Name}}) Start(ctx context.Context) error {
	s.logger.Info("Starting {{.Name}} service")
	s.ctx = ctx
	
	// Add service startup logic here
	
	s.logger.Info("{{.Name}} service started successfully")
	return nil
}

// Stop stops the {{.Name}} service
func (s *{{.Name}}) Stop() error {
	s.logger.Info("Stopping {{.Name}} service")
	
	// Add service shutdown logic here
	
	s.logger.Info("{{.Name}} service stopped")
	return nil
}

// Process performs the main processing logic
func (s *{{.Name}}) Process(data interface{}) error {
	s.logger.Info("Processing data", zap.String("service", s.config.Name))
	
	// Add your processing logic here
	
	return nil
}

// GetStatus returns the current status of the service
func (s *{{.Name}}) GetStatus() (string, error) {
	if s.config.Enabled {
		return "running", nil
	}
	return "stopped", nil
}

// GetConfig returns the service configuration
func (s *{{.Name}}) GetConfig() *{{.Name}}Config {
	return s.config
}

// UpdateConfig updates the service configuration
func (s *{{.Name}}) UpdateConfig(config *{{.Name}}Config) error {
	if config == nil {
		return fmt.Errorf("config cannot be nil")
	}
	
	s.config = config
	s.logger.Info("Configuration updated", zap.String("service", config.Name))
	return nil
}
`

// goHandlerTemplate is the template for generating HTTP handlers
const goHandlerTemplate = `// Package {{.Package}} - Auto-generated HTTP handler
// Generated at: {{.Timestamp}}
// Author: {{.Author}}
package {{.Package}}

import (
{{range .Imports}}	"{{.}}"
{{end}}
	"go.uber.org/zap"
)

// {{.Name}}Handler handles HTTP requests for {{.Name}}
type {{.Name}}Handler struct {
	logger  *zap.Logger
	service *{{.Name}}Service
}

// {{.Name}}Request represents the request payload
type {{.Name}}Request struct {
	ID   string                 ` + "`json:\"id\"`" + `
	Data map[string]interface{} ` + "`json:\"data\"`" + `
}

// {{.Name}}Response represents the response payload
type {{.Name}}Response struct {
	Success bool                   ` + "`json:\"success\"`" + `
	Data    map[string]interface{} ` + "`json:\"data,omitempty\"`" + `
	Error   string                 ` + "`json:\"error,omitempty\"`" + `
}

// New{{.Name}}Handler creates a new HTTP handler
func New{{.Name}}Handler(logger *zap.Logger, service *{{.Name}}Service) *{{.Name}}Handler {
	return &{{.Name}}Handler{
		logger:  logger,
		service: service,
	}
}

// Handle{{.Name}} handles the main {{.Name}} endpoint
func (h *{{.Name}}Handler) Handle{{.Name}}(w http.ResponseWriter, r *http.Request) {
	h.logger.Info("Handling {{.Name}} request", 
		zap.String("method", r.Method),
		zap.String("path", r.URL.Path))

	// Parse request
	var req {{.Name}}Request
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.sendErrorResponse(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Process request
	result, err := h.service.Process(req.Data)
	if err != nil {
		h.logger.Error("Processing failed", zap.Error(err))
		h.sendErrorResponse(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Send response
	response := {{.Name}}Response{
		Success: true,
		Data:    result,
	}

	h.sendJSONResponse(w, response, http.StatusOK)
}

// HandleStatus handles the status endpoint
func (h *{{.Name}}Handler) HandleStatus(w http.ResponseWriter, r *http.Request) {
	status, err := h.service.GetStatus()
	if err != nil {
		h.sendErrorResponse(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"status": status,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	h.sendJSONResponse(w, response, http.StatusOK)
}

// RegisterRoutes registers all handler routes
func (h *{{.Name}}Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/{{.Package}}/{{.Name | lower}}", h.Handle{{.Name}})
	mux.HandleFunc("/{{.Package}}/{{.Name | lower}}/status", h.HandleStatus)
}

// sendJSONResponse sends a JSON response
func (h *{{.Name}}Handler) sendJSONResponse(w http.ResponseWriter, data interface{}, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	
	if err := json.NewEncoder(w).Encode(data); err != nil {
		h.logger.Error("Failed to encode response", zap.Error(err))
	}
}

// sendErrorResponse sends an error response
func (h *{{.Name}}Handler) sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	response := {{.Name}}Response{
		Success: false,
		Error:   message,
	}
	h.sendJSONResponse(w, response, statusCode)
}
`

// goInterfaceTemplate is the template for generating Go interfaces
const goInterfaceTemplate = `// Package {{.Package}} - Auto-generated interface
// Generated at: {{.Timestamp}}
// Author: {{.Author}}
package {{.Package}}

import (
{{range .Imports}}	"{{.}}"
{{end}}
)

// {{.Name}} defines the interface for {{.Description}}
type {{.Name}} interface {
	// Start starts the service
	Start(ctx context.Context) error
	
	// Stop stops the service
	Stop() error
	
	// Process processes the given data
	Process(data interface{}) (map[string]interface{}, error)
	
	// GetStatus returns the current status
	GetStatus() (string, error)
	
	// GetConfig returns the current configuration
	GetConfig() interface{}
	
	// UpdateConfig updates the configuration
	UpdateConfig(config interface{}) error
}

// {{.Name}}Service defines service-specific operations
type {{.Name}}Service interface {
	{{.Name}}
	
	// Validate validates the input data
	Validate(data interface{}) error
	
	// Transform transforms the input data
	Transform(data interface{}) (interface{}, error)
	
	// Store stores the processed data
	Store(data interface{}) error
}

// {{.Name}}Repository defines data access operations
type {{.Name}}Repository interface {
	// Create creates a new record
	Create(data interface{}) error
	
	// Read reads a record by ID
	Read(id string) (interface{}, error)
	
	// Update updates an existing record
	Update(id string, data interface{}) error
	
	// Delete deletes a record by ID
	Delete(id string) error
	
	// List lists all records with optional filters
	List(filters map[string]interface{}) ([]interface{}, error)
}

// {{.Name}}Handler defines HTTP handler operations
type {{.Name}}Handler interface {
	// Handle{{.Name}} handles the main endpoint
	Handle{{.Name}}(w http.ResponseWriter, r *http.Request)
	
	// HandleStatus handles the status endpoint
	HandleStatus(w http.ResponseWriter, r *http.Request)
	
	// RegisterRoutes registers all routes
	RegisterRoutes(mux *http.ServeMux)
}
`

// goTestTemplate is the template for generating Go test files
const goTestTemplate = `// Package {{.Package}} - Auto-generated tests
// Generated at: {{.Timestamp}}
// Author: {{.Author}}
package {{.Package}}

import (
{{range .Imports}}	"{{.}}"
{{end}}
	"go.uber.org/zap"
)

func Test{{.Name}}_New(t *testing.T) {
	logger := zap.NewNop()
	config := &{{.Name | replace "Test" ""}}Config{
		Name:    "test-{{.Name | lower}}",
		Version: "1.0.0",
		Enabled: true,
	}

	service, err := New{{.Name | replace "Test" ""}}(logger, config)
	
	assert.NoError(t, err)
	assert.NotNil(t, service)
	assert.Equal(t, config, service.GetConfig())
}

func Test{{.Name}}_Start(t *testing.T) {
	logger := zap.NewNop()
	config := &{{.Name | replace "Test" ""}}Config{
		Name:    "test-{{.Name | lower}}",
		Version: "1.0.0",
		Enabled: true,
	}

	service, err := New{{.Name | replace "Test" ""}}(logger, config)
	assert.NoError(t, err)

	ctx := context.Background()
	err = service.Start(ctx)
	assert.NoError(t, err)
}

func Test{{.Name}}_Stop(t *testing.T) {
	logger := zap.NewNop()
	config := &{{.Name | replace "Test" ""}}Config{
		Name:    "test-{{.Name | lower}}",
		Version: "1.0.0",
		Enabled: true,
	}

	service, err := New{{.Name | replace "Test" ""}}(logger, config)
	assert.NoError(t, err)

	err = service.Stop()
	assert.NoError(t, err)
}

func Test{{.Name}}_Process(t *testing.T) {
	logger := zap.NewNop()
	config := &{{.Name | replace "Test" ""}}Config{
		Name:    "test-{{.Name | lower}}",
		Version: "1.0.0",
		Enabled: true,
	}

	service, err := New{{.Name | replace "Test" ""}}(logger, config)
	assert.NoError(t, err)

	testData := map[string]interface{}{
		"test": "data",
	}

	err = service.Process(testData)
	assert.NoError(t, err)
}

func Test{{.Name}}_GetStatus(t *testing.T) {
	logger := zap.NewNop()
	config := &{{.Name | replace "Test" ""}}Config{
		Name:    "test-{{.Name | lower}}",
		Version: "1.0.0",
		Enabled: true,
	}

	service, err := New{{.Name | replace "Test" ""}}(logger, config)
	assert.NoError(t, err)

	status, err := service.GetStatus()
	assert.NoError(t, err)
	assert.Equal(t, "running", status)
}

func Test{{.Name}}_UpdateConfig(t *testing.T) {
	logger := zap.NewNop()
	config := &{{.Name | replace "Test" ""}}Config{
		Name:    "test-{{.Name | lower}}",
		Version: "1.0.0",
		Enabled: true,
	}

	service, err := New{{.Name | replace "Test" ""}}(logger, config)
	assert.NoError(t, err)

	newConfig := &{{.Name | replace "Test" ""}}Config{
		Name:    "updated-{{.Name | lower}}",
		Version: "1.1.0",
		Enabled: false,
	}

	err = service.UpdateConfig(newConfig)
	assert.NoError(t, err)
	assert.Equal(t, newConfig, service.GetConfig())
}

// Benchmark tests
func Benchmark{{.Name}}_Process(b *testing.B) {
	logger := zap.NewNop()
	config := &{{.Name | replace "Test" ""}}Config{
		Name:    "test-{{.Name | lower}}",
		Version: "1.0.0",
		Enabled: true,
	}

	service, _ := New{{.Name | replace "Test" ""}}(logger, config)
	testData := map[string]interface{}{
		"test": "data",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		service.Process(testData)
	}
}
`

// goMainTemplate is the template for generating main.go files
const goMainTemplate = `// Package main - Auto-generated main entry point
// Generated at: {{.Timestamp}}
// Author: {{.Author}}
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"go.uber.org/zap"
	"{{.Package}}"
)

var (
	port       = flag.String("port", "8080", "Server port")
	configFile = flag.String("config", "config.json", "Configuration file path")
	logLevel   = flag.String("log-level", "info", "Log level (debug, info, warn, error)")
)

func main() {
	flag.Parse()

	// Initialize logger
	logger, err := initLogger(*logLevel)
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}
	defer logger.Sync()

	logger.Info("Starting {{.Name}} service",
		zap.String("port", *port),
		zap.String("config", *configFile))

	// Load configuration
	config, err := loadConfig(*configFile)
	if err != nil {
		logger.Fatal("Failed to load configuration", zap.Error(err))
	}

	// Initialize service
	service, err := {{.Package}}.New{{.Name}}(logger, config)
	if err != nil {
		logger.Fatal("Failed to initialize service", zap.Error(err))
	}

	// Initialize HTTP handler
	handler := {{.Package}}.New{{.Name}}Handler(logger, service)

	// Setup HTTP server
	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	server := &http.Server{
		Addr:    ":" + *port,
		Handler: mux,
	}

	// Start service
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	if err := service.Start(ctx); err != nil {
		logger.Fatal("Failed to start service", zap.Error(err))
	}

	// Start HTTP server
	go func() {
		logger.Info("HTTP server listening", zap.String("port", *port))
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("HTTP server failed", zap.Error(err))
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	// Shutdown HTTP server
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		logger.Error("Server forced to shutdown", zap.Error(err))
	}

	// Stop service
	if err := service.Stop(); err != nil {
		logger.Error("Service shutdown error", zap.Error(err))
	}

	logger.Info("Server exited")
}

func initLogger(level string) (*zap.Logger, error) {
	var config zap.Config
	
	switch level {
	case "debug":
		config = zap.NewDevelopmentConfig()
	default:
		config = zap.NewProductionConfig()
	}

	return config.Build()
}

func loadConfig(configFile string) (*{{.Package}}.{{.Name}}Config, error) {
	// Add configuration loading logic here
	return &{{.Package}}.{{.Name}}Config{
		Name:    "{{.Name}}",
		Version: "1.0.0",
		Enabled: true,
		Settings: make(map[string]interface{}),
	}, nil
}
`

// goConfigTemplate is the template for generating configuration files
const goConfigTemplate = `// Package {{.Package}} - Auto-generated configuration
// Generated at: {{.Timestamp}}
// Author: {{.Author}}
package {{.Package}}

import (
	"encoding/json"
	"fmt"
	"os"
)

// Config represents the application configuration
type Config struct {
	Server   ServerConfig   ` + "`json:\"server\"`" + `
	Database DatabaseConfig ` + "`json:\"database\"`" + `
	Logging  LoggingConfig  ` + "`json:\"logging\"`" + `
	{{.Name}} {{.Name}}Config  ` + "`json:\"{{.Name | lower}}\"`" + `
}

// ServerConfig holds server configuration
type ServerConfig struct {
	Host            string ` + "`json:\"host\"`" + `
	Port            int    ` + "`json:\"port\"`" + `
	ReadTimeout     int    ` + "`json:\"read_timeout\"`" + `
	WriteTimeout    int    ` + "`json:\"write_timeout\"`" + `
	ShutdownTimeout int    ` + "`json:\"shutdown_timeout\"`" + `
}

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Driver   string ` + "`json:\"driver\"`" + `
	Host     string ` + "`json:\"host\"`" + `
	Port     int    ` + "`json:\"port\"`" + `
	Name     string ` + "`json:\"name\"`" + `
	Username string ` + "`json:\"username\"`" + `
	Password string ` + "`json:\"password\"`" + `
	SSLMode  string ` + "`json:\"ssl_mode\"`" + `
}

// LoggingConfig holds logging configuration
type LoggingConfig struct {
	Level      string ` + "`json:\"level\"`" + `
	Format     string ` + "`json:\"format\"`" + `
	Output     string ` + "`json:\"output\"`" + `
	MaxSize    int    ` + "`json:\"max_size\"`" + `
	MaxBackups int    ` + "`json:\"max_backups\"`" + `
	MaxAge     int    ` + "`json:\"max_age\"`" + `
}

// LoadConfig loads configuration from file
func LoadConfig(filePath string) (*Config, error) {
	if filePath == "" {
		return nil, fmt.Errorf("configuration file path is required")
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	// Apply defaults
	applyDefaults(&config)

	// Validate configuration
	if err := validateConfig(&config); err != nil {
		return nil, fmt.Errorf("configuration validation failed: %w", err)
	}

	return &config, nil
}

// SaveConfig saves configuration to file
func SaveConfig(config *Config, filePath string) error {
	if config == nil {
		return fmt.Errorf("config cannot be nil")
	}

	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	if err := os.WriteFile(filePath, data, 0644); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

// applyDefaults applies default values to configuration
func applyDefaults(config *Config) {
	if config.Server.Host == "" {
		config.Server.Host = "localhost"
	}
	if config.Server.Port == 0 {
		config.Server.Port = 8080
	}
	if config.Server.ReadTimeout == 0 {
		config.Server.ReadTimeout = 30
	}
	if config.Server.WriteTimeout == 0 {
		config.Server.WriteTimeout = 30
	}
	if config.Server.ShutdownTimeout == 0 {
		config.Server.ShutdownTimeout = 30
	}

	if config.Logging.Level == "" {
		config.Logging.Level = "info"
	}
	if config.Logging.Format == "" {
		config.Logging.Format = "json"
	}
	if config.Logging.Output == "" {
		config.Logging.Output = "stdout"
	}
}

// validateConfig validates the configuration
func validateConfig(config *Config) error {
	if config.Server.Port < 1 || config.Server.Port > 65535 {
		return fmt.Errorf("invalid server port: %d", config.Server.Port)
	}

	validLogLevels := map[string]bool{
		"debug": true, "info": true, "warn": true, "error": true, "fatal": true,
	}
	if !validLogLevels[config.Logging.Level] {
		return fmt.Errorf("invalid log level: %s", config.Logging.Level)
	}

	return nil
}

// GetDefaultConfig returns a default configuration
func GetDefaultConfig() *Config {
	config := &Config{
		Server: ServerConfig{
			Host:            "localhost",
			Port:            8080,
			ReadTimeout:     30,
			WriteTimeout:    30,
			ShutdownTimeout: 30,
		},
		Database: DatabaseConfig{
			Driver:  "postgres",
			Host:    "localhost",
			Port:    5432,
			SSLMode: "disable",
		},
		Logging: LoggingConfig{
			Level:      "info",
			Format:     "json",
			Output:     "stdout",
			MaxSize:    100,
			MaxBackups: 3,
			MaxAge:     28,
		},
		{{.Name}}: {{.Name}}Config{
			Name:    "{{.Name}}",
			Version: "1.0.0",
			Enabled: true,
			Settings: make(map[string]interface{}),
		},
	}

	return config
}
`

// readmeTemplate is the template for generating README files
const readmeTemplate = `# {{.Name}}

{{.Description}}

## Overview

This is an auto-generated service created using the GoGenEngine template system.

**Generated:** {{.Timestamp}}  
**Author:** {{.Author}}  
**Version:** {{.Version}}

## Features

- RESTful API endpoints
- Configuration management
- Structured logging
- Health checks
- Graceful shutdown
- Unit tests
- Documentation

## Installation

` + "```bash" + `
go mod download
go build -o {{.Name | lower}} ./cmd/{{.Name | lower}}
` + "```" + `

## Configuration

The service uses JSON configuration files. Example:

` + "```json" + `
{
  "server": {
    "host": "localhost",
    "port": 8080,
    "read_timeout": 30,
    "write_timeout": 30,
    "shutdown_timeout": 30
  },
  "logging": {
    "level": "info",
    "format": "json",
    "output": "stdout"
  },
  "{{.Name | lower}}": {
    "name": "{{.Name}}",
    "version": "{{.Version}}",
    "enabled": true,
    "settings": {}
  }
}
` + "```" + `

## Usage

### Starting the Service

` + "```bash" + `
./{{.Name | lower}} -port 8080 -config config.json -log-level info
` + "```" + `

### API Endpoints

- ` + "`POST /{{.Package}}/{{.Name | lower}}`" + ` - Main service endpoint
- ` + "`GET /{{.Package}}/{{.Name | lower}}/status`" + ` - Health check endpoint

### Example Request

` + "```bash" + `
curl -X POST http://localhost:8080/{{.Package}}/{{.Name | lower}} \
  -H "Content-Type: application/json" \
  -d '{"id": "test", "data": {"key": "value"}}'
` + "```" + `

### Example Response

` + "```json" + `
{
  "success": true,
  "data": {
    "processed": true,
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
` + "```" + `

## Development

### Running Tests

` + "```bash" + `
go test ./...
` + "```" + `

### Running with Live Reload

` + "```bash" + `
go run ./cmd/{{.Name | lower}} -port 8080
` + "```" + `

### Building

` + "```bash" + `
go build -o bin/{{.Name | lower}} ./cmd/{{.Name | lower}}
` + "```" + `

## Project Structure

` + "```" + `
.
├── cmd/{{.Name | lower}}/          # Main application
├── internal/{{.Name | lower}}/     # Service implementation
├── pkg/                    # Shared packages
├── configs/               # Configuration files
├── docs/                  # Documentation
├── scripts/              # Build and deployment scripts
└── tests/                # Integration tests
` + "```" + `

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| server.host | string | localhost | Server host |
| server.port | int | 8080 | Server port |
| server.read_timeout | int | 30 | Read timeout in seconds |
| server.write_timeout | int | 30 | Write timeout in seconds |
| logging.level | string | info | Log level (debug, info, warn, error) |
| logging.format | string | json | Log format (json, text) |

## Monitoring

The service provides the following monitoring endpoints:

- Health check: ` + "`GET /{{.Package}}/{{.Name | lower}}/status`" + `
- Metrics: ` + "`GET /metrics`" + ` (if metrics are enabled)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

[Add your license information here]

## Support

[Add support information here]
`
