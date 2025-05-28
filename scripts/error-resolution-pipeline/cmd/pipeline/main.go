// Package main - Point d'entrée principal du pipeline de résolution d'erreurs
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"

	"error-resolution-pipeline/pkg/detector"
	"error-resolution-pipeline/pkg/resolver"
)

const (
	Version = "1.0.0"
	AppName = "Error Resolution Pipeline"
)

// Config représente la configuration globale de l'application
type Config struct {
	TargetPath     string           `json:"target_path"`
	ErrorReports   []string         `json:"error_reports"`
	OutputDir      string           `json:"output_dir"`
	MetricsPort    int              `json:"metrics_port"`
	DetectorConfig *detector.Config `json:"detector"`
	ResolverConfig *resolver.Config `json:"resolver"`
	ProcessingMode string           `json:"processing_mode"`
	EnableMetrics  bool             `json:"enable_metrics"`
	LogLevel       string           `json:"log_level"`
}

// PipelineResults contient les résultats du pipeline
type PipelineResults struct {
	ProcessedAt    time.Time                `json:"processed_at"`
	FilesProcessed int                      `json:"files_processed"`
	ErrorsDetected []detector.DetectedError `json:"errors_detected"`
	FixesApplied   []resolver.FixResult     `json:"fixes_applied"`
	Summary        ProcessingSummary        `json:"summary"`
	Duration       time.Duration            `json:"duration"`
}

// ProcessingSummary résume les résultats du traitement
type ProcessingSummary struct {
	TotalErrors          int     `json:"total_errors"`
	ErrorsFixed          int     `json:"errors_fixed"`
	FixSuccessRate       float64 `json:"fix_success_rate"`
	AverageConfidence    float64 `json:"average_confidence"`
	CriticalIssues       int     `json:"critical_issues"`
	SafeFixesApplied     int     `json:"safe_fixes_applied"`
	ManualReviewRequired int     `json:"manual_review_required"`
}

func main() {
	var (
		configPath = flag.String("config", "src/config/pipeline_config.json", "Path to configuration file")
		targetPath = flag.String("target", "", "Target path to analyze (overrides config)")
		dryRun     = flag.Bool("dry-run", false, "Run in dry-run mode (no changes applied)")
		verbose    = flag.Bool("verbose", false, "Enable verbose logging")
		version    = flag.Bool("version", false, "Show version information")
	)
	flag.Parse()

	if *version {
		fmt.Printf("%s v%s\n", AppName, Version)
		os.Exit(0)
	}

	// Charger la configuration
	config, err := loadConfig(*configPath)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Override avec les paramètres de ligne de commande
	if *targetPath != "" {
		config.TargetPath = *targetPath
	}
	if *dryRun {
		config.ResolverConfig.DryRun = true
	}

	// Configurer les logs
	if *verbose {
		config.LogLevel = "debug"
	}

	log.Printf("Starting %s v%s", AppName, Version)
	log.Printf("Target path: %s", config.TargetPath)
	log.Printf("Dry run mode: %v", config.ResolverConfig.DryRun)

	// Démarrer le serveur de métriques si activé
	if config.EnableMetrics {
		go startMetricsServer(config.MetricsPort)
	}

	// Exécuter le pipeline
	ctx := context.Background()
	results, err := runPipeline(ctx, config)
	if err != nil {
		log.Fatalf("Pipeline execution failed: %v", err)
	}

	// Sauvegarder les résultats
	err = saveResults(config.OutputDir, results)
	if err != nil {
		log.Printf("Warning: Failed to save results: %v", err)
	}

	// Afficher le résumé
	printSummary(results)
}

// loadConfig charge la configuration depuis un fichier JSON
func loadConfig(configPath string) (*Config, error) {
	// Configuration par défaut
	config := &Config{
		TargetPath:     "../../.github/docs/algorithms",
		ErrorReports:   []string{"../../2025-05-28-errors.md"},
		OutputDir:      "./reports",
		MetricsPort:    9090,
		EnableMetrics:  true,
		LogLevel:       "info",
		ProcessingMode: "comprehensive",
		DetectorConfig: &detector.Config{
			MaxFileSize:        10 * 1024 * 1024, // 10MB
			Timeout:            30 * time.Second,
			ParallelProcessing: true,
			MaxGoroutines:      10,
		},
		ResolverConfig: &resolver.Config{
			SafeFixesOnly:       true,
			BackupBeforeFix:     true,
			MaxMutationsPerFile: 3,
			DryRun:              false,
		},
	}

	// Tenter de charger depuis le fichier
	if _, err := os.Stat(configPath); err == nil {
		data, err := os.ReadFile(configPath)
		if err != nil {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}

		err = json.Unmarshal(data, config)
		if err != nil {
			return nil, fmt.Errorf("failed to parse config file: %w", err)
		}
	}

	return config, nil
}

