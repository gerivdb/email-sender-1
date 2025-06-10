// Package discovery provides service discovery capabilities for the AdvancedAutonomyManager
package discovery

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/config"
	"github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/logging"
)

// ServiceType defines the type of service being discovered
type ServiceType string

const (
	// ContainerManager represents the container manager service
	ContainerManager ServiceType = "container-manager"
	// StorageManager represents the storage manager service
	StorageManager ServiceType = "storage-manager"
	// InfrastructureService represents an infrastructure component (Docker, K8s, etc)
	InfrastructureService ServiceType = "infrastructure-service"
	// DockerComposeFile represents a discovered docker-compose file
	DockerComposeFile ServiceType = "docker-compose-file"
)

// ServiceInfo contains information about a discovered service
type ServiceInfo struct {
	Type        ServiceType          `json:"type"`
	ID          string               `json:"id"`
	Name        string               `json:"name"`
	Endpoint    string               `json:"endpoint"`
	Status      string               `json:"status"`
	Version     string               `json:"version"`
	LastSeen    time.Time            `json:"last_seen"`
	Metadata    map[string]string    `json:"metadata"`
}

// ComposeFileInfo contains information about a discovered docker-compose file
type ComposeFileInfo struct {
	Path      string            `json:"path"`
	Services  []string          `json:"services"`
	Networks  []string          `json:"networks"`
	Volumes   []string          `json:"volumes"`
	LastSeen  time.Time         `json:"last_seen"`
	Metadata  map[string]string `json:"metadata"`
}

// InfrastructureDiscoveryService provides discovery for infrastructure components
type InfrastructureDiscoveryService struct {
	config          *config.Config
	services        map[string]*ServiceInfo
	composeFiles    map[string]*ComposeFileInfo
	logger          *logging.Logger
	mutex           sync.RWMutex
	scanTicker      *time.Ticker
	stopChan        chan struct{}
}

// NewInfrastructureDiscoveryService creates a new instance of the infrastructure discovery service
func NewInfrastructureDiscoveryService(cfg *config.Config, logger *logging.Logger) (*InfrastructureDiscoveryService, error) {
	if cfg == nil {
		return nil, fmt.Errorf("config cannot be nil")
	}

	if logger == nil {
		return nil, fmt.Errorf("logger cannot be nil")
	}

	return &InfrastructureDiscoveryService{
		config:       cfg,
		services:     make(map[string]*ServiceInfo),
		composeFiles: make(map[string]*ComposeFileInfo),
		logger:       logger,
		stopChan:     make(chan struct{}),
	}, nil
}

// Start begins the discovery process
func (ids *InfrastructureDiscoveryService) Start(ctx context.Context) error {
	infraCfg := ids.config.InfrastructureConfig
	if infraCfg == nil {
		return fmt.Errorf("infrastructure configuration is missing")
	}

	scanInterval, err := time.ParseDuration(infraCfg.ServiceDiscovery.HealthCheckInterval)
	if err != nil {
		scanInterval = 30 * time.Second // Default interval
	}

	ids.logger.Info("Starting infrastructure discovery service", "scan_interval", scanInterval)
	
	// Initial scan
	if err := ids.performDiscoveryScan(ctx); err != nil {
		ids.logger.Error("Initial discovery scan failed", "error", err)
	}
	
	// Start periodic scanning
	ids.scanTicker = time.NewTicker(scanInterval)
	go func() {
		for {
			select {
			case <-ctx.Done():
				ids.logger.Info("Discovery service stopping due to context cancellation")
				return
			case <-ids.stopChan:
				ids.logger.Info("Discovery service stopping due to stop signal")
				return
			case <-ids.scanTicker.C:
				if err := ids.performDiscoveryScan(ctx); err != nil {
					ids.logger.Error("Discovery scan failed", "error", err)
				}
			}
		}
	}()

	return nil
}

