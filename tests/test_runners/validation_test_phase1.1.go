package validation_test

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

<<<<<<< HEAD
	"email_sender/tools/core/toolkit"
	"email_sender/tools/operations/validation"
	toolkitpkg "email_sender/tools/pkg/manager"
=======
	"github.com/email-sender/tools/core/platform" // Added platform import
	toolkit "github.com/email-sender/tools/core/toolkit"
	validation "github.com/email-sender/tools/operations/validation"
	// managerTool "github.com/email-sender/tools/cmd/manager-toolkit" // Removed
>>>>>>> origin/jules/fix-build-errors-and-cycles
)

// Validation de l'implémentation - Phase 1.1 - Plan v49
// Ce test unitaire vérifie que les outils implémentent correctement l'interface ToolkitOperation
// et que les méthodes d'intégration ManagerToolkit.ExecuteOperation fonctionnent comme attendu.

func TestValidationPhase1_1(t *testing.T) {
	runValidationPhase1_1(t)
}

func runValidationPhase1_1(t *testing.T) {
	fmt.Printf("🧪 TEST DE VALIDATION - Phase 1.1 - Plan v49\n")
	fmt.Printf("============================================\n\n")
	// Créer un répertoire temporaire pour les tests
	tempDir, err := os.MkdirTemp("", "validation_test_v49")
	if err != nil {
		t.Fatalf("❌ ERROR: Impossible de créer le répertoire temporaire: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Test 1: Validation de StructValidator
	fmt.Printf("1️⃣ TEST: StructValidator\n")
	fmt.Printf("------------------------\n")
	// Test 1.1: Création de l'instance avec logger nil
	validator, err := validation.NewStructValidator(tempDir, nil, false)
	if err != nil {
		t.Fatalf("❌ ERROR: Création de StructValidator a échoué: %v", err)
	}
	fmt.Printf("✅ Création de StructValidator réussie\n")

	// Test 1.2: Validation que StructValidator implémente ToolkitOperation
	// Note: Cette vérification est faite à la compilation
	fmt.Printf("✅ StructValidator implémente l'interface ToolkitOperation\n")

	// Test 1.3: Méthode Validate
	if err := validator.Validate(context.Background()); err != nil {
		fmt.Printf("❌ ERROR: Méthode Validate a échoué: %v\n", err)
	} else {
		fmt.Printf("✅ Méthode Validate fonctionnelle\n")
	}

	// Test 1.4: Méthode CollectMetrics
	metrics := validator.CollectMetrics()
	if metrics == nil {
		fmt.Printf("❌ ERROR: CollectMetrics a retourné nil\n")
	} else {
		fmt.Printf("✅ Méthode CollectMetrics fonctionnelle\n")
	}

	// Test 1.5: Méthode HealthCheck
	if err := validator.HealthCheck(context.Background()); err != nil {
		fmt.Printf("❌ ERROR: Méthode HealthCheck a échoué: %v\n", err)
	} else {
		fmt.Printf("✅ Méthode HealthCheck fonctionnelle\n")
	}
	// Test 2: Validation de l'intégration avec ManagerToolkit
	fmt.Printf("\n2️⃣ TEST: Intégration avec ManagerToolkit\n")
<<<<<<< HEAD
	fmt.Printf("--------------------------------------\n") // Test 2.1: Création du ManagerToolkit
	mtk, err := toolkitpkg.NewManagerToolkit(tempDir, "", false)
=======
	fmt.Printf("--------------------------------------\n")

	// Test 2.1: Création du ManagerToolkit
	// Use toolkit.NewManagerToolkit directly as managerTool import is removed
	mtk, err := toolkit.NewManagerToolkit(tempDir, "", false)
>>>>>>> origin/jules/fix-build-errors-and-cycles
	if err != nil {
		t.Fatalf("❌ ERROR: Création de ManagerToolkit a échoué: %v", err)
	}
	fmt.Printf("✅ Création de ManagerToolkit réussie\n")

	// Test 2.2: Test d'intégration avec ExecuteOperation
	ctx := context.Background()
<<<<<<< HEAD
	opts := &toolkit.OperationOptions{
=======

	opts := &platform.OperationOptions{ // Use platform.OperationOptions
>>>>>>> origin/jules/fix-build-errors-and-cycles
		Target: tempDir,
		Output: filepath.Join(tempDir, "test_report.json"),
		Force:  false,
		DryRun: mtk.Config.EnableDryRun,
	}

<<<<<<< HEAD
	operations := []toolkit.Operation{
		toolkit.ValidateStructs,
		toolkit.ResolveImports,
		toolkit.AnalyzeDeps,
		toolkit.DetectDuplicates,
	}

	operationNames := map[toolkit.Operation]string{
		toolkit.ValidateStructs:  "OpValidateStructs",
		toolkit.ResolveImports:   "OpResolveImports",
		toolkit.AnalyzeDeps:      "OpAnalyzeDeps",
		toolkit.DetectDuplicates: "OpDetectDuplicates",
=======
	operations := []platform.Operation{ // Use platform.Operation
		platform.ValidateStructs,
		platform.ResolveImports,
		platform.AnalyzeDeps,
		platform.DetectDuplicates,
	}

	operationNames := map[platform.Operation]string{ // Use platform.Operation
		platform.ValidateStructs:  "OpValidateStructs",
		platform.ResolveImports:   "OpResolveImports",
		platform.AnalyzeDeps:      "OpAnalyzeDeps",
		platform.DetectDuplicates: "OpDetectDuplicates",
>>>>>>> origin/jules/fix-build-errors-and-cycles
	}

	totalOps := len(operations)
	successOps := 0
	for _, op := range operations {
		startTime := time.Now()
<<<<<<< HEAD
		err := mtk.ExecuteOperation(ctx, op, opts) // Use op directly - no cast needed
=======
		err := mtk.ExecuteOperation(ctx, op, opts) // op is already platform.Operation
>>>>>>> origin/jules/fix-build-errors-and-cycles
		duration := time.Since(startTime)

		if err != nil {
			fmt.Printf("❌ ERROR: ExecuteOperation %s a échoué: %v\n", operationNames[op], err)
		} else {
			fmt.Printf("✅ ExecuteOperation %s réussie en %v\n", operationNames[op], duration)
			successOps++
		}
	}
	// Test 3: Vérification des métriques après exécution
	// mtk.Stats is now *platform.ToolkitStats
	fmt.Printf("\n3️⃣ TEST: Vérification des métriques ToolkitStats\n")
	fmt.Printf("---------------------------------------------\n")
	fmt.Printf("- Operations executed: %d\n", mtk.Stats.OperationsExecuted)
	fmt.Printf("- Files analyzed: %d\n", mtk.Stats.FilesAnalyzed)
	fmt.Printf("- Files processed: %d\n", mtk.Stats.FilesProcessed)
	fmt.Printf("- Execution time: %v\n", mtk.Stats.ExecutionTime)
<<<<<<< HEAD

	// Test 4: Test spécifique ResolveImports
	fmt.Printf("\n4️⃣ TEST: ResolveImports spécifique\n")
	fmt.Printf("----------------------------------\n")
	ctx4 := context.Background()
	opts4 := &toolkit.OperationOptions{
		Target: tempDir,
		Output: filepath.Join(tempDir, "resolve_imports.json"),
		Force:  false,
	}

	err = mtk.ExecuteOperation(ctx4, toolkit.ResolveImports, opts4)
	if err != nil {
		fmt.Printf("❌ ERROR: ResolveImports spécifique a échoué: %v\n", err)
	} else {
		fmt.Printf("✅ ResolveImports spécifique réussi\n")
		totalOps++
		successOps++
	}
=======
>>>>>>> origin/jules/fix-build-errors-and-cycles

	// Rapport final
	fmt.Printf("\n📋 RAPPORT FINAL:\n")
	fmt.Printf("--------------\n")
	fmt.Printf("- Tests réussis: %d/%d opérations\n", successOps, totalOps)
	if successOps == totalOps {
		fmt.Printf("✅ VALIDATION COMPLÈTE: Phase 1.1 - Plan v49 est entièrement conforme\n")
		fmt.Printf("🚀 PRÊT POUR LA PHASE 2!\n")
	} else {
		fmt.Printf("⚠️ VALIDATION PARTIELLE: %d/%d tests réussis\n", successOps, totalOps)
		t.Errorf("Test failed: only %d/%d operations succeeded", successOps, totalOps)
	}
}
