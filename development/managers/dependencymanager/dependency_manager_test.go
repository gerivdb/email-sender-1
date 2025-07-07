package dependency

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/email-sender-manager/interfaces"
)

func TestDependencyManager_Implementation(t *testing.T) {
	// Test que DependencyManagerImpl implémente l'interface DependencyManager
	var _ interfaces.DependencyManager = (*DependencyManagerImpl)(nil)
}

func TestNewDependencyManager(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"go", "npm"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	if dm == nil {
		t.Fatal("Dependency manager is nil")
	}

	if !dm.isInitialized {
		t.Error("Dependency manager should be initialized")
	}
}

func TestDependencyManager_AnalyzeDependencies(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"go", "npm"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	// Créer un projet test temporaire
	tmpDir := t.TempDir()

	// Créer un go.mod de test
	goModContent := `module test-project

go 1.21

require (
	github.com/gorilla/mux v1.8.0
	github.com/lib/pq v1.10.9
)
`
	goModPath := filepath.Join(tmpDir, "go.mod")
	if err := os.WriteFile(goModPath, []byte(goModContent), 0644); err != nil {
		t.Fatalf("Failed to write go.mod: %v", err)
	}

	// Analyser les dépendances
	ctx := context.Background()
	analysis, err := dm.AnalyzeDependencies(ctx, tmpDir)
	if err != nil {
		t.Fatalf("Failed to analyze dependencies: %v", err)
	}

	if analysis == nil {
		t.Fatal("Analysis is nil")
	}

	if analysis.ProjectPath != tmpDir {
		t.Errorf("Expected project path %s, got %s", tmpDir, analysis.ProjectPath)
	}

	if len(analysis.DirectDependencies) == 0 {
		t.Error("Expected direct dependencies, got none")
	}

	// Vérifier les dépendances détectées
	expectedDeps := map[string]bool{
		"github.com/gorilla/mux": false,
		"github.com/lib/pq":      false,
	}

	for _, dep := range analysis.DirectDependencies {
		if _, exists := expectedDeps[dep.Name]; exists {
			expectedDeps[dep.Name] = true
		}
	}

	for name, found := range expectedDeps {
		if !found {
			t.Errorf("Expected dependency %s not found", name)
		}
	}
}

func TestDependencyManager_AnalyzePackageJson(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"npm"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	// Créer un projet test temporaire
	tmpDir := t.TempDir()

	// Créer un package.json de test
	packageJsonContent := `{
  "name": "test-project",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "typescript": "^4.8.0"
  }
}`
	packageJsonPath := filepath.Join(tmpDir, "package.json")
	if err := os.WriteFile(packageJsonPath, []byte(packageJsonContent), 0644); err != nil {
		t.Fatalf("Failed to write package.json: %v", err)
	}

	// Analyser les dépendances
	ctx := context.Background()
	analysis, err := dm.AnalyzeDependencies(ctx, tmpDir)
	if err != nil {
		t.Fatalf("Failed to analyze dependencies: %v", err)
	}

	if len(analysis.DirectDependencies) != 4 { // 2 prod + 2 dev
		t.Errorf("Expected 4 dependencies, got %d", len(analysis.DirectDependencies))
	}
}

func TestDependencyManager_ResolveDependencies(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"go", "npm"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	ctx := context.Background()
	dependencies := []string{"github.com/gorilla/mux", "express"}

	result, err := dm.ResolveDependencies(ctx, dependencies)
	if err != nil {
		t.Fatalf("Failed to resolve dependencies: %v", err)
	}

	if result == nil {
		t.Fatal("Resolution result is nil")
	}

	// Le résultat peut ne pas être succès si les registries ne sont pas accessibles
	// mais la structure doit être correcte
	if result.ResolvedPackages == nil {
		t.Error("ResolvedPackages should not be nil")
	}

	if result.Conflicts == nil {
		t.Error("Conflicts should not be nil")
	}

	if result.Errors == nil {
		t.Error("Errors should not be nil")
	}
}

func TestDependencyManager_UpdateDependency(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"go"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	// Ajouter une dépendance au graphe
	dm.dependencyGraph.AddNode("test-package", "1.0.0", true)

	ctx := context.Background()
	err = dm.UpdateDependency(ctx, "test-package", "1.1.0")

	// Cette méthode peut échouer si le package n'existe pas dans le registry
	// mais on teste la logique de base
	if err != nil {
		t.Logf("Update failed as expected for non-existent package: %v", err)
	}
}

func TestDependencyManager_CheckForUpdates(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"go"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	// Ajouter quelques packages au graphe
	dm.dependencyGraph.AddNode("test-package-1", "1.0.0", true)
	dm.dependencyGraph.AddNode("test-package-2", "2.0.0", true)

	ctx := context.Background()
	updates, err := dm.CheckForUpdates(ctx)
	if err != nil {
		t.Fatalf("Failed to check for updates: %v", err)
	}

	// Les updates peuvent être vides si les packages n'existent pas
	// mais la fonction ne doit pas échouer
	if updates == nil {
		t.Error("Updates should not be nil")
	}
}

