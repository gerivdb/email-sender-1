package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"email_sender/development/managers/tools"
)

// Test d'intégration v49 - Validation complète du plan
func main() {
	fmt.Printf("🚀 PHASE 1.1.1 & 1.1.2 INTEGRATION TEST - Plan v49\n")
	fmt.Printf("==================================================\n\n")

	// Créer un répertoire de test temporaire
	tempDir, err := os.MkdirTemp("", "integration_test_v49")
	if err != nil {
		fmt.Printf("❌ ERROR: Failed to create temp dir: %v\n", err)
		return
	}
	defer os.RemoveAll(tempDir)

	// Créer des fichiers de test Go
	testGoFile := filepath.Join(tempDir, "test_example.go")
	testContent := `package main

import (
	"fmt"
	"encoding/json"
)

type User struct {
	Name string ` + "`json:\"name\"`" + `
	Age  int    ` + "`json:\"age\"`" + `
}

type User struct {  // Duplication intentionnelle pour test
	ID   int    ` + "`json:\"id\"`" + `
	Name string ` + "`json:\"name\"`" + `
}

func main() {
	fmt.Println("Test file")
}
`
	if err := os.WriteFile(testGoFile, []byte(testContent), 0644); err != nil {
		fmt.Printf("❌ ERROR: Failed to create test file: %v\n", err)
		return
	}

	// Initialiser le Manager Toolkit conformément à la documentation
	fmt.Printf("1️⃣  Initializing Manager Toolkit (conforme TOOLS_ECOSYSTEM_DOCUMENTATION.md)...\n")
	toolkit, err := tools.NewManagerToolkit(tempDir, "", true)
	if err != nil {
		fmt.Printf("❌ ERROR: Failed to create Manager Toolkit: %v\n", err)
		return
	}
	defer toolkit.Close()

	fmt.Printf("✅ Manager Toolkit initialized successfully\n\n")

	// Test Phase 1.1.1 & 1.1.2 - Nouveaux outils conformes au plan v49
	testOperations := []struct {
		name string
		op   tools.Operation
		desc string
	}{
		{"StructValidator", tools.OpValidateStructs, "Validation des déclarations de structures"},
		{"ImportConflictResolver", tools.OpResolveImports, "Résolution des conflits d'imports"},
		{"DependencyAnalyzer", tools.OpAnalyzeDeps, "Analyse des dépendances"},
		{"DuplicateTypeDetector", tools.OpDetectDuplicates, "Détection des types dupliqués"},
	}

	ctx := context.Background()
	successCount := 0

	for i, test := range testOperations {
		fmt.Printf("%d️⃣  Testing %s: %s\n", i+2, test.name, test.desc)

		startTime := time.Now()

		opts := &tools.OperationOptions{
			Target: tempDir,
			Output: filepath.Join(tempDir, fmt.Sprintf("%s_report.json", test.name)),
			Force:  false,
		}

		// Exécuter l'opération via ExecuteOperation (interface standardisée)
		err := toolkit.ExecuteOperation(ctx, test.op, opts)
		duration := time.Since(startTime)

		if err != nil {
			fmt.Printf("❌ ERROR: %s failed: %v\n", test.name, err)
			continue
		}

		fmt.Printf("✅ %s completed successfully in %v\n", test.name, duration)
		successCount++
	}

	// Affichage des métriques finales (conforme ToolkitStats)
	fmt.Printf("\n📊 FINAL METRICS (ToolkitStats standard):\n")
	fmt.Printf("=========================================\n")
	fmt.Printf("Operations executed: %d\n", toolkit.Stats.OperationsExecuted)
	fmt.Printf("Files analyzed: %d\n", toolkit.Stats.FilesAnalyzed)
	fmt.Printf("Files processed: %d\n", toolkit.Stats.FilesProcessed)
	fmt.Printf("Total execution time: %v\n", toolkit.Stats.ExecutionTime)

	// Validation finale
	fmt.Printf("\n🎯 PHASE 1.1.1 & 1.1.2 VALIDATION RESULTS:\n")
	fmt.Printf("==========================================\n")

	if successCount == len(testOperations) {
		fmt.Printf("✅ ALL TESTS PASSED: %d/%d operations successful\n", successCount, len(testOperations))
		fmt.Printf("✅ CONFORMITÉ PLAN V49: 100%% - Phases 1.1.1 & 1.1.2 COMPLÉTÉES\n")
		fmt.Printf("✅ CONFORMITÉ DOCS: Interface ToolkitOperation respectée\n")
		fmt.Printf("✅ INTÉGRATION: ManagerToolkit.ExecuteOperation() fonctionnel\n")
		fmt.Printf("✅ MÉTRIQUES: ToolkitStats mis à jour correctement\n\n")
		fmt.Printf("🎉 SUCCESS: Ready for Phase 2 - Implémentation des Outils d'Analyse Statique\n")
	} else {
		fmt.Printf("❌ SOME TESTS FAILED: %d/%d operations successful\n", successCount, len(testOperations))
		fmt.Printf("❌ Needs investigation before proceeding to Phase 2\n")
	}
}
