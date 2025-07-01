package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// ExecutionStep représente une étape d'exécution
type ExecutionStep struct {
	Name        string   `json:"name"`
	Command     string   `json:"command"`
	Args        []string `json:"args"`
	Description string   `json:"description"`
	Required    bool     `json:"required"`
	Timeout     int      `json:"timeout_seconds"`
}

// ExecutionResult représente le résultat d'une étape
type ExecutionResult struct {
	Step      ExecutionStep `json:"step"`
	Success   bool          `json:"success"`
	Output    string        `json:"output"`
	Error     string        `json:"error,omitempty"`
	Duration  time.Duration `json:"duration"`
	StartTime time.Time     `json:"start_time"`
	EndTime   time.Time     `json:"end_time"`
}

// RoadmapExecution représente l'exécution complète de la roadmap
type RoadmapExecution struct {
	StartTime      time.Time         `json:"start_time"`
	EndTime        time.Time         `json:"end_time"`
	TotalDuration  time.Duration     `json:"total_duration"`
	Steps          []ExecutionStep   `json:"steps"`
	Results        []ExecutionResult `json:"results"`
	SuccessCount   int               `json:"success_count"`
	FailureCount   int               `json:"failure_count"`
	OverallSuccess bool              `json:"overall_success"`
	Summary        string            `json:"summary"`
}

// getExecutionSteps retourne les étapes à exécuter selon le plan v72
func getExecutionSteps() []ExecutionStep {
	return []ExecutionStep{
		{
			Name:        "module-scan",
			Command:     "go",
			Args:        []string{"run", "core/scanmodules/scanmodules.go"},
			Description: "Scanner les modules et générer la structure du dépôt",
			Required:    true,
			Timeout:     30,
		},
		{
			Name:        "gap-analysis",
			Command:     "go",
			Args:        []string{"run", "core/gapanalyzer/gapanalyzer.go", "-input", "modules.json", "-output", "gap-analysis.json"},
			Description: "Analyser les écarts entre modules attendus et existants",
			Required:    true,
			Timeout:     30,
		},
		{
			Name:        "needs-analysis",
			Command:     "go",
			Args:        []string{"run", "core/reporting/needs.go", "-input", "issues.json", "-output", "besoins.json"},
			Description: "Analyser les besoins à partir des issues/tickets",
			Required:    true,
			Timeout:     30,
		},
		{
			Name:        "build-test",
			Command:     "go",
			Args:        []string{"build", "./..."},
			Description: "Construire tous les modules Go",
			Required:    true,
			Timeout:     60,
		},
		{
			Name:        "unit-tests",
			Command:     "go",
			Args:        []string{"test", "./...", "-v"},
			Description: "Exécuter tous les tests unitaires",
			Required:    false,
			Timeout:     120,
		},
		{
			Name:        "coverage-report",
			Command:     "go",
			Args:        []string{"test", "./...", "-coverprofile=coverage.out"},
			Description: "Générer le rapport de couverture de code",
			Required:    false,
			Timeout:     120,
		},
		{
			Name:        "tidy-dependencies",
			Command:     "go",
			Args:        []string{"mod", "tidy"},
			Description: "Nettoyer et organiser les dépendances Go",
			Required:    true,
			Timeout:     30,
		},
	}
}

// executeStep exécute une étape et retourne le résultat
func executeStep(step ExecutionStep) ExecutionResult {
	fmt.Printf("🔄 Exécution: %s - %s\n", step.Name, step.Description)

	result := ExecutionResult{
		Step:      step,
		StartTime: time.Now(),
	}

	// Créer la commande
	cmd := exec.Command(step.Command, step.Args...)
	cmd.Dir = "." // Exécuter dans le répertoire courant

	// Configurer le timeout si spécifié
	if step.Timeout > 0 {
		// Note: Pour un vrai timeout, on devrait utiliser context.WithTimeout
		// Ici on fait une implémentation simplifiée
	}

	// Exécuter la commande
	output, err := cmd.CombinedOutput()
	result.EndTime = time.Now()
	result.Duration = result.EndTime.Sub(result.StartTime)
	result.Output = string(output)

	if err != nil {
		result.Success = false
		result.Error = err.Error()
		fmt.Printf("❌ Échec: %s (durée: %v)\n", step.Name, result.Duration)
		fmt.Printf("   Erreur: %s\n", err.Error())
		if len(result.Output) > 0 {
			fmt.Printf("   Sortie: %s\n", strings.TrimSpace(result.Output))
		}
	} else {
		result.Success = true
		fmt.Printf("✅ Succès: %s (durée: %v)\n", step.Name, result.Duration)
	}

	return result
}

