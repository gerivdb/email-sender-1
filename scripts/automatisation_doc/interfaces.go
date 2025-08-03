// interfaces.go — Types partagés Roo pour automatisation_doc

package automatisation_doc

import "context"

// DependencyMetadata Roo : struct partagée pour la persistance documentaire.
// À utiliser dans tous les managers Roo concernés (StorageManager, etc.).
type DependencyMetadata struct {
	Name   string
	Fields map[string]interface{}
}

// PluginInterface Roo : interface partagée pour l’extension dynamique des managers Roo.
// À utiliser dans StorageManager, PipelineManager, etc.
type PluginInterface interface {
	Name() string
	Execute(ctx context.Context, params map[string]interface{}) error
}
