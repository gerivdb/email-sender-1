package development

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/email-sender/development/managers/contextual-memory-manager/interfaces"
	"github.com/email-sender/development/managers/contextual-memory-manager/internal/indexing"
	"github.com/email-sender/development/managers/contextual-memory-manager/internal/integration"
	"github.com/email-sender/development/managers/contextual-memory-manager/internal/monitoring"
	"github.com/email-sender/development/managers/contextual-memory-manager/internal/retrieval"
	baseInterfaces "./interfaces"
)

type contextualMemoryManagerImpl struct {
	indexManager       interfaces.IndexManager
	retrievalManager   interfaces.RetrievalManager
	integrationManager interfaces.IntegrationManager
	monitoringManager  interfaces.MonitoringManager
	storageManager     baseInterfaces.StorageManager
	errorManager       baseInterfaces.ErrorManager
	configManager      baseInterfaces.ConfigManager
	initialized        bool
	mu                 sync.RWMutex
}

// NewContextualMemoryManager crÃ©e une nouvelle instance du manager
func NewContextualMemoryManager(
	sm baseInterfaces.StorageManager,
	em baseInterfaces.ErrorManager,
	cm baseInterfaces.ConfigManager,
) interfaces.ContextualMemoryManager {
	return &contextualMemoryManagerImpl{
		storageManager: sm,
		errorManager:   em,
		configManager:  cm,
		initialized:    false,
	}
}

func (cmm *contextualMemoryManagerImpl) Initialize(ctx context.Context) error {
	cmm.mu.Lock()
	defer cmm.mu.Unlock()

	if cmm.initialized {
		return nil
	}

	// Initialiser les sous-managers dans l'ordre des dÃ©pendances

	// 1. Monitoring Manager (premier car utilisÃ© par les autres)
	monitoringMgr, err := monitoring.NewMonitoringManager(
		cmm.storageManager,
		cmm.errorManager,
		cmm.configManager,
	)
	if err != nil {
		return fmt.Errorf("failed to create monitoring manager: %w", err)
	}

	if err := monitoringMgr.Initialize(ctx); err != nil {
		return fmt.Errorf("failed to initialize monitoring manager: %w", err)
	}
	cmm.monitoringManager = monitoringMgr

	// 2. Index Manager (gestion des embeddings)
	indexMgr, err := indexing.NewIndexManager(
		cmm.storageManager,
		cmm.errorManager,
		cmm.configManager,
		cmm.monitoringManager,
	)
	if err != nil {
		return fmt.Errorf("failed to create index manager: %w", err)
	}

	if err := indexMgr.Initialize(ctx); err != nil {
		return fmt.Errorf("failed to initialize index manager: %w", err)
	}
	cmm.indexManager = indexMgr

	// 3. Retrieval Manager (recherche contextuelle)
	retrievalMgr, err := retrieval.NewRetrievalManager(
		cmm.storageManager,
		cmm.errorManager,
		cmm.configManager,
		cmm.indexManager,
		cmm.monitoringManager,
	)
	if err != nil {
		return fmt.Errorf("failed to create retrieval manager: %w", err)
	}

	if err := retrievalMgr.Initialize(ctx); err != nil {
		return fmt.Errorf("failed to initialize retrieval manager: %w", err)
	}
	cmm.retrievalManager = retrievalMgr
	// 4. Integration Manager (MCP Gateway & N8N)
	integrationMgr, err := integration.NewIntegrationManager(
		cmm.storageManager,
		cmm.configManager,
		cmm.errorManager,
	)
	if err != nil {
		return fmt.Errorf("failed to create integration manager: %w", err)
	}

	if err := integrationMgr.Initialize(ctx); err != nil {
		return fmt.Errorf("failed to initialize integration manager: %w", err)
	}
	cmm.integrationManager = integrationMgr

	cmm.initialized = true

	// Enregistrer les mÃ©triques d'initialisation
	if err := cmm.monitoringManager.RecordOperation(ctx, "manager_initialization", time.Since(time.Now()), nil); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record initialization metrics", err)
	}

	return nil
}

func (cmm *contextualMemoryManagerImpl) HealthCheck(ctx context.Context) error {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return fmt.Errorf("manager not initialized")
	}

	// VÃ©rifier la santÃ© de tous les sous-composants
	if err := cmm.monitoringManager.HealthCheck(ctx); err != nil {
		return fmt.Errorf("monitoring manager health check failed: %w", err)
	}

	if err := cmm.indexManager.HealthCheck(ctx); err != nil {
		return fmt.Errorf("index manager health check failed: %w", err)
	}

	if err := cmm.retrievalManager.HealthCheck(ctx); err != nil {
		return fmt.Errorf("retrieval manager health check failed: %w", err)
	}

	if err := cmm.integrationManager.HealthCheck(ctx); err != nil {
		return fmt.Errorf("integration manager health check failed: %w", err)
	}

	return nil
}