// runPipeline exécute le pipeline principal
func runPipeline(ctx context.Context, config *Config) (*PipelineResults, error) {
	start := time.Now()

	log.Println("Initializing error detector...")
	errorDetector := detector.NewErrorDetector(config.DetectorConfig)

	log.Println("Initializing auto resolver...")
	autoResolver := resolver.NewAutoResolver(config.ResolverConfig)

	log.Printf("Analyzing target path: %s", config.TargetPath)

	// Phase 1: Détection des erreurs
	var allErrors []detector.DetectedError
	var filesProcessed int

	if isFile(config.TargetPath) {
		errors, err := errorDetector.DetectInFile(ctx, config.TargetPath)
		if err != nil {
			return nil, fmt.Errorf("failed to detect errors in file: %w", err)
		}
		allErrors = errors
		filesProcessed = 1
	} else {
		errors, err := errorDetector.DetectInDirectory(ctx, config.TargetPath)
		if err != nil {
			return nil, fmt.Errorf("failed to detect errors in directory: %w", err)
		}
		allErrors = errors

		// Compter les fichiers traités
		err = filepath.Walk(config.TargetPath, func(path string, info os.FileInfo, err error) error {
			if err == nil && filepath.Ext(path) == ".go" {
				filesProcessed++
			}
			return nil
		})
	}

	log.Printf("Detection complete. Found %d errors in %d files", len(allErrors), filesProcessed)

	// Phase 2: Résolution automatique
	var fixResults []resolver.FixResult
	if len(allErrors) > 0 {
		log.Println("Starting automatic error resolution...")
		fixes, err := autoResolver.ResolveErrors(ctx, allErrors)
		if err != nil {
			return nil, fmt.Errorf("failed to resolve errors: %w", err)
		}
		fixResults = fixes

		appliedFixes := 0
		for _, fix := range fixes {
			if fix.Applied {
				appliedFixes++
			}
		}
		log.Printf("Resolution complete. Applied %d fixes out of %d attempts", appliedFixes, len(fixes))
	}

	// Calculer le résumé
	summary := calculateSummary(allErrors, fixResults)

	results := &PipelineResults{
		ProcessedAt:    time.Now(),
		FilesProcessed: filesProcessed,
		ErrorsDetected: allErrors,
		FixesApplied:   fixResults,
		Summary:        summary,
		Duration:       time.Since(start),
	}

	return results, nil
}

// calculateSummary calcule le résumé des résultats
func calculateSummary(errors []detector.DetectedError, fixes []resolver.FixResult) ProcessingSummary {
	summary := ProcessingSummary{
		TotalErrors: len(errors),
	}

	if len(fixes) == 0 {
		return summary
	}

	var totalConfidence float64
	var criticalIssues int
	var safeFixesApplied int
	var manualReviewRequired int

	for _, fix := range fixes {
		if fix.Applied {
			summary.ErrorsFixed++
			safeFixesApplied++
		}
		totalConfidence += fix.Confidence

		if len(fix.Warnings) > 0 {
			manualReviewRequired++
		}
	}

	// Compter les issues critiques
	for _, error := range errors {
		if error.Severity == detector.SeverityCritical {
			criticalIssues++
		}
	}

	if len(fixes) > 0 {
		summary.FixSuccessRate = float64(summary.ErrorsFixed) / float64(len(fixes)) * 100
		summary.AverageConfidence = totalConfidence / float64(len(fixes))
	}

	summary.CriticalIssues = criticalIssues
	summary.SafeFixesApplied = safeFixesApplied
	summary.ManualReviewRequired = manualReviewRequired

	return summary
}

// saveResults sauvegarde les résultats dans des fichiers
func saveResults(outputDir string, results *PipelineResults) error {
	err := os.MkdirAll(outputDir, 0755)
	if err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	timestamp := results.ProcessedAt.Format("20060102_150405")

	// Sauvegarder les résultats complets en JSON
	resultsFile := filepath.Join(outputDir, fmt.Sprintf("pipeline_results_%s.json", timestamp))
	data, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal results: %w", err)
	}

	err = os.WriteFile(resultsFile, data, 0644)
	if err != nil {
		return fmt.Errorf("failed to write results file: %w", err)
	}

	log.Printf("Results saved to: %s", resultsFile)
	return nil
}

// printSummary affiche un résumé des résultats
func printSummary(results *PipelineResults) {
	fmt.Println("\n" + strings.Repeat("=", 60))
	fmt.Printf("ERROR RESOLUTION PIPELINE - EXECUTION SUMMARY\n")
	fmt.Println(strings.Repeat("=", 60))

	fmt.Printf("Execution Time: %v\n", results.Duration)
	fmt.Printf("Files Processed: %d\n", results.FilesProcessed)
	fmt.Printf("Total Errors Detected: %d\n", results.Summary.TotalErrors)
	fmt.Printf("Errors Fixed: %d\n", results.Summary.ErrorsFixed)
	fmt.Printf("Fix Success Rate: %.1f%%\n", results.Summary.FixSuccessRate)
	fmt.Printf("Average Confidence: %.1f%%\n", results.Summary.AverageConfidence*100)
	fmt.Printf("Critical Issues: %d\n", results.Summary.CriticalIssues)
	fmt.Printf("Safe Fixes Applied: %d\n", results.Summary.SafeFixesApplied)
	fmt.Printf("Manual Review Required: %d\n", results.Summary.ManualReviewRequired)

	if results.Summary.TotalErrors > 0 {
		fmt.Println("\nError Breakdown by Type:")
		errorTypes := make(map[string]int)
		for _, error := range results.ErrorsDetected {
			errorTypes[error.Type]++
		}
		for errorType, count := range errorTypes {
			fmt.Printf("  %s: %d\n", errorType, count)
		}
	}

	fmt.Println(strings.Repeat("=", 60))
}

// startMetricsServer démarre le serveur de métriques Prometheus
func startMetricsServer(port int) {
	http.Handle("/metrics", promhttp.Handler())
	log.Printf("Metrics server starting on port %d", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", port), nil))
}

// isFile vérifie si le chemin pointe vers un fichier
func isFile(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return !info.IsDir()
}
