package automatisation_doc

package automatisation_doc

package automatisation_doc

// Tests unitaires QualityGateManager
// Les types GeneratedTemplate et ValidationReport sont déjà définis dans smart_template.go, inutile de les redéclarer ici.
package automatisation_doc

import (
	"context"
	"testing"
)

// Mock QualityGatePlugin
type mockQualityGatePlugin struct{}

func (m *mockQualityGatePlugin) CheckCompliance(ctx context.Context, tpl *GeneratedTemplate) (*ValidationReport, error) {
	return &ValidationReport{}, nil
}

func (m *mockQualityGatePlugin) RunTests(ctx context.Context, tpl *GeneratedTemplate) (*ValidationReport, error) {
	return &ValidationReport{}, nil
}

func TestRegisterPluginExplicitName(t *testing.T) {
	manager := &QualityGateManager{}
	plugin := &mockQualityGatePlugin{}
	name := "mockPlugin"

	err := manager.RegisterPlugin(name, plugin)
	if err != nil {
		t.Fatalf("RegisterPlugin failed: %v", err)
	}

	plugins := manager.ListPlugins()
	found := false
	for _, p := range plugins {
		if p == name {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Plugin name '%s' not found in ListPlugins", name)
	}
}