func (cmm *contextualMemoryManagerImpl) Cleanup() error {
	cmm.mu.Lock()
	defer cmm.mu.Unlock()

	if !cmm.initialized {
		return nil
	}

	var errs []error

	// Nettoyer dans l'ordre inverse d'initialisation
	if cmm.integrationManager != nil {
		if err := cmm.integrationManager.Cleanup(); err != nil {
			errs = append(errs, fmt.Errorf("integration manager cleanup: %w", err))
		}
	}

	if cmm.retrievalManager != nil {
		if err := cmm.retrievalManager.Cleanup(); err != nil {
			errs = append(errs, fmt.Errorf("retrieval manager cleanup: %w", err))
		}
	}

	if cmm.indexManager != nil {
		if err := cmm.indexManager.Cleanup(); err != nil {
			errs = append(errs, fmt.Errorf("index manager cleanup: %w", err))
		}
	}

	if cmm.monitoringManager != nil {
		if err := cmm.monitoringManager.Cleanup(); err != nil {
			errs = append(errs, fmt.Errorf("monitoring manager cleanup: %w", err))
		}
	}

	cmm.initialized = false

	if len(errs) > 0 {
		return fmt.Errorf("cleanup errors: %v", errs)
	}

	return nil
}

func (cmm *contextualMemoryManagerImpl) CaptureAction(ctx context.Context, action interfaces.Action) error {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return fmt.Errorf("manager not initialized")
	}

	start := time.Now()

	// 1. Indexer l'action pour recherche future
	if err := cmm.indexManager.IndexAction(ctx, action); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to index action", err)
		return fmt.Errorf("failed to index action: %w", err)
	}

	// 2. Notifier les intÃ©grations (MCP Gateway, N8N)
	if err := cmm.integrationManager.NotifyAction(ctx, action); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to notify integrations", err)
		// Ne pas Ã©chouer la capture pour une erreur de notification
	}

	// 3. Enregistrer les mÃ©triques
	if err := cmm.monitoringManager.RecordOperation(ctx, "action_capture", time.Since(start), nil); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record action capture metrics", err)
	}

	return nil
}

func (cmm *contextualMemoryManagerImpl) SearchContext(ctx context.Context, query interfaces.ContextQuery) ([]interfaces.ContextResult, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	start := time.Now()

	// Utiliser le retrieval manager pour la recherche contextuelle
	results, err := cmm.retrievalManager.SearchContext(ctx, query)
	if err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Context search failed", err)
		if err := cmm.monitoringManager.RecordOperation(ctx, "context_search", time.Since(start), err); err != nil {
			cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record search metrics", err)
		}
		return nil, fmt.Errorf("context search failed: %w", err)
	}

	// Enregistrer les mÃ©triques de succÃ¨s
	if err := cmm.monitoringManager.RecordOperation(ctx, "context_search", time.Since(start), nil); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record search metrics", err)
	}

	return results, nil
}

func (cmm *contextualMemoryManagerImpl) UpdateContext(ctx context.Context, contextID string, updates interfaces.ContextUpdate) error {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return fmt.Errorf("manager not initialized")
	}

	start := time.Now()

	// Mettre Ã  jour via le retrieval manager
	if err := cmm.retrievalManager.UpdateContext(ctx, contextID, updates); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Context update failed", err)
		if err := cmm.monitoringManager.RecordOperation(ctx, "context_update", time.Since(start), err); err != nil {
			cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record update metrics", err)
		}
		return fmt.Errorf("context update failed: %w", err)
	}

	// Notifier les intÃ©grations de la mise Ã  jour
	if err := cmm.integrationManager.NotifyContextUpdate(ctx, contextID, updates); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to notify context update", err)
		// Ne pas Ã©chouer la mise Ã  jour pour une erreur de notification
	}

	// Enregistrer les mÃ©triques
	if err := cmm.monitoringManager.RecordOperation(ctx, "context_update", time.Since(start), nil); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record update metrics", err)
	}

	return nil
}

func (cmm *contextualMemoryManagerImpl) GetContextHistory(ctx context.Context, userID string, limit int) ([]interfaces.ContextResult, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	start := time.Now()

	// RÃ©cupÃ©rer l'historique via le retrieval manager
	history, err := cmm.retrievalManager.GetContextHistory(ctx, userID, limit)
	if err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to get context history", err)
		if err := cmm.monitoringManager.RecordOperation(ctx, "get_history", time.Since(start), err); err != nil {
			cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record history metrics", err)
		}
		return nil, fmt.Errorf("failed to get context history: %w", err)
	}

	// Enregistrer les mÃ©triques
	if err := cmm.monitoringManager.RecordOperation(ctx, "get_history", time.Since(start), nil); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record history metrics", err)
	}

	return history, nil
}

