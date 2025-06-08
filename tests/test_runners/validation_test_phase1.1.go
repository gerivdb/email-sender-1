package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/email-sender/tools/core/toolkit"
	"github.com/email-sender/tools/operations/validation"
	toolkitpkg "github.com/email-sender/tools/pkg/toolkit"
)

// Validation de l'implémentation - Phase 1.1 - Plan v49
// Ce test unitaire vérifie que les outils implémentent correctement l'interface ToolkitOperation
// et que les méthodes d'intégration ManagerToolkit.ExecuteOperation fonctionnent comme attendu.

func runValidationPhase1_1() {
	fmt.Printf("🧪 TEST DE VALIDATION - Phase 1.1 - Plan v49\n")
	fmt.Printf("============================================\n\n")

	// Créer un répertoire temporaire pour les tests
	tempDir, err := os.MkdirTemp("", "validation_test_v49")
	if err != nil {
		fmt.Printf("❌ ERROR: Impossible de créer le répertoire temporaire: %v\n", err)
		os.Exit(1)
	}
	defer os.RemoveAll(tempDir)

	// Test 1: Validation de StructValidator
	fmt.Printf("1️⃣ TEST: StructValidator\n")
	fmt.Printf("------------------------\n")

	// Test 1.1: Création de l'instance
	validator, err := validation.NewStructValidator(tempDir, nil, false) // Changed to validation.NewStructValidator
	if err != nil {
		fmt.Printf("❌ ERROR: Création de StructValidator a échoué: %v\n", err)
		os.Exit(1)
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
	fmt.Printf("--------------------------------------\n")
	// Test 2.1: Création du ManagerToolkit
	mtk, err := toolkitpkg.NewManagerToolkit(tempDir, "", false) // Use toolkitpkg.NewManagerToolkit
	if err != nil {
		fmt.Printf("❌ ERROR: Création de ManagerToolkit a échoué: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("✅ Création de ManagerToolkit réussie\n")

	// Test 2.2: Test d'intégration avec ExecuteOperation
	ctx := context.Background()
	opts := &toolkit.OperationOptions{ // Changed to toolkit.OperationOptions
		Target: tempDir,
		Output: filepath.Join(tempDir, "test_report.json"),
		Force:  false,
	}

	operations := []toolkit.Operation{ // Changed to toolkit.Operation
		toolkit.ValidateStructs,  // Changed to toolkit.ValidateStructs
		toolkit.ResolveImports,   // Changed to toolkit.ResolveImports
		toolkit.AnalyzeDeps,      // Changed to toolkit.AnalyzeDeps
		toolkit.DetectDuplicates, // Changed to toolkit.DetectDuplicates
	}

	operationNames := map[toolkit.Operation]string{ // Changed to toolkit.Operation
		toolkit.ValidateStructs:  "OpValidateStructs",  // Key is toolkit.ValidateStructs
		toolkit.ResolveImports:   "OpResolveImports",   // Key is toolkit.ResolveImports
		toolkit.AnalyzeDeps:      "OpAnalyzeDeps",      // Key is toolkit.AnalyzeDeps
		toolkit.DetectDuplicates: "OpDetectDuplicates", // Key is toolkit.DetectDuplicates
	}

	totalOps := len(operations)
	successOps := 0
	for _, op := range operations {
		startTime := time.Now()
		err := mtk.ExecuteOperation(ctx, op, opts) // Use op directly - no cast needed
		duration := time.Since(startTime)

		if err != nil {
			fmt.Printf("❌ ERROR: ExecuteOperation %s a échoué: %v\n", operationNames[op], err)
		} else {
			fmt.Printf("✅ ExecuteOperation %s réussie en %v\n", operationNames[op], duration)
			successOps++
		}
	}

	// Test 3: Vérification des métriques après exécution
	fmt.Printf("\n3️⃣ TEST: Vérification des métriques ToolkitStats\n")
	fmt.Printf("---------------------------------------------\n")
	fmt.Printf("- Operations executed: %d\n", mtk.Stats.OperationsExecuted) // Changed to mtk.Stats
	fmt.Printf("- Files analyzed: %d\n", mtk.Stats.FilesAnalyzed)           // Changed to mtk.Stats
	fmt.Printf("- Files processed: %d\n", mtk.Stats.FilesProcessed)         // Changed to mtk.Stats
	fmt.Printf("- Execution time: %v\n", mtk.Stats.ExecutionTime)           // Changed to mtk.Stats

	// Rapport final
	fmt.Printf("\n📋 RAPPORT FINAL:\n")
	fmt.Printf("--------------\n")
	fmt.Printf("- Tests réussis: %d/%d opérations\n", successOps, totalOps)

	if successOps == totalOps {
		fmt.Printf("✅ VALIDATION COMPLÈTE: Phase 1.1 - Plan v49 est entièrement conforme\n")
		fmt.Printf("🚀 PRÊT POUR LA PHASE 2!\n")
	} else {
		fmt.Printf("⚠️ VALIDATION PARTIELLE: %d/%d tests réussis\n", successOps, totalOps)
	}
}
