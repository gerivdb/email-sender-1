package coordinator

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// CentralCoordinator unifie les responsabilités communes entre managers
type CentralCoordinator struct {
	managers map[string]ManagerInterface
	logger   *zap.Logger
	mu       sync.RWMutex
	status   CoordinatorStatus
}

// CoordinatorStatus représente l'état du coordinateur
type CoordinatorStatus struct {
	Active       bool      `json:"active"`
	ManagerCount int       `json:"manager_count"`
	LastCheck    time.Time `json:"last_check"`
	Errors       []string  `json:"errors"`
}

// ManagerInterface définit l'interface commune pour tous les managers
type ManagerInterface interface {
	Initialize(ctx context.Context, config interface{}) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	GetStatus() ManagerStatus
	GetMetrics() ManagerMetrics
	ValidateConfig(config interface{}) error
}

// ManagerStatus représente l'état d'un manager
type ManagerStatus struct {
	Name      string    `json:"name"`
	Status    string    `json:"status"`
	LastCheck time.Time `json:"last_check"`
	Errors    []string  `json:"errors"`
}

// ManagerMetrics représente les métriques d'un manager
type ManagerMetrics struct {
	Name         string            `json:"name"`
	Uptime       time.Duration     `json:"uptime"`
	RequestCount int64             `json:"request_count"`
	ErrorCount   int64             `json:"error_count"`
	CustomData   map[string]string `json:"custom_data"`
}

// NewCentralCoordinator crée une nouvelle instance du coordinateur
func NewCentralCoordinator(logger *zap.Logger) *CentralCoordinator {
	return &CentralCoordinator{
		managers: make(map[string]ManagerInterface),
		logger:   logger,
		status: CoordinatorStatus{
			Active:    false,
			LastCheck: time.Now(),
			Errors:    make([]string, 0),
		},
	}
}

// RegisterManager enregistre un manager dans le coordinateur
func (cc *CentralCoordinator) RegisterManager(name string, manager ManagerInterface) error {
	cc.mu.Lock()
	defer cc.mu.Unlock()

	if _, exists := cc.managers[name]; exists {
		return fmt.Errorf("manager %s already registered", name)
	}

	cc.managers[name] = manager
	cc.status.ManagerCount = len(cc.managers)
	cc.logger.Info("Manager registered", zap.String("name", name))

	return nil
}

// UnregisterManager retire un manager du coordinateur
func (cc *CentralCoordinator) UnregisterManager(name string) error {
	cc.mu.Lock()
	defer cc.mu.Unlock()

	if _, exists := cc.managers[name]; !exists {
		return fmt.Errorf("manager %s not found", name)
	}

	delete(cc.managers, name)
	cc.status.ManagerCount = len(cc.managers)
	cc.logger.Info("Manager unregistered", zap.String("name", name))

	return nil
}

// StartAll démarre tous les managers enregistrés
func (cc *CentralCoordinator) StartAll(ctx context.Context) error {
	cc.mu.Lock()
	defer cc.mu.Unlock()

	var wg sync.WaitGroup
	errors := make(chan error, len(cc.managers))

	for name, manager := range cc.managers {
		wg.Add(1)
		go func(n string, m ManagerInterface) {
			defer wg.Done()
			if err := m.Start(ctx); err != nil {
				errors <- fmt.Errorf("failed to start manager %s: %w", n, err)
			}
		}(name, manager)
	}

	wg.Wait()
	close(errors)

	// Collecter les erreurs
	var allErrors []string
	for err := range errors {
		allErrors = append(allErrors, err.Error())
		cc.logger.Error("Manager start error", zap.Error(err))
	}

	cc.status.Errors = allErrors
	cc.status.Active = len(allErrors) == 0
	cc.status.LastCheck = time.Now()

	if len(allErrors) > 0 {
		return fmt.Errorf("failed to start %d managers", len(allErrors))
	}

	cc.logger.Info("All managers started successfully", zap.Int("count", len(cc.managers)))
	return nil
}

// StopAll arrête tous les managers enregistrés
func (cc *CentralCoordinator) StopAll(ctx context.Context) error {
	cc.mu.Lock()
	defer cc.mu.Unlock()

	var wg sync.WaitGroup
	errors := make(chan error, len(cc.managers))

	for name, manager := range cc.managers {
		wg.Add(1)
		go func(n string, m ManagerInterface) {
			defer wg.Done()
			if err := m.Stop(ctx); err != nil {
				errors <- fmt.Errorf("failed to stop manager %s: %w", n, err)
			}
		}(name, manager)
	}

	wg.Wait()
	close(errors)

	// Collecter les erreurs
	var allErrors []string
	for err := range errors {
		allErrors = append(allErrors, err.Error())
		cc.logger.Error("Manager stop error", zap.Error(err))
	}

	cc.status.Errors = allErrors
	cc.status.Active = false
	cc.status.LastCheck = time.Now()

	if len(allErrors) > 0 {
		return fmt.Errorf("failed to stop %d managers", len(allErrors))
	}

	cc.logger.Info("All managers stopped successfully", zap.Int("count", len(cc.managers)))
	return nil
}

// GetAllManagersStatus retourne le statut de tous les managers
func (cc *CentralCoordinator) GetAllManagersStatus() map[string]ManagerStatus {
	cc.mu.RLock()
	defer cc.mu.RUnlock()

	statuses := make(map[string]ManagerStatus)
	for name, manager := range cc.managers {
		statuses[name] = manager.GetStatus()
	}

	return statuses
}

// GetCoordinatorStatus retourne le statut du coordinateur
func (cc *CentralCoordinator) GetCoordinatorStatus() CoordinatorStatus {
	cc.mu.RLock()
	defer cc.mu.RUnlock()

	return cc.status
}

// HealthCheck vérifie la santé de tous les managers
func (cc *CentralCoordinator) HealthCheck(ctx context.Context) error {
	cc.mu.RLock()
	defer cc.mu.RUnlock()

	unhealthyManagers := make([]string, 0)

	for name, manager := range cc.managers {
		status := manager.GetStatus()
		if status.Status != "healthy" && status.Status != "running" {
			unhealthyManagers = append(unhealthyManagers, name)
		}
	}

	if len(unhealthyManagers) > 0 {
		return fmt.Errorf("unhealthy managers detected: %v", unhealthyManagers)
	}

	cc.logger.Info("Health check passed", zap.Int("manager_count", len(cc.managers)))
	return nil
}