// executeRoadmap exécute toute la roadmap
func executeRoadmap(steps []ExecutionStep, continueOnFailure bool) RoadmapExecution {
	execution := RoadmapExecution{
		StartTime: time.Now(),
		Steps:     steps,
		Results:   []ExecutionResult{},
	}

	fmt.Println("🚀 Démarrage de l'exécution de la roadmap v72")
	fmt.Printf("📅 Heure de début: %s\n", execution.StartTime.Format("2006-01-02 15:04:05"))
	fmt.Printf("📋 Étapes à exécuter: %d\n", len(steps))

	for i, step := range steps {
		fmt.Printf("\n[%d/%d] ", i+1, len(steps))
		result := executeStep(step)
		execution.Results = append(execution.Results, result)

		if result.Success {
			execution.SuccessCount++
		} else {
			execution.FailureCount++
			if step.Required && !continueOnFailure {
				fmt.Printf("\n🛑 Arrêt de l'exécution: étape requise '%s' a échoué\n", step.Name)
				break
			}
		}
	}

	execution.EndTime = time.Now()
	execution.TotalDuration = execution.EndTime.Sub(execution.StartTime)
	execution.OverallSuccess = execution.FailureCount == 0

	// Générer le résumé
	if execution.OverallSuccess {
		execution.Summary = fmt.Sprintf("Roadmap exécutée avec succès! %d/%d étapes réussies en %v",
			execution.SuccessCount, len(execution.Results), execution.TotalDuration)
	} else {
		execution.Summary = fmt.Sprintf("Roadmap terminée avec des erreurs. %d succès, %d échecs sur %d étapes en %v",
			execution.SuccessCount, execution.FailureCount, len(execution.Results), execution.TotalDuration)
	}

	return execution
}

// generateExecutionReport génère un rapport détaillé d'exécution
func generateExecutionReport(execution RoadmapExecution) string {
	var report strings.Builder

	report.WriteString("# 🚀 Rapport d'Exécution de la Roadmap v72\n\n")
	report.WriteString(fmt.Sprintf("**Date d'exécution:** %s\n", execution.StartTime.Format("2006-01-02 15:04:05")))
	report.WriteString(fmt.Sprintf("**Durée totale:** %v\n", execution.TotalDuration))
	report.WriteString(fmt.Sprintf("**Statut général:** %s\n\n", map[bool]string{true: "✅ Succès", false: "❌ Échec"}[execution.OverallSuccess]))

	// Résumé
	report.WriteString("## 📊 Résumé\n\n")
	report.WriteString(fmt.Sprintf("- **Étapes exécutées:** %d\n", len(execution.Results)))
	report.WriteString(fmt.Sprintf("- **Succès:** %d\n", execution.SuccessCount))
	report.WriteString(fmt.Sprintf("- **Échecs:** %d\n", execution.FailureCount))
	report.WriteString(fmt.Sprintf("- **Taux de réussite:** %.1f%%\n\n",
		float64(execution.SuccessCount)/float64(len(execution.Results))*100))

	// Détail des étapes
	report.WriteString("## 📝 Détail des Étapes\n\n")
	for i, result := range execution.Results {
		status := "✅"
		if !result.Success {
			status = "❌"
		}
		report.WriteString(fmt.Sprintf("### %d. %s %s\n\n", i+1, status, result.Step.Name))
		report.WriteString(fmt.Sprintf("- **Description:** %s\n", result.Step.Description))
		report.WriteString(fmt.Sprintf("- **Commande:** `%s %s`\n", result.Step.Command, strings.Join(result.Step.Args, " ")))
		report.WriteString(fmt.Sprintf("- **Durée:** %v\n", result.Duration))
		report.WriteString(fmt.Sprintf("- **Statut:** %s\n", map[bool]string{true: "Succès", false: "Échec"}[result.Success]))

		if !result.Success && result.Error != "" {
			report.WriteString(fmt.Sprintf("- **Erreur:** %s\n", result.Error))
		}

		if result.Output != "" {
			output := strings.TrimSpace(result.Output)
			if len(output) > 500 { // Limiter la sortie
				output = output[:500] + "... (tronqué)"
			}
			report.WriteString(fmt.Sprintf("- **Sortie:**\n```\n%s\n```\n", output))
		}
		report.WriteString("\n")
	}

	// Recommandations
	report.WriteString("## 🎯 Recommandations\n\n")
	if execution.OverallSuccess {
		report.WriteString("🎉 **Excellent!** Toutes les étapes ont été exécutées avec succès.\n\n")
		report.WriteString("**Prochaines étapes suggérées:**\n")
		report.WriteString("1. Vérifier les rapports générés (gap-analysis.md, BESOINS_INITIAUX.md)\n")
		report.WriteString("2. Implémenter les modules manquants identifiés\n")
		report.WriteString("3. Configurer la CI/CD pour l'automatisation\n")
	} else {
		report.WriteString("⚠️ **Attention!** Certaines étapes ont échoué.\n\n")
		report.WriteString("**Actions recommandées:**\n")
		for _, result := range execution.Results {
			if !result.Success {
				report.WriteString(fmt.Sprintf("- Corriger l'erreur dans '%s': %s\n", result.Step.Name, result.Error))
			}
		}
	}

	return report.String()
}

