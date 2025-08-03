// monitoring_manager_test.go — Tests unitaires Roo pour MonitoringManager (extension plugins)
// Couverture : enregistrement, hooks, cas limites, gestion des erreurs.
// Auteur : Roo (généré automatiquement)

package automatisation_doc

import (
	"context"
	"errors"
	"testing"
)

// MockPlugin — Implémentation factice de PluginInterface pour tests
type MockPlugin struct {
	name           string
	executed       bool
	beforeCalled   bool
	afterCalled    bool
	onErrorCalled  bool
	forceErrorHook string // "execute", "before", "after", "onerror"
}

func (m *MockPlugin) Name() string { return m.name }

func (m *MockPlugin) Execute(ctx context.Context, params map[string]interface{}) error {
	m.executed = true
	if m.forceErrorHook == "execute" {
		return errors.New("erreur Execute")
	}
	return nil
}

func (m *MockPlugin) BeforeStep(ctx context.Context, stepName string, params map[string]interface{}) error {
	m.beforeCalled = true
	if m.forceErrorHook == "before" {
		return errors.New("erreur BeforeStep")
	}
	return nil
}

func (m *MockPlugin) AfterStep(ctx context.Context, stepName string, params map[string]interface{}) error {
	m.afterCalled = true
	if m.forceErrorHook == "after" {
		return errors.New("erreur AfterStep")
	}
	return nil
}

func (m *MockPlugin) OnError(ctx context.Context, stepName string, params map[string]interface{}, stepErr error) error {
	m.onErrorCalled = true
	if m.forceErrorHook == "onerror" {
		return errors.New("erreur OnError")
	}
	return nil
}

/*
Test d’enregistrement d’un plugin valide.
Vérifie que l’ajout d’un plugin conforme fonctionne sans erreur et que le plugin est bien enregistré.
*/
func TestRegisterPlugin_Valide(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	err := mgr.RegisterPlugin(plugin)
	if err != nil {
		t.Errorf("Enregistrement plugin valide échoué : %v", err)
	}
}

/*
Test d’enregistrement d’un plugin nul.
Vérifie que l’ajout d’un plugin nil est refusé et retourne une erreur.
*/
func TestRegisterPlugin_Nil(t *testing.T) {
	mgr := NewMonitoringManager()
	err := mgr.RegisterPlugin(nil)
	if err == nil {
		t.Error("Enregistrement plugin nul devrait échouer")
	}
}

/*
Test d’enregistrement d’un plugin déjà enregistré (doublon).
Vérifie que l’ajout d’un même plugin deux fois est refusé et retourne une erreur.
*/
func TestRegisterPlugin_Doublon(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.RegisterPlugin(plugin)
	if err == nil {
		t.Error("Enregistrement plugin doublon devrait échouer")
	}
}

/*
Test d’appel du hook Execute.
Vérifie que le hook Execute est bien appelé sur le plugin lors de l’exécution.
*/
func TestPlugin_Execute(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.ExecutePlugins(context.Background(), map[string]interface{}{"foo": "bar"})
	if err != nil {
		t.Errorf("Erreur inattendue ExecutePlugins : %v", err)
	}
	if !plugin.executed {
		t.Error("Le hook Execute n’a pas été appelé")
	}
}

/*
Test d’appel du hook BeforeStep.
Vérifie que le hook BeforeStep est bien appelé sur le plugin avant une étape.
*/
func TestPlugin_BeforeStep(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallBeforeStep(context.Background(), "stepA", nil)
	if err != nil {
		t.Errorf("Erreur inattendue BeforeStep : %v", err)
	}
	if !plugin.beforeCalled {
		t.Error("Le hook BeforeStep n’a pas été appelé")
	}
}

/*
Test d’appel du hook AfterStep.
Vérifie que le hook AfterStep est bien appelé sur le plugin après une étape.
*/
func TestPlugin_AfterStep(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallAfterStep(context.Background(), "stepA", nil)
	if err != nil {
		t.Errorf("Erreur inattendue AfterStep : %v", err)
	}
	if !plugin.afterCalled {
		t.Error("Le hook AfterStep n’a pas été appelé")
	}
}

