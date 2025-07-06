package tests

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/interfaces" // New import
	"golang.org/x/mod/modfile"                                          // New import
)

// MockDepManager implements interfaces.DepManager for testing
type MockDepManager struct {
	dependencies []interfaces.Dependency
	config       *interfaces.Config
}

func (m *MockDepManager) List() ([]interfaces.Dependency, error) {
	return m.dependencies, nil
}

func (m *MockDepManager) Add(module, version string) error {
	dep := interfaces.Dependency{
		Name:    module,
		Version: version,
	}
	m.dependencies = append(m.dependencies, dep)
	return nil
}

func (m *MockDepManager) Remove(module string) error {
	for i, dep := range m.dependencies {
		if dep.Name == module {
			m.dependencies = append(m.dependencies[:i], m.dependencies[i+1:]...)
			break
		}
	}
	return nil
}

func (m *MockDepManager) Update(module string) error {
	for i, dep := range m.dependencies {
		if dep.Name == module {
			m.dependencies[i].Version = "latest"
			break
		}
	}
	return nil
}

func (m *MockDepManager) Audit() error {
	return nil
}

func (m *MockDepManager) Cleanup() error {
	return nil
}

// Test helper functions
func createTestGoMod(t *testing.T, dir string) string {
	goModContent := `module test

go 1.23

require (
    github.com/gorilla/mux v1.8.1
    github.com/stretchr/testify v1.10.0
)

require (
    github.com/davecgh/go-spew v1.1.1 // indirect
    github.com/pmezard/go-difflib v1.0.0 // indirect
    gopkg.in/yaml.v3 v3.0.1 // indirect
)
`
	modPath := filepath.Join(dir, "go.mod")
	err := os.WriteFile(modPath, []byte(goModContent), 0o644)
	if err != nil {
		t.Fatalf("Failed to create test go.mod: %v", err)
	}
	return modPath
}

func createTestConfig(t *testing.T, dir string) *interfaces.Config {
	config := &interfaces.Config{
		Name:    "dependency-manager",
		Version: "1.0.0",
	}
	config.Settings.LogPath = filepath.Join(dir, "logs")
	config.Settings.LogLevel = "INFO"
	config.Settings.GoModPath = "go.mod"
	config.Settings.AutoTidy = true
	config.Settings.VulnerabilityCheck = false
	config.Settings.BackupOnChange = true

	return config
}

// Unit tests
func TestMockDepManager_List(t *testing.T) {
	manager := &MockDepManager{
		dependencies: []interfaces.Dependency{
			{Name: "github.com/gorilla/mux", Version: "v1.8.1"},
			{Name: "github.com/stretchr/testify", Version: "v1.10.0"},
		},
	}

	deps, err := manager.List()
	if err != nil {
		t.Fatalf("List() failed: %v", err)
	}

	if len(deps) != 2 {
		t.Errorf("Expected 2 dependencies, got %d", len(deps))
	}

	if deps[0].Name != "github.com/gorilla/mux" {
		t.Errorf("Expected first dependency to be github.com/gorilla/mux, got %s", deps[0].Name)
	}
}

func TestMockDepManager_Add(t *testing.T) {
	manager := &MockDepManager{dependencies: []interfaces.Dependency{}}

	err := manager.Add("github.com/pkg/errors", "v0.9.1")
	if err != nil {
		t.Fatalf("Add() failed: %v", err)
	}

	if len(manager.dependencies) != 1 {
		t.Errorf("Expected 1 dependency after add, got %d", len(manager.dependencies))
	}

	if manager.dependencies[0].Name != "github.com/pkg/errors" {
		t.Errorf("Expected added dependency to be github.com/pkg/errors, got %s", manager.dependencies[0].Name)
	}
}

func TestMockDepManager_Remove(t *testing.T) {
	manager := &MockDepManager{
		dependencies: []interfaces.Dependency{
			{Name: "github.com/gorilla/mux", Version: "v1.8.1"},
			{Name: "github.com/pkg/errors", Version: "v0.9.1"},
		},
	}

	err := manager.Remove("github.com/pkg/errors")
	if err != nil {
		t.Fatalf("Remove() failed: %v", err)
	}

	if len(manager.dependencies) != 1 {
		t.Errorf("Expected 1 dependency after remove, got %d", len(manager.dependencies))
	}

	if manager.dependencies[0].Name != "github.com/gorilla/mux" {
		t.Errorf("Expected remaining dependency to be github.com/gorilla/mux, got %s", manager.dependencies[0].Name)
	}
}

func TestMockDepManager_Update(t *testing.T) {
	manager := &MockDepManager{
		dependencies: []interfaces.Dependency{
			{Name: "github.com/gorilla/mux", Version: "v1.8.0"},
		},
	}

	err := manager.Update("github.com/gorilla/mux")
	if err != nil {
		t.Fatalf("Update() failed: %v", err)
	}

	if manager.dependencies[0].Version != "latest" {
		t.Errorf("Expected version to be 'latest', got %s", manager.dependencies[0].Version)
	}
}

