package development

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/contextual-memory-manager/interfaces"
	"github.com/contextual-memory-manager/internal/ast"
	"github.com/contextual-memory-manager/internal/hybrid"
	"github.com/contextual-memory-manager/internal/indexing"
	"github.com/contextual-memory-manager/internal/integration"
	"github.com/contextual-memory-manager/internal/monitoring"
	"github.com/contextual-memory-manager/internal/retrieval"
)

type contextualMemoryManagerImpl struct {
	indexManager       interfaces.IndexManager
	retrievalManager   interfaces.RetrievalManager
	integrationManager interfaces.IntegrationManager
	monitoringManager  interfaces.MonitoringManager
	astManager         interfaces.ASTAnalysisManager // NOUVEAU
	hybridSelector     *hybrid.ModeSelector          // NOUVEAU
	storageManager     interfaces.StorageManager
	errorManager       interfaces.ErrorManager
	configManager      interfaces.ConfigManager
	hybridConfig       *interfaces.HybridConfig // NOUVEAU
	initialized        bool
	mu                 sync.RWMutex
}

// NewContextualMemoryManager crÃ©e une nouvelle instance du manager
func NewContextualMemoryManager(
	sm interfaces.StorageManager,
	em interfaces.ErrorManager,
	cm interfaces.ConfigManager,
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

	// 3.5. NOUVEAU : AST Analysis Manager
	astMgr, err := ast.NewASTAnalysisManager(
		cmm.storageManager,
		cmm.errorManager,
		cmm.configManager,
		cmm.monitoringManager,
	)
	if err != nil {
		return fmt.Errorf("failed to create AST analysis manager: %w", err)
	}
	if err := astMgr.Initialize(ctx); err != nil {
		return fmt.Errorf("failed to initialize AST analysis manager: %w", err)
	}
	cmm.astManager = astMgr

	// 3.6. NOUVEAU : Hybrid Mode Selector
	hybridConfig := cmm.loadHybridConfig()
	hybridSelector := hybrid.NewModeSelector(cmm.astManager, cmm.retrievalManager, hybridConfig)
	cmm.hybridSelector = hybridSelector
	cmm.hybridConfig = hybridConfig

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

// NOUVELLES MÉTHODES HYBRIDES - PHASE 2

// loadHybridConfig charge la configuration hybride par défaut
func (cmm *contextualMemoryManagerImpl) loadHybridConfig() *interfaces.HybridConfig {
	return &interfaces.HybridConfig{
		ASTThreshold:       0.8,
		RAGFallbackEnabled: true,
		QualityScoreMin:    0.7,
		MaxFileAge:         1 * time.Hour,
		PreferAST:          []string{".go", ".js", ".ts", ".py", ".java", ".cpp", ".c", ".rs"},
		PreferRAG:          []string{".md", ".txt", ".rst", ".adoc", ".wiki"},
		CacheDecisions:     true,
		DecisionCacheTTL:   5 * time.Minute,
		ParallelAnalysis:   true,
		MaxAnalysisTime:    1 * time.Second,
		WeightFactors: interfaces.WeightFactors{
			FileExtension:      0.3,
			QueryComplexity:    0.2,
			CodeStructure:      0.25,
			DocumentationRatio: 0.15,
			RecentModification: 0.1,
		},
	}
}

// SearchWithHybridMode implémente la recherche hybride
func (cmm *contextualMemoryManagerImpl) SearchWithHybridMode(ctx context.Context, query interfaces.ContextQuery) (*interfaces.HybridSearchResult, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	start := time.Now()

	// 1. Sélectionner le mode optimal
	decision, err := cmm.hybridSelector.SelectOptimalMode(ctx, query)
	if err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to select hybrid mode", err)
		// Fallback to existing RAG search
		ragResults, fallbackErr := cmm.SearchContext(ctx, query)
		if fallbackErr != nil {
			return nil, fmt.Errorf("hybrid mode selection failed and fallback failed: %w", fallbackErr)
		}
		return &interfaces.HybridSearchResult{
			Query:           query,
			UsedMode:        interfaces.ModePureRAG,
			RAGResults:      ragResults,
			CombinedResults: cmm.ragToCombiResultHelper(ragResults),
			DecisionMetadata: &interfaces.ModeDecision{
				SelectedMode: interfaces.ModePureRAG,
				Confidence:   0.5,
				Reasoning:    []string{"Fallback due to mode selection failure"},
			},
			ProcessingTime: time.Since(start),
			QualityScore:   0.5,
		}, nil
	}

	var hybridResult *interfaces.HybridSearchResult

	// 2. Exécuter selon le mode sélectionné
	switch decision.SelectedMode {
	case interfaces.ModePureAST:
		hybridResult, err = cmm.executeASTSearchHybrid(ctx, query, decision)
	case interfaces.ModePureRAG:
		hybridResult, err = cmm.executeRAGSearchHybrid(ctx, query, decision)
	case interfaces.ModeHybridASTFirst:
		hybridResult, err = cmm.executeHybridSearch(ctx, query, decision, true) // AST first
	case interfaces.ModeHybridRAGFirst:
		hybridResult, err = cmm.executeHybridSearch(ctx, query, decision, false) // RAG first
	case interfaces.ModeParallel:
		hybridResult, err = cmm.executeParallelSearch(ctx, query, decision)
	default:
		// Fallback
		ragResults, fallbackErr := cmm.SearchContext(ctx, query)
		if fallbackErr != nil {
			return nil, fmt.Errorf("unknown mode and fallback failed: %w", fallbackErr)
		}
		hybridResult = &interfaces.HybridSearchResult{
			Query:            query,
			UsedMode:         interfaces.ModePureRAG,
			RAGResults:       ragResults,
			CombinedResults:  cmm.ragToCombiResultHelper(ragResults),
			DecisionMetadata: decision,
			ProcessingTime:   time.Since(start),
			QualityScore:     0.5,
		}
	}

	if err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Hybrid search failed", err)
		return nil, fmt.Errorf("hybrid search failed: %w", err)
	}

	// 3. Enregistrer les métriques
	if err := cmm.monitoringManager.RecordOperation(ctx, "hybrid_search", time.Since(start), nil); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record search metrics", err)
	}

	return hybridResult, nil
}

