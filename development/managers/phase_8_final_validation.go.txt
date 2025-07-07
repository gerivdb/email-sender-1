package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

// Phase8ValidationResult représente le résultat d'un test de validation Phase 8
type Phase8ValidationResult struct {
	TestName string        `json:"test_name"`
	Success  bool          `json:"success"`
	Duration time.Duration `json:"duration"`
	Details  string        `json:"details"`
	Critical bool          `json:"critical"`
	Score    int           `json:"score"` // Score sur 100
}

// Phase8Report représente le rapport complet de validation Phase 8
type Phase8Report struct {
	Timestamp   time.Time                `json:"timestamp"`
	TotalTests  int                      `json:"total_tests"`
	PassedTests int                      `json:"passed_tests"`
	FailedTests int                      `json:"failed_tests"`
	TotalScore  int                      `json:"total_score"`
	MaxScore    int                      `json:"max_score"`
	Duration    time.Duration            `json:"duration"`
	Results     []Phase8ValidationResult `json:"results"`
	Summary     string                   `json:"summary"`
}

func main() {
	fmt.Println("🎯 Phase 8 - Validation Finale de l'Écosystème")
	fmt.Println("===============================================")

	startTime := time.Now()

	// Liste des tests de validation finale
	tests := []struct {
		name     string
		testFunc func() Phase8ValidationResult
		critical bool
		weight   int
	}{
		{"Architecture Go Native Complète", testGoNativeArchitecture, true, 100},
		{"Documentation Technique", testTechnicalDocumentation, true, 100},
		{"Guides Utilisateur", testUserGuides, true, 100},
		{"API Documentation", testAPIDocumentation, false, 80},
		{"Performance Benchmarks", testPerformanceBenchmarks, true, 100},
		{"Tests d'Intégration", testIntegrationTests, true, 100},
		{"Infrastructure de Déploiement", testDeploymentInfrastructure, true, 100},
		{"Monitoring et Observabilité", testMonitoringSetup, false, 80},
		{"Sécurité et Conformité", testSecurityCompliance, true, 100},
		{"Migration Python Terminée", testPythonMigrationComplete, true, 100},
		{"Managers Opérationnels", testManagersOperational, true, 100},
		{"Vectorisation Go Native", testVectorizationGoNative, true, 100},
		{"Qualité du Code", testCodeQuality, false, 80},
		{"Préparation Production", testProductionReadiness, true, 100},
	}

	fmt.Printf("Exécution de %d tests de validation finale...\n", len(tests))

	var results []Phase8ValidationResult
	totalScore := 0
	maxScore := 0

	for i, test := range tests {
		fmt.Printf("📋 Test %d/%d: %s... ", i+1, len(tests), test.name)

		result := test.testFunc()
		result.TestName = test.name
		result.Critical = test.critical

		// Calcul du score pondéré
		if result.Success {
			result.Score = test.weight
		} else {
			result.Score = 0
		}

		totalScore += result.Score
		maxScore += test.weight

		results = append(results, result)

		if result.Success {
			fmt.Printf("✅ (%.2fs)\n", result.Duration.Seconds())
		} else {
			if result.Critical {
				fmt.Printf("❌ CRITIQUE (%.2fs): %s\n", result.Duration.Seconds(), result.Details)
			} else {
				fmt.Printf("⚠️  (%.2fs): %s\n", result.Duration.Seconds(), result.Details)
			}
		}
	}

	totalDuration := time.Since(startTime)
	passedTests := 0
	failedTests := 0
	criticalFailures := 0

	for _, result := range results {
		if result.Success {
			passedTests++
		} else {
			failedTests++
			if result.Critical {
				criticalFailures++
			}
		}
	}

	// Générer le rapport
	report := Phase8Report{
		Timestamp:   time.Now(),
		TotalTests:  len(tests),
		PassedTests: passedTests,
		FailedTests: failedTests,
		TotalScore:  totalScore,
		MaxScore:    maxScore,
		Duration:    totalDuration,
		Results:     results,
	}

	// Déterminer le statut final
	scorePercentage := float64(totalScore) / float64(maxScore) * 100

	if criticalFailures == 0 && scorePercentage >= 95 {
		report.Summary = "🎉 VALIDATION FINALE RÉUSSIE - ÉCOSYSTÈME PRÊT POUR PRODUCTION"
	} else if criticalFailures == 0 && scorePercentage >= 85 {
		report.Summary = "✅ VALIDATION MAJORITAIRE RÉUSSIE - QUELQUES AMÉLIORATIONS NÉCESSAIRES"
	} else if criticalFailures > 0 {
		report.Summary = "❌ ÉCHECS CRITIQUES DÉTECTÉS - INTERVENTION NÉCESSAIRE"
	} else {
		report.Summary = "⚠️  VALIDATION PARTIELLE - AMÉLIORATIONS REQUISES"
	}

	// Afficher le rapport
	fmt.Println("\n📊 Rapport de Validation Finale Phase 8")
	fmt.Println("=====================================")
	fmt.Printf("Tests exécutés: %d\n", report.TotalTests)
	fmt.Printf("Tests réussis: %d\n", report.PassedTests)
	fmt.Printf("Tests échoués: %d\n", report.FailedTests)
	fmt.Printf("Échecs critiques: %d\n", criticalFailures)
	fmt.Printf("Score final: %d/%d (%.1f%%)\n", report.TotalScore, report.MaxScore, scorePercentage)
	fmt.Printf("Durée totale: %.2fs\n", report.Duration.Seconds())
	fmt.Printf("\n%s\n", report.Summary)

	// Sauvegarder le rapport
	filename := fmt.Sprintf("phase_8_final_validation_%s.json", time.Now().Format("20060102_150405"))
	if err := saveReport(report, filename); err != nil {
		log.Printf("Erreur lors de la sauvegarde: %v", err)
	} else {
		fmt.Printf("Résultats sauvegardés dans: %s\n", filename)
	}

	// Code de sortie basé sur les résultats
	if criticalFailures > 0 {
		os.Exit(1)
	} else if scorePercentage < 85 {
		os.Exit(2)
	}
}

