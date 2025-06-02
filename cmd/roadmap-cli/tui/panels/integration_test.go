package panels

import (
	"testing"

	"github.com/charmbracelet/lipgloss"
)

func TestNewPanelManagerIntegration(t *testing.T) {
	// Configuration de test
	layout := LayoutConfig{
		Type:        LayoutHorizontal,
		Ratio:       []float64{0.3, 0.7},
		Padding:     1,
		Margin:      1,
		BorderStyle: lipgloss.NormalBorder(),
		Adaptive:    true,
	}

	// Création du gestionnaire de panels
	pm := NewPanelManager(120, 40, layout)

	// Vérifications de base
	if pm == nil {
		t.Fatal("PanelManager ne doit pas être nil")
	}

	if pm.GetContextualManager() == nil {
		t.Fatal("ContextualShortcutManager ne doit pas être nil")
	}

	if pm.GetModeKeyManager() == nil {
		t.Fatal("ModeSpecificKeyManager ne doit pas être nil")
	}

	// Test du mode par défaut
	if pm.GetViewMode() != ViewModeList {
		t.Errorf("Mode par défaut attendu: %v, reçu: %v", ViewModeList, pm.GetViewMode())
	}
}

func TestViewModeChange(t *testing.T) {
	layout := LayoutConfig{Type: LayoutHorizontal}
	pm := NewPanelManager(100, 30, layout)

	// Test de changement de mode
	err := pm.SetViewMode(ViewModeKanban)
	if err != nil {
		t.Fatalf("Erreur lors du changement de mode: %v", err)
	}

	if pm.GetViewMode() != ViewModeKanban {
		t.Errorf("Mode attendu: %v, reçu: %v", ViewModeKanban, pm.GetViewMode())
	}
}

func TestPanelWithContextualShortcuts(t *testing.T) {
	layout := LayoutConfig{Type: LayoutHorizontal}
	pm := NewPanelManager(100, 30, layout)

	// Création d'un panel test
	panel := &Panel{
		ID:        "test-panel",
		Title:     "Test Panel",
		Position:  Position{X: 0, Y: 0},
		Size:      Size{Width: 50, Height: 20},
		Visible:   true,
		Minimized: false,
		ZOrder:    1,
		Resizable: true,
		Movable:   true,
	}

	err := pm.AddPanel(panel)
	if err != nil {
		t.Fatalf("Erreur lors de l'ajout du panel: %v", err)
	}

	// Test de mise à jour du contexte
	pm.UpdateShortcutContext()

	// Test de récupération des raccourcis
	shortcuts := pm.GetAvailableShortcuts()
	if shortcuts == nil {
		t.Fatal("Les raccourcis ne doivent pas être nil")
	}

	// Au minimum, nous devrions avoir quelques raccourcis
	t.Logf("Nombre de raccourcis disponibles: %d", len(shortcuts))
}

func TestContextualShortcutManager(t *testing.T) {
	layout := LayoutConfig{Type: LayoutHorizontal}
	pm := NewPanelManager(100, 30, layout)
	
	csm := pm.GetContextualManager()
	if csm == nil {
		t.Fatal("ContextualShortcutManager ne doit pas être nil")
	}

	// Test de HandleKey avec une touche inexistante
	cmd := csm.HandleKey("nonexistent", "test-panel")
	if cmd != nil {
		t.Error("HandleKey devrait retourner nil pour une touche inexistante")
	}

	// Test de GetAvailableShortcuts
	shortcuts := csm.GetAvailableShortcuts("test-panel")
	if shortcuts == nil {
		t.Fatal("GetAvailableShortcuts ne doit pas retourner nil")
	}
}

func TestModeSpecificKeyManager(t *testing.T) {
	layout := LayoutConfig{Type: LayoutHorizontal}
	pm := NewPanelManager(100, 30, layout)
	
	mskm := pm.GetModeKeyManager()
	if mskm == nil {
		t.Fatal("ModeSpecificKeyManager ne doit pas être nil")
	}

	// Test de SetMode
	err := mskm.SetMode(ViewModeCalendar)
	if err != nil {
		t.Fatalf("Erreur lors du changement de mode: %v", err)
	}

	// Test de GetActiveBindings
	bindings := mskm.GetActiveBindings()
	if bindings == nil {
		t.Fatal("GetActiveBindings ne doit pas retourner nil")
	}

	t.Logf("Nombre de bindings actifs: %d", len(bindings))
}
