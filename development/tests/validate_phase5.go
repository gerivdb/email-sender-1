package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// === SCRIPT DE VALIDATION PHASE 5 ===

// TestSuite structure pour organiser les suites de tests
type TestSuite struct {
	Name        string
	Path        string
	Description string
	Type        string // "unit", "integration", "benchmark"
	Timeout     time.Duration
	Required    bool
}

// TestResult résultat d'un test
type TestResult struct {
	Suite    TestSuite
	Success  bool
	Duration time.Duration
	Output   string
	Error    string
}

// ValidationReport rapport de validation
type ValidationReport struct {
	StartTime     time.Time
	EndTime       time.Time
	TotalDuration time.Duration
	Results       []TestResult
	Summary       ValidationSummary
}

// ValidationSummary résumé de la validation
type ValidationSummary struct {
	TotalSuites   int
	PassedSuites  int
	FailedSuites  int
	SkippedSuites int
	SuccessRate   float64
	OverallStatus string
}

func main() {
	fmt.Println("=== VALIDATION PHASE 5: TESTS ET VALIDATION ===")
	fmt.Println("Début de la validation automatisée des tests...")

	validator := NewPhase5Validator()
	report := validator.RunValidation()

	validator.PrintReport(report)
	validator.SaveReport(report)

	if report.Summary.SuccessRate < 0.8 {
		fmt.Printf("ÉCHEC: Taux de réussite insuffisant (%.1f%%). Minimum requis: 80%%\n", report.Summary.SuccessRate*100)
		os.Exit(1)
	}

	fmt.Printf("SUCCÈS: Validation Phase 5 terminée avec %.1f%% de réussite\n", report.Summary.SuccessRate*100)
}

// Phase5Validator validateur pour la Phase 5
type Phase5Validator struct {
	suites     []TestSuite
	projectDir string
}

// NewPhase5Validator crée un nouveau validateur
func NewPhase5Validator() *Phase5Validator {
	projectDir, err := os.Getwd()
	if err != nil {
		log.Fatal("Impossible de déterminer le répertoire du projet:", err)
	}

	return &Phase5Validator{
		projectDir: projectDir,
		suites: []TestSuite{
			// Tests unitaires (Phase 5.1.1)
			{
				Name:        "Qdrant Client Unit Tests",
				Path:        "development/tests/unit/qdrant_client_test.go",
				Description: "Tests unitaires du client Qdrant unifié",
				Type:        "unit",
				Timeout:     5 * time.Minute,
				Required:    true,
			},
			{
				Name:        "Vectorization Engine Unit Tests",
				Path:        "development/tests/unit/vectorization_engine_test.go",
				Description: "Tests unitaires du moteur de vectorisation",
				Type:        "unit",
				Timeout:     5 * time.Minute,
				Required:    true,
			},
			// Tests d'intégration (Phase 5.1.2)
			{
				Name:        "Cross-Managers Integration Tests",
				Path:        "development/tests/integration/cross_managers_test.go",
				Description: "Tests d'intégration cross-managers",
				Type:        "integration",
				Timeout:     10 * time.Minute,
				Required:    true,
			},
			{
				Name:        "Extended Cross-Managers Tests",
				Path:        "development/tests/integration/cross_managers_extended_test.go",
				Description: "Tests d'intégration étendus avec end-to-end",
				Type:        "integration",
				Timeout:     15 * time.Minute,
				Required:    true,
			},
			// Benchmarks et tests de performance (Phase 5.2)
			{
				Name:        "Performance Benchmarks",
				Path:        "development/tests/benchmarks/performance_test.go",
				Description: "Benchmarks de performance et tests de charge",
				Type:        "benchmark",
				Timeout:     30 * time.Minute,
				Required:    true,
			},
			{
				Name:        "Python vs Go Comparison",
				Path:        "development/tests/benchmarks/python_vs_go_comparison_test.go",
				Description: "Comparaison de performance Python vs Go",
				Type:        "benchmark",
				Timeout:     20 * time.Minute,
				Required:    false, // Optionnel pour environnements sans Python
			},
		},
	}
}