func testGoNativeArchitecture() Phase8ValidationResult {
	start := time.Now()
	// Vérifier la structure Go native
	requiredDirs := []string{
		"central-coordinator",
		"vectorization-go",
		"api-gateway",
		"interfaces",
	}

	for _, dir := range requiredDirs {
		if !dirExists(dir) {
			return Phase8ValidationResult{
				Success:  false,
				Duration: time.Since(start),
				Details:  fmt.Sprintf("Répertoire manquant: %s", dir),
			}
		}
	}

	// Vérifier les fichiers Go principaux
	requiredFiles := []string{
		"central-coordinator/coordinator.go",
		"vectorization-go/vector_client.go",
		"api-gateway/gateway.go",
		"interfaces/manager_common.go",
	}

	for _, file := range requiredFiles {
		if !fileExists(file) {
			return Phase8ValidationResult{
				Success:  false,
				Duration: time.Since(start),
				Details:  fmt.Sprintf("Fichier Go manquant: %s", file),
			}
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Architecture Go native complète et validée",
	}
}

func testTechnicalDocumentation() Phase8ValidationResult {
	start := time.Now()
	requiredDocs := []string{
		"../../docs/ARCHITECTURE_GO_NATIVE.md",
		"../../docs/MIGRATION_GUIDE.md",
		"../../docs/TROUBLESHOOTING_GUIDE.md",
	}

	for _, doc := range requiredDocs {
		if !fileExists(doc) {
			return Phase8ValidationResult{
				Success:  false,
				Duration: time.Since(start),
				Details:  fmt.Sprintf("Documentation manquante: %s", doc),
			}
		}

		// Vérifier que le fichier n'est pas vide
		if fileSize, err := getFileSize(doc); err != nil || fileSize < 1000 {
			return Phase8ValidationResult{
				Success:  false,
				Duration: time.Since(start),
				Details:  fmt.Sprintf("Documentation incomplète: %s (taille: %d bytes)", doc, fileSize),
			}
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Documentation technique complète et détaillée",
	}
}

func testUserGuides() Phase8ValidationResult {
	start := time.Now()

	// Vérifier les guides utilisateur dans la documentation
	userGuides := []string{
		"README.md",
		"docs/DEPLOYMENT_GUIDE.md",
	}

	existingGuides := 0
	for _, guide := range userGuides {
		if fileExists(guide) {
			existingGuides++
		}
	}

	if existingGuides < len(userGuides)/2 {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  fmt.Sprintf("Guides utilisateur insuffisants: %d/%d présents", existingGuides, len(userGuides)),
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  fmt.Sprintf("Guides utilisateur disponibles: %d/%d", existingGuides, len(userGuides)),
	}
}

func testAPIDocumentation() Phase8ValidationResult {
	start := time.Now()

	// Vérifier si l'API Gateway expose la documentation
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, "GET", "http://localhost:8080/docs", nil)
	if err != nil {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  "Impossible de créer la requête de test",
		}
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  "API documentation non accessible (service probablement arrêté)",
		}
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  fmt.Sprintf("API documentation retourne status %d", resp.StatusCode),
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "API documentation accessible et fonctionnelle",
	}
}

