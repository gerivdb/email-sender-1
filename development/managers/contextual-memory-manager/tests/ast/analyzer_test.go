// tests/ast/analyzer_test.go
package ast

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/contextual-memory-manager/interfaces"
	"github.com/contextual-memory-manager/internal/ast"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Mock implementations des dépendances
type mockStorageManager struct{}
type mockErrorManager struct{}
type mockConfigManager struct{}
type mockMonitoringManager struct{}

func (m *mockStorageManager) Initialize(ctx context.Context) error { return nil }
func (m *mockStorageManager) Shutdown(ctx context.Context) error   { return nil }
func (m *mockStorageManager) GetStatus(ctx context.Context) interfaces.ManagerStatus {
	return interfaces.ManagerStatus{Name: "MockStorage", Status: "healthy", Initialized: true}
}

func (m *mockErrorManager) Initialize(ctx context.Context) error { return nil }
func (m *mockErrorManager) Shutdown(ctx context.Context) error   { return nil }
func (m *mockErrorManager) GetStatus(ctx context.Context) interfaces.ManagerStatus {
	return interfaces.ManagerStatus{Name: "MockError", Status: "healthy", Initialized: true}
}
func (m *mockErrorManager) LogError(ctx context.Context, component, message string, err error) {}

func (m *mockConfigManager) Initialize(ctx context.Context) error { return nil }
func (m *mockConfigManager) Shutdown(ctx context.Context) error   { return nil }
func (m *mockConfigManager) GetStatus(ctx context.Context) interfaces.ManagerStatus {
	return interfaces.ManagerStatus{Name: "MockConfig", Status: "healthy", Initialized: true}
}

func (m *mockMonitoringManager) Initialize(ctx context.Context) error { return nil }
func (m *mockMonitoringManager) Shutdown(ctx context.Context) error   { return nil }
func (m *mockMonitoringManager) GetStatus(ctx context.Context) interfaces.ManagerStatus {
	return interfaces.ManagerStatus{Name: "MockMonitoring", Status: "healthy", Initialized: true}
}
func (m *mockMonitoringManager) RecordCacheHit(ctx context.Context, hit bool) error { return nil }
func (m *mockMonitoringManager) RecordOperation(ctx context.Context, operation string, duration time.Duration, metadata map[string]interface{}) error {
	return nil
}

func TestASTAnalysisManager_Creation(t *testing.T) {
	manager, err := ast.NewASTAnalysisManager(
		&mockStorageManager{},
		&mockErrorManager{},
		&mockConfigManager{},
		&mockMonitoringManager{},
	)

	require.NoError(t, err)
	assert.NotNil(t, manager)
}

func TestASTAnalysisManager_Initialize(t *testing.T) {
	manager, err := ast.NewASTAnalysisManager(
		&mockStorageManager{},
		&mockErrorManager{},
		&mockConfigManager{},
		&mockMonitoringManager{},
	)
	require.NoError(t, err)

	ctx := context.Background()
	err = manager.Initialize(ctx)
	require.NoError(t, err)

	status := manager.GetStatus(ctx)
	assert.True(t, status.Initialized)
	assert.Equal(t, "healthy", status.Status)
}

