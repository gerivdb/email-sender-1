package sync_core

import (
	"fmt"
	"log"
	"time"
)

// SyncOrchestrator coordinates the conversion and storage of plans
type SyncOrchestrator struct {
	parser		*MarkdownParser
	synchronizer	*PlanSynchronizer
	qdrant		*QDrantClient
	sqlStorage	*SQLStorage
	logger		*log.Logger
}

// SyncConfig holds configuration for the sync orchestrator
type SyncConfig struct {
	QDrantURL	string		`yaml:"qdrant_url"`
	DatabaseConfig	DatabaseConfig	`yaml:"database"`
	OutputDir	string		`yaml:"output_dir"`
}

// NewSyncOrchestrator creates a new sync orchestrator
func NewSyncOrchestrator(config SyncConfig) (*SyncOrchestrator, error) {	// Initialize components
	parser := NewMarkdownParser()

	qdrant := NewQDrantClient(config.QDrantURL)

	sqlStorage, err := NewSQLStorage(config.DatabaseConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize SQL storage: %w", err)
	}
	// Initialize synchronizer for reverse sync
	syncConfig := &MarkdownSyncConfig{
		OutputDirectory:	config.OutputDir,
		PreserveFormatting:	true,
		BackupOriginal:		true,
		OverwriteExisting:	false,
	}

	synchronizer := NewPlanSynchronizer(sqlStorage, qdrant, syncConfig)

	orchestrator := &SyncOrchestrator{
		parser:		parser,
		synchronizer:	synchronizer,
		qdrant:		qdrant,
		sqlStorage:	sqlStorage,
		logger:		log.Default(),
	}
	// Initialize QDrant collection
	if err := qdrant.EnsureCollection(); err != nil {
		return nil, fmt.Errorf("failed to ensure QDrant collection: %w", err)
	}

	return orchestrator, nil
}

// ConvertAndStore performs the complete conversion and storage process
func (so *SyncOrchestrator) ConvertAndStore(metadata *PlanMetadata, tasks []Task) error {
	startTime := time.Now()
	so.logger.Printf("🚀 Starting conversion and storage for plan: %s", metadata.Title)

	// Step 1: Convert to dynamic format
	so.logger.Printf("📝 Step 1: Converting to dynamic format")
	plan, err := so.parser.ConvertToDynamic(metadata, tasks)
	if err != nil {
		return fmt.Errorf("conversion failed: %w", err)
	}

	// Step 2: Validate conversion
	so.logger.Printf("🔍 Step 2: Validating conversion")
	if err := so.parser.ValidateConversion(plan); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	// Step 3: Store in SQL database
	so.logger.Printf("💾 Step 3: Storing in SQL database")
	if err := so.sqlStorage.StorePlan(plan); err != nil {
		return fmt.Errorf("SQL storage failed: %w", err)
	}

	// Step 4: Store embeddings in QDrant (if embeddings exist)
	if len(plan.Embeddings) > 0 {
		so.logger.Printf("📡 Step 4: Storing embeddings in QDrant")
		if err := so.qdrant.StorePlanEmbeddings(plan); err != nil {
			// Log warning but don't fail the entire process
			so.logger.Printf("⚠️  Warning: Failed to store embeddings in QDrant: %v", err)
		}
	} else {
		so.logger.Printf("⚠️  Step 4: No embeddings to store in QDrant")
	}

	duration := time.Since(startTime)
	so.logger.Printf("✅ Conversion and storage completed successfully in %v", duration)

	return nil
}

// GetPlanByID retrieves a plan by its ID
func (so *SyncOrchestrator) GetPlanByID(planID string) (*DynamicPlan, error) {
	so.logger.Printf("📖 Retrieving plan: %s", planID)

	plan, err := so.sqlStorage.GetPlan(planID)
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve plan: %w", err)
	}

	so.logger.Printf("✅ Successfully retrieved plan: %s", planID)
	return plan, nil
}

// SearchSimilarPlans finds plans similar to the given query
func (so *SyncOrchestrator) SearchSimilarPlans(queryPlan *DynamicPlan, limit int) ([]QDrantPoint, error) {
	so.logger.Printf("🔍 Searching for similar plans (limit: %d)", limit)

	if len(queryPlan.Embeddings) == 0 {
		return nil, fmt.Errorf("query plan has no embeddings for similarity search")
	}

	results, err := so.qdrant.SearchSimilarPlans(queryPlan.Embeddings, limit)
	if err != nil {
		return nil, fmt.Errorf("similarity search failed: %w", err)
	}

	so.logger.Printf("✅ Found %d similar plans", len(results))
	return results, nil
}