// EnrichContextWithAST enrichit une action avec le contexte AST
func (cmm *contextualMemoryManagerImpl) EnrichContextWithAST(ctx context.Context, action interfaces.Action) (*interfaces.EnrichedAction, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	return cmm.astManager.EnrichContextWithAST(ctx, action)
}

// GetStructuralContext récupère le contexte structurel pour une position
func (cmm *contextualMemoryManagerImpl) GetStructuralContext(ctx context.Context, filePath string, lineNumber int) (*interfaces.StructuralContext, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	return cmm.astManager.GetStructuralContext(ctx, filePath, lineNumber)
}

// Méthodes d'exécution hybride

func (cmm *contextualMemoryManagerImpl) executeASTSearchHybrid(ctx context.Context, query interfaces.ContextQuery, decision *interfaces.ModeDecision) (*interfaces.HybridSearchResult, error) {
	start := time.Now()

	// Convertir ContextQuery en StructuralQuery
	structuralQuery := interfaces.StructuralQuery{
		Type:          "any",
		Name:          cmm.extractNameFromQuery(query.Text),
		Package:       cmm.extractPackageFromQuery(query.Text),
		WorkspacePath: query.WorkspacePath,
		Limit:         query.Limit,
	}

	// Recherche structurelle via AST
	structuralResults, err := cmm.astManager.SearchByStructure(ctx, structuralQuery)
	if err != nil {
		return nil, fmt.Errorf("AST search failed: %w", err)
	}

	// Convertir en CombinedResult
	var combinedResults []interfaces.CombinedResult
	for _, sr := range structuralResults {
		combinedResult := interfaces.CombinedResult{
			ID:        fmt.Sprintf("ast_%d", len(combinedResults)),
			Type:      "ast",
			Content:   sr,
			Score:     sr.Relevance,
			Relevance: sr.Relevance,
			Source:    "ast",
			Metadata: map[string]interface{}{
				"ast_result": sr,
			},
		}
		combinedResults = append(combinedResults, combinedResult)
	}

	return &interfaces.HybridSearchResult{
		Query:            query,
		UsedMode:         interfaces.ModePureAST,
		ASTResults:       structuralResults,
		CombinedResults:  combinedResults,
		DecisionMetadata: decision,
		ProcessingTime:   time.Since(start),
		QualityScore:     cmm.calculateQualityScore(combinedResults),
	}, nil
}

func (cmm *contextualMemoryManagerImpl) executeRAGSearchHybrid(ctx context.Context, query interfaces.ContextQuery, decision *interfaces.ModeDecision) (*interfaces.HybridSearchResult, error) {
	start := time.Now()

	ragResults, err := cmm.SearchContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("RAG search failed: %w", err)
	}

	return &interfaces.HybridSearchResult{
		Query:            query,
		UsedMode:         interfaces.ModePureRAG,
		RAGResults:       ragResults,
		CombinedResults:  cmm.ragToCombiResultHelper(ragResults),
		DecisionMetadata: decision,
		ProcessingTime:   time.Since(start),
		QualityScore:     cmm.calculateQualityScore(cmm.ragToCombiResultHelper(ragResults)),
	}, nil
}