func TestASTAnalysisManager_AnalyzeFile(t *testing.T) {
	// Créer un fichier Go temporaire pour les tests
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "test.go")

	testCode := `package main

import (
	"fmt"
	"time"
)

// TestFunction est une fonction de test
func TestFunction(name string, age int) (string, error) {
	if age < 0 {
		return "", fmt.Errorf("age cannot be negative")
	}
	
	return fmt.Sprintf("Hello %s, you are %d years old", name, age), nil
}

// TestStruct est une structure de test
type TestStruct struct {
	Name    string    ` + "`json:\"name\"`" + `
	Age     int       ` + "`json:\"age\"`" + `
	Created time.Time ` + "`json:\"created\"`" + `
}

// TestMethod est une méthode de TestStruct
func (ts *TestStruct) TestMethod() string {
	return ts.Name
}

func main() {
	ts := &TestStruct{
		Name:    "Test",
		Age:     25,
		Created: time.Now(),
	}
	
	result, err := TestFunction(ts.Name, ts.Age)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}
	
	fmt.Printf("Result: %s\n", result)
	fmt.Printf("Method result: %s\n", ts.TestMethod())
}
`

	err := os.WriteFile(testFile, []byte(testCode), 0644)
	require.NoError(t, err)

	// Créer et initialiser le manager
	manager, err := ast.NewASTAnalysisManager(
		&mockStorageManager{},
		&mockErrorManager{},
		&mockConfigManager{},
		&mockMonitoringManager{},
	)
	require.NoError(t, err)

	ctx := context.Background()
	err = manager.Initialize(ctx)
	require.NoError(t, err)

	// Analyser le fichier
	result, err := manager.AnalyzeFile(ctx, testFile)
	require.NoError(t, err)
	assert.NotNil(t, result)

	// Vérifier les résultats
	assert.Equal(t, testFile, result.FilePath)
	assert.Equal(t, "main", result.Package)
	assert.Len(t, result.Imports, 2)   // fmt et time
	assert.Len(t, result.Functions, 3) // TestFunction, TestMethod, main
	assert.Len(t, result.Types, 1)     // TestStruct
	assert.True(t, result.AnalysisDuration > 0)

	// Vérifier les imports
	importPaths := make([]string, len(result.Imports))
	for i, imp := range result.Imports {
		importPaths[i] = imp.Path
	}
	assert.Contains(t, importPaths, "fmt")
	assert.Contains(t, importPaths, "time")

	// Vérifier les fonctions
	functionNames := make([]string, len(result.Functions))
	for i, fn := range result.Functions {
		functionNames[i] = fn.Name
	}
	assert.Contains(t, functionNames, "TestFunction")
	assert.Contains(t, functionNames, "TestMethod")
	assert.Contains(t, functionNames, "main")

	// Vérifier la fonction TestFunction spécifiquement
	var testFunction *interfaces.FunctionInfo
	for _, fn := range result.Functions {
		if fn.Name == "TestFunction" {
			testFunction = &fn
			break
		}
	}
	require.NotNil(t, testFunction)
	assert.True(t, testFunction.IsExported)
	assert.Len(t, testFunction.Parameters, 2)
	assert.Len(t, testFunction.ReturnTypes, 2)
	assert.Greater(t, testFunction.Complexity, 1) // À cause du if

	// Vérifier les types
	assert.Len(t, result.Types, 1)
	testStruct := result.Types[0]
	assert.Equal(t, "TestStruct", testStruct.Name)
	assert.Equal(t, "struct", testStruct.Kind)
	assert.True(t, testStruct.IsExported)
	assert.Len(t, testStruct.Fields, 3) // Name, Age, Created
}

func TestASTAnalysisManager_EnrichContextWithAST(t *testing.T) {
	// Créer un fichier Go temporaire
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "context_test.go")

	testCode := `package test

func ExampleFunction() {
	// Example function for context testing
	println("Hello, World!")
}
`

	err := os.WriteFile(testFile, []byte(testCode), 0644)
	require.NoError(t, err)

	// Créer et initialiser le manager
	manager, err := ast.NewASTAnalysisManager(
		&mockStorageManager{},
		&mockErrorManager{},
		&mockConfigManager{},
		&mockMonitoringManager{},
	)
	require.NoError(t, err)

	ctx := context.Background()
	err = manager.Initialize(ctx)
	require.NoError(t, err)

	// Créer une action de test
	action := interfaces.Action{
		ID:         "test-action",
		Type:       "edit",
		Text:       "Test modification",
		FilePath:   testFile,
		LineNumber: 4, // Ligne à l'intérieur de la fonction
		Timestamp:  time.Now(),
	}

	// Enrichir l'action avec l'AST
	enrichedAction, err := manager.EnrichContextWithAST(ctx, action)
	require.NoError(t, err)
	assert.NotNil(t, enrichedAction)

	// Vérifier l'enrichissement
	assert.Equal(t, action, enrichedAction.OriginalAction)
	assert.NotNil(t, enrichedAction.ASTResult)
	assert.NotNil(t, enrichedAction.ASTContext)

	// Vérifier le contexte AST
	assert.Equal(t, "test", enrichedAction.ASTContext["package"])
	assert.Equal(t, 1, enrichedAction.ASTContext["function_count"])
	assert.Equal(t, 0, enrichedAction.ASTContext["type_count"])
}