/*
Test d’appel du hook OnError.
Vérifie que le hook OnError est bien appelé sur le plugin en cas d’erreur d’étape.
*/
func TestPlugin_OnError(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallOnError(context.Background(), "stepA", nil, errors.New("erreur step"))
	if err != nil {
		t.Errorf("Erreur inattendue OnError : %v", err)
	}
	if !plugin.onErrorCalled {
		t.Error("Le hook OnError n’a pas été appelé")
	}
}

/*
Test propagation d’erreur dans Execute.
Vérifie que si le hook Execute retourne une erreur, celle-ci est bien propagée par le manager.
*/
func TestPlugin_Execute_Error(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1", forceErrorHook: "execute"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.ExecutePlugins(context.Background(), nil)
	if err == nil {
		t.Error("L’erreur Execute du plugin aurait dû être propagée")
	}
}

/*
Test propagation d’erreur dans BeforeStep.
Vérifie que si le hook BeforeStep retourne une erreur, celle-ci est bien propagée par le manager.
*/
func TestPlugin_BeforeStep_Error(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1", forceErrorHook: "before"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallBeforeStep(context.Background(), "stepA", nil)
	if err == nil {
		t.Error("L’erreur BeforeStep du plugin aurait dû être propagée")
	}
}

/*
Test propagation d’erreur dans AfterStep.
Vérifie que si le hook AfterStep retourne une erreur, celle-ci est bien propagée par le manager.
*/
func TestPlugin_AfterStep_Error(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1", forceErrorHook: "after"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallAfterStep(context.Background(), "stepA", nil)
	if err == nil {
		t.Error("L’erreur AfterStep du plugin aurait dû être propagée")
	}
}

/*
Test propagation d’erreur dans OnError.
Vérifie que si le hook OnError retourne une erreur, celle-ci est bien propagée par le manager.
*/
func TestPlugin_OnError_Error(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MockPlugin{name: "plugin1", forceErrorHook: "onerror"}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.CallOnError(context.Background(), "stepA", nil, errors.New("erreur step"))
	if err == nil {
		t.Error("L’erreur OnError du plugin aurait dû être propagée")
	}
}

/*
Test : plugin n’implémente que Execute (hooks optionnels retournent nil).
Vérifie qu’un plugin minimaliste (seulement Execute) fonctionne sans erreur et que les hooks optionnels sont ignorés.
*/
type MinimalPlugin struct{ executed bool }

func (m *MinimalPlugin) Name() string { return "minimal" }
func (m *MinimalPlugin) Execute(ctx context.Context, params map[string]interface{}) error {
	m.executed = true
	return nil
}
func (m *MinimalPlugin) BeforeStep(ctx context.Context, stepName string, params map[string]interface{}) error {
	return nil
}
func (m *MinimalPlugin) AfterStep(ctx context.Context, stepName string, params map[string]interface{}) error {
	return nil
}
func (m *MinimalPlugin) OnError(ctx context.Context, stepName string, params map[string]interface{}, stepErr error) error {
	return nil
}

func TestPlugin_Minimal(t *testing.T) {
	mgr := NewMonitoringManager()
	plugin := &MinimalPlugin{}
	_ = mgr.RegisterPlugin(plugin)
	err := mgr.ExecutePlugins(context.Background(), nil)
	if err != nil {
		t.Errorf("Erreur inattendue ExecutePlugins (minimal) : %v", err)
	}
	if !plugin.executed {
		t.Error("Le plugin minimal n’a pas exécuté Execute")
	}
}

/*
Résumé technique de la couverture des tests unitaires Roo — MonitoringManager extension plugins

- Enregistrement plugin : cas normal, plugin nil, doublon.
- Appel de tous les hooks (Execute, BeforeStep, AfterStep, OnError) : succès et propagation stricte des erreurs.
- Cas minimaliste (plugin n’implémente que Execute).
- Tous les cas critiques et limites sont couverts pour garantir la robustesse, la conformité Roo et la testabilité de l’extension plugin.
- Les messages d’erreur sont explicites et chaque test est documenté pour faciliter la maintenance et l’audit.

Voir la documentation Roo et [`monitoring_manager_report.md`](monitoring_manager_report.md) pour la traçabilité complète.
*/