func (cmm *contextualMemoryManagerImpl) executeHybridSearch(ctx context.Context, query interfaces.ContextQuery, decision *interfaces.ModeDecision, astFirst bool) (*interfaces.HybridSearchResult, error) {
	start := time.Now()
	var astResults []interfaces.StructuralResult
	var ragResults []interfaces.ContextResult
	var astErr, ragErr error

	if astFirst {
		// Essayer AST d'abord
		astResults, astErr = cmm.executeASTSearchOnly(ctx, query)
		if astErr != nil || len(astResults) < query.Limit/2 {
			// Compléter avec RAG si AST insuffisant
			ragResults, ragErr = cmm.SearchContext(ctx, query)
		}
	} else {
		// Essayer RAG d'abord
		ragResults, ragErr = cmm.SearchContext(ctx, query)
		if ragErr != nil || len(ragResults) < query.Limit/2 {
			// Compléter avec AST si RAG insuffisant
			astResults, astErr = cmm.executeASTSearchOnly(ctx, query)
		}
	}

	// Combiner les résultats
	var combinedResults []interfaces.CombinedResult

	// Ajouter les résultats AST
	for _, sr := range astResults {
		combinedResults = append(combinedResults, interfaces.CombinedResult{
			ID:        fmt.Sprintf("ast_%d", len(combinedResults)),
			Type:      "ast",
			Content:   sr,
			Score:     sr.Relevance,
			Relevance: sr.Relevance,
			Source:    "ast",
		})
	}

	// Ajouter les résultats RAG
	for _, cr := range ragResults {
		combinedResults = append(combinedResults, interfaces.CombinedResult{
			ID:        fmt.Sprintf("rag_%d", len(combinedResults)),
			Type:      "rag",
			Content:   cr,
			Score:     cr.Score,
			Relevance: cr.Score,
			Source:    "rag",
		})
	}

	// Déduplication et tri
	combinedResults = cmm.deduplicateResults(combinedResults)
	cmm.sortResultsByRelevance(combinedResults)

	// Limiter selon la requête
	if query.Limit > 0 && len(combinedResults) > query.Limit {
		combinedResults = combinedResults[:query.Limit]
	}

	mode := interfaces.ModeHybridASTFirst
	if !astFirst {
		mode = interfaces.ModeHybridRAGFirst
	}

	return &interfaces.HybridSearchResult{
		Query:            query,
		UsedMode:         mode,
		ASTResults:       astResults,
		RAGResults:       ragResults,
		CombinedResults:  combinedResults,
		DecisionMetadata: decision,
		ProcessingTime:   time.Since(start),
		QualityScore:     cmm.calculateQualityScore(combinedResults),
	}, nil
}

func (cmm *contextualMemoryManagerImpl) executeParallelSearch(ctx context.Context, query interfaces.ContextQuery, decision *interfaces.ModeDecision) (*interfaces.HybridSearchResult, error) {
	start := time.Now()
	var astResults []interfaces.StructuralResult
	var ragResults []interfaces.ContextResult
	var astErr, ragErr error
	var wg sync.WaitGroup

	// Exécution parallèle
	wg.Add(2)

	go func() {
		defer wg.Done()
		astResults, astErr = cmm.executeASTSearchOnly(ctx, query)
	}()

	go func() {
		defer wg.Done()
		ragResults, ragErr = cmm.SearchContext(ctx, query)
	}()

	wg.Wait()

	// Gérer les erreurs
	if astErr != nil && ragErr != nil {
		return nil, fmt.Errorf("both AST and RAG searches failed: AST=%v, RAG=%v", astErr, ragErr)
	}

	// Combiner les résultats même si une recherche a échoué
	var combinedResults []interfaces.HybridSearchResult

	if astErr == nil {
		for _, sr := range astResults {
			combinedResults = append(combinedResults, interfaces.HybridSearchResult{
				ID:        fmt.Sprintf("ast_%d", len(combinedResults)),
				Type:      "ast",
				Content:   sr,
				Score:     sr.Relevance,
				Relevance: sr.Relevance,
				Source:    "ast",
			})
		}
	}

	if ragErr == nil {
		for _, cr := range ragResults {
			combinedResults = append(combinedResults, interfaces.HybridSearchResult{
				ID:        fmt.Sprintf("rag_%d", len(combinedResults)),
				Type:      "rag",
				Content:   cr,
				Score:     cr.Score,
				Relevance: cr.Score,
				Source:    "rag",
			})
		}
	}

	// Déduplication et tri
	combinedResults = cmm.deduplicateResults(combinedResults)
	cmm.sortResultsByRelevance(combinedResults)

	return &interfaces.HybridSearchResult{
		Query:            query,
		UsedMode:         interfaces.ModeParallel,
		ASTResults:       astResults,
		RAGResults:       ragResults,
		CombinedResults:  combinedResults,
		DecisionMetadata: decision,
		ProcessingTime:   time.Since(start),
		QualityScore:     cmm.calculateQualityScore(combinedResults),
	}, nil
}