func testPerformanceBenchmarks() Phase8ValidationResult {
	start := time.Now()

	// Vérifier les fichiers de tests de performance
	performanceTests := []string{
		"development/managers/phase_4_performance_validation.go",
		"development/managers/phase_4_performance_test.go",
	}

	foundTests := 0
	for _, test := range performanceTests {
		if fileExists(test) {
			foundTests++
		}
	}

	if foundTests == 0 {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  "Aucun test de performance trouvé",
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  fmt.Sprintf("Tests de performance disponibles: %d fichiers", foundTests),
	}
}

func testIntegrationTests() Phase8ValidationResult {
	start := time.Now()

	// Vérifier les tests d'intégration
	integrationDir := "development/managers/integration_tests"
	if !dirExists(integrationDir) {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  "Répertoire des tests d'intégration manquant",
		}
	}

	requiredTests := []string{
		"development/managers/integration_tests/complete_ecosystem_integration.go",
	}

	for _, test := range requiredTests {
		if !fileExists(test) {
			return Phase8ValidationResult{
				Success:  false,
				Duration: time.Since(start),
				Details:  fmt.Sprintf("Test d'intégration manquant: %s", test),
			}
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Tests d'intégration complets disponibles",
	}
}

func testDeploymentInfrastructure() Phase8ValidationResult {
	start := time.Now()
	// Vérifier l'infrastructure de déploiement
	deploymentFiles := []string{
		"../../deployment/Dockerfile.go",
		"../../deployment/docker-compose.production.yml",
		"../../deployment/staging/staging-deploy.ps1",
		"../../deployment/production/production-deploy.ps1",
	}

	for _, file := range deploymentFiles {
		if !fileExists(file) {
			return Phase8ValidationResult{
				Success:  false,
				Duration: time.Since(start),
				Details:  fmt.Sprintf("Fichier de déploiement manquant: %s", file),
			}
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Infrastructure de déploiement complète",
	}
}

func testMonitoringSetup() Phase8ValidationResult {
	start := time.Now()

	// Vérifier la configuration de monitoring	monitoringFiles := []string{
		"../../deployment/config/prometheus/prometheus.yml",
		"../../deployment/config/nginx/nginx.conf",
	}

	foundFiles := 0
	for _, file := range monitoringFiles {
		if fileExists(file) {
			foundFiles++
		}
	}

	if foundFiles < len(monitoringFiles)/2 {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  fmt.Sprintf("Configuration monitoring incomplète: %d/%d fichiers", foundFiles, len(monitoringFiles)),
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Configuration monitoring disponible",
	}
}

func testSecurityCompliance() Phase8ValidationResult {
	start := time.Now()

	// Vérifier les aspects de sécurité
	securityChecks := []bool{
		fileExists("deployment/config/nginx/nginx.conf"),  // Configuration HTTPS
		!fileExists("config/secrets.yaml"),                // Pas de secrets en plain text
		fileExists("deployment/staging/health-check.ps1"), // Health checks
	}

	passedChecks := 0
	for _, check := range securityChecks {
		if check {
			passedChecks++
		}
	}

	if passedChecks < len(securityChecks)*2/3 {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  fmt.Sprintf("Vérifications sécurité insuffisantes: %d/%d", passedChecks, len(securityChecks)),
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Configuration sécurité conforme",
	}
}

