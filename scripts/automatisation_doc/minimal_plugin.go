// minimal_plugin.go - Implémentation complète SOTA 2025

package automatisation_doc

import (
	"context"
)

// MinimalPlugin avec toutes les méthodes requises
type MinimalPlugin struct {
	executed bool
}

func (m *MinimalPlugin) Name() string { return "minimal" }

func (m *MinimalPlugin) Activate(ctx context.Context) error { return nil }

func (m *MinimalPlugin) Deactivate(ctx context.Context) error { return nil }

func (m *MinimalPlugin) Execute(ctx context.Context, params map[string]interface{}) (interface{}, error) {
	m.executed = true
	return nil, nil
}

func (m *MinimalPlugin) HandleError(ctx context.Context, entry *ErrorEntry) error {
	return nil
}

func (m *MinimalPlugin) BeforeStep(ctx context.Context, stepName string, params interface{}) error {
	return nil
}

func (m *MinimalPlugin) AfterStep(ctx context.Context, stepName string, params interface{}) error {
	return nil
}

func (m *MinimalPlugin) OnError(ctx context.Context, entry *ErrorEntry) error {
	return nil
}
