// interfaces.go — Types partagés Roo pour automatisation_doc

package automatisation_doc

import "context"

// DependencyMetadata Roo : struct partagée pour la persistance documentaire.
// À utiliser dans tous les managers Roo concernés (StorageManager, etc.).
type DependencyMetadata struct {
	Name   string
	Fields map[string]interface{}
}

/*
PluginInterface Roo : interface partagée pour l’extension dynamique des managers Roo.
À utiliser dans StorageManager, PipelineManager, etc.

Points d’extension Roo :
- Execute : exécution principale du plugin (obligatoire)
- BeforeStep : hook appelé avant chaque étape du pipeline (optionnel, peut retourner nil)
- AfterStep : hook appelé après chaque étape du pipeline (optionnel, peut retourner nil)
- OnError : hook appelé en cas d’erreur lors d’une étape (optionnel, peut retourner nil)

Pour compatibilité, les plugins existants peuvent n’implémenter que Execute.
*/
type PluginInterface interface {
	Name() string
	Execute(ctx context.Context, params map[string]interface{}) error

	// BeforeStep Roo : hook optionnel appelé avant l’exécution d’une étape pipeline.
	// Peut retourner nil si non implémenté.
	BeforeStep(ctx context.Context, stepName string, params map[string]interface{}) error

	// AfterStep Roo : hook optionnel appelé après l’exécution d’une étape pipeline.
	// Peut retourner nil si non implémenté.
	AfterStep(ctx context.Context, stepName string, params map[string]interface{}) error

	// OnError Roo : hook optionnel appelé si une erreur survient lors d’une étape pipeline.
	// Peut retourner nil si non implémenté.
	OnError(ctx context.Context, stepName string, params map[string]interface{}, stepErr error) error
}

// ErrorEntry Roo : structure pour la gestion centralisée des erreurs documentaire.
type ErrorEntry struct {
	DocID     string
	Operation string
	Err       error
	Meta      map[string]interface{}
}

// ErrorManager Roo : interface pour la gestion centralisée des erreurs documentaire.
type ErrorManager interface {
	ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
	CatalogError(entry ErrorEntry) error
	ValidateErrorEntry(entry ErrorEntry) error
}

// ErrorHooks Roo : hooks optionnels pour la gestion avancée des erreurs.
type ErrorHooks struct {
	OnError func(error)
}