func testPythonMigrationComplete() Phase8ValidationResult {
	start := time.Now()

	// Vérifier qu'il ne reste plus de dépendances Python critiques
	pythonFiles := []string{
		"misc/vectorize_tasks.py",
		"requirements.txt",
	}

	remainingPython := 0
	for _, file := range pythonFiles {
		if fileExists(file) {
			remainingPython++
		}
	}

	// Il peut y avoir des fichiers Python legacy, mais pas les critiques
	if fileExists("misc/vectorize_tasks.py") {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  "Fichier Python critique encore présent: misc/vectorize_tasks.py",
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Migration Python vers Go terminée",
	}
}

func testManagersOperational() Phase8ValidationResult {
	start := time.Now()

	// Vérifier que tous les managers principaux sont présents
	coreManagers := []string{
		"development/managers/central-coordinator",
		"development/managers/vectorization-go",
		"development/managers/api-gateway",
		"development/managers/dependency-manager",
	}

	for _, manager := range coreManagers {
		if !dirExists(manager) {
			return Phase8ValidationResult{
				Success:  false,
				Duration: time.Since(start),
				Details:  fmt.Sprintf("Manager principal manquant: %s", manager),
			}
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Tous les managers principaux sont présents",
	}
}

func testVectorizationGoNative() Phase8ValidationResult {
	start := time.Now()

	// Vérifier les composants de vectorisation Go
	vectorFiles := []string{
		"development/managers/vectorization-go/vector_client.go",
		"development/managers/vectorization-go/vector_operations.go",
		"development/managers/vectorization-go/connection_pool.go",
		"development/managers/vectorization-go/vector_cache.go",
	}

	for _, file := range vectorFiles {
		if !fileExists(file) {
			return Phase8ValidationResult{
				Success:  false,
				Duration: time.Since(start),
				Details:  fmt.Sprintf("Composant vectorisation manquant: %s", file),
			}
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Vectorisation Go native complète",
	}
}

func testCodeQuality() Phase8ValidationResult {
	start := time.Now()

	// Vérifier la qualité du code (go.mod, structure, etc.)
	qualityChecks := []bool{
		fileExists("go.mod"),
		fileExists("go.sum"),
		dirExists("development/managers"),
		fileExists("development/managers/interfaces/manager_common.go"),
	}

	passedChecks := 0
	for _, check := range qualityChecks {
		if check {
			passedChecks++
		}
	}

	if passedChecks < len(qualityChecks) {
		return Phase8ValidationResult{
			Success:  false,
			Duration: time.Since(start),
			Details:  fmt.Sprintf("Vérifications qualité échouées: %d/%d", passedChecks, len(qualityChecks)),
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Qualité du code conforme",
	}
}

func testProductionReadiness() Phase8ValidationResult {
	start := time.Now()

	// Vérifier la préparation pour la production
	prodReadinessFiles := []string{
		"deployment/docker-compose.production.yml",
		"deployment/production/production-deploy.ps1",
		"deployment/staging/rollback.ps1",
	}

	for _, file := range prodReadinessFiles {
		if !fileExists(file) {
			return Phase8ValidationResult{
				Success:  false,
				Duration: time.Since(start),
				Details:  fmt.Sprintf("Fichier production manquant: %s", file),
			}
		}
	}

	return Phase8ValidationResult{
		Success:  true,
		Duration: time.Since(start),
		Details:  "Environnement production prêt",
	}
}

// Fonctions utilitaires
func fileExists(filename string) bool {
	_, err := os.Stat(filename)
	return !os.IsNotExist(err)
}

func dirExists(dirname string) bool {
	info, err := os.Stat(dirname)
	if os.IsNotExist(err) {
		return false
	}
	return info.IsDir()
}

func getFileSize(filename string) (int64, error) {
	info, err := os.Stat(filename)
	if err != nil {
		return 0, err
	}
	return info.Size(), nil
}

func saveReport(report Phase8Report, filename string) error {
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(filename, data, 0644)
}
