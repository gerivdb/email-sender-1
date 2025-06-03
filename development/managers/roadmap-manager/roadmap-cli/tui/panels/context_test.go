package panels

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestContextManager_SaveState(t *testing.T) {
	// Setup
	tempDir := t.TempDir()
	cm := NewContextManager(tempDir)

	// Create a test panel manager
	pm := NewPanelManager(80, 24, LayoutConfig{Type: LayoutHorizontal})

	// Add a test panel
	panel := &Panel{
		ID:       "test1",
		Title:    "Test Panel",
		Position: Position{X: 0, Y: 0},
		Size:     Size{Width: 40, Height: 24},
		Visible:  true,
	}
	pm.AddPanel(panel)
	pm.SetActivePanel("test1")

	// Create minimizer and floating manager
	minimizer := NewPanelMinimizer()
	fm := NewFloatingManager()

	// Save state
	err := cm.SaveState(pm, fm, minimizer)
	if err != nil {
		t.Fatalf("Failed to save state: %v", err)
	}

	// Check that file was created
	files, err := cm.ListSavedStates()
	if err != nil {
		t.Fatalf("Failed to list saved states: %v", err)
	}

	if len(files) == 0 {
		t.Fatal("No saved states found")
	}
}

func TestSessionRestore_LoadLast(t *testing.T) {
	// Setup
	tempDir := t.TempDir()
	cm := NewContextManager(tempDir)
	sr := NewSessionRestore(cm)

	// Create test state
	state := &ContextState{
		Version:     "1.0.0",
		Timestamp:   time.Now(),
		ActivePanel: "test1",
		Panels: map[PanelID]*PanelData{
			"test1": {
				ID:       "test1",
				Title:    "Test Panel",
				Position: Position{X: 0, Y: 0},
				Size:     Size{Width: 40, Height: 24},
				Visible:  true,
			},
		},
		Layout:            LayoutConfig{Type: LayoutHorizontal},
		NavigationHistory: []PanelID{"test1"},
		Shortcuts:         make(map[string]PanelID),
		MinimizedPanels:   make(map[PanelID]*MinimizedState),
		FloatingPanels:    make(map[PanelID]*FloatingPanelData),
		ZOrderStack:       []PanelID{"test1"},
		WindowSize:        Size{Width: 80, Height: 24},
	}

	// Save state first
	err := cm.saveStateToFile(state)
	if err != nil {
		t.Fatalf("Failed to save test state: %v", err)
	}

	// Load last state
	loadedState, err := sr.LoadLast(nil)
	if err != nil {
		t.Fatalf("Failed to load last state: %v", err)
	}

	if loadedState.ActivePanel != "test1" {
		t.Errorf("Expected active panel 'test1', got '%s'", loadedState.ActivePanel)
	}

	if len(loadedState.Panels) != 1 {
		t.Errorf("Expected 1 panel, got %d", len(loadedState.Panels))
	}
}

func TestStateSerializer_Export(t *testing.T) {
	// Setup
	tempDir := t.TempDir()
	cm := NewContextManager(tempDir)
	ss := NewStateSerializer(cm)

	// Create test state
	state := &ContextState{
		Version:     "1.0.0",
		Timestamp:   time.Now(),
		ActivePanel: "test1",
		Panels: map[PanelID]*PanelData{
			"test1": {
				ID:       "test1",
				Title:    "Test Panel",
				Position: Position{X: 0, Y: 0},
				Size:     Size{Width: 40, Height: 24},
				Visible:  true,
			},
		},
		Layout:     LayoutConfig{Type: LayoutHorizontal},
		WindowSize: Size{Width: 80, Height: 24},
	}

	// Export state
	exportPath := filepath.Join(tempDir, "test_export.json")
	result, err := ss.Export(state, exportPath, &ExportOptions{
		Format:      FormatJSON,
		PrettyPrint: true,
	})

	if err != nil {
		t.Fatalf("Failed to export state: %v", err)
	}

	if !result.Success {
		t.Fatal("Export was not successful")
	}

	// Check file exists
	if _, err := os.Stat(exportPath); os.IsNotExist(err) {
		t.Fatal("Export file was not created")
	}

	// Import and verify
	importResult, err := ss.Import(exportPath, &ImportOptions{
		Format:   FormatJSON,
		Validate: true,
	})

	if err != nil {
		t.Fatalf("Failed to import state: %v", err)
	}

	if !importResult.Success {
		t.Fatal("Import was not successful")
	}

	if importResult.State.ActivePanel != "test1" {
		t.Errorf("Expected active panel 'test1', got '%s'", importResult.State.ActivePanel)
	}
}

