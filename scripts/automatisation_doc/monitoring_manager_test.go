// monitoring_manager_test.go — Tests unitaires SOTA pour MonitoringManager

package automatisation_doc

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestRegisterPlugin_Valide(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	err := mgr.RegisterPlugin(plugin)
	assert.NoError(t, err)
}

func TestRegisterPlugin_Nil(t *testing.T) {
	mgr := NewMonitoringManager()
	err := mgr.RegisterPlugin(nil)
	assert.Error(t, err)
}

func TestRegisterPlugin_Doublon(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.RegisterPlugin(plugin)
	assert.Error(t, err)
}

func TestPlugin_Execute(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.ExecutePlugins(context.Background(), map[string]interface{}{"foo": "bar"})
	assert.NoError(t, err)
	assert.True(t, plugin.executed)
}

func TestPlugin_BeforeStep(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallBeforeStep(context.Background(), "stepA", nil)
	assert.NoError(t, err)
	assert.True(t, plugin.beforeCalled)
}

func TestPlugin_AfterStep(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallAfterStep(context.Background(), "stepA", nil)
	assert.NoError(t, err)
	assert.True(t, plugin.afterCalled)
}

func TestPlugin_OnError(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	entry := &ErrorEntry{
		ID:        "test",
		Component: "MonitoringManager",
		Operation: "stepA",
		Message:   "erreur step",
	}
	err := mgr.CallOnError(context.Background(), entry)
	assert.NoError(t, err)
	assert.True(t, plugin.onErrorCalled)
}

func TestPlugin_Execute_Error(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1", forceErrorHook: "execute"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.ExecutePlugins(context.Background(), nil)
	assert.Error(t, err)
}

func TestPlugin_BeforeStep_Error(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1", forceErrorHook: "before"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallBeforeStep(context.Background(), "stepA", nil)
	assert.Error(t, err)
}

func TestPlugin_AfterStep_Error(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1", forceErrorHook: "after"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallAfterStep(context.Background(), "stepA", nil)
	assert.Error(t, err)
}

func TestPlugin_OnError_Error(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1", forceErrorHook: "onerror"}
	_ = mgr.RegisterPlugin(plugin)
	entry := &ErrorEntry{
		ID:        "test",
		Component: "MonitoringManager",
		Operation: "stepA",
		Message:   "erreur step",
	}
	err := mgr.CallOnError(context.Background(), entry)
	assert.Error(t, err)
}

func TestPlugin_Minimal(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MinimalPlugin{}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.ExecutePlugins(context.Background(), nil)
	assert.NoError(t, err)
	assert.True(t, plugin.executed)
}