// RunValidation exécute la validation complète
func (v *Phase5Validator) RunValidation() ValidationReport {
	startTime := time.Now()

	fmt.Printf("Début de la validation à %s\n", startTime.Format("15:04:05"))
	fmt.Printf("Répertoire du projet: %s\n", v.projectDir)
	fmt.Printf("Nombre de suites de tests: %d\n\n", len(v.suites))

	var results []TestResult

	for i, suite := range v.suites {
		fmt.Printf("[%d/%d] Exécution: %s\n", i+1, len(v.suites), suite.Name)
		fmt.Printf("  Type: %s | Timeout: %v | Requis: %v\n", suite.Type, suite.Timeout, suite.Required)

		result := v.runTestSuite(suite)
		results = append(results, result)

		if result.Success {
			fmt.Printf("  ✅ SUCCÈS (%v)\n", result.Duration)
		} else {
			fmt.Printf("  ❌ ÉCHEC (%v)\n", result.Duration)
			if result.Error != "" {
				fmt.Printf("  Erreur: %s\n", result.Error)
			}
		}
		fmt.Println()
	}

	endTime := time.Now()
	totalDuration := endTime.Sub(startTime)

	summary := v.calculateSummary(results)

	return ValidationReport{
		StartTime:     startTime,
		EndTime:       endTime,
		TotalDuration: totalDuration,
		Results:       results,
		Summary:       summary,
	}
}

// runTestSuite exécute une suite de tests
func (v *Phase5Validator) runTestSuite(suite TestSuite) TestResult {
	startTime := time.Now()

	// Vérification de l'existence du fichier
	fullPath := filepath.Join(v.projectDir, suite.Path)
	if _, err := os.Stat(fullPath); os.IsNotExist(err) {
		return TestResult{
			Suite:    suite,
			Success:  false,
			Duration: time.Since(startTime),
			Output:   "",
			Error:    fmt.Sprintf("Fichier de test non trouvé: %s", fullPath),
		}
	}

	// Construction de la commande
	var cmd *exec.Cmd
	var args []string

	switch suite.Type {
	case "unit", "integration":
		// Tests standards
		args = []string{"test", "-v", "-timeout", suite.Timeout.String()}
		packagePath := "./" + filepath.Dir(suite.Path)
		args = append(args, packagePath)

	case "benchmark":
		// Benchmarks
		args = []string{"test", "-v", "-bench=.", "-benchtime=10s", "-timeout", suite.Timeout.String()}
		packagePath := "./" + filepath.Dir(suite.Path)
		args = append(args, packagePath)
	}

	cmd = exec.Command("go", args...)
	cmd.Dir = v.projectDir

	// Exécution avec timeout
	done := make(chan error, 1)
	var output []byte
	var err error

	go func() {
		output, err = cmd.CombinedOutput()
		done <- err
	}()

	select {
	case err = <-done:
		// Test terminé dans les temps
		duration := time.Since(startTime)
		success := err == nil

		var errorMsg string
		if err != nil {
			errorMsg = err.Error()
		}

		return TestResult{
			Suite:    suite,
			Success:  success,
			Duration: duration,
			Output:   string(output),
			Error:    errorMsg,
		}

	case <-time.After(suite.Timeout):
		// Timeout
		if cmd.Process != nil {
			cmd.Process.Kill()
		}

		return TestResult{
			Suite:    suite,
			Success:  false,
			Duration: suite.Timeout,
			Output:   string(output),
			Error:    fmt.Sprintf("Test timeout après %v", suite.Timeout),
		}
	}
}

// calculateSummary calcule le résumé des résultats
func (v *Phase5Validator) calculateSummary(results []TestResult) ValidationSummary {
	totalSuites := len(results)
	passedSuites := 0
	failedSuites := 0
	skippedSuites := 0

	for _, result := range results {
		if result.Success {
			passedSuites++
		} else {
			if strings.Contains(result.Error, "non trouvé") {
				skippedSuites++
			} else {
				failedSuites++
			}
		}
	}

	successRate := float64(passedSuites) / float64(totalSuites)

	var overallStatus string
	if successRate >= 0.9 {
		overallStatus = "EXCELLENT"
	} else if successRate >= 0.8 {
		overallStatus = "BON"
	} else if successRate >= 0.7 {
		overallStatus = "ACCEPTABLE"
	} else {
		overallStatus = "INSUFFISANT"
	}

	return ValidationSummary{
		TotalSuites:   totalSuites,
		PassedSuites:  passedSuites,
		FailedSuites:  failedSuites,
		SkippedSuites: skippedSuites,
		SuccessRate:   successRate,
		OverallStatus: overallStatus,
	}
}

