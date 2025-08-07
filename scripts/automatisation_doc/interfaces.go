// interfaces.go - Interface complète SOTA 2025

package automatisation_doc

import (
	"context"
)

// ErrorEntry structure pour gestion d'erreur
type ErrorEntry struct {
	ID        string
	Component string
	Operation string
	Message   string
}

// PluginInterface SOTA 2025
type PluginInterface interface {
	Name() string
	Activate(ctx context.Context) error
	Deactivate(ctx context.Context) error
	Execute(ctx context.Context, params map[string]interface{}) (interface{}, error)
	HandleError(ctx context.Context, entry *ErrorEntry) error
	BeforeStep(ctx context.Context, stepName string, params interface{}) error
	AfterStep(ctx context.Context, stepName string, params interface{}) error
	OnError(ctx context.Context, entry *ErrorEntry) error
}

// Compile-time interface compliance check (SOTA pattern 2025)
var _ PluginInterface = (*MockPlugin)(nil)
var _ PluginInterface = (*MinimalPlugin)(nil)
