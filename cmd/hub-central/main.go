package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"go.uber.org/zap"
)

// CentralHub represents the main hub that coordinates all managers
type CentralHub struct {
	managers map[string]Manager
	eventBus *EventBus
	config   *HubConfig
	metrics  *MetricsCollector
	logger   *zap.Logger
	ctx      context.Context
	cancel   context.CancelFunc
	wg       sync.WaitGroup
}

// Manager interface that all managers must implement
type Manager interface {
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	Health() HealthStatus
	Metrics() map[string]interface{}
	GetName() string
}

// HealthStatus represents the health status of a manager
type HealthStatus struct {
	Status    string                 `json:"status"`
	Message   string                 `json:"message"`
	Timestamp time.Time              `json:"timestamp"`
	Details   map[string]interface{} `json:"details,omitempty"`
}

// HubConfig holds the configuration for the central hub
type HubConfig struct {
	Email      *EmailConfig      `yaml:"email"`
	Database   *DatabaseConfig   `yaml:"database"`
	Cache      *CacheConfig      `yaml:"cache"`
	Vector     *VectorConfig     `yaml:"vector"`
	Process    *ProcessConfig    `yaml:"process"`
	Container  *ContainerConfig  `yaml:"container"`
	Dependency *DependencyConfig `yaml:"dependency"`
	MCP        *MCPConfig        `yaml:"mcp"`
	ConfigMgr  *ConfigMgrConfig  `yaml:"config_manager"`
	Watch      *WatchConfig      `yaml:"watch"`
	Hub        *HubSettings      `yaml:"hub"`
}

type HubSettings struct {
	Port            int           `yaml:"port"`
	HealthCheckPort int           `yaml:"health_check_port"`
	ShutdownTimeout time.Duration `yaml:"shutdown_timeout"`
	StartupTimeout  time.Duration `yaml:"startup_timeout"`
	LogLevel        string        `yaml:"log_level"`
}

// NewCentralHub creates a new instance of CentralHub
func NewCentralHub(config *HubConfig, logger *zap.Logger) *CentralHub {
	ctx, cancel := context.WithCancel(context.Background())

	hub := &CentralHub{
		managers: make(map[string]Manager),
		config:   config,
		logger:   logger,
		ctx:      ctx,
		cancel:   cancel,
	}

	// Initialize event bus
	hub.eventBus = NewEventBus(logger)

	// Initialize metrics collector
	hub.metrics = NewMetricsCollector(logger)

	return hub
}

// Initialize sets up all managers and prepares the hub for startup
func (h *CentralHub) Initialize() error {
	h.logger.Info("Initializing Central Hub")

	// Initialize all managers
	h.managers = map[string]Manager{
		"email":      NewEmailManager(h.config.Email, h.logger, h.eventBus),
		"database":   NewDatabaseManager(h.config.Database, h.logger, h.eventBus),
		"cache":      NewCacheManager(h.config.Cache, h.logger, h.eventBus),
		"vector":     NewVectorManager(h.config.Vector, h.logger, h.eventBus),
		"process":    NewProcessManager(h.config.Process, h.logger, h.eventBus),
		"container":  NewContainerManager(h.config.Container, h.logger, h.eventBus),
		"dependency": NewDependencyManager(h.config.Dependency, h.logger, h.eventBus),
		"mcp":        NewMCPManager(h.config.MCP, h.logger, h.eventBus),
		"config":     NewConfigManager(h.config.ConfigMgr, h.logger, h.eventBus),
		"watch":      NewWatchManager(h.config.Watch, h.logger, h.eventBus),
	}

	h.logger.Info("All managers initialized", zap.Int("manager_count", len(h.managers)))

	return h.startAllManagers()
}