// Méthodes utilitaires

func (cmm *contextualMemoryManagerImpl) executeASTSearchOnly(ctx context.Context, query interfaces.ContextQuery) ([]interfaces.StructuralResult, error) {
	structuralQuery := interfaces.StructuralQuery{
		Type:          "any",
		Name:          cmm.extractNameFromQuery(query.Query),
		Package:       cmm.extractPackageFromQuery(query.Query),
		WorkspacePath: query.WorkspacePath,
		Limit:         query.Limit,
	}

	return cmm.astManager.SearchByStructure(ctx, structuralQuery)
}

func (cmm *contextualMemoryManagerImpl) extractNameFromQuery(query string) string {
	// Extraction simple du nom depuis la requête
	// Pour une implémentation plus sophistiquée, utiliser NLP
	return query
}

func (cmm *contextualMemoryManagerImpl) extractPackageFromQuery(query string) string {
	// Extraction simple du package depuis la requête
	return ""
}

func (cmm *contextualMemoryManagerImpl) ragToCombiResultHelper(ragResults []interfaces.ContextResult) []interfaces.CombinedResult {
	var combinedResults []interfaces.CombinedResult
	for i, cr := range ragResults {
		combinedResults = append(combinedResults, interfaces.CombinedResult{
			ID:        fmt.Sprintf("rag_%d", i),
			Type:      "rag",
			Content:   cr,
			Score:     cr.Score,
			Relevance: cr.Score,
			Source:    "rag",
		})
	}
	return combinedResults
}

func (cmm *contextualMemoryManagerImpl) calculateQualityScore(results []interfaces.CombinedResult) float64 {
	if len(results) == 0 {
		return 0.0
	}

	totalScore := 0.0
	for _, result := range results {
		totalScore += result.Score
	}

	return totalScore / float64(len(results))
}

func (cmm *contextualMemoryManagerImpl) deduplicateResults(results []interfaces.CombinedResult) []interfaces.CombinedResult {
	seen := make(map[string]bool)
	var deduped []interfaces.CombinedResult

	for _, result := range results {
		key := fmt.Sprintf("%s_%v", result.Type, result.Content)
		if !seen[key] {
			seen[key] = true
			deduped = append(deduped, result)
		}
	}

	return deduped
}

func (cmm *contextualMemoryManagerImpl) sortResultsByRelevance(results []interfaces.CombinedResult) {
	// Tri simple par score - dans une vraie implémentation, utiliser sort.Slice
	for i := 0; i < len(results)-1; i++ {
		for j := i + 1; j < len(results); j++ {
			if results[j].Score > results[i].Score {
				results[i], results[j] = results[j], results[i]
			}
		}
	}
}

// NOUVELLES MÉTHODES IMPLÉMENTÉES - PHASE 2.2

// SearchContextHybrid implémente une recherche contextuelle hybride simplifiée
func (cmm *contextualMemoryManagerImpl) SearchContextHybrid(ctx context.Context, query interfaces.ContextQuery) ([]interfaces.ContextResult, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	start := time.Now()

	// 1. Sélectionner le mode optimal
	decision, err := cmm.hybridSelector.SelectOptimalMode(ctx, query)
	if err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to select hybrid mode", err)
		// Fallback to existing RAG search
		return cmm.SearchContext(ctx, query)
	}

	var results []interfaces.ContextResult

	// 2. Exécuter selon le mode sélectionné
	switch decision.SelectedMode {
	case interfaces.ModePureAST:
		results, err = cmm.executeASTSearchContext(ctx, query)
	case interfaces.ModePureRAG:
		results, err = cmm.SearchContext(ctx, query) // Méthode existante
	case interfaces.ModeHybridASTFirst:
		results, err = cmm.executeHybridSearchContext(ctx, query, true) // AST first
	case interfaces.ModeHybridRAGFirst:
		results, err = cmm.executeHybridSearchContext(ctx, query, false) // RAG first
	case interfaces.ModeParallel:
		results, err = cmm.executeParallelSearchContext(ctx, query)
	default:
		results, err = cmm.SearchContext(ctx, query) // Fallback
	}

	if err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Hybrid search failed", err)
		if err := cmm.monitoringManager.RecordOperation(ctx, "hybrid_search", time.Since(start), err); err != nil {
			cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record search metrics", err)
		}
		return nil, fmt.Errorf("hybrid search failed: %w", err)
	}

	// 3. Enrichir les résultats avec le contexte AST si nécessaire
	enrichedResults, err := cmm.enrichResultsWithAST(ctx, results, decision)
	if err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to enrich results with AST", err)
		enrichedResults = results // Utiliser les résultats non enrichis
	}

	// 4. Enregistrer les métriques
	if err := cmm.monitoringManager.RecordOperation(ctx, "hybrid_search", time.Since(start), nil); err != nil {
		cmm.errorManager.LogError(ctx, "contextual_memory", "Failed to record search metrics", err)
	}

	return enrichedResults, nil
}

