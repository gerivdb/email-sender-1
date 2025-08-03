// SPDX-License-Identifier: Apache-2.0
// Roo Code — Tests unitaires BatchManager
//
// Ce fichier couvre tous les scénarios critiques de robustesse du BatchManager Roo : gestion des hooks de rollback (PluginInterface), centralisation des logs/statuts, intégration plugins (mocks), couverture succès/échec/rollback/reporting.
//
// Les tests n’utilisent que des mocks et ne dépendent d’aucun autre manager Roo.

package automatisation_doc

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"
)

// mockPlugin est un mock complet de PluginInterface Roo, incluant RollbackHook.
type mockPlugin struct {
	name                string
	executeErr          error
	onErrorCalled       []string
	rollbackHookCalled  []string
	rollbackHookErr     error
	executeCalledBefore bool
	executeCalledAfter  bool
	mu                  sync.Mutex
}

func (m *mockPlugin) Name() string { return m.name }
func (m *mockPlugin) Execute(ctx context.Context, params map[string]interface{}) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	// On distingue les appels avant/après via un flag dans params
	if params != nil && params["__after"] == true {
		m.executeCalledAfter = true
	} else {
		m.executeCalledBefore = true
	}
	return m.executeErr
}
func (m *mockPlugin) BeforeStep(ctx context.Context, stepName string, params map[string]interface{}) error {
	return nil
}
func (m *mockPlugin) AfterStep(ctx context.Context, stepName string, params map[string]interface{}) error {
	return nil
}
func (m *mockPlugin) OnError(ctx context.Context, stepName string, params map[string]interface{}, stepErr error) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.onErrorCalled = append(m.onErrorCalled, stepName)
	return nil
}
func (m *mockPlugin) RollbackHook(ctx context.Context, batchID string, batch map[string]interface{}, reason error) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.rollbackHookCalled = append(m.rollbackHookCalled, batchID)
	return m.rollbackHookErr
}

// TestBatchManager_Success teste l’exécution d’un batch sans erreur, plugins appelés, logs centralisés.
/*
RooDoc : Vérifie qu’un batch valide s’exécute sans rollback, que les plugins sont appelés (avant/après), et que les logs/statuts sont cohérents.
*/
func TestBatchManager_Success(t *testing.T) {
	bm := NewBatchManager()
	plugin := &mockPlugin{name: "ok"}
	if err := bm.RegisterPlugin(plugin); err != nil {
		t.Fatalf("Échec RegisterPlugin: %v", err)
	}
	batch := &Batch{ID: "batch1", Docs: []string{"docA", "docB"}, CreatedAt: time.Now()}
	res, err := bm.ExecuteBatch(context.Background(), batch)
	if err != nil {
		t.Fatalf("Échec ExecuteBatch: %v", err)
	}
	if !res.Success || res.RolledBack {
		t.Errorf("Batch devrait réussir sans rollback, got Success=%v RolledBack=%v", res.Success, res.RolledBack)
	}
	if len(res.Logs) == 0 || res.Error != nil {
		t.Errorf("Logs attendus et pas d’erreur, got logs=%v err=%v", res.Logs, res.Error)
	}
	if !plugin.executeCalledBefore {
		t.Errorf("Plugin Execute (avant) non appelé")
	}
}

// TestBatchManager_PluginFailAvant vérifie le rollback si un plugin échoue avant l’exécution principale.
/*
RooDoc : Simule un plugin qui échoue avant l’exécution du lot : rollback automatique, hook RollbackHook appelé, logs centralisés, reporting cohérent.
*/
func TestBatchManager_PluginFailAvant(t *testing.T) {
	bm := NewBatchManager()
	plugin := &mockPlugin{name: "fail", executeErr: errors.New("fail avant")}
	if err := bm.RegisterPlugin(plugin); err != nil {
		t.Fatalf("Échec RegisterPlugin: %v", err)
	}
	batch := &Batch{ID: "batch2", Docs: []string{"docA"}, CreatedAt: time.Now()}
	res, err := bm.ExecuteBatch(context.Background(), batch)
	if err == nil || res == nil || !res.RolledBack {
		t.Fatalf("Batch devrait échouer et rollback, got err=%v rolledBack=%v", err, res != nil && res.RolledBack)
	}
	if len(plugin.rollbackHookCalled) == 0 {
		t.Errorf("RollbackHook plugin non appelé")
	}
	if res.Error == nil || res.Error.Error() != "plugin fail (avant lot): fail avant" {
		t.Errorf("Erreur attendue dans res.Error, got %v", res.Error)
	}
	if len(res.Logs) == 0 || res.Logs[0] == "" {
		t.Errorf("Logs de rollback attendus")
	}
}

