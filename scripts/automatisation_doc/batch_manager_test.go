// batch_manager_test.go — Squelette Roo Code des tests unitaires BatchManager
//
// Ce fichier définit la structure de base des tests unitaires pour le manager BatchManager.
// Respecte les conventions Roo Code : lisibilité, documentation, traçabilité, structuration claire.
// À compléter avec des cas de test réels, des mocks et des assertions selon les standards du projet.

package automatisation_doc

import (
	"context"
	"errors"
	"testing"
)

// TestBatchManager — Tests unitaires Roo Code pour BatchManager.
type mockPlugin struct {
	name      string
	shouldErr bool
}

// Implémentation minimaliste de PluginInterface pour test
func (m *mockPlugin) Name() string { return m.name }
func (m *mockPlugin) Execute(ctx context.Context, params map[string]interface{}) error {
	if m.shouldErr {
		return errors.New("plugin error")
	}
	return nil
}

type mockErrorManager struct {
	lastErr error
}

func (m *mockErrorManager) ProcessError(ctx context.Context, err error, component, operation string, hooks interface{}) error {
	m.lastErr = err
	return nil
}

func TestBatchManager(t *testing.T) {
	t.Run("Initialisation correcte", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		if err := bm.Init(); err != nil {
			t.Fatalf("Init() doit réussir, erreur: %v", err)
		}
		if bm.Status() != "ready" {
			t.Errorf("Status attendu 'ready', obtenu: %s", bm.Status())
		}
	})

	t.Run("Erreur si ErrorManager absent", func(t *testing.T) {
		bm := NewBatchManager(context.Background(), nil, nil)
		if err := bm.Init(); err == nil {
			t.Error("Init() doit échouer si ErrorManager absent")
		}
	})

	t.Run("Exécution batch standard (succès plugin)", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		_ = bm.RegisterPlugin(&mockPlugin{name: "ok", shouldErr: false})
		if err := bm.Run(); err != nil {
			t.Errorf("Run() doit réussir, erreur: %v", err)
		}
		if len(bm.batchResults) == 0 || bm.batchResults[len(bm.batchResults)-1].Status != "success" {
			t.Error("BatchResult doit être 'success'")
		}
	})

	t.Run("Erreur plugin batch et rollback déclenché", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		rollbackCalled := false
		bm.rollbackHooks = append(bm.rollbackHooks, func() error { rollbackCalled = true; return nil })
		_ = bm.RegisterPlugin(&mockPlugin{name: "fail", shouldErr: true})
		err := bm.Run()
		if err == nil {
			t.Error("Run() doit échouer si plugin retourne une erreur")
		}
		if !rollbackCalled {
			t.Error("Le hook de rollback doit être appelé en cas d'erreur plugin")
		}
		if em.lastErr == nil {
			t.Error("L'erreur doit être remontée à ErrorManager")
		}
	})

	t.Run("Traçabilité et logs générés", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		_ = bm.RegisterPlugin(&mockPlugin{name: "ok", shouldErr: false})
		_ = bm.Run()
		if len(bm.logs) == 0 {
			t.Error("Des logs doivent être générés lors de l'exécution")
		}
	})

	t.Run("Cas limites: plugin sans nom", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		err := bm.RegisterPlugin(&mockPlugin{name: "", shouldErr: false})
		if err == nil {
			t.Error("RegisterPlugin doit échouer si le nom du plugin est vide")
		}
	})

	// --- Extension Roo : hooks de reporting, batchResults multiples, plugins multiples, cas limites avancés ---

	t.Run("Reporting hook appelé et erreur propagée", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		reportingCalled := false
		bm.reportingHooks = append(bm.reportingHooks, func() error { reportingCalled = true; return nil })
		_ = bm.RegisterPlugin(&mockPlugin{name: "ok", shouldErr: false})
		_ = bm.Run()
		if !reportingCalled {
			t.Error("Le hook de reporting doit être appelé après Run")
		}
	})

	t.Run("Reporting hook retourne une erreur (non bloquant)", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		bm.reportingHooks = append(bm.reportingHooks, func() error { return errors.New("reporting error") })
		_ = bm.RegisterPlugin(&mockPlugin{name: "ok", shouldErr: false})
		err := bm.Run()
		if err != nil {
			t.Error("Run ne doit pas échouer si le reporting hook retourne une erreur")
		}
	})

	t.Run("BatchResults multiples et traçabilité", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		_ = bm.RegisterPlugin(&mockPlugin{name: "p1", shouldErr: false})
		_ = bm.Run()
		_ = bm.RegisterPlugin(&mockPlugin{name: "p2", shouldErr: false})
		_ = bm.Run()
		if len(bm.batchResults) != 2 {
			t.Errorf("On attend 2 batchResults, obtenu: %d", len(bm.batchResults))
		}
		for _, br := range bm.batchResults {
			if br.Status != "success" && br.Status != "error" && br.Status != "started" {
				t.Errorf("Status inattendu dans batchResults: %s", br.Status)
			}
		}
	})

	t.Run("Plugins multiples, dont un en erreur", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		_ = bm.RegisterPlugin(&mockPlugin{name: "ok", shouldErr: false})
		_ = bm.RegisterPlugin(&mockPlugin{name: "fail", shouldErr: true})
		err := bm.Run()
		if err == nil {
			t.Error("Run doit échouer si un plugin retourne une erreur")
		}
		if em.lastErr == nil {
			t.Error("L'erreur plugin doit être propagée à ErrorManager")
		}
	})

	t.Run("Plugin dupliqué : écrasement silencieux", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		_ = bm.RegisterPlugin(&mockPlugin{name: "dup", shouldErr: false})
		err := bm.RegisterPlugin(&mockPlugin{name: "dup", shouldErr: true})
		if err != nil {
			t.Error("RegisterPlugin doit permettre l'écrasement d'un plugin du même nom")
		}
	})

	t.Run("Rollback hook retourne une erreur (non bloquant)", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		bm.rollbackHooks = append(bm.rollbackHooks, func() error { return errors.New("rollback error") })
		_ = bm.RegisterPlugin(&mockPlugin{name: "fail", shouldErr: true})
		err := bm.Run()
		if err == nil {
			t.Error("Run doit échouer si plugin retourne une erreur, même si rollback hook échoue")
		}
	})

	t.Run("Vérification du contenu des logs et traçabilité", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		_ = bm.Init()
		_ = bm.RegisterPlugin(&mockPlugin{name: "ok", shouldErr: false})
		_ = bm.Run()
		found := false
		for _, log := range bm.logs {
			if log == "BatchManager prêt." {
				found = true
				break
			}
		}
		if !found {
			t.Error("Le log 'BatchManager prêt.' doit être présent dans les logs")
		}
	})

	t.Run("Stop non implémenté", func(t *testing.T) {
		em := &mockErrorManager{}
		bm := NewBatchManager(context.Background(), nil, em)
		err := bm.Stop()
		if err == nil || err.Error() != "Stop non implémenté" {
			t.Error("Stop doit retourner une erreur explicite")
		}
	})
}

// Fin du squelette Roo Code — batch_manager_test.go