func (cmm *contextualMemoryManagerImpl) DeleteContext(ctx context.Context, contextID string) error {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return fmt.Errorf("manager not initialized")
	}

	start := time.Now()

	// Supprimer du retrieval manager
	if err := cmm.retrievalManager.DeleteContext(ctx, contextID); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to delete context", err)
		if err := cmm.monitoringManager.RecordOperation(ctx, "delete_context", time.Since(start), err); err != nil {
			cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record delete metrics", err)
		}
		return fmt.Errorf("failed to delete context: %w", err)
	}

	// Supprimer de l'index
	if err := cmm.indexManager.DeleteFromIndex(ctx, contextID); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to delete from index", err)
		// Ne pas Ã©chouer la suppression pour une erreur d'index
	}

	// Notifier les intÃ©grations
	if err := cmm.integrationManager.NotifyContextDeletion(ctx, contextID); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to notify context deletion", err)
		// Ne pas Ã©chouer la suppression pour une erreur de notification
	}

	// Enregistrer les mÃ©triques
	if err := cmm.monitoringManager.RecordOperation(ctx, "delete_context", time.Since(start), nil); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record delete metrics", err)
	}

	return nil
}

func (cmm *contextualMemoryManagerImpl) GetMetrics(ctx context.Context) (interfaces.ManagerMetrics, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return interfaces.ManagerMetrics{}, fmt.Errorf("manager not initialized")
	}

	// RÃ©cupÃ©rer les mÃ©triques du monitoring manager
	return cmm.monitoringManager.GetMetrics(ctx)
}

// MÃ©thodes manquantes pour l'interface complÃ¨te
func (cmm *contextualMemoryManagerImpl) BatchCaptureActions(ctx context.Context, actions []interfaces.Action) error {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return fmt.Errorf("manager not initialized")
	}

	for _, action := range actions {
		if err := cmm.CaptureAction(ctx, action); err != nil {
			return fmt.Errorf("failed to capture action %s: %w", action.ID, err)
		}
	}

	return nil
}

func (cmm *contextualMemoryManagerImpl) GetActionHistory(ctx context.Context, workspacePath string, limit int) ([]interfaces.Action, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	// Convertir les rÃ©sultats de contexte en actions
	query := interfaces.ContextQuery{
		WorkspacePath: workspacePath,
		Limit:         limit,
	}

	results, err := cmm.retrievalManager.SearchContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get action history: %w", err)
	}

	actions := make([]interfaces.Action, len(results))
	for i, result := range results {
		actions[i] = result.Action
	}

	return actions, nil
}

func (cmm *contextualMemoryManagerImpl) StartSession(ctx context.Context, workspacePath string) (string, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return "", fmt.Errorf("manager not initialized")
	}

	// GÃ©nÃ©rer un ID de session unique
	sessionID := fmt.Sprintf("session_%d", time.Now().UnixNano())

	// Incrementer le compteur de sessions actives
	if err := cmm.monitoringManager.IncrementActiveSession(ctx); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to increment active session count", err)
	}

	return sessionID, nil
}

func (cmm *contextualMemoryManagerImpl) EndSession(ctx context.Context, sessionID string) error {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return fmt.Errorf("manager not initialized")
	}

	// DÃ©crementer le compteur de sessions actives
	if err := cmm.monitoringManager.DecrementActiveSession(ctx); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to decrement active session count", err)
	}

	return nil
}

func (cmm *contextualMemoryManagerImpl) GetSessionActions(ctx context.Context, sessionID string) ([]interfaces.Action, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	// Pour l'instant, retourner une liste vide
	// Dans une implÃ©mentation complÃ¨te, cela rechercherait les actions par session
	return []interfaces.Action{}, nil
}

func (cmm *contextualMemoryManagerImpl) AnalyzePatternsUsage(ctx context.Context, workspacePath string) (map[string]interface{}, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	// Analyse basique des patterns d'utilisation
	patterns := map[string]interface{}{
		"workspace_path":     workspacePath,
		"analysis_timestamp": time.Now(),
		"patterns":           map[string]interface{}{},
	}

	// Obtenir les mÃ©triques actuelles
	metrics, err := cmm.monitoringManager.GetMetrics(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get metrics for pattern analysis: %w", err)
	}

	patterns["total_actions"] = metrics.TotalActions
	patterns["active_sessions"] = metrics.ActiveSessions
	patterns["cache_hit_ratio"] = metrics.CacheHitRatio

	return patterns, nil
}

func (cmm *contextualMemoryManagerImpl) GetSimilarActions(ctx context.Context, actionID string, limit int) ([]interfaces.ContextResult, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	// Utiliser le retrieval manager pour trouver des actions similaires
	// Pour l'instant, retourner une liste vide
	// Dans une implÃ©mentation complÃ¨te, cela utiliserait l'index manager pour la similaritÃ© vectorielle

	return []interfaces.ContextResult{}, nil
}