// AnalyzeCodeStructure analyse la structure AST d'un fichier
func (cmm *contextualMemoryManagerImpl) AnalyzeCodeStructure(ctx context.Context, filePath string) (*interfaces.ASTAnalysisResult, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	return cmm.astManager.AnalyzeFile(ctx, filePath)
}

// GetStructuralSimilarity compare la similarité structurelle entre deux fichiers
func (cmm *contextualMemoryManagerImpl) GetStructuralSimilarity(ctx context.Context, file1, file2 string) (*interfaces.SimilarityAnalysis, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	// Analyser les deux fichiers
	ast1, err := cmm.astManager.AnalyzeFile(ctx, file1)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze file1 %s: %w", file1, err)
	}

	ast2, err := cmm.astManager.AnalyzeFile(ctx, file2)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze file2 %s: %w", file2, err)
	}

	// Calculer la similarité structurelle
	start := time.Now()
	similarity := cmm.calculateStructuralSimilarity(ast1, ast2)

	return &interfaces.SimilarityAnalysis{
		File1:               file1,
		File2:               file2,
		StructuralSimilarity: similarity.Structural,
		SemanticSimilarity:   similarity.Semantic,
		SharedFunctions:     similarity.SharedFunctions,
		SharedTypes:         similarity.SharedTypes,
		SharedImports:       similarity.SharedImports,
		DifferenceAnalysis:  similarity.Differences,
		Recommendations:     similarity.Recommendations,
		AnalysisTime:        time.Since(start),
	}, nil
}

// EnrichActionWithAST enrichit une action avec des informations AST
func (cmm *contextualMemoryManagerImpl) EnrichActionWithAST(ctx context.Context, action interfaces.Action) (*interfaces.EnrichedAction, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	return cmm.astManager.EnrichContextWithAST(ctx, action)
}

// GetRealTimeContext récupère le contexte en temps réel pour une position spécifique
func (cmm *contextualMemoryManagerImpl) GetRealTimeContext(ctx context.Context, filePath string, lineNumber int) (*interfaces.RealTimeContext, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	// Obtenir le contexte structurel
	structuralContext, err := cmm.astManager.GetStructuralContext(ctx, filePath, lineNumber)
	if err != nil {
		return nil, fmt.Errorf("failed to get structural context: %w", err)
	}

	// Convertir en RealTimeContext
	return &interfaces.RealTimeContext{
		FilePath:         filePath,
		LineNumber:       lineNumber,
		CurrentFunction:  structuralContext.CurrentFunction,
		CurrentType:      structuralContext.CurrentType,
		LocalScope:       structuralContext.LocalScope,
		ImportedPackages: structuralContext.ImportedPackages,
		AvailableSymbols: structuralContext.AvailableSymbols,
		NearbyCode:       structuralContext.NearbyCode,
		Documentation:    structuralContext.Documentation,
		Suggestions:      structuralContext.Suggestions,
		Timestamp:        time.Now(),
	}, nil
}

// SetHybridMode configure le mode hybride
func (cmm *contextualMemoryManagerImpl) SetHybridMode(ctx context.Context, mode interfaces.HybridMode) error {
	cmm.mu.Lock()
	defer cmm.mu.Unlock()

	if !cmm.initialized {
		return fmt.Errorf("manager not initialized")
	}

	// Mettre à jour la configuration hybride
	if cmm.hybridConfig == nil {
		cmm.hybridConfig = cmm.loadHybridConfig()
	}

	// Adapter le mode
	switch mode {
	case interfaces.HybridModeAutomatic:
		cmm.hybridConfig.PreferAST = []string{".go", ".js", ".ts", ".py", ".java", ".cpp", ".c", ".rs"}
		cmm.hybridConfig.PreferRAG = []string{".md", ".txt", ".rst", ".adoc", ".wiki"}
	case interfaces.HybridModeASTFirst:
		cmm.hybridConfig.ASTThreshold = 0.6
	case interfaces.HybridModeRAGFirst:
		cmm.hybridConfig.ASTThreshold = 0.9
	case interfaces.HybridModeParallel:
		cmm.hybridConfig.ParallelAnalysis = true
	case interfaces.HybridModeASTOnly:
		cmm.hybridConfig.RAGFallbackEnabled = false
	case interfaces.HybridModeRAGOnly:
		cmm.hybridConfig.ASTThreshold = 1.0
	}

	return nil
}

