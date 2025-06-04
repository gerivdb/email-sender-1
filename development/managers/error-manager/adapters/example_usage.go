package adapters

import (
	"log"
	"path/filepath"
	"time"
)

// Exemple d'utilisation des adaptateurs Infrastructure PowerShell/Python
func ExampleUsageDemo() {
	log.Println("=== Démonstration des Adaptateurs Infrastructure ===")

	// 1. Configuration et test de l'adaptateur ScriptInventory
	demonstrateScriptInventoryAdapter()

	// 2. Configuration et test du gestionnaire de duplication
	demonstrateDuplicationHandler()

	// 3. Exemple d'erreurs enrichies avec contexte de duplication
	demonstrateEnhancedErrors()

	log.Println("=== Démonstration terminée ===")
}

// demonstrateScriptInventoryAdapter illustre l'utilisation de l'adaptateur de script
func demonstrateScriptInventoryAdapter() {
	log.Println("\n--- Test de l'Adaptateur ScriptInventory ---")

	// Configuration de l'adaptateur
	config := ScriptInventoryConfig{
		ScriptInventoryPath: filepath.Join(".", "ScriptInventoryManager.psm1"),
		PythonExecutable:    "python",
		WorkingDirectory:    ".",
		TimeoutSeconds:      30,
	}

	adapter := NewScriptInventoryAdapter(config)
	log.Printf("✅ Adaptateur créé avec timeout: %v", adapter)

	// Test de connectivité (sera simulé si PowerShell n'est pas disponible)
	log.Println("🔍 Test de connectivité PowerShell...")
	if err := adapter.ConnectToScriptInventory(); err != nil {
		log.Printf("⚠️  Connectivité PowerShell échouée (normal en environnement de test): %v", err)
	} else {
		log.Println("✅ Connectivité PowerShell réussie")
	}

	// Simulation d'exécution d'inventaire (normalement appellerait PowerShell)
	log.Println("📊 Simulation d'inventaire des scripts...")
	// result, err := adapter.ExecuteScriptInventory("./src")
	// En mode démonstration, on simule le résultat
	simulatedResult := &ScriptInventoryResult{
		Success: true,
		Scripts: []ScriptInfo{
			{
				Path:         "./example.ps1",
				Type:         "PowerShell",
				Size:         1024,
				LastModified: time.Now(),
				Hash:         "abc123def456",
				Dependencies: []string{"Microsoft.PowerShell.Utility"},
				Metadata:     map[string]string{"Author": "Demo", "Version": "1.0"},
			},
			{
				Path:         "./script.py",
				Type:         "Python",
				Size:         2048,
				LastModified: time.Now(),
				Hash:         "def456abc123",
				Dependencies: []string{"os", "sys", "json"},
				Metadata:     map[string]string{"Author": "Demo", "Version": "2.0"},
			},
		},
		ExecutionTime: time.Millisecond * 150,
		Metadata: map[string]interface{}{
			"scan_timestamp": time.Now().Unix(),
			"total_files":    2,
		},
	}

	log.Printf("📋 Inventaire simulé terminé: %d scripts trouvés en %v",
		len(simulatedResult.Scripts), simulatedResult.ExecutionTime)

	for _, script := range simulatedResult.Scripts {
		log.Printf("  📄 %s (%s) - %d bytes, %d dépendances",
			script.Path, script.Type, script.Size, len(script.Dependencies))
	}
}

// demonstrateDuplicationHandler illustre l'utilisation du gestionnaire de duplication
func demonstrateDuplicationHandler() {
	log.Println("\n--- Test du Gestionnaire de Duplication ---")

	// Créer un répertoire temporaire simulé
	reportsPath := "./temp_reports"
	handler := NewDuplicationErrorHandler(reportsPath, time.Second*10)
	log.Printf("✅ Gestionnaire de duplication créé pour: %s", reportsPath)

	// Configuration du callback pour traiter les erreurs
	var processedErrors []DuplicationError
	handler.SetErrorCallback(func(err DuplicationError) {
		processedErrors = append(processedErrors, err)
		log.Printf("🔍 Duplication détectée: %s -> %s (score: %.2f, action: %s)",
			err.SourceFile, err.DuplicateFile, err.SimilarityScore, err.RecommendedAction)
	})

	// Simulation de génération d'erreurs de duplication
	log.Println("🎯 Simulation de détection de duplications...")

	testCases := []struct {
		source, duplicate string
		score             float64
	}{
		{"./src/main.go", "./src/main_backup.go", 0.98},
		{"./scripts/deploy.ps1", "./scripts/deploy_old.ps1", 0.85},
		{"./utils/helper.py", "./utils/helper_v2.py", 0.72},
		{"./config/settings.json", "./config/settings_prod.json", 0.45},
	}

	for _, tc := range testCases {
		dupError := handler.GenerateDuplicationError(tc.source, tc.duplicate, tc.score)

		// Simuler le callback
		if handler != nil {
			processedErrors = append(processedErrors, dupError)
			log.Printf("  📊 %s: Score %.2f → Sévérité %s → %s",
				dupError.ID, dupError.SimilarityScore, dupError.Severity, dupError.RecommendedAction)
		}
	}

	log.Printf("✅ %d duplications traitées", len(processedErrors))
}