// Stop halts the discovery process
func (ids *InfrastructureDiscoveryService) Stop() {
	if ids.scanTicker != nil {
		ids.scanTicker.Stop()
	}
	close(ids.stopChan)
	ids.logger.Info("Infrastructure discovery service stopped")
}

// GetContainerManagerInfo returns information about the discovered container manager
func (ids *InfrastructureDiscoveryService) GetContainerManagerInfo() (*ServiceInfo, bool) {
	ids.mutex.RLock()
	defer ids.mutex.RUnlock()

	for _, svc := range ids.services {
		if svc.Type == ContainerManager {
			return svc, true
		}
	}

	return nil, false
}

// GetStorageManagerInfo returns information about the discovered storage manager
func (ids *InfrastructureDiscoveryService) GetStorageManagerInfo() (*ServiceInfo, bool) {
	ids.mutex.RLock()
	defer ids.mutex.RUnlock()

	for _, svc := range ids.services {
		if svc.Type == StorageManager {
			return svc, true
		}
	}

	return nil, false
}

// GetDiscoveredServices returns all discovered services
func (ids *InfrastructureDiscoveryService) GetDiscoveredServices() []*ServiceInfo {
	ids.mutex.RLock()
	defer ids.mutex.RUnlock()

	result := make([]*ServiceInfo, 0, len(ids.services))
	for _, svc := range ids.services {
		result = append(result, svc)
	}

	return result
}

// GetDiscoveredComposeFiles returns all discovered docker-compose files
func (ids *InfrastructureDiscoveryService) GetDiscoveredComposeFiles() []*ComposeFileInfo {
	ids.mutex.RLock()
	defer ids.mutex.RUnlock()

	result := make([]*ComposeFileInfo, 0, len(ids.composeFiles))
	for _, compose := range ids.composeFiles {
		result = append(result, compose)
	}

	return result
}

// RegisterService registers a new infrastructure service
func (ids *InfrastructureDiscoveryService) RegisterService(serviceInfo *ServiceInfo) {
	if serviceInfo == nil {
		return
	}

	ids.mutex.Lock()
	defer ids.mutex.Unlock()

	serviceInfo.LastSeen = time.Now()
	ids.services[serviceInfo.ID] = serviceInfo
	ids.logger.Info("Service registered", "id", serviceInfo.ID, "type", serviceInfo.Type, "endpoint", serviceInfo.Endpoint)
}

// performDiscoveryScan executes a discovery scan for infrastructure components
func (ids *InfrastructureDiscoveryService) performDiscoveryScan(ctx context.Context) error {
	ids.logger.Debug("Starting infrastructure discovery scan")

	// Scan for container manager
	if err := ids.discoverContainerManager(ctx); err != nil {
		ids.logger.Error("Failed to discover container manager", "error", err)
	}

	// Scan for storage manager
	if err := ids.discoverStorageManager(ctx); err != nil {
		ids.logger.Error("Failed to discover storage manager", "error", err)
	}

	// Scan for docker-compose files
	if err := ids.discoverDockerComposeFiles(ctx); err != nil {
		ids.logger.Error("Failed to discover docker-compose files", "error", err)
	}

	ids.logger.Debug("Infrastructure discovery scan completed", 
		"services", len(ids.services),
		"compose_files", len(ids.composeFiles))

	return nil
}

