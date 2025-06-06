// Manager Toolkit - Duplicate Type Detector Tests
// Version: 3.0.0
// Comprehensive test suite for DuplicateTypeDetector with toolkit.ToolkitOperation interface compliance

package analysis

import (
	"github.com/email-sender/tools/core/toolkit"
	"context"
	"encoding/json"
	"fmt"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// TestNewDuplicateTypeDetector teste la création d'une nouvelle instance
func TestNewDuplicateTypeDetector(t *testing.T) {
	tests := []struct {
		name    string
		baseDir string
		wantErr bool
	}{
		{
			name:    "valid base directory",
			baseDir: os.TempDir(),
			wantErr: false,
		},
		{
			name:    "empty base directory",
			baseDir: "",
			wantErr: false, // Constructor doesn't validate, Validate() does
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			logger := &toolkit.Logger{} // verbose = false
			// if err != nil {
			// 	t.Fatalf("Failed to create logger: %v", err)
			// }
			stats := &toolkit.ToolkitStats{}

			detector := &DuplicateTypeDetector{
				BaseDir: tt.baseDir,
				FileSet: token.NewFileSet(),
				Logger:  logger,
				Stats:   stats,
				DryRun:  false,
			}

			if detector == nil {
				t.Error("Expected DuplicateTypeDetector instance, got nil")
			}

			if detector.BaseDir != tt.baseDir {
				t.Errorf("Expected BaseDir %s, got %s", tt.baseDir, detector.BaseDir)
			}

			if detector.FileSet == nil {
				t.Error("Expected FileSet to be initialized")
			}

			if detector.Logger == nil {
				t.Error("Expected toolkit.Logger to be set")
			}

			if detector.Stats == nil {
				t.Error("Expected Stats to be set")
			}
		})
	}
}

