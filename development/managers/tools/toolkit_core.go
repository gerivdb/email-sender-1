// Manager Toolkit - Core Type Definitions
// Version: 3.0.0

package tools

import (
	"context"
	"time"
)

// ToolkitOperation represents the common interface for all toolkit operations
type ToolkitOperation interface {
	// Exécution principale
	Execute(ctx context.Context, options *OperationOptions) error
	
	// Validation pré-exécution
	Validate(ctx context.Context) error
	
	// Métriques post-exécution
	CollectMetrics() map[string]interface{}
	
	// Vérification de santé
	HealthCheck(ctx context.Context) error
	
	// Identification de l'outil (NOUVEAU - résout l'ambiguïté d'identification)
	String() string
	
	// Description de l'outil (NOUVEAU - améliore la documentation)
	GetDescription() string
	
	// Gestion des signaux d'arrêt (NOUVEAU - pour la robustesse)
	Stop(ctx context.Context) error
}

// OperationOptions holds options for operations
type OperationOptions struct {
	// Core options
	Target    string `json:"target"`    // Specific file or directory target
	Output    string `json:"output"`    // Output file for reports
	Force     bool   `json:"force"`     // Force operations without confirmation
	
	// Runtime control options (Phase 2.1 - Critical fixes)
	DryRun    bool   `json:"dry_run"`   // Simulation mode without making changes
	Verbose   bool   `json:"verbose"`   // Enable detailed logging
	Timeout   time.Duration `json:"timeout"` // Operation timeout duration
	Workers   int    `json:"workers"`   // Number of concurrent workers
	LogLevel  string `json:"log_level"` // Logging level (DEBUG, INFO, WARN, ERROR)
	
	// Advanced options
	Context   context.Context `json:"-"`        // Execution context (not serialized)
	Config    *ToolkitConfig  `json:"config"`   // Runtime configuration override
}

func NewNamingNormalizer(baseDir string, logger *Logger, stats *ToolkitStats, dryRun bool) *NamingNormalizer {
	return &NamingNormalizer{
		BaseDir: baseDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  dryRun,
	}
}