// startAllManagers starts all registered managers
func (h *CentralHub) startAllManagers() error {
	h.logger.Info("Starting all managers")

	startCtx, cancel := context.WithTimeout(h.ctx, h.config.Hub.StartupTimeout)
	defer cancel()

	// Start event bus first
	if err := h.eventBus.Start(startCtx); err != nil {
		return fmt.Errorf("failed to start event bus: %w", err)
	}

	// Start metrics collector
	if err := h.metrics.Start(startCtx); err != nil {
		return fmt.Errorf("failed to start metrics collector: %w", err)
	}

	// Start all managers in parallel
	errChan := make(chan error, len(h.managers))

	for name, manager := range h.managers {
		h.wg.Add(1)
		go func(name string, mgr Manager) {
			defer h.wg.Done()

			h.logger.Info("Starting manager", zap.String("manager", name))
			if err := mgr.Start(startCtx); err != nil {
				errChan <- fmt.Errorf("failed to start manager %s: %w", name, err)
				return
			}

			h.logger.Info("Manager started successfully", zap.String("manager", name))
		}(name, manager)
	}

	// Wait for all managers to start or timeout
	done := make(chan struct{})
	go func() {
		h.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		h.logger.Info("All managers started successfully")
		return nil
	case err := <-errChan:
		return err
	case <-startCtx.Done():
		return fmt.Errorf("startup timeout exceeded")
	}
}

// Stop gracefully shuts down all managers
func (h *CentralHub) Stop() error {
	h.logger.Info("Stopping Central Hub")

	stopCtx, cancel := context.WithTimeout(context.Background(), h.config.Hub.ShutdownTimeout)
	defer cancel()

	// Stop all managers
	var stopErrors []error
	for name, manager := range h.managers {
		h.logger.Info("Stopping manager", zap.String("manager", name))
		if err := manager.Stop(stopCtx); err != nil {
			stopErrors = append(stopErrors, fmt.Errorf("failed to stop manager %s: %w", name, err))
		}
	}

	// Stop metrics collector
	if err := h.metrics.Stop(stopCtx); err != nil {
		stopErrors = append(stopErrors, fmt.Errorf("failed to stop metrics collector: %w", err))
	}

	// Stop event bus
	if err := h.eventBus.Stop(stopCtx); err != nil {
		stopErrors = append(stopErrors, fmt.Errorf("failed to stop event bus: %w", err))
	}

	h.cancel()

	if len(stopErrors) > 0 {
		return fmt.Errorf("errors during shutdown: %v", stopErrors)
	}

	h.logger.Info("Central Hub stopped successfully")
	return nil
}

// GetHealth returns the overall health status of the hub
func (h *CentralHub) GetHealth() map[string]HealthStatus {
	health := make(map[string]HealthStatus)

	for name, manager := range h.managers {
		health[name] = manager.Health()
	}

	// Add event bus health
	health["event_bus"] = h.eventBus.Health()

	// Add metrics collector health
	health["metrics"] = h.metrics.Health()

	return health
}

// GetMetrics returns metrics from all managers
func (h *CentralHub) GetMetrics() map[string]map[string]interface{} {
	metrics := make(map[string]map[string]interface{})

	for name, manager := range h.managers {
		metrics[name] = manager.Metrics()
	}

	// Add hub-level metrics
	metrics["hub"] = map[string]interface{}{
		"manager_count":   len(h.managers),
		"uptime_seconds":  time.Since(h.metrics.startTime).Seconds(),
		"event_bus_stats": h.eventBus.GetStats(),
		"memory_usage":    h.metrics.GetMemoryStats(),
	}

	return metrics
}

// Run starts the hub and blocks until shutdown
func (h *CentralHub) Run() error {
	// Initialize the hub
	if err := h.Initialize(); err != nil {
		return fmt.Errorf("failed to initialize hub: %w", err)
	}

	h.logger.Info("Central Hub is running",
		zap.Int("port", h.config.Hub.Port),
		zap.Int("health_port", h.config.Hub.HealthCheckPort))

	// Start HTTP server for health checks and metrics
	server := NewHubServer(h, h.config.Hub.Port, h.config.Hub.HealthCheckPort, h.logger)
	if err := server.Start(); err != nil {
		return fmt.Errorf("failed to start hub server: %w", err)
	}
	defer server.Stop()

	// Wait for shutdown signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-sigChan:
		h.logger.Info("Received shutdown signal", zap.String("signal", sig.String()))
	case <-h.ctx.Done():
		h.logger.Info("Context cancelled, shutting down")
	}

	return h.Stop()
}

func main() {
	// Initialize logger
	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}
	defer logger.Sync()

	// Load configuration
	config, err := LoadHubConfig()
	if err != nil {
		logger.Fatal("Failed to load configuration", zap.Error(err))
	}

	// Create and run the central hub
	hub := NewCentralHub(config, logger)
	if err := hub.Run(); err != nil {
		logger.Fatal("Central Hub failed", zap.Error(err))
	}

	logger.Info("Central Hub shutdown complete")
}
