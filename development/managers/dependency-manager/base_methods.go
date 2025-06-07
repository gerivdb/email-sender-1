package dependency

import (
	"context"
	"fmt"

	"github.com/email-sender-manager/interfaces"
)

// Interface compliance methods

// GetID retourne l'ID du manager
func (dm *DependencyManagerImpl) GetID() string {
	return dm.id
}

// GetName retourne le nom du manager
func (dm *DependencyManagerImpl) GetName() string {
	return dm.name
}

// GetVersion retourne la version du manager
func (dm *DependencyManagerImpl) GetVersion() string {
	return dm.version
}

// GetStatus retourne le statut du manager
func (dm *DependencyManagerImpl) GetStatus() interfaces.ManagerStatus {
	dm.mu.RLock()
	defer dm.mu.RUnlock()
	return dm.status
}

// Initialize initialise le gestionnaire de dépendances
func (dm *DependencyManagerImpl) Initialize(ctx context.Context) error {
	dm.mu.Lock()
	defer dm.mu.Unlock()

	if dm.isInitialized {
		return nil
	}

	dm.logger.Println("Initializing Dependency Manager...")
	dm.status = interfaces.StatusStarting

	// Initialiser le graphe des dépendances
	if err := dm.initializeDependencyGraph(ctx); err != nil {
		dm.status = interfaces.StatusError
		return fmt.Errorf("failed to initialize dependency graph: %w", err)
	}

	// Charger les métadonnées existantes
	if err := dm.loadExistingMetadata(ctx); err != nil {
		dm.logger.Printf("Warning: Failed to load existing metadata: %v", err)
	}

	dm.isInitialized = true
	dm.status = interfaces.StatusRunning
	dm.logger.Println("Dependency Manager initialized successfully")
	return nil
}

// Start démarre le gestionnaire
func (dm *DependencyManagerImpl) Start(ctx context.Context) error {
	if !dm.isInitialized {
		if err := dm.Initialize(ctx); err != nil {
			return err
		}
	}

	dm.mu.Lock()
	defer dm.mu.Unlock()

	if dm.status == interfaces.StatusRunning {
		return nil
	}

	dm.status = interfaces.StatusRunning
	dm.logger.Println("Dependency Manager started")
	return nil
}

// Stop arrête le gestionnaire
func (dm *DependencyManagerImpl) Stop(ctx context.Context) error {
	dm.mu.Lock()
	defer dm.mu.Unlock()

	dm.logger.Println("Stopping Dependency Manager...")
	dm.status = interfaces.StatusStopping

	// Sauvegarder le cache si nécessaire
	if err := dm.saveCache(ctx); err != nil {
		dm.logger.Printf("Warning: Failed to save cache: %v", err)
	}

	dm.status = interfaces.StatusStopped
	dm.logger.Println("Dependency Manager stopped")
	return nil
}

// Health vérifie la santé du gestionnaire
func (dm *DependencyManagerImpl) Health(ctx context.Context) error {
	dm.mu.RLock()
	defer dm.mu.RUnlock()

	if dm.status != interfaces.StatusRunning {
		return fmt.Errorf("dependency manager is not running, status: %v", dm.status)
	}

	// Vérifier la disponibilité des registres
	if err := dm.checkRegistryHealth(ctx); err != nil {
		return fmt.Errorf("registry health check failed: %w", err)
	}

	dm.logger.Println("Health check passed")
	return nil
}

// HealthCheck implémente BaseManager.HealthCheck
func (dm *DependencyManagerImpl) HealthCheck(ctx context.Context) error {
	return dm.Health(ctx)
}

// Cleanup implémente BaseManager.Cleanup
func (dm *DependencyManagerImpl) Cleanup() error {
	ctx := context.Background()
	return dm.Stop(ctx)
}