// TestBatchManager_ExecFail vérifie le rollback si l’exécution principale échoue.
/*
RooDoc : Simule un échec de traitement documentaire (doc == "fail") : rollback automatique, hook RollbackHook appelé, logs/statuts cohérents.
*/
func TestBatchManager_ExecFail(t *testing.T) {
	bm := NewBatchManager()
	plugin := &mockPlugin{name: "ok"}
	if err := bm.RegisterPlugin(plugin); err != nil {
		t.Fatalf("Échec RegisterPlugin: %v", err)
	}
	batch := &Batch{ID: "batch3", Docs: []string{"docA", "fail"}, CreatedAt: time.Now()}
	res, err := bm.ExecuteBatch(context.Background(), batch)
	if err == nil || !res.RolledBack {
		t.Fatalf("Batch devrait échouer et rollback, got err=%v rolledBack=%v", err, res.RolledBack)
	}
	if len(plugin.rollbackHookCalled) == 0 {
		t.Errorf("RollbackHook plugin non appelé")
	}
	if res.Error == nil || res.Error.Error() != "échec traitement doc: fail" {
		t.Errorf("Erreur attendue dans res.Error, got %v", res.Error)
	}
	if len(res.Logs) == 0 {
		t.Errorf("Logs de rollback attendus")
	}
}

// TestBatchManager_RollbackHookError vérifie que les erreurs de RollbackHook sont journalisées mais non bloquantes.
/*
RooDoc : Simule un plugin dont RollbackHook retourne une erreur : l’erreur est loggée, le rollback global n’est pas bloqué.
*/
func TestBatchManager_RollbackHookError(t *testing.T) {
	bm := NewBatchManager()
	plugin := &mockPlugin{name: "errhook", rollbackHookErr: errors.New("rollback fail")}
	if err := bm.RegisterPlugin(plugin); err != nil {
		t.Fatalf("Échec RegisterPlugin: %v", err)
	}
	batch := &Batch{ID: "batch4", Docs: []string{"fail"}, CreatedAt: time.Now()}
	res, err := bm.ExecuteBatch(context.Background(), batch)
	if err == nil || !res.RolledBack {
		t.Fatalf("Batch devrait échouer et rollback, got err=%v rolledBack=%v", err, res.RolledBack)
	}
	found := false
	for _, l := range res.Logs {
		if l == "RollbackHook plugin errhook: rollback fail" {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Erreur RollbackHook non loggée")
	}
}

// TestBatchManager_Reporting vérifie la centralisation du reporting après rollback.
/*
RooDoc : Vérifie que Report retourne l’état complet du lot (succès, échec, rollback, logs) après exécution.
*/
func TestBatchManager_Reporting(t *testing.T) {
	bm := NewBatchManager()
	plugin := &mockPlugin{name: "ok"}
	_ = bm.RegisterPlugin(plugin)
	batch := &Batch{ID: "batch5", Docs: []string{"fail"}, CreatedAt: time.Now()}
	_, _ = bm.ExecuteBatch(context.Background(), batch)
	rep, err := bm.Report(context.Background(), "batch5")
	if err != nil {
		t.Fatalf("Échec Report: %v", err)
	}
	if !rep.RolledBack || rep.Success {
		t.Errorf("Report incohérent: attendu RolledBack=true, Success=false, got %v/%v", rep.RolledBack, rep.Success)
	}
	if len(rep.Logs) == 0 {
		t.Errorf("Logs attendus dans reporting")
	}
}

// TestBatchManager_MultiPlugins vérifie la robustesse avec plusieurs plugins (succès et échec).
/*
RooDoc : Enregistre plusieurs plugins (dont un qui échoue), vérifie que tous les hooks sont appelés, rollback et logs centralisés.
*/
func TestBatchManager_MultiPlugins(t *testing.T) {
	bm := NewBatchManager()
	ok := &mockPlugin{name: "ok"}
	fail := &mockPlugin{name: "fail", executeErr: errors.New("fail")}
	_ = bm.RegisterPlugin(ok)
	_ = bm.RegisterPlugin(fail)
	batch := &Batch{ID: "batch6", Docs: []string{"docA"}, CreatedAt: time.Now()}
	res, err := bm.ExecuteBatch(context.Background(), batch)
	if err == nil || !res.RolledBack {
		t.Fatalf("Batch devrait échouer et rollback, got err=%v rolledBack=%v", err, res.RolledBack)
	}
	if len(ok.rollbackHookCalled) == 0 || len(fail.rollbackHookCalled) == 0 {
		t.Errorf("RollbackHook de tous les plugins doit être appelé")
	}
}

// TestBatchManager_RegisterPlugin_Duplicate vérifie qu’on ne peut pas enregistrer deux plugins du même nom.
/*
RooDoc : Vérifie que RegisterPlugin refuse les doublons de nom de plugin.
*/
func TestBatchManager_RegisterPlugin_Duplicate(t *testing.T) {
	bm := NewBatchManager()
	plugin := &mockPlugin{name: "dup"}
	if err := bm.RegisterPlugin(plugin); err != nil {
		t.Fatalf("Échec RegisterPlugin: %v", err)
	}
	if err := bm.RegisterPlugin(plugin); err == nil {
		t.Errorf("RegisterPlugin devrait échouer sur doublon")
	}
}