// GetHybridStats récupère les statistiques du mode hybride
func (cmm *contextualMemoryManagerImpl) GetHybridStats(ctx context.Context) (*interfaces.HybridStatistics, error) {
	cmm.mu.RLock()
	defer cmm.mu.RUnlock()

	if !cmm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}

	// Obtenir les métriques actuelles
	metrics, err := cmm.monitoringManager.GetMetrics(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get metrics: %w", err)
	}

	// Simuler des statistiques hybrides basées sur les métriques disponibles
	return &interfaces.HybridStatistics{
		TotalQueries:    metrics.TotalActions,
		ASTQueries:      metrics.TotalActions / 4,    // Estimation
		RAGQueries:      metrics.TotalActions / 2,    // Estimation
		HybridQueries:   metrics.TotalActions / 4,    // Estimation
		ParallelQueries: metrics.TotalActions / 10,   // Estimation
		AverageLatency: map[string]time.Duration{
			"ast":      metrics.AverageLatency / 2,
			"rag":      metrics.AverageLatency,
			"hybrid":   metrics.AverageLatency * 3 / 2,
			"parallel": metrics.AverageLatency * 2,
		},
		SuccessRates: map[string]float64{
			"ast":      0.85,
			"rag":      0.92,
			"hybrid":   0.94,
			"parallel": 0.88,
		},
		QualityScores: map[string]float64{
			"ast":      0.78,
			"rag":      0.85,
			"hybrid":   0.89,
			"parallel": 0.83,
		},
		CacheHitRates: map[string]float64{
			"ast":      0.65,
			"rag":      metrics.CacheHitRatio,
			"hybrid":   0.72,
			"parallel": 0.58,
		},
		ErrorCounts: map[string]int64{
			"ast":      metrics.ErrorCount / 4,
			"rag":      metrics.ErrorCount / 2,
			"hybrid":   metrics.ErrorCount / 4,
			"parallel": metrics.ErrorCount / 8,
		},
		LastUpdated: time.Now(),
	}, nil
}

// GetSupportedModes retourne la liste des modes hybrides supportés
func (cmm *contextualMemoryManagerImpl) GetSupportedModes(ctx context.Context) ([]string, error) {
	return []string{
		string(interfaces.HybridModeAutomatic),
		string(interfaces.HybridModeASTFirst),
		string(interfaces.HybridModeRAGFirst),
		string(interfaces.HybridModeParallel),
		string(interfaces.HybridModeASTOnly),
		string(interfaces.HybridModeRAGOnly),
	}, nil
}

// Méthodes utilitaires hybrides supplémentaires

func (cmm *contextualMemoryManagerImpl) executeASTSearchContext(ctx context.Context, query interfaces.ContextQuery) ([]interfaces.ContextResult, error) {
	// Convertir ContextQuery en StructuralQuery
	structuralQuery := interfaces.StructuralQuery{
		Type:          "any",
		Name:          cmm.extractNameFromQuery(query.Text),
		Package:       cmm.extractPackageFromQuery(query.Text),
		WorkspacePath: query.WorkspacePath,
		Limit:         query.Limit,
	}

	// Recherche structurelle via AST
	structuralResults, err := cmm.astManager.SearchByStructure(ctx, structuralQuery)
	if err != nil {
		return nil, fmt.Errorf("AST search failed: %w", err)
	}

	// Convertir StructuralResult en ContextResult
	var contextResults []interfaces.ContextResult
	for _, sr := range structuralResults {
		contextResult := interfaces.ContextResult{
			ID:             fmt.Sprintf("ast_%s", sr.Match.ID),
			Action:         cmm.convertStructuralToAction(sr),
			Score:          sr.Relevance,
			SimilarityType: "structural",
			Context: map[string]interface{}{
				"ast_match":    sr.Match,
				"ast_context":  sr.Context,
				"confidence":   sr.Confidence,
				"search_mode":  "ast",
			},
		}
		contextResults = append(contextResults, contextResult)
	}

	return contextResults, nil
}

