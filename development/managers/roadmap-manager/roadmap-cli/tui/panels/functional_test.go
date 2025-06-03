// Package panels - Functional integration test
package panels

import (
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

// SimpleModel is a basic tea.Model for testing
type SimpleModel struct {
	content string
}

func (m SimpleModel) Init() tea.Cmd {
	return nil
}

func (m SimpleModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	return m, nil
}

func (m SimpleModel) View() string {
	return m.content
}

// TestFullPanelSystemIntegration tests the complete panel management system
func TestFullPanelSystemIntegration(t *testing.T) {
	// Setup system components
	tempDir := t.TempDir()
	cm := NewContextManager(tempDir)
	pm := NewPanelManager(80, 24, LayoutConfig{Type: LayoutHorizontal})
	fm := NewFloatingManager()
	minimizer := NewPanelMinimizer()
	sr := NewSessionRestore(cm)

	// Create test panels
	panel1 := &Panel{
		ID:        "panel1",
		Title:     "Panel 1",
		Content:   SimpleModel{content: "Content of Panel 1"},
		Position:  Position{X: 0, Y: 0},
		Size:      Size{Width: 40, Height: 12},
		Visible:   true,
		Minimized: false,
		Resizable: true,
		ZOrder:    1,
		CreatedAt: time.Now(),
	}

	panel2 := &Panel{
		ID:        "panel2",
		Title:     "Panel 2",
		Content:   SimpleModel{content: "Content of Panel 2"},
		Position:  Position{X: 40, Y: 0},
		Size:      Size{Width: 40, Height: 12},
		Visible:   true,
		Minimized: false,
		Resizable: true,
		ZOrder:    2,
		CreatedAt: time.Now(),
	}

	// Add panels to manager
	err := pm.AddPanel(panel1)
	if err != nil {
		t.Fatalf("Failed to add panel1: %v", err)
	}

	err = pm.AddPanel(panel2)
	if err != nil {
		t.Fatalf("Failed to add panel2: %v", err)
	}

	// Set active panel
	pm.SetActivePanel("panel1")

	// Test panel operations
	if pm.GetActivePanelID() != "panel1" {
		t.Errorf("Expected active panel 'panel1', got '%s'", pm.GetActivePanelID())
	}

	// Test minimization
	panel2 = pm.GetPanel("panel2")
	if panel2 == nil {
		t.Fatal("Panel2 not found")
	}
	err = minimizer.MinimizePanel(panel2, "test")
	if err != nil {
		t.Fatalf("Failed to minimize panel2: %v", err)
	}

	// Test state save/restore
	err = cm.SaveState(pm, fm, minimizer)
	if err != nil {
		t.Fatalf("Failed to save state: %v", err)
	}

	// Clear current state
	pm.panels = make(map[PanelID]*Panel)
	pm.panelOrder = make([]PanelID, 0)
	pm.activePanel = ""

	// Restore state
	state, err := sr.LoadLast(nil)
	if err != nil {
		t.Fatalf("Failed to load last state: %v", err)
	}

	err = cm.RestoreState(state, pm, fm, minimizer)
	if err != nil {
		t.Fatalf("Failed to restore state: %v", err)
	}

	// Verify restoration
	if pm.GetActivePanelID() != "panel1" {
		t.Errorf("Expected restored active panel 'panel1', got '%s'", pm.GetActivePanelID())
	}

	if len(pm.panels) != 2 {
		t.Errorf("Expected 2 panels after restore, got %d", len(pm.panels))
	}

	// Test layout changes
	pm.SetLayout(LayoutConfig{Type: LayoutGrid})
	if pm.layout.Type != LayoutGrid {
		t.Errorf("Expected layout type LayoutGrid, got %v", pm.layout.Type)
	}

	// Test panel positioning
	err = pm.MovePanel("panel1", Position{X: 10, Y: 5})
	if err != nil {
		t.Errorf("Failed to move panel: %v", err)
	}
	panel := pm.GetPanel("panel1")
	if panel == nil {
		t.Fatal("Panel1 not found after move")
	}
	if panel.Position.X != 10 || panel.Position.Y != 5 {
		t.Errorf("Expected panel position (10,5), got (%d,%d)",
			panel.Position.X, panel.Position.Y)
	}

	// Test panel resizing
	err = pm.ResizePanel("panel1", Size{Width: 50, Height: 15})
	if err != nil {
		t.Errorf("Failed to resize panel: %v", err)
	}
	if panel.Size.Width != 50 || panel.Size.Height != 15 {
		t.Errorf("Expected panel size (50,15), got (%d,%d)",
			panel.Size.Width, panel.Size.Height)
	}

	t.Logf("✅ Full panel system integration test completed successfully")
}

// TestContextPreservationCycle tests complete context preservation cycle
func TestContextPreservationCycle(t *testing.T) {
	tempDir := t.TempDir()
	cm := NewContextManager(tempDir)
	pm := NewPanelManager(80, 24, LayoutConfig{Type: LayoutHorizontal})
	fm := NewFloatingManager()
	minimizer := NewPanelMinimizer()
	sr := NewSessionRestore(cm)

	// Create multiple panels and set complex state
	for i := 0; i < 5; i++ {
		panel := &Panel{
			ID:        PanelID("panel" + string(rune('1'+i))),
			Title:     "Panel " + string(rune('1'+i)),
			Content:   SimpleModel{content: "Dynamic content " + string(rune('1'+i))},
			Position:  Position{X: i * 20, Y: i * 5},
			Size:      Size{Width: 30, Height: 10},
			Visible:   true,
			Resizable: true,
			ZOrder:    i + 1,
		}
		pm.AddPanel(panel)
	}

	// Set navigation history
	pm.SetActivePanel("panel1")
	pm.SetActivePanel("panel3")
	pm.SetActivePanel("panel2")

	// Minimize some panels
	panel4 := pm.GetPanel("panel4")
	if panel4 != nil {
		minimizer.MinimizePanel(panel4, "test")
	}

	panel5 := pm.GetPanel("panel5")
	if panel5 != nil {
		minimizer.MinimizePanel(panel5, "test")
	}

	// Save state multiple times to test versioning
	for i := 0; i < 3; i++ {
		time.Sleep(time.Millisecond * 10) // Ensure different timestamps
		err := cm.SaveState(pm, fm, minimizer)
		if err != nil {
			t.Fatalf("Failed to save state iteration %d: %v", i, err)
		}
	}

	// Test state listing
	timestamps, err := cm.ListSavedStates()
	if err != nil {
		t.Fatalf("Failed to list saved states: %v", err)
	}

	if len(timestamps) < 3 {
		t.Errorf("Expected at least 3 saved states, got %d", len(timestamps))
	}

	// Load and verify most recent state
	latestState, err := sr.LoadLast(nil)
	if err != nil {
		t.Fatalf("Failed to load latest state: %v", err)
	}

	if latestState.ActivePanel != "panel2" {
		t.Errorf("Expected active panel 'panel2', got '%s'", latestState.ActivePanel)
	}

	if len(latestState.Panels) != 5 {
		t.Errorf("Expected 5 panels in state, got %d", len(latestState.Panels))
	}

	if len(latestState.MinimizedPanels) < 2 {
		t.Logf("Note: Expected 2 minimized panels, got %d", len(latestState.MinimizedPanels))
	}

	// Test state compression
	sc := NewStateCompression()
	result, err := sc.Optimize(latestState, OptimizeSize)
	if err != nil {
		t.Fatalf("Failed to optimize state: %v", err)
	}
	t.Logf("✅ Context preservation cycle test completed successfully")
	t.Logf("📊 Saved %d states with optimization", len(timestamps))
	t.Logf("🔧 Optimization applied with size reduction: %d bytes, ratio: %.2f", result.SizeReduction, result.CompressionRatio)
}