// discoverContainerManager attempts to discover the container manager service
func (ids *InfrastructureDiscoveryService) discoverContainerManager(ctx context.Context) error {
	infraCfg := ids.config.InfrastructureConfig
	if infraCfg == nil || infraCfg.ServiceDiscovery.ContainerManagerEndpoint == "" {
		return fmt.Errorf("container manager endpoint not configured")
	}

	endpoint := infraCfg.ServiceDiscovery.ContainerManagerEndpoint
	
	// Create HTTP request with context
	req, err := http.NewRequestWithContext(ctx, "GET", fmt.Sprintf("http://%s/health", endpoint), nil)
	if err != nil {
		return fmt.Errorf("failed to create container manager health check request: %w", err)
	}

	client := &http.Client{
		Timeout: 5 * time.Second,
	}
	
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("container manager health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("container manager returned non-OK status: %d", resp.StatusCode)
	}

	// Read and parse response
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read container manager response: %w", err)
	}

	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		return fmt.Errorf("failed to parse container manager response: %w", err)
	}

	// Extract service info
	serviceInfo := &ServiceInfo{
		Type:     ContainerManager,
		ID:       "container-manager-001", // This would normally come from the response
		Name:     "ContainerManager",
		Endpoint: endpoint,
		Status:   "active",
		LastSeen: time.Now(),
		Metadata: make(map[string]string),
	}

	// Extract version if available
	if version, ok := data["version"].(string); ok {
		serviceInfo.Version = version
		serviceInfo.Metadata["version"] = version
	}

	// Register the discovered service
	ids.RegisterService(serviceInfo)
	ids.logger.Info("Container manager discovered", "endpoint", endpoint)

	return nil
}

// discoverStorageManager attempts to discover the storage manager service
func (ids *InfrastructureDiscoveryService) discoverStorageManager(ctx context.Context) error {
	// This would be similar to the container manager discovery,
	// but for now, we'll just create a mock implementation
	
	// In a real implementation, this would connect to the storage manager endpoint
	// and retrieve its health/status information

	serviceInfo := &ServiceInfo{
		Type:     StorageManager,
		ID:       "storage-manager-001",
		Name:     "StorageManager",
		Endpoint: "localhost:8081", // This would be configured or discovered
		Status:   "active",
		LastSeen: time.Now(),
		Metadata: map[string]string{
			"version": "1.0.0",
		},
	}

	ids.RegisterService(serviceInfo)
	ids.logger.Info("Storage manager discovered", "endpoint", serviceInfo.Endpoint)

	return nil
}

// discoverDockerComposeFiles scans for docker-compose files in the configured path
func (ids *InfrastructureDiscoveryService) discoverDockerComposeFiles(ctx context.Context) error {
	infraCfg := ids.config.InfrastructureConfig
	if infraCfg == nil || infraCfg.ServiceDiscovery.DockerComposePath == "" {
		return fmt.Errorf("docker-compose path not configured")
	}

	path := infraCfg.ServiceDiscovery.DockerComposePath
	
	// Handle relative paths
	if !filepath.IsAbs(path) {
		// Convert to absolute path based on current working directory
		workDir, err := os.Getwd()
		if err != nil {
			return fmt.Errorf("failed to get working directory: %w", err)
		}
		path = filepath.Join(workDir, path)
	}

	// Check if file exists
	info, err := os.Stat(path)
	if err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("docker-compose file not found at %s", path)
		}
		return fmt.Errorf("error checking docker-compose file: %w", err)
	}

	if info.IsDir() {
		return fmt.Errorf("%s is a directory, expected a file", path)
	}

	// Read the compose file
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return fmt.Errorf("failed to read docker-compose file: %w", err)
	}

	// In a real implementation, we would parse the YAML to extract services, networks, etc.
	// For this implementation, we'll create a mock ComposeFileInfo

	composeFileInfo := &ComposeFileInfo{
		Path:     path,
		Services: []string{"qdrant", "redis", "postgresql", "prometheus", "grafana", "rag-server"},
		Networks: []string{"infrastructure-network"},
		Volumes:  []string{"qdrant-data", "prometheus-data", "grafana-data"},
		LastSeen: time.Now(),
		Metadata: map[string]string{
			"size": fmt.Sprintf("%d", len(data)),
		},
	}

	ids.mutex.Lock()
	ids.composeFiles[path] = composeFileInfo
	ids.mutex.Unlock()

	ids.logger.Info("Docker-compose file discovered", "path", path, "services", len(composeFileInfo.Services))

	return nil
}
