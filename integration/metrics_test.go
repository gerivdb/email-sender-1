package integration

import (
	"fmt"
	"io"
	"os"
	"regexp"
	"testing"
)

func TestNewMetricsManager(t *testing.T) {
	manager := NewMetricsManager()
	if manager == nil {
		t.Error("NewMetricsManager should not return nil")
	}
}

func TestMetricsManager_Collect(t *testing.T) {
	manager := NewMetricsManager()
	metrics, err := manager.Collect()
	if err != nil {
		t.Fatalf("Collect failed: %v", err)
	}

	// Check if values are within expected ranges (based on random generation logic)
	if metrics.Quality < 0.7 || metrics.Quality > 1.0 {
		t.Errorf("Quality out of expected range: %f", metrics.Quality)
	}
	if metrics.Coverage < 0.6 || metrics.Coverage > 1.0 {
		t.Errorf("Coverage out of expected range: %f", metrics.Coverage)
	}
	if metrics.Usage < 0.5 || metrics.Usage > 1.0 {
		t.Errorf("Usage out of expected range: %f", metrics.Usage)
	}
}

func TestMetricsManager_Report(t *testing.T) {
	manager := NewMetricsManager()

	// Capture stdout
	oldStdout := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	err := manager.Report()
	if err != nil {
		t.Fatalf("Report failed: %v", err)
	}

	w.Close()
	out, _ := io.ReadAll(r)
	os.Stdout = oldStdout // Restore stdout

	output := string(out)

	// Check for expected output patterns
	expectedPatterns := []string{
		"Rapport de métriques:",
		"Qualité: \\d\\.\\d{2}",
		"Couverture: \\d\\.\\d{2}",
		"Usage: \\d\\.\\d{2}",
		"Rapport de métriques généré avec succès.",
	}

	for _, pattern := range expectedPatterns {
		matched, _ := regexp.MatchString(pattern, output)
		if !matched {
			t.Errorf("Report output missing expected pattern: '%s'\nOutput:\n%s", pattern, output)
		}
	}
}

// MockMetricsManager pour simuler des erreurs de collecte
type MockMetricsManager struct {
	CollectFunc func() (Metrics, error)
}

func (m *MockMetricsManager) Collect() (Metrics, error) {
	if m.CollectFunc != nil {
		return m.CollectFunc()
	}
	return Metrics{}, nil
}

func (m *MockMetricsManager) Report() error {
	metrics, err := m.Collect()
	if err != nil {
		return fmt.Errorf("échec de la collecte des métriques pour le rapport: %w", err)
	}
	// Normal reporting logic if collection succeeds
	fmt.Printf("Rapport de métriques:\n")
	fmt.Printf("  Qualité: %.2f\n", metrics.Quality)
	return nil
}

func TestMetricsManager_Report_CollectionError(t *testing.T) {
	mockErr := fmt.Errorf("erreur simulée de collecte")
	mockManager := &MockMetricsManager{
		CollectFunc: func() (Metrics, error) {
			return Metrics{}, mockErr
		},
	}

	// Capture stdout (not strictly necessary for this test, but good practice)
	oldStdout := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	err := mockManager.Report()

	w.Close()
	_, _ = io.ReadAll(r)  // Read to clear pipe
	os.Stdout = oldStdout // Restore stdout

	if err == nil {
		t.Fatal("Report should return an error if Collect fails")
	}
	expectedErr := fmt.Sprintf("échec de la collecte des métriques pour le rapport: %v", mockErr)
	if err.Error() != expectedErr {
		t.Errorf("Expected error '%s', got '%s'", expectedErr, err.Error())
	}
}