func TestGoModParsing(t *testing.T) {
	tempDir := t.TempDir()
	modPath := createTestGoMod(t, tempDir)

	data, err := os.ReadFile(modPath)
	if err != nil {
		t.Fatalf("Failed to read test go.mod: %v", err)
	}

	modFile, err := modfile.Parse(modPath, data, nil)
	if err != nil {
		t.Fatalf("Failed to parse go.mod: %v", err)
	}

	if modFile.Module.Mod.Path != "test" {
		t.Errorf("Expected module path to be 'test', got %s", modFile.Module.Mod.Path)
	}

	if len(modFile.Require) < 2 {
		t.Errorf("Expected at least 2 requirements, got %d", len(modFile.Require))
	}

	// Check for specific dependencies
	found := false
	for _, req := range modFile.Require {
		if req.Mod.Path == "github.com/gorilla/mux" {
			found = true
			if req.Mod.Version != "v1.8.1" {
				t.Errorf("Expected gorilla/mux version v1.8.1, got %s", req.Mod.Version)
			}
			break
		}
	}
	if !found {
		t.Error("github.com/gorilla/mux not found in requirements")
	}
}

func TestConfigLoading(t *testing.T) {
	tempDir := t.TempDir()
	config := createTestConfig(t, tempDir)

	// Test JSON marshaling/unmarshaling
	configJSON, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		t.Fatalf("Failed to marshal config: %v", err)
	}

	var loadedConfig interfaces.Config
	err = json.Unmarshal(configJSON, &loadedConfig)
	if err != nil {
		t.Fatalf("Failed to unmarshal config: %v", err)
	}

	if loadedConfig.Name != config.Name {
		t.Errorf("Expected config name %s, got %s", config.Name, loadedConfig.Name)
	}

	if loadedConfig.Settings.AutoTidy != config.Settings.AutoTidy {
		t.Errorf("Expected AutoTidy %v, got %v", config.Settings.AutoTidy, loadedConfig.Settings.AutoTidy)
	}
}

func TestBackupFunctionality(t *testing.T) {
	tempDir := t.TempDir()
	modPath := createTestGoMod(t, tempDir)

	// Read original content
	originalContent, err := os.ReadFile(modPath)
	if err != nil {
		t.Fatalf("Failed to read original go.mod: %v", err)
	}

	// Create backup
	timestamp := time.Now().Format("20060102_150405")
	backupPath := filepath.Join(tempDir, "go.mod.backup."+timestamp)
	err = os.WriteFile(backupPath, originalContent, 0o644)
	if err != nil {
		t.Fatalf("Failed to create backup: %v", err)
	}

	// Verify backup exists and has same content
	backupContent, err := os.ReadFile(backupPath)
	if err != nil {
		t.Fatalf("Failed to read backup: %v", err)
	}

	if string(originalContent) != string(backupContent) {
		t.Error("Backup content doesn't match original")
	}
}

func TestLogging(t *testing.T) {
	tempDir := t.TempDir()
	logDir := filepath.Join(tempDir, "logs")
	err := os.MkdirAll(logDir, 0o755)
	if err != nil {
		t.Fatalf("Failed to create log directory: %v", err)
	}

	logFile := filepath.Join(logDir, "dependency-manager.log")
	logMessage := "[2025-06-03 20:00:00] [INFO] Test log message\n"

	err = os.WriteFile(logFile, []byte(logMessage), 0o644)
	if err != nil {
		t.Fatalf("Failed to write log: %v", err)
	}

	// Verify log file exists and contains message
	content, err := os.ReadFile(logFile)
	if err != nil {
		t.Fatalf("Failed to read log file: %v", err)
	}

	if string(content) != logMessage {
		t.Errorf("Expected log content %q, got %q", logMessage, string(content))
	}
}

// Benchmark tests
func BenchmarkListDependencies(b *testing.B) {
	manager := &MockDepManager{
		dependencies: make([]interfaces.Dependency, 100),
	}

	// Fill with test data
	for i := 0; i < 100; i++ {
		manager.dependencies[i] = interfaces.Dependency{
			Name:    "github.com/test/package" + string(rune('0'+i%10)),
			Version: "v1.0.0",
		}
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := manager.List()
		if err != nil {
			b.Fatalf("List() failed: %v", err)
		}
	}
}

func BenchmarkAddDependency(b *testing.B) {
	manager := &MockDepManager{dependencies: []interfaces.Dependency{}}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		err := manager.Add("github.com/test/package", "v1.0.0")
		if err != nil {
			b.Fatalf("Add() failed: %v", err)
		}
		// Reset for next iteration
		if len(manager.dependencies) > 1000 {
			manager.dependencies = []interfaces.Dependency{}
		}
	}
}
