// scripts/automatisation_doc/session_manager_test.go
//
// 🧪 Tests unitaires Roo Code pour SessionManager (Phase 3 - Automatisation documentaire)
// - Injection dynamique des hooks de persistance
// - Appel correct des hooks BeforePersist, AfterPersist, OnPersistError
// - Traçabilité des événements
// - Gestion des erreurs et conformité Roo Code
//
// 🔗 Références croisées :
// - [session_manager.go](session_manager.go)
// - [plan-dev-v113-autmatisation-doc-roo.md](../projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)

package automatisation_doc

import (
	"context"
	"errors"
	"testing"
)

// --- Mock PersistenceEngine pour injection et simulation succès/échec ---
type mockPersistenceEngine struct {
	shouldFail bool
	called     bool
}

func (m *mockPersistenceEngine) Persist(ctx context.Context, config SessionConfig) error {
	m.called = true
	if m.shouldFail {
		return errors.New("mock persist error")
	}
	return nil
}

// Test minimal d'initialisation (déjà présent)
func TestNewSessionManager_Init(t *testing.T) {
	config := SessionConfig{
		SessionID: "test-session-001",
	}
	manager := NewSessionManager(config, &mockPersistenceEngine{shouldFail: false})
	if manager == nil {
		t.Fatal("SessionManager doit être instancié")
	}
	ctx := context.Background()
	if err := manager.Init(ctx, config); err != nil {
		t.Errorf("Init doit réussir, erreur reçue: %v", err)
	}
	// TODO: Ajouter des assertions sur l’état, les hooks, la configuration, etc.
}

func TestSessionManager_PersistenceHooks_OrderAndEventType(t *testing.T) {
	manager := NewSessionManager(SessionConfig{SessionID: "persist-hook-test"}, &mockPersistenceEngine{shouldFail: false})
	ctx := context.Background()
	var trace []string

	// Injection du mock PersistenceEngine (succès)
	mockEngine := &mockPersistenceEngine{shouldFail: false}
	manager.persistence = mockEngine

	manager.RegisterPersistenceHook(BeforePersistHook, func(ev SessionEvent) error {
		if ev.Type != "before_persist" {
			t.Errorf("Type d'événement attendu: before_persist, reçu: %s", ev.Type)
		}
		trace = append(trace, "before")
		return nil
	})
	manager.RegisterPersistenceHook(AfterPersistHook, func(ev SessionEvent) error {
		if ev.Type != "after_persist" {
			t.Errorf("Type d'événement attendu: after_persist, reçu: %s", ev.Type)
		}
		trace = append(trace, "after")
		return nil
	})
	manager.RegisterPersistenceHook(OnPersistErrorHook, func(ev SessionEvent) error {
		t.Errorf("OnPersistError ne doit pas être appelé en cas de succès")
		return nil
	})

	if err := manager.persist(ctx); err != nil {
		t.Errorf("persist doit réussir, erreur reçue: %v", err)
	}
	if len(trace) != 2 || trace[0] != "before" || trace[1] != "after" {
		t.Errorf("Ordre des hooks incorrect, trace: %v", trace)
	}
	if !mockEngine.called {
		t.Error("Le mock PersistenceEngine doit être appelé")
	}
}

// Test gestion d’erreur : BeforePersist retourne une erreur
func TestSessionManager_PersistenceHooks_BeforePersistError(t *testing.T) {
	manager := NewSessionManager(SessionConfig{SessionID: "persist-err-test"}, &mockPersistenceEngine{shouldFail: false})
	ctx := context.Background()
	called := false

	manager.RegisterPersistenceHook(BeforePersistHook, func(ev SessionEvent) error {
		called = true
		return errors.New("erreur avant persistance")
	})
	manager.RegisterPersistenceHook(AfterPersistHook, func(ev SessionEvent) error {
		t.Errorf("AfterPersist ne doit pas être appelé si BeforePersist échoue")
		return nil
	})
	manager.RegisterPersistenceHook(OnPersistErrorHook, func(ev SessionEvent) error {
		// Ne doit pas être appelé ici (l’erreur vient du hook, pas de la persistance)
		return nil
	})

	err := manager.persist(ctx)
	if !called {
		t.Error("Le hook BeforePersist doit être appelé")
	}
	if err == nil || err.Error() != "erreur avant persistance" {
		t.Errorf("L’erreur du hook BeforePersist doit être propagée, reçu: %v", err)
	}
}