// demonstrateEnhancedErrors illustre l'utilisation des erreurs enrichies
func demonstrateEnhancedErrors() {
	log.Println("\n--- Test des Erreurs Enrichies ---")

	// Création d'une erreur de base
	baseError := map[string]interface{}{
		"id":          "err_demo_123",
		"timestamp":   time.Now(),
		"message":     "Erreur détectée dans le script de déploiement",
		"stack_trace": "at deploy.ps1:42\nat main.ps1:15",
		"module":      "deployment-manager",
		"error_code":  "DEPLOY_ERROR",
		"severity":    "ERROR",
		"manager_context": map[string]interface{}{
			"deployment_stage": "production",
			"server_count":     3,
		},
	}
	// Création d'un contexte de duplication
	dupContext := &DuplicationContext{
		SourceFile:     "./scripts/deploy.ps1",
		DuplicateFiles: []string{"./scripts/deploy_backup.ps1", "./scripts/deploy_old.ps1"},
		SimilarityScores: map[string]float64{
			"./scripts/deploy_backup.ps1": 0.95,
			"./scripts/deploy_old.ps1":    0.78,
		},
		DetectionMethod: "powershell_analysis",
		FileReferences:  []string{"./config/deploy.yaml", "./scripts/common.ps1"},
		LastDetection:   time.Now(),
		Metadata: map[string]interface{}{
			"detection_algorithm": "levenshtein_distance",
			"confidence_level":    0.92,
		},
	}

	// Création d'une erreur enrichie
	enhanced := CreateEnhancedErrorEntry(baseError, dupContext)
	log.Printf("✅ Erreur enrichie créée: %s", enhanced.ID)
	log.Printf("  📁 Fichier source: %s", enhanced.DuplicationContext.SourceFile)
	log.Printf("  🔄 %d duplicatas détectés", len(enhanced.DuplicationContext.DuplicateFiles))

	for file, score := range enhanced.DuplicationContext.SimilarityScores {
		log.Printf("    - %s: %.2f%% de similarité", file, score*100)
	}
	// Test de calcul de corrélation
	log.Println("🧮 Calcul des corrélations...")

	dupError := DuplicationError{
		ID:              "dup_demo_456",
		Timestamp:       time.Now().Add(-time.Minute * 5), // 5 minutes avant l'erreur
		SourceFile:      "./scripts/deploy.ps1",
		DuplicateFile:   "./scripts/deploy_backup.ps1",
		SimilarityScore: 0.95,
		ErrorCode:       "SCRIPT_DUPLICATION",
		Severity:        "ERROR",
	}

	correlationScore := CalculateCorrelationScore(enhanced, dupError)
	log.Printf("  📈 Score de corrélation: %.2f", correlationScore)

	if correlationScore > 0.7 {
		log.Println("  🎯 Corrélation forte détectée - Investigation recommandée")
	} else if correlationScore > 0.4 {
		log.Println("  ⚠️  Corrélation modérée - Surveillance recommandée")
	} else {
		log.Println("  ℹ️  Corrélation faible - Pas d'action immédiate")
	}
	// Simulation de métriques de duplication
	log.Println("📊 Simulation des métriques de duplication...")

	metrics := DuplicationMetrics{
		TotalDuplications: 15,
		AverageSimilarity: 0.78,
		FileTypeDuplication: map[string]int{
			"PowerShell": 8,
			"Python":     4,
			"Go":         2,
			"JavaScript": 1,
		},
		ModuleDuplication: map[string]int{
			"deployment-manager": 6,
			"script-manager":     4,
			"process-manager":    3,
			"config-manager":     2,
		},
		TopDuplicatedFiles: []DuplicatedFileInfo{
			{
				FilePath:         "./scripts/deploy.ps1",
				DuplicationCount: 3,
				AverageScore:     0.89,
				LastDetected:     time.Now(),
			},
			{
				FilePath:         "./utils/common.py",
				DuplicationCount: 2,
				AverageScore:     0.82,
				LastDetected:     time.Now().Add(-time.Hour),
			},
		},
	}

	log.Printf("  📊 Total duplications: %d", metrics.TotalDuplications)
	log.Printf("  📈 Similarité moyenne: %.1f%%", metrics.AverageSimilarity*100)
	log.Printf("  🏆 Fichier le plus dupliqué: %s (%d fois)",
		metrics.TopDuplicatedFiles[0].FilePath, metrics.TopDuplicatedFiles[0].DuplicationCount)

	log.Println("✅ Démonstration des erreurs enrichies terminée")
}

// Fonction utilitaire pour simuler l'environnement de test
func init() {
	log.SetFlags(log.LstdFlags | log.Lmsgprefix)
	log.SetPrefix("[ADAPTATEURS-DEMO] ")
}