func TestASTAnalysisManager_GetStructuralContext(t *testing.T) {
	// Créer un fichier Go temporaire
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "structural_test.go")

	testCode := `package test

type MyStruct struct {
	Field1 string
	Field2 int
}

func (ms *MyStruct) MyMethod() string {
	return ms.Field1
}

func StandaloneFunction() {
	// Function body
	if true {
		println("inside if")
	}
}
`

	err := os.WriteFile(testFile, []byte(testCode), 0644)
	require.NoError(t, err)

	// Créer et initialiser le manager
	manager, err := ast.NewASTAnalysisManager(
		&mockStorageManager{},
		&mockErrorManager{},
		&mockConfigManager{},
		&mockMonitoringManager{},
	)
	require.NoError(t, err)

	ctx := context.Background()
	err = manager.Initialize(ctx)
	require.NoError(t, err)

	// Test contexte dans une fonction
	structuralContext, err := manager.GetStructuralContext(ctx, testFile, 9)
	require.NoError(t, err)
	assert.NotNil(t, structuralContext)
	assert.Equal(t, "function", structuralContext.Scope)
	assert.NotNil(t, structuralContext.CurrentFunction)
	assert.Equal(t, "MyMethod", structuralContext.CurrentFunction.Name)

	// Test contexte dans un type
	structuralContext, err = manager.GetStructuralContext(ctx, testFile, 4)
	require.NoError(t, err)
	assert.NotNil(t, structuralContext)
	assert.Equal(t, "type", structuralContext.Scope)
	assert.NotNil(t, structuralContext.CurrentType)
	assert.Equal(t, "MyStruct", structuralContext.CurrentType.Name)

	// Test contexte au niveau package
	structuralContext, err = manager.GetStructuralContext(ctx, testFile, 1)
	require.NoError(t, err)
	assert.NotNil(t, structuralContext)
	assert.Equal(t, "package", structuralContext.Scope)
}

func TestASTAnalysisManager_Cache(t *testing.T) {
	// Créer un fichier Go temporaire
	tempDir := t.TempDir()
	testFile := filepath.Join(tempDir, "cache_test.go")

	testCode := `package cache

func CachedFunction() {
	println("This should be cached")
}
`

	err := os.WriteFile(testFile, []byte(testCode), 0644)
	require.NoError(t, err)

	// Créer et initialiser le manager
	manager, err := ast.NewASTAnalysisManager(
		&mockStorageManager{},
		&mockErrorManager{},
		&mockConfigManager{},
		&mockMonitoringManager{},
	)
	require.NoError(t, err)

	ctx := context.Background()
	err = manager.Initialize(ctx)
	require.NoError(t, err)

	// Premier appel - cache miss
	start := time.Now()
	result1, err := manager.AnalyzeFile(ctx, testFile)
	duration1 := time.Since(start)
	require.NoError(t, err)
	assert.NotNil(t, result1)

	// Deuxième appel - cache hit (devrait être plus rapide)
	start = time.Now()
	result2, err := manager.AnalyzeFile(ctx, testFile)
	duration2 := time.Since(start)
	require.NoError(t, err)
	assert.NotNil(t, result2)

	// Vérifier que les résultats sont identiques
	assert.Equal(t, result1.FilePath, result2.FilePath)
	assert.Equal(t, result1.Package, result2.Package)
	assert.Len(t, result2.Functions, len(result1.Functions))

	// Le cache hit devrait être plus rapide (avec une marge d'erreur)
	assert.True(t, duration2 < duration1/2, "Cache hit should be significantly faster")

	// Vérifier les statistiques du cache
	stats, err := manager.GetCacheStats(ctx)
	require.NoError(t, err)
	assert.NotNil(t, stats)
	assert.Equal(t, 1, stats.TotalEntries)
	assert.True(t, stats.HitRate > 0)
}

func TestASTAnalysisManager_Shutdown(t *testing.T) {
	manager, err := ast.NewASTAnalysisManager(
		&mockStorageManager{},
		&mockErrorManager{},
		&mockConfigManager{},
		&mockMonitoringManager{},
	)
	require.NoError(t, err)

	ctx := context.Background()
	err = manager.Initialize(ctx)
	require.NoError(t, err)

	// Vérifier que le manager est initialisé
	status := manager.GetStatus(ctx)
	assert.True(t, status.Initialized)

	// Arrêter le manager
	err = manager.Shutdown(ctx)
	require.NoError(t, err)

	// Vérifier que le manager n'est plus initialisé
	status = manager.GetStatus(ctx)
	assert.False(t, status.Initialized)
	assert.Equal(t, "not_initialized", status.Status)
}