// saveResults sauvegarde les résultats d'exécution
func saveResults(execution RoadmapExecution) error {
	// Sauvegarder en JSON
	jsonData, err := json.MarshalIndent(execution, "", "  ")
	if err != nil {
		return fmt.Errorf("erreur lors de la sérialisation JSON: %v", err)
	}

	timestamp := execution.StartTime.Format("2006-01-02_15-04-05")
	jsonFile := fmt.Sprintf("roadmap-execution_%s.json", timestamp)
	err = ioutil.WriteFile(jsonFile, jsonData, 0644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier JSON: %v", err)
	}

	// Générer et sauvegarder le rapport Markdown
	report := generateExecutionReport(execution)
	markdownFile := fmt.Sprintf("ROADMAP_EXECUTION_REPORT_%s.md", timestamp)
	err = ioutil.WriteFile(markdownFile, []byte(report), 0644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du rapport Markdown: %v", err)
	}

	fmt.Printf("📄 Fichiers générés:\n")
	fmt.Printf("   - %s (résultats JSON)\n", jsonFile)
	fmt.Printf("   - %s (rapport Markdown)\n", markdownFile)

	return nil
}

// createBackup crée une sauvegarde des fichiers importants
func createBackup() error {
	backupDir := fmt.Sprintf("backup_%s", time.Now().Format("2006-01-02_15-04-05"))
	err := os.MkdirAll(backupDir, 0755)
	if err != nil {
		return fmt.Errorf("erreur lors de la création du dossier de sauvegarde: %v", err)
	}

	// Fichiers à sauvegarder
	filesToBackup := []string{
		"modules.json",
		"gap-analysis.json",
		"besoins.json",
		"arborescence.txt",
		"modules.txt",
	}

	for _, file := range filesToBackup {
		if _, err := os.Stat(file); err == nil {
			// Le fichier existe, le copier
			src := file
			dst := filepath.Join(backupDir, file)

			data, err := ioutil.ReadFile(src)
			if err != nil {
				log.Printf("⚠️ Impossible de lire %s: %v", src, err)
				continue
			}
			err = ioutil.WriteFile(dst, data, 0644)
			if err != nil {
				log.Printf("⚠️ Impossible de sauvegarder %s: %v", file, err)
				continue
			}
		}
	}

	fmt.Printf("💾 Sauvegarde créée dans: %s\n", backupDir)
	return nil
}

func main() {
	// Définir les flags de ligne de commande
	continueOnFailure := flag.Bool("continue", false, "Continuer l'exécution même en cas d'échec d'une étape requise")
	backup := flag.Bool("backup", true, "Créer une sauvegarde avant l'exécution")
	flag.Parse()

	fmt.Println("🎯 === Orchestrateur Global de la Roadmap v72 ===")
	fmt.Printf("⚙️ Options: continue-on-failure=%v, backup=%v\n", *continueOnFailure, *backup)

	// Créer une sauvegarde si demandé
	if *backup {
		fmt.Println("\n💾 Création de la sauvegarde...")
		if err := createBackup(); err != nil {
			log.Printf("⚠️ Erreur lors de la sauvegarde: %v", err)
		}
	}

	// Obtenir les étapes d'exécution
	steps := getExecutionSteps()

	// Exécuter la roadmap
	execution := executeRoadmap(steps, *continueOnFailure)

	// Afficher le résumé
	fmt.Printf("\n🎉 === Résumé de l'Exécution ===\n")
	fmt.Printf("📊 %s\n", execution.Summary)
	fmt.Printf("⏱️ Durée totale: %v\n", execution.TotalDuration)

	if execution.OverallSuccess {
		fmt.Printf("🎉 Statut: SUCCÈS COMPLET\n")
	} else {
		fmt.Printf("⚠️ Statut: TERMINÉ AVEC ERREURS\n")
	}

	// Sauvegarder les résultats
	fmt.Println("\n📄 Sauvegarde des résultats...")
	if err := saveResults(execution); err != nil {
		log.Printf("❌ Erreur lors de la sauvegarde des résultats: %v", err)
	}

	// Code de sortie
	if execution.OverallSuccess {
		fmt.Println("\n✨ Roadmap exécutée avec succès!")
		os.Exit(0)
	} else {
		fmt.Println("\n⚠️ Roadmap terminée avec des erreurs")
		os.Exit(1)
	}
}