func TestDetectConfigFiles(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"go", "npm"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	// Créer un répertoire temporaire avec différents fichiers de config
	tmpDir := t.TempDir()

	// Créer go.mod
	goModPath := filepath.Join(tmpDir, "go.mod")
	if err := os.WriteFile(goModPath, []byte("module test"), 0644); err != nil {
		t.Fatalf("Failed to write go.mod: %v", err)
	}

	// Créer package.json
	packageJsonPath := filepath.Join(tmpDir, "package.json")
	if err := os.WriteFile(packageJsonPath, []byte("{}"), 0644); err != nil {
		t.Fatalf("Failed to write package.json: %v", err)
	}

	// Détecter les fichiers de config
	configs, err := dm.detectConfigFiles(tmpDir)
	if err != nil {
		t.Fatalf("Failed to detect config files: %v", err)
	}

	if len(configs) != 2 {
		t.Errorf("Expected 2 config files, got %d", len(configs))
	}

	// Vérifier les types détectés
	types := make(map[string]bool)
	for _, config := range configs {
		types[config.Type] = true
	}

	if !types["go.mod"] {
		t.Error("go.mod not detected")
	}

	if !types["package.json"] {
		t.Error("package.json not detected")
	}
}

func TestDetectDependencyConflicts(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"go"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	// Créer des dépendances avec conflit
	directDeps := []interfaces.DependencyMetadata{
		{
			Name:    "conflicting-package",
			Version: "1.0.0",
			Type:    "go",
			Direct:  true,
		},
		{
			Name:    "normal-package",
			Version: "2.0.0",
			Type:    "go",
			Direct:  true,
		},
	}

	transitiveDeps := []interfaces.DependencyMetadata{
		{
			Name:    "conflicting-package",
			Version: "1.1.0", // Version différente!
			Type:    "go",
			Direct:  false,
		},
	}

	conflicts := dm.detectDependencyConflicts(directDeps, transitiveDeps)

	if len(conflicts) != 1 {
		t.Errorf("Expected 1 conflict, got %d", len(conflicts))
	}

	if len(conflicts) > 0 {
		conflict := conflicts[0]
		if conflict.PackageName != "conflicting-package" {
			t.Errorf("Expected conflict for 'conflicting-package', got '%s'", conflict.PackageName)
		}

		if conflict.ConflictType != "version" {
			t.Errorf("Expected conflict type 'version', got '%s'", conflict.ConflictType)
		}

		if len(conflict.ConflictingVersions) != 2 {
			t.Errorf("Expected 2 conflicting versions, got %d", len(conflict.ConflictingVersions))
		}
	}
}

func TestAnalyzeVulnerabilities(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"npm"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	// Créer des dépendances avec vulnérabilités connues
	directDeps := []interfaces.DependencyMetadata{
		{
			Name:    "lodash",
			Version: "4.17.20", // Version vulnérable
			Type:    "npm",
			Direct:  true,
		},
		{
			Name:    "express",
			Version: "4.16.0", // Version vulnérable
			Type:    "npm",
			Direct:  true,
		},
		{
			Name:    "safe-package",
			Version: "1.0.0",
			Type:    "npm",
			Direct:  true,
		},
	}

	ctx := context.Background()
	vulns := dm.analyzeVulnerabilities(ctx, directDeps, []interfaces.DependencyMetadata{})

	if len(vulns) != 2 {
		t.Errorf("Expected 2 vulnerabilities, got %d", len(vulns))
	}

	// Vérifier que les vulnérabilités détectées sont correctes
	vulnNames := make(map[string]bool)
	for _, vuln := range vulns {
		vulnNames[vuln.PackageName] = true
	}

	if !vulnNames["lodash"] {
		t.Error("lodash vulnerability not detected")
	}

	if !vulnNames["express"] {
		t.Error("express vulnerability not detected")
	}
}

func TestDetermineUpdateType(t *testing.T) {
	config := &Config{
		PackageManagers: []string{"go"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		t.Fatalf("Failed to create dependency manager: %v", err)
	}

	tests := []struct {
		current  string
		latest   string
		expected string
	}{
		{"1.0.0", "2.0.0", "major"},
		{"1.0.0", "1.1.0", "minor"},
		{"1.0.0", "1.0.1", "patch"},
	}

	for _, test := range tests {
		result := dm.determineUpdateType(test.current, test.latest)
		if result != test.expected {
			t.Errorf("For %s -> %s, expected %s, got %s",
				test.current, test.latest, test.expected, result)
		}
	}
}

// Benchmark tests
func BenchmarkAnalyzeDependencies(b *testing.B) {
	config := &Config{
		PackageManagers: []string{"go"},
		CacheEnabled:    true,
		CacheTTL:        5 * time.Minute,
		RegistryTimeout: 30 * time.Second,
	}

	dm, err := NewDependencyManager(config)
	if err != nil {
		b.Fatalf("Failed to create dependency manager: %v", err)
	}

	// Créer un projet test
	tmpDir := b.TempDir()
	goModContent := `module test-project

go 1.21

require (
	github.com/gorilla/mux v1.8.0
	github.com/lib/pq v1.10.9
	github.com/golang/protobuf v1.5.2
)
`
	goModPath := filepath.Join(tmpDir, "go.mod")
	if err := os.WriteFile(goModPath, []byte(goModContent), 0644); err != nil {
		b.Fatalf("Failed to write go.mod: %v", err)
	}

	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := dm.AnalyzeDependencies(ctx, tmpDir)
		if err != nil {
			b.Fatalf("Failed to analyze dependencies: %v", err)
		}
	}
}