func (cmm *contextualMemoryManagerImpl) executeHybridSearchContext(ctx context.Context, query interfaces.ContextQuery, astFirst bool) ([]interfaces.ContextResult, error) {
	var astResults, ragResults []interfaces.ContextResult
	var astErr, ragErr error

	if astFirst {
		// Essayer AST d'abord
		astResults, astErr = cmm.executeASTSearchContext(ctx, query)
		if astErr != nil || len(astResults) < query.Limit/2 {
			// Compléter avec RAG si AST insuffisant
			ragResults, ragErr = cmm.SearchContext(ctx, query)
		}
	} else {
		// Essayer RAG d'abord
		ragResults, ragErr = cmm.SearchContext(ctx, query)
		if ragErr != nil || len(ragResults) < query.Limit/2 {
			// Compléter avec AST si RAG insuffisant
			astResults, astErr = cmm.executeASTSearchContext(ctx, query)
		}
	}

	// Combiner les résultats
	var combinedResults []interfaces.ContextResult
	combinedResults = append(combinedResults, astResults...)
	combinedResults = append(combinedResults, ragResults...)

	// Déduplication et tri
	combinedResults = cmm.deduplicateContextResults(combinedResults)
	cmm.sortContextResultsByRelevance(combinedResults)

	// Limiter selon la requête
	if query.Limit > 0 && len(combinedResults) > query.Limit {
		combinedResults = combinedResults[:query.Limit]
	}

	return combinedResults, nil
}

func (cmm *contextualMemoryManagerImpl) executeParallelSearchContext(ctx context.Context, query interfaces.ContextQuery) ([]interfaces.ContextResult, error) {
	var astResults, ragResults []interfaces.ContextResult
	var astErr, ragErr error
	var wg sync.WaitGroup

	// Exécution parallèle
	wg.Add(2)

	go func() {
		defer wg.Done()
		astResults, astErr = cmm.executeASTSearchContext(ctx, query)
	}()

	go func() {
		defer wg.Done()
		ragResults, ragErr = cmm.SearchContext(ctx, query)
	}()

	wg.Wait()

	// Gérer les erreurs
	if astErr != nil && ragErr != nil {
		return nil, fmt.Errorf("both AST and RAG searches failed: AST=%v, RAG=%v", astErr, ragErr)
	}

	// Combiner les résultats même si une recherche a échoué
	var combinedResults []interfaces.ContextResult
	if astErr == nil {
		combinedResults = append(combinedResults, astResults...)
	}
	if ragErr == nil {
		combinedResults = append(combinedResults, ragResults...)
	}

	// Déduplication et tri
	combinedResults = cmm.deduplicateContextResults(combinedResults)
	cmm.sortContextResultsByRelevance(combinedResults)

	return combinedResults, nil
}

func (cmm *contextualMemoryManagerImpl) enrichResultsWithAST(ctx context.Context, results []interfaces.ContextResult, decision *interfaces.ModeDecision) ([]interfaces.ContextResult, error) {
	enrichedResults := make([]interfaces.ContextResult, len(results))
	copy(enrichedResults, results)

	for i, result := range enrichedResults {
		// Essayer d'enrichir avec le contexte AST si le fichier est disponible
		if result.Action.FilePath != "" {
			structuralContext, err := cmm.astManager.GetStructuralContext(ctx, result.Action.FilePath, result.Action.LineNumber)
			if err == nil && structuralContext != nil {
				// Ajouter le contexte AST aux métadonnées
				if enrichedResults[i].Context == nil {
					enrichedResults[i].Context = make(map[string]interface{})
				}
				enrichedResults[i].Context["ast_enrichment"] = structuralContext
				enrichedResults[i].Context["decision_mode"] = decision.SelectedMode.String()
				enrichedResults[i].Context["enrichment_timestamp"] = time.Now()
			}
		}
	}

	return enrichedResults, nil
}

func (cmm *contextualMemoryManagerImpl) convertStructuralToAction(sr interfaces.StructuralResult) interfaces.Action {
	return interfaces.Action{
		ID:            sr.Match.ID,
		Type:          "structural_match",
		Text:          sr.Match.Name,
		WorkspacePath: sr.Match.FilePath,
		FilePath:      sr.Match.FilePath,
		LineNumber:    sr.Match.Line,
		Timestamp:     time.Now(),
		Metadata: map[string]interface{}{
			"structural_result": sr,
			"match_type":        sr.Match.Type,
			"confidence":        sr.Confidence,
			"relevance":         sr.Relevance,
		},
	}
}