// TestDuplicateTypeDetector_ToolkitOperationInterface teste la conformité avec l'interface toolkit.ToolkitOperation
func TestDuplicateTypeDetector_ToolkitOperationInterface(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "duplicate_detector_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	logger := &toolkit.Logger{} // verbose = false
	// if err != nil {
	// 	t.Fatalf("Failed to create logger: %v", err)
	// }
	stats := &toolkit.ToolkitStats{}

	detector := &DuplicateTypeDetector{
		BaseDir: tempDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	ctx := context.Background()

	t.Run("Execute method", func(t *testing.T) {
		// Créer un fichier Go de test avec des types dupliqués
		testFile1 := filepath.Join(tempDir, "test1.go")
		testContent1 := `package test

type User struct {
	ID   int
	Name string
}

type Config struct {
	Host string
	Port int
}
`
		if err := os.WriteFile(testFile1, []byte(testContent1), 0644); err != nil {
			t.Fatalf("Failed to create test file 1: %v", err)
		}

		testFile2 := filepath.Join(tempDir, "test2.go")
		testContent2 := `package test

type User struct {
	ID   int
	Name string
}

type Settings struct {
	Debug bool
}
`
		if err := os.WriteFile(testFile2, []byte(testContent2), 0644); err != nil {
			t.Fatalf("Failed to create test file 2: %v", err)
		}

		options := &toolkit.OperationOptions{
			Target: tempDir,
			Output: filepath.Join(tempDir, "duplicates_report.json"),
		}

		err := detector.Execute(ctx, options)
		if err != nil {
			t.Errorf("Execute failed: %v", err)
		}

		// Vérifier que le rapport a été généré
		if _, err := os.Stat(options.Output); os.IsNotExist(err) {
			t.Error("Expected report file to be created")
		}

		// Vérifier le contenu du rapport
		reportData, err := os.ReadFile(options.Output)
		if err != nil {
			t.Fatalf("Failed to read report: %v", err)
		}

		var report DuplicationReport
		if err := json.Unmarshal(reportData, &report); err != nil {
			t.Fatalf("Failed to parse report JSON: %v", err)
		}

		if report.Tool != "DuplicateTypeDetector" {
			t.Errorf("Expected tool name 'DuplicateTypeDetector', got %s", report.Tool)
		}

		if report.FilesAnalyzed != 2 {
			t.Errorf("Expected 2 files analyzed, got %d", report.FilesAnalyzed)
		}

		if report.DuplicatesFound == 0 {
			t.Error("Expected to find duplicates")
		}
	})

	t.Run("Validate method", func(t *testing.T) {
		// Test avec configuration valide
		err := detector.Validate(ctx)
		if err != nil {
			t.Errorf("Validate failed with valid config: %v", err)
		}

		// Test avec BaseDir vide
		detector.BaseDir = ""
		err = detector.Validate(ctx)
		if err == nil {
			t.Error("Expected Validate to fail with empty BaseDir")
		}

		// Test avec toolkit.Logger nil
		detector.BaseDir = tempDir
		detector.Logger = nil
		err = detector.Validate(ctx)
		if err == nil {
			t.Error("Expected Validate to fail with nil Logger")
		}

		// Restore toolkit.Logger for other tests
		detector.Logger = logger // Restore the original logger instance

		// Test avec répertoire inexistant
		detector.BaseDir = "/nonexistent/directory"
		err = detector.Validate(ctx)
		if err == nil {
			t.Error("Expected Validate to fail with nonexistent directory")
		}

		// Restore baseDir
		detector.BaseDir = tempDir
	})

	t.Run("HealthCheck method", func(t *testing.T) {
		err := detector.HealthCheck(ctx)
		if err != nil {
			t.Errorf("HealthCheck failed: %v", err)
		}

		// Test avec FileSet nil
		detector.FileSet = nil
		err = detector.HealthCheck(ctx)
		if err == nil {
			t.Error("Expected HealthCheck to fail with nil FileSet")
		}

		// Restore FileSet
		detector.FileSet = token.NewFileSet()

		// Test avec répertoire inexistant
		detector.BaseDir = "/nonexistent/directory"
		err = detector.HealthCheck(ctx)
		if err == nil {
			t.Error("Expected HealthCheck to fail with nonexistent directory")
		}

		// Restore baseDir
		detector.BaseDir = tempDir
	})

	t.Run("CollectMetrics method", func(t *testing.T) {
		metrics := detector.CollectMetrics()
		if metrics == nil {
			t.Error("Expected metrics map, got nil")
		}

		expectedKeys := []string{"tool", "files_analyzed", "duplicates_found", "dry_run_mode", "base_directory"}
		for _, key := range expectedKeys {
			if _, exists := metrics[key]; !exists {
				t.Errorf("Expected metric key %s not found", key)
			}
		}

		if metrics["tool"] != "DuplicateTypeDetector" {
			t.Errorf("Expected tool name 'DuplicateTypeDetector', got %v", metrics["tool"])
		}

		if metrics["dry_run_mode"] != false {
			t.Errorf("Expected dry_run_mode false, got %v", metrics["dry_run_mode"])
		}
	})
}

// TestDuplicateTypeDetector_DetectDuplicates teste la détection de types dupliqués
func TestDuplicateTypeDetector_DetectDuplicates(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "duplicate_detector_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	logger := &toolkit.Logger{} // verbose = false
	// if err != nil {
	// 	t.Fatalf("Failed to create logger: %v", err)
	// }
	stats := &toolkit.ToolkitStats{}

	detector := &DuplicateTypeDetector{
		BaseDir: tempDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	tests := []struct {
		name          string
		files         map[string]string
		expectedDupes int
		expectedTypes []string
	}{
		{
			name: "identical struct duplicates",
			files: map[string]string{
				"file1.go": `package test
type User struct {
	ID   int
	Name string
}`,
				"file2.go": `package test
type User struct {
	ID   int
	Name string
}`,
			},
			expectedDupes: 1,
			expectedTypes: []string{"User"},
		},
		{
			name: "different struct signatures",
			files: map[string]string{
				"file1.go": `package test
type User struct {
	ID   int
	Name string
}`,
				"file2.go": `package test
type User struct {
	ID    int
	Name  string
	Email string
}`,
			},
			expectedDupes: 0, // Different signatures, not duplicates
			expectedTypes: []string{},
		},
		{
			name: "interface duplicates",
			files: map[string]string{
				"file1.go": `package test
type Reader interface {
	Read() error
}`,
				"file2.go": `package test
type Reader interface {
	Read() error
}`,
			},
			expectedDupes: 1,
			expectedTypes: []string{"Reader"},
		},
		{
			name: "mixed type duplicates",
			files: map[string]string{
				"file1.go": `package test
type Status string
type Config struct {
	Host string
}`,
				"file2.go": `package test
type Status string
type Config struct {
	Host string
}`,
			},
			expectedDupes: 2,
			expectedTypes: []string{"Status", "Config"},
		},
		{
			name: "no duplicates",
			files: map[string]string{
				"file1.go": `package test
type User struct {
	ID int
}`,
				"file2.go": `package test
type Product struct {
	Name string
}`,
			},
			expectedDupes: 0,
			expectedTypes: []string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Nettoyer le répertoire de test
			os.RemoveAll(tempDir)
			os.MkdirAll(tempDir, 0755)

			// Créer les fichiers de test
			for filename, content := range tt.files {
				filePath := filepath.Join(tempDir, filename)
				if err := os.WriteFile(filePath, []byte(content), 0644); err != nil {
					t.Fatalf("Failed to create test file %s: %v", filename, err)
				}
			}

			// Réinitialiser les stats
			detector.Stats = &toolkit.ToolkitStats{}
			detector.FileSet = token.NewFileSet()

			ctx := context.Background()
			options := &toolkit.OperationOptions{
				Target: tempDir,
				Output: filepath.Join(tempDir, "report.json"),
			}

			err := detector.Execute(ctx, options)
			if err != nil {
				t.Fatalf("Execute failed: %v", err)
			}

			// Lire et vérifier le rapport
			reportData, err := os.ReadFile(options.Output)
			if err != nil {
				t.Fatalf("Failed to read report: %v", err)
			}

			var report DuplicationReport
			if err := json.Unmarshal(reportData, &report); err != nil {
				t.Fatalf("Failed to parse report: %v", err)
			}

			if report.DuplicatesFound != tt.expectedDupes {
				t.Errorf("Expected %d duplicates, got %d", tt.expectedDupes, report.DuplicatesFound)
			}

			// Vérifier les types spécifiques
			foundTypes := make(map[string]bool)
			for _, duplicate := range report.DuplicateTypes {
				foundTypes[duplicate.TypeName] = true
			}

			for _, expectedType := range tt.expectedTypes {
				if !foundTypes[expectedType] {
					t.Errorf("Expected to find duplicate type %s", expectedType)
				}
			}
		})
	}
}

// TestDuplicateTypeDetector_TypeSignatures teste la génération de signatures de types
func TestDuplicateTypeDetector_TypeSignatures(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "signature_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	logger := &toolkit.Logger{} // verbose = false
	// if err != nil {
	// 	t.Fatalf("Failed to create logger: %v", err)
	// }
	stats := &toolkit.ToolkitStats{}
	logger := &toolkit.Logger{} // verbose = false
	// if err != nil {
	// 	t.Fatalf("Failed to create logger: %v", err)
	// }
	stats := &toolkit.ToolkitStats{}

	detector := &DuplicateTypeDetector{
		BaseDir: tempDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	// Test avec différents types pour vérifier les signatures
	testFile := filepath.Join(tempDir, "types.go")
	testContent := `package test

type EmptyStruct struct{}

type SimpleStruct struct {
	ID int
	Name string
}

type EmptyInterface interface{}

type SimpleInterface interface {
	Read() error
	Write() error
}

type StringAlias string

type SliceType []string

type MapType map[string]int
`

	if err := os.WriteFile(testFile, []byte(testContent), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Analyser le fichier
	types, err := detector.analyzeFile(testFile)
	if err != nil {
		t.Fatalf("Failed to analyze file: %v", err)
	}

	expectedSignatures := map[string]string{
		"EmptyStruct":     "struct{}",
		"SimpleStruct":    "struct{2_fields}",
		"EmptyInterface":  "interface{}",
		"SimpleInterface": "interface{2_methods}",
		"StringAlias":     "string",
		"SliceType":       "[]string",
		"MapType":         "map[string]int",
	}

	for _, typeDef := range types {
		expectedSig, exists := expectedSignatures[typeDef.Name]
		if !exists {
			t.Errorf("Unexpected type found: %s", typeDef.Name)
			continue
		}

		if typeDef.Signature != expectedSig {
			t.Errorf("Type %s: expected signature %s, got %s",
				typeDef.Name, expectedSig, typeDef.Signature)
		}
	}
}

// TestDuplicateTypeDetector_SeverityCalculation teste le calcul de sévérité
func TestDuplicateTypeDetector_SeverityCalculation(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "severity_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	logger, err := NewLogger(false) // verbose = false
	if err != nil {
		t.Fatalf("Failed to create logger: %v", err)
	}
	stats := &ToolkitStats{}

	detector := &DuplicateTypeDetector{
		BaseDir: tempDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	// Créer un sous-répertoire pour tester les conflits inter-packages
	subDir := filepath.Join(tempDir, "subpackage")
	os.MkdirAll(subDir, 0755)

	// Fichier dans le package principal
	mainFile := filepath.Join(tempDir, "main.go")
	mainContent := `package main
type User struct {
	ID int
}`

	if err := os.WriteFile(mainFile, []byte(mainContent), 0644); err != nil {
		t.Fatalf("Failed to create main file: %v", err)
	}

	// Fichier dans le sous-package
	subFile := filepath.Join(subDir, "sub.go")
	subContent := `package subpackage
type User struct {
	ID int
}`

	if err := os.WriteFile(subFile, []byte(subContent), 0644); err != nil {
		t.Fatalf("Failed to create sub file: %v", err)
	}

	ctx := context.Background()
	options := &toolkit.OperationOptions{
		Target: tempDir,
		Output: filepath.Join(tempDir, "severity_report.json"),
	}

	err = detector.Execute(ctx, options)
	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	// Lire le rapport
	reportData, err := os.ReadFile(options.Output)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	var report DuplicationReport
	if err := json.Unmarshal(reportData, &report); err != nil {
		t.Fatalf("Failed to parse report: %v", err)
	}

	// Vérifier qu'il y a au moins un doublon de sévérité élevée
	// (car il y a conflit entre packages différents)
	foundHighSeverity := false
	for _, duplicate := range report.DuplicateTypes {
		if duplicate.Severity == "high" {
			foundHighSeverity = true
			break
		}
	}

	if !foundHighSeverity {
		t.Error("Expected at least one high severity duplicate (cross-package conflict)")
	}
}

// TestDuplicateTypeDetector_DryRunMode teste le mode dry-run
func TestDuplicateTypeDetector_DryRunMode(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "dryrun_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	logger := &toolkit.Logger{} // verbose = false
	// if err != nil {
	// 	t.Fatalf("Failed to create logger: %v", err)
	// }
	stats := &toolkit.ToolkitStats{}

	detector := &DuplicateTypeDetector{
		BaseDir: tempDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  true,
	}

	// Créer un fichier de test avec des doublons
	testFile := filepath.Join(tempDir, "test.go")
	testContent := `package test
type User struct {
	ID int
}
type User struct {
	ID int
}
`

	if err := os.WriteFile(testFile, []byte(testContent), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	ctx := context.Background()
	outputFile := filepath.Join(tempDir, "dryrun_report.json")
	options := &toolkit.OperationOptions{
		Target: tempDir,
		Output: outputFile,
	}

	err = detector.Execute(ctx, options)
	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	// En mode dry-run, aucun fichier de rapport ne devrait être créé
	if _, err := os.Stat(outputFile); err == nil {
		t.Error("Expected no report file to be created in dry-run mode")
	}

	// Vérifier les métriques
	metrics := detector.CollectMetrics()
	if metrics["dry_run_mode"] != true {
		t.Error("Expected dry_run_mode to be true in metrics")
	}
}

// TestDuplicateTypeDetector_EdgeCases teste les cas limites
func TestDuplicateTypeDetector_EdgeCases(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "edge_cases_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	logger := &toolkit.Logger{} // verbose = false
	// if err != nil {
	// 	t.Fatalf("Failed to create logger: %v", err)
	// }
	stats := &toolkit.ToolkitStats{}

	detector := &DuplicateTypeDetector{
		BaseDir: tempDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	t.Run("empty directory", func(t *testing.T) {
		emptyDir := filepath.Join(tempDir, "empty")
		os.MkdirAll(emptyDir, 0755)

		ctx := context.Background()
		options := &toolkit.OperationOptions{
			Target: emptyDir,
			Output: filepath.Join(emptyDir, "empty_report.json"),
		}

		err := detector.Execute(ctx, options)
		if err != nil {
			t.Errorf("Execute should not fail on empty directory: %v", err)
		}
	})

	t.Run("invalid Go files", func(t *testing.T) {
		invalidDir := filepath.Join(tempDir, "invalid")
		os.MkdirAll(invalidDir, 0755)

		// Créer un fichier Go invalide
		invalidFile := filepath.Join(invalidDir, "invalid.go")
		invalidContent := `package test
		type User struct {
			// Syntax error
			ID int,,,
		`

		if err := os.WriteFile(invalidFile, []byte(invalidContent), 0644); err != nil {
			t.Fatalf("Failed to create invalid file: %v", err)
		}

		detector.BaseDir = invalidDir
		ctx := context.Background()
		options := &toolkit.OperationOptions{
			Target: invalidDir,
			Output: filepath.Join(invalidDir, "invalid_report.json"),
		}

		// L'exécution ne devrait pas échouer, mais continuer avec les autres fichiers
		err := detector.Execute(ctx, options)
		if err != nil {
			t.Errorf("Execute should not fail on invalid files: %v", err)
		}
	})

	t.Run("test files exclusion", func(t *testing.T) {
		testDir := filepath.Join(tempDir, "testexcl")
		os.MkdirAll(testDir, 0755)

		// Créer un fichier de test (devrait être ignoré)
		testFile := filepath.Join(testDir, "user_test.go")
		testContent := `package test
		type TestUser struct {
			ID int
		}
		`

		if err := os.WriteFile(testFile, []byte(testContent), 0644); err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}

		detector.BaseDir = testDir
		ctx := context.Background()
		options := &toolkit.OperationOptions{
			Target: testDir,
			Output: filepath.Join(testDir, "exclusion_report.json"),
		}

		err := detector.Execute(ctx, options)
		if err != nil {
			t.Fatalf("Execute failed: %v", err)
		}

		// Vérifier que le rapport indique 0 fichiers analysés
		reportData, err := os.ReadFile(options.Output)
		if err != nil {
			t.Fatalf("Failed to read report: %v", err)
		}

		var report DuplicationReport
		if err := json.Unmarshal(reportData, &report); err != nil {
			t.Fatalf("Failed to parse report: %v", err)
		}

		if report.FilesAnalyzed != 0 {
			t.Errorf("Expected 0 files analyzed (test files should be excluded), got %d", report.FilesAnalyzed)
		}
	})

	t.Run("context cancellation", func(t *testing.T) {
		cancelDir := filepath.Join(tempDir, "cancel")
		os.MkdirAll(cancelDir, 0755)

		// Créer plusieurs fichiers pour tester l'annulation
		for i := 0; i < 5; i++ {
			filename := filepath.Join(cancelDir, fmt.Sprintf("file%d.go", i))
			content := fmt.Sprintf(`package test
			type Type%d struct {
				ID int
			}
			`, i)
			if err := os.WriteFile(filename, []byte(content), 0644); err != nil {
				t.Fatalf("Failed to create file %d: %v", i, err)
			}
		}

		detector.BaseDir = cancelDir
		ctx, cancel := context.WithTimeout(context.Background(), 1*time.Nanosecond)
		defer cancel()

		options := &toolkit.OperationOptions{
			Target: cancelDir,
			Output: filepath.Join(cancelDir, "cancel_report.json"),
		}

		err := detector.Execute(ctx, options)
		if err == nil {
			t.Error("Expected Execute to fail with context cancellation")
		}

		if !strings.Contains(err.Error(), "context") {
			t.Errorf("Expected context cancellation error, got: %v", err)
		}
	})
}

// BenchmarkDuplicateTypeDetector_Performance teste les performances
func BenchmarkDuplicateTypeDetector_Performance(b *testing.B) {
	tempDir, err := os.MkdirTemp("", "perf_test")
	if err != nil {
		b.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Créer plusieurs fichiers avec des types pour tester les performances
	for i := 0; i < 50; i++ {
		filename := filepath.Join(tempDir, fmt.Sprintf("file%d.go", i))
		content := fmt.Sprintf(`package test

type User%d struct {
	ID%d   int
	Name%d string
	Age%d  int
}

type Config%d struct {
	Host%d string
	Port%d int
}

type Handler%d interface {
	Handle%d() error
	Process%d() string
}
`, i, i, i, i, i, i, i, i, i, i)

		if err := os.WriteFile(filename, []byte(content), 0644); err != nil {
			b.Fatalf("Failed to create file %d: %v", i, err)
		}
	}

	logger := &toolkit.Logger{} // Réduire les logs pour le benchmark
	// if err != nil {
	// 	b.Fatalf("Failed to create logger: %v", err)
	// }
	stats := &toolkit.ToolkitStats{}

	detector := &DuplicateTypeDetector{
		BaseDir: tempDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  true, // Mode dry-run pour éviter la création de fichiers
	}

	ctx := context.Background()
	options := &toolkit.OperationOptions{
		Target: tempDir,
		Output: "", // Pas de sortie en mode dry-run
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		detector.Stats = &toolkit.ToolkitStats{} // Réinitialiser les stats
		detector.FileSet = token.NewFileSet()

		err := detector.Execute(ctx, options)
		if err != nil {
			b.Fatalf("Execute failed: %v", err)
		}
	}
}

// BenchmarkDuplicateTypeDetector_LargeCodebase teste les performances sur une grande base de code
func BenchmarkDuplicateTypeDetector_LargeCodebase(b *testing.B) {
	tempDir, err := os.MkdirTemp("", "large_perf_test")
	if err != nil {
		b.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Créer une structure de répertoires plus complexe
	dirs := []string{"models", "handlers", "services", "utils", "types"}
	for _, dir := range dirs {
		dirPath := filepath.Join(tempDir, dir)
		os.MkdirAll(dirPath, 0755)

		// Créer des fichiers dans chaque répertoire
		for i := 0; i < 20; i++ {
			filename := filepath.Join(dirPath, fmt.Sprintf("%s_%d.go", dir, i))
			content := fmt.Sprintf(`package %s

type Entity%d struct {
	ID       int64
	Name     string
	Status   string
	Created  time.Time
	Modified time.Time
}

type Repository%d interface {
	Get%d(id int64) (*Entity%d, error)
	Create%d(entity *Entity%d) error
	Update%d(entity *Entity%d) error
	Delete%d(id int64) error
}

type Service%d struct {
	repo Repository%d
}

func (s *Service%d) Process%d() error {
	return nil
}
`, dir, i, i, i, i, i, i, i, i, i, i, i, i)

			if err := os.WriteFile(filename, []byte(content), 0644); err != nil {
				b.Fatalf("Failed to create file %s: %v", filename, err)
			}
		}
	}

	logger := &toolkit.Logger{}
	// if err != nil {
	// 	b.Fatalf("Failed to create logger: %v", err)
	// }
	stats := &toolkit.ToolkitStats{}

	detector := &DuplicateTypeDetector{
		BaseDir: tempDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  true,
	}

	ctx := context.Background()
	options := &toolkit.OperationOptions{
		Target: tempDir,
		Output: "",
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		detector.Stats = &toolkit.ToolkitStats{}
		detector.FileSet = token.NewFileSet()

		err := detector.Execute(ctx, options)
		if err != nil {
			b.Fatalf("Execute failed: %v", err)
		}
	}
}


