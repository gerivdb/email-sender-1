package coordinator

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// ManagerDiscovery implémente la découverte automatique de managers
type ManagerDiscovery struct {
	registry map[string]ManagerInterface
	mu       sync.RWMutex
	logger   *zap.Logger
}

// ManagerInterface définit l'interface commune (duplicata pour éviter import circulaire)
type ManagerInterface interface {
	Initialize(ctx context.Context, config interface{}) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	GetStatus() ManagerStatus
	GetMetrics() ManagerMetrics
	ValidateConfig(config interface{}) error
	GetID() string
	GetName() string
	GetVersion() string
	Health(ctx context.Context) error
}

// ManagerStatus représente l'état d'un manager
type ManagerStatus struct {
	Name      string        `json:"name"`
	Status    string        `json:"status"`
	LastCheck time.Time     `json:"last_check"`
	Errors    []string      `json:"errors"`
	Uptime    time.Duration `json:"uptime"`
}

// ManagerMetrics représente les métriques d'un manager
type ManagerMetrics struct {
	Name         string            `json:"name"`
	Uptime       time.Duration     `json:"uptime"`
	RequestCount int64             `json:"request_count"`
	ErrorCount   int64             `json:"error_count"`
	LastRequest  time.Time         `json:"last_request"`
	CustomData   map[string]string `json:"custom_data"`
}

// NewManagerDiscovery crée une nouvelle instance de découverte
func NewManagerDiscovery(logger *zap.Logger) *ManagerDiscovery {
	return &ManagerDiscovery{
		registry: make(map[string]ManagerInterface),
		logger:   logger,
	}
}

// DiscoverManagers découvre automatiquement tous les managers dans l'écosystème
func (md *ManagerDiscovery) DiscoverManagers(ctx context.Context) ([]string, error) {
	md.mu.Lock()
	defer md.mu.Unlock()

	// Liste des managers connus de l'écosystème (26 managers)
	knownManagers := []string{
		"advanced-autonomy-manager",
		"ai-template-manager",
		"branching-manager",
		"config-manager",
		"container-manager",
		"contextual-memory-manager",
		"dependency-manager",
		"deployment-manager",
		"email-manager",
		"error-manager",
		"git-workflow-manager",
		"integrated-manager",
		"integration-manager",
		"maintenance-manager",
		"mcp-manager",
		"mode-manager",
		"monitoring-manager",
		"n8n-manager",
		"notification-manager",
		"process-manager",
		"roadmap-manager",
		"script-manager",
		"security-manager",
		"smart-variable-manager",
		"storage-manager",
		"template-performance-manager",
	}

	discovered := make([]string, 0)

	for _, managerName := range knownManagers {
		// Simuler la découverte - en réalité, cela scannerait les répertoires
		mock := &MockManager{
			name:    managerName,
			version: "1.0.0",
			status: ManagerStatus{
				Name:      managerName,
				Status:    "discovered",
				LastCheck: time.Now(),
				Errors:    make([]string, 0),
			},
		}

		md.registry[managerName] = mock
		discovered = append(discovered, managerName)
		md.logger.Info("Manager discovered", zap.String("name", managerName))
	}

	md.logger.Info("Manager discovery completed",
		zap.Int("total_discovered", len(discovered)))

	return discovered, nil
}

// GetManager retourne un manager par nom
func (md *ManagerDiscovery) GetManager(name string) (ManagerInterface, error) {
	md.mu.RLock()
	defer md.mu.RUnlock()

	manager, exists := md.registry[name]
	if !exists {
		return nil, fmt.Errorf("manager %s not found", name)
	}

	return manager, nil
}

// ListManagers retourne la liste de tous les managers découverts
func (md *ManagerDiscovery) ListManagers() []string {
	md.mu.RLock()
	defer md.mu.RUnlock()

	managers := make([]string, 0, len(md.registry))
	for name := range md.registry {
		managers = append(managers, name)
	}

	return managers
}

// GetAllManagers retourne tous les managers
func (md *ManagerDiscovery) GetAllManagers() map[string]ManagerInterface {
	md.mu.RLock()
	defer md.mu.RUnlock()

	managers := make(map[string]ManagerInterface)
	for name, manager := range md.registry {
		managers[name] = manager
	}

	return managers
}

// MockManager implémente ManagerInterface pour les tests
type MockManager struct {
	name      string
	version   string
	status    ManagerStatus
	startTime time.Time
}

func (m *MockManager) Initialize(ctx context.Context, config interface{}) error {
	m.status.Status = "initialized"
	m.status.LastCheck = time.Now()
	return nil
}

func (m *MockManager) Start(ctx context.Context) error {
	m.status.Status = "running"
	m.status.LastCheck = time.Now()
	m.startTime = time.Now()
	return nil
}

func (m *MockManager) Stop(ctx context.Context) error {
	m.status.Status = "stopped"
	m.status.LastCheck = time.Now()
	return nil
}

func (m *MockManager) GetStatus() ManagerStatus {
	if !m.startTime.IsZero() {
		m.status.Uptime = time.Since(m.startTime)
	}
	return m.status
}

func (m *MockManager) GetMetrics() ManagerMetrics {
	return ManagerMetrics{
		Name:         m.name,
		Uptime:       time.Since(m.startTime),
		RequestCount: 0,
		ErrorCount:   0,
		LastRequest:  time.Now(),
		CustomData:   make(map[string]string),
	}
}

func (m *MockManager) ValidateConfig(config interface{}) error {
	return nil
}

func (m *MockManager) GetID() string {
	return fmt.Sprintf("%s-id", m.name)
}

func (m *MockManager) GetName() string {
	return m.name
}

func (m *MockManager) GetVersion() string {
	return m.version
}

func (m *MockManager) Health(ctx context.Context) error {
	if m.status.Status == "running" {
		return nil
	}
	return fmt.Errorf("manager %s is not healthy", m.name)
}