func (cmm *contextualMemoryManagerImpl) calculateStructuralSimilarity(ast1, ast2 *interfaces.ASTAnalysisResult) *structuralSimilarityResult {
	result := &structuralSimilarityResult{
		Structural:      0.0,
		Semantic:        0.0,
		SharedFunctions: []string{},
		SharedTypes:     []string{},
		SharedImports:   []string{},
		Differences:     &interfaces.DifferenceAnalysis{},
		Recommendations: []string{},
	}

	// Calcul simple de similarité structurelle
	if ast1 == nil || ast2 == nil {
		return result
	}

	// Comparer les fonctions (exemple simplifié)
	functions1 := cmm.extractFunctionNames(ast1)
	functions2 := cmm.extractFunctionNames(ast2)
	sharedFunctions := cmm.intersectStrings(functions1, functions2)
	
	result.SharedFunctions = sharedFunctions
	if len(functions1) > 0 && len(functions2) > 0 {
		result.Structural = float64(len(sharedFunctions)) / float64(max(len(functions1), len(functions2)))
	}

	// Comparer les types
	types1 := cmm.extractTypeNames(ast1)
	types2 := cmm.extractTypeNames(ast2)
	sharedTypes := cmm.intersectStrings(types1, types2)
	result.SharedTypes = sharedTypes

	// Comparer les imports
	imports1 := cmm.extractImportNames(ast1)
	imports2 := cmm.extractImportNames(ast2)
	sharedImports := cmm.intersectStrings(imports1, imports2)
	result.SharedImports = sharedImports

	// Analyse des différences
	result.Differences = &interfaces.DifferenceAnalysis{
		AddedFunctions:    cmm.diffStrings(functions1, functions2),
		RemovedFunctions:  cmm.diffStrings(functions2, functions1),
		ModifiedFunctions: []string{}, // Analyse plus complexe nécessaire
		StructuralChanges: []string{}, // Analyse plus complexe nécessaire
	}

	// Recommandations simples
	if result.Structural < 0.3 {
		result.Recommendations = append(result.Recommendations, "Files have very different structures")
	} else if result.Structural > 0.8 {
		result.Recommendations = append(result.Recommendations, "Files are very similar, consider refactoring common code")
	}

	// Similarité sémantique (estimation simple)
	result.Semantic = result.Structural * 0.8 // Approximation

	return result
}

func (cmm *contextualMemoryManagerImpl) deduplicateContextResults(results []interfaces.ContextResult) []interfaces.ContextResult {
	seen := make(map[string]bool)
	var deduped []interfaces.ContextResult

	for _, result := range results {
		key := fmt.Sprintf("%s_%s_%d", result.Action.FilePath, result.Action.Type, result.Action.LineNumber)
		if !seen[key] {
			seen[key] = true
			deduped = append(deduped, result)
		}
	}

	return deduped
}

func (cmm *contextualMemoryManagerImpl) sortContextResultsByRelevance(results []interfaces.ContextResult) {
	// Tri simple par score - dans une vraie implémentation, utiliser sort.Slice
	for i := 0; i < len(results)-1; i++ {
		for j := i + 1; j < len(results); j++ {
			if results[j].Score > results[i].Score {
				results[i], results[j] = results[j], results[i]
			}
		}
	}
}

// Types et méthodes utilitaires

type structuralSimilarityResult struct {
	Structural      float64
	Semantic        float64
	SharedFunctions []string
	SharedTypes     []string
	SharedImports   []string
	Differences     *interfaces.DifferenceAnalysis
	Recommendations []string
}

func (cmm *contextualMemoryManagerImpl) extractFunctionNames(ast *interfaces.ASTAnalysisResult) []string {
	var names []string
	for _, fn := range ast.Functions {
		names = append(names, fn.Name)
	}
	return names
}

func (cmm *contextualMemoryManagerImpl) extractTypeNames(ast *interfaces.ASTAnalysisResult) []string {
	var names []string
	for _, tp := range ast.Types {
		names = append(names, tp.Name)
	}
	return names
}

func (cmm *contextualMemoryManagerImpl) extractImportNames(ast *interfaces.ASTAnalysisResult) []string {
	var names []string
	for _, imp := range ast.Imports {
		names = append(names, imp.Package)
	}
	return names
}

func (cmm *contextualMemoryManagerImpl) intersectStrings(a, b []string) []string {
	setA := make(map[string]bool)
	for _, item := range a {
		setA[item] = true
	}

	var intersection []string
	for _, item := range b {
		if setA[item] {
			intersection = append(intersection, item)
		}
	}

	return intersection
}

func (cmm *contextualMemoryManagerImpl) diffStrings(a, b []string) []string {
	setB := make(map[string]bool)
	for _, item := range b {
		setB[item] = true
	}

	var diff []string
	for _, item := range a {
		if !setB[item] {
			diff = append(diff, item)
		}
	}

	return diff
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// Méthode UpdateHybridConfig manquante - implémentation simplifiée
func (cmm *contextualMemoryManagerImpl) UpdateHybridConfig(ctx context.Context, config interfaces.HybridConfig) error {
	cmm.mu.Lock()
	defer cmm.mu.Unlock()

	if !cmm.initialized {
		return fmt.Errorf("manager not initialized")
	}

	// Mettre à jour la configuration hybride
	cmm.hybridConfig = &config

	// Recréer le sélecteur hybride avec la nouvelle configuration
	cmm.hybridSelector = hybrid.NewModeSelector(cmm.astManager, cmm.retrievalManager, cmm.hybridConfig)

	return nil
}