// GetSyncStatistics returns comprehensive synchronization statistics
func (so *SyncOrchestrator) GetSyncStatistics() (map[string]interface{}, error) {
	so.logger.Printf("📊 Gathering sync statistics")

	stats, err := so.sqlStorage.GetSyncStats()
	if err != nil {
		return nil, fmt.Errorf("failed to get SQL statistics: %w", err)
	}

	// Add QDrant health status
	err = so.qdrant.HealthCheck()
	stats["qdrant_healthy"] = err == nil
	if err != nil {
		stats["qdrant_error"] = err.Error()
	}

	so.logger.Printf("✅ Statistics gathered successfully")
	return stats, nil
}

// HealthCheck performs a comprehensive health check of all components
func (so *SyncOrchestrator) HealthCheck() error {
	so.logger.Printf("🏥 Performing health check")

	// Check QDrant
	if err := so.qdrant.HealthCheck(); err != nil {
		return fmt.Errorf("QDrant health check failed: %w", err)
	}

	// Check SQL database by attempting to get stats
	_, err := so.sqlStorage.GetSyncStats()
	if err != nil {
		return fmt.Errorf("SQL database health check failed: %w", err)
	}

	so.logger.Printf("✅ All components healthy")
	return nil
}

// Close gracefully shuts down all components
func (so *SyncOrchestrator) Close() error {
	so.logger.Printf("🔌 Shutting down sync orchestrator")

	if err := so.sqlStorage.Close(); err != nil {
		return fmt.Errorf("failed to close SQL storage: %w", err)
	}

	so.logger.Printf("✅ Sync orchestrator shut down successfully")
	return nil
}

// Example usage and test function
func ExampleUsage() {
	// Configuration
	config := SyncConfig{
		QDrantURL:	"http://localhost:6333",
		DatabaseConfig: DatabaseConfig{
			Driver:		"sqlite3",
			Connection:	"file:plans.db?cache=shared&mode=rwc",
		},
	}

	// Create orchestrator
	orchestrator, err := NewSyncOrchestrator(config)
	if err != nil {
		log.Fatalf("Failed to create orchestrator: %v", err)
	}
	defer orchestrator.Close()

	// Example plan metadata
	metadata := &PlanMetadata{
		FilePath:	"exemple/plan-dev-v48-repovisualizer.md",
		Title:		"Plan de développement v48 - Repository Visualizer",
		Version:	"v48",
		Date:		"2025-06-11",
		Progression:	75.0,
		Description:	"Plan pour le développement du visualiseur de repository",
	}

	// Example tasks
	tasks := []Task{
		{
			ID:		"task_1",
			Title:		"Architecture de base",
			Description:	"Définir l'architecture du système",
			Status:		"completed",
			Phase:		"Phase 1",
			Level:		1,
			Priority:	"high",
			Completed:	true,
			CreatedAt:	time.Now(),
			UpdatedAt:	time.Now(),
		},
		{
			ID:		"task_2",
			Title:		"Implémentation parser",
			Description:	"Développer le parser de fichiers",
			Status:		"in_progress",
			Phase:		"Phase 2",
			Level:		2,
			Priority:	"medium",
			Completed:	false,
			CreatedAt:	time.Now(),
			UpdatedAt:	time.Now(),
			Dependencies:	[]string{"task_1"},
		},
	}

	// Convert and store
	if err := orchestrator.ConvertAndStore(metadata, tasks); err != nil {
		log.Printf("Error: %v", err)
		return
	}

	// Get statistics
	stats, err := orchestrator.GetSyncStatistics()
	if err != nil {
		log.Printf("Failed to get statistics: %v", err)
		return
	}

	log.Printf("Sync Statistics: %+v", stats)
}

// SyncToMarkdown synchronizes a specific plan from dynamic system to Markdown
func (so *SyncOrchestrator) SyncToMarkdown(planID string) error {
	so.logger.Printf("🔄 Starting reverse synchronization for plan: %s", planID)

	if so.synchronizer == nil {
		return fmt.Errorf("synchronizer not initialized")
	}

	return so.synchronizer.SyncToMarkdown(planID)
}

// SyncAllToMarkdown synchronizes all plans from dynamic system to Markdown
func (so *SyncOrchestrator) SyncAllToMarkdown() error {
	so.logger.Printf("🔄 Starting bulk reverse synchronization")

	if so.synchronizer == nil {
		return fmt.Errorf("synchronizer not initialized")
	}

	return so.synchronizer.SyncAllPlans()
}

// GetSyncToMarkdownStats returns statistics from the markdown synchronizer
func (so *SyncOrchestrator) GetSyncToMarkdownStats() *SyncStats {
	if so.synchronizer == nil {
		return &SyncStats{}
	}

	return so.synchronizer.GetStats()
}

// ResetSyncToMarkdownStats resets the markdown synchronizer statistics
func (so *SyncOrchestrator) ResetSyncToMarkdownStats() {
	if so.synchronizer != nil {
		so.synchronizer.ResetStats()
		so.logger.Printf("📊 Markdown synchronizer statistics reset")
	}
}
