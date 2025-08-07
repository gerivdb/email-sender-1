// mock_plugin.go - Implémentation complète SOTA 2025

package automatisation_doc

import (
	"context"
	"errors"

	"github.com/stretchr/testify/mock"
)

// MockPlugin - Implémentation complète conforme SOTA 2025
type MockPlugin struct {
	mock.Mock
	name           string
	executed       bool
	beforeCalled   bool
	afterCalled    bool
	onErrorCalled  bool
	forceErrorHook string
}

// Interface compliance - toutes les méthodes requises
func (m *MockPlugin) Name() string { return m.name }

func (m *MockPlugin) Activate(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockPlugin) Deactivate(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockPlugin) Execute(ctx context.Context, params map[string]interface{}) (interface{}, error) {
	m.executed = true
	args := m.Called(ctx, params)
	if m.forceErrorHook == "execute" {
		return nil, errors.New("erreur Execute")
	}
	return args.Get(0), args.Error(1)
}

func (m *MockPlugin) HandleError(ctx context.Context, entry *ErrorEntry) error {
	args := m.Called(ctx, entry)
	if m.forceErrorHook == "handle" {
		return errors.New("erreur HandleError")
	}
	return args.Error(0)
}

func (m *MockPlugin) BeforeStep(ctx context.Context, stepName string, params interface{}) error {
	m.beforeCalled = true
	args := m.Called(ctx, stepName, params)
	if m.forceErrorHook == "before" {
		return errors.New("erreur BeforeStep")
	}
	return args.Error(0)
}

func (m *MockPlugin) AfterStep(ctx context.Context, stepName string, params interface{}) error {
	m.afterCalled = true
	args := m.Called(ctx, stepName, params)
	if m.forceErrorHook == "after" {
		return errors.New("erreur AfterStep")
	}
	return args.Error(0)
}

func (m *MockPlugin) OnError(ctx context.Context, entry *ErrorEntry) error {
	m.onErrorCalled = true
	args := m.Called(ctx, entry)
	if m.forceErrorHook == "onerror" {
		return errors.New("erreur OnError")
	}
	return args.Error(0)
}