func TestSessionManager_PersistenceHooks_OnPersistError(t *testing.T) {
	mockEngine := &mockPersistenceEngine{shouldFail: true}
	manager := NewSessionManager(SessionConfig{SessionID: "persist-fail-test"}, mockEngine)
	ctx := context.Background()
	var onErrorCalled bool

	manager.RegisterPersistenceHook(BeforePersistHook, func(ev SessionEvent) error { return nil })
	manager.RegisterPersistenceHook(AfterPersistHook, func(ev SessionEvent) error {
		t.Errorf("AfterPersist ne doit pas être appelé en cas d’erreur de persistance")
		return nil
	})
	manager.RegisterPersistenceHook(OnPersistErrorHook, func(ev SessionEvent) error {
		if ev.Type != "persist_error" {
			t.Errorf("Type d'événement attendu: persist_error, reçu: %s", ev.Type)
		}
		onErrorCalled = true
		return nil
	})

	err := manager.persist(ctx)
	if err == nil || err.Error() != "mock persist error" {
		t.Errorf("L’erreur de persistance doit être propagée, reçu: %v", err)
	}
	if !onErrorCalled {
		t.Error("Le hook OnPersistError doit être appelé en cas d’erreur de persistance")
	}
	if !mockEngine.called {
		t.Error("Le mock PersistenceEngine doit être appelé")
	}
}

// Test traçabilité des hooks classiques (RegisterHook, Start/End)
func TestSessionManager_Hooks_TraçabilitéStartEnd(t *testing.T) {
	// Utilisation d'un mock PersistenceEngine qui ne sera pas utilisé ici
	manager := NewSessionManager(SessionConfig{SessionID: "hook-trace-test"}, &mockPersistenceEngine{shouldFail: false})
	ctx := context.Background()
	var events []string

	manager.RegisterHook(func(ev SessionEvent) error {
		events = append(events, ev.Type)
		return nil
	})

	if err := manager.Start(ctx); err != nil {
		t.Errorf("Start doit réussir, erreur reçue: %v", err)
	}
	if err := manager.End(ctx); err != nil {
		t.Errorf("End doit réussir, erreur reçue: %v", err)
	}
	if len(events) != 2 || events[0] != "start" || events[1] != "end" {
		t.Errorf("Traçabilité des hooks incorrecte, events: %v", events)
	}
}

// Test traçabilité/log explicite lors d’un OnPersistError (événement et contexte)
func TestSessionManager_PersistenceHooks_OnPersistError_Trace(t *testing.T) {
	mockEngine := &mockPersistenceEngine{shouldFail: true}
	manager := NewSessionManager(SessionConfig{SessionID: "persist-fail-trace"}, mockEngine)
	ctx := context.Background()
	var trace []string

	manager.RegisterPersistenceHook(BeforePersistHook, func(ev SessionEvent) error { trace = append(trace, "before"); return nil })
	manager.RegisterPersistenceHook(AfterPersistHook, func(ev SessionEvent) error { t.Errorf("AfterPersist ne doit pas être appelé"); return nil })
	manager.RegisterPersistenceHook(OnPersistErrorHook, func(ev SessionEvent) error {
		trace = append(trace, "onerror:"+ev.Type+":"+manager.config.SessionID)
		return nil
	})

	err := manager.persist(ctx)
	if err == nil {
		t.Errorf("L’erreur de persistance doit être propagée")
	}
	if len(trace) != 2 || trace[0] != "before" || trace[1] != "onerror:persist_error:persist-fail-trace" {
		t.Errorf("Traçabilité/log OnPersistError incorrecte, trace: %v", trace)
	}
}

// Test : plusieurs hooks du même type sont tous appelés dans l’ordre d’enregistrement
func TestSessionManager_PersistenceHooks_MultiOrder(t *testing.T) {
	manager := NewSessionManager(SessionConfig{SessionID: "multi-hook-test"}, &mockPersistenceEngine{shouldFail: false})
	ctx := context.Background()
	var order []string

	manager.RegisterPersistenceHook(BeforePersistHook, func(ev SessionEvent) error { order = append(order, "before1"); return nil })
	manager.RegisterPersistenceHook(BeforePersistHook, func(ev SessionEvent) error { order = append(order, "before2"); return nil })
	manager.RegisterPersistenceHook(AfterPersistHook, func(ev SessionEvent) error { order = append(order, "after1"); return nil })
	manager.RegisterPersistenceHook(AfterPersistHook, func(ev SessionEvent) error { order = append(order, "after2"); return nil })
	manager.RegisterPersistenceHook(OnPersistErrorHook, func(ev SessionEvent) error { return nil })

	if err := manager.persist(ctx); err != nil {
		t.Errorf("persist doit réussir, erreur reçue: %v", err)
	}
	if len(order) != 4 || order[0] != "before1" || order[1] != "before2" || order[2] != "after1" || order[3] != "after2" {
		t.Errorf("Ordre d’appel des hooks incorrect, reçu: %v", order)
	}
}