func TestContextValidator_Verify(t *testing.T) {
	cv := NewContextValidator()

	// Test valid state
	validState := &ContextState{
		Version:     "1.0.0",
		Timestamp:   time.Now(),
		ActivePanel: "test1",
		Panels: map[PanelID]*PanelData{
			"test1": {
				ID:         "test1",
				Title:      "Test Panel",
				Position:   Position{X: 0, Y: 0},
				Size:       Size{Width: 40, Height: 24},
				Visible:    true,
				CreatedAt:  time.Now(),
				LastActive: time.Now(),
			},
		},
		Layout:            LayoutConfig{Type: LayoutHorizontal},
		NavigationHistory: []PanelID{"test1"},
		Shortcuts:         make(map[string]PanelID),
		MinimizedPanels:   make(map[PanelID]*MinimizedState),
		FloatingPanels:    make(map[PanelID]*FloatingPanelData),
		ZOrderStack:       []PanelID{"test1"},
		WindowSize:        Size{Width: 80, Height: 24},
	}

	result, err := cv.Verify(validState, nil)
	if err != nil {
		t.Fatalf("Failed to verify state: %v", err)
	}

	if !result.Valid {
		t.Errorf("Valid state was marked as invalid. Errors: %v", result.Errors)
	}

	// Test invalid state
	invalidState := &ContextState{
		Version:     "",
		Timestamp:   time.Time{},
		ActivePanel: "nonexistent",
		Panels:      make(map[PanelID]*PanelData),
		WindowSize:  Size{Width: -1, Height: -1},
	}

	result, err = cv.Verify(invalidState, nil)
	if err != nil {
		t.Fatalf("Failed to verify invalid state: %v", err)
	}

	if result.Valid {
		t.Error("Invalid state was marked as valid")
	}

	if len(result.Errors) == 0 {
		t.Error("No errors found for invalid state")
	}
}

func TestStateCompression_Optimize(t *testing.T) {
	sc := NewStateCompression()

	// Create test state with some redundant data
	state := &ContextState{
		Version:     "1.0.0",
		Timestamp:   time.Now(),
		ActivePanel: "test1",
		Panels: map[PanelID]*PanelData{
			"test1": {
				ID:          "test1",
				Title:       "Test Panel",
				Position:    Position{X: 0, Y: 0},
				Size:        Size{Width: 40, Height: 24},
				Visible:     true,
				CreatedAt:   time.Now(),
				LastActive:  time.Now().Add(-40 * 24 * time.Hour), // Very old
				ContentData: map[string]interface{}{"large": "data"},
			},
			"test2": {
				ID:          "test2",
				Title:       "Hidden Panel",
				Position:    Position{X: 40, Y: 0},
				Size:        Size{Width: 40, Height: 24},
				Visible:     false,
				CreatedAt:   time.Now(),
				LastActive:  time.Now(),
				ContentData: map[string]interface{}{"large": "data"},
			},
		},
		Layout:            LayoutConfig{Type: LayoutHorizontal},
		NavigationHistory: []PanelID{"test1", "test2", "test1", "test2", "test1"}, // Duplicates
		Shortcuts:         map[string]PanelID{"1": "test1", "2": "nonexistent"},   // Invalid reference
		WindowSize:        Size{Width: 80, Height: 24},
	}

	// Optimize for size
	result, err := sc.Optimize(state, OptimizeSize)
	if err != nil {
		t.Fatalf("Failed to optimize state: %v", err)
	}

	if result.SizeReduction <= 0 {
		t.Error("No size reduction achieved")
	}

	if len(result.Optimizations) == 0 {
		t.Error("No optimizations applied")
	}

	// Check that duplicates were removed from history
	if len(result.OptimizedState.NavigationHistory) >= len(state.NavigationHistory) {
		t.Error("Navigation history was not optimized")
	}

	// Check that invalid shortcut was removed
	if _, exists := result.OptimizedState.Shortcuts["2"]; exists {
		t.Error("Invalid shortcut was not removed")
	}
}

func TestStateCompression_Compress(t *testing.T) {
	sc := NewStateCompression()
	// Set threshold to 0 to ensure compression happens
	sc.SetThreshold(0)

	// Test data that should compress well
	testData := []byte(`{
		"version": "1.0.0",
		"timestamp": "2024-01-01T00:00:00Z",
		"panels": {
			"test1": {"id": "test1", "title": "Test Panel 1"},
			"test2": {"id": "test2", "title": "Test Panel 2"},
			"test3": {"id": "test3", "title": "Test Panel 3"}
		}
	}`)

	result, err := sc.Compress(testData)
	if err != nil {
		t.Fatalf("Failed to compress data: %v", err)
	}

	if result.Ratio >= 1.0 {
		t.Error("No compression achieved")
	}

	if result.CompressedSize >= result.OriginalSize {
		t.Error("Compressed size is not smaller than original")
	}
}

// Helper function to create a temporary context manager
func createTestContextManager(t *testing.T) *ContextManager {
	tempDir := t.TempDir()
	return NewContextManager(tempDir)
}

// Benchmark tests
func BenchmarkContextManager_SaveState(b *testing.B) {
	cm := createTestContextManager(&testing.T{})
	pm := NewPanelManager(80, 24, LayoutConfig{Type: LayoutHorizontal})
	minimizer := NewPanelMinimizer()
	fm := NewFloatingManager()

	// Add some test panels
	for i := 0; i < 5; i++ {
		panel := &Panel{
			ID:       PanelID(fmt.Sprintf("test%d", i)),
			Title:    fmt.Sprintf("Test Panel %d", i),
			Position: Position{X: i * 16, Y: 0},
			Size:     Size{Width: 16, Height: 24},
			Visible:  true,
		}
		pm.AddPanel(panel)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		cm.SaveState(pm, fm, minimizer)
	}
}

func BenchmarkStateCompression_Compress(b *testing.B) {
	sc := NewStateCompression()

	// Create test data
	testData := make([]byte, 1024*10) // 10KB
	for i := range testData {
		testData[i] = byte(i % 256)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		sc.Compress(testData)
	}
}