// PrintReport affiche le rapport
func (v *Phase5Validator) PrintReport(report ValidationReport) {
	fmt.Println(strings.Repeat("=", 60))
	fmt.Println("RAPPORT DE VALIDATION PHASE 5")
	fmt.Println(strings.Repeat("=", 60))

	fmt.Printf("Période: %s à %s\n",
		report.StartTime.Format("15:04:05"),
		report.EndTime.Format("15:04:05"))
	fmt.Printf("Durée totale: %v\n\n", report.TotalDuration)

	// Résultats détaillés
	fmt.Println("RÉSULTATS DÉTAILLÉS:")
	fmt.Println(strings.Repeat("-", 40))

	for _, result := range report.Results {
		status := "❌ ÉCHEC"
		if result.Success {
			status = "✅ SUCCÈS"
		}

		fmt.Printf("%s | %s (%v)\n", status, result.Suite.Name, result.Duration)
		if !result.Success && result.Error != "" {
			fmt.Printf("   Erreur: %s\n", result.Error)
		}
	}
	// Résumé
	fmt.Println("\nRÉSUMÉ:")
	fmt.Println(strings.Repeat("-", 20))
	fmt.Printf("Total des suites: %d\n", report.Summary.TotalSuites)
	fmt.Printf("Réussies: %d\n", report.Summary.PassedSuites)
	fmt.Printf("Échouées: %d\n", report.Summary.FailedSuites)
	fmt.Printf("Ignorées: %d\n", report.Summary.SkippedSuites)
	fmt.Printf("Taux de réussite: %.1f%%\n", report.Summary.SuccessRate*100)
	fmt.Printf("Status global: %s\n", report.Summary.OverallStatus)

	// Recommendations
	fmt.Println("\nRECOMMANDATIONS:")
	fmt.Println(strings.Repeat("-", 20))

	if report.Summary.SuccessRate >= 0.9 {
		fmt.Println("✅ Excellente qualité de tests. Phase 5 validée avec succès.")
	} else if report.Summary.SuccessRate >= 0.8 {
		fmt.Println("✅ Bonne qualité de tests. Phase 5 validée.")
		fmt.Println("💡 Considérer l'amélioration des tests échoués pour optimiser la couverture.")
	} else if report.Summary.SuccessRate >= 0.7 {
		fmt.Println("⚠️  Qualité acceptable mais amélioration nécessaire.")
		fmt.Println("🔧 Corriger les tests échoués avant finalisation.")
	} else {
		fmt.Println("❌ Qualité insuffisante. Action requise.")
		fmt.Println("🚨 Corriger immédiatement les problèmes identifiés.")
	}

	if report.Summary.SkippedSuites > 0 {
		fmt.Printf("📁 %d suites ignorées (fichiers manquants). Vérifier l'implémentation.\n", report.Summary.SkippedSuites)
	}
}

// SaveReport sauvegarde le rapport
func (v *Phase5Validator) SaveReport(report ValidationReport) {
	filename := fmt.Sprintf("phase5_validation_report_%s.txt",
		report.StartTime.Format("2006-01-02_15-04-05"))

	file, err := os.Create(filename)
	if err != nil {
		log.Printf("Erreur lors de la création du fichier de rapport: %v", err)
		return
	}
	defer file.Close()

	// Redirection de la sortie vers le fichier pour PrintReport
	oldStdout := os.Stdout
	os.Stdout = file

	v.PrintReport(report)

	os.Stdout = oldStdout

	fmt.Printf("Rapport sauvegardé: %s\n", filename)
}
